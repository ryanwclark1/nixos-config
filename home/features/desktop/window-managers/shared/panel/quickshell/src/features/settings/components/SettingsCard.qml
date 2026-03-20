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
    color: Colors.withAlpha(Colors.surface, 0.64)
    border.color: Colors.withAlpha(Colors.text, 0.12)
    border.width: 1
    clip: true

    SharedWidgets.InnerHighlight { highlightOpacity: 0.1 }

    Behavior on implicitHeight {
        Anim {}
    }

    Rectangle {
        id: headerContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        implicitHeight: headerColumn.implicitHeight + Colors.spacingM * 2
        color: Colors.withAlpha(Colors.surface, 0.28)

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 3
            color: Colors.withAlpha(Colors.primary, root.expanded ? 0.8 : 0.55)
        }

        ColumnLayout {
            id: headerColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Colors.spacingM
            anchors.leftMargin: Colors.spacingL
            spacing: Colors.spacingXS

            RowLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                Rectangle {
                    visible: root.iconName !== ""
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: Colors.radiusMedium
                    color: Colors.primarySubtle
                    border.color: Colors.primaryRing
                    border.width: 1

                    Loader {
                        anchors.centerIn: parent
                        sourceComponent: root.iconName.endsWith(".svg") ? _scSvg : _scNerd
                    }
                    Component { id: _scSvg; SvgIcon { source: root.iconName; color: Colors.primary; size: Colors.fontSizeSmall } }
                    Component { id: _scNerd; Text { text: root.iconName; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeSmall } }
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
                    implicitWidth: 26
                    implicitHeight: 26
                    radius: Colors.radiusCard
                    color: Colors.withAlpha(Colors.surface, collapseHover.containsMouse ? 0.62 : 0.42)
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
        color: Colors.withAlpha(Colors.border, 0.7)
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
