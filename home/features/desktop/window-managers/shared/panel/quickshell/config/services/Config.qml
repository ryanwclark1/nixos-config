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

  // Internal Logic to Load
  readonly property string configPath: Quickshell.statePath("config.json")

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
    if (configFile.path === "") return;
    var raw = configFile.text();
    if (!raw) return;

    try {
      var data = JSON.parse(raw);
      if (data.bar) {
        barHeight = data.bar.height || barHeight;
        barFloating = data.bar.floating !== undefined ? data.bar.floating : barFloating;
        barMargin = data.bar.margin !== undefined ? data.bar.margin : barMargin;
        barOpacity = data.bar.opacity || barOpacity;
      }
      if (data.glass) {
        blurEnabled = data.glass.blur !== undefined ? data.glass.blur : blurEnabled;
        glassOpacity = data.glass.opacity || glassOpacity;
      }
      if (data.notifications) {
        notifWidth = data.notifications.width || notifWidth;
        popupTimer = data.notifications.popupTimer || popupTimer;
      }
    } catch (e) {
      console.error("Failed to load config: " + e);
    }

    applyRuntimeSettings();
  }

  property FileView configFile: FileView {
    path: ""
    blockLoading: true
    watchChanges: true
    onLoaded: root.load()
    onFileChanged: reload()
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
    if (configFile.path === "") configFile.path = root.configPath;
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
      }
    };

    configFile.setText(JSON.stringify(data, null, 2));
    applyRuntimeSettings();
  }

  Component.onCompleted: {
    Quickshell.execDetached(["sh", "-c", "mkdir -p $(dirname " + configPath + ") && touch " + configPath]);
    configFile.path = root.configPath;
    configFile.reload();
  }
}
