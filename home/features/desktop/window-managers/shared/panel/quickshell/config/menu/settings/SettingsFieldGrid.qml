import QtQuick
import QtQuick.Layouts
import "../../services"

Item {
  id: root

  default property alias content: grid.data
  implicitHeight: grid.implicitHeight
  Layout.fillWidth: true

  GridLayout {
    id: grid
    anchors.left: parent.left
    anchors.right: parent.right
    columns: 2
    columnSpacing: Colors.spacingL
    rowSpacing: Colors.spacingL
  }
}
