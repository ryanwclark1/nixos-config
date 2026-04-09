.pragma library

function statusColor(statusKey, colors) {
    if (statusKey === "connected")
        return colors.success;
    if (statusKey === "attention")
        return colors.warning;
    if (statusKey === "stopped")
        return colors.warning;
    if (statusKey === "disconnected")
        return colors.textSecondary;
    return colors.textDisabled;
}

function backendStateStatusKey(backendState) {
    var state = String(backendState || "");
    if (state === "Running")
        return "connected";
    if (state === "NeedsLogin" || state === "NeedsMachineAuth")
        return "attention";
    if (state === "Stopped")
        return "stopped";
    if (state !== "")
        return "disconnected";
    return "unavailable";
}

function backendStateLabel(backendState) {
    var state = String(backendState || "");
    if (state === "Running")
        return "Connected";
    if (state === "NeedsLogin")
        return "Needs Login";
    if (state === "NeedsMachineAuth")
        return "Needs Approval";
    if (state === "Stopped")
        return "Stopped";
    if (state === "Starting")
        return "Starting";
    if (state !== "")
        return "Disconnected";
    return "Unavailable";
}

function healthSummary(healthMessages) {
    var list = Array.isArray(healthMessages) ? healthMessages : [];
    for (var i = 0; i < list.length; ++i) {
        var item = String(list[i] || "").trim();
        if (item !== "")
            return item;
    }
    return "";
}

function firstIpv4(addresses) {
    var list = Array.isArray(addresses) ? addresses : [];
    for (var i = 0; i < list.length; ++i) {
        var value = String(list[i] || "");
        if (value.indexOf(".") !== -1)
            return value;
    }
    return list.length > 0 ? String(list[0] || "") : "";
}

function advertiseExitNodeEnabled(prefs) {
    var routes = prefs && Array.isArray(prefs.AdvertiseRoutes) ? prefs.AdvertiseRoutes : [];
    return routes.indexOf("0.0.0.0/0") !== -1 || routes.indexOf("::/0") !== -1;
}

function statefulFilteringEnabled(prefs) {
    if (!prefs || prefs.NoStatefulFiltering === undefined)
        return true;
    return !prefs.NoStatefulFiltering;
}

function exitNodeLabel(exitNode) {
    if (!exitNode)
        return "";
    var label = String(exitNode.name || exitNode.dnsName || exitNode.ip || "");
    if (label !== "")
        return label;
    return "";
}

function trimDnsName(value) {
    var dns = String(value || "");
    if (dns.endsWith("."))
        return dns.slice(0, dns.length - 1);
    return dns;
}

function peerOwnerLabel(peer) {
    if (!peer)
        return "";
    var ownerName = String(peer.ownerName || "").trim();
    if (ownerName !== "")
        return ownerName;
    return String(peer.ownerLogin || "").trim();
}

function peerRouteLabel(peer) {
    if (!peer)
        return "";
    var currentAddress = String(peer.currentAddress || "").trim();
    if (currentAddress !== "")
        return currentAddress.indexOf(".") !== -1 || currentAddress.indexOf(":") !== -1
            ? "Direct " + currentAddress
            : "Relay " + currentAddress;
    return "";
}

function formatTimestamp(value) {
    var text = String(value || "").trim();
    if (text === "" || text.indexOf("0001-01-01") === 0)
        return "";
    var date = new Date(text);
    if (isNaN(date.getTime()))
        return "";
    var year = date.getFullYear();
    var month = String(date.getMonth() + 1).padStart(2, "0");
    var day = String(date.getDate()).padStart(2, "0");
    var hour = String(date.getHours()).padStart(2, "0");
    var minute = String(date.getMinutes()).padStart(2, "0");
    return year + "-" + month + "-" + day + " " + hour + ":" + minute;
}

function peerStatusDetail(peer) {
    if (!peer)
        return "";
    var routeLabel = peerRouteLabel(peer);
    if (routeLabel !== "")
        return routeLabel;
    if (!peer.online) {
        var lastSeen = formatTimestamp(peer.lastSeen);
        if (lastSeen !== "")
            return "Last seen " + lastSeen;
    }
    return "";
}

function vpnProfileTypeLabel(profile) {
    var type = String(profile && profile.type || "").toLowerCase();
    if (type === "wireguard")
        return "WireGuard";
    if (type === "tun")
        return "Tunnel";
    if (type === "vpn")
        return "VPN";
    return type !== "" ? type : "VPN";
}

function vpnProfileIcon(profile, isActive) {
    var type = String(profile && profile.type || "").toLowerCase();
    if (type === "wireguard")
        return isActive ? "link.svg" : "shield.svg";
    return isActive ? "globe-shield.svg" : "shield-lock.svg";
}

function vpnProfilePrimaryDetail(profile) {
    if (!profile)
        return "";
    var parts = [vpnProfileTypeLabel(profile)];
    var interfaceName = String(profile.interfaceName || profile.device || "").trim();
    if (interfaceName !== "" && interfaceName !== String(profile.name || "").trim())
        parts.push(interfaceName);
    return parts.join(" • ");
}

function vpnProfileSecondaryDetail(profile) {
    if (!profile)
        return "";
    var parts = [];
    var primaryAddress = String(profile.primaryAddress || "").trim();
    if (primaryAddress !== "")
        parts.push(primaryAddress);
    var routeCount = parseInt(profile.routeCount || "0", 10) || 0;
    if (routeCount > 0)
        parts.push(routeCount === 1 ? "1 route" : routeCount + " routes");
    var listenPort = parseInt(profile.listenPort || "0", 10) || 0;
    if (listenPort > 0)
        parts.push("UDP " + listenPort);
    if (profile.peerRoutes === true)
        parts.push("Peer routes");
    else if (profile.peerRoutes === false)
        parts.push("Manual routes");
    return parts.join(" • ");
}

function vpnProfileRouteDetail(profile) {
    if (!profile || !Array.isArray(profile.routeDestinations))
        return "";
    var routes = profile.routeDestinations
        .map(function(route) { return String(route || "").trim(); })
        .filter(function(route) { return route !== ""; });
    if (routes.length === 0)
        return "";
    return "Routes " + routes.join(", ");
}
