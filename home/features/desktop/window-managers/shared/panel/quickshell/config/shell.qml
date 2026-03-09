import Quickshell // PanelWindow
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

  IpcHandler {
    target: "Shell"
    function toggleNotifications() {
      root.controlCenterVisible = false;
      root.notifCenterVisible = !root.notifCenterVisible;
    }

    function toggleControls() {
      root.notifCenterVisible = false;
      root.controlCenterVisible = !root.controlCenterVisible;
    }
    
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

  property bool powerMenuVisible: false

  NotificationManager {
    id: notifManager
  }

  Repeater {
    model: Quickshell.screens

    delegate: PanelWindow {
      id: toplevel
      screen: modelData
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
      WlrLayershell.blur: Config.blurEnabled

      Panel {
        id: panel
        anchors.fill: parent
        manager: notifManager
        onNotifClicked: {
          root.controlCenterVisible = false;
          root.notifCenterVisible = !root.notifCenterVisible;
        }
        onControlClicked: {
          root.notifCenterVisible = false;
          root.controlCenterVisible = !root.controlCenterVisible;
        }
      }

      BluetoothMenu {
        id: btMenu
        anchor.window: toplevel
        anchor.rect.x: toplevel.width - width - 12
        anchor.rect.y: toplevel.height + 8
        visible: panel.btMenuVisible
      }
    }
  }

  Osd {
    id: osd
    screen: Quickshell.cursorScreen
  }

  MediaOsd {
    id: mediaOsd
    screen: Quickshell.cursorScreen
  }

  WorkspaceOsd {
    id: workspaceOsd
    screen: Quickshell.cursorScreen
  }

  Overview {
    id: overview
    screen: Quickshell.cursorScreen
  }

  Dock {
    id: dock
    screen: Quickshell.cursorScreen
  }

  Notifications {
    id: popups
    manager: notifManager
    screen: Quickshell.cursorScreen
  }

  NotificationCenter {
    id: center
    manager: notifManager
    showContent: root.notifCenterVisible
    screen: root.notifCenterVisible ? Quickshell.cursorScreen : screen
  }

  ControlCenter {
    id: controls
    showContent: root.controlCenterVisible
    screen: root.controlCenterVisible ? Quickshell.cursorScreen : screen
  }

  Powermenu {
    id: powermenu
    isVisible: root.powerMenuVisible
    screen: root.powerMenuVisible ? Quickshell.cursorScreen : screen
  }

  Launcher {
    id: launcher
    screen: opacity > 0 ? Quickshell.cursorScreen : screen
  }

  SettingsHub {
    id: settingsHub
    screen: Quickshell.cursorScreen
  }

  Repeater {
    model: Quickshell.screens
    delegate: NativeLock {
      id: lockscreen
      screen: modelData
    }
  }

  Repeater {
    model: Quickshell.screens
    
    delegate: PanelWindow {
      id: desktopBackground
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
      mask: Region {}

      DesktopWidgets {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 80
        anchors.topMargin: 120
      }
    }
  }

  Repeater {
    model: Quickshell.screens
    delegate: Corners {
      id: screenCorners
      screen: modelData
    }
  }
}
