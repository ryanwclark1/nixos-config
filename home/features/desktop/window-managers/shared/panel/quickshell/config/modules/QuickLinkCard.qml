import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import "../widgets" as SharedWidgets

Rectangle {
    id: root
    property string icon
    property string title
    property string subtitle
    property var clickCommand: []

    Layout.fillWidth: true
    implicitHeight: 68
    radius: Colors.radiusMedium
    color: Colors.bgWidget
    border.color: Colors.border
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.margins: Colors.spacingM
        spacing: Colors.spacingM

        Rectangle {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            radius: height / 2
            color: Colors.withAlpha(Colors.primary, 0.12)

            Text {
                anchors.centerIn: parent
                text: icon
                color: Colors.primary
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeXL
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                text: title
                color: Colors.text
                font.pixelSize: Colors.fontSizeMedium
                font.weight: Font.DemiBold
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                text: subtitle
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeXS
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }

        Text {
            text: "󰄮"
            color: Colors.textSecondary
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeMedium
        }
    }

    SharedWidgets.StateLayer {
        id: stateLayer
        hovered: quickLinkHover.containsMouse
        pressed: quickLinkHover.pressed
    }

    MouseArea {
        id: quickLinkHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => {
            stateLayer.burst(mouse.x, mouse.y);
            Quickshell.execDetached(clickCommand);
        }
    }
}
