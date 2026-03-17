import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

Rectangle {
    id: root
    property alias text: input.text
    property alias searchInput: input
    property string placeholder: "Search..."
    property color accentColor: Colors.primary

    signal accepted
    signal escapePressed

    height: 48
    radius: Colors.radiusLarge
    color: Qt.rgba(0.2, 0.19, 0.2, 0.95)
    border.color: input.activeFocus ? accentColor : Colors.withAlpha(Colors.border, 0.6)
    border.width: 1

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, root.radius - 1)
        color: Qt.rgba(0.22, 0.21, 0.22, 0.94)
        border.color: Colors.withAlpha(input.activeFocus ? accentColor : Colors.surface, input.activeFocus ? 0.2 : 0.32)
        border.width: 1
    }

    Behavior on border.color {
        ColorAnimation {
            duration: Colors.durationFast
        }
    }

    // Inner highlight
    SharedWidgets.InnerHighlight {}

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Colors.spacingM
        anchors.rightMargin: Colors.spacingM
        spacing: Colors.spacingS

        Text {
            text: "󰍉"
            color: input.activeFocus ? accentColor : Colors.textDisabled
            font.pixelSize: Colors.fontSizeXL
            font.family: Colors.fontMono
            Behavior on color {
                ColorAnimation {
                    duration: Colors.durationFast
                }
            }
        }

        Rectangle {
        id: categoryBadge
        readonly property string category: root.parent && root.parent.launcher ? root.parent.launcher.drunCategoryFilterLabel : ""
        visible: category !== "" && category !== "All"
        Layout.alignment: Qt.AlignVCenter
        radius: Colors.radiusSmall
        color: Colors.withAlpha(accentColor, 0.15)
        border.color: Colors.withAlpha(accentColor, 0.4)
        border.width: 1
        implicitHeight: 24
        implicitWidth: categoryLabel.implicitWidth + 16

        RowLayout {
            anchors.centerIn: parent
            spacing: 4
            Text {
                id: categoryLabel
                text: categoryBadge.category
                color: accentColor
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.Bold
            }
            SharedWidgets.IconButton {
                icon: "󰅖"
                size: 14
                iconSize: 10
                iconColor: accentColor
                onClicked: if (root.parent && root.parent.launcher) root.parent.launcher.setDrunCategoryFilter("")
            }
        }
    }

    TextInput {
            id: input
            Layout.fillWidth: true
            color: Colors.text
            font.pixelSize: Colors.fontSizeLarge
            verticalAlignment: Text.AlignVCenter
            selectByMouse: true
            selectionColor: Colors.highlight
            onVisibleChanged: if (!visible && activeFocus)
                focus = false

            Text {
                text: root.placeholder
                color: Colors.textDisabled
                font: input.font
                visible: !input.text && !input.activeFocus
            }

            Keys.onReturnPressed: root.accepted()
        }

        // Clear button
        SharedWidgets.IconButton {
            visible: input.text !== ""
            icon: "󰅖"
            size: 24
            iconSize: 14
            iconColor: Colors.textDisabled
            onClicked: {
                input.text = "";
                input.forceActiveFocus();
            }
        }
    }
}
