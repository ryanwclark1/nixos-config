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

  function load() {
    var raw = configFile.text();
    if (!raw) return;

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
      }
    } catch (e) {
      console.error("Failed to load config: " + e);
    }

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
        "size": osdSize
      }
    };

    configFile.setText(JSON.stringify(data, null, 2));
    applyRuntimeSettings();
  }
}
