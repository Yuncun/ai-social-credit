#!/bin/bash
# Render the current score for /score skill output.
# Reads ~/.claude/social-credit.local.md, applies formula/fico.sh, prints status.

SCORE_FILE="$HOME/.claude/social-credit.local.md"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/fico.sh"

if [ ! -f "$SCORE_FILE" ]; then
    echo "No score file yet. Scoring starts after the next session ends."
    exit 0
fi

TOTAL=$(grep '^total_score:'  "$SCORE_FILE" | head -1 | sed 's/total_score: *//;s/[[:space:]]*$//')
SESSIONS=$(grep '^sessions:'  "$SCORE_FILE" | head -1 | sed 's/sessions: *//;s/[[:space:]]*$//')
UPDATED=$(grep '^last_updated:' "$SCORE_FILE" | head -1 | sed 's/last_updated: *//;s/[[:space:]]*$//')
[ -z "$TOTAL" ]    && TOTAL=0
[ -z "$SESSIONS" ] && SESSIONS=0
[ -z "$UPDATED" ]  && UPDATED="never"

FICO=$(internal_to_fico "$TOTAL")
TIER=$(fico_to_tier "$FICO")

DELTA_DISPLAY="$TOTAL"
[ "$TOTAL" -gt 0 ] 2>/dev/null && DELTA_DISPLAY="+${TOTAL}"

echo "AI Social Credit Score"
echo "----------------------"
echo "FICO:       $FICO ($TIER)"
echo "Internal:   $DELTA_DISPLAY"
echo "Sessions:   $SESSIONS"
echo "Updated:    $UPDATED"
echo
echo "Recent history:"

END_FM=$(grep -n '^---$' "$SCORE_FILE" | sed -n '2p' | cut -d: -f1)
if [ -n "$END_FM" ]; then
    tail -n +$((END_FM + 1)) "$SCORE_FILE" | grep '^|' | tail -n 6
fi
