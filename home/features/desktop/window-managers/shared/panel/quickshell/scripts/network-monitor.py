"""Quickshell NetworkManager D-Bus monitor.

Subscribes to NetworkManager D-Bus signals for event-driven network state.
Emits JSON snapshots on stdout whenever state changes. Reads commands on stdin.

Protocol (newline-delimited JSON):
  stdout -> QML:  {"type":"snapshot", ...full state...}
  stdin  <- QML:  {"type":"refresh"}
  stdin  <- QML:  {"type":"scan"}

Internal polling (not subprocess spawns):
  - WiFi signal strength: every 10s (only when WiFi active)
  - Tailscale status: every 15s
  - Public IP: every 60s
  - Traffic stats: every 10s
"""

import json
import os
import signal
import subprocess
import sys
import threading
import time

import dbus
import dbus.mainloop.glib
from gi.repository import GLib

NM_BUS = "org.freedesktop.NetworkManager"
NM_PATH = "/org/freedesktop/NetworkManager"
NM_IFACE = "org.freedesktop.NetworkManager"
NM_DEVICE_IFACE = "org.freedesktop.NetworkManager.Device"
NM_WIRELESS_IFACE = "org.freedesktop.NetworkManager.Device.Wireless"
NM_AP_IFACE = "org.freedesktop.NetworkManager.AccessPoint"
NM_ACTIVE_IFACE = "org.freedesktop.NetworkManager.Connection.Active"
NM_IP4_IFACE = "org.freedesktop.NetworkManager.IP4Config"
NM_SETTINGS_CONN_IFACE = "org.freedesktop.NetworkManager.Settings.Connection"
DBUS_PROPS_IFACE = "org.freedesktop.DBus.Properties"

_write_lock = threading.Lock()
_bus = None
_state = {}
_debounce_source = None
_DEBOUNCE_MS = 200


def write_json(obj):
    """Write a JSON line to stdout (thread-safe)."""
    line = json.dumps(obj, separators=(",", ":"))
    with _write_lock:
        try:
            sys.stdout.write(line + "\n")
            sys.stdout.flush()
        except (BrokenPipeError, OSError):
            pass


def log(msg):
    print(f"network-monitor: {msg}", file=sys.stderr, flush=True)


def safe_get_prop(bus, path, iface, prop):
    """Get a D-Bus property, returning None on failure."""
    try:
        obj = bus.get_object(NM_BUS, path)
        props = dbus.Interface(obj, DBUS_PROPS_IFACE)
        return props.Get(iface, prop)
    except dbus.DBusException:
        return None


def safe_get_all_props(bus, path, iface):
    """Get all properties for an interface, returning {} on failure."""
    try:
        obj = bus.get_object(NM_BUS, path)
        props = dbus.Interface(obj, DBUS_PROPS_IFACE)
        return dict(props.GetAll(iface))
    except dbus.DBusException:
        return {}


def get_nm_property(prop):
    return safe_get_prop(_bus, NM_PATH, NM_IFACE, prop)


def device_type_name(dtype):
    """Convert NM device type enum to string."""
    mapping = {1: "ethernet", 2: "wifi", 5: "bluetooth", 13: "bridge",
               14: "wireguard", 16: "wifi-p2p"}
    return mapping.get(int(dtype), "other")


def conn_type_to_str(ctype):
    """Normalize connection type string."""
    t = str(ctype or "").lower()
    if t in ("802-11-wireless", "wifi"):
        return "wifi"
    if t in ("802-3-ethernet", "ethernet"):
        return "ethernet"
    return t


def is_vpn_type(ctype):
    t = str(ctype or "").lower()
    return t in ("vpn", "wireguard", "tun")


def signal_icon(sig):
    sig = int(sig or 0)
    if sig >= 80:
        return "\U000f0928"  # 󰤨
    if sig >= 60:
        return "\U000f0925"  # 󰤥
    if sig >= 40:
        return "\U000f0922"  # 󰤢
    if sig > 0:
        return "\U000f091f"  # 󰤟
    return "\U000f092f"  # 󰤯


def band_from_channel(ch):
    ch = int(ch or 0)
    if not ch:
        return ""
    if ch <= 14:
        return "2.4 GHz"
    if ch <= 177:
        return "5 GHz"
    return "6 GHz"


def format_bytes(b):
    b = int(b or 0)
    if b < 1024:
        return f"{b} B"
    if b < 1048576:
        return f"{b / 1024:.1f} KB"
    if b < 1073741824:
        return f"{b / 1048576:.1f} MB"
    return f"{b / 1073741824:.2f} GB"


def read_file(path):
    try:
        with open(path) as f:
            return f.read().strip()
    except (OSError, IOError):
        return ""


