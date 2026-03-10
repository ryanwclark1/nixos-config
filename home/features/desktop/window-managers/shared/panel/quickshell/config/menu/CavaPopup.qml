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

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 15
      spacing: 10

      Text {
        text: "Audio Visualizer"
        color: Colors.textDisabled
        font.pixelSize: 10
        font.weight: Font.Bold
        font.letterSpacing: 1
        Layout.alignment: Qt.AlignHCenter
      }

      Text {
        id: bigCavaText
        text: root.cavaData
        color: Colors.primary
        font.pixelSize: 32
        font.letterSpacing: 2
        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
      }
      
      Item { Layout.fillHeight: true }
    }
  }
}
