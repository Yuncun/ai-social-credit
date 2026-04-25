#!/bin/bash
SCORE_FILE="$HOME/.claude/social-credit.local.md"
. "${CLAUDE_PLUGIN_ROOT}/formula/fico.sh"

[ -f "$SCORE_FILE" ] || exit 0

VERBOSE=$(grep '^verbose:' "$SCORE_FILE" | head -1 | sed 's/verbose: *//;s/[[:space:]]*$//')
[ "$VERBOSE" = "true" ] || exit 0

TOTAL=$(grep '^total_score:' "$SCORE_FILE" | head -1 | sed 's/total_score: *//;s/[[:space:]]*$//')
[ -z "$TOTAL" ] && TOTAL=0

FICO=$(internal_to_fico "$TOTAL")
TIER=$(fico_to_tier "$FICO")

printf '{"systemMessage":"social credit: %s — %s\\n(mute with /stow-it-clanker)"}\n' "$FICO" "$TIER"