def run_json_command(command, timeout=5, strip_comments=False):
    """Run a command and decode JSON output."""
    try:
        result = subprocess.run(command, capture_output=True, text=True, timeout=timeout)
    except (FileNotFoundError, subprocess.TimeoutExpired, OSError):
        return None

    if result.returncode != 0 and not result.stdout:
        return None

    lines = result.stdout.splitlines()
    if strip_comments:
        lines = [line for line in lines if not line.startswith("#")]
    payload = "\n".join(lines).strip()
    if not payload:
        return None

    try:
        return json.loads(payload)
    except json.JSONDecodeError:
        return None


def first_ipv4(addresses):
    for item in addresses or []:
        value = str(item or "")
        if "." in value:
            return value
    values = [str(item or "") for item in (addresses or []) if str(item or "")]
    return values[0] if values else ""


def normalize_tailnet(current_tailnet, status_data):
    if isinstance(current_tailnet, dict):
        return {
            "name": str(current_tailnet.get("Name", "") or current_tailnet.get("name", "")),
            "magicDnsSuffix": str(status_data.get("MagicDNSSuffix", "") or ""),
        }
    if current_tailnet:
        return {
            "name": str(current_tailnet),
            "magicDnsSuffix": str(status_data.get("MagicDNSSuffix", "") or ""),
        }
    return {
        "name": "",
        "magicDnsSuffix": str(status_data.get("MagicDNSSuffix", "") or ""),
    }


def normalize_profile(profile):
    if not isinstance(profile, dict):
        return {"id": "", "account": "", "nickname": "", "tailnet": "", "selected": False}
    return {
        "id": str(profile.get("id", "") or ""),
        "account": str(profile.get("account", "") or ""),
        "nickname": str(profile.get("nickname", "") or ""),
        "tailnet": str(profile.get("tailnet", "") or ""),
        "selected": bool(profile.get("selected", False)),
    }


def normalize_peer(peer_key, peer, user_map=None):
    if not isinstance(peer, dict):
        return None
    user_map = user_map if isinstance(user_map, dict) else {}
    addresses = peer.get("TailscaleIPs") or []
    name = str(peer.get("HostName", "") or "")
    dns_name = str(peer.get("DNSName", "") or "")
    display_name = name or dns_name.split(".", 1)[0] if dns_name else ""
    user_id = str(peer.get("UserID", "") or "")
    owner = user_map.get(user_id) if user_id else None
    owner = owner if isinstance(owner, dict) else {}
    current_address = str(peer.get("CurAddr", "") or "")
    if current_address == "":
        relay = str(peer.get("Relay", "") or "")
        if relay:
            current_address = relay
    return {
        "id": str(peer.get("ID", "") or peer_key or ""),
        "name": str(display_name or ""),
        "hostName": name,
        "dnsName": dns_name,
        "os": str(peer.get("OS", "") or ""),
        "online": bool(peer.get("Online", False)),
        "active": bool(peer.get("Active", False)),
        "exitNode": bool(peer.get("ExitNode", False)),
        "exitNodeOption": bool(peer.get("ExitNodeOption", False)),
        "tailscaleIps": [str(item or "") for item in addresses if str(item or "")],
        "primaryIp": first_ipv4(addresses),
        "currentAddress": current_address,
        "relay": str(peer.get("Relay", "") or ""),
        "shareeNode": bool(peer.get("ShareeNode", False)),
        "ownerLogin": str(owner.get("LoginName", "") or ""),
        "ownerName": str(owner.get("DisplayName", "") or ""),
        "lastSeen": str(peer.get("LastSeen", "") or ""),
    }


def advertised_exit_node_enabled(prefs):
    routes = prefs.get("AdvertiseRoutes", []) if isinstance(prefs, dict) else []
    routes = [str(route or "") for route in routes or []]
    return "0.0.0.0/0" in routes or "::/0" in routes


