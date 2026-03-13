import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Wayland
import "../services"

Scope {
  id: root
  property bool shouldShowOsd: false
  property string workspaceName: ""
  property bool isSpecial: false
  property bool initialized: false

  Timer {
    id: hideTimer
    interval: 1500
    onTriggered: root.shouldShowOsd = false
  }

  Connections {
    target: Hyprland

    function onFocusedWorkspaceChanged() {
      if (Hyprland.focusedWorkspace) {
        root.workspaceName = Hyprland.focusedWorkspace.name;
        root.isSpecial = root.workspaceName.startsWith("special");
        if (root.isSpecial) {
          root.workspaceName = root.workspaceName.replace("special:", "Special: ");
        }

        // Don't show OSD on initial load
        if (!root.initialized) {
          root.initialized = true;
          return;
        }
        root.shouldShowOsd = true;
        hideTimer.restart();
      }
    }
  }

  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        id: osdWindow
        required property ShellScreen modelData
        screen: modelData

        // Delayed unmap: stay mapped briefly after hide for fade-out
        property bool _wantVisible: root.shouldShowOsd && (Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name === modelData.name : true)
        visible: _wantVisible || unmapDelay.running
        on_WantVisibleChanged: {
          if (!_wantVisible) unmapDelay.restart();
        }
        Timer { id: unmapDelay; interval: 350 }

        // PanelWindow anchoring doesn't support centerIn; place it manually instead.
        anchors.top: true
        margins.top: screen.height / 2 - implicitHeight / 2
        anchors.left: true
        margins.left: screen.width / 2 - implicitWidth / 2

        exclusiveZone: 0

        implicitWidth: 200
        implicitHeight: 200
        color: "transparent"

        mask: Region { item: content }

        Rectangle {
          id: content
          anchors.fill: parent
          radius: Colors.radiusLarge
          color: Colors.withAlpha(Colors.background, 0.6)
          border.color: Colors.border
          border.width: 1

          opacity: _wantVisible ? 1.0 : 0.0
          scale: _wantVisible ? 1.0 : 0.9

          Behavior on opacity {
            NumberAnimation {
              id: osdFadeAnim
              duration: _wantVisible ? 160 : 320
              easing.type: _wantVisible ? Easing.OutQuad : Easing.InCubic
            }
          }
          Behavior on scale {
            NumberAnimation {
              id: osdScaleAnim
              duration: _wantVisible ? 240 : 280
              easing.type: _wantVisible ? Easing.OutCubic : Easing.InCubic
            }
          }

          layer.enabled: osdFadeAnim.running || osdScaleAnim.running || unmapDelay.running

          ColumnLayout {
            anchors.centerIn: parent
            spacing: 20

            AppIcon {
              Layout.alignment: Qt.AlignHCenter
              iconSize: 64
              iconName: root.isSpecial ? "view-pin-symbolic" : "desktop-symbolic"
              fallbackIcon: root.isSpecial ? "S" : "W"
            }

            Text {
              Layout.alignment: Qt.AlignHCenter
              text: root.workspaceName
              color: Colors.text
              font.pointSize: 24
              font.bold: true
            }
          }
        }
      }
    }
  }
}
