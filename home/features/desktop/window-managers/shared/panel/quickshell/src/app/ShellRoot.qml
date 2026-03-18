//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import "../features/ai"
import "../features/bar"
import "../features/color-picker"
import "../features/control-center"
import "../features/display"
import "../features/lock"
import "../features/launcher"
import "../features/media"
import "../features/osd"
import "../features/cheatsheet"
import "../features/osk"
import "../features/notifications"
import "../features/power"
import "../features/system/surfaces"
import "../features/settings"
import "../features/workspace"
import "../services"
import "../shell"

Scope {
    id: root

    SurfaceService {
        id: surfaceService
    }

    // Canonical UI state: only one closable surface is active at a time.
    property alias activeSurfaceId: surfaceService.activeSurfaceId
    property alias activeSurfaceContext: surfaceService.activeSurfaceContext

    // ── Named timing constants ─────────────────
    // Time to wait for LazyLoader to create FileBrowser before calling open().
    readonly property int lazyLoaderSettleMs: 50
    // Delay before re-opening SettingsHub after FileBrowser closes, avoids
    // the same click event toggling SettingsHub back off immediately.
    readonly property int settingsHubReopenMs: 130

    readonly property bool notifCenterVisible: root.isSurfaceOpen("notifCenter")
    readonly property bool controlCenterVisible: root.isSurfaceOpen("controlCenter")
    readonly property bool networkMenuVisible: root.isSurfaceOpen("networkMenu")
    readonly property bool vpnMenuVisible: root.isSurfaceOpen("vpnMenu")
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
    function isSurfaceOpen(surfaceId) {
        return surfaceService.isSurfaceOpen(surfaceId);
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
        function isSurfaceOpen(surfaceId: string): bool {
            return root.isSurfaceOpen(surfaceId);
        }
        function closeAllSurfaces() {
            root.closeAllSurfaces();
        }
        function closeAll() {
            root.closeAllSurfaces();
        }
        // Emergency escape: closes all surfaces, forces launcher closed,
        // and forces overview closed locally (bypasses Niri IPC).
        // Bind this to a compositor hotkey as a last resort:
        //   quickshell ipc call Shell panicClose
        function panicClose() {
            root.closeAllSurfaces();
            launcher.close();
            osk.close();
            if (overview)
                overview.forceClose();
            if (altTabSwitcher.item && altTabSwitcher.item.hide)
                altTabSwitcher.item.hide();
        }
        function reloadConfig() {
            Config.load();
        }
        function showAltTab() {
            if (altTabSwitcher.item && altTabSwitcher.item.show)
                altTabSwitcher.item.show();
        }
    }

    // Global shortcuts (outside Variants to avoid duplicate registration)
    // NOTE: These are standard focus-dependent shortcuts. Since Quickshell layers are
    // typically configured with WlrKeyboardFocus.None, these will only work when
    // another Quickshell window (like the Launcher) is focused.
    // For global system-wide hotkeys, these MUST be mirrored in the compositor config
    // (e.g., ~/.config/niri/config.kdl) calling into Quickshell IPC.
    Shortcut {
        sequence: "Meta+S"
        onActivated: settingsHub.toggle()
    }

    Shortcut {
        sequence: "Meta+C"
        onActivated: root.toggleSurface("controlCenter")
    }

    Shortcut {
        sequence: "Meta+N"
        onActivated: root.toggleSurface("notifCenter")
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

    LazyLoader {
        id: overviewLoader
        active: CompositorAdapter.supportsOverview

        Overview {
            id: overview
        }
    }

    Loader {
        id: altTabSwitcher
        active: CompositorAdapter.isNiri && NiriService.available
        sourceComponent: altTabSwitcherComponent
    }

    Component {
        id: altTabSwitcherComponent
        AltTabSwitcher {}
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
            panelWidth: layoutState.width
            reservedTop: layoutState.top
            reservedRight: layoutState.right
            reservedBottom: layoutState.bottom
            onCloseRequested: root.closeSurface("notifCenter")
        }
    }

    ControlCenter {
        id: controls
        readonly property var layoutState: root.surfacePanelLayout(root.activeSurfaceContext, Config.controlCenterWidth)
        screen: layoutState.screen
        manager: notifManager
        showContent: root.controlCenterVisible
        panelWidth: layoutState.width
        reservedTop: layoutState.top
        reservedRight: layoutState.right
        reservedBottom: layoutState.bottom
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

    Cheatsheet {
        id: cheatsheet
    }

    OnScreenKeyboard {
        id: osk
    }

    NativeLock {
        id: lockscreen
    }

    ShellDecorLayers {
        showBorders: Config.showScreenBorders
    }
}
