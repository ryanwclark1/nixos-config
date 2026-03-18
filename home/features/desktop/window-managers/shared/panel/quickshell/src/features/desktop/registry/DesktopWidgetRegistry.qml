pragma Singleton
import QtQuick
import "../../../services" as Services

QtObject {
    id: root

    property bool editMode: false

    // Built-in widget catalog
    readonly property var builtInWidgetCatalog: [
        {
            id: "Clock",
            name: "Clock",
            icon: "󰥔",
            source: "builtin",
            componentSource: Qt.resolvedUrl("../components/DesktopClock.qml"),
            settingsSource: ""
        },
        {
            id: "SystemStat",
            name: "System Stats",
            icon: "",
            source: "builtin",
            componentSource: Qt.resolvedUrl("../components/DesktopSystemStat.qml"),
            settingsSource: ""
        },
        {
            id: "Weather",
            name: "Weather",
            icon: "󰖐",
            source: "builtin",
            componentSource: Qt.resolvedUrl("../components/DesktopWeather.qml"),
            settingsSource: ""
        }
    ]

    // Unified desktop widget catalog (built-ins + enabled desktop plugins)
    readonly property var widgetCatalog: {
        var result = builtInWidgetCatalog.slice();
        var plugins = Services.PluginService.desktopPlugins || [];
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

    function search(query) {
        var q = String(query || "").trim().toLowerCase();
        var items = widgetCatalog.slice();
        if (!q)
            return items;

        var results = [];
        for (var i = 0; i < items.length; i++) {
            var item = items[i];
            var haystack = (String(item.name || "") + " " + String(item.id || "") + " " + String(item.pluginId || "")).toLowerCase();
            if (haystack.indexOf(q) !== -1)
                results.push(item);
        }
        return results;
    }

    function pluginForWidgetType(widgetType) {
        if (!widgetType || widgetType.indexOf("plugin:") !== 0)
            return null;
        var pluginId = widgetType.slice("plugin:".length);
        var plugins = Services.PluginService.desktopPlugins || [];
        for (var i = 0; i < plugins.length; i++) {
            if (plugins[i].id === pluginId)
                return plugins[i];
        }
        return null;
    }

    function metadataForWidgetType(widgetType) {
        var items = widgetCatalog;
        for (var i = 0; i < items.length; i++) {
            if (items[i].id === widgetType)
                return items[i];
        }
        var plugin = pluginForWidgetType(widgetType);
        if (!plugin)
            return null;
        var desktopEntry = (plugin.entryPoints && plugin.entryPoints.desktopWidget) ? plugin.entryPoints.desktopWidget : "";
        var settingsEntry = (plugin.entryPoints && plugin.entryPoints.settings) ? plugin.entryPoints.settings : "";
        return {
            id: "plugin:" + plugin.id,
            name: plugin.name || plugin.id,
            icon: "󰖲",
            source: "plugin",
            pluginId: plugin.id,
            componentSource: (plugin.path || "") + desktopEntry,
            settingsSource: settingsEntry ? (plugin.path || "") + settingsEntry : ""
        };
    }

    function getWidgetsForScreen(screenName) {
        var monitors = Services.Config.desktopWidgetsMonitorWidgets || [];
        for (var i = 0; i < monitors.length; i++) {
            if (monitors[i].name === screenName)
                return monitors[i].widgets || [];
        }
        return [];
    }

    function updateWidgetData(screenName, widgetId, data) {
        var monitors = JSON.parse(JSON.stringify(Services.Config.desktopWidgetsMonitorWidgets || []));
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
        if (found)
            Services.Config.desktopWidgetsMonitorWidgets = monitors;
    }

    function addWidget(screenName, widgetType) {
        return addWidgetAt(screenName, widgetType, 100, 100);
    }

    function addWidgetAt(screenName, widgetType, x, y) {
        var monitors = JSON.parse(JSON.stringify(Services.Config.desktopWidgetsMonitorWidgets || []));
        var monitorIdx = -1;
        for (var i = 0; i < monitors.length; i++) {
            if (monitors[i].name === screenName) {
                monitorIdx = i;
                break;
            }
        }
        if (monitorIdx < 0) {
            monitors.push({
                name: screenName,
                widgets: []
            });
            monitorIdx = monitors.length - 1;
        }

        var id = widgetType + "_" + Date.now();
        monitors[monitorIdx].widgets.push({
            id: id,
            type: widgetType,
            x: Math.round(Number(x) || 100),
            y: Math.round(Number(y) || 100),
            scale: 1.0
        });

        Services.Config.desktopWidgetsMonitorWidgets = monitors;
        return id;
    }

    function removeWidget(screenName, widgetId) {
        var monitors = JSON.parse(JSON.stringify(Services.Config.desktopWidgetsMonitorWidgets || []));
        for (var i = 0; i < monitors.length; i++) {
            if (monitors[i].name === screenName) {
                monitors[i].widgets = (monitors[i].widgets || []).filter(function (w) {
                    return w.id !== widgetId;
                });
                break;
            }
        }
        Services.Config.desktopWidgetsMonitorWidgets = monitors;
    }
}
