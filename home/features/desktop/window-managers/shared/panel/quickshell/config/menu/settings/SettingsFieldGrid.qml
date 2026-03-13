import QtQuick
import QtQuick.Layouts
import "../../services"

Item {
  id: root

  default property alias content: grid.data
  property int maximumColumns: 2
  property int minimumColumnWidth: 280
  readonly property int resolvedColumns: Math.max(
    1,
    Math.min(
      maximumColumns,
      Math.floor((root.width + grid.columnSpacing) / (minimumColumnWidth + grid.columnSpacing)) || 1
    )
  )
  implicitHeight: grid.implicitHeight
  Layout.fillWidth: true

  GridLayout {
    id: grid
    anchors.left: parent.left
    anchors.right: parent.right
    columns: root.resolvedColumns
    columnSpacing: Colors.spacingL
    rowSpacing: Colors.spacingL
  }
}
