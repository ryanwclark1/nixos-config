import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import "../services"

Scope {
  id: root
  property bool shouldShowOsd: false
  property bool initialized: false

  Timer {
    id: hideTimer
    interval: 3000
    onTriggered: root.shouldShowOsd = false
  }

  // Startup suppression — don't show OSD for 2 seconds after shell starts
  Timer {
    id: startupGuard
    interval: 2000
    running: true
    onTriggered: root.initialized = true
  }

  // Watch MediaService for track changes (already deduped + browser-merged)
  Connections {
    target: MediaService
    function onTrackTitleChanged() {
      if (!root.initialized) return;
      if (!MediaService.trackTitle) return;
      root.shouldShowOsd = true;
      hideTimer.restart();
    }
  }

  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        id: osdWindow
        required property ShellScreen modelData
        screen: modelData
        readonly property var edgeMargins: Config.reservedEdgesForScreen(modelData, "")
        readonly property int usableWidth: Math.max(0, screen.width - edgeMargins.left - edgeMargins.right)
        readonly property int usableHeight: Math.max(0, screen.height - edgeMargins.top - edgeMargins.bottom)

        // Deferred unmap: keep window mapped briefly after hide for fade-out
        property bool _wantVisible: root.shouldShowOsd
        visible: _wantVisible || unmapDelay.running
        on_WantVisibleChanged: {
          if (!_wantVisible) unmapDelay.restart();
        }
        Timer { id: unmapDelay; interval: 350 }

        anchors.top: true
        anchors.left: true
        margins.top: edgeMargins.top + Math.round(usableHeight / 10)
        margins.left: edgeMargins.left + Math.max(0, (usableWidth - implicitWidth) / 2)
        exclusiveZone: 0

        implicitWidth: 350
        implicitHeight: 80
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell"

        mask: Region { item: content }

        Rectangle {
          id: content
          anchors.fill: parent
          radius: 12
          color: Colors.bgGlass
          border.color: Colors.border
          border.width: 1

          opacity: root.shouldShowOsd ? 1.0 : 0.0
          scale: root.shouldShowOsd ? 1.0 : 0.92

          Behavior on opacity {
            NumberAnimation {
              id: osdFadeAnim
              duration: root.shouldShowOsd ? 160 : 280
              easing.type: root.shouldShowOsd ? Easing.OutQuad : Easing.InCubic
            }
          }
          Behavior on scale {
            NumberAnimation {
              id: osdScaleAnim
              duration: root.shouldShowOsd ? 200 : 280
              easing.type: root.shouldShowOsd ? Easing.OutCubic : Easing.InCubic
            }
          }

          layer.enabled: osdFadeAnim.running || osdScaleAnim.running || unmapDelay.running

          RowLayout {
            anchors.fill: parent
            anchors.margins: Colors.paddingSmall
            spacing: Colors.spacingM

            Image {
              Layout.preferredWidth: 60
              Layout.preferredHeight: 60
              source: MediaService.trackArtUrl || ""
              sourceSize: Qt.size(120, 120)
              asynchronous: true
              fillMode: Image.PreserveAspectCrop
              visible: MediaService.trackArtUrl !== ""

              Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: Colors.border
                border.width: 1
                radius: 6
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: Colors.spacingXS

              Text {
                text: MediaService.trackTitle || "No Media"
                color: Colors.text
                font.pointSize: 12
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              Text {
                text: MediaService.trackArtist || "Unknown Artist"
                color: Colors.textSecondary
                font.pointSize: 10
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
            }

            Text {
              Layout.preferredWidth: 24
              Layout.preferredHeight: 24
              horizontalAlignment: Text.AlignHCenter
              verticalAlignment: Text.AlignVCenter
              text: MediaService.isPlaying ? "󰏤" : "󰐊"
              color: Colors.text
              font.family: Colors.fontMono
              font.pixelSize: 18
            }
          }
        }
      }
    }
  }
}
