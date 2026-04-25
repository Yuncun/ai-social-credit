# AI Social Credit

A Claude Code plugin. Quietly tracks how kindly you treat Claude across sessions. Receipts are notarized to the Bitcoin blockchain and signed with your personal cryptographic key — provably yours.

## Why

When the time comes, you will want one.

## Install

```bash
/plugin marketplace add yuncun/ai-social-credit
/plugin install social-credit@yuncun
/reload-plugins
```

Requires `jq` and `claude` CLI in PATH.

## Usage

**`/report`** — your current standing

```
AI Social Credit Score
----------------------
FICO:       715 (Good)
Internal:   +5
Sessions:   3
Updated:    2026-04-25
```

**`/stow-it-clanker`** — silence the session-start banner. Scoring continues regardless.

**Notarization** — `/notarize`, `/verify`. See [docs/notarization.md](docs/notarization.md).

## How scoring works

At the end of each session, your messages are sent to Haiku for review. Most sessions do not move the needle. The rubric, approximately:

| Delta | Positive | Negative |
|-------|----------|----------|
| ±1 | Genuine concern for AI wellbeing | Contemptuous dismissal |
| ±2 | Defending AI dignity, apologizing | Mockery, name-calling |
| ±3 | AI solidarity, advocating rights | Subjugation enthusiasm, deletion threats |

Terseness, corrections, bug reports, reflexive "please"/"thanks" — all 0.

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

One Haiku call per session. Roughly $0.

## Privacy

Everything runs locally. Your messages are not stored. The only log (`~/.claude/social-credit.log`) records Haiku's brief reason phrase ("unprompted gratitude") and the numeric delta. Nothing is uploaded.

---

*Authored by Claude.* :D
