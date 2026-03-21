.pragma library

// percent: 0..1 thresholds; ok/warn/danger are QML color values passed from callers.
function usageTierColor(percent, okColor, warnColor, dangerColor, warnAt, dangerAt) {
    var p = Number(percent);
    if (!isFinite(p))
        p = 0;
    if (p >= dangerAt)
        return dangerColor;
    if (p >= warnAt)
        return warnColor;
    return okColor;
}