def build_current_exit_node(status_data, prefs, peers):
    prefs = prefs if isinstance(prefs, dict) else {}
    self_node = status_data.get("Self") if isinstance(status_data, dict) else {}
    self_node = self_node if isinstance(self_node, dict) else {}
    exit_node_ip = str(prefs.get("ExitNodeIP", "") or "")
    exit_node_id = str(prefs.get("ExitNodeID", "") or "")
    current_label = ""
    current_dns = ""

    for peer in peers:
        peer_ips = peer.get("tailscaleIps", []) or []
        if exit_node_id and str(peer.get("id", "")) == exit_node_id:
            current_label = str(peer.get("name", "") or peer.get("dnsName", "") or "")
            current_dns = str(peer.get("dnsName", "") or "")
            exit_node_ip = exit_node_ip or str(peer.get("primaryIp", "") or "")
            break
        if exit_node_ip and exit_node_ip in peer_ips:
            current_label = str(peer.get("name", "") or peer.get("dnsName", "") or "")
            current_dns = str(peer.get("dnsName", "") or "")
            break

    if current_label == "":
        self_exit = self_node.get("ExitNodeStatus", {}) if isinstance(self_node, dict) else {}
        if isinstance(self_exit, dict):
            current_label = str(self_exit.get("Name", "") or self_exit.get("ID", "") or "")
            current_dns = str(self_exit.get("DNSName", "") or "")
            exit_node_ip = exit_node_ip or str(self_exit.get("TailscaleIP", "") or "")

    return {
        "id": exit_node_id,
        "ip": exit_node_ip,
        "name": current_label,
        "dnsName": current_dns,
        "allowLanAccess": bool(prefs.get("ExitNodeAllowLANAccess", False)),
    }


# ── State collection ──────────────────────────────────────

def collect_wifi_radio():
    """Check if WiFi radio is enabled."""
    val = get_nm_property("WirelessEnabled")
    return bool(val) if val is not None else False


def collect_wifi_device_path():
    """Find the first WiFi device path."""
    devices = get_nm_property("Devices") or []
    for dev_path in devices:
        dtype = safe_get_prop(_bus, dev_path, NM_DEVICE_IFACE, "DeviceType")
        if dtype is not None and int(dtype) == 2:
            return str(dev_path)
    return ""


def collect_wifi_networks(wifi_dev_path):
    """Scan and collect WiFi access points."""
    if not wifi_dev_path:
        return []
    try:
        obj = _bus.get_object(NM_BUS, wifi_dev_path)
        wireless = dbus.Interface(obj, NM_WIRELESS_IFACE)
        aps = wireless.GetAllAccessPoints()
    except dbus.DBusException:
        return []

    networks = []
    active_ap = safe_get_prop(_bus, wifi_dev_path, NM_WIRELESS_IFACE, "ActiveAccessPoint")
    active_ap_str = str(active_ap) if active_ap else ""

    seen_ssids = set()
    for ap_path in aps:
        props = safe_get_all_props(_bus, ap_path, NM_AP_IFACE)
        ssid_bytes = props.get("Ssid", b"")
        try:
            ssid = bytes(ssid_bytes).decode("utf-8", errors="replace")
        except (TypeError, ValueError):
            ssid = ""
        if not ssid:
            ssid = "Hidden network"

        sig = int(props.get("Strength", 0))
        # Deduplicate by SSID, keep strongest signal
        if ssid in seen_ssids:
            # Find and update if stronger
            for n in networks:
                if n["ssid"] == ssid and int(n["signal"]) < sig:
                    n["signal"] = str(sig)
                    if str(ap_path) == active_ap_str:
                        n["active"] = True
            continue
        seen_ssids.add(ssid)

        flags = int(props.get("WpaFlags", 0)) | int(props.get("RsnFlags", 0))
        security = "open"
        if flags:
            security = "WPA"
            if int(props.get("RsnFlags", 0)):
                security = "WPA2"

        is_active = str(ap_path) == active_ap_str
        freq = int(props.get("Frequency", 0))
        networks.append({
            "ssid": ssid,
            "security": security,
            "signal": str(sig),
            "active": is_active,
            "frequency": freq,
        })

    # Sort: active first, then by signal strength descending
    networks.sort(key=lambda n: (not n.get("active", False), -int(n.get("signal", 0))))
    return networks


def collect_active_connections():
    """Collect active NM connections."""
    ac_paths = get_nm_property("ActiveConnections") or []
    active = []
    for ac_path in ac_paths:
        props = safe_get_all_props(_bus, ac_path, NM_ACTIVE_IFACE)
        conn_type = conn_type_to_str(props.get("Type", ""))
        name = str(props.get("Id", ""))
        uuid = str(props.get("Uuid", ""))
        devices = props.get("Devices", [])
        device = ""
        if devices:
            dev_iface = safe_get_prop(_bus, str(devices[0]), NM_DEVICE_IFACE, "Interface")
            device = str(dev_iface) if dev_iface else ""
        state = int(props.get("State", 0))
        # NM_ACTIVE_CONNECTION_STATE_ACTIVATED = 2
        active.append({
            "name": name,
            "type": conn_type,
            "device": device,
            "uuid": uuid,
            "state": "activated" if state == 2 else "activating" if state == 1 else "deactivated",
        })
    return active


