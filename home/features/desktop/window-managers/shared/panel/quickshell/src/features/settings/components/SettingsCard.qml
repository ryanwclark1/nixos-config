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
        implicitHeight: headerColumn.implicitHeight + Appearance.spacingM * 2
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
            anchors.margins: Appearance.spacingM
            anchors.leftMargin: Appearance.spacingL
            spacing: Appearance.spacingXS

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingS

                Rectangle {
                    visible: root.iconName !== ""
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: Appearance.radiusMedium
                    color: Colors.primarySubtle
                    border.color: Colors.primaryRing
                    border.width: 1

                    Loader {
                        anchors.centerIn: parent
                        sourceComponent: root.iconName.endsWith(".svg") ? _scSvg : _scNerd
                    }
                    Component { id: _scSvg; SvgIcon { source: root.iconName; color: Colors.primary; size: Appearance.fontSizeSmall } }
                    Component { id: _scNerd; Text { text: root.iconName; color: Colors.primary; font.family: Appearance.fontMono; font.pixelSize: Appearance.fontSizeSmall } }
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
                    implicitWidth: 26
                    implicitHeight: 26
                    radius: Appearance.radiusCard
                    color: Colors.withAlpha(Colors.surface, collapseHover.containsMouse ? 0.62 : 0.42)
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
        color: Colors.withAlpha(Colors.border, 0.7)
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
