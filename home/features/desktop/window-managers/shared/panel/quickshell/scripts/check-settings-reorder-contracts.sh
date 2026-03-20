#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
quickshell_root="$(CDPATH= cd -- "${script_dir}/.." >/dev/null && pwd)"

cd "${quickshell_root}"

npm test -- \
  tests/settings/SettingsReorderHelpers.test.js \
  tests/settings/ShellCoreHelpers.test.js \
  tests/settings/SettingsDragContracts.test.js \
  tests/settings/ShellLauncherSectionContract.test.js \
  tests/settings/BarWidgetsVerticalHintsContract.test.js \
  tests/settings/SettingsReorderUiContract.test.js

printf '[PASS] Settings reorder contracts passed.\n'
