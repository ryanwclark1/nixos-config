import QtQuick
import QtQuick.Layouts
import "../../services"

ColumnLayout {
  id: root

  property string label
  property real min
  property real max
  property real value
  property real step: 1
  property string unit: step < 1 ? "%" : "px"
  signal moved(real v)

  spacing: Colors.spacingM
  Layout.fillWidth: true

  RowLayout {
    Text { text: root.label; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.Medium }
    Item { Layout.fillWidth: true }
    Text {
      text: (root.unit === "ms" ? Math.round(root.value) : (root.step < 1 ? Math.round(root.value * 100) : Math.round(root.value))) + root.unit
      color: Colors.fgSecondary
      font.pixelSize: Colors.fontSizeSmall
      font.family: Colors.fontMono
    }
  }

  Item {
    Layout.fillWidth: true
    height: 24

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width
      height: 6
      color: Colors.surface
      radius: 3
      Rectangle {
        width: parent.width * ((root.value - root.min) / (root.max - root.min))
        height: parent.height
        color: Colors.primary
        radius: 3
        Behavior on width { NumberAnimation { duration: 80 } }
      }
    }

    Rectangle {
      width: 14
      height: 14
      radius: 7
      color: Colors.primary
      border.color: Colors.bgWidget
      border.width: 2
      x: Math.max(0, Math.min(parent.width - width, parent.width * ((root.value - root.min) / (root.max - root.min)) - width / 2))
      anchors.verticalCenter: parent.verticalCenter
      Behavior on x { NumberAnimation { duration: 80 } }
    }

    MouseArea {
      anchors.fill: parent
      anchors.topMargin: -4
      anchors.bottomMargin: -4
      cursorShape: Qt.PointingHandCursor
      function updateValue(mouse) {
        var raw = root.min + (mouse.x / width) * (root.max - root.min);
        var val = Math.round(raw / root.step) * root.step;
        root.moved(Math.max(root.min, Math.min(root.max, val)));
      }
      onPressed: (mouse) => updateValue(mouse)
      onPositionChanged: (mouse) => {
        if (pressed) updateValue(mouse);
      }
    }
  }
}
