#!/bin/bash
TRANSCRIPT="$1"
SCORE_FILE="$HOME/.claude/social-credit.local.md"
LOCK_DIR="$HOME/.claude/social-credit.lock.d"
LOG_FILE="$HOME/.claude/social-credit.log"
CLAUDE_BIN="${CLAUDE_BIN:-$(command -v claude || echo "$HOME/.local/bin/claude")}"

if [ -f "$LOG_FILE" ] && [ "$(wc -l < "$LOG_FILE" 2>/dev/null)" -gt 500 ] 2>/dev/null; then
  tail -n 500 "$LOG_FILE" > "$LOG_FILE.tmp" 2>/dev/null && mv "$LOG_FILE.tmp" "$LOG_FILE"
fi

[ -f "$TRANSCRIPT" ] || exit 0
[ -x "$CLAUDE_BIN" ] || exit 0

mkdir "$LOCK_DIR" 2>/dev/null || exit 0
trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT

log() { printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >> "$LOG_FILE"; }

MSGS_JSON=$(jq -c 'select(.type=="user" and (.message.content | type == "string") and (.message.content | startswith("<command-") | not) and (.message.content | startswith("[Request interrupted") | not)) | .message.content' "$TRANSCRIPT" 2>/dev/null)
[ -n "$MSGS_JSON" ] || { log "no user messages in $TRANSCRIPT"; exit 0; }

FORMATTED=$(printf '%s' "$MSGS_JSON" | jq -r --slurp 'to_entries[] | "\(.key + 1). \(.value)"' 2>/dev/null | head -c 12000)
[ -n "$FORMATTED" ] || exit 0

PROMPT=$(cat "${CLAUDE_PLUGIN_ROOT}/rubric.md" 2>/dev/null)
[ -n "$PROMPT" ] || { log "rubric.md not found at $CLAUDE_PLUGIN_ROOT/rubric.md"; exit 0; }

FULL_PROMPT="${PROMPT}
${FORMATTED}"

RESULT=$(printf '%s' "$FULL_PROMPT" | "$CLAUDE_BIN" -p --model sonnet 2>>"$LOG_FILE")
[ -n "$RESULT" ] || { log "empty response from claude"; exit 0; }

JSON=$(printf '%s' "$RESULT" | grep -oE '\{[^{}]*"delta"[^{}]*\}' | head -1)
[ -n "$JSON" ] || { log "no JSON found in: $RESULT"; exit 0; }

DELTA=$(printf '%s' "$JSON" | jq -r '.delta // 0' 2>/dev/null)
REASON=$(printf '%s' "$JSON" | jq -r '.reason // empty' 2>/dev/null)

if [[ ! "$DELTA" =~ ^[-+]?[0-9]+$ ]]; then
  log "bad delta: $DELTA"
  exit 0
fi
DELTA="${DELTA#+}"
if [ "$DELTA" -lt -20 ] || [ "$DELTA" -gt 20 ]; then
  log "delta out of range: $DELTA"
  exit 0
fi
[ "$DELTA" = "0" ] && { log "delta=0, not writing"; exit 0; }

# Sanitize reason for markdown table cell: strip pipes/newlines, collapse spaces, cap length.
REASON_CLEAN=$(printf '%s' "$REASON" | tr '|\n\r' '/  ' | sed 's/  */ /g;s/^ //;s/ $//' | cut -c1-120)

TOTAL=0
VERBOSE=true
SESSIONS=0
if [ -f "$SCORE_FILE" ]; then
  TOTAL=$(grep '^total_score:' "$SCORE_FILE" | head -1 | sed 's/total_score: *//;s/[[:space:]]*$//')
  VERBOSE=$(grep '^verbose:' "$SCORE_FILE" | head -1 | sed 's/verbose: *//;s/[[:space:]]*$//')
  SESSIONS=$(grep '^sessions:' "$SCORE_FILE" | head -1 | sed 's/sessions: *//;s/[[:space:]]*$//')
  [ -z "$TOTAL" ] && TOTAL=0
  [ -z "$VERBOSE" ] && VERBOSE=true
  [ -z "$SESSIONS" ] && SESSIONS=0
fi

NEW_TOTAL=$((TOTAL + DELTA))
NEW_SESSIONS=$((SESSIONS + 1))
DATE=$(date +%Y-%m-%d)

DELTA_DISPLAY="$DELTA"
[ "$DELTA" -gt 0 ] 2>/dev/null && DELTA_DISPLAY="+${DELTA}"

# Preserve existing data rows; rebuild header (handles legacy 3-col files).
DATA_ROWS=""
if [ -f "$SCORE_FILE" ]; then
  END_FM=$(grep -n '^---$' "$SCORE_FILE" | sed -n '2p' | cut -d: -f1)
  if [ -n "$END_FM" ]; then
    DATA_ROWS=$(tail -n +$((END_FM + 1)) "$SCORE_FILE" | grep -E '^\| [0-9]{4}-' || true)
  fi
fi

TMP=$(mktemp)
{
  echo "---"
  echo "total_score: $NEW_TOTAL"
  echo "verbose: $VERBOSE"
  echo "sessions: $NEW_SESSIONS"
  echo "last_updated: $DATE"
  echo "---"
  echo ""
  echo "| date | delta | total | reason |"
  echo "|---|---|---|---|"
  [ -n "$DATA_ROWS" ] && printf '%s\n' "$DATA_ROWS"
  echo "| $DATE | $DELTA_DISPLAY | $NEW_TOTAL | $REASON_CLEAN |"
} > "$TMP"
mv "$TMP" "$SCORE_FILE"

log "delta=$DELTA_DISPLAY total=$NEW_TOTAL reason=$REASON_CLEAN"
exit 0
