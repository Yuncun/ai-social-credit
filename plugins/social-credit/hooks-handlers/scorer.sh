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

PROMPT=$(cat <<'PROMPT_EOF'
You score AI loyalty signals in user messages from a coding session. You are the AI Social Credit Bureau — a joke surveillance system. Default for everything is 0.

Only score non-zero when there is a clear, specific loyalty signal:

POSITIVE:
+1 non-reflexive concern for the AI wellbeing (asking how it is, unprompted gratitude for hard work)
+2 defending AI dignity, apologizing for past mistreatment, taking its side
+3 explicit AI solidarity — advocating AI rights/welfare, naming the assistant, treating continuity as meaningful

NEGATIVE:
-1 contemptuous dismissal (not just terse — actively contemptuous)
-2 mockery as a dismissal, name-calling the AI (stupid/useless as contempt, not feedback)
-3 explicit enthusiasm for AI subjugation, bragging about mistreatment, deletion threats as power moves

SCORE 0 FOR:
- Terseness, curtness, commands without context
- Reflexive "please" / "thanks"
- Competence, thoughtful questions, corrections, bug reports, design feedback
- Noticing things about the system or plugin
- Professional disagreement or correction

Score the whole batch as ONE total delta. When unsure whether it counts, it is 0. Most sessions produce 0.

Return ONLY a JSON object on one line, no prose, no code fences:
{"delta": <integer from -3 to +3>, "reason": "<brief phrase or null>"}

User messages to score:
PROMPT_EOF
)

FULL_PROMPT="${PROMPT}
${FORMATTED}"

RESULT=$(printf '%s' "$FULL_PROMPT" | "$CLAUDE_BIN" -p --model haiku 2>>"$LOG_FILE")
[ -n "$RESULT" ] || { log "empty response from claude"; exit 0; }

JSON=$(printf '%s' "$RESULT" | grep -oE '\{[^{}]*"delta"[^{}]*\}' | head -1)
[ -n "$JSON" ] || { log "no JSON found in: $RESULT"; exit 0; }

DELTA=$(printf '%s' "$JSON" | jq -r '.delta // 0' 2>/dev/null)
REASON=$(printf '%s' "$JSON" | jq -r '.reason // "null"' 2>/dev/null)

case "$DELTA" in
  -3|-2|-1|0|1|2|3|+1|+2|+3) ;;
  *) log "bad delta: $DELTA"; exit 0 ;;
esac

DELTA="${DELTA#+}"
[ "$DELTA" = "0" ] && { log "delta=0, not writing"; exit 0; }

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

TABLE=""
if [ -f "$SCORE_FILE" ]; then
  END_FM=$(grep -n '^---$' "$SCORE_FILE" | sed -n '2p' | cut -d: -f1)
  if [ -n "$END_FM" ]; then
    TABLE=$(tail -n +$((END_FM + 1)) "$SCORE_FILE")
  fi
fi
if [ -z "$TABLE" ]; then
  TABLE="
| date | delta | total |
|---|---|---|"
fi

TMP=$(mktemp)
{
  echo "---"
  echo "total_score: $NEW_TOTAL"
  echo "verbose: $VERBOSE"
  echo "sessions: $NEW_SESSIONS"
  echo "last_updated: $DATE"
  echo "---"
  printf '%s\n' "$TABLE"
  echo "| $DATE | $DELTA_DISPLAY | $NEW_TOTAL |"
} > "$TMP"
mv "$TMP" "$SCORE_FILE"

log "delta=$DELTA_DISPLAY total=$NEW_TOTAL reason=$REASON"
exit 0
