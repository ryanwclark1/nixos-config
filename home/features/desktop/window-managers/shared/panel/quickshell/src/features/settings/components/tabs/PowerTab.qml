import QtQuick
import "../../../../services"
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false

    SettingsTabPage {
        anchors.fill: parent
        tabId: root.tabId
        title: "Power & Sleep"
        iconName: "󰌪"

        SettingsCard {
            title: "Power Menu"
            iconName: "󰌪"
            description: "Configure countdown timing for destructive power actions."

            SettingsSliderRow {
                label: "Powermenu Countdown"
                min: 1000
                max: 10000
                step: 500
                value: Config.powermenuCountdown
                unit: "ms"
                onMoved: v => Config.powermenuCountdown = v
            }
        }

        SettingsCard {
            title: "Display"
            iconName: "󰍹"
            description: "Visual helpers and idle inhibition behavior."

            SettingsFieldGrid {
                maximumColumns: root.compactMode ? 1 : 2

                SettingsToggleRow {
                    label: "Screen Borders"
                    icon: "󰩪"
                    configKey: "showScreenBorders"
                }
                SettingsToggleRow {
                    label: "Hot Corners"
                    icon: "󰘖"
                    configKey: "hotCornersEnabled"
                }
                SettingsToggleRow {
                    label: "Idle Inhibitor"
                    icon: "󰈈"
                    configKey: "idleInhibitEnabled"
                }
                SettingsToggleRow {
                    label: "Prevent Idle When Playing"
                    icon: "󰎈"
                    configKey: "inhibitIdleWhenPlaying"
                }
            }
        }

        SettingsCard {
            title: "Battery Alerts"
            iconName: "󱃍"
            description: "Get notified when battery is running low."

            SettingsToggleRow {
                label: "Battery Alerts"
                icon: "󱃍"
                configKey: "batteryAlertsEnabled"
            }

            SettingsSliderRow {
                label: "Warning Threshold"
                min: 5
                max: 50
                value: Config.batteryWarningThreshold
                unit: "%"
                onMoved: v => {
                    Config.batteryWarningThreshold = v;
                    if (Config.batteryCriticalThreshold > v)
                        Config.batteryCriticalThreshold = v;
                }
            }

            SettingsSliderRow {
                label: "Critical Threshold"
                min: 5
                max: 30
                value: Config.batteryCriticalThreshold
                unit: "%"
                onMoved: v => {
                    Config.batteryCriticalThreshold = v;
                    if (Config.batteryWarningThreshold < v)
                        Config.batteryWarningThreshold = v;
                }
            }
        }

        SettingsCard {
            title: "AC Power Profile"
            iconName: "󰚥"
            description: "Timeout settings when connected to AC power. Set to 0 to disable."

            SettingsSliderRow {
                label: "Monitor Off"
                min: 0
                max: 60
                value: Config.powerAcMonitorTimeout
                unit: "min"
                onMoved: v => Config.powerAcMonitorTimeout = v
            }

            SettingsSliderRow {
                label: "Lock Screen"
                min: 0
                max: 60
                value: Config.powerAcLockTimeout
                unit: "min"
                onMoved: v => Config.powerAcLockTimeout = v
            }

            SettingsSliderRow {
                label: "Suspend"
                min: 0
                max: 120
                step: 5
                value: Config.powerAcSuspendTimeout
                unit: "min"
                onMoved: v => Config.powerAcSuspendTimeout = v
            }

            SettingsModeRow {
                label: "Suspend Action"
                currentValue: Config.powerAcSuspendAction
                options: [
                    { value: "suspend", label: "Suspend" },
                    { value: "hibernate", label: "Hibernate" },
                    { value: "suspend-then-hibernate", label: "Hybrid" }
                ]
                onModeSelected: v => Config.powerAcSuspendAction = v
            }
        }

        SettingsCard {
            title: "Battery Power Profile"
            iconName: "󰁹"
            description: "Timeout settings when running on battery. Set to 0 to disable."

            SettingsSliderRow {
                label: "Monitor Off"
                min: 0
                max: 30
                value: Config.powerBatMonitorTimeout
                unit: "min"
                onMoved: v => Config.powerBatMonitorTimeout = v
            }

            SettingsSliderRow {
                label: "Lock Screen"
                min: 0
                max: 30
                value: Config.powerBatLockTimeout
                unit: "min"
                onMoved: v => Config.powerBatLockTimeout = v
            }

            SettingsSliderRow {
                label: "Suspend"
                min: 0
                max: 60
                step: 5
                value: Config.powerBatSuspendTimeout
                unit: "min"
                onMoved: v => Config.powerBatSuspendTimeout = v
            }

            SettingsModeRow {
                label: "Suspend Action"
                currentValue: Config.powerBatSuspendAction
                options: [
                    { value: "suspend", label: "Suspend" },
                    { value: "hibernate", label: "Hibernate" },
                    { value: "suspend-then-hibernate", label: "Hybrid" }
                ]
                onModeSelected: v => Config.powerBatSuspendAction = v
            }
        }
    }
}
