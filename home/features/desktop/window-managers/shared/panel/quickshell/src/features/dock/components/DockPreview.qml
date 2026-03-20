import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../../services"
import "../../../shared"
import "../../../widgets" as SharedWidgets

// Popup window preview shown on dock item hover.
// Displays window title(s) and app icon for grouped windows.
PopupWindow {
    id: root

    required property var anchorItem
    required property var anchorWindow
    required property var toplevels
    required property string appName
    required property string appIcon
    required property bool vertical

    property bool hovered: false

    visible: hovered && toplevels.length > 0
    anchor.window: anchorWindow
    anchor.rect.x: vertical
        ? anchorWindow.itemRect(anchorItem).x - width - Config.popupGap
        : anchorWindow.itemRect(anchorItem).x + (anchorItem.width - width) / 2
    anchor.rect.y: vertical
        ? anchorWindow.itemRect(anchorItem).y + (anchorItem.height - height) / 2
        : anchorWindow.itemRect(anchorItem).y - height - Config.popupGap
    implicitWidth: previewContent.implicitWidth + Colors.paddingLarge * 2
    implicitHeight: previewContent.implicitHeight + Colors.paddingMedium * 2
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: Colors.radiusMedium
        color: Colors.popupSurface
        border.color: Colors.border
        border.width: 1

        ColumnLayout {
            id: previewContent
            anchors.fill: parent
            anchors.margins: Colors.paddingMedium
            spacing: Colors.spacingS

            Repeater {
                model: root.toplevels

                delegate: RowLayout {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    spacing: Colors.spacingS

                    AppIcon {
                        iconName: root.appIcon
                        appName: root.appName
                        iconSize: 20
                        fallbackIcon: "\u{F0BBB}"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: modelData.title || root.appName
                            color: Colors.text
                            font.pixelSize: Colors.fontSizeSmall
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                            Layout.maximumWidth: 220
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: root.toplevels.length > 1
                            text: "Window " + (index + 1)
                            color: Colors.textDisabled
                            font.pixelSize: Colors.fontSizeXS
                        }
                    }

                    // Close button for individual windows
                    SharedWidgets.IconButton {
                        icon: "dismiss.svg"
                        size: 20
                        iconSize: 12
                        onClicked: modelData.close()
                    }
                }
            }
        }
    }
}
