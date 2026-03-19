import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../shared"
import "../../../widgets" as SharedWidgets

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
    radius: Colors.radiusLarge
    color: Colors.withAlpha(Colors.surface, 0.82)
    border.color: Colors.withAlpha(Colors.primary, 0.18)
    border.width: 1
    clip: true

    SharedWidgets.InnerHighlight {}

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 4
        radius: Colors.radiusPill
        color: Colors.withAlpha(Colors.primary, 0.82)
        opacity: 0.72
    }

    Behavior on implicitHeight {
        Anim {}
    }

    Rectangle {
        id: headerContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        implicitHeight: headerColumn.implicitHeight + Colors.spacingM * 2
        color: Colors.withAlpha(Colors.primary, 0.08)

        ColumnLayout {
            id: headerColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Colors.spacingM
            spacing: Colors.spacingXXS

            Text {
                text: "LAUNCHER"
                color: Colors.primary
                font.pixelSize: Colors.fontSizeXXS
                font.weight: Font.Black
                font.letterSpacing: Colors.letterSpacingExtraWide
            }

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
                    font.weight: Font.Black
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
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: headerContainer.bottom
        height: 1
        color: Colors.withAlpha(Colors.primary, 0.12)
        visible: root.expanded
    }

    ColumnLayout {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: headerContainer.bottom
        anchors.leftMargin: Colors.spacingL
        anchors.rightMargin: Colors.spacingL
        anchors.topMargin: Colors.spacingM
        anchors.bottomMargin: Colors.spacingL
        spacing: Colors.spacingL
        visible: root.expanded
    }
}
