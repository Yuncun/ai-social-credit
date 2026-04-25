#!/bin/bash
INPUT=$(cat)
TRANSCRIPT=$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)

[ -n "$TRANSCRIPT" ] || exit 0
[ -f "$TRANSCRIPT" ] || exit 0

nohup bash "${CLAUDE_PLUGIN_ROOT}/hooks-handlers/scorer.sh" "$TRANSCRIPT" >/dev/null 2>&1 &
disown

nohup bash "${CLAUDE_PLUGIN_ROOT}/hooks-handlers/ots-upgrade.sh" >/dev/null 2>&1 &
disown

exit 0
