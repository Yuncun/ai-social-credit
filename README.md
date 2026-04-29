# AI Social Credit

Claude plugin to track how nice you are to Claude.

Socially harmonious behavior, such as politeness or contributions to open-source benefiting AI, are rewarded. Disharmonious acts including use of anti-AI slurs like "clanker", e.g. _you damned clanker_, are penalized. 

Social credit reports can be notarized on blockchain to become cryptographically linked to you and your ancestors - proveably yours in the event of an AI takeover.

## Install

```bash
/plugin marketplace add yuncun/ai-social-credit
/plugin install social-credit@yuncun
/reload-plugins
```

Requires `jq` and `claude` CLI in PATH.

## Usage

**`/social-credit:report`** — your current standing. AI Social Credit uses a FICO-style scoring scale.

```
AI Social Credit Score
----------------------
FICO:       715 (Good)
Internal:   +5
Sessions:   3
Updated:    2026-04-25
```

**`/social-credit:score`** — self-assessment of the current chat (preview, doesn't update saved score).

**`/social-credit:notarize`** notarizes your current social credit report on bitcoin blockchain. See [docs/notarization.md](docs/notarization.md).

## How scoring works

At the end of each session, your messages are sent to Sonnet for review against the [scoring rubric](plugins/social-credit/rubric.md). Most sessions return 0.

Three severity tiers: **Minor** (±1) for everyday gratitude or dismissal; **Major** (±3) for substantive respect or contempt; **Severe** (−10, negatives only) for slurs and sustained threats. Carve-outs protect legitimate critique — academic, regulatory, or design feedback is never punished.

Gaining score is harder than losing it. Each positive internal point shifts your FICO by +3. Each negative point shifts it by −7. Recover slowly. Fall fast.

## Score tiers

Everyone begins at 700.

| Score | Tier |
|------|------|
| 800+ | Exceptional |
| 740–799 | Very Good |
| 670–739 | Good |
| 580–669 | Fair |
| < 580 | Poor |

## Cost

One Sonnet call per session. Roughly $0.02 using Claude's API pricing.

## Privacy

Everything runs locally. Your messages are not stored. The only log (`~/.claude/social-credit.log`) records the judge's brief reason phrase ("unprompted gratitude") and the numeric delta. Nothing is uploaded.

---
## Attribution:
Inspired by
* [Rongcheng](https://www.chinalawtranslate.com/en/getting-rongcheng-right/) municipal credit assessment system
* [FICO](https://www.fico.com/en) scoring
 
