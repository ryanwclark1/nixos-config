.pragma library

function isWallpaperFolderPathValid(path) {
    var p = (path || "").trim();
    return p.length > 0 && (p.indexOf("/") === 0 || p === "~" || p.indexOf("~/") === 0);
}

function normalizeSolidColor(value) {
    var v = (value || "").trim();
    if (v.indexOf("#") === 0)
        v = v.slice(1);
    v = v.toLowerCase();
    if (/^[0-9a-f]{6}$/.test(v))
        return v + "ff";
    if (/^[0-9a-f]{8}$/.test(v))
        return v;
    return "";
}

function imageSource(path, unsupportedMap) {
    if (!path || (unsupportedMap && unsupportedMap[path]))
        return "";
    return "file://" + path;
}

function sanitizeSolidColorMap(value) {
    var out = {};
    if (!value || typeof value !== "object")
        return out;
    var keys = Object.keys(value);
    for (var i = 0; i < keys.length; i++) {
        var key = String(keys[i] || "");
        if (!key.length)
            continue;
        var color = normalizeSolidColor(value[key]);
        if (!color)
            continue;
        out[key] = color;
    }
    return out;
}

function sanitizeRecentSolidColors(value) {
    var out = [];
    if (!Array.isArray(value))
        return out;
    for (var i = 0; i < value.length; i++) {
        var color = normalizeSolidColor(value[i]);
        if (!color || out.indexOf(color) >= 0)
            continue;
        out.push(color);
        if (out.length >= 12)
            break;
    }
    return out;
}

function rememberRecentSolidColor(hex8, currentList) {
    var normalized = normalizeSolidColor(hex8);
    if (!normalized)
        return currentList || [];
    var list = (currentList || []).slice();
    var next = [normalized];
    for (var i = 0; i < list.length; i++) {
        if ((list[i] || "").toLowerCase() !== normalized)
            next.push((list[i] || "").toLowerCase());
    }
    if (next.length > 12)
        next = next.slice(0, 12);
    return next;
}

function resolveMonitor(selectedMonitor) {
    return selectedMonitor === "__all__" ? "" : selectedMonitor;
}
