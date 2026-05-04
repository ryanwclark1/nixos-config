pragma Singleton

import QtQuick
import "../../../services" as Services
import "../../../bar/VerticalWidgetPolicy.js" as VerticalWidgetPolicy

QtObject {
  id: root

  readonly property var builtins: [
    { widgetType: "logo", label: "App Launcher", icon: "app-generic.svg", section: "left", description: "Application launcher trigger.", hasSettings: true, defaultSettings: { displayMode: "icon", labelText: "Apps" }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether this trigger stays icon-only or also shows a text label in the bar.", options: [ { value: "icon", label: "Icon" }, { value: "full", label: "Full" } ] },
      { type: "text", key: "labelText", label: "Label Text", icon: "rename.svg", placeholder: "Apps" }
    ] },
    { widgetType: "workspaces", label: "Workspace Switcher", icon: "desktop.svg", section: "left", description: "Current workspaces and switching.", hasSettings: true, defaultSettings: { showAddButton: true, showMiniMap: true, showEmpty: true, showNames: false, showAppIcons: false, showWindowCount: false, pillSize: "normal", style: "pill", layout: "horizontal", clickBehavior: "focus" }, settingsSchema: [
      { type: "toggle", key: "showAddButton", label: "Add Button", icon: "add.svg", enabledText: "Show the quick add-workspace button at the end of the strip.", disabledText: "Hide the add-workspace button from this widget instance." },
      { type: "toggle", key: "showMiniMap", label: "Mini-map", icon: "desktop.svg", enabledText: "Show live mini-map window previews inside workspace pills.", disabledText: "Hide mini-map previews and keep the pills text-only." },
      { type: "toggle", key: "showEmpty", label: "Show Empty", icon: "empty.svg", enabledText: "Show all workspaces including empty ones.", disabledText: "Hide empty workspaces from the strip." },
      { type: "toggle", key: "showNames", label: "Show Names", icon: "rename.svg", enabledText: "Show workspace names or custom labels.", disabledText: "Show only workspace numbers or icons." },
      { type: "toggle", key: "showAppIcons", label: "App Icons", icon: "app-generic.svg", enabledText: "Show application icons inside workspace pills.", disabledText: "Hide application icons." },
      { type: "toggle", key: "showWindowCount", label: "Window Count", icon: "board.svg", enabledText: "Show a badge with the number of windows in the workspace.", disabledText: "Hide the window count badge." },
      { type: "mode", key: "pillSize", label: "Pill Size", description: "Choose the size of the workspace pills.", options: [ { value: "compact", label: "Compact" }, { value: "normal", label: "Normal" }, { value: "large", label: "Large" } ] },
      { type: "mode", key: "style", label: "Visual Style", description: "Choose the visual style for workspaces.", options: [ { value: "pill", label: "Pill" }, { value: "strip", label: "Strip" }, { value: "dots", label: "Dots" }, { value: "icons", label: "Icons" } ] },
      { type: "mode", key: "layout", label: "Layout", description: "Choose the layout for the workspace selector.", options: [ { value: "horizontal", label: "Horizontal" }, { value: "vertical", label: "Vertical" }, { value: "grid", label: "Grid" } ] },
      { type: "mode", key: "clickBehavior", label: "Click Behavior", description: "Choose what happens when you click a workspace pill.", options: [ { value: "focus", label: "Focus Workspace" }, { value: "last_window", label: "Last Active Window" } ] }
    ] },
    { widgetType: "specialWorkspaces", label: "Special Workspaces", icon: "star.svg", section: "left", description: "Hyprland special workspace indicator and toggle (scratchpads).", hasSettings: true, defaultSettings: { mainIcon: "app-generic.svg", showLabels: false }, settingsSchema: [
      { type: "text", key: "mainIcon", label: "Main Icon", icon: "app-generic.svg", placeholder: "app-generic.svg" },
      { type: "toggle", key: "showLabels", label: "Show Labels", icon: "rename.svg", enabledText: "Show workspace names alongside icons in expanded pills.", disabledText: "Show only icons in the expanded workspace pills." }
    ] },
    { widgetType: "windowTitle", label: "Active App Context", icon: "window-shield.svg", section: "left", description: "Active window title and app-specific tools.", hasSettings: true, defaultSettings: { maxTitleWidth: 300, showAppIcon: true, showGitStatus: true, showMediaContext: true }, settingsSchema: [
      { type: "slider", key: "maxTitleWidth", label: "Title Width", icon: "ruler.svg", min: 120, max: 520, step: 1 },
      { type: "toggle", key: "showAppIcon", label: "App Icon", icon: "app-generic.svg", enabledText: "Show the active app icon before the title.", disabledText: "Hide the app icon and show only textual context." },
      { type: "toggle", key: "showGitStatus", label: "Git Status", icon: "git-branch.svg", enabledText: "Show inline repository status next to the active window title.", disabledText: "Hide inline repository status from the title widget." },
      { type: "toggle", key: "showMediaContext", label: "Media Context", icon: "music-note-2.svg", enabledText: "Show the mini media context badge when media is active.", disabledText: "Hide inline media context from the title widget." }
    ] },
    { widgetType: "keyboardLayout", label: "Keyboard Layout", icon: "keyboard.svg", section: "right", description: "Current keyboard layout indicator. Auto-hides unless multiple layouts are available.", hasSettings: true, defaultSettings: { labelMode: "short" }, settingsSchema: [
      { type: "mode", key: "labelMode", label: "Label Mode", description: "Choose between the compact three-letter abbreviation or the full layout name. This widget only appears when the compositor exposes more than one keyboard layout.", options: [ { value: "short", label: "Short" }, { value: "full", label: "Full" } ] }
    ] },
    { widgetType: "taskbar", label: "Running Apps", icon: "apps.svg", section: "left", description: "Focused and running applications.", hasSettings: true, defaultSettings: { buttonSize: 32, iconSize: 20, showRunningIndicator: true, showSeparator: true, maxUnpinned: 0 }, settingsSchema: [
      { type: "slider", key: "buttonSize", label: "Button Size", icon: "crop.svg", min: 24, max: 56, step: 1 },
      { type: "slider", key: "iconSize", label: "Icon Size", icon: "app-generic.svg", min: 14, max: 36, step: 1 },
      { type: "slider", key: "maxUnpinned", label: "Max Unpinned Apps", icon: "arrow-counterclockwise.svg", min: 0, max: 20, step: 1 },
      { type: "toggle", key: "showRunningIndicator", label: "Running Indicator", icon: "record.svg", enabledText: "Show the running-state dot on active task buttons.", disabledText: "Hide the running-state indicator dot." },
      { type: "toggle", key: "showSeparator", label: "Separator", icon: "more-horizontal.svg", enabledText: "Separate pinned apps from unpinned running apps.", disabledText: "Remove the divider between pinned and unpinned apps." }
    ] },
    { widgetType: "cpuStatus", label: "CPU", icon: "developer-board.svg", section: "left", description: "CPU usage with system stats popup.", hasSettings: true, defaultSettings: { displayMode: "auto", valueStyle: "percent" }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether this stat adapts to bar orientation or always stays full, compact, or icon-only. Compact mode may shorten long values automatically to keep vertical bars narrow.", options: [ { value: "auto", label: "Auto" }, { value: "full", label: "Full" }, { value: "compact", label: "Compact" }, { value: "icon", label: "Icon" } ] },
      { type: "mode", key: "valueStyle", label: "Value Style", description: "Choose whether this stat shows percent only, usage text, or usage with temperature. Compact mode can shorten long values automatically.", options: [ { value: "percent", label: "Percent" }, { value: "usage", label: "Usage" }, { value: "usageTemp", label: "Usage + Temp" } ] }
    ] },
    { widgetType: "ramStatus", label: "Memory", icon: "board.svg", section: "left", description: "Memory usage with system stats popup.", hasSettings: true, defaultSettings: { displayMode: "auto", valueStyle: "usage" }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether this stat adapts to bar orientation or always stays full, compact, or icon-only. Compact mode may shorten long values automatically to keep vertical bars narrow.", options: [ { value: "auto", label: "Auto" }, { value: "full", label: "Full" }, { value: "compact", label: "Compact" }, { value: "icon", label: "Icon" } ] },
      { type: "mode", key: "valueStyle", label: "Value Style", description: "Choose whether memory shows percent used or the current used-memory value. Compact mode can still fall back to percent when the usage text is too long.", options: [ { value: "usage", label: "Usage" }, { value: "percent", label: "Percent" } ] }
    ] },
    { widgetType: "gpuStatus", label: "GPU", icon: "developer-board.svg", section: "left", description: "GPU usage with system stats popup.", hasSettings: true, defaultSettings: { displayMode: "auto", valueStyle: "percent" }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether this stat adapts to bar orientation or always stays full, compact, or icon-only. Compact mode may shorten long values automatically to keep vertical bars narrow.", options: [ { value: "auto", label: "Auto" }, { value: "full", label: "Full" }, { value: "compact", label: "Compact" }, { value: "icon", label: "Icon" } ] },
      { type: "mode", key: "valueStyle", label: "Value Style", description: "Choose whether this stat shows percent only, usage text, or usage with temperature. Compact mode can shorten long values automatically.", options: [ { value: "percent", label: "Percent" }, { value: "usage", label: "Usage" }, { value: "usageTemp", label: "Usage + Temp" } ] }
    ] },
    { widgetType: "diskStatus", label: "Disk", icon: "hard-drive.svg", section: "left", description: "Disk usage with system stats popup.", hasSettings: true, defaultSettings: { displayMode: "auto", valueStyle: "percent" }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether this stat adapts to bar orientation or always stays full, compact, or icon-only.", options: [ { value: "auto", label: "Auto" }, { value: "full", label: "Full" }, { value: "compact", label: "Compact" }, { value: "icon", label: "Icon" } ] },
      { type: "mode", key: "valueStyle", label: "Value Style", description: "Choose whether to show disk usage as a percentage.", options: [ { value: "percent", label: "Percent" } ] }
    ] },
    { widgetType: "networkStatus", label: "Network Throughput", icon: "ethernet.svg", section: "left", description: "Network throughput with system stats popup.", hasSettings: true, defaultSettings: { displayMode: "auto", valueStyle: "rate" }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether this stat adapts to bar orientation or always stays full, compact, or icon-only.", options: [ { value: "auto", label: "Auto" }, { value: "full", label: "Full" }, { value: "compact", label: "Compact" }, { value: "icon", label: "Icon" } ] },
      { type: "mode", key: "valueStyle", label: "Value Style", description: "Choose whether to show download rate, upload rate, or combined.", options: [ { value: "rate", label: "Download" }, { value: "up", label: "Upload" } ] }
    ] },
    { widgetType: "systemMonitor", label: "System Monitor", icon: "board.svg", section: "left", description: "Legacy combined system monitor widget with the full stats surface." },
    { widgetType: "dateTime", label: "Clock", icon: "clock.svg", section: "center", description: "Current time and date popup.", hasSettings: true, defaultSettings: { displayMode: "auto", showDate: true }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether the clock adapts to bar orientation automatically, always shows the full time row, or stays icon-only.", options: [ { value: "auto", label: "Auto" }, { value: "full", label: "Full" }, { value: "icon", label: "Icon" } ] },
      { type: "toggle", key: "showDate", label: "Show Date", icon: "calendar-add.svg", enabledText: "Show the date segment alongside the time when space allows.", disabledText: "Show only the time in the bar widget." }
    ] },
    { widgetType: "mediaBar", label: "Media Controls", icon: "music-note-2.svg", section: "center", description: "Current media playback widget with optional inline visualizer.", hasSettings: true, defaultSettings: { displayMode: "auto", maxTextWidth: 150, showVisualizer: true, visualizerBars: 8 }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether the media widget adapts to bar orientation automatically, always shows track text, or stays icon-only.", options: [ { value: "auto", label: "Auto" }, { value: "full", label: "Full" }, { value: "icon", label: "Icon" } ] },
      { type: "slider", key: "maxTextWidth", label: "Track Text Width", icon: "ruler.svg", min: 80, max: 240, step: 1 },
      { type: "toggle", key: "showVisualizer", label: "Visualizer", icon: "device-eq.svg", enabledText: "Show the inline visualizer inside media controls while media is actively playing.", disabledText: "Hide the inline visualizer and keep only the media controls." },
      { type: "slider", key: "visualizerBars", label: "Visualizer Bars", icon: "device-eq.svg", min: 4, max: 20, step: 1 }
    ] },
    { widgetType: "updates", label: "Updates", icon: "arrow-sync.svg", section: "center", description: "Pending system updates.", hasSettings: true, defaultSettings: { displayMode: "auto" }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether the updates widget adapts to bar orientation automatically, always shows its count, or stays icon-only.", options: [ { value: "auto", label: "Auto" }, { value: "full", label: "Full" }, { value: "icon", label: "Icon" } ] }
    ] },
    { widgetType: "cava", label: "Visualizer", icon: "device-eq.svg", section: "center", description: "Compact audio spectrum with popup.", hasSettings: true, defaultSettings: { barCount: 8 }, settingsSchema: [
      { type: "slider", key: "barCount", label: "Bar Count", icon: "device-eq.svg", min: 4, max: 20, step: 1 }
    ] },
    { widgetType: "idleInhibitor", label: "Idle Inhibitor", icon: "power-sleep-filled.svg", section: "center", description: "Toggle idle inhibit state." },
    { widgetType: "modelUsage", label: "AI Model Usage", icon: "board.svg", section: "right", description: "Popup-first AI coding assistant usage surface for Claude Code, Codex CLI, and Gemini CLI.", hasSettings: true, defaultSettings: { displayMode: "auto" }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether this widget adapts to bar orientation automatically, always shows its text/details, or stays icon-only.", options: [ { value: "auto", label: "Auto" }, { value: "full", label: "Full" }, { value: "icon", label: "Icon" } ] }
    ] },
    { widgetType: "weather", label: "Weather", icon: "weather-sunny.svg", section: "right", description: "Current weather and forecast popup.", hasSettings: true, defaultSettings: { displayMode: "auto" }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether this widget adapts to bar orientation automatically, always shows its text/details, or stays icon-only.", options: [ { value: "auto", label: "Auto" }, { value: "full", label: "Full" }, { value: "icon", label: "Icon" } ] }
    ] },
    { widgetType: "market", label: "Markets", icon: "news.svg", section: "right", description: "Market quotes and indices.", hasSettings: true, defaultSettings: { displayMode: "auto" }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether this widget adapts to bar orientation automatically, always shows its text/details, or stays icon-only.", options: [ { value: "auto", label: "Auto" }, { value: "full", label: "Full" }, { value: "icon", label: "Icon" } ] }
    ] },
    {
      widgetType: "ssh",
      label: "SSH",
      icon: "server.svg",
      section: "right",
      description: "SSH hosts with manual entries and ~/.ssh/config import.",
      hasSettings: true,
      defaultSettings: {
        manualHosts: [],
        enableSshConfigImport: true,
        displayMode: "count",
        defaultAction: "connect",
        sshCommand: "ssh",
        showWhenEmpty: false,
        emptyClickAction: "menu",
        emptyLabel: "SSH",
        state: {
          lastConnectedId: "",
          lastConnectedLabel: "",
          lastConnectedAt: "",
          recentIds: []
        }
      },
      settingsSchema: [
        { type: "toggle", key: "enableSshConfigImport", label: "SSH Config Import", icon: "server.svg", enabledText: "Import aliases from ~/.ssh/config and include files.", disabledText: "Only manual hosts are shown." },
        { type: "text", key: "sshCommand", label: "SSH Command", icon: "terminal.svg", placeholder: "ssh", description: "Command for connections (e.g. ssh, kitten ssh, mosh)." },
        { type: "mode", key: "displayMode", label: "Bar Label", description: "Choose whether the widget shows the total host count or the most recent host label.", options: [ { value: "count", label: "Count" }, { value: "recent", label: "Recent" } ] },
        { type: "mode", key: "defaultAction", label: "Primary Click", description: "Choose the action used when the widget has exactly one host.", options: [ { value: "connect", label: "Connect" }, { value: "copy", label: "Copy Command" } ] },
        { type: "toggle", key: "showWhenEmpty", label: "Show When Empty", icon: "empty.svg", enabledText: "Keep the SSH pill visible even when no hosts or import results are available yet.", disabledText: "Hide the SSH pill until hosts, import activity, or import errors exist." },
        { type: "mode", key: "emptyClickAction", label: "Empty Click", description: "Choose what clicking the SSH pill does when it is visible but still has no hosts.", options: [ { value: "menu", label: "Open Menu" }, { value: "refresh", label: "Refresh Import" } ] },
        { type: "text", key: "emptyLabel", label: "Empty Label", icon: "rename.svg", placeholder: "SSH" }
      ]
    },
    { widgetType: "vpn", label: "VPN Hub", icon: "shield-lock.svg", section: "right", description: "Tailscale-first VPN status and controls popup.", hasSettings: true, defaultSettings: { displayMode: "auto", labelMode: "status", showOtherVpnCount: true }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether this widget adapts to bar orientation automatically, always shows its label, or stays icon-only.", options: [ { value: "auto", label: "Auto" }, { value: "full", label: "Full" }, { value: "icon", label: "Icon" } ] },
      { type: "mode", key: "labelMode", label: "Detail Label", description: "Choose whether the secondary chip shows Tailscale status text or the current IPv4 address when connected.", options: [ { value: "status", label: "Status" }, { value: "ip", label: "IP" } ] },
      { type: "toggle", key: "showOtherVpnCount", label: "Other VPN Count", icon: "shield-lock.svg", enabledText: "Show a secondary badge when non-Tailscale VPN sessions are active.", disabledText: "Hide the secondary VPN count badge and keep the widget Tailscale-only." }
    ] },
    { widgetType: "network", label: "Network", icon: "wifi-4.svg", section: "right", description: "Network state and controls popup.", hasSettings: true, defaultSettings: { displayMode: "auto" }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether this widget adapts to bar orientation automatically, always shows its text/details, or stays icon-only.", options: [ { value: "auto", label: "Auto" }, { value: "full", label: "Full" }, { value: "icon", label: "Icon" } ] }
    ] },
    { widgetType: "bluetooth", label: "Bluetooth", icon: "bluetooth.svg", section: "right", description: "Bluetooth status and controls popup.", hasSettings: true, defaultSettings: { displayMode: "auto" }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether the Bluetooth widget adapts to bar orientation automatically, always shows status text, or stays icon-only.", options: [ { value: "auto", label: "Auto" }, { value: "full", label: "Full" }, { value: "icon", label: "Icon" } ] }
    ] },
    { widgetType: "audio", label: "Audio", icon: "speaker.svg", section: "right", description: "Volume and device controls popup.", hasSettings: true, defaultSettings: { displayMode: "auto" }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether this widget adapts to bar orientation automatically, always shows its text/details, or stays icon-only.", options: [ { value: "auto", label: "Auto" }, { value: "full", label: "Full" }, { value: "icon", label: "Icon" } ] }
    ] },
    { widgetType: "music", label: "Music", icon: "music-note-2.svg", section: "right", description: "Compact active player shortcut.", hasSettings: true, defaultSettings: { displayMode: "auto", maxTextWidth: 100 }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether the music widget adapts to bar orientation automatically, always shows track text, or stays icon-only.", options: [ { value: "auto", label: "Auto" }, { value: "full", label: "Full" }, { value: "icon", label: "Icon" } ] },
      { type: "slider", key: "maxTextWidth", label: "Track Text Width", icon: "ruler.svg", min: 60, max: 220, step: 1 }
    ] },
    { widgetType: "privacy", label: "Privacy", icon: "shield.svg", section: "right", description: "Camera, mic, and share indicators.", hasSettings: true, defaultSettings: { displayMode: "auto", showPulseDot: true }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether the privacy widget adapts to bar orientation automatically, always shows text, or stays icon-only.", options: [ { value: "auto", label: "Auto" }, { value: "full", label: "Full" }, { value: "icon", label: "Icon" } ] },
      { type: "toggle", key: "showPulseDot", label: "Pulse Dot", icon: "record.svg", enabledText: "Show the animated activity dot beside the privacy icon.", disabledText: "Hide the animated pulse dot and keep only the icon/text." }
    ] },
    { widgetType: "voxtype", label: "Voxtype", icon: "mic.svg", section: "right", description: "Voice-to-text daemon status and recording controls.", hasSettings: true, defaultSettings: { displayMode: "auto", iconTheme: "nerd-font", refreshInterval: 1 }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether the Voxtype widget adapts to bar orientation automatically, always shows status text, or stays icon-only.", options: [ { value: "auto", label: "Auto" }, { value: "full", label: "Full" }, { value: "icon", label: "Icon" } ] },
      { type: "mode", key: "iconTheme", label: "Icon Theme", description: "Choose which voxtype icon theme the widget requests from the CLI.", options: [ { value: "nerd-font", label: "Nerd Font" }, { value: "emoji", label: "Emoji" }, { value: "material", label: "Material" }, { value: "phosphor", label: "Phosphor" }, { value: "codicons", label: "Codicons" }, { value: "omarchy", label: "Omarchy" }, { value: "minimal", label: "Minimal" }, { value: "dots", label: "Dots" }, { value: "arrows", label: "Arrows" }, { value: "text", label: "Text" } ] },
      { type: "slider", key: "refreshInterval", label: "Refresh Interval", icon: "clock.svg", min: 1, max: 10, step: 1, unit: "s" }
    ] },
    { widgetType: "forge", label: "Forge Notifications", icon: "brands/github.svg", section: "right", description: "GitHub and GitLab unread notifications.", hasSettings: true, defaultSettings: { displayMode: "auto" }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether this widget adapts to bar orientation automatically, always shows its label, or stays icon-only.", options: [ { value: "auto", label: "Auto" }, { value: "full", label: "Full" }, { value: "icon", label: "Icon" } ] }
    ] },
    { widgetType: "serviceMonitor", label: "Service Monitor", icon: "settings.svg", section: "right", description: "Monitor and control a systemd service.", hasSettings: true, repeatable: true, defaultSettings: { displayMode: "auto", serviceName: "syncthing.service", scope: "user", label: "", icon: "settings.svg" }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether this widget adapts to bar orientation automatically, always shows its label, or stays icon-only.", options: [ { value: "auto", label: "Auto" }, { value: "full", label: "Full" }, { value: "icon", label: "Icon" } ] },
      { type: "text", key: "serviceName", label: "Service Name", icon: "settings.svg", placeholder: "syncthing.service" },
      { type: "mode", key: "scope", label: "Scope", description: "Choose whether to monitor a user or system service.", options: [ { value: "user", label: "User" }, { value: "system", label: "System" } ] },
      { type: "text", key: "label", label: "Custom Label", icon: "rename.svg", placeholder: "Optional label" },
      { type: "text", key: "icon", label: "Custom Icon", icon: "app-generic.svg", placeholder: "settings.svg" }
    ] },
    { widgetType: "recording", label: "Recording", icon: "record.svg", section: "right", description: "Active screen recording indicator.", hasSettings: true, defaultSettings: { displayMode: "auto", showPulseDot: true }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether the recording widget adapts to bar orientation automatically, always shows REC text, or stays icon-only.", options: [ { value: "auto", label: "Auto" }, { value: "full", label: "Full" }, { value: "icon", label: "Icon" } ] },
      { type: "toggle", key: "showPulseDot", label: "Pulse Dot", icon: "record.svg", enabledText: "Show the animated recording dot beside the label.", disabledText: "Hide the recording pulse dot." }
    ] },
    { widgetType: "battery", label: "Battery", icon: "battery-full.svg", section: "right", description: "Battery status and actions popup.", hasSettings: true, defaultSettings: { displayMode: "auto" }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether this widget adapts to bar orientation automatically, always shows its text/details, or stays icon-only.", options: [ { value: "auto", label: "Auto" }, { value: "full", label: "Full" }, { value: "icon", label: "Icon" } ] }
    ] },
    { widgetType: "printer", label: "Printers", icon: "print.svg", section: "right", description: "Printer status popup.", hasSettings: true, defaultSettings: { displayMode: "auto", badgeStyle: "count" }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether the printer widget adapts to bar orientation automatically, always shows job badges, or stays icon-only.", options: [ { value: "auto", label: "Auto" }, { value: "full", label: "Full" }, { value: "icon", label: "Icon" } ] },
      { type: "mode", key: "badgeStyle", label: "Badge Style", description: "Choose whether active print jobs show as a count badge, a dot, or no badge.", options: [ { value: "count", label: "Count" }, { value: "dot", label: "Dot" }, { value: "off", label: "Off" } ] }
    ] },
    { widgetType: "aiChat", label: "AI Chat", icon: "chat.svg", section: "right", description: "AI chat assistant toggle.", hasSettings: true, defaultSettings: { displayMode: "icon", labelText: "AI" }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether this trigger stays icon-only or also shows a text label in the bar.", options: [ { value: "icon", label: "Icon" }, { value: "full", label: "Full" } ] },
      { type: "text", key: "labelText", label: "Label Text", icon: "rename.svg", placeholder: "AI" }
    ] },
    { widgetType: "notepad", label: "Notepad", icon: "document.svg", section: "right", description: "Slideout notepad trigger.", hasSettings: true, defaultSettings: { displayMode: "icon", labelText: "Notes" }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether this trigger stays icon-only or also shows a text label in the bar.", options: [ { value: "icon", label: "Icon" }, { value: "full", label: "Full" } ] },
      { type: "text", key: "labelText", label: "Label Text", icon: "rename.svg", placeholder: "Notes" }
    ] },
    { widgetType: "controlCenter", label: "Control Center", icon: "settings.svg", section: "right", description: "Command center trigger.", hasSettings: true, defaultSettings: { displayMode: "icon", labelText: "Controls" }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether this trigger stays icon-only or also shows a text label in the bar.", options: [ { value: "icon", label: "Icon" }, { value: "full", label: "Full" } ] },
      { type: "text", key: "labelText", label: "Label Text", icon: "rename.svg", placeholder: "Controls" }
    ] },
    { widgetType: "tray", label: "System Tray", icon: "app-generic.svg", section: "right", description: "Status notifier tray.", hasSettings: true, defaultSettings: { itemSize: 24, iconSize: 18, spacing: 6 }, settingsSchema: [
      { type: "slider", key: "itemSize", label: "Item Size", icon: "desktop.svg", min: 18, max: 40, step: 1 },
      { type: "slider", key: "iconSize", label: "Icon Size", icon: "app-generic.svg", min: 12, max: 32, step: 1 },
      { type: "slider", key: "spacing", label: "Spacing", icon: "more-horizontal.svg", min: 2, max: 16, step: 1 }
    ] },
    { widgetType: "clipboard", label: "Clipboard", icon: "copy.svg", section: "right", description: "Clipboard history popup.", hasSettings: true, defaultSettings: { displayMode: "icon", labelText: "Clipboard" }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether this trigger stays icon-only or also shows a text label in the bar.", options: [ { value: "icon", label: "Icon" }, { value: "full", label: "Full" } ] },
      { type: "text", key: "labelText", label: "Label Text", icon: "rename.svg", placeholder: "Clipboard" }
    ] },
    { widgetType: "screenshot", label: "Screenshot", icon: "crop.svg", section: "right", description: "Screenshot capture popup.", hasSettings: true, defaultSettings: { displayMode: "icon", labelText: "Shot" }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether this trigger stays icon-only or also shows a text label in the bar.", options: [ { value: "icon", label: "Icon" }, { value: "full", label: "Full" } ] },
      { type: "text", key: "labelText", label: "Label Text", icon: "rename.svg", placeholder: "Shot" }
    ] },
    { widgetType: "notifications", label: "Notifications", icon: "alert.svg", section: "right", description: "Notification center trigger.", hasSettings: true, defaultSettings: { displayMode: "auto", badgeStyle: "dot" }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether the notifications widget adapts to bar orientation automatically, always shows extra status text, or stays icon-only.", options: [ { value: "auto", label: "Auto" }, { value: "full", label: "Full" }, { value: "icon", label: "Icon" } ] },
      { type: "mode", key: "badgeStyle", label: "Badge Style", description: "Choose whether unread notifications show as a dot, a count, or no badge at all.", options: [ { value: "dot", label: "Dot" }, { value: "count", label: "Count" }, { value: "off", label: "Off" } ] }
    ] },
    { widgetType: "spacer", label: "Spacer", icon: "subtract.svg", section: "center", description: "Adjustable empty spacing.", hasSettings: true, defaultSettings: { size: 24 }, settingsSchema: [
      { type: "slider", key: "size", label: "Spacer Size", icon: "subtract.svg", min: 4, max: 160, step: 1 }
    ] },
    { widgetType: "separator", label: "Separator", icon: "more-horizontal.svg", section: "center", description: "Thin divider between widgets.", hasSettings: true, defaultSettings: { thickness: 1, length: 20, opacity: 0.8 }, settingsSchema: [
      { type: "slider", key: "thickness", label: "Thickness", icon: "more-horizontal.svg", min: 1, max: 8, step: 1 },
      { type: "slider", key: "length", label: "Length", icon: "crop.svg", min: 8, max: 64, step: 1 },
      { type: "slider", key: "opacity", label: "Opacity", icon: "weather-moon.svg", min: 0.1, max: 1.0, step: 0.05, unit: "%" }
    ] },
    { widgetType: "personality", label: "Personality", icon: "people.svg", section: "center", description: "Animated personality GIF widget.", hasSettings: true, defaultSettings: { reactionMode: "media" }, settingsSchema: [
      { type: "mode", key: "reactionMode", label: "Reaction Mode", description: "Choose how the character reacts to system activity.", options: [ { value: "idle", label: "Idle" }, { value: "media", label: "Media" }, { value: "cpu", label: "CPU" }, { value: "beat", label: "Beat" } ] }
    ] },
    { widgetType: "pomodoro", label: "Pomodoro Timer", icon: "pomodoro.svg", section: "right", description: "Focus/break timer with start, pause, skip, and reset controls." },
    { widgetType: "power", label: "Power", icon: "power.svg", section: "right", description: "System power and session controls.", hasSettings: true, defaultSettings: { displayMode: "icon", labelText: "Power" }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether this trigger stays icon-only or also shows a text label in the bar.", options: [ { value: "icon", label: "Icon" }, { value: "full", label: "Full" } ] },
      { type: "text", key: "labelText", label: "Label Text", icon: "rename.svg", placeholder: "Power" }
    ] },
    { widgetType: "todo", label: "Todo", icon: "checkmark.svg", section: "right", description: "Pending task counter with clear-done shortcut." },
    { widgetType: "gameMode", label: "Game Mode", icon: "games.svg", section: "right", description: "Performance mode indicator — shows when game mode is active." },
    { widgetType: "nightLight", label: "Night Light", icon: "weather-moon.svg", section: "right", description: "Night light indicator — shows when color temperature filter is active." },
    { widgetType: "unifiNetwork", label: "UniFi Network", icon: "brands/ubiquiti-symbolic.svg", section: "right", description: "UniFi network overview — devices, sites, and ISP health metrics.", hasSettings: true, defaultSettings: { displayMode: "auto" }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether this widget adapts to bar orientation automatically, always shows details, or stays icon-only.", options: [ { value: "auto", label: "Auto" }, { value: "full", label: "Full" }, { value: "icon", label: "Icon" } ] }
    ] },
    { widgetType: "unifiProtect", label: "UniFi Protect", icon: "brands/unifi-protect-symbolic.svg", section: "right", description: "UniFi Protect cameras — snapshots and live RTSPS streams.", hasSettings: true, defaultSettings: { displayMode: "auto" }, settingsSchema: [
      { type: "mode", key: "displayMode", label: "Display Mode", description: "Choose whether this widget adapts to bar orientation automatically, always shows details, or stays icon-only.", options: [ { value: "auto", label: "Auto" }, { value: "full", label: "Full" }, { value: "icon", label: "Icon" } ] }
    ] }
  ]

  readonly property var pluginWidgets: {
    var items = [];
    var plugins = Services.PluginService.barPlugins || [];
    for (var i = 0; i < plugins.length; ++i) {
      var plugin = plugins[i];
      items.push({
        widgetType: "plugin:" + plugin.id,
        label: plugin.name || plugin.id,
        icon: "apps.svg",
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

  function metadataFor(widgetType) {
    var items = widgets;
    for (var i = 0; i < items.length; ++i) {
      if (items[i].widgetType === widgetType) return items[i];
    }

    if (String(widgetType || "").indexOf("plugin:") === 0) {
      var pluginId = String(widgetType).slice(7);
      var plugins = Services.PluginService.barPlugins || [];
      for (var j = 0; j < plugins.length; ++j) {
        if (plugins[j].id === pluginId) {
          return {
            widgetType: widgetType,
            label: plugins[j].name || pluginId,
            icon: "apps.svg",
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
    return meta ? meta.icon : "app-generic.svg";
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

  function settingsSchema(widgetType) {
    var meta = metadataFor(widgetType);
    return meta && meta.settingsSchema ? JSON.parse(JSON.stringify(meta.settingsSchema)) : [];
  }

  function verticalBehavior(widgetType) {
    return VerticalWidgetPolicy.verticalWidgetBehavior(widgetType);
  }

  function verticalHintLabel(widgetType) {
    return VerticalWidgetPolicy.verticalHintLabel(widgetType);
  }

  function _isVerticalBarContext(barPositionOrVertical) {
    if (barPositionOrVertical === true)
      return true;
    var position = String(barPositionOrVertical || "");
    return position === "left" || position === "right";
  }

  function _effectiveSettings(widgetInstance) {
    var widgetType = widgetInstance ? String(widgetInstance.widgetType || "") : "";
    var defaults = defaultSettings(widgetType);
    var settings = widgetInstance && widgetInstance.settings ? widgetInstance.settings : {};
    var next = JSON.parse(JSON.stringify(defaults));
    for (var key in settings) {
      next[key] = settings[key];
    }
    return next;
  }

  function _modeLabel(modeValue) {
    var mode = String(modeValue || "auto");
    if (mode === "full")
      return "Full";
    if (mode === "compact")
      return "Compact";
    if (mode === "icon")
      return "Icon";
    return "Auto";
  }

  function _simpleTriggerFallbackLabel(widgetType) {
    if (widgetType === "logo")
      return "Apps";
    if (widgetType === "aiChat")
      return "AI";
    if (widgetType === "notepad")
      return "Notes";
    if (widgetType === "controlCenter")
      return "Controls";
    if (widgetType === "clipboard")
      return "Clipboard";
    if (widgetType === "screenshot")
      return "Shot";
    return "Open";
  }

  function _keyboardLayoutVisibilityChip() {
    if (!Services.CompositorAdapter.supportsKeyboardLayouts)
      return "Auto: Unavailable";

    var names = Services.CompositorAdapter.niriKeyboardLayoutNames || [];
    if (names.length > 1)
      return "Auto: Shown";

    return "Auto: Hidden";
  }

  function summaryChips(widgetInstance, barPositionOrVertical) {
    if (!widgetInstance)
      return [];

    var widgetType = String(widgetInstance.widgetType || "");
    var settings = _effectiveSettings(widgetInstance);
    var chips = [];
    var parsed;
    if (_isVerticalBarContext(barPositionOrVertical))
      chips.push(verticalHintLabel(widgetType));

    if (widgetType === "cpuStatus" || widgetType === "ramStatus" || widgetType === "gpuStatus" || widgetType === "diskStatus" || widgetType === "networkStatus") {
      var valueStyle = String(settings.valueStyle || (widgetType === "ramStatus" ? "usage" : "percent"));
      var valueLabel = "Percent";
      if (valueStyle === "usageTemp")
        valueLabel = "Usage + Temp";
      else if (valueStyle === "usage")
        valueLabel = "Usage";
      chips.push("Mode: " + _modeLabel(settings.displayMode));
      chips.push("Value: " + valueLabel);
      return chips;
    }

    if (widgetType === "weather" || widgetType === "market" || widgetType === "modelUsage" || widgetType === "network" || widgetType === "audio" || widgetType === "battery" || widgetType === "updates" || widgetType === "bluetooth") {
      chips.push("Display: " + _modeLabel(settings.displayMode));
      return chips;
    }

    if (widgetType === "windowTitle") {
      var titleParts = [];
      if (settings.showAppIcon !== false)
        titleParts.push("Icon");
      if (settings.showGitStatus !== false)
        titleParts.push("Git");
      if (settings.showMediaContext !== false)
        titleParts.push("Media");
      chips.push(titleParts.length > 0 ? titleParts.join(" + ") : "Title Only");
      return chips;
    }

    if (widgetType === "mediaBar") {
      parsed = parseInt(settings.maxTextWidth !== undefined ? settings.maxTextWidth : 150, 10);
      chips.push("Display: " + _modeLabel(settings.displayMode));
      chips.push("Text: " + String(isNaN(parsed) ? 150 : parsed) + "px");
      chips.push(settings.showVisualizer !== false ? "Visualizer On" : "Visualizer Off");
      if (settings.showVisualizer !== false) {
        var mediaBars = parseInt(settings.visualizerBars !== undefined ? settings.visualizerBars : 8, 10);
        chips.push("Bars: " + String(isNaN(mediaBars) ? 8 : mediaBars));
      }
      return chips;
    }

    if (widgetType === "keyboardLayout") {
      chips.push(_keyboardLayoutVisibilityChip());
      chips.push("Label: " + (String(settings.labelMode || "short") === "full" ? "Full" : "Short"));
      return chips;
    }

    if (widgetType === "dateTime") {
      chips.push("Display: " + _modeLabel(settings.displayMode));
      chips.push(settings.showDate !== false ? "Date On" : "Date Off");
      return chips;
    }

    if (widgetType === "notifications") {
      var notificationBadge = String(settings.badgeStyle || "dot");
      var notificationBadgeLabel = notificationBadge === "count" ? "Count" : (notificationBadge === "off" ? "Off" : "Dot");
      chips.push("Display: " + _modeLabel(settings.displayMode));
      chips.push("Badge: " + notificationBadgeLabel);
      return chips;
    }

    if (widgetType === "tray") {
      var itemSize = parseInt(settings.itemSize !== undefined ? settings.itemSize : 24, 10);
      var iconSize = parseInt(settings.iconSize !== undefined ? settings.iconSize : 18, 10);
      chips.push(String(isNaN(itemSize) ? 24 : itemSize) + "px items");
      chips.push(String(isNaN(iconSize) ? 18 : iconSize) + "px icons");
      return chips;
    }

    if (widgetType === "taskbar") {
      var buttonSize = parseInt(settings.buttonSize !== undefined ? settings.buttonSize : 32, 10);
      var taskIconSize = parseInt(settings.iconSize !== undefined ? settings.iconSize : 20, 10);
      var maxUnpinned = parseInt(settings.maxUnpinned !== undefined ? settings.maxUnpinned : 0, 10);
      chips.push(String(isNaN(buttonSize) ? 32 : buttonSize) + "px buttons");
      chips.push(String(isNaN(taskIconSize) ? 20 : taskIconSize) + "px icons");
      if (!isNaN(maxUnpinned) && maxUnpinned > 0)
        chips.push("+" + maxUnpinned + " unpinned");
      return chips;
    }

    if (widgetType === "workspaces") {
      chips.push(settings.showAddButton !== false ? "Add On" : "Add Off");
      chips.push(settings.showMiniMap !== false ? "Mini-map On" : "Mini-map Off");
      return chips;
    }

    if (widgetType === "specialWorkspaces") {
      chips.push(settings.showLabels === true ? "Labels On" : "Labels Off");
      return chips;
    }

    if (widgetType === "music") {
      parsed = parseInt(settings.maxTextWidth !== undefined ? settings.maxTextWidth : 100, 10);
      chips.push("Display: " + _modeLabel(settings.displayMode));
      chips.push("Text: " + String(isNaN(parsed) ? 100 : parsed) + "px");
      return chips;
    }

    if (widgetType === "printer") {
      var printerBadge = String(settings.badgeStyle || "count");
      var printerBadgeLabel = printerBadge === "dot" ? "Dot" : (printerBadge === "off" ? "Off" : "Count");
      chips.push("Display: " + _modeLabel(settings.displayMode));
      chips.push("Badge: " + printerBadgeLabel);
      return chips;
    }

    if (widgetType === "privacy" || widgetType === "recording") {
      chips.push("Display: " + _modeLabel(settings.displayMode));
      chips.push(settings.showPulseDot !== false ? "Pulse On" : "Pulse Off");
      return chips;
    }

    if (widgetType === "voxtype") {
      chips.push("Display: " + _modeLabel(settings.displayMode));
      chips.push("Theme: " + String(settings.iconTheme || "nerd-font"));
      chips.push("Refresh: " + String(parseInt(settings.refreshInterval !== undefined ? settings.refreshInterval : 1, 10) || 1) + "s");
      return chips;
    }

    if (widgetType === "cava") {
      parsed = parseInt(settings.barCount !== undefined ? settings.barCount : 8, 10);
      chips.push("Bars: " + String(isNaN(parsed) ? 8 : parsed));
      return chips;
    }

    if (widgetType === "separator") {
      var thickness = parseInt(settings.thickness !== undefined ? settings.thickness : 1, 10);
      var length = parseInt(settings.length !== undefined ? settings.length : 20, 10);
      var opacity = Number(settings.opacity !== undefined ? settings.opacity : 0.8);
      chips.push(String(isNaN(thickness) ? 1 : thickness) + "px");
      chips.push(String(isNaN(length) ? 20 : length) + "px");
      chips.push(isNaN(opacity) ? "80%" : Math.round(opacity * 100) + "%");
      return chips;
    }

    if (widgetType === "logo" || widgetType === "aiChat" || widgetType === "notepad" || widgetType === "controlCenter" || widgetType === "clipboard" || widgetType === "screenshot") {
      var fallback = _simpleTriggerFallbackLabel(widgetType);
      var triggerLabel = String(settings.labelText !== undefined ? settings.labelText : fallback).trim();
      chips.push("Display: " + (String(settings.displayMode || "icon") === "full" ? "Full" : "Icon"));
      chips.push("Label: " + (triggerLabel.length > 0 ? triggerLabel : fallback));
      return chips;
    }

    if (widgetType === "personality") {
      chips.push("Mode: " + String(settings.reactionMode || "media").toUpperCase());
      return chips;
    }

    if (widgetType === "spacer") {
      parsed = parseInt(settings.size !== undefined ? settings.size : 24, 10);
      chips.push("Size: " + String(isNaN(parsed) ? 24 : parsed) + "px");
      return chips;
    }

    if (widgetType === "ssh") {
      var manualHosts = Array.isArray(settings.manualHosts) ? settings.manualHosts : [];
      var state = settings.state || {};
      var displayMode = String(settings.displayMode || "count") === "recent" ? "Recent" : "Count";
      var defaultAction = String(settings.defaultAction || "connect") === "copy" ? "Copy" : "Connect";
      var emptyClickAction = String(settings.emptyClickAction || "menu") === "refresh" ? "Refresh" : "Menu";
      var lastConnected = String(state.lastConnectedLabel || "").trim();
      var sshCmd = String(settings.sshCommand || "ssh").trim();
      chips.push("Label: " + displayMode);
      chips.push("Click: " + defaultAction);
      if (sshCmd !== "" && sshCmd !== "ssh")
        chips.push("Cmd: " + sshCmd);
      chips.push("Manual: " + manualHosts.length);
      chips.push(settings.enableSshConfigImport !== false ? "Import On" : "Import Off");
      chips.push(settings.showWhenEmpty === true ? "Pinned Empty" : "Hide Empty");
      chips.push("Empty: " + emptyClickAction);
      if (lastConnected.length > 0)
        chips.push("Last: " + lastConnected);
      return chips;
    }

    return chips;
  }

  function pluginByWidgetType(widgetType) {
    if (String(widgetType || "").indexOf("plugin:") !== 0) return null;
    var pluginId = String(widgetType).slice(7);
    var plugins = Services.PluginService.barPlugins || [];
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
