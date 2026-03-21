import QtQuick
import QtQuick.Layouts
import "../services"
import "."

// ScrollableContent — reusable scrollable wrapper for popup menus.
//
// Composes Flickable + ColumnLayout with shared Scrollbar and OverscrollGlow.
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

  property int columnSpacing: Appearance.spacingM
  /// Insets for content inside the flickable (settings tabs use this; popups leave 0).
  property int contentMarginH: 0
  property int contentMarginV: 0
  default property alias content: contentColumn.data
  readonly property alias flickable: flick

  Flickable {
    id: flick
    anchors.fill: parent
    contentHeight: contentColumn.implicitHeight + root.contentMarginV * 2
    clip: true
    boundsBehavior: Flickable.DragOverBounds

    ColumnLayout {
      id: contentColumn
      x: root.contentMarginH
      y: root.contentMarginV
      width: parent.width - root.contentMarginH * 2
      spacing: root.columnSpacing
    }
  }

  Scrollbar {
    flickable: flick
  }

  // Match prior menu/settings overscroll: soft highlight (not primary-tinted default).
  OverscrollGlow {
    flickable: flick
    glowColor: Colors.highlightLight
  }
}
