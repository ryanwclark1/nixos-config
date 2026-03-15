//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "bar"
import "launcher"
import "menu"
import "modules"
import "notifications"
import "services"
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
    readonly property bool dateTimeMenuVisible: root.isSurfaceOpen("dateTimeMenu")
    readonly property bool systemStatsMenuVisible: root.isSurfaceOpen("systemStatsMenu")
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
    function toggleDateTimeMenu() {
        toggleSurface("dateTimeMenu");
    }
    function toggleSystemStatsMenu() {
        toggleSurface("systemStatsMenu");
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
        function toggleDateTimeMenu() {
            root.toggleSurface("dateTimeMenu");
        }
        function toggleSystemStatsMenu() {
            root.toggleSurface("systemStatsMenu");
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

    // Per-screen bars + popup menus
    Variants {
        model: Quickshell.screens

        delegate: Component {
            Item {
                id: screenBars
                required property ShellScreen modelData
                property var bars: Config.barsForScreen(modelData)

                Variants {
                    model: screenBars.bars

                    delegate: Component {
                        PanelWindow {
                            id: barWindow
                            required property var modelData
                            readonly property var barConfig: modelData
                            readonly property bool vertical: Config.isVerticalBar(barConfig.position)
                            readonly property int marginValue: Config.floatingInset(barConfig)
                            readonly property int thicknessValue: Config.barThickness(barConfig)
                            screen: screenBars.modelData

                            function surfaceContext(surfaceId) {
                                return root.surfaceContextFor(surfaceId, screenBars.modelData, barConfig.id);
                            }

                            function popupVisible(surfaceId) {
                                return root.isSurfacePresentedOnBar(surfaceId, screenBars.modelData, barConfig.id);
                            }

                            function popupPreferredEdge(surfaceId) {
                                var context = surfaceContext(surfaceId);
                                return context ? context.position : barConfig.position;
                            }

                            function popupAnchorXFor(surfaceId, popupWidth) {
                                return root.popupAnchorX(surfaceContext(surfaceId), popupWidth, screen ? screen.width : width);
                            }

                            function popupAnchorYFor(surfaceId, popupHeight) {
                                return root.popupAnchorY(surfaceContext(surfaceId), popupHeight, screen ? screen.height : height);
                            }

                            anchors {
                                top: barConfig.position === "top" || barConfig.position === "left" || barConfig.position === "right"
                                bottom: barConfig.position === "bottom" || barConfig.position === "left" || barConfig.position === "right"
                                left: barConfig.position === "left" || barConfig.position === "top" || barConfig.position === "bottom"
                                right: barConfig.position === "right" || barConfig.position === "top" || barConfig.position === "bottom"
                            }
                            margins {
                                top: (barConfig.position === "top" || (vertical && barConfig.floating)) ? marginValue : 0
                                bottom: (barConfig.position === "bottom" || (vertical && barConfig.floating)) ? marginValue : 0
                                left: (barConfig.position === "left" || (!vertical && barConfig.floating)) ? marginValue : 0
                                right: (barConfig.position === "right" || (!vertical && barConfig.floating)) ? marginValue : 0
                            }

                            color: "transparent"
                            implicitWidth: vertical ? panel.implicitWidth : 0
                            implicitHeight: vertical ? 0 : panel.implicitHeight

                            WlrLayershell.layer: WlrLayer.Top
                            WlrLayershell.namespace: "quickshell-bar-" + barConfig.id
                            WlrLayershell.exclusiveZone: panel.isAutoHidden ? 0 : (vertical ? width + marginValue : height + marginValue)
                            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                            Panel {
                                id: panel
                                anchors.fill: parent
                                manager: notifManager
                                anchorWindow: barWindow
                                screenRef: screenBars.modelData
                                barConfig: barWindow.barConfig
                                activeSurfaceId: root.barOwnsSurface(root.activeSurfaceContext, screenBars.modelData, barWindow.barConfig.id) ? root.activeSurfaceId : ""
                                onSurfaceRequested: (surfaceId, context) => root.toggleSurface(surfaceId, context)
                                onContextMenuRequested: (actions, rect) => barContextPopup.show(actions, rect, barWindow.barConfig.position, barWindow)
                            }

                            BluetoothMenu {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("bluetoothMenu")
                                anchor.rect.x: barWindow.popupAnchorXFor("bluetoothMenu", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("bluetoothMenu", height)
                                wantVisible: barWindow.popupVisible("bluetoothMenu")
                                onCloseRequested: root.closeSurface("bluetoothMenu")
                            }

                            AudioMenu {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("audioMenu")
                                anchor.rect.x: barWindow.popupAnchorXFor("audioMenu", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("audioMenu", height)
                                wantVisible: barWindow.popupVisible("audioMenu")
                                onCloseRequested: root.closeSurface("audioMenu")
                            }

                            NetworkMenu {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("networkMenu")
                                anchor.rect.x: barWindow.popupAnchorXFor("networkMenu", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("networkMenu", height)
                                wantVisible: barWindow.popupVisible("networkMenu")
                                onCloseRequested: root.closeSurface("networkMenu")
                            }

                            ClipboardMenu {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("clipboardMenu")
                                anchor.rect.x: barWindow.popupAnchorXFor("clipboardMenu", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("clipboardMenu", height)
                                wantVisible: barWindow.popupVisible("clipboardMenu")
                                onCloseRequested: root.closeSurface("clipboardMenu")
                            }

                            RecordingMenu {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("recordingMenu")
                                anchor.rect.x: barWindow.popupAnchorXFor("recordingMenu", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("recordingMenu", height)
                                wantVisible: barWindow.popupVisible("recordingMenu")
                                onCloseRequested: root.closeSurface("recordingMenu")
                            }

                            PrivacyMenu {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("privacyMenu")
                                anchor.rect.x: barWindow.popupAnchorXFor("privacyMenu", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("privacyMenu", height)
                                wantVisible: barWindow.popupVisible("privacyMenu")
                                onCloseRequested: root.closeSurface("privacyMenu")
                            }

                            MusicMenu {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("musicMenu")
                                anchor.rect.x: barWindow.popupAnchorXFor("musicMenu", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("musicMenu", height)
                                wantVisible: barWindow.popupVisible("musicMenu")
                                onCloseRequested: root.closeSurface("musicMenu")
                            }

                            BatteryMenu {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("batteryMenu")
                                anchor.rect.x: barWindow.popupAnchorXFor("batteryMenu", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("batteryMenu", height)
                                wantVisible: barWindow.popupVisible("batteryMenu")
                                onCloseRequested: root.closeSurface("batteryMenu")
                            }

                            WeatherMenu {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("weatherMenu")
                                implicitHeight: Math.min(600, root.popupMaxHeight((barWindow.screen && barWindow.screen.height) ? barWindow.screen.height : barWindow.height))
                                anchor.rect.x: barWindow.popupAnchorXFor("weatherMenu", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("weatherMenu", implicitHeight)
                                wantVisible: barWindow.popupVisible("weatherMenu")
                                onCloseRequested: root.closeSurface("weatherMenu")
                            }

                            DateTimeMenu {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("dateTimeMenu")
                                implicitHeight: Math.min(560, root.popupMaxHeight((barWindow.screen && barWindow.screen.height) ? barWindow.screen.height : barWindow.height))
                                anchor.rect.x: barWindow.popupAnchorXFor("dateTimeMenu", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("dateTimeMenu", implicitHeight)
                                wantVisible: barWindow.popupVisible("dateTimeMenu")
                                onCloseRequested: root.closeSurface("dateTimeMenu")
                            }

                            SystemStatsMenu {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("systemStatsMenu")
                                anchor.rect.x: barWindow.popupAnchorXFor("systemStatsMenu", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("systemStatsMenu", height)
                                wantVisible: barWindow.popupVisible("systemStatsMenu")
                                onCloseRequested: root.closeSurface("systemStatsMenu")
                            }

                            PrinterMenu {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("printerMenu")
                                anchor.rect.x: barWindow.popupAnchorXFor("printerMenu", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("printerMenu", height)
                                wantVisible: barWindow.popupVisible("printerMenu")
                                onCloseRequested: root.closeSurface("printerMenu")
                            }

                            ScreenshotMenu {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("screenshotMenu")
                                anchor.rect.x: barWindow.popupAnchorXFor("screenshotMenu", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("screenshotMenu", height)
                                wantVisible: barWindow.popupVisible("screenshotMenu")
                                onCloseRequested: root.closeSurface("screenshotMenu")
                            }

                            CavaPopup {
                                anchor.window: barWindow
                                preferredEdge: barWindow.popupPreferredEdge("cavaPopup")
                                anchor.rect.x: barWindow.popupAnchorXFor("cavaPopup", width)
                                anchor.rect.y: barWindow.popupAnchorYFor("cavaPopup", height)
                                wantVisible: barWindow.popupVisible("cavaPopup")
                                cavaData: panel.fullCavaData
                                onCloseRequested: root.closeSurface("cavaPopup")
                            }
                        }
                    }
                }
            }
        }
    }

    BarContextPopup {
        id: barContextPopup
    }

    Connections {
        target: surfaceService
        function onActiveSurfaceIdChanged() { barContextPopup.close(); }
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

    Dock {
        id: dock
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

    // --- File operation coordination ---
    // Tracks what triggered the FileBrowser so we can route fileSelected back
    property string _fileBrowserCaller: "" // "notepad-open", "notepad-save", "wallpaper", "wallpaper-folder"
    property string _pendingNotepadContent: "" // content to save for notepad-save
    property string _wallpaperMonitor: "" // monitor name for wallpaper browse
    property bool _reopenSettingsHubAfterFileBrowser: false

    function _openFileBrowserForNotepad(mode) {
        _reopenSettingsHubTimer.stop();
        _fileBrowserCaller = mode === "save" ? "notepad-save" : "notepad-open";
        root.openSurface("fileBrowser");
        // FileBrowser is now inside LazyLoader — need to defer open() call
        _fileBrowserOpenTimer.opMode = mode;
        _fileBrowserOpenTimer.restart();
    }

    Timer {
        id: _fileBrowserOpenTimer
        interval: root.lazyLoaderSettleMs
        property string opMode: "open"
        onTriggered: {
            if (fileBrowser) {
                var home = Quickshell.env("HOME") || "/home";
                var wallpaperDir = WallpaperService.normalizedWallpaperDir(Config.wallpaperDefaultFolder);
                if (opMode === "__wallpaper__") {
                    fileBrowser.open(wallpaperDir, [
                        {
                            label: "Images",
                            extensions: ["jpg", "jpeg", "png", "webp", "gif"]
                        }
                    ], "open");
                } else if (opMode === "__wallpaper_folder__") {
                    fileBrowser.open(wallpaperDir, [], "folder");
                } else if (opMode === "open") {
                    fileBrowser.open(home, [
                        {
                            label: "Text Files",
                            extensions: ["txt", "md", "json", "qml", "conf", "log", "nix", "sh", "toml", "yaml", "yml"]
                        }
                    ], "open");
                } else {
                    fileBrowser.open(home, [
                        {
                            label: "Text Files",
                            extensions: ["txt", "md"]
                        }
                    ], "save");
                }
            }
        }
    }

    // Avoid reactivating SettingsHub in the same click cycle as modal close.
    Timer {
        id: _reopenSettingsHubTimer
        interval: root.settingsHubReopenMs
        repeat: false
        onTriggered: {
            if (root._reopenSettingsHubAfterFileBrowser && !root.fileBrowserVisible) {
                settingsHub.open();
                root._reopenSettingsHubAfterFileBrowser = false;
            }
        }
    }

    LazyLoader {
        active: root.notepadVisible
        Notepad {
            id: notepad
            screen: root.currentSurfaceScreen()
            showContent: root.notepadVisible
            onCloseRequested: root.closeSurface("notepad")
            onOpenFileRequested: root._openFileBrowserForNotepad("open")
            onSaveAsRequested: content => {
                root._pendingNotepadContent = content;
                root._openFileBrowserForNotepad("save");
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
        onBrowseWallpaper: monitorName => {
            _reopenSettingsHubTimer.stop();
            root._fileBrowserCaller = "wallpaper";
            root._wallpaperMonitor = monitorName;
            root._reopenSettingsHubAfterFileBrowser = settingsHub.isOpen;
            if (settingsHub.isOpen)
                settingsHub.close();
            root.openSurface("fileBrowser");
            _fileBrowserOpenTimer.opMode = "__wallpaper__";
            _fileBrowserOpenTimer.restart();
        }
        onPickWallpaperFolder: {
            _reopenSettingsHubTimer.stop();
            root._fileBrowserCaller = "wallpaper-folder";
            root._reopenSettingsHubAfterFileBrowser = settingsHub.isOpen;
            if (settingsHub.isOpen)
                settingsHub.close();
            root.openSurface("fileBrowser");
            _fileBrowserOpenTimer.opMode = "__wallpaper_folder__";
            _fileBrowserOpenTimer.restart();
        }
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
        onIsOpenChanged: {
            if (!isOpen) {
                root.closeSurface("fileBrowser");
                if (root._reopenSettingsHubAfterFileBrowser) {
                    _reopenSettingsHubTimer.restart();
                }
            }
        }
        onFileSelected: filePath => {
            root.closeSurface("fileBrowser");
            if (root._fileBrowserCaller === "notepad-open") {
                // Re-open notepad if it was closed, then load file
                root.openSurface("notepad");
                // Defer until notepad is created by LazyLoader
                Qt.callLater(function () {
                    if (notepad)
                        notepad.loadFile(filePath);
                });
            } else if (root._fileBrowserCaller === "notepad-save") {
                root.openSurface("notepad");
                Qt.callLater(function () {
                    if (notepad)
                        notepad.saveToFile(filePath, root._pendingNotepadContent);
                });
            } else if (root._fileBrowserCaller === "wallpaper") {
                Quickshell.execDetached(["sh", "-c", "swww img '" + filePath.replace(/'/g, "'\\''") + "'" + (root._wallpaperMonitor ? " --outputs '" + root._wallpaperMonitor + "'" : "") + " --transition-type grow --transition-duration 1.5"]);
            }
            root._fileBrowserCaller = "";
            root._pendingNotepadContent = "";
        }
        onFolderSelected: folderPath => {
            root.closeSurface("fileBrowser");
            if (root._fileBrowserCaller === "wallpaper-folder") {
                Config.wallpaperDefaultFolder = folderPath;
                WallpaperService.scanWallpapers();
            }
            root._fileBrowserCaller = "";
            root._pendingNotepadContent = "";
        }
    }

    NativeLock {
        id: lockscreen
    }

    // Per-screen desktop background + widgets
    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                required property ShellScreen modelData
                screen: modelData

                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }
                color: "transparent"
                exclusiveZone: -1
                WlrLayershell.layer: WlrLayer.Background
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                DesktopWidgets {
                    id: desktopWidgets
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.leftMargin: 80
                    anchors.topMargin: 120
                }
            }
        }
    }

    // Per-screen toast overlay
    Variants {
        model: Quickshell.screens

        delegate: Component {
            ToastOverlay {
                required property ShellScreen modelData
                screenModel: modelData
            }
        }
    }

    Corners {
        id: screenCorners
    }

    // Per-screen decorative border
    Variants {
        model: Quickshell.screens

        delegate: Component {
            ScreenBorder {
                required property ShellScreen modelData
                screen: modelData
                visible: Config.showScreenBorders
            }
        }
    }
}