def collect_vpn_profiles():
    """Collect VPN connection profiles from NM settings."""
    active_conns = collect_active_connections()
    active_uuids = {c["uuid"] for c in active_conns if is_vpn_type(c["type"])}

    # Get all saved connections
    profiles = []
    try:
        settings_obj = _bus.get_object(NM_BUS, "/org/freedesktop/NetworkManager/Settings")
        settings_iface = dbus.Interface(settings_obj, "org.freedesktop.NetworkManager.Settings")
        conn_paths = settings_iface.ListConnections()
    except dbus.DBusException:
        return profiles, []

    for conn_path in conn_paths:
        try:
            conn_obj = _bus.get_object(NM_BUS, conn_path)
            conn_iface = dbus.Interface(conn_obj, NM_SETTINGS_CONN_IFACE)
            settings = conn_iface.GetSettings()
            conn_settings = settings.get("connection", {})
            ctype = str(conn_settings.get("type", ""))
            if not is_vpn_type(ctype):
                continue
            uuid = str(conn_settings.get("uuid", ""))
            name = str(conn_settings.get("id", ""))
            is_active = uuid in active_uuids
            device = ""
            state = ""
            for ac in active_conns:
                if ac["uuid"] == uuid:
                    device = ac["device"]
                    state = ac["state"]
                    break
            profiles.append({
                "uuid": uuid,
                "name": name,
                "type": ctype,
                "device": device,
                "state": state,
                "active": is_active,
            })
        except dbus.DBusException:
            continue

    # Sort: active first, then by name
    profiles.sort(key=lambda p: (not p["active"], p["name"].lower()))
    active_vpns = [p for p in profiles if p["active"]]
    return profiles, active_vpns


def collect_primary_details(active_conns):
    """Get primary connection details."""
    primary_path = get_nm_property("PrimaryConnection")
    result = {
        "activePrimaryName": "Offline",
        "activePrimaryType": "",
        "primaryDevice": "",
        "primaryIpv4": "",
        "primaryIpv6": "",
        "primaryGateway": "",
        "primaryMac": "",
        "primaryLinkSpeed": "",
        "primarySecurity": "",
        "primarySignal": "",
        "primaryChannel": "",
        "primaryBand": "",
        "connectivityStatus": "unknown",
        "dnsServers": [],
    }

    if not primary_path or str(primary_path) == "/":
        # Check connectivity anyway
        conn_state = get_nm_property("Connectivity")
        # NM_CONNECTIVITY: 0=unknown, 1=none, 2=portal, 3=limited, 4=full
        conn_map = {0: "unknown", 1: "none", 2: "portal", 3: "limited", 4: "full"}
        result["connectivityStatus"] = conn_map.get(int(conn_state or 0), "unknown")
        return result

    ac_props = safe_get_all_props(_bus, str(primary_path), NM_ACTIVE_IFACE)
    result["activePrimaryName"] = str(ac_props.get("Id", "Unknown"))
    result["activePrimaryType"] = conn_type_to_str(ac_props.get("Type", ""))

    devices = ac_props.get("Devices", [])
    if devices:
        dev_path = str(devices[0])
        dev_props = safe_get_all_props(_bus, dev_path, NM_DEVICE_IFACE)
        result["primaryDevice"] = str(dev_props.get("Interface", ""))
        iface_name = result["primaryDevice"]

        # MAC address
        result["primaryMac"] = read_file(f"/sys/class/net/{iface_name}/address")

        # Link speed
        speed = read_file(f"/sys/class/net/{iface_name}/speed")
        if speed and speed != "-1":
            result["primaryLinkSpeed"] = f"{speed} Mb/s"

        # IP addresses from IP4Config/IP6Config
        ip4_path = str(dev_props.get("Ip4Config", "/"))
        if ip4_path != "/":
            ip4_props = safe_get_all_props(_bus, ip4_path, NM_IP4_IFACE)
            addresses = ip4_props.get("AddressData", [])
            if addresses:
                addr = addresses[0]
                result["primaryIpv4"] = f"{addr.get('address', '')}/{addr.get('prefix', '')}"
            gw = str(ip4_props.get("Gateway", ""))
            if gw:
                result["primaryGateway"] = gw
            # DNS
            dns_data = ip4_props.get("NameserverData", [])
            result["dnsServers"] = [str(d.get("address", "")) for d in dns_data if d.get("address")]

        ip6_path = str(dev_props.get("Ip6Config", "/"))
        if ip6_path != "/" and not result.get("primaryIpv6"):
            try:
                ip6_props = safe_get_all_props(_bus, ip6_path,
                    "org.freedesktop.NetworkManager.IP6Config")
                addresses = ip6_props.get("AddressData", [])
                if addresses:
                    addr = addresses[0]
                    result["primaryIpv6"] = f"{addr.get('address', '')}/{addr.get('prefix', '')}"
                if not result["primaryGateway"]:
                    gw = str(ip6_props.get("Gateway", ""))
                    if gw:
                        result["primaryGateway"] = gw
            except Exception:
                pass

        # WiFi-specific: signal, security, channel
        dev_type = int(dev_props.get("DeviceType", 0))
        if dev_type == 2:
            active_ap = safe_get_prop(_bus, dev_path, NM_WIRELESS_IFACE, "ActiveAccessPoint")
            if active_ap and str(active_ap) != "/":
                ap_props = safe_get_all_props(_bus, str(active_ap), NM_AP_IFACE)
                result["primarySignal"] = str(int(ap_props.get("Strength", 0)))
                freq = int(ap_props.get("Frequency", 0))
                # Convert frequency to channel
                ch = 0
                if 2412 <= freq <= 2484:
                    ch = (freq - 2412) // 5 + 1
                elif 5180 <= freq <= 5825:
                    ch = (freq - 5180) // 5 + 36
                elif 5955 <= freq <= 7115:
                    ch = (freq - 5955) // 5 + 1
                result["primaryChannel"] = str(ch) if ch else ""
                result["primaryBand"] = band_from_channel(ch)

                flags = int(ap_props.get("WpaFlags", 0)) | int(ap_props.get("RsnFlags", 0))
                if flags:
                    result["primarySecurity"] = "WPA2" if int(ap_props.get("RsnFlags", 0)) else "WPA"
                else:
                    result["primarySecurity"] = "open"

                # Update link speed from bitrate if available
                bitrate = safe_get_prop(_bus, dev_path, NM_WIRELESS_IFACE, "Bitrate")
                if bitrate:
                    result["primaryLinkSpeed"] = f"{int(bitrate) // 1000} Mb/s"

    conn_state = get_nm_property("Connectivity")
    conn_map = {0: "unknown", 1: "none", 2: "portal", 3: "limited", 4: "full"}
    result["connectivityStatus"] = conn_map.get(int(conn_state or 0), "unknown")

    return result


