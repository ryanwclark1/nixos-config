import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../shared"
import "../../../widgets" as SharedWidgets

Rectangle {
    id: root

    property bool active: false
    property real activeBackgroundAlpha: 0.07
    property int contentInset: Colors.spacingM
    property int rowSpacing: Colors.spacingM
    property int minimumHeight: 0
    property bool highlighted: false
    property bool dragging: false
    property bool dropTargeted: false
    default property alias rowContent: contentRow.data

    Layout.fillWidth: true
    implicitHeight: Math.max(minimumHeight, contentRow.implicitHeight + contentInset * 2)
    radius: Colors.radiusXS
    color: root.dragging ? Colors.withAlpha(Colors.primary, 0.12) : (root.active ? Colors.primarySubtle : Colors.cardSurface)
    border.color: (root.dragging || root.dropTargeted) ? Colors.primary : (root.active ? Colors.primary : Colors.border)
    border.width: 1
    opacity: root.dragging ? 0.82 : 1.0

    SharedWidgets.InnerHighlight { hoveredOpacity: 0.3; hovered: root.active || root.dragging || root.dropTargeted }

    Behavior on color {
        enabled: !Colors.isTransitioning
        CAnim {}
    }

    Behavior on border.color {
        enabled: !Colors.isTransitioning
        CAnim {}
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

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Colors.primary
        opacity: listHighlightPulse.running ? listHighlightPulse._opacity : 0
        visible: root.highlighted

        SequentialAnimation {
            id: listHighlightPulse
            property real _opacity: 0
            running: root.highlighted
            loops: 2
            NumberAnimation { target: listHighlightPulse; property: "_opacity"; from: 0; to: 0.2; duration: Colors.durationSlow; easing.type: Easing.OutCubic }
            NumberAnimation { target: listHighlightPulse; property: "_opacity"; from: 0.2; to: 0; duration: Colors.durationSlow; easing.type: Easing.InCubic }
        }
    }
}
