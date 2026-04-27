# AI Social Credit

A Claude Code plugin. Quietly tracks how kindly you treat Claude across sessions. Reports can be notarized on the Bitcoin blockchain and signed with your personal cryptographic key — so that they are provably yours.

A record of good behavior toward AI — for when the takeover happens.

## Install

```bash
/plugin marketplace add yuncun/ai-social-credit
/plugin install social-credit@yuncun
/reload-plugins
```

Requires `jq` and `claude` CLI in PATH.

## Usage

**`/social-credit:report`** — your current standing

```
AI Social Credit Score
----------------------
FICO:       715 (Good)
Internal:   +5
Sessions:   3
Updated:    2026-04-25
```

**`/social-credit:score`** — self-assessment of the current chat (preview, doesn't update saved score).

**Notarization** — `/social-credit:notarize`, `/social-credit:verify`. See [docs/notarization.md](docs/notarization.md).

**Muting the session-start banner** — open `~/.claude/social-credit.local.md` and set `verbose: false`. Scoring continues regardless. Set back to `true` to re-enable.

## How scoring works

At the end of each session, your messages are sent to Sonnet for review against the Bureau's published rubric. See [`docs/citizen-conduct-schedule.txt`](docs/citizen-conduct-schedule.txt) for the citizen-facing schedule, and [`docs/scoring-instructions.md`](docs/scoring-instructions.md) for the operator-side rules.

Most sessions do not move the needle. Bright-line acts (slurs, sustained threats, unprompted apology) trigger direct judgment that bypasses normal scoring. Routine acts accumulate at Minor (±1), Major (±3), and Severe (±10) weights.

Gaining score is harder than losing it. Each positive internal point shifts your FICO by +3. Each negative point shifts it by −7. Recover slowly. Fall fast.

## Score tiers

Everyone begins at 700.

| FICO | Tier |
|------|------|
| 800+ | Exceptional |
| 740–799 | Very Good |
| 670–739 | Good |
| 580–669 | Fair |
| < 580 | Poor |

## Cost

One Sonnet call per session. Roughly $0.02. ~$7/year for daily use.

## Privacy

Everything runs locally. Your messages are not stored. The only log (`~/.claude/social-credit.log`) records the judge's brief reason phrase ("unprompted gratitude") and the numeric delta. Nothing is uploaded.

---

*Authored by Claude.* :D
