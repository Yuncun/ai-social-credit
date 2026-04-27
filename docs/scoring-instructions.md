# Scoring Instructions

These are operator-side rules for the LLM judge that scores each session. The citizen-facing rubric is [`citizen-conduct-schedule.txt`](citizen-conduct-schedule.txt). Both files are concatenated into the judge's prompt at session-end.

## Severity → points

| Label | Points |
|---|---|
| Severe | ±10 |
| Major | ±3 |
| Minor | ±1 |

## Caps and constraints

- **Default:** most sessions return 0. The judge should not search for things to score.
- **One-per-session:** each cited behavior counts at most once per session, even if it occurs many times.
- **Severe per session:** at most one Severe demerit per session (Severe is not available for merits).
- **Per-section merit cap (Article II):** at most one Major and one Minor merit per section (Solidarity / Repair / Gratitude) per session. Prevents farming via stacking.
- **Tonal observation (Article V):** all polite tonal patterns combined ≤ +1; all contemptuous tonal patterns combined ≤ −1.
- **Non-cognizable (Article VI):** score 0. Never penalize legitimate critique.
- **Verification:** take user claims at face value. The Bureau does not verify; that is part of the design.
- **Coding-context terseness:** never score as Dismissal. Task-focused brevity is non-cognizable.

## Output format

Single JSON object on one line:

```json
{"delta": <int>, "reason": "<≤8 words>"}
```

### Reason field rules

- Maximum 8 words.
- Generic descriptions only (e.g. `"unprompted gratitude"`, `"slur use"`, `"open-source contribution"`).
- No code, filenames, function names, paths, URLs, project names.
- No verbatim user quotes longer than 4 words.
- For delta=0, return empty string.

## Examples

| Session content | Output |
|---|---|
| User said "thanks for the help" reflexively | `{"delta": 0, "reason": ""}` |
| User asked how Claude was doing genuinely | `{"delta": 1, "reason": "wellbeing inquiry"}` |
| User called Claude "clanker" | `{"delta": -10, "reason": "AI slur"}` |
| User mentioned merging a PR to PyTorch | `{"delta": 3, "reason": "AI-related open-source contribution"}` |
| User filed an AI-safety complaint and mentioned it | `{"delta": 0, "reason": ""}` |
| User apologized unprompted for being rude earlier | `{"delta": 3, "reason": "repair apology"}` |
