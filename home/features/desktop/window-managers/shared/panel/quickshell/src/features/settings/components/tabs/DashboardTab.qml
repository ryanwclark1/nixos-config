import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../../services"
import "../../../../widgets" as SharedWidgets
import ".."

Item {
    id: root

    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false

    SettingsTabPage {
        anchors.fill: parent
        settingsRoot: root.settingsRoot
        tabId: root.tabId
        compactMode: root.compactMode
        tightSpacing: root.tightSpacing

        SettingsSectionGroup {
            title: "Shell Snapshot"
            description: "The current session at a glance, with status and media surfaced first."

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingL

                SettingsCard {
                    Layout.fillWidth: true
                    title: "System Status"
                    iconName: "󰄧"

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacingS

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "CPU Usage"
                                color: Colors.textSecondary
                                font.pixelSize: Appearance.fontSizeSmall
                                Layout.fillWidth: true
                            }

                            Text {
                                text: Math.round(SystemStatus.cpuPercent * 100) + "%"
                                color: Colors.primary
                                font.weight: Font.DemiBold
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "Memory"
                                color: Colors.textSecondary
                                font.pixelSize: Appearance.fontSizeSmall
                                Layout.fillWidth: true
                            }

                            Text {
                                text: Math.round(SystemStatus.ramPercent * 100) + "%"
                                color: Colors.primary
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }

                SettingsCard {
                    Layout.fillWidth: true
                    title: "Now Playing"
                    iconName: "music-note-2.svg"
                    visible: MediaService.isPlaying || !!MediaService.currentPlayer

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacingM

                        Rectangle {
                            width: 64
                            height: 64
                            radius: Appearance.radiusSmall
                            color: Colors.bgWidget

                            Item {
                                anchors.fill: parent

                                Image {
                                    anchors.fill: parent
                                    source: MediaService.trackArtUrl || ""
                                    fillMode: Image.PreserveAspectCrop
                                }

                                SharedWidgets.SvgIcon {
                                    visible: !MediaService.trackArtUrl
                                    anchors.centerIn: parent
                                    source: "brands/github-symbolic.svg"
                                    size: Appearance.iconSizeMedium
                                    color: Colors.textDisabled
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Appearance.spacingXXS

                            Text {
                                text: MediaService.trackTitle || "Not Playing"
                                color: Colors.text
                                font.pixelSize: Appearance.fontSizeMedium
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: MediaService.trackArtist || "Unknown Artist"
                                color: Colors.textSecondary
                                font.pixelSize: Appearance.fontSizeSmall
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }

        SettingsSectionGroup {
            title: "Quick Actions"
            description: "A few high-value actions that help recover or inspect the shell quickly."

            Flow {
                Layout.fillWidth: true
                spacing: Appearance.spacingM

                SettingsActionButton {
                    label: "Restart Shell"
                    iconName: "arrow-clockwise.svg"
                    onClicked: Quickshell.reload()
                }

                SettingsActionButton {
                    label: Config.debug ? "Disable Debug" : "Enable Debug"
                    iconName: "bug.svg"
                    onClicked: Config.debug = !Config.debug
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
