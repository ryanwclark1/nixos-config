import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../widgets" as SharedWidgets

Rectangle {
    id: root

    property string title
    property string iconName: ""
    property string description: ""
    property bool collapsible: false
    property bool expanded: true
    default property alias content: contentColumn.data

    readonly property bool _showChevron: root.collapsible

    Layout.fillWidth: true
    implicitHeight: headerContainer.implicitHeight + (expanded ? contentColumn.implicitHeight + Colors.spacingL : 0)
    radius: Colors.radiusMedium
    color: Colors.cardSurface
    border.color: Colors.border
    border.width: 1
    clip: true


    // Inner highlight
    SharedWidgets.InnerHighlight { }

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Colors.durationNormal
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: headerContainer
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        implicitHeight: headerColumn.implicitHeight + Colors.spacingM * 2
        color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.06)

        ColumnLayout {
            id: headerColumn
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: Colors.spacingM
            }
            spacing: Colors.spacingXXS

            RowLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                Text {
                    visible: root.iconName !== ""
                    text: root.iconName
                    color: Colors.primary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeLarge
                }

                Text {
                    Layout.fillWidth: true
                    text: root.title
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeMedium
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    visible: root._showChevron
                    implicitWidth: 24
                    implicitHeight: 24
                    radius: Colors.radiusCard
                    color: Colors.withAlpha(Colors.text, collapseHover.containsMouse ? 0.14 : 0.08)
                    border.color: Colors.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.expanded ? "󰅃" : "󰅀"
                        color: Colors.textSecondary
                        font.family: Colors.fontMono
                        font.pixelSize: Colors.fontSizeSmall
                    }
                }
            }

            Text {
                visible: root.description !== ""
                text: root.description
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeSmall
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }

        MouseArea {
            id: collapseHover
            anchors.fill: parent
            enabled: root.collapsible
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.expanded = !root.expanded
        }

        SharedWidgets.StateLayer {
            hovered: collapseHover.containsMouse
            pressed: collapseHover.pressed
            disabled: !root.collapsible
            stateColor: Colors.primary
        }
    }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            top: headerContainer.bottom
        }
        height: 1
        color: Colors.withAlpha(Colors.border, 0.7)
        visible: root.expanded
    }

    ColumnLayout {
        id: contentColumn
        anchors {
            left: parent.left
            right: parent.right
            top: headerContainer.bottom
            leftMargin: Colors.spacingL
            rightMargin: Colors.spacingL
            topMargin: Colors.spacingM
            bottomMargin: Colors.spacingL
        }
        spacing: Colors.spacingL
        visible: root.expanded
    }
}
