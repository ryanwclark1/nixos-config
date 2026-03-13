import QtQuick
import QtQuick.Layouts
import "../../services"

Rectangle {
  id: root

  property string title
  property string iconName: ""
  property bool collapsible: false
  property bool expanded: true
  default property alias content: contentColumn.data

  Layout.fillWidth: true
  implicitHeight: headerRow.height + headerRow.anchors.margins + (expanded ? contentColumn.implicitHeight + contentColumn.anchors.topMargin + Colors.spacingL : 0)
  radius: Colors.radiusMedium
  color: Colors.bgWidget
  border.color: Colors.border
  border.width: 1
  clip: true

  Behavior on implicitHeight { NumberAnimation { duration: Colors.durationNormal; easing.type: Easing.OutCubic } }

  RowLayout {
    id: headerRow
    anchors { left: parent.left; right: parent.right; top: parent.top }
    anchors.margins: Colors.spacingL
    height: 40
    spacing: Colors.spacingM

    Text {
      visible: root.iconName !== ""
      text: root.iconName
      color: Colors.primary
      font.family: Colors.fontMono
      font.pixelSize: Colors.fontSizeXL
    }

    Text {
      text: root.title
      color: Colors.text
      font.pixelSize: Colors.fontSizeLarge
      font.weight: Font.Medium
      Layout.fillWidth: true
    }

    Text {
      visible: root.collapsible
      text: root.expanded ? "󰅃" : "󰅀"
      color: Colors.fgDim
      font.family: Colors.fontMono
      font.pixelSize: Colors.fontSizeLarge
    }

  }

  MouseArea {
    anchors.fill: headerRow
    visible: root.collapsible
    cursorShape: root.collapsible ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: if (root.collapsible) root.expanded = !root.expanded
  }

  ColumnLayout {
    id: contentColumn
    anchors {
      left: parent.left
      right: parent.right
      top: headerRow.bottom
      leftMargin: Colors.spacingL
      rightMargin: Colors.spacingL
      topMargin: Colors.spacingM
      bottomMargin: Colors.spacingL
    }
    spacing: Colors.spacingL
    visible: root.expanded
  }
}
