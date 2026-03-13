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
    color: root.active ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, root.activeBackgroundAlpha) : Colors.bgWidget
    border.color: root.active ? Colors.primary : Colors.border
    border.width: 1

    Behavior on color {
        ColorAnimation {
            duration: 180
        }
    }

    Behavior on border.color {
        ColorAnimation {
            duration: 180
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
