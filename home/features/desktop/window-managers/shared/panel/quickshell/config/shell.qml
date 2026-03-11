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

  // Track which screen triggered the current menu (captured at toggle time)
  property var menuScreen: null
  readonly property var activeScreen: (Quickshell.screens && Quickshell.screens.length > 0) ? (Quickshell.cursorScreen || Quickshell.screens[0]) : null

  readonly property var allPanels: ["notifCenterVisible", "controlCenterVisible", "networkMenuVisible", "audioMenuVisible", "bluetoothMenuVisible", "clipboardMenuVisible", "recordingMenuVisible", "musicMenuVisible", "batteryMenuVisible", "weatherMenuVisible", "systemStatsMenuVisible", "powerMenuVisible"]

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

  IpcHandler {
    target: "Shell"
    function toggleNotifications() { root.toggleNotifications(); }
    function toggleControls() { root.toggleControls(); }
    function toggleNetworkMenu() { root.toggleNetworkMenu(); }
    function toggleAudioMenu() { root.toggleAudioMenu(); }
    function toggleBluetoothMenu() { root.toggleBluetoothMenu(); }
    function toggleClipboardMenu() { root.toggleClipboardMenu(); }
    function toggleRecordingMenu() { root.toggleRecordingMenu(); }
    function toggleMusicMenu() { root.toggleMusicMenu(); }
    function toggleBatteryMenu() { root.toggleBatteryMenu(); }
    function toggleWeatherMenu() { root.toggleWeatherMenu(); }
    function toggleSystemStatsMenu() { root.toggleSystemStatsMenu(); }

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
          onBatteryClicked: root.toggleBatteryMenu()
          onClipboardClicked: root.toggleClipboardMenu()
          onBluetoothClicked: root.toggleBluetoothMenu()
          onWeatherClicked: root.toggleWeatherMenu()
          onSystemStatsClicked: root.toggleSystemStatsMenu()
        }

        // PopupWindow menus — anchored to this screen's bar, only visible on the menu screen
        BluetoothMenu {
          anchor.window: barWindow
          anchor.rect.x: barWindow.width - width - 8
          anchor.rect.y: panel.btTriggerBottomY + 6
          visible: root.bluetoothMenuVisible && barWindow.isMenuScreen
        }

        AudioMenu {
          anchor.window: barWindow
          anchor.rect.x: barWindow.width - width - 8
          anchor.rect.y: panel.audioTriggerBottomY + 6
          visible: root.audioMenuVisible && barWindow.isMenuScreen
        }

        NetworkMenu {
          anchor.window: barWindow
          anchor.rect.x: barWindow.width - width - 8
          anchor.rect.y: panel.networkTriggerBottomY + 6
          visible: root.networkMenuVisible && barWindow.isMenuScreen
        }

        ClipboardMenu {
          anchor.window: barWindow
          anchor.rect.x: barWindow.width - width - 8
          anchor.rect.y: panel.clipboardTriggerBottomY + 6
          visible: root.clipboardMenuVisible && barWindow.isMenuScreen
        }

        RecordingMenu {
          anchor.window: barWindow
          anchor.rect.x: barWindow.width - width - 8
          anchor.rect.y: panel.recordingTriggerBottomY + 6
          visible: root.recordingMenuVisible && barWindow.isMenuScreen
        }

        MusicMenu {
          anchor.window: barWindow
          anchor.rect.x: barWindow.width - width - 8
          anchor.rect.y: panel.musicTriggerBottomY + 6
          visible: root.musicMenuVisible && barWindow.isMenuScreen
        }

        BatteryMenu {
          anchor.window: barWindow
          anchor.rect.x: barWindow.width - width - 8
          anchor.rect.y: panel.batteryTriggerBottomY + 6
          visible: root.batteryMenuVisible && barWindow.isMenuScreen
        }

        WeatherMenu {
          anchor.window: barWindow
          anchor.rect.x: barWindow.width - width - 8
          anchor.rect.y: panel.weatherTriggerBottomY + 6
          visible: root.weatherMenuVisible && barWindow.isMenuScreen
        }

        SystemStatsMenu {
          anchor.window: barWindow
          anchor.rect.x: 8
          anchor.rect.y: panel.systemMonitorBottomY + 6
          visible: root.systemStatsMenuVisible && barWindow.isMenuScreen
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

  NotificationCenter {
    id: center
    manager: notifManager
    showContent: root.notifCenterVisible
    onCloseRequested: root.notifCenterVisible = false
  }

  ControlCenter {
    id: controls
    manager: notifManager
    showContent: root.controlCenterVisible
    onCloseRequested: root.controlCenterVisible = false
  }

  Powermenu {
    id: powermenu
    isVisible: root.powerMenuVisible
  }

  Launcher {
    id: launcher
  }

  SettingsHub {
    id: settingsHub
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
}
