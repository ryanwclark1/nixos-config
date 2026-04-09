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

bar_registry="${repo_root}/src/features/bar/registry/BarWidgetRegistry.qml"
panel_qml="${repo_root}/src/bar/Panel.qml"
surface_service_qml="${repo_root}/src/services/SurfaceService.qml"
shell_qml="${repo_root}/src/shell.qml"
shell_bar_layer_qml="${repo_root}/src/shell/ShellBarLayer.qml"
network_qmldir="${repo_root}/src/features/network/qmldir"
network_service_qml="${repo_root}/src/services/NetworkService.qml"
vpn_menu_qml="${repo_root}/src/features/network/VpnMenu.qml"
network_menu_qml="${repo_root}/src/features/network/NetworkMenu.qml"

require_literal "$bar_registry" 'widgetType: "vpn"' "VPN widget is registered in BarWidgetRegistry"
require_literal "$bar_registry" 'key: "labelMode"' "VPN widget exposes labelMode setting"
require_literal "$bar_registry" 'key: "showOtherVpnCount"' "VPN widget exposes overlay count setting"
require_literal "$panel_qml" '"vpn": vpnComponent,' "Panel dispatch maps the vpn widget type"
require_literal "$panel_qml" 'id: vpnComponent' "Panel defines the vpn widget component"
require_literal "$panel_qml" 'onTriggerRequested: triggerItem => root.requestSurface("vpnMenu", triggerItem)' "VPN widget opens the vpnMenu surface"
require_literal "$surface_service_qml" 'vpnMenu: {' "SurfaceService registers vpnMenu"
require_literal "${repo_root}/src/app/ShellRoot.qml" 'readonly property bool vpnMenuVisible: root.isSurfaceOpen("vpnMenu")' "ShellRoot exposes vpnMenu visibility"
require_literal "$shell_bar_layer_qml" 'VpnMenu {' "ShellBarLayer instantiates VpnMenu"
require_literal "$shell_bar_layer_qml" 'implicitHeight: Math.min(compactMode ? 900 : 980, root.shellRoot.popupMaxHeight' "ShellBarLayer caps the larger VPN popup height by screen space"
require_literal "$network_qmldir" 'VpnMenu 1.0 VpnMenu.qml' "network qmldir exports VpnMenu"
require_literal "$network_qmldir" 'VpnWidget 1.0 components/VpnWidget.qml' "network qmldir exports VpnWidget"
require_literal "$network_service_qml" 'readonly property var vpnActiveProfiles: vpnOtherSessions' "NetworkService exposes active VPN profile collections"
require_literal "$network_service_qml" 'readonly property var vpnInactiveProfiles: (vpnProfiles || []).filter(function(profile) { return !profile.active; })' "NetworkService exposes inactive VPN profile collections"
require_literal "$network_service_qml" 'function connectVpnProfile(uuidValue) {' "NetworkService exposes connectVpnProfile action"
require_literal "$network_service_qml" 'function disconnectVpnProfile(uuidValue) {' "NetworkService exposes disconnectVpnProfile action"
require_literal "$network_service_qml" 'property string tailscaleBackendState: ""' "NetworkService exposes rich Tailscale backend state"
require_literal "$network_service_qml" 'property var tailscalePeers: []' "NetworkService exposes Tailscale peer collection"
require_literal "${repo_root}/scripts/network-monitor.py" '"ownerLogin": str(owner.get("LoginName", "") or "")' "Network monitor maps Tailscale peer owner login"
require_literal "${repo_root}/scripts/network-monitor.py" '"ownerName": str(owner.get("DisplayName", "") or "")' "Network monitor maps Tailscale peer owner name"
require_literal "${repo_root}/scripts/network-monitor.py" '"lastSeen": str(peer.get("LastSeen", "") or "")' "Network monitor maps Tailscale peer last seen timestamps"
require_literal "${repo_root}/scripts/network-monitor.py" 'if is_tailscale_connection(name=name, uuid=uuid):' "Network monitor excludes Tailscale from Other VPN profiles"
require_literal "${repo_root}/scripts/network-monitor.py" '"routeDestinations": route_destinations,' "Network monitor maps VPN route destinations"
require_literal "${repo_root}/scripts/network-monitor.py" '"listenPort": listen_port_value,' "Network monitor maps WireGuard listen port"
require_literal "$network_service_qml" 'function tailscaleSwitchProfile(profileId) {' "NetworkService exposes Tailscale account switching"
require_literal "$network_service_qml" 'function tailscaleSelectExitNode(nodeValue) {' "NetworkService exposes exit-node selection"
require_literal "$network_service_qml" 'function tailscaleSetAcceptDns(enabled) {' "NetworkService exposes Tailscale DNS toggle"
require_literal "$vpn_menu_qml" 'popupMinWidth: 420' "VpnMenu uses the wider popup minimum width"
require_literal "$vpn_menu_qml" 'popupMaxWidth: 560' "VpnMenu uses the wider popup maximum width"
require_literal "$vpn_menu_qml" 'label: "Tailscale"' "VpnMenu exposes the Tailscale tab"
require_literal "$vpn_menu_qml" 'label: "Other VPNs"' "VpnMenu exposes the Other VPNs tab"
require_literal "$vpn_menu_qml" 'Tailnet Accounts' "VpnMenu shows the Tailscale account section"
require_literal "$vpn_menu_qml" 'Exit Nodes' "VpnMenu shows the exit-node section"
require_literal "$vpn_menu_qml" 'Runtime Preferences' "VpnMenu shows the runtime preference section"
require_literal "$vpn_menu_qml" 'Tailnet Machines' "VpnMenu shows the machine section"
require_literal "$vpn_menu_qml" 'Active VPN Profiles' "VpnMenu shows the active profile section"
require_literal "$vpn_menu_qml" 'Available VPN Profiles' "VpnMenu shows the available profile section"
require_literal "$network_menu_qml" 'NetworkService.vpnHasSavedProfiles' "NetworkMenu summary appears when saved VPN profiles exist"
require_literal "${repo_root}/src/features/network/VpnHelpers.js" 'function vpnProfileRouteDetail(profile) {' "VPN helpers expose route-detail rendering"
require_literal "${repo_root}/src/features/network/components/VpnProfileDelegate.qml" 'text: VH.vpnProfileSecondaryDetail(root.modelData)' "VpnProfileDelegate renders enriched VPN profile detail"

printf '[INFO] VPN contract summary: %d pass, %d fail\n' "$pass_count" "$fail_count"
(( fail_count == 0 ))
