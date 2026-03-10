import QtQuick
import QtQuick.Layouts
import "../services"

Rectangle {
  id: root
  
  property string icon: ""
  property string label: ""
  property bool active: false
  signal clicked()

  Layout.fillWidth: true
  Layout.preferredHeight: 60
  radius: Colors.radiusMedium
  color: active ? Colors.primary : Colors.bgWidget
  border.color: active ? Colors.primary : Colors.border
  border.width: 1

  Behavior on color { ColorAnimation { duration: 200 } }
  Behavior on border.color { ColorAnimation { duration: 200 } }

  RowLayout {
    anchors.fill: parent
    anchors.margins: 12
    spacing: 12

    Rectangle {
      width: 36; height: 36
      radius: 18
      color: active ? Qt.rgba(1, 1, 1, 0.2) : Colors.surface
      
      Text {
        anchors.centerIn: parent
        text: root.icon
        color: active ? Colors.text : Colors.primary
        font.family: Colors.fontMono
        font.pixelSize: 18
      }
    }

    Column {
      Layout.fillWidth: true
      spacing: 2
      Text {
        text: root.label
        color: active ? Colors.text : Colors.fgMain
        font.pixelSize: 12
        font.weight: Font.Bold
        elide: Text.ElideRight
      }
      Text {
        text: active ? "On" : "Off"
        color: active ? Qt.rgba(1, 1, 1, 0.7) : Colors.fgSecondary
        font.pixelSize: 10
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    onEntered: if (!active) root.color = Colors.surface
    onExited: if (!active) root.color = Colors.bgWidget
    onClicked: root.clicked()
  }
}
