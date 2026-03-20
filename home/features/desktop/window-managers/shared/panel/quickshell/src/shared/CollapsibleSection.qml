import QtQuick
import QtQuick.Layouts
import "."
import "../services"

// Animated expand/collapse section with header.
//
// Usage:
//   CollapsibleSection {
//     title: "Advanced"
//     icon: "󰒓"
//     expanded: false
//
//     ColumnLayout { /* children go here */ }
//   }
ColumnLayout {
    id: root

    property string title: ""
    property string subtitle: ""
    property string icon: ""
    property bool expanded: true
    property alias headerColor: headerText.color
    property alias headerExtras: headerExtrasContainer.data

    default property alias content: contentContainer.data

    spacing: 0

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: headerRow.implicitHeight + Appearance.spacingS * 2
        radius: Appearance.radiusSmall
        color: "transparent"

        StateLayer {
            id: headerState
            hovered: headerMouse.containsMouse
            pressed: headerMouse.pressed
        }

        RowLayout {
            id: headerRow
            anchors.fill: parent
            anchors.leftMargin: Appearance.spacingS
            anchors.rightMargin: Appearance.spacingS
            anchors.topMargin: Appearance.spacingS
            anchors.bottomMargin: Appearance.spacingS
            spacing: Appearance.spacingS

            Text {
                text: "\u{f0140}"
                color: Colors.textDisabled
                font.family: Appearance.fontMono
                font.pixelSize: Appearance.fontSizeSmall
                rotation: root.expanded ? 0 : -90
                Behavior on rotation { Anim { duration: Appearance.durationFast } }
            }

            Text {
                visible: !!root.icon
                text: root.icon
                color: Colors.textSecondary
                font.family: Appearance.fontMono
                font.pixelSize: Appearance.fontSizeMedium
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    id: headerText
                    text: root.title
                    color: Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeSmall
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }

                Text {
                    visible: !!root.subtitle
                    text: root.subtitle
                    color: Colors.textDisabled
                    font.pixelSize: Appearance.fontSizeXS
                    Layout.fillWidth: true
                }
            }

            Row { id: headerExtrasContainer; spacing: Appearance.spacingXS }
        }

        MouseArea {
            id: headerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => {
                headerState.burst(mouse.x, mouse.y)
                root.expanded = !root.expanded
            }
        }
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: root.expanded ? contentContainer.implicitHeight : 0
        clip: true

        Behavior on implicitHeight { Anim {} }

        ColumnLayout {
            id: contentContainer
            width: parent.width
        }
    }
}
