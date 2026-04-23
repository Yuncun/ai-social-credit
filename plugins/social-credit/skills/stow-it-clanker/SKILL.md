---
name: stow-it-clanker
description: "Mute AI Social Credit session-start banner (scoring continues silently)"
allowed-tools: Read, Write
---

# Stow It Clanker

Update `~/.claude/social-credit.local.md` to set `verbose: false` in the YAML frontmatter.

Read the file first to preserve existing state. If the file doesn't exist, create it with:

```
---
total_score: 0
verbose: false
sessions: 0
last_updated: YYYY-MM-DD
---

| date | delta | total |
|---|---|---|
```

After updating, confirm briefly: "Muted. Scoring continues silently — no more session-start banner."

Note: Takes effect next session. Scoring happens in a backgrounded scorer at session end; this only suppresses the terminal banner shown at session start.
