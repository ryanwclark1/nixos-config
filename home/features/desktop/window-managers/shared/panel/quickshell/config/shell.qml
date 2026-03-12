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

  property bool notifCenterVisible: false
  property bool controlCenterVisible: false
  property bool networkMenuVisible: false
  property bool audioMenuVisible: false
  property bool powerMenuVisible: false
  property bool clipboardMenuVisible: false
  property bool recordingMenuVisible: false
  property bool musicMenuVisible: false
  property bool batteryMenuVisible: false
  property bool weatherMenuVisible: false
  property bool systemStatsMenuVisible: false
  property bool bluetoothMenuVisible: false
  property bool printerMenuVisible: false
  property bool privacyMenuVisible: false
  property bool notepadVisible: false
  property bool colorPickerVisible: false
  property bool displayConfigVisible: false
  property bool fileBrowserVisible: false

  // Track which screen triggered the current menu (captured at toggle time)
  property var menuScreen: null
  readonly property var activeScreen: (Quickshell.screens && Quickshell.screens.length > 0) ? (Quickshell.cursorScreen || Quickshell.screens[0]) : null

  readonly property var allPanels: ["notifCenterVisible", "controlCenterVisible", "networkMenuVisible", "audioMenuVisible", "bluetoothMenuVisible", "printerMenuVisible", "privacyMenuVisible", "clipboardMenuVisible", "recordingMenuVisible", "musicMenuVisible", "batteryMenuVisible", "weatherMenuVisible", "systemStatsMenuVisible", "powerMenuVisible", "notepadVisible", "colorPickerVisible", "displayConfigVisible", "fileBrowserVisible"]

  function togglePanel(panel) {
    var next = !root[panel];
    for (var i = 0; i < allPanels.length; i++) {
      root[allPanels[i]] = (allPanels[i] === panel) ? next : false;
    }
    // Capture which screen the user interacted with
    if (next) root.menuScreen = root.activeScreen;
  }

  function toggleNotifications() { togglePanel("notifCenterVisible"); }
  function toggleControls() { togglePanel("controlCenterVisible"); }
  function toggleNetworkMenu() { togglePanel("networkMenuVisible"); }
  function toggleAudioMenu() { togglePanel("audioMenuVisible"); }
  function toggleClipboardMenu() { togglePanel("clipboardMenuVisible"); }
  function toggleRecordingMenu() { togglePanel("recordingMenuVisible"); }
  function toggleMusicMenu() { togglePanel("musicMenuVisible"); }
  function toggleBatteryMenu() { togglePanel("batteryMenuVisible"); }
  function toggleWeatherMenu() { togglePanel("weatherMenuVisible"); }
  function toggleSystemStatsMenu() { togglePanel("systemStatsMenuVisible"); }
  function toggleBluetoothMenu() { togglePanel("bluetoothMenuVisible"); }
  function togglePrinterMenu() { togglePanel("printerMenuVisible"); }
  function togglePrivacyMenu() { togglePanel("privacyMenuVisible"); }
  function toggleNotepad() { togglePanel("notepadVisible"); }
  function toggleColorPicker() { togglePanel("colorPickerVisible"); }
  function toggleDisplayConfig() { togglePanel("displayConfigVisible"); }
  function toggleFileBrowser() { togglePanel("fileBrowserVisible"); }

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
    function toggleSystemStatsMenu() { root.toggleSystemStatsMenu(); }
    function toggleNotepad() { root.toggleNotepad(); }
    function toggleColorPicker() { root.toggleColorPicker(); }
    function toggleDisplayConfig() { root.toggleDisplayConfig(); }
    function toggleFileBrowser() { root.toggleFileBrowser(); }

    function closeAll() {
      for (var i = 0; i < root.allPanels.length; i++) {
        root[root.allPanels[i]] = false;
      }
    }

    function togglePowermenu() {
      root.togglePanel("powerMenuVisible");
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
          onSystemStatsClicked: root.toggleSystemStatsMenu()
          onNotepadClicked: root.toggleNotepad()
        }

        // PopupWindow menus — anchored to this screen's bar.
        // Each BasePopupMenu self-manages deferred unmapping via wantVisible.
        BluetoothMenu {
          anchor.window: barWindow
          anchor.rect.x: barWindow.width - width - 8
          anchor.rect.y: panel.btTriggerBottomY + 6
          wantVisible: root.bluetoothMenuVisible && barWindow.isMenuScreen
        }

        AudioMenu {
          anchor.window: barWindow
          anchor.rect.x: barWindow.width - width - 8
          anchor.rect.y: panel.audioTriggerBottomY + 6
          wantVisible: root.audioMenuVisible && barWindow.isMenuScreen
        }

        NetworkMenu {
          anchor.window: barWindow
          anchor.rect.x: barWindow.width - width - 8
          anchor.rect.y: panel.networkTriggerBottomY + 6
          wantVisible: root.networkMenuVisible && barWindow.isMenuScreen
        }

        ClipboardMenu {
          anchor.window: barWindow
          anchor.rect.x: barWindow.width - width - 8
          anchor.rect.y: panel.clipboardTriggerBottomY + 6
          wantVisible: root.clipboardMenuVisible && barWindow.isMenuScreen
        }

        RecordingMenu {
          anchor.window: barWindow
          anchor.rect.x: barWindow.width - width - 8
          anchor.rect.y: panel.recordingTriggerBottomY + 6
          wantVisible: root.recordingMenuVisible && barWindow.isMenuScreen
        }

        PrivacyMenu {
          anchor.window: barWindow
          anchor.rect.x: barWindow.width - width - 8
          anchor.rect.y: panel.privacyTriggerBottomY + 6
          wantVisible: root.privacyMenuVisible && barWindow.isMenuScreen
        }

        MusicMenu {
          anchor.window: barWindow
          anchor.rect.x: barWindow.width - width - 8
          anchor.rect.y: panel.musicTriggerBottomY + 6
          wantVisible: root.musicMenuVisible && barWindow.isMenuScreen
        }

        BatteryMenu {
          anchor.window: barWindow
          anchor.rect.x: barWindow.width - width - 8
          anchor.rect.y: panel.batteryTriggerBottomY + 6
          wantVisible: root.batteryMenuVisible && barWindow.isMenuScreen
        }

        WeatherMenu {
          anchor.window: barWindow
          anchor.rect.x: barWindow.width - width - 8
          anchor.rect.y: panel.weatherTriggerBottomY + 6
          wantVisible: root.weatherMenuVisible && barWindow.isMenuScreen
        }

        SystemStatsMenu {
          anchor.window: barWindow
          anchor.rect.x: 8
          anchor.rect.y: panel.systemMonitorBottomY + 6
          wantVisible: root.systemStatsMenuVisible && barWindow.isMenuScreen
        }

        PrinterMenu {
          anchor.window: barWindow
          anchor.rect.x: barWindow.width - width - 8
          anchor.rect.y: panel.printerTriggerBottomY + 6
          wantVisible: root.printerMenuVisible && barWindow.isMenuScreen
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
      onCloseRequested: root.notifCenterVisible = false
    }
  }

  ControlCenter {
    id: controls
    manager: notifManager
    showContent: root.controlCenterVisible
    onCloseRequested: root.controlCenterVisible = false
  }

  // --- File operation coordination ---
  // Tracks what triggered the FileBrowser so we can route fileSelected back
  property string _fileBrowserCaller: "" // "notepad-open", "notepad-save", "wallpaper"
  property string _pendingNotepadContent: "" // content to save for notepad-save
  property string _wallpaperMonitor: "" // monitor name for wallpaper browse

  function _openFileBrowserForNotepad(mode) {
    _fileBrowserCaller = mode === "save" ? "notepad-save" : "notepad-open";
    root.fileBrowserVisible = true;
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
        if (opMode === "__wallpaper__") {
          fileBrowser.open(home + "/Pictures", [{label: "Images", extensions: ["jpg","jpeg","png","webp","gif"]}], "open");
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
      onCloseRequested: root.notepadVisible = false
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
      root.fileBrowserVisible = true;
      _fileBrowserOpenTimer.opMode = "__wallpaper__";
      _fileBrowserOpenTimer.restart();
    }
  }

  LazyLoader {
    active: root.colorPickerVisible
    ColorPicker {
      id: colorPicker
      isOpen: root.colorPickerVisible
      onIsOpenChanged: if (!isOpen) root.colorPickerVisible = false
    }
  }

  LazyLoader {
    active: root.displayConfigVisible
    DisplayConfig {
      id: displayConfig
      isOpen: root.displayConfigVisible
      onIsOpenChanged: if (!isOpen) root.displayConfigVisible = false
    }
  }

  LazyLoader {
    active: root.fileBrowserVisible
    FileBrowser {
      id: fileBrowser
      isOpen: root.fileBrowserVisible
      onIsOpenChanged: if (!isOpen) root.fileBrowserVisible = false
      onFileSelected: (filePath) => {
        root.fileBrowserVisible = false;
        if (root._fileBrowserCaller === "notepad-open") {
          // Re-open notepad if it was closed, then load file
          root.notepadVisible = true;
          // Defer until notepad is created by LazyLoader
          Qt.callLater(function() {
            if (notepad) notepad.loadFile(filePath);
          });
        } else if (root._fileBrowserCaller === "notepad-save") {
          root.notepadVisible = true;
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
