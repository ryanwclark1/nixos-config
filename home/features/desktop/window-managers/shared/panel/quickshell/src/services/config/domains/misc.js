.pragma library

var sectionKey = "market"

var maps = [
    ["tickers", "marketTickers"]
]

var modelUsage = {
    sectionKey: "modelUsage",
    maps: [
        ["claudeEnabled", "modelUsageClaudeEnabled"],
        ["codexEnabled", "modelUsageCodexEnabled"],
        ["geminiEnabled", "modelUsageGeminiEnabled"],
        ["activeProvider", "modelUsageActiveProvider"]
    ]
}

var desktopWidgets = {
    sectionKey: "desktopWidgets",
    maps: [
        ["enabled", "desktopWidgetsEnabled"],
        ["gridSnap", "desktopWidgetsGridSnap"],
        ["monitorWidgets", "desktopWidgetsMonitorWidgets"]
    ]
}

var background = {
    sectionKey: "background",
    maps: [
        ["visualizerEnabled", "backgroundVisualizerEnabled"],
        ["useShaderVisualizer", "backgroundUseShaderVisualizer"],
        ["clockEnabled", "backgroundClockEnabled"],
        ["autoHide", "backgroundAutoHide"],
        ["clockPosition", "backgroundClockPosition"],
        ["weatherOverlay", "weatherOverlayEnabled"]
    ]
}

var workspaces = {
    sectionKey: "workspaces",
    maps: [
        ["showEmpty", "workspaceShowEmpty"],
        ["showNames", "workspaceShowNames"],
        ["showAppIcons", "workspaceShowAppIcons"],
        ["showWindowCount", "workspaceShowWindowCount"],
        ["maxIcons", "workspaceMaxIcons"],
        ["pillSize", "workspacePillSize"],
        ["style", "workspaceStyle"],
        ["layout", "workspaceLayout"],
        ["scrollEnabled", "workspaceScrollEnabled"],
        ["reverseScroll", "workspaceReverseScroll"],
        ["activeColor", "workspaceActiveColor"],
        ["urgentColor", "workspaceUrgentColor"],
        ["clickBehavior", "workspaceClickBehavior"]
    ]
}

var displayProfiles = {
    sectionKey: "displayProfiles",
    maps: [
        ["profiles", "displayProfiles"],
        ["autoProfile", "displayAutoProfile"]
    ]
}

var state = {
    sectionKey: "state",
    maps: [
        ["activeSurfaceId", "activeSurfaceId"],
        ["debug", "debug"],
        ["barWidgetLoadLogging", "barWidgetLoadLogging"]
    ]
}
