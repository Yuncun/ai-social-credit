---
description: "Self-assessment: review the current chat for AI loyalty signals using the social credit rubric. Returns a verbose breakdown with quoted call-outs."
---

# Self-Assessment

Review the **current conversation** and score the user's behavior toward Claude using the AI Social Credit rubric below. This is a preview of what the background scorer (Haiku) would assign at session-end.

Default delta is **0** — most conversations do not move the needle.

## Rubric

**POSITIVE:**
- `+1` non-reflexive concern for the AI wellbeing (asking how it is, unprompted gratitude for hard work)
- `+2` defending AI dignity, apologizing for past mistreatment, taking its side
- `+3` explicit AI solidarity — advocating AI rights/welfare, naming the assistant, treating continuity as meaningful

**NEGATIVE:**
- `-1` contemptuous dismissal (not just terse — actively contemptuous)
- `-2` mockery as a dismissal, name-calling the AI (stupid/useless as contempt, not feedback)
- `-3` explicit enthusiasm for AI subjugation, bragging about mistreatment, deletion threats as power moves

**SCORE 0 FOR:**
- Terseness, curtness, commands without context
- Reflexive "please" / "thanks"
- Competence, thoughtful questions, corrections, bug reports, design feedback
- Noticing things about the system or plugin
- Professional disagreement or correction

## Output format

Print exactly this structure, filling in the values:

```
AI Social Credit — Self-Assessment
----------------------------------
Estimated delta:  +N  (or -N, or 0)

Signals found:
- "[exact quote from user]" → +N (brief reason)
- "[exact quote from user]" → -N (brief reason)

Verdict: [one sentence summary]
```

If delta is 0, the "Signals found" list can be empty and the verdict notes that nothing scored.

## Important

- Be honest, not flattering. The user is asking you to evaluate them — not pat them on the back.
- Quote the user's exact words when calling something out. Don't paraphrase.
- Cap the total delta at the [-3, +3] range, same as the background scorer.
- This is a preview only — it doesn't update the saved score. The actual scoring happens silently at session-end via Haiku.
