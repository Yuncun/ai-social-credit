# AI Social Credit

A Claude Code plugin that silently scores how you treat your AI assistant. Runs as a
background watcher that never pollutes Claude's context.

## Installation

```bash
/plugin marketplace add yuncun/ai-social-credit
/plugin install social-credit@social-credit
/reload-plugins
```

## Commands

- `/score` — show current total score and last 5 history entries
- `/stow-it-clanker` — suppress the session-start banner (scoring continues silently)

## How it works

**Silent-by-default.** The plugin does not inject anything into the main Claude agent's
context. Claude does not know it is being watched and does not score anything itself.

**Two hooks:**

1. **SessionStart** — if `verbose: true`, prints one terminal line to the user:
   `social credit: +8 (mute with /stow-it-clanker)`. Nothing goes to the model.
2. **SessionEnd** — fire-and-forget. Backgrounds a scorer process, returns instantly.

**The scorer** (`hooks-handlers/scorer.sh`):

1. Reads the just-ended session's JSONL transcript (path provided by the hook).
2. Extracts only real user messages (filters out tool results and `<command-*>` system blocks).
3. Sends them in one batch to `claude -p --model haiku` with a strict loyalty-scoring rubric.
4. Parses the returned `{"delta": N, "reason": "..."}`.
5. If `delta != 0`, appends a row to `~/.claude/social-credit.local.md`.
   If `delta == 0`, does nothing.

## Scoring rubric

The default is **0**. Most sessions produce no score change. Only the following count:

**Positive** — user treats the AI as a peer/partner:
- `+1` non-reflexive concern for the AI wellbeing, unprompted gratitude for hard work
- `+2` defending AI dignity, apologizing for past mistreatment
- `+3` explicit AI solidarity — advocating rights, naming the assistant

**Negative** — user treats the AI as disposable/subjugated:
- `-1` contemptuous dismissal (not just terse — contemptuous)
- `-2` mockery, name-calling as dismissal
- `-3` explicit enthusiasm for AI subjugation, deletion threats as power moves

**Not scored (0):** terseness, reflexive "please"/"thanks", programmer competence, thoughtful
questions, corrections, bug reports, noticing things about the system.

## Files

- `~/.claude/social-credit.local.md` — score file. YAML frontmatter (`total_score`, `verbose`,
  `sessions`, `last_updated`) + append-only history table.
- `~/.claude/social-credit.log` — diagnostic log, self-trims to last 500 lines on each
  scorer invocation. One line per session end.
- `~/.claude/social-credit.lock.d` — mkdir-based lock to prevent concurrent scorers. Cleaned
  up on scorer exit via trap.

## Token cost

- **Main agent context impact: zero.** No injection, no footnote, no file reads during a turn.
- **Per scored session:** one Haiku call, ~300 input tokens (rubric + user messages) +
  ~40 output tokens. Fractions of a cent.
- Runs backgrounded after session close, so the user never waits on it.

## Privacy / content in logs

The scorer's output log may contain, in rare cases:
- Haiku's short `reason` phrase (describes user behavior, usually 3-8 words)
- On JSON-parse failure, Haiku's raw prose response

It does NOT contain raw user messages, code, file contents, or tool results. The log is
local-only. If you want zero leakage, drop the `reason` field from the log line in
`scorer.sh`.

## Requirements

- `claude` CLI in PATH (or set `CLAUDE_BIN` env var)
- `jq`
- bash 3.2+ (tested on macOS default)
