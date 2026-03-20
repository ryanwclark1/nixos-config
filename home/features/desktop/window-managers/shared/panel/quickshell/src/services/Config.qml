pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "config/ConfigLauncher.js" as ConfigLauncher
import "config/ConfigPersistence.js" as ConfigPersistence

QtObject {
    id: root

    // --- BAR (legacy compatibility + shell defaults) ---
    property int barHeight: 38
    property bool barFloating: true
    property int barMargin: 4
    property real barOpacity: 1.0
    property var barConfigs: []
    property string selectedBarId: ""
    property var barLeftEntries: ["logo", "workspaces", "specialWorkspaces"]
    property var barCenterEntries: ["windowTitle"]
    property var barRightEntries: ["updates", "cava", "mediaBar", "network", "bluetooth", "audio", "battery", "dateTime", "notifications", "tray", "controlCenter"]
    property bool barUseModularEntries: false
    property var _modularLayoutHistory: []

    // --- GLASS ---
    property bool blurEnabled: true
    property real glassOpacityBase: 0.85
    property real glassOpacitySurface: 0.94
    property real glassOpacityOverlay: 1.0
    property real settingsBackdropOpacity: 0.92
    property bool autoTransparency: false

    // --- NOTIFICATIONS ---
    property int notifWidth: 350
    property int popupTimer: 5000
    property string notifPosition: "top_right"
    property int notifTimeoutLow: 3000
    property int notifTimeoutNormal: 5000
    property int notifTimeoutCritical: 0
    property bool notifCompact: false
    property bool notifPrivacyMode: false
    property bool notifHistoryEnabled: true
    property int notifHistoryMaxCount: 50
    property int notifHistoryMaxAgeDays: 7
    property var notifRules: []
    property bool notifTtsEnabled: false
    property string notifTtsEngine: "espeak-ng"  // espeak-ng | piper | speak
    property int notifTtsRate: 175               // words per minute
    property int notifTtsVolume: 100             // 0-200 (espeak scale)
    property var notifTtsExcludedApps: []        // app names to skip

    // --- TIME ---
    property bool timeUse24Hour: true
    property bool timeShowSeconds: false
    property bool timeShowBarDate: true
    property string timeBarDateStyle: "weekday_short" // weekday_short | month_day | weekday_month_day

    // --- WEATHER ---
    property string weatherProvider: "open-meteo" // open-meteo | wttr
    property string weatherUnits: "metric" // metric | imperial
    property bool weatherAutoLocation: true
    property string weatherCityQuery: ""
    property string weatherLatitude: ""
    property string weatherLongitude: ""
    property string weatherLocationPriority: "latlon_city_auto"
    property bool weatherUiAnimationEnabled: false

    // --- MARKET ---
    property string marketTickers: "^SPX ^DJI ^NDQ"

    // --- LAUNCHER ---
    property string launcherDefaultMode: "drun"
    property bool launcherShowModeHints: true
    property bool launcherShowHomeSections: false
    property bool launcherDrunCategoryFiltersEnabled: false
    property bool launcherEnablePreload: true
    property bool launcherKeepSearchOnModeSwitch: true
    property bool launcherEnableDebugTimings: false
    property bool launcherShowRuntimeMetrics: false
    property string launcherCharacterTrigger: ":"
    property bool launcherCharacterPasteOnSelect: false
    property int launcherPreloadFailureThreshold: 3
    property int launcherPreloadFailureBackoffSec: 120
    property int launcherMaxResults: 80
    property int launcherFileMinQueryLength: 2
    property int launcherFileMaxResults: 100
    property string launcherFileSearchRoot: "~"
    property bool launcherFileShowHidden: false
    property string launcherFileOpener: "xdg-open"
    property bool launcherFilePreviewEnabled: true
    property int launcherRecentsLimit: 12
    property int launcherRecentAppsLimit: 6
    property int launcherSuggestionsLimit: 4
    property int launcherCacheTtlSec: 300
    property int launcherSearchDebounceMs: 35
    property int launcherFileSearchDebounceMs: 140
    property string launcherTabBehavior: "contextual"
    property bool launcherWebEnterUsesPrimary: true
    property bool launcherWebNumberHotkeysEnabled: true
    property var launcherWebAliases: ({
            "duckduckgo": ["d", "ddg"],
            "google": ["g"],
            "youtube": ["yt"],
            "nixos": ["nix", "np"],
            "github": ["gh"],
            "brave": ["br"],
            "bing": ["b"],
            "kagi": ["k"],
            "stackoverflow": ["so", "stack"],
            "npm": ["n"],
            "pypi": ["pip", "py"],
            "crates": ["cr", "cargo"],
            "mdn": ["md"],
            "archwiki": ["aw", "arch"],
            "aur": ["au"],
            "nixopts": ["no", "opts"],
            "reddit": ["r"],
            "twitter": ["tw", "x"],
            "linkedin": ["li"],
            "wikipedia": ["w", "wiki"],
            "translate": ["tr"],
            "imdb": ["im"],
            "amazon": ["az"],
            "ebay": ["eb"],
            "maps": ["map"],
            "images": ["img"]
        })
    property bool launcherRememberWebProvider: true
    property string launcherWebLastProviderKey: "duckduckgo"
    property var launcherWebProviderOrder: ["duckduckgo", "google", "youtube", "nixos", "github"]
    property var launcherModeOrder: ["drun", "window", "files", "ai", "system", "settings", "run", "ssh", "web", "clip", "emoji", "calc", "bookmarks", "media", "nixos", "wallpapers", "plugins", "devops", "orchestrator", "keybinds"]
    property var launcherEnabledModes: ["drun", "window", "files", "ai", "system", "settings", "run", "ssh", "web", "clip", "emoji", "calc", "bookmarks", "media", "nixos", "wallpapers", "plugins", "devops", "orchestrator", "keybinds"]
    property var launcherPrimaryModes: ["drun", "window", "files", "ai", "system"]
    property real launcherScoreNameWeight: 1.0
    property real launcherScoreTitleWeight: 0.92
    property real launcherScoreExecWeight: 0.88
    property real launcherScoreBodyWeight: 0.75
    property real launcherScoreCategoryWeight: 0.7
    property var launcherWebCustomEngines: []
    property bool launcherWebBangsEnabled: false
    property string launcherWebBangsLastSync: ""

    // --- MODEL USAGE ---
    property bool modelUsageClaudeEnabled: true
    property bool modelUsageCodexEnabled: false
    property bool modelUsageGeminiEnabled: false
    property string modelUsageActiveProvider: "claude"
    property string modelUsageBarMetric: "prompts" // prompts | tokens
    property int modelUsageRefreshSec: 30

    // --- CONTROL CENTER ---
    readonly property int controlCenterWidthMin: 440
    readonly property int controlCenterWidthDefault: 440
    readonly property int controlCenterWidthMax: 560
    property int controlCenterWidth: controlCenterWidthDefault
    property bool controlCenterShowQuickLinks: true
    property bool controlCenterShowMediaWidget: true
    property var controlCenterToggleOrder: ["bluetooth", "dnd", "nightLight", "caffeine", "recording"]
    property var controlCenterHiddenToggles: []
    property var controlCenterPluginOrder: []
    property var controlCenterHiddenPlugins: []

    // --- ON-SCREEN KEYBOARD ---
    property string oskLayout: "English (US)"
    property bool oskPinnedOnStartup: false

    // --- OSD ---
    property int osdDuration: 2000
    property int osdSize: 180
    property string osdPosition: "top"
    property string osdStyle: "circular"
    property bool osdOverdrive: false

    // --- DOCK ---
    property bool dockEnabled: true
    property bool dockAutoHide: false
    property var dockPinnedApps: []
    property string dockPosition: "bottom"
    property bool dockGroupApps: true
    property int dockIconSize: 36

    // --- DESKTOP WIDGETS ---
    property bool desktopWidgetsEnabled: false
    property bool desktopWidgetsGridSnap: false
    property bool desktopEditMode: false
    property var desktopWidgetsMonitorWidgets: []

    // --- BACKGROUND ---
    property bool backgroundVisualizerEnabled: false
    property bool backgroundUseShaderVisualizer: false
    property bool backgroundClockEnabled: false
    property bool backgroundAutoHide: true
    property string backgroundClockPosition: "center"
    property bool weatherOverlayEnabled: false

    // --- SCREEN DECORATIONS ---
    property bool showScreenBorders: false
    property bool showScreenCorners: true
    property int screenCornerRadius: 18

    // --- OLED ---
    property bool oledMode: false

    // --- HOT CORNERS ---
    property bool hotCornersEnabled: false

    // --- POWER MENU ---
    property int powermenuCountdown: 3000

    // --- LOCK SCREEN ---
    property bool lockScreenCompact: false
    property bool lockScreenMediaControls: true
    property bool lockScreenWeather: true
    property bool lockScreenSessionButtons: true
    property int lockScreenCountdown: 5000
    property bool lockScreenFingerprint: true

    // --- PRIVACY ---
    property bool privacyIndicatorsEnabled: true
    property bool privacyCameraMonitoring: true

    // --- AUDIO ---
    property bool volumeProtectionEnabled: true
    property real volumeProtectionMaxJump: 0.15
    property var audioPinnedOutputs: []
    property var audioPinnedInputs: []
    property var audioHiddenOutputs: []
    property var audioHiddenInputs: []

    // --- SCREENSHOT ---
    property string screenshotEditor: "none"        // none | swappy | satty
    property bool screenshotEditAfterCapture: false
    property int screenshotDelay: 0                 // 0, 3, 5, 10 seconds
    property string ocrLanguage: "eng"              // tesseract language code
    property var screenshotHistory: []               // [{path, timestamp, mode}]
    property int screenshotHistoryMax: 20

    // --- RECORDING ---
    property string recordingCaptureSource: "portal"   // portal | screen
    property int recordingFps: 60
    property string recordingQuality: "very_high"      // medium | high | very_high
    property bool recordingRecordCursor: true
    property string recordingOutputDir: ""
    property bool recordingIncludeDesktopAudio: true
    property bool recordingIncludeMicrophoneAudio: false

    // --- NIGHT LIGHT ---
    property bool nightLightEnabled: false
    property int nightLightTemperature: 4000
    property bool nightLightAutoSchedule: false
    property string nightLightScheduleMode: "time"
    property int nightLightStartHour: 20
    property int nightLightStartMinute: 0
    property int nightLightEndHour: 6
    property int nightLightEndMinute: 0
    property string nightLightLatitude: ""
    property string nightLightLongitude: ""

    // --- POWER ---
    property int powerAcMonitorTimeout: 15
    property int powerAcLockTimeout: 20
    property int powerAcSuspendTimeout: 45
    property string powerAcSuspendAction: "hibernate"
    property int powerBatMonitorTimeout: 5
    property int powerBatLockTimeout: 7
    property int powerBatSuspendTimeout: 10
    property string powerBatSuspendAction: "suspend"
    property bool batteryAlertsEnabled: true
    property int batteryWarningThreshold: 20
    property int batteryCriticalThreshold: 10
    property bool idleInhibitEnabled: false
    property bool inhibitIdleWhenPlaying: false
    // --- WORKSPACES ---
    property bool workspaceShowEmpty: true
    property bool workspaceShowNames: false
    property bool workspaceShowAppIcons: false
    property bool workspaceShowWindowCount: false
    property int workspaceMaxIcons: 3
    property string workspacePillSize: "normal"
    property string workspaceStyle: "pill" // pill | strip | dots | icons
    property string workspaceLayout: "horizontal" // horizontal | vertical | grid
    property bool workspaceScrollEnabled: true
    property bool workspaceReverseScroll: false
    property string workspaceActiveColor: ""
    property string workspaceUrgentColor: ""
    property string workspaceClickBehavior: "focus" // focus | last_window

    // --- DISPLAY PROFILES ---
    property var displayProfiles: []
    property bool displayAutoProfile: false

    // --- COLOR PICKER ---
    property var recentPickerColors: []

    // --- WALLPAPER ---
    property bool wallpaperRunPywal: false
    property var wallpaperPaths: ({})
    property int wallpaperCycleInterval: 0
    property string wallpaperDefaultFolder: (Quickshell.env("HOME") || "/home") + "/Pictures"
    property string wallpaperSolidColor: "000000ff"
    property bool wallpaperUseSolidOnStartup: false
    property var wallpaperSolidColorsByMonitor: ({})
    property var wallpaperRecentSolidColors: []
    property string wallpaperTransitionType: "fade"     // fade | pixelate | wipe | none
    property int wallpaperTransitionDuration: 1500       // ms
    property bool wallpaperUseShellRenderer: false       // true = shell renders wallpaper, false = use swww/external
    property bool wallpaperDynamicEnabled: false
    property string wallpaperDynamicManifest: ""         // path to manifest.json
    property bool wallpaperVideoEnabled: false
    property string wallpaperVideoPath: ""               // path to video file

    // --- WALLHAVEN ---
    property string wallhavenApiKey: ""                  // optional API key for NSFW/favorites
    property string wallhavenLastQuery: ""
    property string wallhavenDownloadDir: (Quickshell.env("HOME") || "/home") + "/Pictures/Wallhaven"

    // --- COLOR BACKEND ---
    property string colorBackend: "pywal"  // pywal | matugen | dynamic

    // --- THEME ---
    property string themeName: ""
    property bool themeAutoScheduleEnabled: false
    property bool useDynamicTheming: false
    property string themeAutoScheduleMode: "time"
    property string themeDarkName: ""
    property string themeLightName: ""
    property int themeDarkHour: 20
    property int themeDarkMinute: 0
    property int themeLightHour: 7
    property int themeLightMinute: 0
    property string themeAutoLatitude: ""
    property string themeAutoLongitude: ""

    // --- APPEARANCE ---
    property string fontFamily: "Inter"
    property string monoFontFamily: "JetBrainsMono Nerd Font"
    property real fontScale: 1.0
    property real radiusScale: 1.0
    property real spacingScale: 1.0
    property real uiDensityScale: 1.0
    property real animationSpeedScale: 1.0
    property bool autoEcoMode: true
    property bool personalityGifEnabled: false
    property string personalityGifPath: ""
    property string personalityGifReactionMode: "media" // media | cpu | beat | idle

    // --- AI ASSISTANT ---
    property string aiProvider: "ollama"           // "ollama"|"anthropic"|"openai"|"gemini"|"custom"
    property string aiModel: ""                    // empty = provider default
    property string aiCustomEndpoint: ""           // for "custom" provider
    property bool aiSystemContext: false            // include system info in prompt
    property bool notepadProjectSync: true          // auto-switch tabs based on workspace name
    property int aiMaxTokens: 4096
    property real aiTemperature: 0.7
    property string aiSystemPrompt: ""             // custom system prompt
    property string aiAnthropicKey: ""             // fallback if ANTHROPIC_API_KEY env not set
    property string aiOpenaiKey: ""                // fallback if OPENAI_API_KEY env not set
    property string aiGeminiKey: ""                // fallback if GEMINI_API_KEY env not set
    property int aiMaxConversations: 20
    property int aiMaxMessages: 100                // per conversation
    property string aiProviderProfiles: "{}"       // JSON — per-provider model/temp/tokens/endpoint
    property int aiTimeout: 120                    // seconds, passed to curl --max-time
    property bool aiToolCallAutoReply: false        // auto-send tool output back to AI

    // --- STATE RECOVERY ---
    property string activeSurfaceId: ""
    onActiveSurfaceIdChanged: {
        if (!pauseAutoSave) scheduleSave();
    }

    // --- PLUGINS ---
    property var disabledPlugins: []
    property var pluginLauncherTriggers: ({})
    property var pluginLauncherNoTrigger: ({})
    property var pluginSettings: ({})
    property bool pluginHotReload: true

    // --- PANELS ---
    property var enabledPanels: [
        "notifCenter", "controlCenter", "notepad", "aiChat",
        "commandPalette", "powerMenu", "colorPicker", "displayConfig",
        "fileBrowser", "systemMonitor"
    ]

    // --- HOOKS ---
    property bool hooksEnabled: true
    property var hookPaths: ({})

    // --- COLOR EXPORT ---
    property bool colorExportEnabled: false
    property bool colorExportGhostty: false
    property bool colorExportKitty: false
    property bool colorExportGtkScheme: false

    // --- INTERNAL ---
    property bool debug: false
    property bool pauseAutoSave: false
    property bool configReady: false
    property bool _syncingLegacyBarSettings: false

    readonly property int maxBars: 4
    readonly property int popupGap: 8
    readonly property int overlayInset: 12
    readonly property string configPath: Quickshell.env("HOME") + "/.local/state/quickshell/config.json"
    readonly property var iconAliases: ({
            "alacritty": ["utilities-terminal", "terminal", "org.gnome.Console"],
            "org.alacritty.alacritty": ["utilities-terminal", "terminal", "org.gnome.Console"],
            "org.gnome.nautilus": ["system-file-manager", "folder", "inode-directory"],
            "nautilus": ["system-file-manager", "folder", "inode-directory"],
            "com.mitchellh.ghostty": ["com.mitchellh.ghostty"],
            "ghostty": ["com.mitchellh.ghostty"],
            "firefox": ["firefox", "org.mozilla.firefox", "mozilla-firefox"],
            "nvim": ["nvim", "neovim"],
            "neovim": ["neovim", "nvim"],
            "mpv": ["mpv", "mpv-symbolic"]
        })

    function normalizedIconNames(name) {
        if (!name)
            return [];
        if (name.startsWith("/") || name.startsWith("file://"))
            return [name];

        var customPathIndex = name.indexOf("?path=");
        var baseName = customPathIndex === -1 ? name : name.substring(0, customPathIndex);
        var customPath = customPathIndex === -1 ? "" : name.substring(customPathIndex + 6);
        var lookupName = baseName;
        if (lookupName.startsWith("image://icon/"))
            lookupName = lookupName.substring("image://icon/".length);
        else if (lookupName.startsWith("image://"))
            return [lookupName];

        var lower = lookupName.toLowerCase();
        var names = [];

        function appendUnique(value) {
            if (!value)
                return;
            if (names.indexOf(value) === -1)
                names.push(value);
        }

        if (customPath.startsWith("/")) {
            appendUnique(customPath + "/" + lookupName);
            appendUnique(customPath + "/" + lookupName + ".svg");
            appendUnique(customPath + "/" + lookupName + ".png");
            appendUnique(customPath + "/" + lookupName + ".xpm");
        }

        appendUnique(lookupName);
        appendUnique(lower);

        var aliases = iconAliases[lower] || [];
        for (var i = 0; i < aliases.length; ++i)
            appendUnique(aliases[i]);

        return names;
    }

    function resolveIconPath(name) {
        var names = normalizedIconNames(name);
        for (var i = 0; i < names.length; ++i) {
            var candidate = names[i];
            if (!candidate)
                continue;
            if (candidate.startsWith("/") || candidate.startsWith("file://"))
                return candidate;

            var resolved = Quickshell.iconPath(candidate, true);
            if (resolved && resolved !== candidate && (resolved.startsWith("/") || resolved.startsWith("file://")))
                return resolved;
        }

        return "";
    }

    function resolveIconSource(name) {
        var resolved = resolveIconPath(name);
        if (!resolved)
            return "";
        if (resolved.startsWith("file://") && resolved.indexOf("/image://") !== -1)
            return "";
        if (resolved.startsWith("/") || resolved.startsWith("file://"))
            return resolved.startsWith("file://") ? resolved : "file://" + resolved;
        return resolved;
    }

    function isPanelEnabled(panelId) {
        return enabledPanels.indexOf(panelId) !== -1;
    }

    function applyRuntimeSettings() {
        if (CompositorAdapter.supportsHyprctlSettings) {
            CompositorAdapter.setHyprKeyword("decoration:blur:enabled", blurEnabled ? "true" : "false", "Set blur");
        }
    }

    function normalizeLauncherConfig(data) {
        ConfigLauncher.applyLauncherConfig(root, data);
    }

    // ── Bar management delegated to ConfigBarManager ──
    property ConfigBarManager _barMgr: ConfigBarManager {
        config: root
    }

    // Facade methods — preserve existing Config.xxx() call sites
    function defaultBarSectionWidgets() {
        return _barMgr.defaultBarSectionWidgets();
    }
    function generateId(prefix) {
        return _barMgr.generateId(prefix);
    }
    function createWidgetInstance(widgetType, initialSettings) {
        return _barMgr.createWidgetInstance(widgetType, initialSettings);
    }
    function createBarConfig(name) {
        return _barMgr.createBarConfig(name);
    }
    function isValidEdge(position) {
        return _barMgr.isValidEdge(position);
    }
    function isVerticalBar(positionOrBar) {
        return _barMgr.isVerticalBar(positionOrBar);
    }
    function barThickness(barConfig) {
        return _barMgr.barThickness(barConfig);
    }
    function floatingInset(barConfig) {
        return _barMgr.floatingInset(barConfig);
    }
    function screenName(screen) {
        return _barMgr.screenName(screen);
    }
    function allScreens() {
        return _barMgr.allScreens();
    }
    function primaryScreen() {
        return _barMgr.primaryScreen();
    }
    function normalizeSectionWidgets(sectionWidgets) {
        return _barMgr.normalizeSectionWidgets(sectionWidgets);
    }
    function cloneWidgetSettings(item) {
        return _barMgr.cloneWidgetSettings(item);
    }
    function normalizedWidgetSettings(widgetType, item) {
        return _barMgr.normalizedWidgetSettings(widgetType, item);
    }
    function normalizeWidgetInstances(item) {
        return _barMgr.normalizeWidgetInstances(item);
    }
    function normalizeWidgetInstance(item) {
        return _barMgr.normalizeWidgetInstance(item);
    }
    function normalizeBarConfig(bar, index) {
        return _barMgr.normalizeBarConfig(bar, index);
    }
    function migrateLegacyBars(data) {
        return _barMgr.migrateLegacyBars(data);
    }
    function normalizeBarConfigs(bars, data) {
        return _barMgr.normalizeBarConfigs(bars, data);
    }
    function ensureSelectedBar() {
        _barMgr.ensureSelectedBar();
    }
    function selectedBar() {
        return _barMgr.selectedBar();
    }
    function barById(barId) {
        return _barMgr.barById(barId);
    }
    function barsForScreen(screen) {
        return _barMgr.barsForScreen(screen);
    }
    function barEnabledOnScreen(barConfig, screen) {
        return _barMgr.barEnabledOnScreen(barConfig, screen);
    }
    function screensForBar(barConfig) {
        return _barMgr.screensForBar(barConfig);
    }
    function barSectionWidgets(barConfig, section) {
        return _barMgr.barSectionWidgets(barConfig, section);
    }
    function sectionLabel(section, position) {
        return _barMgr.sectionLabel(section, position);
    }
    function cloneBar(barConfig) {
        return _barMgr.cloneBar(barConfig);
    }
    function replaceBarConfig(updatedBar) {
        return _barMgr.replaceBarConfig(updatedBar);
    }
    function barConflictDetails(barConfig) {
        return _barMgr.barConflictDetails(barConfig);
    }
    function barConflictMessage(barConfig) {
        return _barMgr.barConflictMessage(barConfig);
    }
    function addBar() {
        return _barMgr.addBar();
    }
    function removeBar(barId) {
        return _barMgr.removeBar(barId);
    }
    function setSelectedBar(barId) {
        return _barMgr.setSelectedBar(barId);
    }
    function updateBarConfig(barId, patch) {
        return _barMgr.updateBarConfig(barId, patch);
    }
    function updateBarDisplayTargets(barId, targets) {
        return _barMgr.updateBarDisplayTargets(barId, targets);
    }
    function updateBarSection(barId, section, widgets) {
        return _barMgr.updateBarSection(barId, section, widgets);
    }
    function addBarWidget(barId, section, widgetType, initialSettings) {
        return _barMgr.addBarWidget(barId, section, widgetType, initialSettings);
    }
    function applyBarWidgetPreset(barId, presetName) {
        return _barMgr.applyBarWidgetPreset(barId, presetName);
    }
    function removeBarWidget(barId, section, instanceId) {
        return _barMgr.removeBarWidget(barId, section, instanceId);
    }
    function updateBarWidget(barId, section, instanceId, patch) {
        return _barMgr.updateBarWidget(barId, section, instanceId, patch);
    }
    function updateBarWidgetByInstance(instanceId, patch) {
        return _barMgr.updateBarWidgetByInstance(instanceId, patch);
    }
    function findBarWidgetInstance(instanceId) {
        return _barMgr.findBarWidgetInstance(instanceId);
    }
    function moveBarWidget(barId, section, fromIndex, toIndex, targetSection) {
        return _barMgr.moveBarWidget(barId, section, fromIndex, toIndex, targetSection);
    }
    function widgetInstance(barId, section, instanceId) {
        return _barMgr.widgetInstance(barId, section, instanceId);
    }
    function surfaceAnchorBar(barId, screen) {
        return _barMgr.surfaceAnchorBar(barId, screen);
    }
    function screenBarConflict(barId, position, screen) {
        return _barMgr.screenBarConflict(barId, position, screen);
    }
    function barHasConflict(barConfig) {
        return _barMgr.barHasConflict(barConfig);
    }
    function dockConflictsWithBar(barConfig) {
        return _barMgr.dockConflictsWithBar(barConfig);
    }
    function dockConflictScreens(positionOverride) {
        return _barMgr.dockConflictScreens(positionOverride);
    }
    function dockConflictMessage(positionOverride) {
        return _barMgr.dockConflictMessage(positionOverride);
    }
    function barDockConflictScreens(barConfig) {
        return _barMgr.barDockConflictScreens(barConfig);
    }
    function barDockConflictMessage(barConfig) {
        return _barMgr.barDockConflictMessage(barConfig);
    }
    function dockConflictsOnScreen(screen, positionOverride) {
        return _barMgr.dockConflictsOnScreen(screen, positionOverride);
    }
    function dockHasConflict() {
        return _barMgr.dockHasConflict();
    }
    function canUseDockPosition(position) {
        return _barMgr.canUseDockPosition(position);
    }
    function setDockPosition(position) {
        return _barMgr.setDockPosition(position);
    }
    function reservedEdgesForScreen(screen, excludeBarId) {
        return _barMgr.reservedEdgesForScreen(screen, excludeBarId);
    }
    function notificationMargins(screen) {
        return _barMgr.notificationMargins(screen);
    }
    function compatibleLegacyBar() {
        return _barMgr.compatibleLegacyBar();
    }
    function syncLegacyBarSettingsFromPrimary() {
        _barMgr.syncLegacyBarSettingsFromPrimary();
    }
    function applyLegacyBarSetting(key, value) {
        _barMgr.applyLegacyBarSetting(key, value);
    }

    readonly property int _saveDebounceMs: 500

    property Timer saveTimer: Timer {
        interval: root._saveDebounceMs
        onTriggered: root.save()
    }

    property ConfigAutoSave _autoSave: ConfigAutoSave {
        config: root
    }

    function _pushModularHistory() {
        var snapshot = {
            left: barLeftEntries.slice(),
            center: barCenterEntries.slice(),
            right: barRightEntries.slice()
        };
        var history = _modularLayoutHistory.slice();
        history.push(snapshot);
        if (history.length > 10) history.shift();
        _modularLayoutHistory = history;
    }

    function undoModularChange() {
        if (_modularLayoutHistory.length === 0) return;
        var history = _modularLayoutHistory.slice();
        var last = history.pop();
        
        // Block save during restore to avoid loops
        pauseAutoSave = true;
        barLeftEntries = last.left;
        barCenterEntries = last.center;
        barRightEntries = last.right;
        pauseAutoSave = false;
        
        _modularLayoutHistory = history;
        scheduleSave();
    }

    function addModularEntry(section, type) {
        _pushModularHistory();
        var list = [];
        if (section === "left") list = barLeftEntries.slice();
        else if (section === "center") list = barCenterEntries.slice();
        else if (section === "right") list = barRightEntries.slice();

        list.push(type);

        if (section === "left") barLeftEntries = list;
        else if (section === "center") barCenterEntries = list;
        else if (section === "right") barRightEntries = list;

        scheduleSave();
    }

    function moveModularEntry(section, index, direction) {
        _pushModularHistory();
        var list = [];
        if (section === "left") list = barLeftEntries.slice();
        else if (section === "center") list = barCenterEntries.slice();
        else if (section === "right") list = barRightEntries.slice();

        if (index < 0 || index >= list.length) return;
        var newIndex = index + direction;
        if (newIndex < 0 || newIndex >= list.length) return;

        var item = list.splice(index, 1)[0];
        list.splice(newIndex, 0, item);

        if (section === "left") barLeftEntries = list;
        else if (section === "center") barCenterEntries = list;
        else if (section === "right") barRightEntries = list;

        scheduleSave();
    }

    function removeModularEntry(section, index) {
        _pushModularHistory();
        var list = [];
        if (section === "left") list = barLeftEntries.slice();
        else if (section === "center") list = barCenterEntries.slice();
        else if (section === "right") list = barRightEntries.slice();

        if (index < 0 || index >= list.length) return;
        list.splice(index, 1);

        if (section === "left") barLeftEntries = list;
        else if (section === "center") barCenterEntries = list;
        else if (section === "right") barRightEntries = list;

        scheduleSave();
    }

    function scheduleSave() {
        if (!pauseAutoSave)
            saveTimer.restart();
    }

    function load() {
        var done = Logger.perf("Config", "load");
        var raw = configFile.text();
        if (!raw) {
            ConfigPersistence.initializeDefaults(root);
            configReady = true;
            done();
            return;
        }

        pauseAutoSave = true;

        try {
            var data = JSON.parse(raw);
            ConfigPersistence.applyData(root, data);
        } catch (e) {
            Logger.e("Config", "Failed to load config:", e);
            barConfigs = normalizeBarConfigs([], {});
        }

        ensureSelectedBar();
        syncLegacyBarSettingsFromPrimary();
        pauseAutoSave = false;
        configReady = true;
        applyRuntimeSettings();
        done();
    }

    property FileView configFile: FileView {
        path: root.configPath
        blockLoading: true
        printErrors: false
        onLoaded: root.load()
        onLoadFailed: error => {
            if (error === 2) {
                ConfigPersistence.initializeDefaults(root);
                root.configReady = true;
                root.save();
                return;
            }
            Logger.e("Config", "Failed to load config file:", error);
            root.configReady = true;
        }
        onSaveFailed: error => Logger.e("Config", "Failed to save config file:", error)
    }

    function save() {
        var data = ConfigPersistence.buildData(root);

        configFile.setText(JSON.stringify(data, null, 2));
        applyRuntimeSettings();
    }
}
