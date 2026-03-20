import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

Rectangle {
    id: root

    required property bool showingConfirm
    required property string confirmTitle

    signal confirmed
    signal cancelled

    visible: root.showingConfirm
    color: Colors.withAlpha(Colors.background, 0.9)
    radius: Appearance.radiusLarge

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 25
        Text {
            text: root.confirmTitle
            color: Colors.text
            font.pixelSize: Appearance.fontSizeXL
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }
        RowLayout {
            spacing: Appearance.paddingMedium
            Layout.alignment: Qt.AlignHCenter
            Rectangle {
                width: 100
                height: 40
                radius: Appearance.radiusLarge
                color: Colors.error
                Text {
                    text: "Yes"
                    color: Colors.text
                    anchors.centerIn: parent
                    font.bold: true
                }
                SharedWidgets.StateLayer {
                    id: yesStateLayer
                    hovered: yesHover.containsMouse
                    pressed: yesHover.pressed
                    stateColor: Colors.error
                }
                MouseArea {
                    id: yesHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        yesStateLayer.burst(mouse.x, mouse.y);
                        root.confirmed();
                    }
                }
            }
            Rectangle {
                width: 100
                height: 40
                radius: Appearance.radiusLarge
                color: Colors.surface
                Text {
                    text: "No"
                    color: Colors.text
                    anchors.centerIn: parent
                    font.bold: true
                }
                SharedWidgets.StateLayer {
                    id: noStateLayer
                    hovered: noHover.containsMouse
                    pressed: noHover.pressed
                }
                MouseArea {
                    id: noHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        noStateLayer.burst(mouse.x, mouse.y);
                        root.cancelled();
                    }
                }
            }
        }
    }
}
