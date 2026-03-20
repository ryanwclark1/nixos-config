.pragma library

function _entry(base, actions, actionName) {
    var out = Object.assign({}, base);
    if (actionName && actions && typeof actions[actionName] === "function")
        out.action = actions[actionName];
    return out;
}

function buildSystemDestinationItems(actions) {
    return [
        _entry({
            id: "dashboard",
            category: "System",
            name: "Dashboard",
            title: "Open the shell overview",
            description: "Shell > Dashboard",
            icon: "board.svg",
            keywords: "overview vitals media dashboard",
            entryKind: "destination"
        }, actions, "openDashboard"),
        _entry({
            id: "settings",
            category: "System",
            name: "Settings",
            title: "Open launcher and shell settings",
            description: "System > Settings",
            icon: "settings.svg",
            keywords: "preferences settings launcher shell",
            entryKind: "destination"
        }, actions, "openSettings"),
        _entry({
            id: "notifications",
            category: "System",
            name: "Notifications",
            title: "Open notification history",
            description: "System > Notifications",
            icon: "alert.svg",
            keywords: "notifications inbox alerts dnd",
            entryKind: "destination"
        }, actions, "openNotifications"),
        _entry({
            id: "control-center",
            category: "System",
            name: "Control Center",
            title: "Open shell controls",
            description: "System > Control Center",
            icon: "app-generic.svg",
            keywords: "control center quick toggles media system",
            entryKind: "destination"
        }, actions, "openControlCenter"),
        _entry({
            id: "screenshot-menu",
            category: "System",
            name: "Screenshot Menu",
            title: "Open screenshot tools",
            description: "System > Capture",
            icon: "crop.svg",
            keywords: "screenshot capture snip record",
            entryKind: "destination"
        }, actions, "openScreenshotMenu"),
        _entry({
            id: "power-menu",
            category: "Session",
            name: "Power Menu",
            title: "Open session controls",
            description: "Session > Power",
            icon: "power.svg",
            keywords: "power logout reboot shutdown suspend",
            entryKind: "destination"
        }, actions, "openPowerMenu")
    ];
}

function buildCommandPaletteActions(actions) {
    return [
        _entry({
            id: "dashboard",
            category: "System",
            label: "Open Dashboard",
            description: "Jump to the shell overview and system status view.",
            icon: "board.svg",
            keywords: "dashboard overview shell"
        }, actions, "openDashboard"),
        _entry({
            id: "settings",
            category: "System",
            label: "Open Settings",
            description: "Open Quickshell settings.",
            icon: "settings.svg",
            keywords: "settings preferences launcher"
        }, actions, "openSettings"),
        _entry({
            id: "notifications",
            category: "System",
            label: "Open Notifications",
            description: "Show recent notifications and alerts.",
            icon: "alert.svg",
            keywords: "notifications alerts inbox"
        }, actions, "openNotifications"),
        _entry({
            id: "control-center",
            category: "Controls",
            label: "Open Control Center",
            description: "Open the main shell controls surface.",
            icon: "app-generic.svg",
            keywords: "control center quick toggles media"
        }, actions, "openControlCenter"),
        _entry({
            id: "network-controls",
            category: "Controls",
            label: "Open Network Controls",
            description: "Jump directly to Wi-Fi and connectivity controls.",
            icon: "wifi-4.svg",
            keywords: "network wifi connectivity internet"
        }, actions, "openNetworkControls"),
        _entry({
            id: "audio-controls",
            category: "Controls",
            label: "Open Audio Controls",
            description: "Open output, input, and volume controls.",
            icon: "speaker.svg",
            keywords: "audio volume microphone speaker"
        }, actions, "openAudioControls"),
        _entry({
            id: "vpn-controls",
            category: "Controls",
            label: "Open VPN Hub",
            description: "Show VPN and Tailscale controls.",
            icon: "shield-lock.svg",
            keywords: "vpn tailscale network secure"
        }, actions, "openVpnControls"),
        _entry({
            id: "power-menu",
            category: "Session",
            label: "Open Power Menu",
            description: "Open lock, logout, reboot, and shutdown actions.",
            icon: "power.svg",
            keywords: "power reboot shutdown logout suspend"
        }, actions, "openPowerMenu"),
        _entry({
            id: "screenshot",
            category: "System",
            label: "Open Screenshot Menu",
            description: "Start a screenshot or capture workflow.",
            icon: "crop.svg",
            keywords: "screenshot capture snip"
        }, actions, "openScreenshotMenu"),
        _entry({
            id: "ai",
            category: "Intelligence",
            label: "Ask AI Assistant",
            description: "Open the AI chat surface.",
            icon: "chat.svg",
            keywords: "ai assistant chat"
        }, actions, "openAiChat"),
        _entry({
            id: "eco-mode",
            category: "Power",
            label: "Toggle Eco Mode",
            description: "Flip the shell into reduced-intensity mode.",
            icon: "battery-saver.svg",
            keywords: "eco battery power save"
        }, actions, "toggleEcoMode"),
        _entry({
            id: "edit-mode",
            category: "Desktop",
            label: "Toggle Desktop Edit Mode",
            description: "Enable desktop widget edit affordances.",
            icon: "edit.svg",
            keywords: "desktop edit widgets layout"
        }, actions, "toggleDesktopEditMode"),
        _entry({
            id: "dynamic-theme",
            category: "Visuals",
            label: "Toggle Dynamic Theme",
            description: "Switch dynamic wallpaper-driven theming on or off.",
            icon: "color-palette.svg",
            keywords: "theme visuals dynamic wallpaper"
        }, actions, "toggleDynamicTheme"),
        _entry({
            id: "reload",
            category: "System",
            label: "Reload Shell",
            description: "Reload the active Quickshell config.",
            icon: "arrow-counterclockwise.svg",
            keywords: "reload shell refresh"
        }, actions, "reloadShell")
    ];
}
