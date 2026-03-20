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
    implicitHeight: headerContainer.implicitHeight + (expanded ? contentColumn.implicitHeight + Appearance.spacingL : 0)
    radius: Appearance.radiusLarge
    color: Colors.withAlpha(Colors.surface, 0.82)
    border.color: Colors.withAlpha(Colors.primary, 0.18)
    border.width: 1
    clip: true

    SharedWidgets.InnerHighlight {}

    SharedWidgets.AdaptiveAccentStrip {
        accentColor: Colors.primary
        parentRadius: root.radius
        opacityValue: 0.72
    }

    Behavior on implicitHeight {
        Anim {}
    }

    Rectangle {
        id: headerContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        implicitHeight: headerColumn.implicitHeight + Appearance.spacingM * 2
        color: Colors.withAlpha(Colors.primary, 0.05)

        ColumnLayout {
            id: headerColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Appearance.spacingM
            spacing: Appearance.spacingXXS

            Text {
                text: "LAUNCHER"
                color: Colors.primary
                font.pixelSize: Appearance.fontSizeXXS
                font.weight: Font.Black
                font.letterSpacing: Appearance.letterSpacingExtraWide
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingS

                Text {
                    visible: root.iconName !== ""
                    text: root.iconName
                    color: Colors.primary
                    font.family: Appearance.fontMono
                    font.pixelSize: Appearance.fontSizeLarge
                }

                Text {
                    Layout.fillWidth: true
                    text: root.title
                    color: Colors.text
                    font.pixelSize: Appearance.fontSizeMedium
                    font.weight: Font.Black
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    visible: root._showChevron
                    implicitWidth: 24
                    implicitHeight: 24
                    radius: Appearance.radiusCard
                    color: Colors.withAlpha(Colors.text, collapseHover.containsMouse ? 0.14 : 0.08)
                    border.color: Colors.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.expanded ? "󰅃" : "󰅀"
                        color: Colors.textSecondary
                        font.family: Appearance.fontMono
                        font.pixelSize: Appearance.fontSizeSmall
                    }
                }
            }

            Text {
                visible: root.description !== ""
                text: root.description
                color: Colors.textSecondary
                font.pixelSize: Appearance.fontSizeSmall
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
        anchors.leftMargin: Appearance.spacingL
        anchors.rightMargin: Appearance.spacingL
        anchors.topMargin: Appearance.spacingM
        anchors.bottomMargin: Appearance.spacingL
        spacing: Appearance.spacingL
        visible: root.expanded
    }
}
