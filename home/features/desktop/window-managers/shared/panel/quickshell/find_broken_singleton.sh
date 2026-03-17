#!/usr/bin/env bash
set -euo pipefail

services_dir="./config/services"
# Get all singletons from qmldir
singletons=$(grep "singleton" "${services_dir}/qmldir" | awk '{print $2}')

for name in $singletons; do
  echo "Checking singleton $name..."
  cat > "test_$name.qml" <<EOF
import QtQuick
import "config/services"
Item {
  Component.onCompleted: console.log("Successfully accessed $name: " + $name)
}
EOF
  QT_QPA_PLATFORM=offscreen timeout 5s quickshell -p "test_$name.qml" >"check_$name.log" 2>&1 || true
  if grep "ERROR" "check_$name.log" >/dev/null; then
    echo "  FAILED to access $name:"
    grep "ERROR" "check_$name.log" | head -n 5
  else
    echo "  $name OK"
  fi
  rm -f "test_$name.qml" "check_$name.log"
done
