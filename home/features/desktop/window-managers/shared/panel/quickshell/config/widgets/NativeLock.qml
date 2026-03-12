import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"

Scope {
  id: root

  property bool active: false

  IpcHandler {
    target: "Lockscreen"
    function lock() { root.active = true; }
    function unlock() { root.active = false; }
  }

  // Unload after unlock with delay for animation
  Timer {
    id: unloadTimer
    interval: 250
    onTriggered: root.active = false
  }

  // PAM authentication context
  LockContext {
    id: lockContext
    onUnlocked: {
      lockSession.locked = false;
      unloadTimer.start();
      lockContext.reset();
    }
    onFailed: {
      lockContext.currentText = "";
    }
  }

  // WlSessionLock — proper Wayland session lock protocol
  WlSessionLock {
    id: lockSession
    locked: root.active

    Variants {
      model: Quickshell.screens

      WlSessionLockSurface {
        LockPanel {
          anchors.fill: parent
          lockContext: lockContext
        }
      }
    }
  }
}
