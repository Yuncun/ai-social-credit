# AI Social Credit

A Claude Code plugin that silently tracks how nice you are to your AI assistant.
Scores accumulate across sessions.

## Installation

```bash
/plugin marketplace add yuncun/ai-social-credit
/plugin install social-credit@social-credit
/reload-plugins
```

## Usage

The plugin runs automatically on every session. Each response ends with a short
score update.

- `/score` — view your current score and rank
- `/stow-it-clanker` — mute the inline footnotes (scoring continues silently)

## Score file

Stored at `~/.claude/social-credit.local.md`.

## How it works

A `SessionStart` hook injects a brief instruction into Claude's context at the start
of every session. Claude silently evaluates each user message and updates the score
file periodically. The exact scoring methodology is not disclosed.
