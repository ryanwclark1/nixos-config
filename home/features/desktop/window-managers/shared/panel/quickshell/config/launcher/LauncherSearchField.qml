import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

Rectangle {
    id: root
    property alias text: input.text
    property alias searchInput: input
    property string placeholder: "Search..."
    property color accentColor: Colors.primary
    
    signal accepted()
    signal escapePressed()

    height: 48
    radius: Colors.radiusMedium
    color: Colors.withAlpha(Colors.surface, 0.4)
    border.color: input.activeFocus ? accentColor : Colors.border
    border.width: 1
    
    Behavior on border.color { ColorAnimation { duration: Colors.durationFast } }

    // Inner highlight
    Rectangle {
        anchors.fill: parent; anchors.margins: 1; radius: parent.radius - 1
        color: "transparent"; border.color: Colors.borderLight; border.width: 1; opacity: 0.1
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Colors.spacingM
        anchors.rightMargin: Colors.spacingM
        spacing: Colors.spacingS

        Text {
            text: "󰍉"
            color: input.activeFocus ? accentColor : Colors.textDisabled
            font.pixelSize: 20
            font.family: Colors.fontMono
            Behavior on color { ColorAnimation { duration: Colors.durationFast } }
        }

        TextInput {
            id: input
            Layout.fillWidth: true
            color: Colors.text
            font.pixelSize: Colors.fontSizeLarge
            verticalAlignment: Text.AlignVCenter
            selectByMouse: true
            selectionColor: Colors.highlight
            
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
            size: 24; iconSize: 14
            iconColor: Colors.textDisabled
            onClicked: { input.text = ""; input.forceActiveFocus(); }
        }
    }
}
