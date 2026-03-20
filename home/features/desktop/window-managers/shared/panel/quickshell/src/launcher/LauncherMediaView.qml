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

    spacing: root.compactMode ? Appearance.paddingSmall : Appearance.paddingMedium

    Repeater {
        model: root.mediaPlayers
        delegate: Rectangle {
            Layout.fillWidth: true
            height: root.tightMode ? 96 : (root.compactMode ? 108 : 120)
            color: Colors.bgWidget
            radius: Appearance.radiusMedium
            border.color: Colors.border
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: root.compactMode ? Appearance.spacingM : Appearance.paddingMedium
                spacing: root.compactMode ? Appearance.paddingSmall : Appearance.paddingMedium
                ClippingWrapperRectangle {
                    width: root.compactMode ? 72 : 90
                    height: root.compactMode ? 72 : 90
                    radius: Appearance.radiusXS
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
                        font.pixelSize: root.compactMode ? Appearance.fontSizeMedium : Appearance.fontSizeLarge
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }
                    Text {
                        text: modelData.trackArtist || "Unknown"
                        color: Colors.textSecondary
                        font.pixelSize: Appearance.fontSizeSmall
                    }
                    Item {
                        Layout.fillHeight: true
                    }
                    RowLayout {
                        spacing: root.compactMode ? Appearance.paddingSmall : Appearance.paddingMedium
                        SharedWidgets.IconButton {
                            icon: "previous.svg"
                            size: root.compactMode ? 26 : 30
                            iconSize: root.compactMode ? Appearance.fontSizeLarge : Appearance.fontSizeXL
                            iconColor: Colors.text
                            tooltipText: "Previous track"
                            onClicked: (modelData._playerRef || modelData).previous()
                        }
                        SharedWidgets.IconButton {
                            icon: (modelData._playerRef || modelData).playbackState === Mpris.Playing ? "󰏤" : "󰐊"
                            size: root.compactMode ? 30 : 36
                            iconSize: root.compactMode ? Appearance.fontSizeXL : Appearance.fontSizeHuge
                            iconColor: Colors.primary
                            tooltipText: (modelData._playerRef || modelData).playbackState === Mpris.Playing ? "Pause" : "Play"
                            onClicked: (modelData._playerRef || modelData).playPause()
                        }
                        SharedWidgets.IconButton {
                            icon: "next.svg"
                            size: root.compactMode ? 26 : 30
                            iconSize: root.compactMode ? Appearance.fontSizeLarge : Appearance.fontSizeXL
                            iconColor: Colors.text
                            tooltipText: "Next track"
                            onClicked: (modelData._playerRef || modelData).next()
                        }
                    }
                }
            }
        }
    }
}
