import QtQuick
import Quickshell
import "."

pragma Singleton

QtObject {
  id: root

  property bool editMode: false

  // Built-in widget catalog
  readonly property var builtInWidgetCatalog: [
    { id: "Clock", name: "Clock", icon: "󰥔" },
    { id: "SystemStat", name: "System Stats", icon: "" },
    { id: "Weather", name: "Weather", icon: "󰖐" }
  ]

  // Unified desktop widget catalog (built-ins + enabled desktop plugins)
  readonly property var widgetCatalog: {
    var result = builtInWidgetCatalog.slice();
    var plugins = PluginService.desktopPlugins || [];
    for (var i = 0; i < plugins.length; i++) {
      var p = plugins[i];
      result.push({
        id: "plugin:" + p.id,
        name: p.name || p.id,
        icon: "󰖲",
        source: "plugin",
        pluginId: p.id
      });
    }
    return result;
  }

  function pluginForWidgetType(widgetType) {
    if (!widgetType || widgetType.indexOf("plugin:") !== 0) return null;
    var pluginId = widgetType.slice("plugin:".length);
    var plugins = PluginService.desktopPlugins || [];
    for (var i = 0; i < plugins.length; i++) {
      if (plugins[i].id === pluginId) return plugins[i];
    }
    return null;
  }

  function pluginSourceForWidgetType(widgetType) {
    var plugin = pluginForWidgetType(widgetType);
    if (!plugin) return "";
    return (plugin.path || "") + (plugin.mainFile || "");
  }

  function isBuiltInType(widgetType) {
    return widgetType === "Clock" || widgetType === "SystemStat" || widgetType === "Weather";
  }

  function getWidgetsForScreen(screenName) {
    var monitors = Config.desktopWidgetsMonitorWidgets || [];
    for (var i = 0; i < monitors.length; i++) {
      if (monitors[i].name === screenName) return monitors[i].widgets || [];
    }
    return [];
  }

  function updateWidgetData(screenName, widgetId, data) {
    var monitors = JSON.parse(JSON.stringify(Config.desktopWidgetsMonitorWidgets || []));
    var found = false;
    for (var i = 0; i < monitors.length; i++) {
      if (monitors[i].name === screenName) {
        var widgets = monitors[i].widgets || [];
        for (var j = 0; j < widgets.length; j++) {
          if (widgets[j].id === widgetId) {
            widgets[j] = Object.assign(widgets[j], data);
            found = true;
            break;
          }
        }
        monitors[i].widgets = widgets;
        break;
      }
    }
    if (found) Config.desktopWidgetsMonitorWidgets = monitors;
  }

  function addWidget(screenName, widgetType) {
    var monitors = JSON.parse(JSON.stringify(Config.desktopWidgetsMonitorWidgets || []));
    var monitorIdx = -1;
    for (var i = 0; i < monitors.length; i++) {
      if (monitors[i].name === screenName) { monitorIdx = i; break; }
    }
    if (monitorIdx < 0) {
      monitors.push({ name: screenName, widgets: [] });
      monitorIdx = monitors.length - 1;
    }

    var id = widgetType + "_" + Date.now();
    monitors[monitorIdx].widgets.push({
      id: id,
      type: widgetType,
      x: 100,
      y: 100,
      scale: 1.0
    });

    Config.desktopWidgetsMonitorWidgets = monitors;
    return id;
  }

  function removeWidget(screenName, widgetId) {
    var monitors = JSON.parse(JSON.stringify(Config.desktopWidgetsMonitorWidgets || []));
    for (var i = 0; i < monitors.length; i++) {
      if (monitors[i].name === screenName) {
        monitors[i].widgets = (monitors[i].widgets || []).filter(function(w) {
          return w.id !== widgetId;
        });
        break;
      }
    }
    Config.desktopWidgetsMonitorWidgets = monitors;
  }
}
