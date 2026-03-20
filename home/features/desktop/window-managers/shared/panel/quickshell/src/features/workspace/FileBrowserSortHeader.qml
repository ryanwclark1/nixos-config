import QtQuick
import QtQuick.Layouts
import "../../services"

Rectangle {
    id: root

    required property string sortBy
    required property bool sortAsc
    required property bool showDetailColumns

    signal sortChanged(string field, bool ascending)

    Layout.fillWidth: true
    height: 32
    color: Colors.cardSurface

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Colors.border
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Appearance.spacingM
        anchors.rightMargin: Appearance.spacingM
        spacing: 0

        // Name column header
        Item {
            Layout.fillWidth: true
            Layout.preferredWidth: 100
            height: parent.height

            RowLayout {
                anchors.fill: parent
                spacing: Appearance.spacingXS
                Text {
                    text: "Name"
                    color: root.sortBy === "name" ? Colors.primary : Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeSmall
                    font.weight: Font.Medium
                }
                Text {
                    text: root.sortBy === "name" ? (root.sortAsc ? "↑" : "↓") : ""
                    color: Colors.primary
                    font.pixelSize: Appearance.fontSizeSmall
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.sortBy === "name") root.sortChanged("name", !root.sortAsc);
                    else root.sortChanged("name", true);
                }
            }
        }

        // Size column header
        Item {
            Layout.preferredWidth: 80
            height: parent.height

            RowLayout {
                anchors.fill: parent
                spacing: Appearance.spacingXS
                Text {
                    text: "Size"
                    color: root.sortBy === "size" ? Colors.primary : Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeSmall
                    font.weight: Font.Medium
                }
                Text {
                    text: root.sortBy === "size" ? (root.sortAsc ? "↑" : "↓") : ""
                    color: Colors.primary
                    font.pixelSize: Appearance.fontSizeSmall
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.sortBy === "size") root.sortChanged("size", !root.sortAsc);
                    else root.sortChanged("size", true);
                }
            }
        }

        // Date column header
        Item {
            visible: root.showDetailColumns
            Layout.preferredWidth: root.showDetailColumns ? 100 : 0
            height: parent.height

            RowLayout {
                anchors.fill: parent
                spacing: Appearance.spacingXS
                Text {
                    text: "Modified"
                    color: root.sortBy === "date" ? Colors.primary : Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeSmall
                    font.weight: Font.Medium
                }
                Text {
                    text: root.sortBy === "date" ? (root.sortAsc ? "↑" : "↓") : ""
                    color: Colors.primary
                    font.pixelSize: Appearance.fontSizeSmall
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.sortBy === "date") root.sortChanged("date", !root.sortAsc);
                    else root.sortChanged("date", false);
                }
            }
        }

        // Type column header
        Item {
            visible: root.showDetailColumns
            Layout.preferredWidth: root.showDetailColumns ? 60 : 0
            height: parent.height

            RowLayout {
                anchors.fill: parent
                spacing: Appearance.spacingXS
                Text {
                    text: "Type"
                    color: root.sortBy === "type" ? Colors.primary : Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeSmall
                    font.weight: Font.Medium
                }
                Text {
                    text: root.sortBy === "type" ? (root.sortAsc ? "↑" : "↓") : ""
                    color: Colors.primary
                    font.pixelSize: Appearance.fontSizeSmall
                }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.sortBy === "type") root.sortChanged("type", !root.sortAsc);
                    else root.sortChanged("type", true);
                }
            }
        }
    }
}
