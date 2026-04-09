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
