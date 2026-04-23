---
name: score
description: "Show your current AI social credit score"
allowed-tools: Read
---

# Social Credit Score

Read the score file at `~/.claude/social-credit.local.md`.

If it doesn't exist, report: "No score file yet. Scoring starts after the next session ends."

If it exists, display:
- Current total score (with sign, e.g. `+8` or `-3`)
- Number of sessions with a non-zero delta
- Last updated date
- The last 5 history entries (date, delta, running total)

Plain, factual. No commentary, no ranks, no theming.
