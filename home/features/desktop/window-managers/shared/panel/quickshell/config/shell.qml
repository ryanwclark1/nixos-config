//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import "bar"
import "launcher"
import "menu"
import "modules"
import "notifications"
import "services"
import "shell"
import "widgets"

Scope {
    id: root

    SurfaceService {
        id: surfaceService
    }

    // Canonical UI state: only one closable surface is active at a time.
    property alias activeSurfaceId: surfaceService.activeSurfaceId
    property alias activeSurfaceContext: surfaceService.activeSurfaceContext
    readonly property var surfaceRegistry: surfaceService.surfaceRegistry
    readonly property var knownSurfaces: surfaceService.knownSurfaces
    readonly property var legacyPanelToSurface: surfaceService.legacyPanelToSurface
    property alias closingSurfaceId: surfaceService.closingSurfaceId
    property alias closingSurfaceContext: surfaceService.closingSurfaceContext
    property alias closingMenuScreen: surfaceService.closingMenuScreen
    property alias pendingSurfaceId: surfaceService.pendingSurfaceId
    property alias pendingSurfaceContext: surfaceService.pendingSurfaceContext
    property alias menuScreen: surfaceService.menuScreen
    readonly property var activeScreen: surfaceService.activeScreen

    // ── Named timing constants ─────────────────
    // Time to wait for LazyLoader to create FileBrowser before calling open().
    readonly property int lazyLoaderSettleMs: 50
    // Delay before re-opening SettingsHub after FileBrowser closes, avoids
    // the same click event toggling SettingsHub back off immediately.
    readonly property int settingsHubReopenMs: 130

    readonly property bool notifCenterVisible: root.isSurfaceOpen("notifCenter")
    readonly property bool controlCenterVisible: root.isSurfaceOpen("controlCenter")
    readonly property bool networkMenuVisible: root.isSurfaceOpen("networkMenu")
    readonly property bool audioMenuVisible: root.isSurfaceOpen("audioMenu")
    readonly property bool powerMenuVisible: root.isSurfaceOpen("powerMenu")
    readonly property bool clipboardMenuVisible: root.isSurfaceOpen("clipboardMenu")
    readonly property bool recordingMenuVisible: root.isSurfaceOpen("recordingMenu")
    readonly property bool musicMenuVisible: root.isSurfaceOpen("musicMenu")
    readonly property bool batteryMenuVisible: root.isSurfaceOpen("batteryMenu")
    readonly property bool weatherMenuVisible: root.isSurfaceOpen("weatherMenu")
    readonly property bool sshMenuVisible: root.isSurfaceOpen("sshMenu")
    readonly property bool dateTimeMenuVisible: root.isSurfaceOpen("dateTimeMenu")
    readonly property bool systemStatsMenuVisible: root.isSurfaceOpen("systemStatsMenu")
    readonly property bool systemMonitorVisible: root.isSurfaceOpen("systemMonitor")
    readonly property bool bluetoothMenuVisible: root.isSurfaceOpen("bluetoothMenu")
    readonly property bool printerMenuVisible: root.isSurfaceOpen("printerMenu")
    readonly property bool privacyMenuVisible: root.isSurfaceOpen("privacyMenu")
    readonly property bool notepadVisible: root.isSurfaceOpen("notepad")
    readonly property bool colorPickerVisible: root.isSurfaceOpen("colorPicker")
    readonly property bool displayConfigVisible: root.isSurfaceOpen("displayConfig")
    readonly property bool fileBrowserVisible: root.isSurfaceOpen("fileBrowser")
    readonly property bool screenshotMenuVisible: root.isSurfaceOpen("screenshotMenu")
    readonly property bool cavaPopupVisible: root.isSurfaceOpen("cavaPopup")
    readonly property bool aiChatVisible: root.isSurfaceOpen("aiChat")

    function currentSurfaceScreen() {
        return surfaceService.currentSurfaceScreen();
    }
    function normalizeSurfaceId(surfaceId) {
        return surfaceService.normalizeSurfaceId(surfaceId);
    }
    function isSurfaceOpen(surfaceId) {
        return surfaceService.isSurfaceOpen(surfaceId);
    }
    function surfaceMeta(surfaceId) {
        return surfaceService.surfaceMeta(surfaceId);
    }
    function surfaceKind(surfaceId) {
        return surfaceService.surfaceKind(surfaceId);
    }
    function barOwnsSurface(context, screenRef, barId) {
        return surfaceService.barOwnsSurface(context, screenRef, barId);
    }
    function surfaceContextFor(surfaceId, screenRef, barId) {
        return surfaceService.surfaceContextFor(surfaceId, screenRef, barId);
    }
    function isSurfacePresentedOnBar(surfaceId, screenRef, barId) {
        return surfaceService.isSurfacePresentedOnBar(surfaceId, screenRef, barId);
    }
    function clearClosingSurface() {
        surfaceService.clearClosingSurface();
    }
    function clearPendingSurface() {
        surfaceService.clearPendingSurface();
    }
    function defaultSurfaceContext(surfaceId, preferredScreen) {
        return surfaceService.defaultSurfaceContext(surfaceId, preferredScreen);
    }
    function resolveSurfaceContext(surfaceId, context) {
        return surfaceService.resolveSurfaceContext(surfaceId, context);
    }
    function commitSurfaceOpen(surfaceId, surfaceContext) {
        surfaceService.commitSurfaceOpen(surfaceId, surfaceContext);
    }
    function beginPopupSwitch(surfaceId, surfaceContext) {
        surfaceService.beginPopupSwitch(surfaceId, surfaceContext);
    }
    function openSurface(surfaceId, context) {
        return surfaceService.openSurface(surfaceId, context);
    }
    function closeSurface(surfaceId) {
        return surfaceService.closeSurface(surfaceId);
    }
    function closeAllSurfaces() {
        surfaceService.closeAllSurfaces();
    }
    function toggleSurface(surfaceId, context) {
        return surfaceService.toggleSurface(surfaceId, context);
    }

    // Backward-compatibility helper for older callers.
    function togglePanel(panel) {
        return toggleSurface(panel);
    }

    function popupAnchorX(context, popupWidth, screenWidth) {
        return surfaceService.popupAnchorX(context, popupWidth, screenWidth);
    }
    function popupAnchorY(context, popupHeight, screenHeight) {
        return surfaceService.popupAnchorY(context, popupHeight, screenHeight);
    }
    function popupMaxHeight(screenHeight) {
        return surfaceService.popupMaxHeight(screenHeight);
    }
    function surfacePanelLayout(context, preferredWidth) {
        return surfaceService.surfacePanelLayout(context, preferredWidth);
    }

    function toggleNotifications() {
        toggleSurface("notifCenter");
    }
    function toggleControls() {
        toggleSurface("controlCenter");
    }
    function toggleNetworkMenu() {
        toggleSurface("networkMenu");
    }
    function toggleAudioMenu() {
        toggleSurface("audioMenu");
    }
    function toggleClipboardMenu() {
        toggleSurface("clipboardMenu");
    }
    function toggleRecordingMenu() {
        toggleSurface("recordingMenu");
    }
    function toggleMusicMenu() {
        toggleSurface("musicMenu");
    }
    function toggleBatteryMenu() {
        toggleSurface("batteryMenu");
    }
    function toggleWeatherMenu() {
        toggleSurface("weatherMenu");
    }
    function toggleSshMenu() {
        toggleSurface("sshMenu");
    }
    function toggleDateTimeMenu() {
        toggleSurface("dateTimeMenu");
    }
    function toggleSystemStatsMenu() {
        toggleSurface("systemStatsMenu");
    }
    function toggleSystemMonitor() {
        toggleSurface("systemMonitor");
    }
    function toggleBluetoothMenu() {
        toggleSurface("bluetoothMenu");
    }
    function togglePrinterMenu() {
        toggleSurface("printerMenu");
    }
    function togglePrivacyMenu() {
        toggleSurface("privacyMenu");
    }
    function toggleNotepad() {
        toggleSurface("notepad");
    }
    function toggleColorPicker() {
        toggleSurface("colorPicker");
    }
    function toggleDisplayConfig() {
        toggleSurface("displayConfig");
    }
    function toggleFileBrowser() {
        toggleSurface("fileBrowser");
    }
    function toggleScreenshotMenu() {
        toggleSurface("screenshotMenu");
    }
    function toggleCavaPopup() {
        toggleSurface("cavaPopup");
    }
    function toggleAiChat() {
        toggleSurface("aiChat");
    }

    IpcHandler {
        target: "Shell"

        // Generic surface operations — preferred for new callers:
        //   quickshell ipc call Shell toggleSurface audioMenu
        function toggleSurface(surfaceId: string) {
            root.toggleSurface(surfaceId);
        }
        function openSurface(surfaceId: string) {
            root.openSurface(surfaceId);
        }
        function closeAllSurfaces() {
            root.closeAllSurfaces();
        }
        function closeAll() {
            root.closeAllSurfaces();
        }
        function reloadConfig() {
            Config.load();
        }
        function showAltTab() {
            if (altTabSwitcher.item && altTabSwitcher.item.show)
                altTabSwitcher.item.show();
        }

        // Per-surface toggle methods — kept for backward compatibility with
        // existing keybindings and scripts (e.g. `quickshell ipc call Shell toggleAudioMenu`).
        function toggleNotifications() {
            root.toggleSurface("notifCenter");
        }
        function toggleControls() {
            root.toggleSurface("controlCenter");
        }
        function toggleNetworkMenu() {
            root.toggleSurface("networkMenu");
        }
        function toggleAudioMenu() {
            root.toggleSurface("audioMenu");
        }
        function toggleBluetoothMenu() {
            root.toggleSurface("bluetoothMenu");
        }
        function togglePrinterMenu() {
            root.toggleSurface("printerMenu");
        }
        function togglePrivacyMenu() {
            root.toggleSurface("privacyMenu");
        }
        function toggleClipboardMenu() {
            root.toggleSurface("clipboardMenu");
        }
        function toggleRecordingMenu() {
            root.toggleSurface("recordingMenu");
        }
        function toggleMusicMenu() {
            root.toggleSurface("musicMenu");
        }
        function toggleBatteryMenu() {
            root.toggleSurface("batteryMenu");
        }
        function toggleWeatherMenu() {
            root.toggleSurface("weatherMenu");
        }
        function toggleSshMenu() {
            root.toggleSurface("sshMenu");
        }
        function toggleDateTimeMenu() {
            root.toggleSurface("dateTimeMenu");
        }
        function toggleSystemStatsMenu() {
            root.toggleSurface("systemStatsMenu");
        }
        function toggleSystemMonitor() {
            root.toggleSurface("systemMonitor");
        }
        function toggleNotepad() {
            root.toggleSurface("notepad");
        }
        function toggleColorPicker() {
            root.toggleSurface("colorPicker");
        }
        function toggleDisplayConfig() {
            root.toggleSurface("displayConfig");
        }
        function toggleFileBrowser() {
            root.toggleSurface("fileBrowser");
        }
        function togglePowermenu() {
            root.toggleSurface("powerMenu");
        }
        function toggleScreenshotMenu() {
            root.toggleSurface("screenshotMenu");
        }
        function toggleCavaPopup() {
            root.toggleSurface("cavaPopup");
        }
        function toggleAiChat() {
            root.toggleSurface("aiChat");
        }
    }

    // Global shortcuts (outside Variants to avoid duplicate registration)
    Shortcut {
        sequence: "Meta+S"
        onActivated: settingsHub.toggle()
    }

    Shortcut {
        sequence: "Meta+C"
        onActivated: root.toggleControls()
    }

    Shortcut {
        sequence: "Meta+N"
        onActivated: root.toggleNotifications()
    }

    // Ensure ThemeService and HookService initialize early
    Component.onCompleted: {
        void ThemeService.activeThemeId;
        void HookService;
    }

    NotificationManager {
        id: notifManager
    }

    ShellBarLayer {
        shellRoot: root
        surfaceService: surfaceService
        notifManager: notifManager
    }

    // Show a toast when Niri reports a config load failure
    Connections {
        target: NiriService
        enabled: CompositorAdapter.isNiri && NiriService.available
        function onConfigLoadFinished(ok, error) {
            if (!ok)
                ToastService.showError("Niri config error", error || "Failed to load config");
        }
        function onWindowUrgentChanged() {
            var wins = NiriService.windows;
            for (var i = 0; i < wins.length; i++) {
                if (wins[i].is_urgent) {
                    ToastService.showNotice(
                        wins[i].app_id || "Window",
                        (wins[i].title || "A window") + " needs attention"
                    );
                    break;
                }
            }
        }
    }

    Osd {
        id: osd
    }

    MediaOsd {
        id: mediaOsd
    }

    WorkspaceOsd {
        id: workspaceOsd
    }

    Loader {
        id: overview
        active: CompositorAdapter.supportsOverview
        source: CompositorAdapter.isNiri ? "launcher/OverviewNiri.qml" : "launcher/Overview.qml"
    }

    Loader {
        id: altTabSwitcher
        active: CompositorAdapter.isNiri && NiriService.available
        source: "launcher/AltTabSwitcher.qml"
    }

    Notifications {
        id: popups
        manager: notifManager
    }

    LazyLoader {
        active: root.notifCenterVisible
        NotificationCenter {
            id: center
            readonly property var layoutState: root.surfacePanelLayout(root.activeSurfaceContext, Config.controlCenterWidth)
            screen: layoutState.screen
            manager: notifManager
            showContent: root.notifCenterVisible
            surfaceEdge: layoutState.edge
            panelWidth: layoutState.width
            panelHeight: layoutState.height
            panelX: layoutState.x
            reservedTop: layoutState.top
            reservedRight: layoutState.right
            reservedBottom: layoutState.bottom
            reservedLeft: layoutState.left
            onCloseRequested: root.closeSurface("notifCenter")
        }
    }

    ControlCenter {
        id: controls
        readonly property var layoutState: root.surfacePanelLayout(root.activeSurfaceContext, Config.controlCenterWidth)
        screen: layoutState.screen
        manager: notifManager
        showContent: root.controlCenterVisible
        surfaceEdge: layoutState.edge
        panelWidth: layoutState.width
        panelHeight: layoutState.height
        panelX: layoutState.x
        reservedTop: layoutState.top
        reservedRight: layoutState.right
        reservedBottom: layoutState.bottom
        reservedLeft: layoutState.left
        onCloseRequested: root.closeSurface("controlCenter")
    }

    ShellFileFlow {
        id: fileFlow
        shellRoot: root
        fileBrowser: fileBrowser
        settingsHub: settingsHub
        notepad: notepad
        lazyLoaderSettleMs: root.lazyLoaderSettleMs
        settingsHubReopenMs: root.settingsHubReopenMs
    }

    LazyLoader {
        active: root.systemMonitorVisible
        SystemMonitorPanel {
            id: systemMonitor
            screen: root.currentSurfaceScreen()
            showContent: root.systemMonitorVisible
            onCloseRequested: root.closeSurface("systemMonitor")
        }
    }

    LazyLoader {
        active: root.notepadVisible
        Notepad {
            id: notepad
            screen: root.currentSurfaceScreen()
            showContent: root.notepadVisible
            onCloseRequested: root.closeSurface("notepad")
            onOpenFileRequested: fileFlow.openFileBrowserForNotepad("open")
            onSaveAsRequested: content => {
                fileFlow.pendingNotepadContent = content;
                fileFlow.openFileBrowserForNotepad("save");
            }
        }
    }

    LazyLoader {
        active: root.aiChatVisible
        AiChat {
            id: aiChat
            screen: root.currentSurfaceScreen()
            showContent: root.aiChatVisible
            onCloseRequested: root.closeSurface("aiChat")
        }
    }

    LazyLoader {
        active: root.powerMenuVisible
        Powermenu {
            id: powermenu
            screen: root.currentSurfaceScreen()
            isVisible: root.powerMenuVisible
        }
    }

    Launcher {
        id: launcher
    }

    SettingsHub {
        id: settingsHub
        interactionBlocked: root.fileBrowserVisible
        onBrowseWallpaper: monitorName => fileFlow.browseWallpaper(monitorName)
        onPickWallpaperFolder: fileFlow.pickWallpaperFolder()
    }

    LazyLoader {
        active: root.colorPickerVisible
        ColorPicker {
            id: colorPicker
            isOpen: root.colorPickerVisible
            onIsOpenChanged: if (!isOpen)
                root.closeSurface("colorPicker")
        }
    }

    LazyLoader {
        active: root.displayConfigVisible
        DisplayConfig {
            id: displayConfig
            isOpen: root.displayConfigVisible
            onIsOpenChanged: if (!isOpen)
                root.closeSurface("displayConfig")
        }
    }

    FileBrowser {
        id: fileBrowser
        isOpen: root.fileBrowserVisible
        onIsOpenChanged: fileFlow.handleFileBrowserOpenChanged(isOpen)
        onFileSelected: filePath => fileFlow.handleFileSelected(filePath)
        onFolderSelected: folderPath => fileFlow.handleFolderSelected(folderPath)
    }

    NativeLock {
        id: lockscreen
    }

    ShellDecorLayers {
        showBorders: Config.showScreenBorders
    }
}
