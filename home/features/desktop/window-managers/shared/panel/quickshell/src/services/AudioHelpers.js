.pragma library

function normalizeVolume(value, maxValue) {
    var limit = Number(maxValue);
    if (isNaN(limit) || !isFinite(limit) || limit <= 0)
        limit = 1.0;

    var numeric = Number(value);
    if (isNaN(numeric) || !isFinite(numeric))
        return 0;

    if (numeric < 0)
        return 0;

    return Math.min(numeric, limit);
}

function parseWpctlVolume(output, maxValue) {
    var text = String(output || "");
    var match = text.match(/Volume:\s+([0-9]+(?:\.[0-9]+)?)/);
    if (!match)
        return null;

    return {
        volume: normalizeVolume(match[1], maxValue),
        muted: text.indexOf("[MUTED]") !== -1
    };
}
