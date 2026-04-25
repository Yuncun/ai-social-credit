#!/bin/bash
# Verify a notarized AI Social Credit report.
# Checks the Ed25519 signature in the YAML and the OpenTimestamps proof.

set -e

REPORT_FILE="$1"

if [ -z "$REPORT_FILE" ]; then
    echo "Usage: verify.sh <path-to-report.yaml>"
    exit 1
fi

if [ ! -f "$REPORT_FILE" ]; then
    echo "ERROR: report file not found: $REPORT_FILE"
    exit 1
fi

OTS_FILE="$REPORT_FILE.ots"

# Dependency checks
if ! command -v openssl >/dev/null 2>&1; then
    echo "ERROR: openssl is required but was not found in PATH."
    exit 1
fi

if ! command -v ots >/dev/null 2>&1; then
    echo "ERROR: ots (OpenTimestamps client) is required but was not found in PATH."
    echo "Install with: pipx install opentimestamps-client"
    exit 1
fi

# Parse pubkey and signature from the report
PUBKEY_LINE=$(grep '^pubkey: ed25519:' "$REPORT_FILE" | head -1)
SIG_LINE=$(grep '^signature: ed25519:' "$REPORT_FILE" | head -1)

if [ -z "$PUBKEY_LINE" ] || [ -z "$SIG_LINE" ]; then
    echo "ERROR: report is missing pubkey or signature line."
    exit 1
fi

PUBKEY_HEX="${PUBKEY_LINE#pubkey: ed25519:}"
SIG_HEX="${SIG_LINE#signature: ed25519:}"

# The signed body is everything except the signature line. Strip the trailing
# signature line and any blank line before it.
BODY=$(sed '/^signature: /,$d' "$REPORT_FILE" | sed -e :a -e '/^$/{$d;N;ba' -e '}')

# Reconstruct the Ed25519 public key as PEM.
# DER format for Ed25519 public key: 12-byte prefix + 32-byte raw key.
DER_PREFIX="302a300506032b6570032100"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

PUB_PEM="$TMP_DIR/pub.pem"
SIG_BIN="$TMP_DIR/sig.bin"
BODY_FILE="$TMP_DIR/body.txt"

printf '%s%s' "$DER_PREFIX" "$PUBKEY_HEX" | xxd -r -p | base64 | (
    echo "-----BEGIN PUBLIC KEY-----"
    cat
    echo "-----END PUBLIC KEY-----"
) > "$PUB_PEM"

printf '%s' "$SIG_HEX" | xxd -r -p > "$SIG_BIN"
printf '%s' "$BODY" > "$BODY_FILE"

# Verify the signature
SIG_OK=0
if openssl pkeyutl -verify -pubin -inkey "$PUB_PEM" -rawin -in "$BODY_FILE" -sigfile "$SIG_BIN" >/dev/null 2>&1; then
    SIG_STATUS="VALID"
    SIG_OK=1
else
    SIG_STATUS="INVALID"
fi

# Verify the OpenTimestamps proof
OTS_STATUS=""
OTS_DETAIL=""
if [ ! -f "$OTS_FILE" ]; then
    OTS_STATUS="MISSING"
    OTS_DETAIL="No .ots file found at $OTS_FILE"
else
    OTS_OUTPUT=$(ots verify "$OTS_FILE" 2>&1 || true)
    if echo "$OTS_OUTPUT" | grep -qi "Success!"; then
        OTS_STATUS="VALID"
        OTS_DETAIL=$(echo "$OTS_OUTPUT" | grep -i "Bitcoin block" | head -1 | sed 's/^[[:space:]]*//')
    elif echo "$OTS_OUTPUT" | grep -qi "Pending"; then
        OTS_STATUS="PENDING"
        OTS_DETAIL="Stamp not yet confirmed by Bitcoin (~24h after stamping). Run: ots upgrade $OTS_FILE"
    else
        OTS_STATUS="UNVERIFIED"
        OTS_DETAIL=$(echo "$OTS_OUTPUT" | tail -3)
    fi
fi

# Print summary
echo "Report:      $REPORT_FILE"
echo "Signed by:   ed25519:$PUBKEY_HEX"
echo "Signature:   $SIG_STATUS"
echo "Timestamp:   $OTS_STATUS"
[ -n "$OTS_DETAIL" ] && echo "             $OTS_DETAIL"

# Show the score that was attested
echo
echo "--- Attested score ---"
sed -n '/^score:/,/^attested_at:/p' "$REPORT_FILE"

# Exit code reflects signature validity
if [ "$SIG_OK" = "1" ]; then
    exit 0
else
    exit 1
fi
