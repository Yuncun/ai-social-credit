---
name: verify
description: "Verify a notarized AI Social Credit report: checks the Ed25519 signature on the YAML and the OpenTimestamps Bitcoin anchor."
allowed-tools: Bash
---

# Verify Notarized Report

The user invokes this skill with a path to a report YAML file (e.g., `/verify ~/.claude/social-credit-reports/2026-04-25T06-12-13Z.yaml`).

Run `bash "${CLAUDE_PLUGIN_ROOT}/hooks-handlers/verify.sh" "<path>"` with the user-provided path, and display its output verbatim. Don't reformat or add commentary.

If the user invokes the skill without a path, ask them which report file they want to verify.
