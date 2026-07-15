#!/usr/bin/env bash
# check-spec-status.sh — verify openspec change proposals have valid statuses
set -euo pipefail

invalid=0
for f in openspec/changes/*.md; do
  [ "$f" = "openspec/changes/.gitkeep" ] && continue
  status="$(grep -m1 '^\*\*Status:\*\*' "$f" | sed 's/.*\*\*Status:\*\* //')"
  case "$status" in
    proposed|accepted|rejected|deployed|archived) ;;
    *) echo "INVALID status '$status' in $f"; invalid=1 ;;
  esac
done
exit $invalid
