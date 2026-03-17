import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

// ScrollableContent — reusable scrollable wrapper for popup menus.
//
// Replaces the boilerplate Item + Flickable + ColumnLayout + Scrollbar
// + OverscrollGlow pattern used across popup menus.
//
// Usage:
//   ScrollableContent {
//     Layout.fillWidth: true
//     Layout.fillHeight: true
//     // children go directly into the inner ColumnLayout
//     Text { text: "Hello" }
//   }

Item {
  id: root

  property int columnSpacing: Colors.spacingM
  default property alias content: contentColumn.data
  readonly property alias flickable: flick

  Flickable {
    id: flick
    anchors.fill: parent
    contentHeight: contentColumn.implicitHeight
    clip: true
    boundsBehavior: Flickable.DragOverBounds

    ColumnLayout {
      id: contentColumn
      width: parent.width
      spacing: root.columnSpacing
    }
  }

  SharedWidgets.Scrollbar { flickable: flick }
  SharedWidgets.OverscrollGlow { flickable: flick }
}
