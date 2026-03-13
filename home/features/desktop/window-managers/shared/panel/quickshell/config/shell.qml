//@ pragma UseQApplication
import Quickshell
import QtQuick
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "bar"
import "launcher"
import "menu"
import "modules"
import "notifications"
import "services"
import "widgets"

Scope {
  id: root

  // Canonical UI state: only one closable surface is active at a time.
  property string activeSurfaceId: ""
  readonly property var knownSurfaces: [
    "notifCenter", "controlCenter", "networkMenu", "audioMenu", "powerMenu",
    "clipboardMenu", "recordingMenu", "musicMenu", "batteryMenu", "weatherMenu",
    "dateTimeMenu", "systemStatsMenu", "bluetoothMenu", "printerMenu", "privacyMenu",
    "notepad", "colorPicker", "displayConfig", "fileBrowser", "cavaPopup"
  ]
  readonly property var legacyPanelToSurface: ({
    "notifCenterVisible": "notifCenter",
    "controlCenterVisible": "controlCenter",
    "networkMenuVisible": "networkMenu",
    "audioMenuVisible": "audioMenu",
    "powerMenuVisible": "powerMenu",
    "clipboardMenuVisible": "clipboardMenu",
    "recordingMenuVisible": "recordingMenu",
    "musicMenuVisible": "musicMenu",
    "batteryMenuVisible": "batteryMenu",
    "weatherMenuVisible": "weatherMenu",
    "dateTimeMenuVisible": "dateTimeMenu",
    "systemStatsMenuVisible": "systemStatsMenu",
    "bluetoothMenuVisible": "bluetoothMenu",
    "printerMenuVisible": "printerMenu",
    "privacyMenuVisible": "privacyMenu",
    "notepadVisible": "notepad",
    "colorPickerVisible": "colorPicker",
    "displayConfigVisible": "displayConfig",
    "fileBrowserVisible": "fileBrowser",
    "cavaPopupVisible": "cavaPopup"
  })

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
  readonly property bool cavaPopupVisible: root.isSurfaceOpen("cavaPopup")

  // Track which screen triggered the current menu (captured at toggle time)
  property var menuScreen: null
  readonly property var activeScreen: (Quickshell.screens && Quickshell.screens.length > 0) ? (Quickshell.cursorScreen || Quickshell.screens[0]) : null

  function normalizeSurfaceId(surfaceId) {
    if (!surfaceId) return "";
    if (knownSurfaces.indexOf(surfaceId) !== -1) return surfaceId;
    if (legacyPanelToSurface[surfaceId]) return legacyPanelToSurface[surfaceId];
    return "";
  }

  function isSurfaceOpen(surfaceId) {
    return root.activeSurfaceId === surfaceId;
  }

  function openSurface(surfaceId) {
    var resolved = normalizeSurfaceId(surfaceId);
    if (!resolved) return false;
    root.activeSurfaceId = resolved;
    root.menuScreen = root.activeScreen;
    return true;
  }

  function closeSurface(surfaceId) {
    if (root.activeSurfaceId !== surfaceId) return false;
    root.activeSurfaceId = "";
    root.menuScreen = null;
    return true;
  }

  function closeAllSurfaces() {
    root.activeSurfaceId = "";
    root.menuScreen = null;
  }

  function toggleSurface(surfaceId) {
    var resolved = normalizeSurfaceId(surfaceId);
    if (!resolved) return false;
    if (root.activeSurfaceId === resolved) {
      closeAllSurfaces();
    } else {
      openSurface(resolved);
    }
    return true;
  }

  // Backward-compatibility helper for older callers.
  function togglePanel(panel) {
    return toggleSurface(panel);
  }

  function popupAnchorX(centerX, popupWidth, windowWidth) {
    return Math.min(Math.max(8, centerX - popupWidth / 2), windowWidth - popupWidth - 8);
  }

  function popupAnchorY(bottomY, popupHeight, windowHeight) {
    // Keep popups below the bar surface to avoid overlap with the panel.
    var minY = Math.max(bottomY + 8, Config.barHeight + 8);
    if (popupHeight === undefined || windowHeight === undefined || windowHeight <= 0)
      return minY;

    // If it would clip at the bottom, move upward as much as possible
    // while still respecting the "never overlap bar" rule.
    if (minY + popupHeight + 8 > windowHeight) {
      var adjusted = windowHeight - popupHeight - 8;
      return Math.max(Config.barHeight + 8, adjusted);
    }

    return minY;
  }

  function popupMaxHeight(windowHeight) {
    if (windowHeight === undefined || windowHeight <= 0)
      return 560;
    return Math.max(320, windowHeight - (Config.barHeight + 16));
  }

  function toggleNotifications() { toggleSurface("notifCenter"); }
  function toggleControls() { toggleSurface("controlCenter"); }
  function toggleNetworkMenu() { toggleSurface("networkMenu"); }
  function toggleAudioMenu() { toggleSurface("audioMenu"); }
  function toggleClipboardMenu() { toggleSurface("clipboardMenu"); }
  function toggleRecordingMenu() { toggleSurface("recordingMenu"); }
  function toggleMusicMenu() { toggleSurface("musicMenu"); }
  function toggleBatteryMenu() { toggleSurface("batteryMenu"); }
  function toggleWeatherMenu() { toggleSurface("weatherMenu"); }
  function toggleDateTimeMenu() { toggleSurface("dateTimeMenu"); }
  function toggleSystemStatsMenu() { toggleSurface("systemStatsMenu"); }
  function toggleBluetoothMenu() { toggleSurface("bluetoothMenu"); }
  function togglePrinterMenu() { toggleSurface("printerMenu"); }
  function togglePrivacyMenu() { toggleSurface("privacyMenu"); }
  function toggleNotepad() { toggleSurface("notepad"); }
  function toggleColorPicker() { toggleSurface("colorPicker"); }
  function toggleDisplayConfig() { toggleSurface("displayConfig"); }
  function toggleFileBrowser() { toggleSurface("fileBrowser"); }
  function toggleCavaPopup() { toggleSurface("cavaPopup"); }

  IpcHandler {
    target: "Shell"
    function toggleNotifications() { root.toggleNotifications(); }
    function toggleControls() { root.toggleControls(); }
    function toggleNetworkMenu() { root.toggleNetworkMenu(); }
    function toggleAudioMenu() { root.toggleAudioMenu(); }
    function toggleBluetoothMenu() { root.toggleBluetoothMenu(); }
    function togglePrinterMenu() { root.togglePrinterMenu(); }
    function togglePrivacyMenu() { root.togglePrivacyMenu(); }
    function toggleClipboardMenu() { root.toggleClipboardMenu(); }
    function toggleRecordingMenu() { root.toggleRecordingMenu(); }
    function toggleMusicMenu() { root.toggleMusicMenu(); }
    function toggleBatteryMenu() { root.toggleBatteryMenu(); }
    function toggleWeatherMenu() { root.toggleWeatherMenu(); }
    function toggleDateTimeMenu() { root.toggleDateTimeMenu(); }
    function toggleSystemStatsMenu() { root.toggleSystemStatsMenu(); }
    function toggleNotepad() { root.toggleNotepad(); }
    function toggleColorPicker() { root.toggleColorPicker(); }
    function toggleDisplayConfig() { root.toggleDisplayConfig(); }
    function toggleFileBrowser() { root.toggleFileBrowser(); }
    function toggleSurface(surfaceId: string) { root.toggleSurface(surfaceId); }
    function openSurface(surfaceId: string) { root.openSurface(surfaceId); }
    function closeAllSurfaces() { root.closeAllSurfaces(); }

    function closeAll() {
      root.closeAllSurfaces();
    }

    function togglePowermenu() {
      root.toggleSurface("powerMenu");
    }

    function reloadConfig() {
      Config.load();
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

  // Ensure ThemeService initializes early (loads manifest + applies saved theme)
  Component.onCompleted: { void ThemeService.activeThemeId; }

  NotificationManager {
    id: notifManager
  }

  // Per-screen bar + popup menus
  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        id: barWindow
        required property ShellScreen modelData
        screen: modelData

        // Helper: is this the screen where the user opened a menu?
        readonly property bool isMenuScreen: root.menuScreen === modelData

        anchors {
          top: true
          left: Config.barFloating
          right: Config.barFloating
        }
        margins {
          top: Config.barFloating ? Config.barMargin : 0
          left: Config.barFloating ? Config.barMargin : 0
          right: Config.barFloating ? Config.barMargin : 0
        }

        color: "transparent"
        implicitHeight: Config.barHeight

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell"
        WlrLayershell.exclusiveZone: Config.barHeight
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        Panel {
          id: panel
          anchors.fill: parent
          manager: notifManager
          anchorWindow: barWindow
          onNotifClicked: root.toggleNotifications()
          onNetworkClicked: root.toggleNetworkMenu()
          onAudioClicked: root.toggleAudioMenu()
          onCommandClicked: root.toggleControls()
          onMusicClicked: root.toggleMusicMenu()
          onRecordingClicked: root.toggleRecordingMenu()
          onPrivacyClicked: root.togglePrivacyMenu()
          onBatteryClicked: root.toggleBatteryMenu()
          onClipboardClicked: root.toggleClipboardMenu()
          onBluetoothClicked: root.toggleBluetoothMenu()
          onPrinterClicked: root.togglePrinterMenu()
          onWeatherClicked: root.toggleWeatherMenu()
          onDateTimeClicked: root.toggleDateTimeMenu()
          onSystemStatsClicked: root.toggleSystemStatsMenu()
          onNotepadClicked: root.toggleNotepad()
          onCavaClicked: root.toggleCavaPopup()
        }

        // PopupWindow menus — anchored to this screen's bar.
        // Each BasePopupMenu self-manages deferred unmapping via wantVisible.
        BluetoothMenu {
          anchor.window: barWindow
          anchor.rect.x: root.popupAnchorX(panel.btTriggerCenterX, width, barWindow.width)
          anchor.rect.y: root.popupAnchorY(panel.btTriggerBottomY)
          wantVisible: root.bluetoothMenuVisible && barWindow.isMenuScreen
          onCloseRequested: root.closeSurface("bluetoothMenu")
        }

        AudioMenu {
          anchor.window: barWindow
          anchor.rect.x: root.popupAnchorX(panel.audioTriggerCenterX, width, barWindow.width)
          anchor.rect.y: root.popupAnchorY(panel.audioTriggerBottomY)
          wantVisible: root.audioMenuVisible && barWindow.isMenuScreen
          onCloseRequested: root.closeSurface("audioMenu")
        }

        NetworkMenu {
          anchor.window: barWindow
          anchor.rect.x: root.popupAnchorX(panel.networkTriggerCenterX, width, barWindow.width)
          anchor.rect.y: root.popupAnchorY(panel.networkTriggerBottomY)
          wantVisible: root.networkMenuVisible && barWindow.isMenuScreen
          onCloseRequested: root.closeSurface("networkMenu")
        }

        ClipboardMenu {
          anchor.window: barWindow
          anchor.rect.x: root.popupAnchorX(panel.clipboardTriggerCenterX, width, barWindow.width)
          anchor.rect.y: root.popupAnchorY(panel.clipboardTriggerBottomY)
          wantVisible: root.clipboardMenuVisible && barWindow.isMenuScreen
          onCloseRequested: root.closeSurface("clipboardMenu")
        }

        RecordingMenu {
          anchor.window: barWindow
          anchor.rect.x: root.popupAnchorX(panel.recordingTriggerCenterX, width, barWindow.width)
          anchor.rect.y: root.popupAnchorY(panel.recordingTriggerBottomY)
          wantVisible: root.recordingMenuVisible && barWindow.isMenuScreen
          onCloseRequested: root.closeSurface("recordingMenu")
        }

        PrivacyMenu {
          anchor.window: barWindow
          anchor.rect.x: root.popupAnchorX(panel.privacyTriggerCenterX, width, barWindow.width)
          anchor.rect.y: root.popupAnchorY(panel.privacyTriggerBottomY)
          wantVisible: root.privacyMenuVisible && barWindow.isMenuScreen
          onCloseRequested: root.closeSurface("privacyMenu")
        }

        MusicMenu {
          anchor.window: barWindow
          anchor.rect.x: root.popupAnchorX(panel.musicTriggerCenterX, width, barWindow.width)
          anchor.rect.y: root.popupAnchorY(panel.musicTriggerBottomY)
          wantVisible: root.musicMenuVisible && barWindow.isMenuScreen
          onCloseRequested: root.closeSurface("musicMenu")
        }

        BatteryMenu {
          anchor.window: barWindow
          anchor.rect.x: root.popupAnchorX(panel.batteryTriggerCenterX, width, barWindow.width)
          anchor.rect.y: root.popupAnchorY(panel.batteryTriggerBottomY)
          wantVisible: root.batteryMenuVisible && barWindow.isMenuScreen
          onCloseRequested: root.closeSurface("batteryMenu")
        }

        WeatherMenu {
          anchor.window: barWindow
          implicitHeight: Math.min(600, root.popupMaxHeight((barWindow.screen && barWindow.screen.height) ? barWindow.screen.height : barWindow.height))
          anchor.rect.x: root.popupAnchorX(panel.weatherTriggerCenterX, width, barWindow.width)
          anchor.rect.y: root.popupAnchorY(
            panel.weatherTriggerBottomY,
            implicitHeight,
            (barWindow.screen && barWindow.screen.height) ? barWindow.screen.height : barWindow.height
          )
          wantVisible: root.weatherMenuVisible && barWindow.isMenuScreen
          onCloseRequested: root.closeSurface("weatherMenu")
        }

        DateTimeMenu {
          anchor.window: barWindow
          implicitHeight: Math.min(560, root.popupMaxHeight((barWindow.screen && barWindow.screen.height) ? barWindow.screen.height : barWindow.height))
          anchor.rect.x: root.popupAnchorX(panel.dateTimeTriggerCenterX, width, barWindow.width)
          anchor.rect.y: root.popupAnchorY(
            panel.dateTimeTriggerBottomY,
            implicitHeight,
            (barWindow.screen && barWindow.screen.height) ? barWindow.screen.height : barWindow.height
          )
          wantVisible: root.dateTimeMenuVisible && barWindow.isMenuScreen
          onCloseRequested: root.closeSurface("dateTimeMenu")
        }

        SystemStatsMenu {
          anchor.window: barWindow
          anchor.rect.x: root.popupAnchorX(panel.systemMonitorCenterX, width, barWindow.width)
          anchor.rect.y: root.popupAnchorY(panel.systemMonitorBottomY)
          wantVisible: root.systemStatsMenuVisible && barWindow.isMenuScreen
          onCloseRequested: root.closeSurface("systemStatsMenu")
        }

        PrinterMenu {
          anchor.window: barWindow
          anchor.rect.x: root.popupAnchorX(panel.printerTriggerCenterX, width, barWindow.width)
          anchor.rect.y: root.popupAnchorY(panel.printerTriggerBottomY)
          wantVisible: root.printerMenuVisible && barWindow.isMenuScreen
          onCloseRequested: root.closeSurface("printerMenu")
        }

        CavaPopup {
          anchor.window: barWindow
          anchor.rect.x: root.popupAnchorX(panel.cavaTriggerCenterX, width, barWindow.width)
          anchor.rect.y: root.popupAnchorY(panel.cavaTriggerBottomY)
          visible: root.cavaPopupVisible && barWindow.isMenuScreen
          cavaData: panel.fullCavaData
          onCloseRequested: root.closeSurface("cavaPopup")
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

  Overview {
    id: overview
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
      manager: notifManager
      showContent: root.notifCenterVisible
      onCloseRequested: root.closeSurface("notifCenter")
    }
  }

  ControlCenter {
    id: controls
    manager: notifManager
    showContent: root.controlCenterVisible
    onCloseRequested: root.closeSurface("controlCenter")
  }

  // --- File operation coordination ---
  // Tracks what triggered the FileBrowser so we can route fileSelected back
  property string _fileBrowserCaller: "" // "notepad-open", "notepad-save", "wallpaper", "wallpaper-folder"
  property string _pendingNotepadContent: "" // content to save for notepad-save
  property string _wallpaperMonitor: "" // monitor name for wallpaper browse
  property bool _reopenSettingsHubAfterFileBrowser: false

  function _openFileBrowserForNotepad(mode) {
    _fileBrowserCaller = mode === "save" ? "notepad-save" : "notepad-open";
    root.openSurface("fileBrowser");
    // FileBrowser is now inside LazyLoader — need to defer open() call
    _fileBrowserOpenTimer.opMode = mode;
    _fileBrowserOpenTimer.restart();
  }

  Timer {
    id: _fileBrowserOpenTimer
    interval: 50
    property string opMode: "open"
    onTriggered: {
      if (fileBrowser) {
        var home = Quickshell.env("HOME") || "/home";
        var wallpaperDir = WallpaperService.normalizedWallpaperDir(Config.wallpaperDefaultFolder);
        if (opMode === "__wallpaper__") {
          fileBrowser.open(wallpaperDir, [{label: "Images", extensions: ["jpg","jpeg","png","webp","gif"]}], "open");
        } else if (opMode === "__wallpaper_folder__") {
          fileBrowser.open(wallpaperDir, [], "folder");
        } else if (opMode === "open") {
          fileBrowser.open(home, [{label: "Text Files", extensions: ["txt","md","json","qml","conf","log","nix","sh","toml","yaml","yml"]}], "open");
        } else {
          fileBrowser.open(home, [{label: "Text Files", extensions: ["txt","md"]}], "save");
        }
      }
    }
  }

  LazyLoader {
    active: root.notepadVisible
    Notepad {
      id: notepad
      showContent: root.notepadVisible
      onCloseRequested: root.closeSurface("notepad")
      onOpenFileRequested: root._openFileBrowserForNotepad("open")
      onSaveAsRequested: (content) => {
        root._pendingNotepadContent = content;
        root._openFileBrowserForNotepad("save");
      }
    }
  }

  LazyLoader {
    active: root.powerMenuVisible
    Powermenu {
      id: powermenu
      isVisible: root.powerMenuVisible
    }
  }

  Launcher {
    id: launcher
  }

  SettingsHub {
    id: settingsHub
    onBrowseWallpaper: (monitorName) => {
      root._fileBrowserCaller = "wallpaper";
      root._wallpaperMonitor = monitorName;
      root._reopenSettingsHubAfterFileBrowser = settingsHub.isOpen;
      if (settingsHub.isOpen) settingsHub.close();
      root.openSurface("fileBrowser");
      _fileBrowserOpenTimer.opMode = "__wallpaper__";
      _fileBrowserOpenTimer.restart();
    }
    onPickWallpaperFolder: {
      root._fileBrowserCaller = "wallpaper-folder";
      root._reopenSettingsHubAfterFileBrowser = settingsHub.isOpen;
      if (settingsHub.isOpen) settingsHub.close();
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
      onIsOpenChanged: if (!isOpen) root.closeSurface("colorPicker")
    }
  }

  LazyLoader {
    active: root.displayConfigVisible
    DisplayConfig {
      id: displayConfig
      isOpen: root.displayConfigVisible
      onIsOpenChanged: if (!isOpen) root.closeSurface("displayConfig")
    }
  }

  FileBrowser {
    id: fileBrowser
    isOpen: root.fileBrowserVisible
    onIsOpenChanged: {
      if (!isOpen) {
        root.closeSurface("fileBrowser");
        if (root._reopenSettingsHubAfterFileBrowser) {
          settingsHub.open();
          root._reopenSettingsHubAfterFileBrowser = false;
        }
      }
    }
    onFileSelected: (filePath) => {
      root.closeSurface("fileBrowser");
      if (root._fileBrowserCaller === "notepad-open") {
        // Re-open notepad if it was closed, then load file
        root.openSurface("notepad");
        // Defer until notepad is created by LazyLoader
        Qt.callLater(function() {
          if (notepad) notepad.loadFile(filePath);
        });
      } else if (root._fileBrowserCaller === "notepad-save") {
        root.openSurface("notepad");
        Qt.callLater(function() {
          if (notepad) notepad.saveToFile(filePath, root._pendingNotepadContent);
        });
      } else if (root._fileBrowserCaller === "wallpaper") {
        Quickshell.execDetached(["sh", "-c",
          "swww img '" + filePath.replace(/'/g, "'\\''") + "'" +
          (root._wallpaperMonitor ? " --outputs '" + root._wallpaperMonitor + "'" : "") +
          " --transition-type grow --transition-duration 1.5"
        ]);
      }
      root._fileBrowserCaller = "";
      root._pendingNotepadContent = "";
    }
    onFolderSelected: (folderPath) => {
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
