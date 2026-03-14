.pragma library

function initializeDefaults(config) {
    config.barConfigs = config.normalizeBarConfigs([], {});
    config.ensureSelectedBar();
    config.syncLegacyBarSettingsFromPrimary();
}

function applyData(config, data) {
    if (data.bar) {
        if (data.bar.height !== undefined)
            config.barHeight = data.bar.height;
        if (data.bar.floating !== undefined)
            config.barFloating = data.bar.floating;
        if (data.bar.margin !== undefined)
            config.barMargin = data.bar.margin;
        if (data.bar.opacity !== undefined)
            config.barOpacity = data.bar.opacity;
    }

    if (data.bars) {
        if (data.bars.configs !== undefined)
            config.barConfigs = config.normalizeBarConfigs(data.bars.configs, data);
        if (data.bars.selectedBarId !== undefined)
            config.selectedBarId = data.bars.selectedBarId;
    } else {
        config.barConfigs = config.normalizeBarConfigs([], data);
    }

    if (data.glass) {
        if (data.glass.blur !== undefined)
            config.blurEnabled = data.glass.blur;
        if (data.glass.opacity !== undefined)
            config.glassOpacity = data.glass.opacity;
    }

    if (data.notifications) {
        if (data.notifications.width !== undefined)
            config.notifWidth = data.notifications.width;
        if (data.notifications.popupTimer !== undefined)
            config.popupTimer = data.notifications.popupTimer;
        if (data.notifications.position !== undefined)
            config.notifPosition = data.notifications.position;
        if (data.notifications.timeoutLow !== undefined)
            config.notifTimeoutLow = data.notifications.timeoutLow;
        if (data.notifications.timeoutNormal !== undefined)
            config.notifTimeoutNormal = data.notifications.timeoutNormal;
        if (data.notifications.timeoutCritical !== undefined)
            config.notifTimeoutCritical = data.notifications.timeoutCritical;
        if (data.notifications.compact !== undefined)
            config.notifCompact = data.notifications.compact;
        if (data.notifications.privacyMode !== undefined)
            config.notifPrivacyMode = data.notifications.privacyMode;
        if (data.notifications.historyEnabled !== undefined)
            config.notifHistoryEnabled = data.notifications.historyEnabled;
        if (data.notifications.historyMaxCount !== undefined)
            config.notifHistoryMaxCount = data.notifications.historyMaxCount;
        if (data.notifications.historyMaxAgeDays !== undefined)
            config.notifHistoryMaxAgeDays = data.notifications.historyMaxAgeDays;
        if (data.notifications.rules !== undefined)
            config.notifRules = data.notifications.rules;
    }

    if (data.time) {
        if (data.time.use24Hour !== undefined)
            config.timeUse24Hour = data.time.use24Hour;
        if (data.time.showSeconds !== undefined)
            config.timeShowSeconds = data.time.showSeconds;
        if (data.time.showBarDate !== undefined)
            config.timeShowBarDate = data.time.showBarDate;
        if (data.time.barDateStyle !== undefined)
            config.timeBarDateStyle = data.time.barDateStyle;
    }

    if (data.weather) {
        if (data.weather.units !== undefined)
            config.weatherUnits = data.weather.units;
        if (data.weather.autoLocation !== undefined)
            config.weatherAutoLocation = data.weather.autoLocation;
        if (data.weather.cityQuery !== undefined)
            config.weatherCityQuery = data.weather.cityQuery;
        if (data.weather.latitude !== undefined)
            config.weatherLatitude = String(data.weather.latitude);
        if (data.weather.longitude !== undefined)
            config.weatherLongitude = String(data.weather.longitude);
        if (data.weather.locationPriority !== undefined)
            config.weatherLocationPriority = data.weather.locationPriority;
    }

    if (data.launcher)
        config.normalizeLauncherConfig(data);

    if (data.controlCenter) {
        if (data.controlCenter.width !== undefined)
            config.controlCenterWidth = data.controlCenter.width;
        if (data.controlCenter.showQuickLinks !== undefined)
            config.controlCenterShowQuickLinks = data.controlCenter.showQuickLinks;
        if (data.controlCenter.showMediaWidget !== undefined)
            config.controlCenterShowMediaWidget = data.controlCenter.showMediaWidget;
        if (data.controlCenter.toggleOrder !== undefined)
            config.controlCenterToggleOrder = data.controlCenter.toggleOrder;
        if (data.controlCenter.hiddenToggles !== undefined)
            config.controlCenterHiddenToggles = data.controlCenter.hiddenToggles;
        if (data.controlCenter.pluginOrder !== undefined)
            config.controlCenterPluginOrder = data.controlCenter.pluginOrder;
        if (data.controlCenter.hiddenPlugins !== undefined)
            config.controlCenterHiddenPlugins = data.controlCenter.hiddenPlugins;
    }

    if (data.osd) {
        if (data.osd.duration !== undefined)
            config.osdDuration = data.osd.duration;
        if (data.osd.size !== undefined)
            config.osdSize = data.osd.size;
        if (data.osd.position !== undefined)
            config.osdPosition = data.osd.position;
        if (data.osd.style !== undefined)
            config.osdStyle = data.osd.style;
        if (data.osd.overdrive !== undefined)
            config.osdOverdrive = data.osd.overdrive;
    }

    if (data.dock) {
        if (data.dock.enabled !== undefined)
            config.dockEnabled = data.dock.enabled;
        if (data.dock.autoHide !== undefined)
            config.dockAutoHide = data.dock.autoHide;
        if (data.dock.pinnedApps !== undefined)
            config.dockPinnedApps = data.dock.pinnedApps;
        if (data.dock.position !== undefined)
            config.dockPosition = data.dock.position;
        if (data.dock.groupApps !== undefined)
            config.dockGroupApps = data.dock.groupApps;
        if (data.dock.iconSize !== undefined)
            config.dockIconSize = data.dock.iconSize;
    }

    if (data.desktopWidgets) {
        if (data.desktopWidgets.enabled !== undefined)
            config.desktopWidgetsEnabled = data.desktopWidgets.enabled;
        if (data.desktopWidgets.gridSnap !== undefined)
            config.desktopWidgetsGridSnap = data.desktopWidgets.gridSnap;
        if (data.desktopWidgets.monitorWidgets !== undefined)
            config.desktopWidgetsMonitorWidgets = data.desktopWidgets.monitorWidgets;
    }

    if (data.screenBorders) {
        if (data.screenBorders.show !== undefined)
            config.showScreenBorders = data.screenBorders.show;
    }

    if (data.powerMenu) {
        if (data.powerMenu.countdown !== undefined)
            config.powermenuCountdown = data.powerMenu.countdown;
    }

    if (data.lockScreen) {
        if (data.lockScreen.compact !== undefined)
            config.lockScreenCompact = data.lockScreen.compact;
        if (data.lockScreen.mediaControls !== undefined)
            config.lockScreenMediaControls = data.lockScreen.mediaControls;
        if (data.lockScreen.weather !== undefined)
            config.lockScreenWeather = data.lockScreen.weather;
        if (data.lockScreen.sessionButtons !== undefined)
            config.lockScreenSessionButtons = data.lockScreen.sessionButtons;
        if (data.lockScreen.countdown !== undefined)
            config.lockScreenCountdown = data.lockScreen.countdown;
    }

    if (data.privacy) {
        if (data.privacy.indicatorsEnabled !== undefined)
            config.privacyIndicatorsEnabled = data.privacy.indicatorsEnabled;
        if (data.privacy.cameraMonitoring !== undefined)
            config.privacyCameraMonitoring = data.privacy.cameraMonitoring;
    }

    if (data.audio) {
        if (data.audio.volumeProtectionEnabled !== undefined)
            config.volumeProtectionEnabled = data.audio.volumeProtectionEnabled;
        if (data.audio.volumeProtectionMaxJump !== undefined)
            config.volumeProtectionMaxJump = data.audio.volumeProtectionMaxJump;
        if (data.audio.pinnedOutputs !== undefined)
            config.audioPinnedOutputs = data.audio.pinnedOutputs;
        if (data.audio.pinnedInputs !== undefined)
            config.audioPinnedInputs = data.audio.pinnedInputs;
        if (data.audio.hiddenOutputs !== undefined)
            config.audioHiddenOutputs = data.audio.hiddenOutputs;
        if (data.audio.hiddenInputs !== undefined)
            config.audioHiddenInputs = data.audio.hiddenInputs;
    }

    if (data.nightLight) {
        if (data.nightLight.enabled !== undefined)
            config.nightLightEnabled = data.nightLight.enabled;
        if (data.nightLight.temperature !== undefined)
            config.nightLightTemperature = data.nightLight.temperature;
        if (data.nightLight.autoSchedule !== undefined)
            config.nightLightAutoSchedule = data.nightLight.autoSchedule;
        if (data.nightLight.scheduleMode !== undefined)
            config.nightLightScheduleMode = data.nightLight.scheduleMode;
        if (data.nightLight.startHour !== undefined)
            config.nightLightStartHour = data.nightLight.startHour;
        if (data.nightLight.startMinute !== undefined)
            config.nightLightStartMinute = data.nightLight.startMinute;
        if (data.nightLight.endHour !== undefined)
            config.nightLightEndHour = data.nightLight.endHour;
        if (data.nightLight.endMinute !== undefined)
            config.nightLightEndMinute = data.nightLight.endMinute;
        if (data.nightLight.latitude !== undefined)
            config.nightLightLatitude = String(data.nightLight.latitude);
        if (data.nightLight.longitude !== undefined)
            config.nightLightLongitude = String(data.nightLight.longitude);
    }

    if (data.power) {
        if (data.power.idleInhibit !== undefined)
            config.idleInhibitEnabled = data.power.idleInhibit;
        if (data.power.acMonitorTimeout !== undefined)
            config.powerAcMonitorTimeout = data.power.acMonitorTimeout;
        if (data.power.acLockTimeout !== undefined)
            config.powerAcLockTimeout = data.power.acLockTimeout;
        if (data.power.acSuspendTimeout !== undefined)
            config.powerAcSuspendTimeout = data.power.acSuspendTimeout;
        if (data.power.acSuspendAction !== undefined)
            config.powerAcSuspendAction = data.power.acSuspendAction;
        if (data.power.batMonitorTimeout !== undefined)
            config.powerBatMonitorTimeout = data.power.batMonitorTimeout;
        if (data.power.batLockTimeout !== undefined)
            config.powerBatLockTimeout = data.power.batLockTimeout;
        if (data.power.batSuspendTimeout !== undefined)
            config.powerBatSuspendTimeout = data.power.batSuspendTimeout;
        if (data.power.batSuspendAction !== undefined)
            config.powerBatSuspendAction = data.power.batSuspendAction;
        if (data.power.batteryAlertsEnabled !== undefined)
            config.batteryAlertsEnabled = data.power.batteryAlertsEnabled;
        if (data.power.batteryWarningThreshold !== undefined)
            config.batteryWarningThreshold = data.power.batteryWarningThreshold;
        if (data.power.batteryCriticalThreshold !== undefined)
            config.batteryCriticalThreshold = data.power.batteryCriticalThreshold;
    }

    if (data.hooks) {
        if (data.hooks.enabled !== undefined)
            config.hooksEnabled = data.hooks.enabled;
        if (data.hooks.paths !== undefined)
            config.hookPaths = data.hooks.paths;
    }

    if (data.colorPicker) {
        if (data.colorPicker.recentColors !== undefined)
            config.recentPickerColors = data.colorPicker.recentColors;
    }

    if (data.ai) {
        if (data.ai.provider !== undefined)
            config.aiProvider = data.ai.provider;
        if (data.ai.model !== undefined)
            config.aiModel = data.ai.model;
        if (data.ai.customEndpoint !== undefined)
            config.aiCustomEndpoint = data.ai.customEndpoint;
        if (data.ai.systemContext !== undefined)
            config.aiSystemContext = data.ai.systemContext;
        if (data.ai.maxTokens !== undefined)
            config.aiMaxTokens = data.ai.maxTokens;
        if (data.ai.temperature !== undefined)
            config.aiTemperature = data.ai.temperature;
        if (data.ai.systemPrompt !== undefined)
            config.aiSystemPrompt = data.ai.systemPrompt;
        if (data.ai.anthropicKey !== undefined)
            config.aiAnthropicKey = data.ai.anthropicKey;
        if (data.ai.openaiKey !== undefined)
            config.aiOpenaiKey = data.ai.openaiKey;
        if (data.ai.geminiKey !== undefined)
            config.aiGeminiKey = data.ai.geminiKey;
        if (data.ai.maxConversations !== undefined)
            config.aiMaxConversations = data.ai.maxConversations;
        if (data.ai.maxMessages !== undefined)
            config.aiMaxMessages = data.ai.maxMessages;
    }

    if (data.plugins) {
        if (data.plugins.disabled !== undefined)
            config.disabledPlugins = data.plugins.disabled;
        if (data.plugins.launcherTriggers !== undefined)
            config.pluginLauncherTriggers = data.plugins.launcherTriggers;
        if (data.plugins.launcherNoTrigger !== undefined)
            config.pluginLauncherNoTrigger = data.plugins.launcherNoTrigger;
        if (data.plugins.settings !== undefined)
            config.pluginSettings = data.plugins.settings;
        if (data.plugins.hotReload !== undefined)
            config.pluginHotReload = data.plugins.hotReload;
    }

    if (data.theme) {
        if (data.theme.name !== undefined)
            config.themeName = data.theme.name;
        if (data.theme.autoScheduleEnabled !== undefined)
            config.themeAutoScheduleEnabled = data.theme.autoScheduleEnabled;
        if (data.theme.autoScheduleMode !== undefined)
            config.themeAutoScheduleMode = data.theme.autoScheduleMode;
        if (data.theme.darkName !== undefined)
            config.themeDarkName = data.theme.darkName;
        if (data.theme.lightName !== undefined)
            config.themeLightName = data.theme.lightName;
        if (data.theme.darkHour !== undefined)
            config.themeDarkHour = data.theme.darkHour;
        if (data.theme.darkMinute !== undefined)
            config.themeDarkMinute = data.theme.darkMinute;
        if (data.theme.lightHour !== undefined)
            config.themeLightHour = data.theme.lightHour;
        if (data.theme.lightMinute !== undefined)
            config.themeLightMinute = data.theme.lightMinute;
        if (data.theme.autoLatitude !== undefined)
            config.themeAutoLatitude = String(data.theme.autoLatitude);
        if (data.theme.autoLongitude !== undefined)
            config.themeAutoLongitude = String(data.theme.autoLongitude);
    }

    if (data.workspaces) {
        if (data.workspaces.showEmpty !== undefined)
            config.workspaceShowEmpty = data.workspaces.showEmpty;
        if (data.workspaces.showNames !== undefined)
            config.workspaceShowNames = data.workspaces.showNames;
        if (data.workspaces.showAppIcons !== undefined)
            config.workspaceShowAppIcons = data.workspaces.showAppIcons;
        if (data.workspaces.maxIcons !== undefined)
            config.workspaceMaxIcons = data.workspaces.maxIcons;
        if (data.workspaces.pillSize !== undefined)
            config.workspacePillSize = data.workspaces.pillSize;
        if (data.workspaces.scrollEnabled !== undefined)
            config.workspaceScrollEnabled = data.workspaces.scrollEnabled;
        if (data.workspaces.reverseScroll !== undefined)
            config.workspaceReverseScroll = data.workspaces.reverseScroll;
        if (data.workspaces.activeColor !== undefined)
            config.workspaceActiveColor = data.workspaces.activeColor;
        if (data.workspaces.urgentColor !== undefined)
            config.workspaceUrgentColor = data.workspaces.urgentColor;
    }

    if (data.displayProfiles) {
        if (data.displayProfiles.profiles !== undefined)
            config.displayProfiles = data.displayProfiles.profiles;
        if (data.displayProfiles.autoProfile !== undefined)
            config.displayAutoProfile = data.displayProfiles.autoProfile;
    }

    if (data.appearance) {
        if (data.appearance.fontFamily !== undefined)
            config.fontFamily = String(data.appearance.fontFamily || "");
        if (data.appearance.monoFontFamily !== undefined)
            config.monoFontFamily = String(data.appearance.monoFontFamily || "");
        if (data.appearance.fontScale !== undefined)
            config.fontScale = Number(data.appearance.fontScale) || 1.0;
        if (data.appearance.radiusScale !== undefined)
            config.radiusScale = Number(data.appearance.radiusScale) || 1.0;
        if (data.appearance.spacingScale !== undefined)
            config.spacingScale = Number(data.appearance.spacingScale) || 1.0;
    }

    if (data.wallpaper) {
        if (data.wallpaper.runPywal !== undefined)
            config.wallpaperRunPywal = data.wallpaper.runPywal;
        if (data.wallpaper.paths !== undefined)
            config.wallpaperPaths = data.wallpaper.paths;
        if (data.wallpaper.cycleInterval !== undefined)
            config.wallpaperCycleInterval = data.wallpaper.cycleInterval;
        if (data.wallpaper.defaultFolder !== undefined)
            config.wallpaperDefaultFolder = data.wallpaper.defaultFolder;
        if (data.wallpaper.solidColor !== undefined)
            config.wallpaperSolidColor = data.wallpaper.solidColor;
        if (data.wallpaper.useSolidOnStartup !== undefined)
            config.wallpaperUseSolidOnStartup = data.wallpaper.useSolidOnStartup;
        if (data.wallpaper.solidColorsByMonitor !== undefined)
            config.wallpaperSolidColorsByMonitor = data.wallpaper.solidColorsByMonitor;
        if (data.wallpaper.recentSolidColors !== undefined)
            config.wallpaperRecentSolidColors = data.wallpaper.recentSolidColors;
    }
}

