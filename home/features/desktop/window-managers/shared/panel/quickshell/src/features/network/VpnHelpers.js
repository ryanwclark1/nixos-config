.pragma library

function statusColor(statusKey, colors) {
    if (statusKey === "connected")
        return colors.success;
    if (statusKey === "stopped")
        return colors.warning;
    if (statusKey === "disconnected")
        return colors.textSecondary;
    return colors.textDisabled;
}
