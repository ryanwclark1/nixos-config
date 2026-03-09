import Quickshell // PanelWindow
import QtQuick
import Quickshell.Io
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
    }
  }

  NotificationManager {
    id: notifManager
  }

  HyprlandState {
    id: hyprState
  }

  PanelWindow {
    id: toplevel
    anchors {
      top: true
      left: true
      right: true
    }

    implicitHeight: panel.implicitHeight

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

  ActivateLinux {
    id: activateLinux
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
    showContent: root.controlCenterVisible
  }

  Launcher {
    id: launcher
    hyprState: hyprState
  }
}