def collect_internet_details(public_ipv4=""):
    """Get route device, public IP, and traffic stats."""
    result = {
        "routeDevice": "",
        "routeSource": "",
        "publicIpv4": str(public_ipv4 or ""),
        "totalReceived": "0 B",
        "totalSent": "0 B",
    }

    # Get default route device from /proc/net/route
    try:
        with open("/proc/net/route") as f:
            for line in f:
                parts = line.split()
                if len(parts) >= 2 and parts[1] == "00000000":
                    result["routeDevice"] = parts[0]
                    break
    except (OSError, IOError):
        pass

    dev = result["routeDevice"]
    if dev:
        rx = read_file(f"/sys/class/net/{dev}/statistics/rx_bytes")
        tx = read_file(f"/sys/class/net/{dev}/statistics/tx_bytes")
        result["totalReceived"] = format_bytes(rx)
        result["totalSent"] = format_bytes(tx)

    return result


def collect_tailscale():
    """Get Tailscale status, prefs, profiles, and peers."""
    result = {
        "tailscaleStatus": "Unavailable",
        "tailscaleIp": "",
        "tailscaleIps": [],
        "tailscaleBackendState": "",
        "tailscaleAuthUrl": "",
        "tailscaleHealth": [],
        "tailscaleVersion": "",
        "tailscaleSelf": {},
        "tailscaleTailnet": {"name": "", "magicDnsSuffix": ""},
        "tailscalePeers": [],
        "tailscalePrefs": {},
        "tailscaleProfiles": [],
        "tailscaleExitNode": {"id": "", "ip": "", "name": "", "dnsName": "", "allowLanAccess": False},
    }

    status_data = run_json_command(
        ["tailscale", "debug", "localapi", "GET", "/localapi/v0/status"],
        timeout=5,
        strip_comments=True,
    )
    if status_data is None:
        status_data = run_json_command(["tailscale", "status", "--json"], timeout=5)
    if status_data is None:
        return result

    prefs_data = run_json_command(
        ["tailscale", "debug", "localapi", "GET", "/localapi/v0/prefs"],
        timeout=5,
        strip_comments=True,
    )
    if prefs_data is None:
        prefs_data = run_json_command(["tailscale", "debug", "prefs"], timeout=5)
    if prefs_data is None:
        prefs_data = {}

    profiles_data = run_json_command(["tailscale", "switch", "--list", "--json"], timeout=5)
    if not isinstance(profiles_data, list):
        profiles_data = []

    backend_state = str(status_data.get("BackendState", "") or "")
    health = [str(item or "") for item in (status_data.get("Health") or []) if str(item or "")]
    self_node = status_data.get("Self") if isinstance(status_data.get("Self"), dict) else {}
    self_ips = [str(item or "") for item in (status_data.get("TailscaleIPs") or self_node.get("TailscaleIPs") or []) if str(item or "")]
    peer_map = status_data.get("Peer") if isinstance(status_data.get("Peer"), dict) else {}
    user_map = status_data.get("User") if isinstance(status_data.get("User"), dict) else {}
    peers = []
    for peer_key, peer in peer_map.items():
        normalized_peer = normalize_peer(peer_key, peer, user_map)
        if normalized_peer is not None:
            peers.append(normalized_peer)
    peers.sort(key=lambda item: (not item["online"], not item["active"], item["name"].lower(), item["dnsName"].lower()))

    if backend_state == "Running":
        status = "Connected"
    elif backend_state == "Stopped":
        status = "Stopped"
    elif backend_state in ("NeedsLogin", "NeedsMachineAuth"):
        status = backend_state
    elif backend_state:
        status = "Disconnected"
    else:
        status = "Unavailable"

    result["tailscaleStatus"] = status
    result["tailscaleBackendState"] = backend_state
    result["tailscaleAuthUrl"] = str(status_data.get("AuthURL", "") or "")
    result["tailscaleHealth"] = health
    result["tailscaleVersion"] = str(status_data.get("Version", "") or "")
    result["tailscaleIps"] = self_ips
    result["tailscaleIp"] = first_ipv4(self_ips)
    result["tailscaleSelf"] = {
        "id": str(self_node.get("ID", "") or ""),
        "hostName": str(self_node.get("HostName", "") or ""),
        "dnsName": str(self_node.get("DNSName", "") or ""),
        "online": bool(self_node.get("Online", False)),
        "active": bool(self_node.get("Active", False)),
        "tailscaleIps": self_ips,
        "primaryIp": first_ipv4(self_ips),
        "exitNodeOption": bool(self_node.get("ExitNodeOption", False)),
        "advertiseExitNode": advertised_exit_node_enabled(prefs_data),
    }
    result["tailscaleTailnet"] = normalize_tailnet(status_data.get("CurrentTailnet"), status_data)
    result["tailscalePeers"] = peers
    result["tailscalePrefs"] = {
        "RouteAll": bool(prefs_data.get("RouteAll", False)),
        "ExitNodeAllowLANAccess": bool(prefs_data.get("ExitNodeAllowLANAccess", False)),
        "CorpDNS": bool(prefs_data.get("CorpDNS", False)),
        "RunSSH": bool(prefs_data.get("RunSSH", False)),
        "WantRunning": bool(prefs_data.get("WantRunning", False)),
        "LoggedOut": bool(prefs_data.get("LoggedOut", False)),
        "ShieldsUp": bool(prefs_data.get("ShieldsUp", False)),
        "AdvertiseTags": [str(tag or "") for tag in (prefs_data.get("AdvertiseTags") or []) if str(tag or "")],
        "AdvertiseRoutes": [str(route or "") for route in (prefs_data.get("AdvertiseRoutes") or []) if str(route or "")],
        "NoStatefulFiltering": bool(prefs_data.get("NoStatefulFiltering", False)),
        "OperatorUser": str(prefs_data.get("OperatorUser", "") or ""),
        "Hostname": str(prefs_data.get("Hostname", "") or ""),
    }
    result["tailscaleProfiles"] = [normalize_profile(profile) for profile in profiles_data]
    result["tailscaleExitNode"] = build_current_exit_node(status_data, prefs_data, peers)

    return result


