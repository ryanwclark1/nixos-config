import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../../../../services"
import "../../../../widgets" as SharedWidgets
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: tightSpacing ? Colors.spacingM : Colors.spacingL
        spacing: Colors.spacingL

        Text {
            text: "Dashboard"
            color: Colors.text
            font.pixelSize: Colors.fontSizeHuge
            font.weight: Font.Bold
            font.letterSpacing: Colors.letterSpacingTight
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingL

            // Quick Stats
            SettingsCard {
                Layout.fillWidth: true
                title: "System Status"
                iconName: "󰄧"
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Colors.spacingS

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "CPU Usage"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeSmall; Layout.fillWidth: true }
                        Text { text: Math.round(SystemStatus.cpuUsage * 100) + "%"; color: Colors.primary; font.weight: Font.DemiBold }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Memory"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeSmall; Layout.fillWidth: true }
                        Text { text: Math.round(SystemStatus.memoryUsage * 100) + "%"; color: Colors.primary; font.weight: Font.DemiBold }
                    }
                }
            }

            // Media Quick View
            SettingsCard {
                Layout.fillWidth: true
                title: "Now Playing"
                iconName: "󰝚"
                visible: !!MediaService.playing || !!MediaService.hasPlayer

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Colors.spacingM

                    Rectangle {
                        width: 64
                        height: 64
                        radius: Colors.radiusSmall
                        color: Colors.bgWidget

                        Item {
                            anchors.fill: parent

                            Image {
                                anchors.fill: parent
                                source: MediaService.trackArtUrl || ""
                                fillMode: Image.PreserveAspectCrop
                            }

                            Text {
                                visible: !MediaService.trackArtUrl
                                anchors.centerIn: parent
                                text: "󰓃"
                                font.pixelSize: 32
                                color: Colors.textDisabled
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: MediaService.trackTitle || "Not Playing"
                            color: Colors.text
                            font.pixelSize: Colors.fontSizeMedium
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: MediaService.trackArtist || "Unknown Artist"
                            color: Colors.textSecondary
                            font.pixelSize: Colors.fontSizeSmall
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }

        SettingsSectionLabel { text: "QUICK ACTIONS" }

        Flow {
            Layout.fillWidth: true
            spacing: Colors.spacingM

            SettingsActionButton {
                label: "Restart Shell"
                iconName: "󰑐"
                onClicked: Quickshell.reload()
            }

            SettingsActionButton {
                label: "Clear Notifications"
                iconName: "󰎟"
                onClicked: NotificationManager.clearAll()
            }
        }

        Item { Layout.fillHeight: true }
    }
}
