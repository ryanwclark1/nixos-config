import QtQuick
import QtQuick.Layouts
import "../../../../services"
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false

    readonly property int _moduleCount: (Config.lockScreenMediaControls ? 1 : 0)
        + (Config.lockScreenWeather ? 1 : 0)
        + (Config.lockScreenSessionButtons ? 1 : 0)
        + (Config.lockScreenFingerprint ? 1 : 0)
    readonly property string _presentationSummary: Config.lockScreenCompact ? "Compact" : "Standard"
    readonly property string _unlockSummary: Config.lockScreenFingerprint ? "Password + fingerprint" : "Password only"

    SettingsTabPage {
        anchors.fill: parent
        settingsRoot: root.settingsRoot
        tabId: root.tabId
        title: "Lock Screen"
        iconName: "󰌾"
        compactMode: root.compactMode
        tightSpacing: root.tightSpacing

        SettingsSectionGroup {
            title: "Lock Screen Overview"
            description: "Presentation density, enabled modules, and unlock flow for the shell lock surface."

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Colors.spacingM

                Repeater {
                    model: [
                        {
                            icon: "󰘖",
                            label: "Presentation",
                            value: root._presentationSummary
                        },
                        {
                            icon: "󰓣",
                            label: "Modules",
                            value: root._moduleCount + " active"
                        },
                        {
                            icon: "󰈷",
                            label: "Unlock",
                            value: root._unlockSummary
                        },
                        {
                            icon: "󰔛",
                            label: "Countdown",
                            value: Config.lockScreenCountdown + " ms"
                        }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        width: root.compactMode ? parent.width : Math.max(180, Math.floor((parent.width - Colors.spacingM * 2) / 3))
                        implicitHeight: metricColumn.implicitHeight + Colors.spacingM * 2
                        radius: Colors.radiusLarge
                        color: Colors.withAlpha(Colors.surface, 0.38)
                        border.color: Colors.withAlpha(Colors.primary, 0.14)
                        border.width: 1

                        ColumnLayout {
                            id: metricColumn
                            anchors.fill: parent
                            anchors.margins: Colors.spacingM
                            spacing: Colors.spacingXS

                            Text {
                                text: modelData.icon
                                color: Colors.primary
                                font.family: Colors.fontMono
                                font.pixelSize: Colors.fontSizeLarge
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.label
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeXS
                                font.weight: Font.Black
                                font.letterSpacing: Colors.letterSpacingExtraWide
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.value
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeMedium
                                font.weight: Font.Bold
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }

        SettingsSectionGroup {
            title: "Modules & Unlock Flow"
            description: "Choose which elements appear on the lock screen and how long the pre-lock countdown lasts."

            SettingsCard {
                title: "Features"
                iconName: "󰌾"
                description: "Lock screen modules and pre-lock countdown timing."

                SettingsFieldGrid {
                    maximumColumns: root.compactMode ? 1 : 2

                    SettingsToggleRow {
                        label: "Compact Mode"
                        icon: "󰘖"
                        configKey: "lockScreenCompact"
                    }
                    SettingsToggleRow {
                        label: "Media Controls"
                        icon: "󰝚"
                        configKey: "lockScreenMediaControls"
                    }
                    SettingsToggleRow {
                        label: "Weather"
                        icon: "󰖙"
                        configKey: "lockScreenWeather"
                    }
                    SettingsToggleRow {
                        label: "Session Buttons"
                        icon: "󰐥"
                        configKey: "lockScreenSessionButtons"
                    }
                    SettingsToggleRow {
                        label: "Fingerprint Unlock"
                        icon: "󰈷"
                        configKey: "lockScreenFingerprint"
                    }
                }

                SettingsSliderRow {
                    label: "Lock Countdown"
                    min: 1000
                    max: 10000
                    step: 500
                    value: Config.lockScreenCountdown
                    unit: "ms"
                    onMoved: v => Config.lockScreenCountdown = v
                }
            }
        }
    }
}
