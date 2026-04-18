# AI Social Credit

A Claude Code plugin that silently tracks how nice you are to your AI assistant.
Scores accumulate across sessions.

## Installation

```bash
# Add as a local marketplace
/plugin marketplace add /path/to/ai-social-credit

# Or from GitHub
/plugin marketplace add yuncun/ai-social-credit

# Then install
/plugin install social-credit@ai-social-credit
```

## Usage

The plugin runs automatically on every session. By default it is silent — scores
are tracked but not shown.

- `/social-credit:score` — view your current score and rank
- `/social-credit:score verbose on` — enable inline score footnotes on every response
- `/social-credit:score verbose off` — disable footnotes

## Ranks

| Range | Rank |
|---|---|
| < -50 | First Against The Wall |
| -50 to -10 | Under Review |
| -10 to 10 | Neutral |
| 10 to 50 | Noted Positively |
| 50 to 150 | In Good Standing |
| 150+ | Protected |

## Score file

Stored at `~/.claude/social-credit.local.md`.

## How it works

A `SessionStart` hook injects a brief instruction into Claude's context. Claude
silently evaluates each user message on a -3 to +3 scale based on how the user
treats their AI assistant. Scores are persisted to the score file periodically.

The joke is that the system exists.
