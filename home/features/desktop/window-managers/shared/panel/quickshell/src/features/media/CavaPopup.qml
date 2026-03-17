import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../services"

PopupWindow {
  id: root
  color: "transparent"
  readonly property int availablePopupWidth: screen ? Math.max(280, screen.width - 40) : 400
  readonly property bool compactMode: availablePopupWidth < 340
  implicitWidth: Math.min(400, availablePopupWidth)
  implicitHeight: compactMode ? 108 : 120

  property string cavaData: ""
  property string preferredEdge: "top"
  signal closeRequested()
  property bool wantVisible: false
  property bool showContent: wantVisible
  visible: wantVisible || cavaFadeAnim.running || cavaScaleAnim.running

  Rectangle {
    anchors.fill: parent
    color: Colors.bgGlass
    radius: Colors.radiusLarge
    border.color: Colors.border
    border.width: 1
    clip: true
    focus: true
    Keys.onEscapePressed: root.closeRequested()
    opacity: root.showContent ? 1.0 : 0.0
    scale: root.showContent ? 1.0 : 0.96
    transformOrigin: {
      if (root.preferredEdge === "bottom") return Item.Bottom;
      if (root.preferredEdge === "left") return Item.Left;
      if (root.preferredEdge === "right") return Item.Right;
      return Item.Top;
    }
    Behavior on opacity { NumberAnimation { id: cavaFadeAnim; duration: Colors.durationFast; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { id: cavaScaleAnim; duration: Colors.durationMedium; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }
    layer.enabled: cavaFadeAnim.running || cavaScaleAnim.running

    // Top accent line
    Rectangle {
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.topMargin: 1
      anchors.leftMargin: parent.radius
      anchors.rightMargin: parent.radius
      height: 2
      color: Colors.withAlpha(Colors.primary, 0.4)
    }

    // Bottom gradient
    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      height: parent.height * 0.5
      radius: Colors.radiusLarge
      gradient: Gradient {
        GradientStop { position: 0.0; color: "transparent" }
        GradientStop { position: 1.0; color: Colors.withAlpha(Colors.primary, 0.06) }
      }
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Colors.paddingMedium
      spacing: Colors.paddingSmall

      Text {
        text: "󰎆  AUDIO VISUALIZER"
        color: Colors.textSecondary
        font.pixelSize: Colors.fontSizeXS
        font.weight: Font.Bold
        font.letterSpacing: Colors.letterSpacingWide
        Layout.alignment: Qt.AlignHCenter
      }

      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignHCenter

        // Glow layer behind main text
        Text {
          anchors.centerIn: parent
          text: root.cavaData
          color: Colors.withAlpha(Colors.primary, 0.3)
          font.pixelSize: root.compactMode ? 30 : 36
          font.letterSpacing: 2
          horizontalAlignment: Text.AlignHCenter
          width: parent.width
        }

        // Main cava text
        Text {
          id: bigCavaText
          anchors.centerIn: parent
          text: root.cavaData
          color: Colors.primary
          font.pixelSize: root.compactMode ? 28 : 32
          font.letterSpacing: 2
          horizontalAlignment: Text.AlignHCenter
          width: parent.width
        }
      }
    }
  }
}
