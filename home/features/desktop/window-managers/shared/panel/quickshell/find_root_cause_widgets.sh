#!/usr/bin/env bash
set -euo pipefail

widgets_dir="./config/widgets"
for file in "${widgets_dir}"/*.qml; do
  echo "Checking $(basename "$file")..."
  QT_QPA_PLATFORM=offscreen timeout 3s quickshell -p "$file" >"check_$(basename "$file").log" 2>&1 || true
  if grep -E "ERROR:   caused by .*:[0-9]+:[0-9]+\]: .* (is not a type|unavailable)" "check_$(basename "$file").log" >/dev/null; then
    # It's an unavailable/not a type error, might be secondary
    echo "  (Secondary error?)"
  elif grep "ERROR" "check_$(basename "$file").log" >/dev/null; then
    echo "  SPECIFIC ERROR found in $(basename "$file"):"
    grep "ERROR" "check_$(basename "$file").log"
    # head -n 20 "check_$(basename "$file").log"
  fi
  rm -f "check_$(basename "$file").log"
done
