#!/bin/bash
# Bundle the user's notarized reports, signing keypair, and score file into a
# tar.gz suitable for backup or transfer to another machine.

set -e

REPORTS_DIR="$HOME/.claude/social-credit-reports"
KEY_FILE="$HOME/.claude/social-credit.key"
PUBKEY_FILE="$HOME/.claude/social-credit.pub"
SCORE_FILE="$HOME/.claude/social-credit.local.md"

TS=$(date -u +%Y-%m-%dT%H-%M-%SZ)
OUT_FILE="$HOME/social-credit-export-$TS.tar.gz"

# Collect what exists
PIECES=()
[ -d "$REPORTS_DIR" ] && PIECES+=("$REPORTS_DIR")
[ -f "$KEY_FILE" ]    && PIECES+=("$KEY_FILE")
[ -f "$PUBKEY_FILE" ] && PIECES+=("$PUBKEY_FILE")
[ -f "$SCORE_FILE" ]  && PIECES+=("$SCORE_FILE")

if [ ${#PIECES[@]} -eq 0 ]; then
    echo "Nothing to export. Run /notarize-report at least once first."
    exit 0
fi

# Tar relative to $HOME so the archive restores cleanly with `tar -xzf` from $HOME
RELATIVE=()
for p in "${PIECES[@]}"; do
    RELATIVE+=("${p#$HOME/}")
done

tar -czf "$OUT_FILE" -C "$HOME" "${RELATIVE[@]}"

SIZE=$(du -h "$OUT_FILE" | cut -f1)

echo "Export complete."
echo
echo "File:    $OUT_FILE"
echo "Size:    $SIZE"
echo "Bundled:"
for r in "${RELATIVE[@]}"; do
    echo "  ~/$r"
done
echo
echo "To restore on another machine:"
echo "  tar -xzf $(basename "$OUT_FILE") -C ~"
