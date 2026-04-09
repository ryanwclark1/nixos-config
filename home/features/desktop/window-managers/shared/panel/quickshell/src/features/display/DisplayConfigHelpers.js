.pragma library

function _number(value, fallbackValue) {
    var parsed = Number(value);
    return isFinite(parsed) ? parsed : fallbackValue;
}

function parseJsonOutput(rawText, fallbackValue) {
    var text = String(rawText || "").trim();
    if (text === "")
        return fallbackValue;

    var parseError = null;
    try {
        return JSON.parse(text);
    } catch (e) {
        parseError = e;
    }

    var lines = text.split("\n");
    for (var i = 0; i < lines.length; i++) {
        var candidate = lines.slice(i).join("\n").trim();
        if (candidate === "")
            continue;
        var firstChar = candidate.charAt(0);
        if (firstChar !== "{" && firstChar !== "[")
            continue;
        try {
            return JSON.parse(candidate);
        } catch (_) {
        }
    }

    throw parseError;
}

function normalizeMonitorList(rawMonitors) {
    var source = Array.isArray(rawMonitors) ? rawMonitors : [];
    var result = [];

    for (var i = 0; i < source.length; i++) {
        var mon = source[i] || {};
        var width = _number(mon.width, _number(mon.currentMode && mon.currentMode.width, 1920));
        var height = _number(mon.height, _number(mon.currentMode && mon.currentMode.height, 1080));
        var refreshRate = _number(
            mon.refreshRate,
            _number(mon.refresh, _number(mon.currentMode && mon.currentMode.refreshRate, 60.0))
        );
        var scale = _number(mon.scale, 1.0);
        var x = _number(mon.x, _number(mon.transformX, 0));
        var y = _number(mon.y, _number(mon.transformY, 0));

        var modes = [];
        var availableModes = Array.isArray(mon.availableModes)
            ? mon.availableModes
            : (Array.isArray(mon.modes) ? mon.modes : []);

        for (var j = 0; j < availableModes.length; j++) {
            var mode = availableModes[j];
            if (typeof mode === "string") {
                modes.push(mode);
                continue;
            }

            if (!mode)
                continue;

            var modeWidth = _number(mode.width, 0);
            var modeHeight = _number(mode.height, 0);
            var modeRefresh = _number(mode.refreshRate, _number(mode.refresh, 0));
            if (modeWidth > 0 && modeHeight > 0 && modeRefresh > 0)
                modes.push(modeWidth + "x" + modeHeight + "@" + modeRefresh.toFixed(2) + "Hz");
        }

        var currentMode = width + "x" + height + "@" + refreshRate.toFixed(2) + "Hz";
        if (modes.indexOf(currentMode) === -1)
            modes.unshift(currentMode);

        result.push({
            id: mon.id !== undefined ? mon.id : i,
            name: String(mon.name || mon.output || ("Monitor " + (i + 1))),
            description: String(mon.description || mon.make || mon.model || ""),
            width: width,
            height: height,
            refreshRate: refreshRate,
            x: x,
            y: y,
            scale: scale,
            availableModes: modes,
            dragX: 0,
            dragY: 0
        });
    }

    return result;
}

function fallbackMonitorsFromScreens(screens) {
    var source = Array.isArray(screens) ? screens : [];
    var result = [];
    var xCursor = 0;

    for (var i = 0; i < source.length; i++) {
        var screen = source[i] || {};
        var width = Math.max(1, Math.round(_number(screen.width, 1920)));
        var height = Math.max(1, Math.round(_number(screen.height, 1080)));
        var scale = _number(screen.devicePixelRatio, _number(screen.scaleFactor, 1.0));

        result.push({
            id: "screen-" + i,
            name: String(screen.name || ("Monitor " + (i + 1))),
            description: "Detected by Quickshell",
            width: width,
            height: height,
            refreshRate: 60.0,
            x: xCursor,
            y: 0,
            scale: scale,
            availableModes: [width + "x" + height + "@60.00Hz"],
            dragX: 0,
            dragY: 0
        });

        xCursor += width;
    }

    return result;
}

