import QtQuick
import Quickshell
import Quickshell.Io

pragma Singleton

QtObject {
  id: root

  // --- BAR ---
  property int barHeight: 38
  property bool barFloating: true
  property int barMargin: 12
  property real barOpacity: 0.85

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
  property var wallpaperPaths: ({})      // monitorName → absolute image path
  property int wallpaperCycleInterval: 0  // 0 = disabled, otherwise minutes between auto-cycle
  property string wallpaperDefaultFolder: (Quickshell.env("HOME") || "/home") + "/Pictures"

  // --- THEME ---
  property string themeName: ""  // base24 theme id; empty = pywal fallback

  // --- PLUGINS ---
  property var disabledPlugins: []

  // --- INTERNAL ---
  property bool _loading: false

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
    if (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") !== "") {
      Quickshell.execDetached([
        "hyprctl",
        "keyword",
        "decoration:blur:enabled",
        blurEnabled ? "true" : "false"
      ]);
    }
  }

  // Debounced save: batches rapid property changes into a single disk write
  property Timer saveTimer: Timer {
    interval: 500
    onTriggered: root.save()
  }

  function scheduleSave() {
    if (!_loading) saveTimer.restart();
  }

  // Wire all user-facing properties to scheduleSave
  onBarHeightChanged: scheduleSave()
  onBarFloatingChanged: scheduleSave()
  onBarMarginChanged: scheduleSave()
  onBarOpacityChanged: scheduleSave()
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

  function load() {
    var raw = configFile.text();
    if (!raw) return;

    _loading = true;

    try {
      var data = JSON.parse(raw);

      if (data.bar) {
        if (data.bar.height !== undefined) barHeight = data.bar.height;
        if (data.bar.floating !== undefined) barFloating = data.bar.floating;
        if (data.bar.margin !== undefined) barMargin = data.bar.margin;
        if (data.bar.opacity !== undefined) barOpacity = data.bar.opacity;
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

      if (data.launcher) {
        if (data.launcher.defaultMode !== undefined) launcherDefaultMode = data.launcher.defaultMode;
        if (data.launcher.showModeHints !== undefined) launcherShowModeHints = data.launcher.showModeHints;
        if (data.launcher.showHomeSections !== undefined) launcherShowHomeSections = data.launcher.showHomeSections;
      }

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
      }
    } catch (e) {
      console.error("Failed to load config: " + e);
    }

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
        "showHomeSections": launcherShowHomeSections
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
        "defaultFolder": wallpaperDefaultFolder
      }
    };

    configFile.setText(JSON.stringify(data, null, 2));
    applyRuntimeSettings();
  }
}
