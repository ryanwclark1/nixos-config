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
  property bool powerMenuVisible: false
  readonly property var activeScreen: (Quickshell.screens && Quickshell.screens.length > 0) ? (Quickshell.cursorScreen || Quickshell.screens[0]) : null

  function toggleNotifications() {
    controlCenterVisible = false;
    notifCenterVisible = !notifCenterVisible;
  }

  function toggleControls() {
    notifCenterVisible = false;
    controlCenterVisible = !controlCenterVisible;
  }

  IpcHandler {
    target: "Shell"
    function toggleNotifications() { root.toggleNotifications(); }
    function toggleControls() { root.toggleControls(); }

    function closeAll() {
      root.notifCenterVisible = false;
      root.controlCenterVisible = false;
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
    
    Panel {
      id: panel
      anchors.fill: parent
      manager: notifManager
      onNotifClicked: root.toggleNotifications()
      onControlClicked: root.toggleControls()
    }

    BluetoothMenu {
      id: btMenu
      anchor.window: toplevel
      anchor.rect.x: toplevel.width - width - 12
      anchor.rect.y: toplevel.height + 8
      visible: panel.btMenuVisible
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