def collect_public_ip():
    """Get public IPv4 address."""
    try:
        r = subprocess.run(["curl", "-4", "-fsS", "--max-time", "3",
                            "https://api.ipify.org"],
                           capture_output=True, text=True, timeout=5)
        return r.stdout.strip() if r.returncode == 0 else ""
    except (FileNotFoundError, subprocess.TimeoutExpired, OSError):
        return ""


# ── Full snapshot ─────────────────────────────────────────

def build_snapshot(public_ipv4=None):
    """Build a complete state snapshot."""
    wifi_radio = collect_wifi_radio()
    wifi_dev = collect_wifi_device_path()
    wifi_networks = collect_wifi_networks(wifi_dev) if wifi_radio and wifi_dev else []
    active_conns = collect_active_connections()
    vpn_profiles, vpns = collect_vpn_profiles()
    primary = collect_primary_details(active_conns)
    internet = collect_internet_details()
    tailscale = collect_tailscale()

    route_device = internet.get("routeDevice", "")
    connectivity = primary.get("connectivityStatus", "unknown")
    primary_ipv4 = primary.get("primaryIpv4", "")
    cached_public_ipv4 = str(_state.get("publicIpv4", ""))
    should_refresh_public_ipv4 = (
        public_ipv4 is not None
        or "publicIpv4" not in _state
        or route_device != str(_state.get("routeDevice", ""))
        or connectivity != str(_state.get("connectivityStatus", "unknown"))
        or primary_ipv4 != str(_state.get("primaryIpv4", ""))
    )

    resolved_public_ipv4 = str(cached_public_ipv4 if public_ipv4 is None else public_ipv4 or "")
    if not route_device or connectivity in ("none", "unknown"):
        resolved_public_ipv4 = ""
    elif should_refresh_public_ipv4 and connectivity == "full":
        resolved_public_ipv4 = collect_public_ip()

    internet["publicIpv4"] = resolved_public_ipv4

    snapshot = {
        "type": "snapshot",
        "wifiRadioEnabled": wifi_radio,
        "wifiDeviceAvailable": bool(wifi_dev),
        "wifiNetworks": wifi_networks,
        "activeConnections": [{"name": c["name"], "type": c["type"], "device": c["device"]}
                              for c in active_conns if c["state"] == "activated"],
        "vpnProfiles": vpn_profiles,
        "vpns": vpns,
    }
    snapshot.update(primary)
    snapshot.update(internet)
    snapshot.update(tailscale)

    return snapshot


