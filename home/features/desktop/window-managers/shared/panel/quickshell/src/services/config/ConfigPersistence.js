.pragma library

// ── Domain imports ───────────────────────────────────────────────
// Each domain module exports a sectionKey + maps array, and optionally
// sub-sections as named objects with their own sectionKey/maps/extraKeys.
.import "domains/bar.js" as Bar
.import "domains/glass.js" as Glass
.import "domains/notifications.js" as Notifications
.import "domains/time.js" as Time
.import "domains/weather.js" as Weather
.import "domains/audio.js" as Audio
.import "domains/ai.js" as Ai
.import "domains/wallpaper.js" as Wallpaper
.import "domains/appearance.js" as Appearance
.import "domains/theme.js" as Theme
.import "domains/power.js" as Power
.import "domains/panels.js" as Panels
.import "domains/features.js" as Features
.import "domains/misc.js" as Misc
.import "domains/launcher.js" as Launcher

// ── Assemble _MAPS from domain modules ──────────────────────────
// Primary sections come from each module's top-level sectionKey/maps.
// Sub-sections (e.g. Power.nightLight, Panels.controlCenter) are nested
// objects with their own sectionKey/maps.

var _allDomains = [
    Bar,
    Glass,
    Notifications,
    Time,
    Weather,
    Audio,
    Ai,
    Wallpaper,
    Appearance,
    Theme,
    Power,
    Panels,
    Features,
    Misc,
    Launcher
];

// Collect sub-sections from domain modules.
// Each domain may export additional named objects with sectionKey/maps.
var _SUB_SECTIONS = [
    Power.nightLight,
    Panels.controlCenter,
    Panels.osd,
    Panels.dock,
    Panels.powerMenu,
    Panels.lockScreen,
    Features.recording,
    Features.privacy,
    Features.colorPicker,
    Features.notepad,
    Features.hooks,
    Features.osk,
    Features.hotCorners,
    Features.screenBorders,
    Misc.modelUsage,
    Misc.desktopWidgets,
    Misc.background,
    Misc.workspaces,
    Misc.displayProfiles,
    Misc.state
];

var _MAPS = (function() {
    var m = {};
    var i;
    for (i = 0; i < _allDomains.length; i++)
        m[_allDomains[i].sectionKey] = _allDomains[i].maps;
    for (i = 0; i < _SUB_SECTIONS.length; i++)
        m[_SUB_SECTIONS[i].sectionKey] = _SUB_SECTIONS[i].maps;
    return m;
})();

// ── Extra section keys (for validation of non-mapped keys) ──────
var _EXTRA_SECTION_KEYS = (function() {
    var result = {};
    var i;
    for (i = 0; i < _allDomains.length; i++) {
        if (_allDomains[i].extraKeys)
            result[_allDomains[i].sectionKey] = _allDomains[i].extraKeys;
    }
    for (i = 0; i < _SUB_SECTIONS.length; i++) {
        if (_SUB_SECTIONS[i].extraKeys)
            result[_SUB_SECTIONS[i].sectionKey] = _SUB_SECTIONS[i].extraKeys;
    }
    return result;
})();

// ── Constants ────────────────────────────────────────────────────

var REMOVED_PLUGIN_IDS = ["quickshell.ssh.monitor"];

var CURRENT_VERSION = 4;

// Migration functions: each takes `data` and mutates it in place.
// Index corresponds to the version being migrated FROM (0 → 1, 1 → 2, etc.).
var _MIGRATIONS = [
    // v0 → v1: Baseline. Move REMOVED_PLUGIN_IDS sanitization into migration.
    function(data) {
        if (data.plugins) {
            if (data.plugins.disabled)
                data.plugins.disabled = _sanitizeDisabledPlugins(data.plugins.disabled);
            if (data.plugins.launcherTriggers)
                data.plugins.launcherTriggers = _sanitizePluginMap(data.plugins.launcherTriggers);
            if (data.plugins.launcherNoTrigger)
                data.plugins.launcherNoTrigger = _sanitizePluginMap(data.plugins.launcherNoTrigger);
            if (data.plugins.settings)
                data.plugins.settings = _sanitizePluginMap(data.plugins.settings);
        }
    },
    // v1 → v2: Ensure wallpaper transition defaults exist.
    function(data) {
        if (!data.wallpaper) data.wallpaper = {};
        if (data.wallpaper.transitionType === undefined)
            data.wallpaper.transitionType = "fade";
        if (data.wallpaper.transitionDuration === undefined)
            data.wallpaper.transitionDuration = 1500;
        if (data.wallpaper.useShellRenderer === undefined)
            data.wallpaper.useShellRenderer = false;
    },
    // v2 → v3: Drop dead legacy opacity keys.
    function(data) {
        if (data.glass && typeof data.glass === "object") {
            delete data.glass.opacity;
            delete data.glass.settingsSurfaceOpacity;
        }
    },
    // v3 → v4: Add enabledPanels default.
    function(data) {
        if (!data.panels) data.panels = {};
        if (data.panels.enabledPanels === undefined)
            data.panels.enabledPanels = [
                "notifCenter", "controlCenter", "notepad", "aiChat",
                "commandPalette", "powerMenu", "colorPicker", "displayConfig",
                "fileBrowser", "systemMonitor"
            ];
    }
];

function _migrateData(data) {
    var version = (typeof data._version === "number") ? data._version : 0;
    while (version < CURRENT_VERSION && version < _MIGRATIONS.length) {
        _MIGRATIONS[version](data);
        version++;
    }
    data._version = CURRENT_VERSION;
}

