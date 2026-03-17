.pragma library

function widgetSettings(widgetInstance) {
    return widgetInstance && widgetInstance.settings ? widgetInstance.settings : {};
}

function widgetDiagnosticId(widgetInstance, barConfig) {
    var type = widgetInstance ? String(widgetInstance.widgetType || "unknown") : "unknown";
    var instanceId = widgetInstance ? String(widgetInstance.instanceId || "") : "";
    var barId = barConfig ? String(barConfig.id || "bar") : "bar";
    return "bar=" + barId + " widget=" + type + (instanceId !== "" ? " instance=" + instanceId : "");
}

function itemLayoutFootprint(item, vertical) {
    if (!item)
        return 0;

    var implicitWidth = Number(item.implicitWidth);
    var implicitHeight = Number(item.implicitHeight);

    implicitWidth = isNaN(implicitWidth) ? 0 : implicitWidth;
    implicitHeight = isNaN(implicitHeight) ? 0 : implicitHeight;

    return vertical ? implicitHeight : implicitWidth;
}

function itemOccupiesSpace(item, vertical) {
    if (!item || item.visible === false)
        return false;
    return itemLayoutFootprint(item, vertical) > 0;
}

function compactPercentText(value) {
    return Math.round(Math.max(0, Math.min(1, Number(value) || 0)) * 100) + "%";
}

function widgetValueStyle(widgetInstance, widgetType) {
    var settings = widgetSettings(widgetInstance);
    var fallback = widgetType === "ramStatus" ? "usage" : "percent";
    var style = String(settings.valueStyle || fallback);
    if (widgetType === "ramStatus")
        return ["usage", "percent"].indexOf(style) !== -1 ? style : fallback;
    return ["percent", "usage", "usageTemp"].indexOf(style) !== -1 ? style : fallback;
}

function statDisplayText(widgetType, widgetInstance, SystemStatus) {
    var style = widgetValueStyle(widgetInstance, widgetType);
    if (widgetType === "cpuStatus") {
        if (style === "usageTemp")
            return SystemStatus.cpuUsage + " • " + SystemStatus.cpuTemp;
        return SystemStatus.cpuUsage;
    }
    if (widgetType === "ramStatus") {
        if (style === "percent")
            return compactPercentText(SystemStatus.ramPercent);
        return SystemStatus.ramUsage;
    }
    if (widgetType === "gpuStatus") {
        if (style === "usageTemp")
            return SystemStatus.gpuUsage + " • " + SystemStatus.gpuTemp;
        return SystemStatus.gpuUsage;
    }
    return "";
}

function compactStatDisplayText(widgetType, widgetInstance, SystemStatus) {
    var style = widgetValueStyle(widgetInstance, widgetType);
    if (style === "percent")
        return statDisplayText(widgetType, widgetInstance, SystemStatus);

    if (widgetType === "ramStatus") {
        var ramUsage = statDisplayText(widgetType, widgetInstance, SystemStatus);
        return ramUsage.length <= 5 ? ramUsage : compactPercentText(SystemStatus.ramPercent);
    }

    if (style === "usageTemp")
        return widgetType === "cpuStatus" ? SystemStatus.cpuUsage : SystemStatus.gpuUsage;

    var usage = statDisplayText(widgetType, widgetInstance, SystemStatus);
    return usage.length <= 5 ? usage : (widgetType === "cpuStatus" ? SystemStatus.cpuUsage : SystemStatus.gpuUsage);
}

function statTooltipText(widgetType, widgetInstance, SystemStatus) {
    if (widgetType === "cpuStatus")
        return "CPU " + statDisplayText(widgetType, widgetInstance, SystemStatus);
    if (widgetType === "ramStatus")
        return "RAM " + statDisplayText(widgetType, widgetInstance, SystemStatus) + " • " + compactPercentText(SystemStatus.ramPercent);
    if (widgetType === "gpuStatus")
        return "GPU " + statDisplayText(widgetType, widgetInstance, SystemStatus);
    return "";
}

function widgetDisplayMode(widgetInstance) {
    var settings = widgetSettings(widgetInstance);
    var mode = String(settings.displayMode || "auto");
    return ["auto", "full", "compact", "icon"].indexOf(mode) !== -1 ? mode : "auto";
}

function widgetSummaryDisplayMode(widgetInstance) {
    var settings = widgetSettings(widgetInstance);
    var mode = String(settings.displayMode || "auto");
    return ["auto", "full", "icon"].indexOf(mode) !== -1 ? mode : "auto";
}

function isCompactStatWidget(widgetInstance, vertical) {
    var mode = widgetDisplayMode(widgetInstance);
    if (mode === "compact")
        return true;
    if (mode === "icon" || mode === "full")
        return false;
    return vertical;
}

function isIconOnlyStatWidget(widgetInstance) {
    return widgetDisplayMode(widgetInstance) === "icon";
}

function isSummaryWidgetIconOnly(widgetInstance, vertical) {
    var mode = widgetSummaryDisplayMode(widgetInstance);
    if (mode === "icon")
        return true;
    if (mode === "full")
        return false;
    return vertical;
}

function isSummaryWidgetFull(widgetInstance, vertical) {
    return !isSummaryWidgetIconOnly(widgetInstance, vertical);
}

function widgetIntegerSetting(widgetInstance, key, fallback, minValue, maxValue) {
    var settings = widgetSettings(widgetInstance);
    var parsed = parseInt(settings[key] !== undefined ? settings[key] : fallback, 10);
    if (isNaN(parsed))
        parsed = fallback;
    if (minValue !== undefined)
        parsed = Math.max(minValue, parsed);
    if (maxValue !== undefined)
        parsed = Math.min(maxValue, parsed);
    return parsed;
}

function widgetBooleanSetting(widgetInstance, key, fallback) {
    var settings = widgetSettings(widgetInstance);
    if (settings[key] === undefined)
        return fallback;
    return settings[key] !== false;
}

function widgetStringSetting(widgetInstance, key, fallback, allowedValues) {
    var settings = widgetSettings(widgetInstance);
    var value = String(settings[key] !== undefined ? settings[key] : fallback);
    if (allowedValues && allowedValues.indexOf(value) === -1)
        return fallback;
    return value;
}

function triggerWidgetIconOnly(widgetInstance) {
    var mode = widgetStringSetting(widgetInstance, "displayMode", "icon", ["icon", "full"]);
    return mode !== "full";
}

function triggerWidgetLabel(widgetInstance, fallback) {
    var settings = widgetSettings(widgetInstance);
    var label = String(settings.labelText !== undefined ? settings.labelText : fallback);
    return label.trim().length > 0 ? label : fallback;
}
