import QtQuick
import QtQuick.Layouts
import "../../../../services"
import "../../../../widgets" as SharedWidgets
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false

    SharedWidgets.Ref { service: SystemStatus }
    SharedWidgets.Ref { service: MediaService }
    SharedWidgets.Ref { service: WallpaperService }

    SettingsTabPage {
        anchors.fill: parent
        tabId: root.tabId
        title: "System Dashboard"
        iconName: "󰕮"
        subtitle: "A high-level overview of your system and shell environment."

        GridLayout {
            Layout.fillWidth: true
            columns: root.compactMode ? 1 : 2
            columnSpacing: Colors.spacingL
            rowSpacing: Colors.spacingL

            // --- PERFORMANCE CARD ---
            SettingsCard {
                Layout.fillWidth: true
                title: "System Performance"
                iconName: "󰍛"
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Colors.spacingL

                    ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "CPU Load"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Black }
                        Text { text: SystemStatus.cpuUsage; color: Colors.primary; font.pixelSize: Colors.fontSizeXXL; font.weight: Font.Bold }
                        Text { text: "Temp: " + SystemStatus.cpuTemp; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeSmall }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "Memory"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Black }
                        Text { text: SystemStatus.ramUsage; color: Colors.secondary; font.pixelSize: Colors.fontSizeXXL; font.weight: Font.Bold }
                        Text { text: "Net: " + SystemStatus.netDown + " ↓"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeSmall }
                    }
                }
            }

            // --- ENVIRONMENT CARD ---
            SettingsCard {
                Layout.fillWidth: true
                title: "Environment"
                iconName: "󰏘"

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Colors.spacingM

                    Rectangle {
                        Layout.preferredWidth: 120
                        Layout.preferredHeight: 68
                        radius: Colors.radiusSmall
                        color: Colors.bgWidget
                        clip: true
                        border.color: Colors.border
                        border.width: 1

                        Image {
                            anchors.fill: parent
                            source: {
                                var keys = Object.keys(WallpaperService.wallpapers);
                                var path = WallpaperService.wallpapers["__all__"]
                                    || (keys.length > 0 ? WallpaperService.wallpapers[keys[0]] : "");
                                return path ? "file://" + path : ""
                            }
                            fillMode: Image.PreserveAspectCrop
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Text { text: "Active Theme"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Black }
                        Text { text: Config.themeName || "Custom (Wal)"; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.Bold }
                        
                        SettingsActionButton {
                            label: "Switch Theme"
                            compact: true
                            onClicked: root.settingsRoot.setCurrentTab("theme")
                        }
                    }
                }
            }

            // --- MEDIA CARD ---
            SettingsCard {
                Layout.fillWidth: true
                title: "Active Media"
                iconName: "󰓃"
                visible: MediaService.currentPlayer != null

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Colors.spacingM

                    Rectangle {
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 64
                        radius: Colors.radiusSmall
                        color: Colors.bgWidget
                        clip: true

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

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text { 
                            text: MediaService.trackTitle || "Nothing playing"
                            color: Colors.text
                            font.pixelSize: Colors.fontSizeMedium
                            font.weight: Font.Bold
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
                        
                        RowLayout {
                            spacing: Colors.spacingS
                            SharedWidgets.IconButton {
                                icon: "󰒮"
                                size: 24
                                onClicked: MediaService.previous()
                            }
                            SharedWidgets.IconButton {
                                icon: MediaService.isPlaying ? "󰏤" : "󰐊"
                                size: 24
                                onClicked: MediaService.playPause()
                            }
                            SharedWidgets.IconButton {
                                icon: "󰒭"
                                size: 24
                                onClicked: MediaService.next()
                            }
                        }
                    }
                }
            }

            // --- STATUS SUMMARY ---
            SettingsCard {
                Layout.fillWidth: true
                title: "Status Overview"
                iconName: "󰒓"

                SettingsFieldGrid {
                    maximumColumns: 2
                    
                    Text { 
                        text: "󰁹 " + (SystemStatus.isBatteryPowered ? "On Battery" : "AC Power")
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeSmall
                    }
                    Text { 
                        text: "󰛳 " + (SystemStatus.overallStatus === "healthy" ? "System Healthy" : "Issues Detected")
                        color: SystemStatus.overallStatus === "healthy" ? Colors.success : Colors.error
                        font.pixelSize: Colors.fontSizeSmall
                    }
                    Text { 
                        text: "󰂚 " + SystemStatus.activeIncidents.length + " Alerts"
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeSmall
                    }
                    Text { 
                        text: "󰏘 " + (Config.useDynamicTheming ? "Dynamic Mode" : "Static Mode")
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeSmall
                    }
                }
            }
        }
    }
}
