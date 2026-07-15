#!/usr/bin/env bash
# check-doc-links.sh — verify internal markdown links resolve to existing files
set -euo pipefail

errors=0
for f in "$@"; do
  [ ! -f "$f" ] && continue
  while IFS= read -r link; do
    case "$link" in
      http*|mailto:*|"") continue ;;
      \#*) continue ;;
      /*) continue ;;
    esac
    target="$(dirname "$f")/$link"
    if [ ! -f "$target" ] && [ ! -d "$target" ]; then
      echo "Broken link: '$link' in $f"
      errors=1
    fi
  done < <(grep -oP '\[.*?\]\(\K[^)#:]+' "$f" 2>/dev/null || true)
done
exit $errors
