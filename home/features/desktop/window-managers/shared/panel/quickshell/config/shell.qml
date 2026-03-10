//@ pragma UseQApplication
import Quickshell
import QtQuick
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
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
  readonly property var activeScreen: (Quickshell.screens && Quickshell.screens.length > 0) ? (Quickshell.cursorScreen || Quickshell.screens[0]) : null

  function togglePanel(panel) {
    var panels = ["notifCenterVisible", "controlCenterVisible", "networkMenuVisible", "audioMenuVisible"];
    for (var i = 0; i < panels.length; i++) {
      root[panels[i]] = (panels[i] === panel) ? !root[panels[i]] : false;
    }
  }

  function toggleNotifications() { togglePanel("notifCenterVisible"); }
  function toggleControls() { togglePanel("controlCenterVisible"); }
  function toggleNetworkMenu() { togglePanel("networkMenuVisible"); }
  function toggleAudioMenu() { togglePanel("audioMenuVisible"); }

  IpcHandler {
    target: "Shell"
    function toggleNotifications() { root.toggleNotifications(); }
    function toggleControls() { root.toggleControls(); }
    function toggleNetworkMenu() { root.toggleNetworkMenu(); }
    function toggleAudioMenu() { root.toggleAudioMenu(); }

    function closeAll() {
      root.notifCenterVisible = false;
      root.controlCenterVisible = false;
      root.networkMenuVisible = false;
      root.audioMenuVisible = false;
      root.powerMenuVisible = false;
    }

    function togglePowermenu() {
      root.powerMenuVisible = !root.powerMenuVisible;
    }

    function reloadConfig() {
      Config.load();
    }
  }

  NotificationManager {
    id: notifManager
  }

  PanelWindow {
    id: toplevel
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
      anchorWindow: toplevel
      onNotifClicked: root.toggleNotifications()
      onNetworkClicked: root.toggleNetworkMenu()
      onAudioClicked: root.toggleAudioMenu()
      onCommandClicked: root.toggleControls()
    }

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

    BluetoothMenu {
      id: btMenu
      anchor.window: toplevel
      anchor.rect.x: toplevel.width - width - 12
      anchor.rect.y: toplevel.height + 8
      visible: panel.btMenuVisible
    }

    AudioMenu {
      id: audioMenu
      anchor.window: toplevel
      anchor.rect.x: toplevel.width - width - 8
      anchor.rect.y: panel.audioTriggerBottomY + 6
      visible: root.audioMenuVisible
    }

    NetworkMenu {
      id: networkMenu
      anchor.window: toplevel
      anchor.rect.x: toplevel.width - width - 8
      anchor.rect.y: panel.networkTriggerBottomY + 6
      visible: root.networkMenuVisible
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
  }

  ControlCenter {
    id: controls
    manager: notifManager
    showContent: root.controlCenterVisible
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

  PanelWindow {
    id: desktopBackground
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

  Corners {
    id: screenCorners
  }
}