// Warn about unknown keys in config data — helps catch typos in manual edits.
function _validateData(data) {
    if (!data) return [];
    var warnings = [];
    var knownSections = {};
    for (var section in _MAPS)
        knownSections[section] = true;
    // Also known: _version, bars, plugins (handled specially)
    knownSections["_version"] = true;
    knownSections["bars"] = true;
    knownSections["plugins"] = true;

    for (var key in data) {
        if (!knownSections[key]) {
            var msg = "ConfigPersistence: unknown top-level key '" + key + "'";
            console.warn(msg);
            warnings.push(msg);
        }
    }

    // Check keys within known sections
    for (var sect in _MAPS) {
        if (!data[sect] || typeof data[sect] !== "object") continue;
        var knownKeys = {};
        var entries = _MAPS[sect];
        for (var i = 0; i < entries.length; i++)
            knownKeys[entries[i][0]] = true;
        var extraKeys = _EXTRA_SECTION_KEYS[sect] || {};
        for (var extraKey in extraKeys)
            knownKeys[extraKey] = true;
        for (var sKey in data[sect]) {
            if (!knownKeys[sKey]) {
                var sMsg = "ConfigPersistence: unknown key '" + sKey + "' in section '" + sect + "'";
                console.warn(sMsg);
                warnings.push(sMsg);
            }
        }
    }
    return warnings;
}

function _sanitizeDisabledPlugins(list) {
    if (!Array.isArray(list))
        return [];
    return list.filter(function(id) {
        return REMOVED_PLUGIN_IDS.indexOf(String(id || "")) === -1;
    });
}

function _sanitizePluginMap(mapValue) {
    var source = mapValue && typeof mapValue === "object" ? mapValue : {};
    var next = {};
    for (var key in source) {
        if (REMOVED_PLUGIN_IDS.indexOf(String(key || "")) !== -1)
            continue;
        next[key] = source[key];
    }
    return next;
}

function initializeDefaults(config) {
    config.barConfigs = config.normalizeBarConfigs([], {});
    config.ensureSelectedBar();
    config.syncLegacyBarSettingsFromPrimary();
}

function _applyPluginData(config, pluginsData, options) {
    if (!pluginsData)
        return;
    var preserveRemovedSettings = !!(options && options.preserveRemovedSettings);
    if (pluginsData.disabled !== undefined)
        config.disabledPlugins = _sanitizeDisabledPlugins(pluginsData.disabled);
    if (pluginsData.launcherTriggers !== undefined)
        config.pluginLauncherTriggers = _sanitizePluginMap(pluginsData.launcherTriggers);
    if (pluginsData.launcherNoTrigger !== undefined)
        config.pluginLauncherNoTrigger = _sanitizePluginMap(pluginsData.launcherNoTrigger);
    if (pluginsData.settings !== undefined)
        config.pluginSettings = preserveRemovedSettings
            ? (pluginsData.settings && typeof pluginsData.settings === "object" ? pluginsData.settings : {})
            : _sanitizePluginMap(pluginsData.settings);
    if (pluginsData.hotReload !== undefined)
        config.pluginHotReload = pluginsData.hotReload;
}

// ── Helpers ──────────────────────────────────────────────────────

function _applyMap(config, sectionData, entries) {
    if (!sectionData) return;
    for (var i = 0; i < entries.length; i++) {
        var e = entries[i];
        if (sectionData[e[0]] !== undefined)
            config[e[1]] = e[2] ? e[2](sectionData[e[0]]) : sectionData[e[0]];
    }
}

function _buildMap(config, entries) {
    var obj = {};
    for (var i = 0; i < entries.length; i++)
        obj[entries[i][0]] = config[entries[i][1]];
    return obj;
}

// ── Public API ───────────────────────────────────────────────────

function applyData(config, data) {
    _migrateData(data);
    _validateData(data);

    // Plugins first — migrated bar widgets may depend on plugin state.
    _applyPluginData(config, data.plugins, { preserveRemovedSettings: true });

    // Bars — needs full data object for normalization.
    if (data.bars) {
        if (data.bars.configs !== undefined)
            config.barConfigs = config.normalizeBarConfigs(data.bars.configs, data);
        if (data.bars.selectedBarId !== undefined)
            config.selectedBarId = data.bars.selectedBarId;
    } else {
        config.barConfigs = config.normalizeBarConfigs([], data);
    }

    // Launcher — custom normalization reads from data.launcher.
    if (data.launcher)
        config.normalizeLauncherConfig(data);

    // Table-driven sections.
    for (var section in _MAPS) {
        if (section === "launcher") continue;
        _applyMap(config, data[section], _MAPS[section]);
    }

    // controlCenter.width requires parseInt + clamp (not in table).
    if (data.controlCenter && data.controlCenter.width !== undefined) {
        var ccw = parseInt(data.controlCenter.width, 10);
        if (!isNaN(ccw))
            config.controlCenterWidth = Math.max(config.controlCenterWidthMin, Math.min(config.controlCenterWidthMax, ccw));
    }
}

function buildData(config) {
    var data = {};

    // Table-driven sections.
    for (var section in _MAPS)
        data[section] = _buildMap(config, _MAPS[section]);

    // Custom: bars
    data.bars = { selectedBarId: config.selectedBarId, configs: config.barConfigs };

    // Custom: controlCenter.width (not in table)
    data.controlCenter.width = config.controlCenterWidth;

    // Custom: plugins (with sanitization)
    data.plugins = {
        disabled: _sanitizeDisabledPlugins(config.disabledPlugins),
        launcherTriggers: _sanitizePluginMap(config.pluginLauncherTriggers),
        launcherNoTrigger: _sanitizePluginMap(config.pluginLauncherNoTrigger),
        settings: _sanitizePluginMap(config.pluginSettings),
        hotReload: config.pluginHotReload
    };

    data._version = CURRENT_VERSION;
    return data;
}
