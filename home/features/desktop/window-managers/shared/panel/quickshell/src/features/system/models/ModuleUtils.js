.pragma library

function formatRate(bytes) {
    var value = Number(bytes || 0);
    if (value < 1024)
        return Math.round(value) + " B/s";
    if (value < 1048576)
        return (value / 1024).toFixed(1) + " KB/s";
    if (value < 1073741824)
        return (value / 1048576).toFixed(1) + " MB/s";
    return (value / 1073741824).toFixed(2) + " GB/s";
}

function formatBytes(bytes) {
    var value = Number(bytes);
    if (!isFinite(value) || value < 0)
        return "Unavailable";
    if (value >= 1024 * 1024 * 1024)
        return (value / (1024 * 1024 * 1024)).toFixed(1) + " GiB";
    if (value >= 1024 * 1024)
        return (value / (1024 * 1024)).toFixed(1) + " MiB";
    if (value >= 1024)
        return (value / 1024).toFixed(1) + " KiB";
    return Math.round(value) + " B";
}

function arrayMax(values) {
    var maxValue = 0;
    for (var i = 0; i < values.length; ++i)
        maxValue = Math.max(maxValue, Number(values[i] || 0));
    return maxValue;
}

function formatAge(timestampMs, clockTick) {
    void clockTick;
    var value = Number(timestampMs || 0);
    if (value <= 0)
        return "waiting";
    var seconds = Math.max(0, Math.round((Date.now() - value) / 1000));
    if (seconds < 1)
        return "now";
    if (seconds < 60)
        return String(seconds) + "s ago";
    var minutes = Math.floor(seconds / 60);
    var remainder = seconds % 60;
    return String(minutes) + "m " + String(remainder) + "s ago";
}
