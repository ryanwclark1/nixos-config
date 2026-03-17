#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
repo_root="$(CDPATH= cd -- "${script_dir}/.." >/dev/null && pwd)"

pass_count=0
fail_count=0

pass() {
  printf '[PASS] %s\n' "$1"
  pass_count=$((pass_count + 1))
}

fail() {
  printf '[FAIL] %s\n' "$1" >&2
  fail_count=$((fail_count + 1))
}

require_literal() {
  local file="$1"
  local literal="$2"
  local label="$3"
  if rg -Fq -- "$literal" "$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

require_pattern() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  if rg -Uq --multiline -- "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

bar_registry="${repo_root}/src/services/BarWidgetRegistry.qml"
panel_qml="${repo_root}/src/bar/Panel.qml"
surface_service_qml="${repo_root}/src/services/SurfaceService.qml"
shell_qml="${repo_root}/src/shell.qml"
shell_bar_layer_qml="${repo_root}/src/shell/ShellBarLayer.qml"
menu_qmldir="${repo_root}/src/menu/qmldir"
widget_qmldir="${repo_root}/src/widgets/qmldir"
network_service_qml="${repo_root}/src/services/NetworkService.qml"
vpn_menu_qml="${repo_root}/src/features/network/VpnMenu.qml"
network_menu_qml="${repo_root}/src/features/network/NetworkMenu.qml"

require_literal "$bar_registry" 'widgetType: "vpn"' "VPN widget is registered in BarWidgetRegistry"
require_literal "$bar_registry" 'key: "labelMode"' "VPN widget exposes labelMode setting"
require_literal "$bar_registry" 'key: "showOtherVpnCount"' "VPN widget exposes overlay count setting"
require_pattern "$panel_qml" 'if \(widgetType === "vpn"\)\s+return vpnComponent;' "Panel dispatch resolves the vpn widget component"
require_literal "$panel_qml" 'root.requestSurface("vpnMenu", this)' "VPN widget opens the vpnMenu surface"
require_literal "$surface_service_qml" 'vpnMenu: {' "SurfaceService registers vpnMenu"
require_literal "$shell_qml" 'readonly property bool vpnMenuVisible: root.isSurfaceOpen("vpnMenu")' "shell.qml exposes vpnMenu visibility"
require_literal "$shell_bar_layer_qml" 'VpnMenu {' "ShellBarLayer instantiates VpnMenu"
require_literal "$menu_qmldir" 'VpnMenu 1.0 ../features/network/VpnMenu.qml' "menu qmldir exports VpnMenu"
require_literal "$widget_qmldir" 'VpnWidget 1.0 VpnWidget.qml' "widgets qmldir exports VpnWidget"
require_literal "$network_service_qml" 'function buildVpnProfiles(catalogText, activeText) {' "NetworkService exposes saved-profile merge helper"
require_literal "$network_service_qml" 'function connectVpnProfile(uuidValue) {' "NetworkService exposes connectVpnProfile action"
require_literal "$network_service_qml" 'function disconnectVpnProfile(uuidValue) {' "NetworkService exposes disconnectVpnProfile action"
require_literal "$vpn_menu_qml" 'Active VPN Profiles' "VpnMenu shows the active profile section"
require_literal "$vpn_menu_qml" 'Available VPN Profiles' "VpnMenu shows the available profile section"
require_literal "$network_menu_qml" 'NetworkService.vpnHasSavedProfiles' "NetworkMenu summary appears when saved VPN profiles exist"

printf '[INFO] VPN contract summary: %d pass, %d fail\n' "$pass_count" "$fail_count"
(( fail_count == 0 ))
