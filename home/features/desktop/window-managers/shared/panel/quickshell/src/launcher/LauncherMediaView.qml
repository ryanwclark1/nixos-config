import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Widgets
import "../widgets" as SharedWidgets
import "../services"

ColumnLayout {
    id: root

    required property var mediaPlayers
    required property bool compactMode
    required property bool tightMode

    spacing: root.compactMode ? Colors.paddingSmall : Colors.paddingMedium

    Repeater {
        model: root.mediaPlayers
        delegate: Rectangle {
            Layout.fillWidth: true
            height: root.tightMode ? 96 : (root.compactMode ? 108 : 120)
            color: Colors.bgWidget
            radius: Colors.radiusMedium
            border.color: Colors.border
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: root.compactMode ? Colors.spacingM : Colors.paddingMedium
                spacing: root.compactMode ? Colors.paddingSmall : Colors.paddingMedium
                ClippingWrapperRectangle {
                    width: root.compactMode ? 72 : 90
                    height: root.compactMode ? 72 : 90
                    radius: Colors.radiusXS
                    color: Colors.surface
                    Image {
                        source: modelData.trackArtUrl || ""
                        sourceSize: Qt.size(128, 128)
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Text {
                        text: modelData.trackTitle || "Unknown"
                        color: Colors.text
                        font.pixelSize: root.compactMode ? Colors.fontSizeMedium : Colors.fontSizeLarge
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }
                    Text {
                        text: modelData.trackArtist || "Unknown"
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeSmall
                    }
                    Item {
                        Layout.fillHeight: true
                    }
                    RowLayout {
                        spacing: root.compactMode ? Colors.paddingSmall : Colors.paddingMedium
                        SharedWidgets.IconButton {
                            icon: "󰒮"
                            size: root.compactMode ? 26 : 30
                            iconSize: root.compactMode ? Colors.fontSizeLarge : Colors.fontSizeXL
                            iconColor: Colors.text
                            onClicked: (modelData._playerRef || modelData).previous()
                        }
                        SharedWidgets.IconButton {
                            icon: (modelData._playerRef || modelData).playbackState === Mpris.Playing ? "󰏤" : "󰐊"
                            size: root.compactMode ? 30 : 36
                            iconSize: root.compactMode ? Colors.fontSizeXL : Colors.fontSizeHuge
                            iconColor: Colors.primary
                            onClicked: (modelData._playerRef || modelData).playPause()
                        }
                        SharedWidgets.IconButton {
                            icon: "󰒭"
                            size: root.compactMode ? 26 : 30
                            iconSize: root.compactMode ? Colors.fontSizeLarge : Colors.fontSizeXL
                            iconColor: Colors.text
                            onClicked: (modelData._playerRef || modelData).next()
                        }
                    }
                }
            }
        }
    }
}
