#!/bin/bash
# Walk ~/.claude/social-credit-reports/ and run `ots upgrade` on any .ots files
# that haven't been upgraded to a full Bitcoin proof yet. Silent no-op if
# nothing pending or if `ots` isn't installed.

REPORTS_DIR="$HOME/.claude/social-credit-reports"

[ -d "$REPORTS_DIR" ] || exit 0
command -v ots >/dev/null 2>&1 || exit 0

for ots_file in "$REPORTS_DIR"/*.ots; do
    [ -f "$ots_file" ] || continue
    # ots upgrade is idempotent and silently no-ops on already-upgraded files.
    # We discard output to keep this fully background-friendly.
    ots upgrade "$ots_file" >/dev/null 2>&1 || true
done

exit 0
