function splitTaggedLine(line) {
    var text = String(line || "");
    var separatorIndex = text.indexOf("\t");
    if (separatorIndex < 0)
        return null;
    return {
        key: text.slice(0, separatorIndex).trim(),
        value: text.slice(separatorIndex + 1).trim()
    };
}

export function parseTaggedStats(rawText) {
    var next = {
        cpuRaw: "",
        ramUsedText: "",
        ramTotalText: "",
        ramFrac: "",
        swapUsedText: "",
        swapTotalText: "",
        diskPct: "",
        netRx: "",
        netTx: ""
    };

    var lines = String(rawText || "").replace(/\r/g, "").split("\n");
    for (var i = 0; i < lines.length; i++) {
        var parsed = splitTaggedLine(lines[i]);
        if (!parsed || parsed.key === "")
            continue;
        switch (parsed.key) {
            case "cpu_raw":
                next.cpuRaw = parsed.value;
                break;
            case "ram_used_text":
                next.ramUsedText = parsed.value;
                break;
            case "ram_total_text":
                next.ramTotalText = parsed.value;
                break;
            case "ram_frac":
                next.ramFrac = parsed.value;
                break;
            case "swap_used_text":
                next.swapUsedText = parsed.value;
                break;
            case "swap_total_text":
                next.swapTotalText = parsed.value;
                break;
            case "disk_pct":
                next.diskPct = parsed.value;
                break;
            case "net_rx":
                next.netRx = parsed.value;
                break;
            case "net_tx":
                next.netTx = parsed.value;
                break;
        }
    }

    return next;
}

export function formatPercent(value) {
    var parsed = Number(value);
    if (!isFinite(parsed) || parsed < 0)
        return "--";
    var clamped = Math.max(0, Math.min(1, parsed));
    return Math.round(clamped * 100) + "%";
}

export function formatUsedTotal(usedText, totalText, fallback) {
    var used = String(usedText || "").trim();
    var total = String(totalText || "").trim();
    if (used !== "" && total !== "")
        return used + " / " + total;
    if (used !== "")
        return used;
    if (total !== "")
        return total;
    return fallback === undefined ? "--" : fallback;
}
