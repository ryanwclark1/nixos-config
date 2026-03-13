import QtQuick
import Quickshell
import Quickshell.Io

pragma Singleton

QtObject {
  id: root

  // --- BAR (legacy compatibility + shell defaults) ---
  property int barHeight: 38
  property bool barFloating: true
  property int barMargin: 12
  property real barOpacity: 0.85
  property var barConfigs: []
  property string selectedBarId: ""

  // --- GLASS ---
  property bool blurEnabled: true
  property real glassOpacity: 0.65

  // --- NOTIFICATIONS ---
  property int notifWidth: 350
  property int popupTimer: 5000

  // --- TIME ---
  property bool timeUse24Hour: true
  property bool timeShowSeconds: false
  property bool timeShowBarDate: true
  property string timeBarDateStyle: "weekday_short" // weekday_short | month_day | weekday_month_day

  // --- WEATHER ---
  property string weatherUnits: "metric" // metric | imperial
  property bool weatherAutoLocation: true
  property string weatherCityQuery: ""
  property string weatherLatitude: ""
  property string weatherLongitude: ""
  property string weatherLocationPriority: "latlon_city_auto"

  // --- LAUNCHER ---
  property string launcherDefaultMode: "drun"
  property bool launcherShowModeHints: true
  property bool launcherShowHomeSections: true
  property bool launcherEnablePreload: true
  property bool launcherKeepSearchOnModeSwitch: true
  property bool launcherEnableDebugTimings: false
  property bool launcherShowRuntimeMetrics: false
  property int launcherPreloadFailureThreshold: 3
  property int launcherPreloadFailureBackoffSec: 120
  property int launcherMaxResults: 80
  property int launcherFileMinQueryLength: 2
  property int launcherFileMaxResults: 100
  property int launcherRecentsLimit: 12
  property int launcherRecentAppsLimit: 6
  property int launcherSuggestionsLimit: 4
  property int launcherCacheTtlSec: 300
  property int launcherSearchDebounceMs: 35
  property int launcherFileSearchDebounceMs: 140
  property bool launcherWebEnterUsesPrimary: true
  property bool launcherWebNumberHotkeysEnabled: true
  property var launcherWebAliases: ({
    "duckduckgo": ["d", "ddg"],
    "google": ["g"],
    "youtube": ["yt"],
    "nixos": ["nix", "np"],
    "github": ["gh"]
  })
  property bool launcherRememberWebProvider: true
  property string launcherWebLastProviderKey: "duckduckgo"
  property var launcherWebProviderOrder: ["duckduckgo", "google", "youtube", "nixos", "github"]
  property var launcherModeOrder: ["drun", "window", "files", "ai", "clip", "emoji", "calc", "web", "run", "system", "keybinds", "media", "nixos", "wallpapers", "bookmarks"]
  property var launcherEnabledModes: ["drun", "window", "files", "ai", "clip", "emoji", "calc", "web", "run", "system", "keybinds", "media", "nixos", "wallpapers", "bookmarks"]
  property real launcherScoreNameWeight: 1.0
  property real launcherScoreTitleWeight: 0.92
  property real launcherScoreExecWeight: 0.88
  property real launcherScoreBodyWeight: 0.75

  // --- CONTROL CENTER ---
  property int controlCenterWidth: 350
  property bool controlCenterShowQuickLinks: true
  property bool controlCenterShowMediaWidget: true

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
  property var desktopWidgetsMonitorWidgets: []

  // --- SCREEN BORDERS ---
  property bool showScreenBorders: false

  // --- POWER MENU ---
  property int powermenuCountdown: 3000

  // --- LOCK SCREEN ---
  property bool lockScreenCompact: false
  property bool lockScreenMediaControls: true
  property bool lockScreenWeather: true
  property bool lockScreenSessionButtons: true
  property int lockScreenCountdown: 5000

  // --- PRIVACY ---
  property bool privacyIndicatorsEnabled: true
  property bool privacyCameraMonitoring: true

  // --- POWER ---
  property bool idleInhibitEnabled: false

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

  // --- THEME ---
  property string themeName: ""

  // --- PLUGINS ---
  property var disabledPlugins: []

  // --- INTERNAL ---
  property bool _loading: false
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
    "ghostty": ["com.mitchellh.ghostty"]
  })

  function normalizedIconNames(name) {
    if (!name) return [];
    if (name.startsWith("/") || name.startsWith("file://")) return [name];

    var lower = name.toLowerCase();
    var names = [];

    function appendUnique(value) {
      if (!value) return;
      if (names.indexOf(value) === -1) names.push(value);
    }

    appendUnique(name);
    appendUnique(lower);

    var aliases = iconAliases[lower] || [];
    for (var i = 0; i < aliases.length; ++i) appendUnique(aliases[i]);

    return names;
  }

  function resolveIconPath(name) {
    var names = normalizedIconNames(name);
    for (var i = 0; i < names.length; ++i) {
      var candidate = names[i];
      if (!candidate) continue;
      if (candidate.startsWith("/") || candidate.startsWith("file://")) return candidate;

      var resolved = Quickshell.iconPath(candidate, true);
      if (resolved && resolved !== candidate && (resolved.startsWith("/") || resolved.startsWith("file://"))) return resolved;
    }

    return "";
  }

  function resolveIconSource(name) {
    var resolved = resolveIconPath(name);
    if (!resolved) return "";
    if (resolved.startsWith("/") || resolved.startsWith("file://"))
      return resolved.startsWith("file://") ? resolved : "file://" + resolved;
    return resolved;
  }

  function applyRuntimeSettings() {
    if (CompositorAdapter.supportsHyprctlSettings) {
      Quickshell.execDetached([
        "hyprctl",
        "keyword",
        "decoration:blur:enabled",
        blurEnabled ? "true" : "false"
      ]);
    }
  }

  function _toInt(value, fallback) {
    var n = parseInt(value, 10);
    return isNaN(n) ? fallback : n;
  }

  function _toReal(value, fallback) {
    var n = Number(value);
    return isNaN(n) ? fallback : n;
  }

  function _clampInt(value, min, max, fallback) {
    var n = _toInt(value, fallback);
    if (n < min) return min;
    if (n > max) return max;
    return n;
  }

  function _clampReal(value, min, max, fallback) {
    var n = _toReal(value, fallback);
    if (n < min) return min;
    if (n > max) return max;
    return n;
  }

  function _asBool(value, fallback) {
    if (value === true || value === false) return value;
    if (value === "true") return true;
    if (value === "false") return false;
    return fallback;
  }

  function _normalizeModeList(list, fallbackList) {
    var allowed = {
      "drun": true,
      "window": true,
      "files": true,
      "ai": true,
      "clip": true,
      "emoji": true,
      "calc": true,
      "web": true,
      "run": true,
      "system": true,
      "keybinds": true,
      "media": true,
      "nixos": true,
      "wallpapers": true,
      "bookmarks": true
    };
    var source = Array.isArray(list) ? list : fallbackList;
    var out = [];
    var seen = {};
    for (var i = 0; i < source.length; ++i) {
      var mode = String(source[i] || "");
      if (!allowed[mode] || seen[mode]) continue;
      out.push(mode);
      seen[mode] = true;
    }
    if (out.length === 0) return fallbackList.slice();
    return out;
  }

  function _normalizeWebProviderOrder(list, fallbackList) {
    var allowed = {
      "duckduckgo": true,
      "google": true,
      "youtube": true,
      "nixos": true,
      "github": true
    };
    var source = Array.isArray(list) ? list : fallbackList;
    var out = [];
    var seen = {};
    for (var i = 0; i < source.length; ++i) {
      var provider = String(source[i] || "");
      if (!allowed[provider] || seen[provider]) continue;
      out.push(provider);
      seen[provider] = true;
    }
    if (out.length === 0) return fallbackList.slice();
    return out;
  }

  function _normalizeWebAliases(map, fallbackMap) {
    var allowed = ["duckduckgo", "google", "youtube", "nixos", "github"];
    var source = (map && typeof map === "object") ? map : {};
    var out = ({});
    var globalSeen = ({});
    var i;

    function addToken(token, seen, bucket, providerKey) {
      var normalized = String(token || "").trim().toLowerCase();
      if (normalized === "") return;
      if (!/^[a-z0-9][a-z0-9_-]{0,15}$/.test(normalized)) return;
      if (seen[normalized] || globalSeen[normalized]) return;
      if (normalized === providerKey) return;
      seen[normalized] = true;
      globalSeen[normalized] = true;
      bucket.push(normalized);
    }

    for (i = 0; i < allowed.length; ++i) {
      var provider = allowed[i];
      var raw = source[provider];
      var defaults = Array.isArray(fallbackMap[provider]) ? fallbackMap[provider] : [];
      var tokens = [];
      var seen = ({});
      var j;

      if (Array.isArray(raw)) {
        for (j = 0; j < raw.length; ++j)
          addToken(raw[j], seen, tokens, provider);
      } else if (typeof raw === "string") {
        var parts = raw.split(/[\s,]+/);
        for (j = 0; j < parts.length; ++j)
          addToken(parts[j], seen, tokens, provider);
      }

      if (tokens.length === 0) {
        for (j = 0; j < defaults.length; ++j)
          addToken(defaults[j], seen, tokens, provider);
      }

      out[provider] = tokens;
    }

    return out;
  }

  function normalizeLauncherConfig(data) {
    var launcher = data && data.launcher ? data.launcher : {};
    var fallbackModes = ["drun", "window", "files", "ai", "clip", "emoji", "calc", "web", "run", "system", "keybinds", "media", "nixos", "wallpapers", "bookmarks"];
    var fallbackWebProviders = ["duckduckgo", "google", "youtube", "nixos", "github"];

    launcherModeOrder = _normalizeModeList(launcher.modeOrder, fallbackModes);
    launcherEnabledModes = _normalizeModeList(launcher.enabledModes, fallbackModes);
    launcherDefaultMode = launcherEnabledModes.indexOf(String(launcher.defaultMode || "")) !== -1 ? launcher.defaultMode : "drun";
    if (launcherEnabledModes.indexOf(launcherDefaultMode) === -1)
      launcherDefaultMode = launcherEnabledModes[0] || "drun";

    launcherShowModeHints = _asBool(launcher.showModeHints, true);
    launcherShowHomeSections = _asBool(launcher.showHomeSections, true);
    launcherEnablePreload = _asBool(launcher.enablePreload, true);
    launcherKeepSearchOnModeSwitch = _asBool(launcher.keepSearchOnModeSwitch, true);
    launcherEnableDebugTimings = _asBool(launcher.enableDebugTimings, false);
    launcherShowRuntimeMetrics = _asBool(launcher.showRuntimeMetrics, false);
    launcherPreloadFailureThreshold = _clampInt(launcher.preloadFailureThreshold, 1, 10, 3);
    launcherPreloadFailureBackoffSec = _clampInt(launcher.preloadFailureBackoffSec, 10, 900, 120);

    launcherMaxResults = _clampInt(launcher.maxResults, 20, 400, 80);
    launcherFileMinQueryLength = _clampInt(launcher.fileMinQueryLength, 1, 8, 2);
    launcherFileMaxResults = _clampInt(launcher.fileMaxResults, 20, 500, 100);
    launcherRecentsLimit = _clampInt(launcher.recentsLimit, 1, 40, 12);
    launcherRecentAppsLimit = _clampInt(launcher.recentAppsLimit, 1, 20, 6);
    launcherSuggestionsLimit = _clampInt(launcher.suggestionsLimit, 1, 20, 4);
    launcherCacheTtlSec = _clampInt(launcher.cacheTtlSec, 10, 3600, 300);
    launcherSearchDebounceMs = _clampInt(launcher.searchDebounceMs, 0, 250, 35);
    launcherFileSearchDebounceMs = _clampInt(launcher.fileSearchDebounceMs, 50, 1200, 140);
    launcherWebEnterUsesPrimary = _asBool(launcher.webEnterUsesPrimary, true);
    launcherWebNumberHotkeysEnabled = _asBool(launcher.webNumberHotkeysEnabled, true);
    launcherWebAliases = _normalizeWebAliases(launcher.webAliases, {
      "duckduckgo": ["d", "ddg"],
      "google": ["g"],
      "youtube": ["yt"],
      "nixos": ["nix", "np"],
      "github": ["gh"]
    });
    launcherWebProviderOrder = _normalizeWebProviderOrder(launcher.webProviderOrder, fallbackWebProviders);
    launcherRememberWebProvider = _asBool(launcher.rememberWebProvider, true);
    launcherWebLastProviderKey = String(launcher.webLastProviderKey || "duckduckgo");
    if (launcherWebProviderOrder.indexOf(launcherWebLastProviderKey) === -1)
      launcherWebLastProviderKey = launcherWebProviderOrder[0] || "duckduckgo";

    launcherScoreNameWeight = _clampReal(launcher.scoreNameWeight, 0.1, 4.0, 1.0);
    launcherScoreTitleWeight = _clampReal(launcher.scoreTitleWeight, 0.1, 4.0, 0.92);
    launcherScoreExecWeight = _clampReal(launcher.scoreExecWeight, 0.1, 4.0, 0.88);
    launcherScoreBodyWeight = _clampReal(launcher.scoreBodyWeight, 0.1, 4.0, 0.75);
  }

  function defaultBarSectionWidgets() {
    return {
      left: [
        createWidgetInstance("logo"),
        createWidgetInstance("workspaces"),
        createWidgetInstance("taskbar"),
        createWidgetInstance("systemMonitor")
      ],
      center: [
        createWidgetInstance("dateTime"),
        createWidgetInstance("mediaBar"),
        createWidgetInstance("updates"),
        createWidgetInstance("cava"),
        createWidgetInstance("idleInhibitor")
      ],
      right: [
        createWidgetInstance("weather"),
        createWidgetInstance("network"),
        createWidgetInstance("bluetooth"),
        createWidgetInstance("audio"),
        createWidgetInstance("music"),
        createWidgetInstance("privacy"),
        createWidgetInstance("recording"),
        createWidgetInstance("battery"),
        createWidgetInstance("printer"),
        createWidgetInstance("notepad"),
        createWidgetInstance("controlCenter"),
        createWidgetInstance("tray"),
        createWidgetInstance("clipboard"),
        createWidgetInstance("notifications")
      ]
    };
  }

  function generateId(prefix) {
    var stamp = Date.now().toString(36);
    var suffix = Math.floor(Math.random() * 1679616).toString(36);
    return prefix + "-" + stamp + "-" + suffix;
  }

  function createWidgetInstance(widgetType, initialSettings) {
    var settingsCopy = initialSettings ? JSON.parse(JSON.stringify(initialSettings)) : {};
    return {
      instanceId: generateId("widget"),
      widgetType: widgetType,
      enabled: true,
      settings: settingsCopy
    };
  }

  function createBarConfig(name) {
    var barIndex = (barConfigs || []).length + 1;
    var preferredPositions = ["top", "bottom", "left", "right"];
    var selectedPosition = "top";
    for (var posIndex = 0; posIndex < preferredPositions.length; ++posIndex) {
      var candidatePos = preferredPositions[posIndex];
      var occupied = false;
      for (var i = 0; i < (barConfigs || []).length; ++i) {
        if (barConfigs[i].enabled && barConfigs[i].position === candidatePos) {
          occupied = true;
          break;
        }
      }
      if (!occupied && dockEnabled && dockPosition === candidatePos)
        occupied = true;
      if (!occupied) {
        selectedPosition = candidatePos;
        break;
      }
    }
    return {
      id: generateId("bar"),
      name: name || (barIndex === 1 ? "Main Bar" : ("Bar " + barIndex)),
      enabled: true,
      position: selectedPosition,
      displayMode: "all",
      displayTargets: [],
      height: barHeight,
      floating: barFloating,
      margin: barMargin,
      opacity: barOpacity,
      sectionWidgets: defaultBarSectionWidgets()
    };
  }

  function isValidEdge(position) {
    return position === "top" || position === "bottom" || position === "left" || position === "right";
  }

  function isVerticalBar(positionOrBar) {
    var position = (typeof positionOrBar === "string") ? positionOrBar : ((positionOrBar && positionOrBar.position) || "top");
    return position === "left" || position === "right";
  }

  function barThickness(barConfig) {
    return Math.max(24, parseInt(barConfig && barConfig.height !== undefined ? barConfig.height : barHeight, 10) || barHeight);
  }

  function floatingInset(barConfig) {
    return !!(barConfig && barConfig.floating) ? Math.max(0, parseInt(barConfig.margin || 0, 10)) : 0;
  }

  function screenName(screen) {
    if (!screen) return "";
    if (screen.name !== undefined) return String(screen.name);
    return String(screen);
  }

  function allScreens() {
    return Quickshell.screens ? Quickshell.screens.values || Quickshell.screens : [];
  }

  function primaryScreen() {
    var screens = allScreens();
    return screens.length > 0 ? screens[0] : null;
  }

  function normalizeSectionWidgets(sectionWidgets) {
    var source = sectionWidgets || {};
    var normalized = { left: [], center: [], right: [] };
    var sections = ["left", "center", "right"];

    for (var i = 0; i < sections.length; ++i) {
      var section = sections[i];
      var items = source[section] || [];
      for (var j = 0; j < items.length; ++j) {
        normalized[section].push(normalizeWidgetInstance(items[j]));
      }
    }

    return normalized;
  }

  function normalizeWidgetInstance(item) {
    if (typeof item === "string") return createWidgetInstance(item);

    var widgetType = item && item.widgetType ? item.widgetType : (item && item.widgetId ? item.widgetId : "spacer");
    return {
      instanceId: item && item.instanceId ? item.instanceId : generateId("widget"),
      widgetType: widgetType,
      enabled: item && item.enabled !== undefined ? !!item.enabled : true,
      settings: item && item.settings ? JSON.parse(JSON.stringify(item.settings)) : {}
    };
  }

  function normalizeBarConfig(bar, index) {
    var normalized = {
      id: bar && bar.id ? bar.id : generateId("bar"),
      name: bar && bar.name ? bar.name : (index === 0 ? "Main Bar" : ("Bar " + (index + 1))),
      enabled: bar && bar.enabled !== undefined ? !!bar.enabled : true,
      position: isValidEdge(bar && bar.position) ? bar.position : "top",
      displayMode: bar && (bar.displayMode === "primary" || bar.displayMode === "specific") ? bar.displayMode : "all",
      displayTargets: bar && Array.isArray(bar.displayTargets) ? bar.displayTargets.slice() : [],
      height: Math.max(24, parseInt(bar && bar.height !== undefined ? bar.height : barHeight, 10) || barHeight),
      floating: bar && bar.floating !== undefined ? !!bar.floating : barFloating,
      margin: Math.max(0, parseInt(bar && bar.margin !== undefined ? bar.margin : barMargin, 10) || barMargin),
      opacity: Math.max(0.2, Math.min(1.0, Number(bar && bar.opacity !== undefined ? bar.opacity : barOpacity) || barOpacity)),
      sectionWidgets: normalizeSectionWidgets(bar && bar.sectionWidgets ? bar.sectionWidgets : defaultBarSectionWidgets())
    };

    return normalized;
  }

  function migrateLegacyBars(data) {
    var migrated = createBarConfig("Main Bar");

    if (data && data.bar) {
      if (data.bar.height !== undefined) migrated.height = Math.max(24, parseInt(data.bar.height, 10) || barHeight);
      if (data.bar.floating !== undefined) migrated.floating = !!data.bar.floating;
      if (data.bar.margin !== undefined) migrated.margin = Math.max(0, parseInt(data.bar.margin, 10) || barMargin);
      if (data.bar.opacity !== undefined) migrated.opacity = Math.max(0.2, Math.min(1.0, Number(data.bar.opacity) || barOpacity));
    }

    return [migrated];
  }

  function normalizeBarConfigs(bars, data) {
    var inputBars = Array.isArray(bars) ? bars : [];
    if (inputBars.length === 0)
      inputBars = migrateLegacyBars(data);

    var normalized = [];
    for (var i = 0; i < inputBars.length && normalized.length < maxBars; ++i) {
      normalized.push(normalizeBarConfig(inputBars[i], normalized.length));
    }

    if (normalized.length === 0)
      normalized.push(normalizeBarConfig(createBarConfig("Main Bar"), 0));

    return normalized;
  }

  function ensureSelectedBar() {
    if (!barConfigs || barConfigs.length === 0) {
      selectedBarId = "";
      return;
    }

    var i;
    for (i = 0; i < barConfigs.length; ++i) {
      if (barConfigs[i].id === selectedBarId) return;
    }

    selectedBarId = barConfigs[0].id;
  }

  function selectedBar() {
    return barById(selectedBarId) || (barConfigs.length > 0 ? barConfigs[0] : null);
  }

  function barById(barId) {
    var bars = barConfigs || [];
    for (var i = 0; i < bars.length; ++i) {
      if (bars[i].id === barId) return bars[i];
    }
    return null;
  }

  function barsForScreen(screen) {
    var screensBars = [];
    var bars = barConfigs || [];
    for (var i = 0; i < bars.length; ++i) {
      if (barEnabledOnScreen(bars[i], screen)) screensBars.push(bars[i]);
    }
    return screensBars;
  }

  function barEnabledOnScreen(barConfig, screen) {
    if (!barConfig || !barConfig.enabled || !screen) return false;
    var mode = barConfig.displayMode || "all";
    if (mode === "all") return true;
    if (mode === "primary") return primaryScreen() === screen;

    var targets = barConfig.displayTargets || [];
    var name = screenName(screen);
    return targets.indexOf(name) !== -1;
  }

  function screensForBar(barConfig) {
    var screens = allScreens();
    var matches = [];
    for (var i = 0; i < screens.length; ++i) {
      if (barEnabledOnScreen(barConfig, screens[i])) matches.push(screens[i]);
    }
    return matches;
  }

  function barSectionWidgets(barConfig, section) {
    if (!barConfig || !barConfig.sectionWidgets || !barConfig.sectionWidgets[section]) return [];
    return barConfig.sectionWidgets[section];
  }

  function sectionLabel(section, position) {
    if (!isVerticalBar(position)) {
      if (section === "left") return "Left";
      if (section === "center") return "Center";
      return "Right";
    }

    if (section === "left") return "Top";
    if (section === "center") return "Middle";
    return "Bottom";
  }

  function cloneBar(barConfig) {
    return JSON.parse(JSON.stringify(barConfig));
  }

  function replaceBarConfig(updatedBar) {
    if (!updatedBar || !updatedBar.id) return false;
    var next = [];
    var replaced = false;
    for (var i = 0; i < barConfigs.length; ++i) {
      if (barConfigs[i].id === updatedBar.id) {
        next.push(normalizeBarConfig(updatedBar, i));
        replaced = true;
      } else {
        next.push(barConfigs[i]);
      }
    }
    if (!replaced) return false;
    barConfigs = next;
    ensureSelectedBar();
    syncLegacyBarSettingsFromPrimary();
    return true;
  }

  function barConflictDetails(barConfig) {
    if (!barConfig || !barConfig.enabled) return null;
    var screens = screensForBar(barConfig);
    for (var i = 0; i < screens.length; ++i) {
      var conflictBar = screenBarConflict(barConfig.id, barConfig.position, screens[i]);
      if (conflictBar) {
        return {
          type: "bar",
          screenName: screenName(screens[i]),
          barId: conflictBar.id,
          barName: conflictBar.name || "Bar"
        };
      }
    }
    return null;
  }

  function barConflictMessage(barConfig) {
    var details = barConflictDetails(barConfig);
    if (!details) return "";
    return (details.barName || "Another bar") + " already uses the " + barConfig.position + " edge on " + details.screenName + ".";
  }

  function addBar() {
    if ((barConfigs || []).length >= maxBars) return null;
    var next = (barConfigs || []).slice();
    var created = createBarConfig();
    if (barConflictDetails(created)) return null;
    next.push(normalizeBarConfig(created, next.length));
    barConfigs = next;
    selectedBarId = created.id;
    syncLegacyBarSettingsFromPrimary();
    return created.id;
  }

  function removeBar(barId) {
    if ((barConfigs || []).length <= 1) return false;
    var next = [];
    for (var i = 0; i < barConfigs.length; ++i) {
      if (barConfigs[i].id !== barId) next.push(barConfigs[i]);
    }
    if (next.length === barConfigs.length) return false;
    barConfigs = next;
    ensureSelectedBar();
    syncLegacyBarSettingsFromPrimary();
    return true;
  }

  function setSelectedBar(barId) {
    if (!barById(barId)) return false;
    selectedBarId = barId;
    return true;
  }

  function updateBarConfig(barId, patch) {
    var barConfig = barById(barId);
    if (!barConfig) return false;

    var updated = cloneBar(barConfig);
    var keys = Object.keys(patch || {});
    for (var i = 0; i < keys.length; ++i)
      updated[keys[i]] = patch[keys[i]];

    if (updated.displayMode !== "specific") updated.displayTargets = [];
    updated = normalizeBarConfig(updated, 0);
    if (barConflictDetails(updated)) return false;

    return replaceBarConfig(updated);
  }

  function updateBarDisplayTargets(barId, targets) {
    return updateBarConfig(barId, { displayTargets: Array.isArray(targets) ? targets.slice() : [] });
  }

  function updateBarSection(barId, section, widgets) {
    var barConfig = barById(barId);
    if (!barConfig || ["left", "center", "right"].indexOf(section) === -1) return false;

    var updated = cloneBar(barConfig);
    if (!updated.sectionWidgets) updated.sectionWidgets = { left: [], center: [], right: [] };

    updated.sectionWidgets[section] = [];
    var source = Array.isArray(widgets) ? widgets : [];
    for (var i = 0; i < source.length; ++i)
      updated.sectionWidgets[section].push(normalizeWidgetInstance(source[i]));

    return replaceBarConfig(updated);
  }

  function addBarWidget(barId, section, widgetType, initialSettings) {
    var barConfig = barById(barId);
    if (!barConfig || ["left", "center", "right"].indexOf(section) === -1) return null;
    var widgets = barSectionWidgets(barConfig, section).slice();
    var created = createWidgetInstance(widgetType, initialSettings);
    widgets.push(created);
    if (!updateBarSection(barId, section, widgets)) return null;
    return created.instanceId;
  }

  function removeBarWidget(barId, section, instanceId) {
    var barConfig = barById(barId);
    if (!barConfig) return false;
    var widgets = barSectionWidgets(barConfig, section).slice();
    var next = [];
    for (var i = 0; i < widgets.length; ++i) {
      if (widgets[i].instanceId !== instanceId) next.push(widgets[i]);
    }
    return updateBarSection(barId, section, next);
  }

  function updateBarWidget(barId, section, instanceId, patch) {
    var barConfig = barById(barId);
    if (!barConfig) return false;
    var widgets = barSectionWidgets(barConfig, section).slice();
    var updated = [];
    var found = false;

    for (var i = 0; i < widgets.length; ++i) {
      var current = normalizeWidgetInstance(widgets[i]);
      if (current.instanceId === instanceId) {
        var merged = JSON.parse(JSON.stringify(current));
        var keys = Object.keys(patch || {});
        for (var j = 0; j < keys.length; ++j)
          merged[keys[j]] = patch[keys[j]];
        if (patch && patch.settings)
          merged.settings = JSON.parse(JSON.stringify(patch.settings));
        updated.push(normalizeWidgetInstance(merged));
        found = true;
      } else {
        updated.push(current);
      }
    }

    if (!found) return false;
    return updateBarSection(barId, section, updated);
  }

  function moveBarWidget(barId, section, fromIndex, toIndex) {
    var barConfig = barById(barId);
    if (!barConfig) return false;
    var widgets = barSectionWidgets(barConfig, section).slice();
    if (fromIndex < 0 || fromIndex >= widgets.length || toIndex < 0 || toIndex >= widgets.length) return false;
    if (fromIndex === toIndex) return true;

    var item = widgets.splice(fromIndex, 1)[0];
    widgets.splice(toIndex, 0, item);
    return updateBarSection(barId, section, widgets);
  }

  function widgetInstance(barId, section, instanceId) {
    var widgets = barSectionWidgets(barById(barId), section);
    for (var i = 0; i < widgets.length; ++i) {
      if (widgets[i].instanceId === instanceId) return widgets[i];
    }
    return null;
  }

  function surfaceAnchorBar(barId, screen) {
    var barConfig = barById(barId);
    if (barConfig && barEnabledOnScreen(barConfig, screen)) return barConfig;

    var candidates = barsForScreen(screen);
    if (candidates.length > 0) return candidates[0];
    return selectedBar();
  }

  function screenBarConflict(barId, position, screen) {
    var bars = barConfigs || [];
    for (var i = 0; i < bars.length; ++i) {
      var barConfig = bars[i];
      if (!barConfig.enabled || barConfig.id === barId) continue;
      if (barConfig.position !== position) continue;
      if (barEnabledOnScreen(barConfig, screen)) return barConfig;
    }
    return null;
  }

  function barHasConflict(barConfig) {
    if (!barConfig || !barConfig.enabled) return false;
    var screens = screensForBar(barConfig);
    for (var i = 0; i < screens.length; ++i) {
      if (screenBarConflict(barConfig.id, barConfig.position, screens[i])) return true;
    }
    return false;
  }

  function dockConflictsWithBar(barConfig) {
    if (!dockEnabled || !barConfig || !barConfig.enabled) return false;
    return barConfig.position === dockPosition;
  }

  function dockConflictScreens(positionOverride) {
    var screens = allScreens();
    var matches = [];
    for (var i = 0; i < screens.length; ++i) {
      if (dockConflictsOnScreen(screens[i], positionOverride))
        matches.push(screenName(screens[i]));
    }
    return matches;
  }

  function dockConflictMessage(positionOverride) {
    var screens = dockConflictScreens(positionOverride);
    if (screens.length === 0) return "";
    var edge = isValidEdge(positionOverride) ? positionOverride : dockPosition;
    return "The dock shares the " + edge + " edge with a bar on " + screens.join(", ") + ". It will stay hidden only on those displays.";
  }

  function barDockConflictScreens(barConfig) {
    if (!dockEnabled || !barConfig || !barConfig.enabled) return [];
    if (barConfig.position !== dockPosition) return [];
    var screens = screensForBar(barConfig);
    var matches = [];
    for (var i = 0; i < screens.length; ++i) {
      if (dockConflictsOnScreen(screens[i], barConfig.position))
        matches.push(screenName(screens[i]));
    }
    return matches;
  }

  function barDockConflictMessage(barConfig) {
    var screens = barDockConflictScreens(barConfig);
    if (screens.length === 0) return "";
    return "This bar shares the " + barConfig.position + " edge with the dock on " + screens.join(", ") + ". The dock will stay hidden on those displays.";
  }

  function dockConflictsOnScreen(screen, positionOverride) {
    if (!dockEnabled || !screen) return false;
    var edge = isValidEdge(positionOverride) ? positionOverride : dockPosition;
    var bars = barConfigs || [];
    for (var i = 0; i < bars.length; ++i) {
      var barConfig = bars[i];
      if (!barConfig.enabled) continue;
      if (barConfig.position !== edge) continue;
      if (barEnabledOnScreen(barConfig, screen)) return true;
    }
    return false;
  }

  function dockHasConflict() {
    if (!dockEnabled) return false;
    var screens = allScreens();
    for (var i = 0; i < screens.length; ++i) {
      if (dockConflictsOnScreen(screens[i])) return true;
    }
    return false;
  }

  function canUseDockPosition(position) {
    return isValidEdge(position);
  }

  function setDockPosition(position) {
    if (!isValidEdge(position)) return false;
    dockPosition = position;
    return true;
  }

  function reservedEdgesForScreen(screen, excludeBarId) {
    var reserved = {
      top: overlayInset,
      right: overlayInset,
      bottom: overlayInset,
      left: overlayInset
    };

    var bars = barConfigs || [];
    for (var i = 0; i < bars.length; ++i) {
      var barConfig = bars[i];
      if (!barConfig.enabled || barConfig.id === excludeBarId) continue;
      if (!barEnabledOnScreen(barConfig, screen)) continue;
      reserved[barConfig.position] += barThickness(barConfig) + floatingInset(barConfig) + popupGap;
    }

    if (dockEnabled && !dockConflictsOnScreen(screen))
      reserved[dockPosition] += dockIconSize + 32;

    return reserved;
  }

  function notificationMargins(screen) {
    var reserved = reservedEdgesForScreen(screen, "");
    return {
      top: reserved.top,
      right: reserved.right,
      bottom: reserved.bottom,
      left: reserved.left
    };
  }

  function compatibleLegacyBar() {
    return selectedBar() || (barConfigs.length > 0 ? barConfigs[0] : null);
  }

  function syncLegacyBarSettingsFromPrimary() {
    var primaryBar = compatibleLegacyBar();
    if (!primaryBar) return;

    _syncingLegacyBarSettings = true;
    barHeight = primaryBar.height;
    barFloating = primaryBar.floating;
    barMargin = primaryBar.margin;
    barOpacity = primaryBar.opacity;
    _syncingLegacyBarSettings = false;
  }

  function applyLegacyBarSetting(key, value) {
    if (_syncingLegacyBarSettings) return;
    var primaryBar = compatibleLegacyBar();
    if (!primaryBar) return;

    var patch = {};
    patch[key] = value;
    updateBarConfig(primaryBar.id, patch);
  }

  property Timer saveTimer: Timer {
    interval: 500
    onTriggered: root.save()
  }

  function scheduleSave() {
    if (!_loading) saveTimer.restart();
  }

  onBarHeightChanged: { applyLegacyBarSetting("height", barHeight); scheduleSave(); }
  onBarFloatingChanged: { applyLegacyBarSetting("floating", barFloating); scheduleSave(); }
  onBarMarginChanged: { applyLegacyBarSetting("margin", barMargin); scheduleSave(); }
  onBarOpacityChanged: { applyLegacyBarSetting("opacity", barOpacity); scheduleSave(); }
  onBarConfigsChanged: { ensureSelectedBar(); syncLegacyBarSettingsFromPrimary(); scheduleSave(); }
  onSelectedBarIdChanged: scheduleSave()
  onBlurEnabledChanged: scheduleSave()
  onGlassOpacityChanged: scheduleSave()
  onNotifWidthChanged: scheduleSave()
  onPopupTimerChanged: scheduleSave()
  onTimeUse24HourChanged: scheduleSave()
  onTimeShowSecondsChanged: scheduleSave()
  onTimeShowBarDateChanged: scheduleSave()
  onTimeBarDateStyleChanged: scheduleSave()
  onWeatherUnitsChanged: scheduleSave()
  onWeatherAutoLocationChanged: scheduleSave()
  onWeatherCityQueryChanged: scheduleSave()
  onWeatherLatitudeChanged: scheduleSave()
  onWeatherLongitudeChanged: scheduleSave()
  onWeatherLocationPriorityChanged: scheduleSave()
  onLauncherDefaultModeChanged: scheduleSave()
  onLauncherShowModeHintsChanged: scheduleSave()
  onLauncherShowHomeSectionsChanged: scheduleSave()
  onLauncherEnablePreloadChanged: scheduleSave()
  onLauncherKeepSearchOnModeSwitchChanged: scheduleSave()
  onLauncherEnableDebugTimingsChanged: scheduleSave()
  onLauncherShowRuntimeMetricsChanged: scheduleSave()
  onLauncherPreloadFailureThresholdChanged: scheduleSave()
  onLauncherPreloadFailureBackoffSecChanged: scheduleSave()
  onLauncherMaxResultsChanged: scheduleSave()
  onLauncherFileMinQueryLengthChanged: scheduleSave()
  onLauncherFileMaxResultsChanged: scheduleSave()
  onLauncherRecentsLimitChanged: scheduleSave()
  onLauncherRecentAppsLimitChanged: scheduleSave()
  onLauncherSuggestionsLimitChanged: scheduleSave()
  onLauncherCacheTtlSecChanged: scheduleSave()
  onLauncherSearchDebounceMsChanged: scheduleSave()
  onLauncherFileSearchDebounceMsChanged: scheduleSave()
  onLauncherWebEnterUsesPrimaryChanged: scheduleSave()
  onLauncherWebNumberHotkeysEnabledChanged: scheduleSave()
  onLauncherWebAliasesChanged: scheduleSave()
  onLauncherRememberWebProviderChanged: scheduleSave()
  onLauncherWebLastProviderKeyChanged: scheduleSave()
  onLauncherWebProviderOrderChanged: scheduleSave()
  onLauncherModeOrderChanged: scheduleSave()
  onLauncherEnabledModesChanged: scheduleSave()
  onLauncherScoreNameWeightChanged: scheduleSave()
  onLauncherScoreTitleWeightChanged: scheduleSave()
  onLauncherScoreExecWeightChanged: scheduleSave()
  onLauncherScoreBodyWeightChanged: scheduleSave()
  onControlCenterWidthChanged: scheduleSave()
  onControlCenterShowQuickLinksChanged: scheduleSave()
  onControlCenterShowMediaWidgetChanged: scheduleSave()
  onOsdDurationChanged: scheduleSave()
  onOsdSizeChanged: scheduleSave()
  onOsdPositionChanged: scheduleSave()
  onOsdStyleChanged: scheduleSave()
  onOsdOverdriveChanged: scheduleSave()
  onDockEnabledChanged: scheduleSave()
  onDockAutoHideChanged: scheduleSave()
  onDockPinnedAppsChanged: scheduleSave()
  onDockPositionChanged: scheduleSave()
  onDockGroupAppsChanged: scheduleSave()
  onDockIconSizeChanged: scheduleSave()
  onDesktopWidgetsEnabledChanged: scheduleSave()
  onDesktopWidgetsGridSnapChanged: scheduleSave()
  onDesktopWidgetsMonitorWidgetsChanged: scheduleSave()
  onShowScreenBordersChanged: scheduleSave()
  onPowermenuCountdownChanged: scheduleSave()
  onLockScreenCompactChanged: scheduleSave()
  onLockScreenMediaControlsChanged: scheduleSave()
  onLockScreenWeatherChanged: scheduleSave()
  onLockScreenSessionButtonsChanged: scheduleSave()
  onLockScreenCountdownChanged: scheduleSave()
  onPrivacyIndicatorsEnabledChanged: scheduleSave()
  onPrivacyCameraMonitoringChanged: scheduleSave()
  onIdleInhibitEnabledChanged: scheduleSave()
  onRecentPickerColorsChanged: scheduleSave()
  onThemeNameChanged: scheduleSave()
  onDisabledPluginsChanged: scheduleSave()
  onWallpaperRunPywalChanged: scheduleSave()
  onWallpaperPathsChanged: scheduleSave()
  onWallpaperCycleIntervalChanged: scheduleSave()
  onWallpaperDefaultFolderChanged: scheduleSave()
  onWallpaperSolidColorChanged: scheduleSave()
  onWallpaperUseSolidOnStartupChanged: scheduleSave()
  onWallpaperSolidColorsByMonitorChanged: scheduleSave()
  onWallpaperRecentSolidColorsChanged: scheduleSave()

  function load() {
    var raw = configFile.text();
    if (!raw) {
      barConfigs = normalizeBarConfigs([], {});
      ensureSelectedBar();
      syncLegacyBarSettingsFromPrimary();
      return;
    }

    _loading = true;

    try {
      var data = JSON.parse(raw);

      if (data.bar) {
        if (data.bar.height !== undefined) barHeight = data.bar.height;
        if (data.bar.floating !== undefined) barFloating = data.bar.floating;
        if (data.bar.margin !== undefined) barMargin = data.bar.margin;
        if (data.bar.opacity !== undefined) barOpacity = data.bar.opacity;
      }

      if (data.bars) {
        if (data.bars.configs !== undefined) barConfigs = normalizeBarConfigs(data.bars.configs, data);
        if (data.bars.selectedBarId !== undefined) selectedBarId = data.bars.selectedBarId;
      } else {
        barConfigs = normalizeBarConfigs([], data);
      }

      if (data.glass) {
        if (data.glass.blur !== undefined) blurEnabled = data.glass.blur;
        if (data.glass.opacity !== undefined) glassOpacity = data.glass.opacity;
      }

      if (data.notifications) {
        if (data.notifications.width !== undefined) notifWidth = data.notifications.width;
        if (data.notifications.popupTimer !== undefined) popupTimer = data.notifications.popupTimer;
      }

      if (data.time) {
        if (data.time.use24Hour !== undefined) timeUse24Hour = data.time.use24Hour;
        if (data.time.showSeconds !== undefined) timeShowSeconds = data.time.showSeconds;
        if (data.time.showBarDate !== undefined) timeShowBarDate = data.time.showBarDate;
        if (data.time.barDateStyle !== undefined) timeBarDateStyle = data.time.barDateStyle;
      }

      if (data.weather) {
        if (data.weather.units !== undefined) weatherUnits = data.weather.units;
        if (data.weather.autoLocation !== undefined) weatherAutoLocation = data.weather.autoLocation;
        if (data.weather.cityQuery !== undefined) weatherCityQuery = data.weather.cityQuery;
        if (data.weather.latitude !== undefined) weatherLatitude = String(data.weather.latitude);
        if (data.weather.longitude !== undefined) weatherLongitude = String(data.weather.longitude);
        if (data.weather.locationPriority !== undefined) weatherLocationPriority = data.weather.locationPriority;
      }

      if (data.launcher)
        normalizeLauncherConfig(data);

      if (data.controlCenter) {
        if (data.controlCenter.width !== undefined) controlCenterWidth = data.controlCenter.width;
        if (data.controlCenter.showQuickLinks !== undefined) controlCenterShowQuickLinks = data.controlCenter.showQuickLinks;
        if (data.controlCenter.showMediaWidget !== undefined) controlCenterShowMediaWidget = data.controlCenter.showMediaWidget;
      }

      if (data.osd) {
        if (data.osd.duration !== undefined) osdDuration = data.osd.duration;
        if (data.osd.size !== undefined) osdSize = data.osd.size;
        if (data.osd.position !== undefined) osdPosition = data.osd.position;
        if (data.osd.style !== undefined) osdStyle = data.osd.style;
        if (data.osd.overdrive !== undefined) osdOverdrive = data.osd.overdrive;
      }

      if (data.dock) {
        if (data.dock.enabled !== undefined) dockEnabled = data.dock.enabled;
        if (data.dock.autoHide !== undefined) dockAutoHide = data.dock.autoHide;
        if (data.dock.pinnedApps !== undefined) dockPinnedApps = data.dock.pinnedApps;
        if (data.dock.position !== undefined) dockPosition = data.dock.position;
        if (data.dock.groupApps !== undefined) dockGroupApps = data.dock.groupApps;
        if (data.dock.iconSize !== undefined) dockIconSize = data.dock.iconSize;
      }

      if (data.desktopWidgets) {
        if (data.desktopWidgets.enabled !== undefined) desktopWidgetsEnabled = data.desktopWidgets.enabled;
        if (data.desktopWidgets.gridSnap !== undefined) desktopWidgetsGridSnap = data.desktopWidgets.gridSnap;
        if (data.desktopWidgets.monitorWidgets !== undefined) desktopWidgetsMonitorWidgets = data.desktopWidgets.monitorWidgets;
      }

      if (data.screenBorders) {
        if (data.screenBorders.show !== undefined) showScreenBorders = data.screenBorders.show;
      }

      if (data.powerMenu) {
        if (data.powerMenu.countdown !== undefined) powermenuCountdown = data.powerMenu.countdown;
      }

      if (data.lockScreen) {
        if (data.lockScreen.compact !== undefined) lockScreenCompact = data.lockScreen.compact;
        if (data.lockScreen.mediaControls !== undefined) lockScreenMediaControls = data.lockScreen.mediaControls;
        if (data.lockScreen.weather !== undefined) lockScreenWeather = data.lockScreen.weather;
        if (data.lockScreen.sessionButtons !== undefined) lockScreenSessionButtons = data.lockScreen.sessionButtons;
        if (data.lockScreen.countdown !== undefined) lockScreenCountdown = data.lockScreen.countdown;
      }

      if (data.privacy) {
        if (data.privacy.indicatorsEnabled !== undefined) privacyIndicatorsEnabled = data.privacy.indicatorsEnabled;
        if (data.privacy.cameraMonitoring !== undefined) privacyCameraMonitoring = data.privacy.cameraMonitoring;
      }

      if (data.power) {
        if (data.power.idleInhibit !== undefined) idleInhibitEnabled = data.power.idleInhibit;
      }

      if (data.colorPicker) {
        if (data.colorPicker.recentColors !== undefined) recentPickerColors = data.colorPicker.recentColors;
      }

      if (data.plugins) {
        if (data.plugins.disabled !== undefined) disabledPlugins = data.plugins.disabled;
      }

      if (data.theme) {
        if (data.theme.name !== undefined) themeName = data.theme.name;
      }

      if (data.wallpaper) {
        if (data.wallpaper.runPywal !== undefined) wallpaperRunPywal = data.wallpaper.runPywal;
        if (data.wallpaper.paths !== undefined) wallpaperPaths = data.wallpaper.paths;
        if (data.wallpaper.cycleInterval !== undefined) wallpaperCycleInterval = data.wallpaper.cycleInterval;
        if (data.wallpaper.defaultFolder !== undefined) wallpaperDefaultFolder = data.wallpaper.defaultFolder;
        if (data.wallpaper.solidColor !== undefined) wallpaperSolidColor = data.wallpaper.solidColor;
        if (data.wallpaper.useSolidOnStartup !== undefined) wallpaperUseSolidOnStartup = data.wallpaper.useSolidOnStartup;
        if (data.wallpaper.solidColorsByMonitor !== undefined) wallpaperSolidColorsByMonitor = data.wallpaper.solidColorsByMonitor;
        if (data.wallpaper.recentSolidColors !== undefined) wallpaperRecentSolidColors = data.wallpaper.recentSolidColors;
      }
    } catch (e) {
      console.error("Failed to load config: " + e);
      barConfigs = normalizeBarConfigs([], {});
    }

    ensureSelectedBar();
    syncLegacyBarSettingsFromPrimary();
    _loading = false;
    applyRuntimeSettings();
  }

  property FileView configFile: FileView {
    path: root.configPath
    blockLoading: true
    printErrors: false
    onLoaded: root.load()
    onLoadFailed: (error) => {
      if (error === 2) {
        root.barConfigs = root.normalizeBarConfigs([], {});
        root.ensureSelectedBar();
        root.syncLegacyBarSettingsFromPrimary();
        root.save();
        return;
      }
      console.error("Failed to load config file: " + error);
    }
    onSaveFailed: (error) => console.error("Failed to save config file: " + error)
  }

  function save() {
    var data = {
      "bar": {
        "height": barHeight,
        "floating": barFloating,
        "margin": barMargin,
        "opacity": barOpacity
      },
      "bars": {
        "selectedBarId": selectedBarId,
        "configs": barConfigs
      },
      "glass": {
        "blur": blurEnabled,
        "opacity": glassOpacity
      },
      "notifications": {
        "width": notifWidth,
        "popupTimer": popupTimer
      },
      "time": {
        "use24Hour": timeUse24Hour,
        "showSeconds": timeShowSeconds,
        "showBarDate": timeShowBarDate,
        "barDateStyle": timeBarDateStyle
      },
      "weather": {
        "units": weatherUnits,
        "autoLocation": weatherAutoLocation,
        "cityQuery": weatherCityQuery,
        "latitude": weatherLatitude,
        "longitude": weatherLongitude,
        "locationPriority": weatherLocationPriority
      },
      "launcher": {
        "defaultMode": launcherDefaultMode,
        "showModeHints": launcherShowModeHints,
        "showHomeSections": launcherShowHomeSections,
        "enablePreload": launcherEnablePreload,
        "keepSearchOnModeSwitch": launcherKeepSearchOnModeSwitch,
        "enableDebugTimings": launcherEnableDebugTimings,
        "showRuntimeMetrics": launcherShowRuntimeMetrics,
        "preloadFailureThreshold": launcherPreloadFailureThreshold,
        "preloadFailureBackoffSec": launcherPreloadFailureBackoffSec,
        "maxResults": launcherMaxResults,
        "fileMinQueryLength": launcherFileMinQueryLength,
        "fileMaxResults": launcherFileMaxResults,
        "recentsLimit": launcherRecentsLimit,
        "recentAppsLimit": launcherRecentAppsLimit,
        "suggestionsLimit": launcherSuggestionsLimit,
        "cacheTtlSec": launcherCacheTtlSec,
        "searchDebounceMs": launcherSearchDebounceMs,
        "fileSearchDebounceMs": launcherFileSearchDebounceMs,
        "webEnterUsesPrimary": launcherWebEnterUsesPrimary,
        "webNumberHotkeysEnabled": launcherWebNumberHotkeysEnabled,
        "webAliases": launcherWebAliases,
        "rememberWebProvider": launcherRememberWebProvider,
        "webLastProviderKey": launcherWebLastProviderKey,
        "webProviderOrder": launcherWebProviderOrder,
        "modeOrder": launcherModeOrder,
        "enabledModes": launcherEnabledModes,
        "scoreNameWeight": launcherScoreNameWeight,
        "scoreTitleWeight": launcherScoreTitleWeight,
        "scoreExecWeight": launcherScoreExecWeight,
        "scoreBodyWeight": launcherScoreBodyWeight
      },
      "controlCenter": {
        "width": controlCenterWidth,
        "showQuickLinks": controlCenterShowQuickLinks,
        "showMediaWidget": controlCenterShowMediaWidget
      },
      "osd": {
        "duration": osdDuration,
        "size": osdSize,
        "position": osdPosition,
        "style": osdStyle,
        "overdrive": osdOverdrive
      },
      "dock": {
        "enabled": dockEnabled,
        "autoHide": dockAutoHide,
        "pinnedApps": dockPinnedApps,
        "position": dockPosition,
        "groupApps": dockGroupApps,
        "iconSize": dockIconSize
      },
      "desktopWidgets": {
        "enabled": desktopWidgetsEnabled,
        "gridSnap": desktopWidgetsGridSnap,
        "monitorWidgets": desktopWidgetsMonitorWidgets
      },
      "screenBorders": {
        "show": showScreenBorders
      },
      "powerMenu": {
        "countdown": powermenuCountdown
      },
      "lockScreen": {
        "compact": lockScreenCompact,
        "mediaControls": lockScreenMediaControls,
        "weather": lockScreenWeather,
        "sessionButtons": lockScreenSessionButtons,
        "countdown": lockScreenCountdown
      },
      "privacy": {
        "indicatorsEnabled": privacyIndicatorsEnabled,
        "cameraMonitoring": privacyCameraMonitoring
      },
      "power": {
        "idleInhibit": idleInhibitEnabled
      },
      "colorPicker": {
        "recentColors": recentPickerColors
      },
      "plugins": {
        "disabled": disabledPlugins
      },
      "theme": {
        "name": themeName
      },
      "wallpaper": {
        "runPywal": wallpaperRunPywal,
        "paths": wallpaperPaths,
        "cycleInterval": wallpaperCycleInterval,
        "defaultFolder": wallpaperDefaultFolder,
        "solidColor": wallpaperSolidColor,
        "useSolidOnStartup": wallpaperUseSolidOnStartup,
        "solidColorsByMonitor": wallpaperSolidColorsByMonitor,
        "recentSolidColors": wallpaperRecentSolidColors
      }
    };

    configFile.setText(JSON.stringify(data, null, 2));
    applyRuntimeSettings();
  }
}
