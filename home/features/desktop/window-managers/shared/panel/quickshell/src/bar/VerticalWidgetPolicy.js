.pragma library

var VERTICAL_HIDE_WIDGETS = [
    "windowTitle",
    "ssh"
];

var VERTICAL_SHORT_LABEL_WIDGETS = [
    "keyboardLayout"
];

var VERTICAL_COMPACT_WIDGETS = [
    "cpuStatus",
    "ramStatus",
    "gpuStatus",
    "diskStatus",
    "networkStatus"
];

var VERTICAL_ICON_WIDGETS = [
    "logo",
    "dateTime",
    "updates",
    "modelUsage",
    "weather",
    "market",
    "vpn",
    "network",
    "bluetooth",
    "audio",
    "music",
    "privacy",
    "voxtype",
    "recording",
    "battery",
    "printer",
    "notifications",
    "aiChat",
    "notepad",
    "controlCenter",
    "clipboard",
    "screenshot",
    "pomodoro",
    "todo",
    "gameMode",
    "nightLight",
    "personality"
];

var VERTICAL_NATIVE_WIDGETS = [
    "workspaces",
    "specialWorkspaces",
    "taskbar",
    "tray",
    "cava",
    "idleInhibitor",
    "mediaBar",
    "spacer",
    "separator"
];

function widgetTypeName(widgetOrType) {
    if (typeof widgetOrType === "string")
        return widgetOrType;
    return widgetOrType ? String(widgetOrType.widgetType || "") : "";
}

function _typeInList(widgetType, values) {
    return values.indexOf(widgetType) !== -1;
}

function verticalWidgetBehavior(widgetOrType) {
    var widgetType = widgetTypeName(widgetOrType);

    if (_typeInList(widgetType, VERTICAL_HIDE_WIDGETS))
        return "hidden";
    if (_typeInList(widgetType, VERTICAL_SHORT_LABEL_WIDGETS))
        return "short-label";
    if (_typeInList(widgetType, VERTICAL_COMPACT_WIDGETS))
        return "compact";
    if (_typeInList(widgetType, VERTICAL_ICON_WIDGETS))
        return "icon";
    if (_typeInList(widgetType, VERTICAL_NATIVE_WIDGETS))
        return "native";
    return "unverified";
}

function isWidgetHiddenInVertical(widgetOrType) {
    return verticalWidgetBehavior(widgetOrType) === "hidden";
}

function shouldCollapseVerticalOverflow(widgetOrType) {
    return verticalWidgetBehavior(widgetOrType) === "unverified";
}

function verticalHintLabel(widgetOrType) {
    var behavior = verticalWidgetBehavior(widgetOrType);
    if (behavior === "hidden")
        return "Vertical: Hidden";
    if (behavior === "short-label")
        return "Vertical: Short Label";
    if (behavior === "compact")
        return "Vertical: Compact";
    if (behavior === "icon")
        return "Vertical: Icon";
    if (behavior === "native")
        return "Vertical: Native";
    return "Vertical: Unverified";
}

function verticalBehaviorSortRank(widgetOrType) {
    var behavior = verticalWidgetBehavior(widgetOrType);
    if (behavior === "native")
        return 0;
    if (behavior === "compact")
        return 1;
    if (behavior === "icon")
        return 2;
    if (behavior === "short-label")
        return 3;
    if (behavior === "hidden")
        return 4;
    return 5;
}
