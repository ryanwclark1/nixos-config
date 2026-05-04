.pragma library

var HORIZONTAL_DEFAULT_PRESET = "horizontal-default";
var VERTICAL_BALANCED_PRESET = "vertical-balanced";
var CUSTOM_PRESET = "custom";

var PRESET_SECTION_WIDGET_TYPES = {};

PRESET_SECTION_WIDGET_TYPES[HORIZONTAL_DEFAULT_PRESET] = {
    left: ["logo", "workspaces", "windowTitle", "taskbar", "cpuStatus", "ramStatus"],
    center: ["dateTime", "mediaBar", "updates", "idleInhibitor"],
    right: ["weather", "network", "bluetooth", "audio", "music", "privacy", "voxtype", "serviceMonitor", "forge", "recording", "battery", "printer", "aiChat", "notepad", "controlCenter", "tray", "clipboard", "keyboardLayout", "notifications"]
};

PRESET_SECTION_WIDGET_TYPES[VERTICAL_BALANCED_PRESET] = {
    left: ["logo", "workspaces", "specialWorkspaces", "taskbar"],
    center: ["mediaBar", "updates", "idleInhibitor"],
    right: ["network", "audio", "battery", "voxtype", "serviceMonitor", "forge", "dateTime", "notifications", "tray", "controlCenter"]
};

function _clone(value) {
    return JSON.parse(JSON.stringify(value));
}

function _normalizePresetName(presetName) {
    var preset = String(presetName || "");
    if (preset === HORIZONTAL_DEFAULT_PRESET || preset === VERTICAL_BALANCED_PRESET || preset === CUSTOM_PRESET)
        return preset;
    return "";
}

function isAutoManagedPreset(presetName) {
    var preset = _normalizePresetName(presetName);
    return preset === HORIZONTAL_DEFAULT_PRESET || preset === VERTICAL_BALANCED_PRESET;
}

function defaultPresetForPosition(positionOrBar) {
    var position = typeof positionOrBar === "string"
        ? positionOrBar
        : String((positionOrBar && positionOrBar.position) || "top");
    return position === "left" || position === "right"
        ? VERTICAL_BALANCED_PRESET
        : HORIZONTAL_DEFAULT_PRESET;
}

function presetSectionWidgetTypes(presetName) {
    var preset = _normalizePresetName(presetName);
    if (!isAutoManagedPreset(preset))
        preset = HORIZONTAL_DEFAULT_PRESET;
    return _clone(PRESET_SECTION_WIDGET_TYPES[preset]);
}

function verticalPresetSection(widgetType) {
    var targetType = String(widgetType || "");
    var sections = PRESET_SECTION_WIDGET_TYPES[VERTICAL_BALANCED_PRESET];
    var keys = ["left", "center", "right"];
    for (var i = 0; i < keys.length; ++i) {
        var section = keys[i];
        var types = sections[section] || [];
        if (types.indexOf(targetType) !== -1)
            return section;
    }
    return "";
}

function _defaultSettings(defaultSettingsLookup, widgetType) {
    if (!defaultSettingsLookup)
        return {};
    var defaults = defaultSettingsLookup(widgetType);
    return defaults && typeof defaults === "object" ? _clone(defaults) : {};
}

function _settingsEqual(left, right) {
    return JSON.stringify(left || {}) === JSON.stringify(right || {});
}

function matchesPresetSectionWidgets(sectionWidgets, presetName, defaultSettingsLookup) {
    if (!sectionWidgets || typeof sectionWidgets !== "object")
        return false;

    var expected = presetSectionWidgetTypes(presetName);
    var sections = ["left", "center", "right"];

    for (var i = 0; i < sections.length; ++i) {
        var section = sections[i];
        var actualItems = Array.isArray(sectionWidgets[section]) ? sectionWidgets[section] : [];
        var expectedTypes = expected[section] || [];

        if (actualItems.length !== expectedTypes.length)
            return false;

        for (var j = 0; j < expectedTypes.length; ++j) {
            var widget = actualItems[j] || {};
            var expectedType = expectedTypes[j];
            if (String(widget.widgetType || "") !== expectedType)
                return false;
            if (widget.enabled === false)
                return false;
            if (!_settingsEqual(widget.settings, _defaultSettings(defaultSettingsLookup, expectedType)))
                return false;
        }
    }

    return true;
}

function resolvePresetForBar(position, storedPresetName, sectionWidgets, defaultSettingsLookup) {
    var storedPreset = _normalizePresetName(storedPresetName);
    if (storedPreset !== "")
        return storedPreset;

    var horizontalMatch = matchesPresetSectionWidgets(sectionWidgets, HORIZONTAL_DEFAULT_PRESET, defaultSettingsLookup);
    var verticalMatch = matchesPresetSectionWidgets(sectionWidgets, VERTICAL_BALANCED_PRESET, defaultSettingsLookup);
    var defaultPreset = defaultPresetForPosition(position);

    if (defaultPreset === VERTICAL_BALANCED_PRESET) {
        if (verticalMatch || horizontalMatch)
            return VERTICAL_BALANCED_PRESET;
        return CUSTOM_PRESET;
    }

    if (horizontalMatch)
        return HORIZONTAL_DEFAULT_PRESET;
    if (verticalMatch)
        return VERTICAL_BALANCED_PRESET;
    return CUSTOM_PRESET;
}
