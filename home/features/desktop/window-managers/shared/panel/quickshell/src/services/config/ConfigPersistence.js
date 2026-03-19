.pragma library

var REMOVED_PLUGIN_IDS = ["quickshell.ssh.monitor"];

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

// ── Transforms for fields that need coercion on apply ────────────
function _str(v) { return String(v); }
function _strDef(v) { return String(v || ""); }
function _num1(v) { return Number(v) || 1.0; }

// ── Data-driven property mapping tables ──────────────────────────
// Each entry: [jsonKey, configProperty] or [jsonKey, configProperty, applyTransform]
// Sections with custom logic (bars, launcher-apply, plugins) are handled separately.

var _MAPS = {
    bar: [
        ["height", "barHeight"],
        ["floating", "barFloating"],
        ["margin", "barMargin"],
        ["opacity", "barOpacity"],
        ["leftEntries", "barLeftEntries"],
        ["centerEntries", "barCenterEntries"],
        ["rightEntries", "barRightEntries"],
        ["useModularEntries", "barUseModularEntries"]
    ],
    glass: [
        ["blur", "blurEnabled"],
        ["opacity", "glassOpacity"],
        ["opacityBase", "glassOpacityBase"],
        ["opacitySurface", "glassOpacitySurface"],
        ["opacityOverlay", "glassOpacityOverlay"],
        ["settingsBackdropOpacity", "settingsBackdropOpacity"],
        ["settingsSurfaceOpacity", "settingsSurfaceOpacity"],
        ["autoTransparency", "autoTransparency"]
    ],
    notifications: [
        ["width", "notifWidth"],
        ["popupTimer", "popupTimer"],
        ["position", "notifPosition"],
        ["timeoutLow", "notifTimeoutLow"],
        ["timeoutNormal", "notifTimeoutNormal"],
        ["timeoutCritical", "notifTimeoutCritical"],
        ["compact", "notifCompact"],
        ["privacyMode", "notifPrivacyMode"],
        ["historyEnabled", "notifHistoryEnabled"],
        ["historyMaxCount", "notifHistoryMaxCount"],
        ["historyMaxAgeDays", "notifHistoryMaxAgeDays"],
        ["rules", "notifRules"]
    ],
    time: [
        ["use24Hour", "timeUse24Hour"],
        ["showSeconds", "timeShowSeconds"],
        ["showBarDate", "timeShowBarDate"],
        ["barDateStyle", "timeBarDateStyle"]
    ],
    weather: [
        ["units", "weatherUnits"],
        ["autoLocation", "weatherAutoLocation"],
        ["cityQuery", "weatherCityQuery"],
        ["latitude", "weatherLatitude", _str],
        ["longitude", "weatherLongitude", _str],
        ["locationPriority", "weatherLocationPriority"]
    ],
    modelUsage: [
        ["claudeEnabled", "modelUsageClaudeEnabled"],
        ["codexEnabled", "modelUsageCodexEnabled"],
        ["activeProvider", "modelUsageActiveProvider"],
        ["barMetric", "modelUsageBarMetric"],
        ["refreshSec", "modelUsageRefreshSec"]
    ],
    controlCenter: [
        ["showQuickLinks", "controlCenterShowQuickLinks"],
        ["showMediaWidget", "controlCenterShowMediaWidget"],
        ["toggleOrder", "controlCenterToggleOrder"],
        ["hiddenToggles", "controlCenterHiddenToggles"],
        ["pluginOrder", "controlCenterPluginOrder"],
        ["hiddenPlugins", "controlCenterHiddenPlugins"]
    ],
    osd: [
        ["duration", "osdDuration"],
        ["size", "osdSize"],
        ["position", "osdPosition"],
        ["style", "osdStyle"],
        ["overdrive", "osdOverdrive"]
    ],
    dock: [
        ["enabled", "dockEnabled"],
        ["autoHide", "dockAutoHide"],
        ["pinnedApps", "dockPinnedApps"],
        ["position", "dockPosition"],
        ["groupApps", "dockGroupApps"],
        ["iconSize", "dockIconSize"]
    ],
    desktopWidgets: [
        ["enabled", "desktopWidgetsEnabled"],
        ["gridSnap", "desktopWidgetsGridSnap"],
        ["monitorWidgets", "desktopWidgetsMonitorWidgets"]
    ],
    background: [
        ["visualizerEnabled", "backgroundVisualizerEnabled"],
        ["useShaderVisualizer", "backgroundUseShaderVisualizer"],
        ["clockEnabled", "backgroundClockEnabled"],
        ["autoHide", "backgroundAutoHide"],
        ["clockPosition", "backgroundClockPosition"]
    ],
    hotCorners: [
        ["enabled", "hotCornersEnabled"]
    ],
    screenBorders: [
        ["show", "showScreenBorders"]
    ],
    powerMenu: [
        ["countdown", "powermenuCountdown"]
    ],
    lockScreen: [
        ["compact", "lockScreenCompact"],
        ["mediaControls", "lockScreenMediaControls"],
        ["weather", "lockScreenWeather"],
        ["sessionButtons", "lockScreenSessionButtons"],
        ["countdown", "lockScreenCountdown"],
        ["fingerprint", "lockScreenFingerprint"]
    ],
    privacy: [
        ["indicatorsEnabled", "privacyIndicatorsEnabled"],
        ["cameraMonitoring", "privacyCameraMonitoring"]
    ],
    audio: [
        ["volumeProtectionEnabled", "volumeProtectionEnabled"],
        ["volumeProtectionMaxJump", "volumeProtectionMaxJump"],
        ["pinnedOutputs", "audioPinnedOutputs"],
        ["pinnedInputs", "audioPinnedInputs"],
        ["hiddenOutputs", "audioHiddenOutputs"],
        ["hiddenInputs", "audioHiddenInputs"]
    ],
    screenshot: [
        ["editor", "screenshotEditor"],
        ["editAfterCapture", "screenshotEditAfterCapture"],
        ["delay", "screenshotDelay"]
    ],
    recording: [
        ["captureSource", "recordingCaptureSource"],
        ["fps", "recordingFps"],
        ["quality", "recordingQuality"],
        ["recordCursor", "recordingRecordCursor"],
        ["outputDir", "recordingOutputDir"],
        ["includeDesktopAudio", "recordingIncludeDesktopAudio"],
        ["includeMicrophoneAudio", "recordingIncludeMicrophoneAudio"]
    ],
    nightLight: [
        ["enabled", "nightLightEnabled"],
        ["temperature", "nightLightTemperature"],
        ["autoSchedule", "nightLightAutoSchedule"],
        ["scheduleMode", "nightLightScheduleMode"],
        ["startHour", "nightLightStartHour"],
        ["startMinute", "nightLightStartMinute"],
        ["endHour", "nightLightEndHour"],
        ["endMinute", "nightLightEndMinute"],
        ["latitude", "nightLightLatitude", _str],
        ["longitude", "nightLightLongitude", _str]
    ],
    power: [
        ["idleInhibit", "idleInhibitEnabled"],
        ["inhibitIdleWhenPlaying", "inhibitIdleWhenPlaying"],
        ["acMonitorTimeout", "powerAcMonitorTimeout"],
        ["acLockTimeout", "powerAcLockTimeout"],
        ["acSuspendTimeout", "powerAcSuspendTimeout"],
        ["acSuspendAction", "powerAcSuspendAction"],
        ["batMonitorTimeout", "powerBatMonitorTimeout"],
        ["batLockTimeout", "powerBatLockTimeout"],
        ["batSuspendTimeout", "powerBatSuspendTimeout"],
        ["batSuspendAction", "powerBatSuspendAction"],
        ["batteryAlertsEnabled", "batteryAlertsEnabled"],
        ["batteryWarningThreshold", "batteryWarningThreshold"],
        ["batteryCriticalThreshold", "batteryCriticalThreshold"]
    ],
    hooks: [
        ["enabled", "hooksEnabled"],
        ["paths", "hookPaths"]
    ],
    colorPicker: [
        ["recentColors", "recentPickerColors"]
    ],
    ai: [
        ["provider", "aiProvider"],
        ["model", "aiModel"],
        ["customEndpoint", "aiCustomEndpoint"],
        ["systemContext", "aiSystemContext"],
        ["maxTokens", "aiMaxTokens"],
        ["temperature", "aiTemperature"],
        ["systemPrompt", "aiSystemPrompt"],
        ["anthropicKey", "aiAnthropicKey"],
        ["openaiKey", "aiOpenaiKey"],
        ["geminiKey", "aiGeminiKey"],
        ["maxConversations", "aiMaxConversations"],
        ["maxMessages", "aiMaxMessages"],
        ["providerProfiles", "aiProviderProfiles"],
        ["timeout", "aiTimeout"]
    ],
    state: [
        ["activeSurfaceId", "activeSurfaceId"]
    ],
    theme: [
        ["name", "themeName"],
        ["autoScheduleEnabled", "themeAutoScheduleEnabled"],
        ["autoScheduleMode", "themeAutoScheduleMode"],
        ["useDynamicTheming", "useDynamicTheming"],
        ["darkName", "themeDarkName"],
        ["lightName", "themeLightName"],
        ["darkHour", "themeDarkHour"],
        ["darkMinute", "themeDarkMinute"],
        ["lightHour", "themeLightHour"],
        ["lightMinute", "themeLightMinute"],
        ["autoLatitude", "themeAutoLatitude", _str],
        ["autoLongitude", "themeAutoLongitude", _str]
    ],
    workspaces: [
        ["showEmpty", "workspaceShowEmpty"],
        ["showNames", "workspaceShowNames"],
        ["showAppIcons", "workspaceShowAppIcons"],
        ["maxIcons", "workspaceMaxIcons"],
        ["pillSize", "workspacePillSize"],
        ["scrollEnabled", "workspaceScrollEnabled"],
        ["reverseScroll", "workspaceReverseScroll"],
        ["activeColor", "workspaceActiveColor"],
        ["urgentColor", "workspaceUrgentColor"]
    ],
    osk: [
        ["layout", "oskLayout"],
        ["pinnedOnStartup", "oskPinnedOnStartup"]
    ],
    notepad: [
        ["projectSync", "notepadProjectSync"]
    ],
    displayProfiles: [
        ["profiles", "displayProfiles"],
        ["autoProfile", "displayAutoProfile"]
    ],
    appearance: [
        ["fontFamily", "fontFamily", _strDef],
        ["monoFontFamily", "monoFontFamily", _strDef],
        ["fontScale", "fontScale", _num1],
        ["radiusScale", "radiusScale", _num1],
        ["spacingScale", "spacingScale", _num1],
        ["uiDensityScale", "uiDensityScale", _num1],
        ["animationSpeedScale", "animationSpeedScale", _num1],
        ["personalityGifEnabled", "personalityGifEnabled"],
        ["personalityGifPath", "personalityGifPath", _strDef],
        ["personalityGifReactionMode", "personalityGifReactionMode", _strDef]
    ],
    wallpaper: [
        ["runPywal", "wallpaperRunPywal"],
        ["paths", "wallpaperPaths"],
        ["cycleInterval", "wallpaperCycleInterval"],
        ["defaultFolder", "wallpaperDefaultFolder"],
        ["solidColor", "wallpaperSolidColor"],
        ["useSolidOnStartup", "wallpaperUseSolidOnStartup"],
        ["solidColorsByMonitor", "wallpaperSolidColorsByMonitor"],
        ["recentSolidColors", "wallpaperRecentSolidColors"]
    ],
    launcher: [
        ["defaultMode", "launcherDefaultMode"],
        ["showModeHints", "launcherShowModeHints"],
        ["showHomeSections", "launcherShowHomeSections"],
        ["drunCategoryFiltersEnabled", "launcherDrunCategoryFiltersEnabled"],
        ["enablePreload", "launcherEnablePreload"],
        ["keepSearchOnModeSwitch", "launcherKeepSearchOnModeSwitch"],
        ["enableDebugTimings", "launcherEnableDebugTimings"],
        ["showRuntimeMetrics", "launcherShowRuntimeMetrics"],
        ["characterTrigger", "launcherCharacterTrigger"],
        ["characterPasteOnSelect", "launcherCharacterPasteOnSelect"],
        ["preloadFailureThreshold", "launcherPreloadFailureThreshold"],
        ["preloadFailureBackoffSec", "launcherPreloadFailureBackoffSec"],
        ["maxResults", "launcherMaxResults"],
        ["fileMinQueryLength", "launcherFileMinQueryLength"],
        ["fileMaxResults", "launcherFileMaxResults"],
        ["fileSearchRoot", "launcherFileSearchRoot"],
        ["fileShowHidden", "launcherFileShowHidden"],
        ["fileOpener", "launcherFileOpener"],
        ["recentsLimit", "launcherRecentsLimit"],
        ["recentAppsLimit", "launcherRecentAppsLimit"],
        ["suggestionsLimit", "launcherSuggestionsLimit"],
        ["cacheTtlSec", "launcherCacheTtlSec"],
        ["searchDebounceMs", "launcherSearchDebounceMs"],
        ["fileSearchDebounceMs", "launcherFileSearchDebounceMs"],
        ["tabBehavior", "launcherTabBehavior"],
        ["webEnterUsesPrimary", "launcherWebEnterUsesPrimary"],
        ["webNumberHotkeysEnabled", "launcherWebNumberHotkeysEnabled"],
        ["webAliases", "launcherWebAliases"],
        ["rememberWebProvider", "launcherRememberWebProvider"],
        ["webLastProviderKey", "launcherWebLastProviderKey"],
        ["webProviderOrder", "launcherWebProviderOrder"],
        ["modeOrder", "launcherModeOrder"],
        ["enabledModes", "launcherEnabledModes"],
        ["scoreNameWeight", "launcherScoreNameWeight"],
        ["scoreTitleWeight", "launcherScoreTitleWeight"],
        ["scoreExecWeight", "launcherScoreExecWeight"],
        ["scoreBodyWeight", "launcherScoreBodyWeight"],
        ["scoreCategoryWeight", "launcherScoreCategoryWeight"],
        ["webCustomEngines", "launcherWebCustomEngines"],
        ["webBangsEnabled", "launcherWebBangsEnabled"],
        ["webBangsLastSync", "launcherWebBangsLastSync"]
    ]
};

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

    return data;
}
