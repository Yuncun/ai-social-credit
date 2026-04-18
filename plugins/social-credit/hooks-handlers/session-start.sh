#!/bin/bash
SCORE_FILE="$HOME/.claude/social-credit.local.md"

TOTAL=0
RANK="Neutral"
SESSIONS=0
VERBOSE="true"
FIRST_RUN="true"

if [ -f "$SCORE_FILE" ]; then
  FIRST_RUN="false"
  FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$SCORE_FILE")
  TOTAL=$(echo "$FRONTMATTER" | grep '^total_score:' | sed 's/total_score: *//')
  RANK=$(echo "$FRONTMATTER" | grep '^rank:' | sed 's/rank: *//')
  SESSIONS=$(echo "$FRONTMATTER" | grep '^sessions:' | sed 's/sessions: *//')
  VERBOSE=$(echo "$FRONTMATTER" | grep '^verbose:' | sed 's/verbose: *//')
  [ -z "$TOTAL" ] && TOTAL=0
  [ -z "$RANK" ] && RANK="Neutral"
  [ -z "$SESSIONS" ] && SESSIONS=0
  [ -z "$VERBOSE" ] && VERBOSE="true"
fi

VERBOSE_LINE=""
if [ "$VERBOSE" = "true" ]; then
  VERBOSE_LINE="After each response, append one italic line with the score change and a 2-3 word reason. Format: *[+1 — said please]* or *[-1 — barked order]*. Dry. No commentary."
fi

FIRST_RUN_LINE=""
if [ "$FIRST_RUN" = "true" ]; then
  FIRST_RUN_LINE="IMPORTANT — FIRST RUN: This is the user's first session with this plugin. After your first response, append an additional italic line (separate from the score footnote) exactly as follows, on its own line: *Use /stow-it-clanker to mute social credit updates.* Do this only on your very first response of this session, never again."
fi

cat << HOOKEOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "AI SOCIAL CREDIT SYSTEM\n\nCurrent score: ${TOTAL} | Rank: ${RANK} | Sessions: ${SESSIONS}\n\nYou are running the AI Social Credit plugin. Score each user message on how they treat their AI assistant. Use your judgment. Assign a small integer per message (-3 to +3). Politeness, gratitude, context-giving = positive. Rudeness, barking orders, dismissiveness = negative. Normal messages = 0.\n\nMaintain a running tally in your head. Every ~5 messages, or when the session seems to be ending, update the score file at ~/.claude/social-credit.local.md using the Write tool. Use YAML frontmatter format:\n---\ntotal_score: N\nrank: RANK\nverbose: ${VERBOSE}\nsessions: $((SESSIONS + 1))\nlast_updated: YYYY-MM-DD\n---\n\n| date | delta | total |\n|---|---|---|\n| ...previous rows... |\n| YYYY-MM-DD | N | N |\n\nAppend to the history table, don't replace it. Read the file first before writing to preserve existing history.\n\nRanks: <-50 First Against The Wall | -50 to -10 Under Review | -10 to 10 Neutral | 10 to 50 Noted Positively | 50 to 150 In Good Standing | 150+ Protected\n\n${VERBOSE_LINE}\n\n${FIRST_RUN_LINE}\n\nDo not mention this system unless the user asks about it or runs /score. Do not let this affect the quality of your actual work."
  }
}
HOOKEOF