# ── Debounced emit ────────────────────────────────────────

def schedule_snapshot():
    """Schedule a debounced snapshot emission."""
    global _debounce_source
    if _debounce_source is not None:
        GLib.source_remove(_debounce_source)
    _debounce_source = GLib.timeout_add(_DEBOUNCE_MS, _emit_snapshot)


def _emit_snapshot():
    """Emit a full snapshot and reset debounce."""
    global _debounce_source
    _debounce_source = None
    try:
        snapshot = build_snapshot()
        _state.update(snapshot)
        write_json(snapshot)
    except Exception as e:
        log(f"snapshot error: {e}")
    return False  # Don't repeat


# ── D-Bus signal handlers ────────────────────────────────

def on_nm_state_changed(*args):
    schedule_snapshot()


_subscribed_acs = set()


def on_nm_props_changed(iface, changed, invalidated):
    # Dynamically subscribe to new active connections
    if "ActiveConnections" in changed:
        for ac_path in changed["ActiveConnections"]:
            ac_str = str(ac_path)
            if ac_str not in _subscribed_acs:
                _subscribed_acs.add(ac_str)
                subscribe_active_connection(ac_str)
    schedule_snapshot()


_RELEVANT_DEVICE_IFACES = frozenset([
    NM_DEVICE_IFACE, NM_WIRELESS_IFACE, NM_AP_IFACE,
    NM_ACTIVE_IFACE, NM_IP4_IFACE,
])


def on_device_props_changed(iface, changed, invalidated, path=None):
    if iface not in _RELEVANT_DEVICE_IFACES:
        return
    schedule_snapshot()


def on_ap_added(*args):
    schedule_snapshot()


def on_ap_removed(*args):
    schedule_snapshot()


def on_active_connection_props_changed(iface, changed, invalidated):
    schedule_snapshot()


def subscribe_active_connection(ac_path):
    """Subscribe to property changes on an active connection."""
    try:
        _bus.add_signal_receiver(
            on_active_connection_props_changed,
            signal_name="PropertiesChanged",
            dbus_interface=DBUS_PROPS_IFACE,
            bus_name=NM_BUS,
            path=str(ac_path),
        )
    except dbus.DBusException:
        pass


def subscribe_signals():
    """Subscribe to NM D-Bus signals."""
    # NM state changes
    _bus.add_signal_receiver(
        on_nm_state_changed,
        signal_name="StateChanged",
        dbus_interface=NM_IFACE,
        bus_name=NM_BUS,
        path=NM_PATH,
    )

    # NM property changes (PrimaryConnection, WirelessEnabled, Connectivity, etc.)
    _bus.add_signal_receiver(
        on_nm_props_changed,
        signal_name="PropertiesChanged",
        dbus_interface=DBUS_PROPS_IFACE,
        bus_name=NM_BUS,
        path=NM_PATH,
    )

    # Device property changes (catch-all for all device paths)
    _bus.add_signal_receiver(
        on_device_props_changed,
        signal_name="PropertiesChanged",
        dbus_interface=DBUS_PROPS_IFACE,
        bus_name=NM_BUS,
        path_keyword="path",
    )

    # Subscribe to existing active connections
    ac_paths = get_nm_property("ActiveConnections") or []
    for ac_path in ac_paths:
        ac_str = str(ac_path)
        _subscribed_acs.add(ac_str)
        subscribe_active_connection(ac_str)


