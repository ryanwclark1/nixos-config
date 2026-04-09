.pragma library

var sectionKey = "panels"

var maps = [
    ["enabledPanels", "enabledPanels"]
]

var controlCenter = {
    sectionKey: "controlCenter",
    maps: [
        ["showQuickLinks", "controlCenterShowQuickLinks"],
        ["showMediaWidget", "controlCenterShowMediaWidget"],
        ["quickLinkOrder", "controlCenterQuickLinkOrder"],
        ["hiddenQuickLinks", "controlCenterHiddenQuickLinks"],
        ["toggleOrder", "controlCenterToggleOrder"],
        ["hiddenToggles", "controlCenterHiddenToggles"],
        ["pluginOrder", "controlCenterPluginOrder"],
        ["hiddenPlugins", "controlCenterHiddenPlugins"],
        ["widgetOrder", "controlCenterWidgetOrder"],
        ["showPomodoro", "controlCenterShowPomodoro"],
        ["showTodo", "controlCenterShowTodo"],
        ["showDevOps", "controlCenterShowDevOps"],
        ["showBrightness", "controlCenterShowBrightness"],
        ["showAudioOutput", "controlCenterShowAudioOutput"],
        ["showAudioInput", "controlCenterShowAudioInput"],
        ["showCpuGpuTemp", "controlCenterShowCpuGpuTemp"],
        ["showCpuWidget", "controlCenterShowCpuWidget"],
        ["showSystemGraphs", "controlCenterShowSystemGraphs"],
        ["showProcessWidget", "controlCenterShowProcessWidget"],
        ["showNetworkGraphs", "controlCenterShowNetworkGraphs"],
        ["showRamWidget", "controlCenterShowRamWidget"],
        ["showDiskWidget", "controlCenterShowDiskWidget"],
        ["showGpuWidget", "controlCenterShowGpuWidget"],
        ["showUpdateWidget", "controlCenterShowUpdateWidget"],
        ["showScratchpad", "controlCenterShowScratchpad"],
        ["showPowerActions", "controlCenterShowPowerActions"]
    ],
    extraKeys: {
        width: true
    }
}

var osd = {
    sectionKey: "osd",
    maps: [
        ["duration", "osdDuration"],
        ["size", "osdSize"],
        ["position", "osdPosition"],
        ["style", "osdStyle"],
        ["overdrive", "osdOverdrive"]
    ]
}

var dock = {
    sectionKey: "dock",
    maps: [
        ["enabled", "dockEnabled"],
        ["autoHide", "dockAutoHide"],
        ["pinnedApps", "dockPinnedApps"],
        ["position", "dockPosition"],
        ["groupApps", "dockGroupApps"],
        ["iconSize", "dockIconSize"]
    ]
}

var powerMenu = {
    sectionKey: "powerMenu",
    maps: [
        ["countdown", "powermenuCountdown"]
    ]
}

var lockScreen = {
    sectionKey: "lockScreen",
    maps: [
        ["compact", "lockScreenCompact"],
        ["mediaControls", "lockScreenMediaControls"],
        ["weather", "lockScreenWeather"],
        ["sessionButtons", "lockScreenSessionButtons"],
        ["countdown", "lockScreenCountdown"],
        ["fingerprint", "lockScreenFingerprint"]
    ]
}