// Extract unique resolutions from a modes array (e.g. ["2560x1440@165.00Hz", ...])
function uniqueResolutions(modes) {
    var seen = {};
    var result = [];
    for (var i = 0; i < modes.length; i++) {
        var parts = modes[i].split("@");
        var res = parts[0];
        if (!seen[res]) { seen[res] = true; result.push(res); }
    }
    return result;
}

// Get available refresh rates for a given resolution string
function ratesForResolution(modes, resolution) {
    var result = [];
    for (var i = 0; i < modes.length; i++) {
        var at = modes[i].indexOf("@");
        if (at === -1) continue;
        var res = modes[i].substring(0, at);
        if (res === resolution) {
            var rate = modes[i].substring(at + 1).replace("Hz", "");
            result.push(rate);
        }
    }
    return result;
}

// Deep-clone a monitor object
function cloneMonitor(m) {
    return {
        id: m.id, name: m.name, description: m.description,
        width: m.width, height: m.height, refreshRate: m.refreshRate,
        x: m.x, y: m.y, scale: m.scale,
        availableModes: m.availableModes,
        dragX: m.dragX, dragY: m.dragY
    };
}

// ── Quick-layout presets ──────────────────────────────────────────
// Each returns a new monitors array with updated x/y positions.
// The caller is responsible for re-syncing drag positions + scale.

// Mirror: stack all monitors at (0,0)
function arrangeMirror(monitors) {
    var result = [];
    for (var i = 0; i < monitors.length; i++) {
        var m = cloneMonitor(monitors[i]);
        m.x = 0;
        m.y = 0;
        result.push(m);
    }
    return result;
}

// Extend: tile monitors left-to-right, vertically centered
function arrangeExtend(monitors) {
    if (monitors.length === 0) return [];
    var result = [];
    var xCursor = 0;
    // Find max height for vertical centering
    var maxH = 0;
    for (var i = 0; i < monitors.length; i++) {
        var h = monitors[i].height / monitors[i].scale;
        if (h > maxH) maxH = h;
    }
    for (var j = 0; j < monitors.length; j++) {
        var m = cloneMonitor(monitors[j]);
        var scaledH = m.height / m.scale;
        m.x = Math.round(xCursor);
        m.y = Math.round((maxH - scaledH) / 2);
        xCursor += m.width / m.scale;
        result.push(m);
    }
    return result;
}

// Primary only: keep first monitor at (0,0), move others far off-screen
// The compositor will effectively disable the off-screen ones on Apply
function arrangePrimaryOnly(monitors) {
    if (monitors.length === 0) return [];
    var result = [];
    var primary = cloneMonitor(monitors[0]);
    primary.x = 0;
    primary.y = 0;
    result.push(primary);
    for (var i = 1; i < monitors.length; i++) {
        var m = cloneMonitor(monitors[i]);
        // Mirror primary position — compositor handles disable
        m.x = -99999;
        m.y = 0;
        result.push(m);
    }
    return result;
}

// Compute scale factor and offsets for fitting monitors in canvas
function computeScaleFactor(monitors, canvasW, canvasH) {
    if (monitors.length === 0) return { scale: 1.0, offsetX: 0, offsetY: 0 };
    var minX = 0, minY = 0, maxX = 0, maxY = 0;
    for (var i = 0; i < monitors.length; i++) {
        var m = monitors[i];
        if (m.x < minX) minX = m.x;
        if (m.y < minY) minY = m.y;
        if (m.x + m.width  > maxX) maxX = m.x + m.width;
        if (m.y + m.height > maxY) maxY = m.y + m.height;
    }
    var totalW = maxX - minX;
    var totalH = maxY - minY;
    if (totalW === 0 || totalH === 0) return { scale: 1.0, offsetX: 0, offsetY: 0 };
    var padding = 40;
    var fitW = (canvasW - padding * 2) / totalW;
    var fitH = (canvasH - padding * 2) / totalH;
    var s = Math.min(fitW, fitH, 0.35);
    s = Math.max(s, 0.05);
    var offsetX = (canvasW - totalW * s) / 2 - minX * s;
    var offsetY = (canvasH - totalH * s) / 2 - minY * s;
    return { scale: s, offsetX: offsetX, offsetY: offsetY };
}
