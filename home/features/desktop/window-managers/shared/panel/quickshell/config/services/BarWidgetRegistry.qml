pragma Singleton

import QtQuick
import "."

QtObject {
  id: root

  readonly property var builtins: [
    { widgetType: "logo", label: "App Launcher", icon: "󰀻", section: "left", description: "Application launcher trigger." },
    { widgetType: "workspaces", label: "Workspace Switcher", icon: "󰍺", section: "left", description: "Current workspaces and switching.", hasSettings: true, defaultSettings: { showAddButton: true, showMiniMap: true } },
    { widgetType: "windowTitle", label: "Active App Context", icon: "󰖯", section: "left", description: "Active window title and app-specific tools.", hasSettings: true, defaultSettings: { maxTitleWidth: 300, showAppIcon: true, showGitStatus: true, showMediaContext: true } },
    { widgetType: "keyboardLayout", label: "Keyboard Layout", icon: "󰌌", section: "right", description: "Current keyboard layout indicator.", hasSettings: true, defaultSettings: { labelMode: "short" } },
    { widgetType: "taskbar", label: "Running Apps", icon: "󰣆", section: "left", description: "Focused and running applications.", hasSettings: true, defaultSettings: { buttonSize: 32, iconSize: 20, showRunningIndicator: true, showSeparator: true, maxUnpinned: 0 } },
    { widgetType: "cpuStatus", label: "CPU", icon: "", section: "left", description: "CPU usage with system stats popup.", hasSettings: true, defaultSettings: { displayMode: "auto", valueStyle: "percent" } },
    { widgetType: "ramStatus", label: "Memory", icon: "", section: "left", description: "Memory usage with system stats popup.", hasSettings: true, defaultSettings: { displayMode: "auto", valueStyle: "usage" } },
    { widgetType: "gpuStatus", label: "GPU", icon: "󰢮", section: "left", description: "GPU usage with system stats popup.", hasSettings: true, defaultSettings: { displayMode: "auto", valueStyle: "percent" } },
    { widgetType: "dateTime", label: "Clock", icon: "󰥔", section: "center", description: "Current time and date popup.", hasSettings: true, defaultSettings: { displayMode: "auto", showDate: true } },
    { widgetType: "mediaBar", label: "Media Controls", icon: "󰎆", section: "center", description: "Current media playback widget.", hasSettings: true, defaultSettings: { displayMode: "auto", maxTextWidth: 150 } },
    { widgetType: "updates", label: "Updates", icon: "󰚰", section: "center", description: "Pending system updates.", hasSettings: true, defaultSettings: { displayMode: "auto" } },
    { widgetType: "cava", label: "Visualizer", icon: "󰎈", section: "center", description: "Compact audio spectrum with popup.", hasSettings: true, defaultSettings: { barCount: 8 } },
    { widgetType: "idleInhibitor", label: "Idle Inhibitor", icon: "󰒲", section: "center", description: "Toggle idle inhibit state." },
    { widgetType: "weather", label: "Weather", icon: "󰖙", section: "right", description: "Current weather and forecast popup.", hasSettings: true, defaultSettings: { displayMode: "auto" } },
    {
      widgetType: "ssh",
      label: "SSH",
      icon: "󰣀",
      section: "right",
      description: "SSH hosts with manual entries and ~/.ssh/config import.",
      hasSettings: true,
      defaultSettings: {
        manualHosts: [],
        enableSshConfigImport: true,
        displayMode: "count",
        defaultAction: "connect",
        state: {
          lastConnectedId: "",
          lastConnectedLabel: "",
          lastConnectedAt: "",
          recentIds: []
        }
      }
    },
    { widgetType: "network", label: "Network", icon: "󰖩", section: "right", description: "Network state and controls popup.", hasSettings: true, defaultSettings: { displayMode: "auto" } },
    { widgetType: "bluetooth", label: "Bluetooth", icon: "󰂯", section: "right", description: "Bluetooth status and controls popup.", hasSettings: true, defaultSettings: { displayMode: "auto" } },
    { widgetType: "audio", label: "Audio", icon: "󰕾", section: "right", description: "Volume and device controls popup.", hasSettings: true, defaultSettings: { displayMode: "auto" } },
    { widgetType: "music", label: "Music", icon: "󰝚", section: "right", description: "Compact active player shortcut.", hasSettings: true, defaultSettings: { displayMode: "auto", maxTextWidth: 100 } },
    { widgetType: "privacy", label: "Privacy", icon: "󰒃", section: "right", description: "Camera, mic, and share indicators.", hasSettings: true, defaultSettings: { displayMode: "auto", showPulseDot: true } },
    { widgetType: "recording", label: "Recording", icon: "󰻃", section: "right", description: "Active screen recording indicator.", hasSettings: true, defaultSettings: { displayMode: "auto", showPulseDot: true } },
    { widgetType: "battery", label: "Battery", icon: "󰁹", section: "right", description: "Battery status and actions popup.", hasSettings: true, defaultSettings: { displayMode: "auto" } },
    { widgetType: "printer", label: "Printers", icon: "󰐪", section: "right", description: "Printer status popup.", hasSettings: true, defaultSettings: { displayMode: "auto", badgeStyle: "count" } },
    { widgetType: "aiChat", label: "AI Chat", icon: "󰚩", section: "right", description: "AI chat assistant toggle." },
    { widgetType: "notepad", label: "Notepad", icon: "󰠮", section: "right", description: "Slideout notepad trigger." },
    { widgetType: "controlCenter", label: "Control Center", icon: "󰒓", section: "right", description: "Command center trigger." },
    { widgetType: "tray", label: "System Tray", icon: "󰀻", section: "right", description: "Status notifier tray.", hasSettings: true, defaultSettings: { itemSize: 24, iconSize: 18, spacing: 6 } },
    { widgetType: "clipboard", label: "Clipboard", icon: "󰅍", section: "right", description: "Clipboard history popup." },
    { widgetType: "screenshot", label: "Screenshot", icon: "󰩭", section: "right", description: "Screenshot capture popup." },
    { widgetType: "notifications", label: "Notifications", icon: "󰂚", section: "right", description: "Notification center trigger.", hasSettings: true, defaultSettings: { displayMode: "auto", badgeStyle: "dot" } },
    { widgetType: "spacer", label: "Spacer", icon: "󰉺", section: "center", description: "Adjustable empty spacing.", hasSettings: true, defaultSettings: { size: 24 } },
    { widgetType: "separator", label: "Separator", icon: "󰇘", section: "center", description: "Thin divider between widgets.", hasSettings: true, defaultSettings: { thickness: 1, length: 20, opacity: 0.8 } }
  ]

  readonly property var pluginWidgets: {
    var items = [];
    var plugins = PluginService.barPlugins || [];
    for (var i = 0; i < plugins.length; ++i) {
      var plugin = plugins[i];
      items.push({
        widgetType: "plugin:" + plugin.id,
        label: plugin.name || plugin.id,
        icon: "󰏗",
        section: "right",
        description: plugin.description || "Bar plugin widget.",
        hasSettings: !!(plugin.entryPoints && plugin.entryPoints.settings),
        pluginId: plugin.id,
        path: plugin.path || "",
        entryFile: (plugin.entryPoints && plugin.entryPoints.barWidget) ? plugin.entryPoints.barWidget : ""
      });
    }
    return items;
  }

  readonly property var widgets: builtins.concat(pluginWidgets)

  function allWidgets() {
    return widgets.slice();
  }

  function metadataFor(widgetType) {
    var items = widgets;
    for (var i = 0; i < items.length; ++i) {
      if (items[i].widgetType === widgetType) return items[i];
    }

    if (String(widgetType || "").indexOf("plugin:") === 0) {
      var pluginId = String(widgetType).slice(7);
      var plugins = PluginService.barPlugins || [];
      for (var j = 0; j < plugins.length; ++j) {
        if (plugins[j].id === pluginId) {
          return {
            widgetType: widgetType,
            label: plugins[j].name || pluginId,
            icon: "󰏗",
            section: "right",
            description: plugins[j].description || "Bar plugin widget.",
            hasSettings: !!(plugins[j].entryPoints && plugins[j].entryPoints.settings),
            pluginId: pluginId,
            path: plugins[j].path || "",
            entryFile: (plugins[j].entryPoints && plugins[j].entryPoints.barWidget) ? plugins[j].entryPoints.barWidget : ""
          };
        }
      }
    }

    return null;
  }

  function displayName(widgetType) {
    var meta = metadataFor(widgetType);
    return meta ? meta.label : String(widgetType || "Unknown Widget");
  }

  function displayIcon(widgetType) {
    var meta = metadataFor(widgetType);
    return meta ? meta.icon : "󰖲";
  }

  function defaultSection(widgetType) {
    var meta = metadataFor(widgetType);
    return meta && meta.section ? meta.section : "right";
  }

  function description(widgetType) {
    var meta = metadataFor(widgetType);
    return meta ? (meta.description || "") : "";
  }

  function supportsSettings(widgetType) {
    var meta = metadataFor(widgetType);
    return !!(meta && meta.hasSettings);
  }

  function defaultSettings(widgetType) {
    var meta = metadataFor(widgetType);
    return meta && meta.defaultSettings ? JSON.parse(JSON.stringify(meta.defaultSettings)) : {};
  }

  function pluginByWidgetType(widgetType) {
    if (String(widgetType || "").indexOf("plugin:") !== 0) return null;
    var pluginId = String(widgetType).slice(7);
    var plugins = PluginService.barPlugins || [];
    for (var i = 0; i < plugins.length; ++i) {
      if (plugins[i].id === pluginId) return plugins[i];
    }
    return null;
  }

  function search(query, preferredSection) {
    var q = String(query || "").trim().toLowerCase();
    var items = widgets.slice();
    if (!q && !preferredSection) return items;

    var results = [];
    for (var i = 0; i < items.length; ++i) {
      var item = items[i];
      if (preferredSection && item.section !== preferredSection && item.section !== "center") {
        if (preferredSection !== "center") continue;
      }
      var haystack = (item.label + " " + (item.description || "") + " " + item.widgetType).toLowerCase();
      if (!q || haystack.indexOf(q) !== -1) results.push(item);
    }
    return results;
  }
}