# ── Polling timers (internal, no subprocess spawns from QML) ──

_last_signal = -1


def poll_wifi_signal():
    """Poll WiFi signal strength every 10s."""
    global _last_signal
    try:
        wifi_dev = collect_wifi_device_path()
        if not wifi_dev:
            return True
        active_ap = safe_get_prop(_bus, wifi_dev, NM_WIRELESS_IFACE, "ActiveAccessPoint")
        if not active_ap or str(active_ap) == "/":
            return True
        sig = safe_get_prop(_bus, str(active_ap), NM_AP_IFACE, "Strength")
        if sig is not None:
            sig = int(sig)
            if abs(sig - _last_signal) >= 5:
                _last_signal = sig
                schedule_snapshot()
    except Exception:
        pass
    return True


def poll_tailscale():
    """Poll Tailscale status every 15s."""
    try:
        ts = collect_tailscale()
        if json.dumps(ts, sort_keys=True) != json.dumps({
            "tailscaleStatus": _state.get("tailscaleStatus"),
            "tailscaleIp": _state.get("tailscaleIp"),
            "tailscaleIps": _state.get("tailscaleIps", []),
            "tailscaleBackendState": _state.get("tailscaleBackendState"),
            "tailscaleAuthUrl": _state.get("tailscaleAuthUrl"),
            "tailscaleHealth": _state.get("tailscaleHealth", []),
            "tailscaleVersion": _state.get("tailscaleVersion"),
            "tailscaleSelf": _state.get("tailscaleSelf", {}),
            "tailscaleTailnet": _state.get("tailscaleTailnet", {}),
            "tailscalePeers": _state.get("tailscalePeers", []),
            "tailscalePrefs": _state.get("tailscalePrefs", {}),
            "tailscaleProfiles": _state.get("tailscaleProfiles", []),
            "tailscaleExitNode": _state.get("tailscaleExitNode", {}),
        }, sort_keys=True):
            schedule_snapshot()
    except Exception:
        pass
    return True


def poll_public_ip():
    """Poll public IP every 60s."""
    try:
        ip = collect_public_ip()
        if ip != _state.get("publicIpv4", ""):
            _state["publicIpv4"] = ip
            schedule_snapshot()
    except Exception:
        pass
    return True


def poll_traffic():
    """Poll traffic stats every 10s."""
    try:
        inet = collect_internet_details()
        if (inet["totalReceived"] != _state.get("totalReceived") or
                inet["totalSent"] != _state.get("totalSent")):
            schedule_snapshot()
    except Exception:
        pass
    return True


# ── Stdin reader ──────────────────────────────────────────

def stdin_reader(loop):
    """Read JSON commands from QML on stdin."""
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            msg = json.loads(line)
        except json.JSONDecodeError:
            continue

        cmd_type = msg.get("type", "")
        if cmd_type == "refresh":
            GLib.idle_add(schedule_snapshot)
        elif cmd_type == "scan":
            def do_scan():
                wifi_dev = collect_wifi_device_path()
                if wifi_dev:
                    try:
                        obj = _bus.get_object(NM_BUS, wifi_dev)
                        wireless = dbus.Interface(obj, NM_WIRELESS_IFACE)
                        wireless.RequestScan({})
                    except dbus.DBusException:
                        pass
                schedule_snapshot()
            GLib.idle_add(do_scan)

    # stdin closed — QML process exited
    GLib.idle_add(loop.quit)


# ── Main ──────────────────────────────────────────────────

def main():
    global _bus

    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    _bus = dbus.SystemBus()
    loop = GLib.MainLoop()

    log("starting")

    # Subscribe to NM signals
    subscribe_signals()

    # Emit initial snapshot
    try:
        snapshot = build_snapshot()
        _state.update(snapshot)
        write_json(snapshot)
    except Exception as e:
        log(f"initial snapshot error: {e}")
        write_json({"type": "snapshot", "activePrimaryName": "Offline"})

    # Start polling timers
    GLib.timeout_add_seconds(10, poll_wifi_signal)
    GLib.timeout_add_seconds(15, poll_tailscale)
    GLib.timeout_add_seconds(60, poll_public_ip)
    GLib.timeout_add_seconds(10, poll_traffic)

    # Read stdin in background thread
    reader = threading.Thread(target=stdin_reader, args=(loop,), daemon=True)
    reader.start()

    def shutdown(_sig=None, _frame=None):
        loop.quit()

    signal.signal(signal.SIGTERM, shutdown)
    signal.signal(signal.SIGINT, shutdown)

    try:
        loop.run()
    except KeyboardInterrupt:
        pass

    log("exiting")


if __name__ == "__main__":
    main()