function buildData(config) {
    return {
        "bar": {
            "height": config.barHeight,
            "floating": config.barFloating,
            "margin": config.barMargin,
            "opacity": config.barOpacity
        },
        "bars": {
            "selectedBarId": config.selectedBarId,
            "configs": config.barConfigs
        },
        "glass": {
            "blur": config.blurEnabled,
            "opacity": config.glassOpacity
        },
        "notifications": {
            "width": config.notifWidth,
            "popupTimer": config.popupTimer,
            "position": config.notifPosition,
            "timeoutLow": config.notifTimeoutLow,
            "timeoutNormal": config.notifTimeoutNormal,
            "timeoutCritical": config.notifTimeoutCritical,
            "compact": config.notifCompact,
            "privacyMode": config.notifPrivacyMode,
            "historyEnabled": config.notifHistoryEnabled,
            "historyMaxCount": config.notifHistoryMaxCount,
            "historyMaxAgeDays": config.notifHistoryMaxAgeDays,
            "rules": config.notifRules
        },
        "time": {
            "use24Hour": config.timeUse24Hour,
            "showSeconds": config.timeShowSeconds,
            "showBarDate": config.timeShowBarDate,
            "barDateStyle": config.timeBarDateStyle
        },
        "weather": {
            "units": config.weatherUnits,
            "autoLocation": config.weatherAutoLocation,
            "cityQuery": config.weatherCityQuery,
            "latitude": config.weatherLatitude,
            "longitude": config.weatherLongitude,
            "locationPriority": config.weatherLocationPriority
        },
        "launcher": {
            "defaultMode": config.launcherDefaultMode,
            "showModeHints": config.launcherShowModeHints,
            "showHomeSections": config.launcherShowHomeSections,
            "drunCategoryFiltersEnabled": config.launcherDrunCategoryFiltersEnabled,
            "enablePreload": config.launcherEnablePreload,
            "keepSearchOnModeSwitch": config.launcherKeepSearchOnModeSwitch,
            "enableDebugTimings": config.launcherEnableDebugTimings,
            "showRuntimeMetrics": config.launcherShowRuntimeMetrics,
            "preloadFailureThreshold": config.launcherPreloadFailureThreshold,
            "preloadFailureBackoffSec": config.launcherPreloadFailureBackoffSec,
            "maxResults": config.launcherMaxResults,
            "fileMinQueryLength": config.launcherFileMinQueryLength,
            "fileMaxResults": config.launcherFileMaxResults,
            "recentsLimit": config.launcherRecentsLimit,
            "recentAppsLimit": config.launcherRecentAppsLimit,
            "suggestionsLimit": config.launcherSuggestionsLimit,
            "cacheTtlSec": config.launcherCacheTtlSec,
            "searchDebounceMs": config.launcherSearchDebounceMs,
            "fileSearchDebounceMs": config.launcherFileSearchDebounceMs,
            "tabBehavior": config.launcherTabBehavior,
            "webEnterUsesPrimary": config.launcherWebEnterUsesPrimary,
            "webNumberHotkeysEnabled": config.launcherWebNumberHotkeysEnabled,
            "webAliases": config.launcherWebAliases,
            "rememberWebProvider": config.launcherRememberWebProvider,
            "webLastProviderKey": config.launcherWebLastProviderKey,
            "webProviderOrder": config.launcherWebProviderOrder,
            "modeOrder": config.launcherModeOrder,
            "enabledModes": config.launcherEnabledModes,
            "scoreNameWeight": config.launcherScoreNameWeight,
            "scoreTitleWeight": config.launcherScoreTitleWeight,
            "scoreExecWeight": config.launcherScoreExecWeight,
            "scoreBodyWeight": config.launcherScoreBodyWeight,
            "scoreCategoryWeight": config.launcherScoreCategoryWeight
        },
        "controlCenter": {
            "width": config.controlCenterWidth,
            "showQuickLinks": config.controlCenterShowQuickLinks,
            "showMediaWidget": config.controlCenterShowMediaWidget,
            "toggleOrder": config.controlCenterToggleOrder,
            "hiddenToggles": config.controlCenterHiddenToggles,
            "pluginOrder": config.controlCenterPluginOrder,
            "hiddenPlugins": config.controlCenterHiddenPlugins
        },
        "osd": {
            "duration": config.osdDuration,
            "size": config.osdSize,
            "position": config.osdPosition,
            "style": config.osdStyle,
            "overdrive": config.osdOverdrive
        },
        "dock": {
            "enabled": config.dockEnabled,
            "autoHide": config.dockAutoHide,
            "pinnedApps": config.dockPinnedApps,
            "position": config.dockPosition,
            "groupApps": config.dockGroupApps,
            "iconSize": config.dockIconSize
        },
        "desktopWidgets": {
            "enabled": config.desktopWidgetsEnabled,
            "gridSnap": config.desktopWidgetsGridSnap,
            "monitorWidgets": config.desktopWidgetsMonitorWidgets
        },
        "screenBorders": {
            "show": config.showScreenBorders
        },
        "powerMenu": {
            "countdown": config.powermenuCountdown
        },
        "lockScreen": {
            "compact": config.lockScreenCompact,
            "mediaControls": config.lockScreenMediaControls,
            "weather": config.lockScreenWeather,
            "sessionButtons": config.lockScreenSessionButtons,
            "countdown": config.lockScreenCountdown
        },
        "privacy": {
            "indicatorsEnabled": config.privacyIndicatorsEnabled,
            "cameraMonitoring": config.privacyCameraMonitoring
        },
        "audio": {
            "volumeProtectionEnabled": config.volumeProtectionEnabled,
            "volumeProtectionMaxJump": config.volumeProtectionMaxJump,
            "pinnedOutputs": config.audioPinnedOutputs,
            "pinnedInputs": config.audioPinnedInputs,
            "hiddenOutputs": config.audioHiddenOutputs,
            "hiddenInputs": config.audioHiddenInputs
        },
        "nightLight": {
            "enabled": config.nightLightEnabled,
            "temperature": config.nightLightTemperature,
            "autoSchedule": config.nightLightAutoSchedule,
            "scheduleMode": config.nightLightScheduleMode,
            "startHour": config.nightLightStartHour,
            "startMinute": config.nightLightStartMinute,
            "endHour": config.nightLightEndHour,
            "endMinute": config.nightLightEndMinute,
            "latitude": config.nightLightLatitude,
            "longitude": config.nightLightLongitude
        },
        "power": {
            "idleInhibit": config.idleInhibitEnabled,
            "acMonitorTimeout": config.powerAcMonitorTimeout,
            "acLockTimeout": config.powerAcLockTimeout,
            "acSuspendTimeout": config.powerAcSuspendTimeout,
            "acSuspendAction": config.powerAcSuspendAction,
            "batMonitorTimeout": config.powerBatMonitorTimeout,
            "batLockTimeout": config.powerBatLockTimeout,
            "batSuspendTimeout": config.powerBatSuspendTimeout,
            "batSuspendAction": config.powerBatSuspendAction,
            "batteryAlertsEnabled": config.batteryAlertsEnabled,
            "batteryWarningThreshold": config.batteryWarningThreshold,
            "batteryCriticalThreshold": config.batteryCriticalThreshold
        },
        "hooks": {
            "enabled": config.hooksEnabled,
            "paths": config.hookPaths
        },
        "colorPicker": {
            "recentColors": config.recentPickerColors
        },
        "ai": {
            "provider": config.aiProvider,
            "model": config.aiModel,
            "customEndpoint": config.aiCustomEndpoint,
            "systemContext": config.aiSystemContext,
            "maxTokens": config.aiMaxTokens,
            "temperature": config.aiTemperature,
            "systemPrompt": config.aiSystemPrompt,
            "anthropicKey": config.aiAnthropicKey,
            "openaiKey": config.aiOpenaiKey,
            "geminiKey": config.aiGeminiKey,
            "maxConversations": config.aiMaxConversations,
            "maxMessages": config.aiMaxMessages
        },
        "plugins": {
            "disabled": config.disabledPlugins,
            "launcherTriggers": config.pluginLauncherTriggers,
            "launcherNoTrigger": config.pluginLauncherNoTrigger,
            "settings": config.pluginSettings,
            "hotReload": config.pluginHotReload
        },
        "theme": {
            "name": config.themeName,
            "autoScheduleEnabled": config.themeAutoScheduleEnabled,
            "autoScheduleMode": config.themeAutoScheduleMode,
            "darkName": config.themeDarkName,
            "lightName": config.themeLightName,
            "darkHour": config.themeDarkHour,
            "darkMinute": config.themeDarkMinute,
            "lightHour": config.themeLightHour,
            "lightMinute": config.themeLightMinute,
            "autoLatitude": config.themeAutoLatitude,
            "autoLongitude": config.themeAutoLongitude
        },
        "workspaces": {
            "showEmpty": config.workspaceShowEmpty,
            "showNames": config.workspaceShowNames,
            "showAppIcons": config.workspaceShowAppIcons,
            "maxIcons": config.workspaceMaxIcons,
            "pillSize": config.workspacePillSize,
            "scrollEnabled": config.workspaceScrollEnabled,
            "reverseScroll": config.workspaceReverseScroll,
            "activeColor": config.workspaceActiveColor,
            "urgentColor": config.workspaceUrgentColor
        },
        "displayProfiles": {
            "profiles": config.displayProfiles,
            "autoProfile": config.displayAutoProfile
        },
        "appearance": {
            "fontFamily": config.fontFamily,
            "monoFontFamily": config.monoFontFamily,
            "fontScale": config.fontScale,
            "radiusScale": config.radiusScale,
            "spacingScale": config.spacingScale
        },
        "wallpaper": {
            "runPywal": config.wallpaperRunPywal,
            "paths": config.wallpaperPaths,
            "cycleInterval": config.wallpaperCycleInterval,
            "defaultFolder": config.wallpaperDefaultFolder,
            "solidColor": config.wallpaperSolidColor,
            "useSolidOnStartup": config.wallpaperUseSolidOnStartup,
            "solidColorsByMonitor": config.wallpaperSolidColorsByMonitor,
            "recentSolidColors": config.wallpaperRecentSolidColors
        }
    };
}
