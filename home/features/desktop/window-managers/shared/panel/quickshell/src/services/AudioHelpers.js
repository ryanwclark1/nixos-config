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
