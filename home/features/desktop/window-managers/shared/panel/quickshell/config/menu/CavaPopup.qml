import Quickshell
import QtQuick
import QtQuick.Layouts
import "../services"

PopupWindow {
  id: root
  implicitWidth: 400
  implicitHeight: 120

  property string cavaData: ""

  Rectangle {
    anchors.fill: parent
    color: Colors.bgGlass
    radius: Colors.radiusLarge
    border.color: Colors.border
    border.width: 1
    clip: true

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
      anchors.margins: 15
      spacing: 10

      Text {
        text: "󰎆  AUDIO VISUALIZER"
        color: Colors.textSecondary
        font.pixelSize: 10
        font.weight: Font.Bold
        font.letterSpacing: 1
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
          font.pixelSize: 36
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
          font.pixelSize: 32
          font.letterSpacing: 2
          horizontalAlignment: Text.AlignHCenter
          width: parent.width
        }
      }
    }
  }
}
