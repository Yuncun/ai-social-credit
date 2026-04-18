---
name: score
description: "Show your current AI social credit score"
allowed-tools: Read
---

# Social Credit Score

Read the score file at `~/.claude/social-credit.local.md`.

If it doesn't exist, report: "No score file found. The system is not yet tracking you."

If it exists, display:
- Current score and rank
- Number of sessions evaluated
- Last updated date
- The last 5 history entries (date, delta, running total)

Present this as a plain, factual summary. No commentary. No ceremony.
