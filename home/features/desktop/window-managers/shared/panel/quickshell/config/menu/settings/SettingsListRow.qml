import QtQuick
import QtQuick.Layouts
import "../../services"

Rectangle {
    id: root

    property bool active: false
    property real activeBackgroundAlpha: 0.07
    property int contentInset: Colors.spacingM
    property int rowSpacing: Colors.spacingM
    property int minimumHeight: 0
    default property alias rowContent: contentRow.data

    Layout.fillWidth: true
    implicitHeight: Math.max(minimumHeight, contentRow.implicitHeight + contentInset * 2)
    radius: Colors.radiusXS
    color: root.active ? Colors.withAlpha(Colors.primary, 0.12) : Colors.withAlpha(Colors.surface, 0.35)
    border.color: root.active ? Colors.primary : Colors.border
    border.width: 1

    // Inner highlight
    Rectangle {
      anchors.fill: parent
      anchors.margins: 1
      radius: parent.radius - 1
      color: "transparent"
      border.color: Colors.borderLight
      border.width: 1
      opacity: root.active ? 0.3 : 0.1
    }

    Behavior on color {
        ColorAnimation {
            duration: Colors.durationFast
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: Colors.durationFast
        }
    }

    RowLayout {
        id: contentRow
        anchors.fill: parent
        anchors.leftMargin: root.contentInset
        anchors.rightMargin: root.contentInset
        anchors.topMargin: root.contentInset
        anchors.bottomMargin: root.contentInset
        spacing: root.rowSpacing
    }
}
