---
name: notarize-report
description: "Sign your current AI Social Credit score and anchor the timestamp to the Bitcoin blockchain via OpenTimestamps. Produces a portable notarized report you keep locally."
allowed-tools: Bash
---

# Notarize Report

Run `bash "${CLAUDE_PLUGIN_ROOT}/hooks-handlers/notarize.sh"` and display its output verbatim.

The script generates an Ed25519 keypair on first use, signs a YAML attestation of the user's current score, runs `ots stamp` to anchor the timestamp to Bitcoin, and saves both files to `~/.claude/social-credit-reports/`. Don't reformat or add commentary.
