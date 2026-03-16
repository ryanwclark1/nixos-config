import Quickshell
import QtQuick
import "./config/services"
import "./config/bar"

Scope {
  Panel {
    id: panel
    barConfig: {
      return {
        position: "top",
        sectionWidgets: { left: [], center: [], right: [] }
      };
    }
    Component.onCompleted: {
      console.log("RESULT:" + JSON.stringify({
        weatherDefaults: BarWidgetRegistry.defaultSettings("weather"),
        networkDefaults: BarWidgetRegistry.defaultSettings("network"),
        audioDefaults: BarWidgetRegistry.defaultSettings("audio"),
        batteryDefaults: BarWidgetRegistry.defaultSettings("battery"),
        autoHorizontalIcon: panel.isSummaryWidgetIconOnly({ settings: { displayMode: "auto" } }),
        iconHorizontalIcon: panel.isSummaryWidgetIconOnly({ settings: { displayMode: "icon" } }),
        fullHorizontalFull: panel.isSummaryWidgetFull({ settings: { displayMode: "full" } })
      }));
      Qt.quit();
    }
  }
}
