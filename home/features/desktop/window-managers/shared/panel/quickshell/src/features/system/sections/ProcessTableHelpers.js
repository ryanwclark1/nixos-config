.pragma library

function formatKiB(kib) {
    var value = Number(kib || 0);
    if (value <= 0)
        return "0 KiB";
    if (value >= 1024 * 1024)
        return (value / (1024 * 1024)).toFixed(1) + " GiB";
    if (value >= 1024)
        return (value / 1024).toFixed(1) + " MiB";
    return Math.round(value) + " KiB";
}

function fallbackText(value) {
    return String(value || "").trim() === "" ? "Unavailable" : String(value);
}

function detailStatusColor(status, Colors) {
    if (status === "ready")
        return Colors.success;
    if (status === "loading")
        return Colors.warning;
    if (status === "permission-limited")
        return Colors.warning;
    if (status === "terminated" || status === "error")
        return Colors.error;
    return Colors.textDisabled;
}

function actionStatusColor(status, Colors) {
    if (status === "success")
        return Colors.success;
    if (status === "pending")
        return Colors.warning;
    if (status === "error")
        return Colors.error;
    return Colors.textDisabled;
}
