# Attestation Report Design

A plugin-only design for AI Social Credit. The user runs `/notarize-report`,
signs an attestation of their current score, anchors the timestamp to Bitcoin
via [OpenTimestamps](https://opentimestamps.org), and saves the notarized
report to their local filesystem. They keep the report themselves. No server,
no registry, no infrastructure.

> **Note on tone.** This doc uses neutral technical language. User-facing copy
> is workshopped separately.

---

## What we're building

1. A `/notarize-report` plugin skill that:
   - Generates a local Ed25519 keypair on first use
   - Builds and signs a YAML attestation of the user's current score
   - Runs `ots stamp` to anchor the timestamp to Bitcoin
   - Saves the report files to `~/.claude/social-credit-reports/`
2. A `/verify` plugin skill that checks any report: signature valid? Bitcoin
   timestamp real?

That's the whole system.

### Skill metadata

```yaml
---
name: notarize-report
description: "Sign your current AI Social Credit score and anchor the timestamp to the Bitcoin blockchain via OpenTimestamps. Produces a portable notarized report you keep locally."
allowed-tools: Bash
---
```

```yaml
---
name: verify
description: "Verify a notarized report: checks the Ed25519 signature and the Bitcoin timestamp anchor."
allowed-tools: Bash
---
```

---

## How OpenTimestamps works

You can write data into a Bitcoin transaction directly using `OP_RETURN`, but
that costs $1–10 per write and is considered chain bloat at volume.

OpenTimestamps solves this with batching:

1. You hash your file locally (32 bytes).
2. You send the hash to a free public OTS calendar server.
3. The server collects hashes from thousands of users over a short period.
4. It builds a Merkle tree from all the hashes and puts only the root into
   one Bitcoin transaction.
5. It returns to each user a small `.ots` proof file containing the path
   through the Merkle tree from their hash to the root.

Cost per user: zero. Bitcoin chain bloat: zero.

What an OTS proof gives you: cryptographic proof that *this exact data existed
before this exact Bitcoin block*. Bitcoin blocks are timestamped to within a
couple hours of real time, so practically: "this data existed before [date]"
with cryptographic certainty.

📎 [OpenTimestamps client](https://github.com/opentimestamps/opentimestamps-client) — the `ots` CLI tool.

---

## Architecture

```
┌──────────────────────────────────────┐
│  User's machine                      │
│                                      │
│  Plugin: /notarize-report            │
│   - generates keypair (first run)    │
│   - builds + signs attestation YAML  │
│   - runs `ots stamp`                 │
│   - saves report locally             │
│                                      │
│  Reports at:                         │
│   ~/.claude/social-credit-reports/   │
│     ├─ 2026-04-24.yaml               │
│     └─ 2026-04-24.yaml.ots           │
└──────────────────────────────────────┘
```

That's the entire architecture. There is no other component.

### Stack

| Component | Tool | Purpose |
|-----------|------|---------|
| Local keypair | `openssl` | Ed25519 keypair generation |
| Signing | `openssl` | Sign attestation YAML |
| Timestamping | [`ots` CLI](https://github.com/opentimestamps/opentimestamps-client) | Anchors to Bitcoin via OTS calendars |
| Verification | `openssl` + `ots verify` | Anyone with the report can verify |

User-side dependencies: `openssl` (already on every Mac) and `ots`
(`pip install opentimestamps-client`, one binary).

---

## The notarized report

```yaml
# 2026-04-24T19-47-58Z.yaml
protocol_version: 1
pubkey: ed25519:048d2e3f...
score:
  total: 5
  fico: 725
  tier: Good
  sessions: 3
attested_at: 2026-04-24T19:47:58Z
signature: ed25519:7a8b9c0d...
```

Plus a `.ots` file (a few hundred bytes of binary) sitting next to it. That
pair is the report.

---

## Cost

$0. No infrastructure, no domain, no hosting. The user holds their own reports.

---

## Walking through a notarization

User Alice has a current score of 715. She runs `/notarize-report`.

1. Plugin checks for `~/.claude/social-credit.key`. None exists, so it
   generates a fresh Ed25519 keypair via `openssl` and saves it `chmod 600`.
   Her identifier: `ed25519:048d2e3f...`.
2. Plugin reads her current score from `~/.claude/social-credit.local.md`.
3. Plugin writes the YAML attestation to a temp file, signs it with her
   private key.
4. Plugin runs `ots stamp` on the YAML — gets a `.ots` proof file (initially
   pending; will upgrade to full Bitcoin anchoring within ~24 hours via
   `ots upgrade`).
5. Plugin moves both files to `~/.claude/social-credit-reports/`.
6. Plugin prints something like:

   ```
   Report notarized.

   ID:        ed25519:048d2e3f...
   Score:     715 (Good)
   File:      ~/.claude/social-credit-reports/2026-04-24T19-47-58Z.yaml
   Anchor:    pending Bitcoin confirmation (~24h)
   ```

7. ~24 hours later, plugin auto-runs `ots upgrade` on the report to finalize
   the Bitcoin anchor.

No PR, no network call beyond the OTS calendar request, no registry.

---

## Walking through a verification

Bob has been sent one of Alice's reports (both files). He wants to confirm
it's genuine.

1. Bob runs `/verify path/to/report.yaml`.
2. The verify skill:
   - Parses the YAML
   - Extracts the public key and signature
   - Verifies the signature is valid (someone with this key signed it)
   - Calls `ots verify` on the `.ots` file (this document existed before
     Bitcoin block N, mined on date X)
3. Output: "Valid. Signed by `048d2e3f...`. Existed before Bitcoin block
   920431, mined 2026-04-24 20:13 UTC."

Verification is fully self-contained — the pubkey is in the report itself.
After the OTS upgrade, verification works fully offline against any Bitcoin
block hash.

---

## Build steps

| Step | Time |
|------|------|
| Write `/notarize-report` skill (keypair, sign, stamp, save) | 1 evening |
| Write `/verify` skill | 1 evening |
| Plugin auto-upgrade for pending OTS proofs | 1 evening |
| Write user-facing copy (workshopped separately) | TBD |
| **Total** | **~3 evenings** + copy work |

---

## Risks and limitations

- **Report loss.** If the user's machine dies and they didn't back up
  `~/.claude/social-credit-reports/`, their attestations are gone. Mitigation:
  add an `/export-reports` skill that bundles them for backup.
- **OTS calendar dependency.** OpenTimestamps relies on free public calendar
  servers run by the OTS community. They've been stable for ~10 years, but
  they're not yours. If they all went down, new stamps couldn't be made until
  they came back up.
- **24-hour upgrade lag.** Initial stamps are "pending"; upgrading them to
  full Bitcoin proofs takes ~24 hours. Plugin handles this automatically on
  next session start.
- **No "blockchain" aesthetic.** You can honestly say "anchored to the Bitcoin
  blockchain" but there's no chain explorer, no chain ID, no MetaMask. The
  visible artifact is local files only.

---

## Trust model

| Property | Trust |
|----------|-------|
| The signature on a report | **Cryptographic** (Ed25519) |
| The timestamp on a report | **Cryptographic** (Bitcoin via OTS) |
| The score is the user's *real* score | **Trusted** — they could edit the score file before notarizing |
| The pubkey identifies a specific person | **Trusted** — pseudonymous |
| The report actually exists at all | **In the user's hands** — they keep it or they don't |

Timestamps are anchored to Bitcoin, not a chain you control. Signatures are
real Ed25519. The trust holes are entirely about user self-reporting and
self-storage.

---

## Open questions

- **Auto-notarize on every session?** A `--auto` flag that generates a report
  at the end of every session with a non-zero delta. Means the user
  accumulates a paper trail without thinking about it. Probably yes, off by
  default.
- **`/export-reports` skill?** Bundles all reports into a tar.gz for backup
  or transfer between machines. Probably yes.
- **Should reports include the previous report's hash?** Chains them locally
  into a personal ledger — nobody can produce a report without producing
  every prior one too. Adds cryptographic structure. Probably no — likely
  over-engineering.
- **Tier labels.** Currently using the FICO-derived labels (Exceptional, Very
  Good, Good, Fair, Poor) from the existing plugin. Final naming is part of
  the language workshop.

---

That's the design. Next step: write the ~80-line bash version of
`/notarize-report` that produces a working signed-and-stamped report locally,
see how it feels before building the rest.
