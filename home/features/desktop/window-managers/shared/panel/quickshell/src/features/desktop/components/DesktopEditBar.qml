import QtQuick
import QtQuick.Layouts
import "../../../services"

Rectangle {
    required property bool editMode
    required property bool gridSnap
    required property var edgeMargins

    signal addWidgetRequested()
    signal toggleGridSnap()
    signal exitEditMode()

    visible: editMode
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottomMargin: edgeMargins.bottom + 20
    width: editRow.implicitWidth + 40
    height: 48
    radius: Appearance.radiusXL
    color: Colors.bgGlass
    border.color: Colors.primary
    border.width: 2

    RowLayout {
        id: editRow
        anchors.centerIn: parent
        spacing: Appearance.spacingL

        // Add Widget button
        Item {
            Layout.preferredWidth: addRow.implicitWidth
            Layout.preferredHeight: 32

            RowLayout {
                id: addRow
                anchors.centerIn: parent
                spacing: Appearance.spacingSM

                Text {
                    text: "󰐕"
                    color: Colors.primary
                    font.family: Appearance.fontMono
                    font.pixelSize: Appearance.fontSizeLarge
                }
                Text {
                    text: "Add Widget"
                    color: Colors.text
                    font.pixelSize: Appearance.fontSizeMedium
                    font.weight: Font.Medium
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: addWidgetRequested()
            }
        }

        // Separator
        Rectangle {
            width: 1
            height: 24
            color: Colors.border
        }

        // Grid Snap toggle
        Rectangle {
            Layout.preferredWidth: snapRow.implicitWidth + 16
            Layout.preferredHeight: 28
            radius: Appearance.radiusMedium
            color: gridSnap ? Colors.primaryTint : "transparent"
            border.color: gridSnap ? Colors.primary : Colors.border
            border.width: 1

            RowLayout {
                id: snapRow
                anchors.centerIn: parent
                spacing: Appearance.spacingXS
                Text {
                    text: "󰕰"
                    color: Colors.text
                    font.family: Appearance.fontMono
                    font.pixelSize: Appearance.fontSizeMedium
                }
                Text {
                    text: "Grid"
                    color: Colors.text
                    font.pixelSize: Appearance.fontSizeSmall
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: toggleGridSnap()
            }
        }

        // Separator
        Rectangle {
            width: 1
            height: 24
            color: Colors.border
        }

        // Exit Edit Mode
        Rectangle {
            Layout.preferredWidth: exitRow.implicitWidth + 16
            Layout.preferredHeight: 28
            radius: Appearance.radiusMedium
            color: Colors.errorLight
            border.color: Colors.error
            border.width: 1

            RowLayout {
                id: exitRow
                anchors.centerIn: parent
                spacing: Appearance.spacingXS
                Text {
                    text: "󰅖"
                    color: Colors.error
                    font.family: Appearance.fontMono
                    font.pixelSize: Appearance.fontSizeMedium
                }
                Text {
                    text: "Done"
                    color: Colors.error
                    font.pixelSize: Appearance.fontSizeSmall
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: exitEditMode()
            }
        }
    }
}
