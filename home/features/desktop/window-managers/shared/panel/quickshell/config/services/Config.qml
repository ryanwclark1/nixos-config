import QtQuick
import Quickshell.Io

pragma Singleton

QtObject {
  id: root

  // --- BAR ---
  property int barHeight: 30
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
  readonly property string configPath: Quickshell.configPath("services/config.json")

  function load() {
    var file = Quickshell.openFile(configPath, File.ReadOnly);
    if (file) {
      try {
        var data = JSON.parse(file.readAll());
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
      } catch(e) { console.error("Failed to load config: " + e); }
      file.close();
    }
  }

  property FileView configWatcher: FileView {
    path: root.configPath
    watchChanges: true
    onTextChanged: root.load()
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
      }
    };
    
    var file = Quickshell.openFile(configPath, File.WriteOnly | File.Truncate);
    if (file) {
      file.write(JSON.stringify(data, null, 2));
      file.close();
    }
  }

  // Watch for changes
  Component.onCompleted: load()
}
