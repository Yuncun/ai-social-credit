#!/bin/bash
# Notarize the current AI Social Credit score.
# Generates an Ed25519 keypair on first use, signs a YAML attestation of the
# current score, and anchors the timestamp to the Bitcoin blockchain via
# OpenTimestamps. Stores the report locally.

set -e

SCORE_FILE="$HOME/.claude/social-credit.local.md"
KEY_FILE="$HOME/.claude/social-credit.key"
PUBKEY_FILE="$HOME/.claude/social-credit.pub"
REPORTS_DIR="$HOME/.claude/social-credit-reports"

# Resolve the path to fico.sh relative to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FICO_LIB="$SCRIPT_DIR/../formula/fico.sh"

# Dependency checks
if ! command -v openssl >/dev/null 2>&1; then
    echo "ERROR: openssl is required but was not found in PATH."
    exit 1
fi

if ! command -v ots >/dev/null 2>&1; then
    echo "ERROR: ots (OpenTimestamps client) is required but was not found in PATH."
    echo "Install with: pipx install opentimestamps-client"
    echo "  (or: pip install --user opentimestamps-client)"
    exit 1
fi

if [ ! -f "$SCORE_FILE" ]; then
    echo "No score file yet. Run a session first; scoring starts after the next session ends."
    exit 0
fi

if [ ! -f "$FICO_LIB" ]; then
    echo "ERROR: cannot find fico.sh at $FICO_LIB"
    exit 1
fi

# Generate keypair on first use
if [ ! -f "$KEY_FILE" ]; then
    echo "First-time setup: generating Ed25519 keypair..."
    openssl genpkey -algorithm ed25519 -out "$KEY_FILE" 2>/dev/null
    chmod 600 "$KEY_FILE"
    openssl pkey -in "$KEY_FILE" -pubout -out "$PUBKEY_FILE" 2>/dev/null
    echo "Keypair saved: $KEY_FILE (private), $PUBKEY_FILE (public)"
    echo
fi

# Extract raw public key bytes (last 32 bytes of DER) and hex-encode
PUBKEY_HEX=$(openssl pkey -in "$KEY_FILE" -pubout -outform DER 2>/dev/null | tail -c 32 | xxd -p -c 64)
PUBKEY_FIELD="ed25519:$PUBKEY_HEX"

# Read current score
TOTAL=$(grep '^total_score:' "$SCORE_FILE" | head -1 | sed 's/total_score: *//;s/[[:space:]]*$//')
SESSIONS=$(grep '^sessions:' "$SCORE_FILE" | head -1 | sed 's/sessions: *//;s/[[:space:]]*$//')
[ -z "$TOTAL" ] && TOTAL=0
[ -z "$SESSIONS" ] && SESSIONS=0

# Compute FICO + tier via the formula library
. "$FICO_LIB"
FICO=$(internal_to_fico "$TOTAL")
TIER=$(fico_to_tier "$FICO")

# Prepare the report file path
mkdir -p "$REPORTS_DIR"
TS_FILE=$(date -u +%Y-%m-%dT%H-%M-%SZ)
TS_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)
REPORT_FILE="$REPORTS_DIR/$TS_FILE.yaml"

# Build the body to sign (everything except the signature line)
BODY=$(cat <<EOF
protocol_version: 1
pubkey: $PUBKEY_FIELD
score:
  total: $TOTAL
  fico: $FICO
  tier: $TIER
  sessions: $SESSIONS
attested_at: $TS_ISO
EOF
)

# Sign the body with the private key (Ed25519 needs -rawin)
TMP_BODY=$(mktemp)
TMP_SIG=$(mktemp)
trap 'rm -f "$TMP_BODY" "$TMP_SIG"' EXIT

printf '%s' "$BODY" > "$TMP_BODY"
openssl pkeyutl -sign -rawin -inkey "$KEY_FILE" -in "$TMP_BODY" -out "$TMP_SIG" 2>/dev/null
SIG_HEX=$(xxd -p -c 256 "$TMP_SIG" | tr -d '\n')

# Write the final report (body + signature)
{
    printf '%s\n' "$BODY"
    printf 'signature: ed25519:%s\n' "$SIG_HEX"
} > "$REPORT_FILE"

# Stamp the report to Bitcoin via OpenTimestamps
echo "Stamping to Bitcoin via OpenTimestamps..."
if ! ots stamp "$REPORT_FILE" >/dev/null 2>&1; then
    echo "WARNING: ots stamp failed. Report saved without timestamp anchor."
    echo "Try again later with: ots stamp $REPORT_FILE"
fi

# Print summary
echo
echo "Report notarized."
echo
echo "ID:        $PUBKEY_FIELD"
echo "Score:     $FICO ($TIER)"
echo "Internal:  $TOTAL"
echo "Sessions:  $SESSIONS"
echo "File:      $REPORT_FILE"
if [ -f "$REPORT_FILE.ots" ]; then
    echo "Anchor:    pending Bitcoin confirmation (~24h)"
    echo
    echo "The anchor will be auto-upgraded next session-end. To upgrade manually:"
    echo "  ots upgrade $REPORT_FILE.ots"
fi
