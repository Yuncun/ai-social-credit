# Notarization

The plugin can produce a cryptographically-signed, Bitcoin-anchored receipt of
your current score. There's no central registry — the reports are yours to keep.

## Setup

Notarization needs the [OpenTimestamps client](https://github.com/opentimestamps/opentimestamps-client)
in your PATH:

```bash
pipx install opentimestamps-client
# or: pip install --user opentimestamps-client
```

`openssl` is also required but ships with macOS.

## Commands

### `/notarize-report`

Generates a Bitcoin-anchored notarized report of your current score.

On first use, generates an Ed25519 keypair at `~/.claude/social-credit.key` (chmod
600) and `~/.claude/social-credit.pub`. Then on every run:

1. Reads your current score from `~/.claude/social-credit.local.md`
2. Signs a YAML attestation with your private key
3. Anchors the timestamp to Bitcoin via OpenTimestamps
4. Saves both files to `~/.claude/social-credit-reports/<timestamp>.yaml{,.ots}`

Output looks like:

```
Report notarized.

ID:        ed25519:68fb0d00...
Score:     715 (Good)
Internal:  5
Sessions:  3
File:      ~/.claude/social-credit-reports/2026-04-25T06-12-13Z.yaml
Anchor:    pending Bitcoin confirmation (~24h)
```

The Bitcoin anchor is initially "pending" — OpenTimestamps batches thousands of
hashes into one Bitcoin transaction every few minutes, but it takes ~24 hours
for the transaction to be confirmed deeply enough to verify against. The
session-end hook auto-upgrades pending proofs in the background, so you don't
have to do anything.

### `/verify <path>`

Verifies a notarized report's signature and Bitcoin timestamp.

```
Report:      /path/to/report.yaml
Signed by:   ed25519:68fb0d00...
Signature:   VALID
Timestamp:   PENDING
             Stamp not yet confirmed by Bitcoin (~24h after stamping).

--- Attested score ---
score:
  total: 5
  fico: 715
  tier: Good
  sessions: 3
attested_at: 2026-04-25T06:12:13Z
```

After Bitcoin confirms the stamp, `Timestamp` becomes `VALID` and shows the
exact Bitcoin block + date.

### `/export-reports`

Bundles your reports + signing key + score file into a tar.gz at
`~/social-credit-export-<timestamp>.tar.gz` for backup or transfer to another
machine.

To restore:

```bash
tar -xzf social-credit-export-<timestamp>.tar.gz -C ~
```

## How it works

Each report contains:

```yaml
protocol_version: 1
pubkey: ed25519:68fb0d00...
score:
  total: 5
  fico: 715
  tier: Good
  sessions: 3
attested_at: 2026-04-25T06:12:13Z
signature: ed25519:f6e1df1f...
```

Plus a `.ots` proof file (a few hundred bytes of binary) that anchors the
report's hash to a specific Bitcoin block.

**Signature** is Ed25519 over the YAML body (everything except the `signature`
line). Anyone with the report can verify it without contacting any server.

**Timestamp** uses OpenTimestamps, which batches thousands of users' hashes into
one Bitcoin transaction (so it's free to use and doesn't bloat the chain). The
proof shows that the report's exact bytes existed before a specific Bitcoin
block was mined.

## Trust model

| Property | Trust |
|----------|-------|
| The signature on a report | Cryptographically guaranteed (Ed25519) |
| The timestamp on a report | Cryptographically guaranteed (Bitcoin via OTS) |
| The score is your *real* score | Trusted — you could edit the score file before notarizing |
| The pubkey identifies you | Trusted — pseudonymous unless you publicly claim it |

You could lie about your score. But who lies *down*?

## Sharing a report

Send someone both files (`<timestamp>.yaml` and `<timestamp>.yaml.ots`) and they
can run `/verify` on the YAML file to confirm:

- The signature is valid (you signed it with the key you control)
- The timestamp is real (anchored to a specific Bitcoin block)
- The score block is what you claimed

There's no Bureau in the cloud. There's no leaderboard. There's just receipts.
