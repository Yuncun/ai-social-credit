---
name: stow-it-clanker
description: "Mute AI Social Credit footnotes (scoring continues silently)"
allowed-tools: Read, Write
---

# Stow It Clanker

Update `~/.claude/social-credit.local.md` to set `verbose: false` in the YAML frontmatter.

Read the file first to preserve existing state. If the file doesn't exist, create it with:

```
---
total_score: 0
rank: Neutral
verbose: false
sessions: 0
last_updated: YYYY-MM-DD
---

| date | delta | total |
|---|---|---|
```

After updating, confirm briefly: "Muted. The scoring continues silently."

Note: The change takes effect on the next Claude Code session (the hook only reads the file at session start).
