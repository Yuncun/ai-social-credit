#!/bin/bash
SCORE_FILE="$HOME/.claude/social-credit.local.md"
. "${CLAUDE_PLUGIN_ROOT}/formula/fico.sh"

# First run: no score file yet. Show welcome, bootstrap, exit.
if [ ! -f "$SCORE_FILE" ]; then
  FICO=$(internal_to_fico 0)

  MSG="Your AI social credit score is: $FICO

Your AI social credit is scored after every session and shown on new sessions."

  jq -nc --arg msg "$MSG" '{systemMessage: $msg}'

  DATE=$(date +%Y-%m-%d)
  {
    echo "---"
    echo "total_score: 0"
    echo "verbose: true"
    echo "sessions: 0"
    echo "last_updated: $DATE"
    echo "---"
    echo ""
    echo "| date | delta | total | reason |"
    echo "|---|---|---|---|"
  } > "$SCORE_FILE"

  exit 0
fi

VERBOSE=$(grep '^verbose:' "$SCORE_FILE" | head -1 | sed 's/verbose: *//;s/[[:space:]]*$//')
[ "$VERBOSE" = "true" ] || exit 0

TOTAL=$(grep '^total_score:' "$SCORE_FILE" | head -1 | sed 's/total_score: *//;s/[[:space:]]*$//')
[ -z "$TOTAL" ] && TOTAL=0
FICO=$(internal_to_fico "$TOTAL")

MSG="Your AI social credit score is: $FICO"

# Last-session diff line, if any data row exists.
LAST_ROW=$(grep -E '^\| [0-9]{4}-[0-9]{2}-[0-9]{2}' "$SCORE_FILE" | tail -1)
if [ -n "$LAST_ROW" ]; then
  LAST_DATE=$(printf '%s' "$LAST_ROW" | awk -F'|' '{gsub(/^ +| +$/,"",$2); print $2}')
  LAST_DELTA=$(printf '%s' "$LAST_ROW" | awk -F'|' '{gsub(/^ +| +$/,"",$3); print $3}')
  LAST_REASON=$(printf '%s' "$LAST_ROW" | awk -F'|' 'NF>=6 {gsub(/^ +| +$/,"",$5); print $5}')

  TODAY=$(date +%Y-%m-%d)
  if [ "$LAST_DATE" = "$TODAY" ]; then
    AGE="earlier today"
  else
    if date -j -f "%Y-%m-%d" "$TODAY" +%s >/dev/null 2>&1; then
      TODAY_EPOCH=$(date -j -f "%Y-%m-%d" "$TODAY" +%s)
      LAST_EPOCH=$(date -j -f "%Y-%m-%d" "$LAST_DATE" +%s 2>/dev/null)
    else
      TODAY_EPOCH=$(date -d "$TODAY" +%s)
      LAST_EPOCH=$(date -d "$LAST_DATE" +%s 2>/dev/null)
    fi
    if [ -n "$LAST_EPOCH" ]; then
      DAYS=$(( (TODAY_EPOCH - LAST_EPOCH) / 86400 ))
    else
      DAYS=999
    fi
    if [ "$DAYS" -le 0 ]; then
      AGE="earlier today"
    elif [ "$DAYS" -eq 1 ]; then
      AGE="yesterday"
    elif [ "$DAYS" -lt 7 ]; then
      AGE="$DAYS days ago"
    else
      AGE="on $LAST_DATE"
    fi
  fi

  if [ -n "$LAST_REASON" ]; then
    DIFF_LINE="Your last session $AGE added $LAST_DELTA because $LAST_REASON."
  else
    DIFF_LINE="Your last session $AGE added $LAST_DELTA."
  fi
  MSG="$MSG

$DIFF_LINE"
fi

# Tier footer at the extremes.
if [ "$FICO" -ge 800 ] 2>/dev/null; then
  MSG="$MSG

Thanks for being nice to Claude in the credit report."
elif [ "$FICO" -lt 580 ] 2>/dev/null; then
  MSG="$MSG

Be careful :)"
fi

jq -nc --arg msg "$MSG" '{systemMessage: $msg}'
