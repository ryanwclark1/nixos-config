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
        iconName: "power.svg"

        SettingsCard {
            title: "Power Menu"
            iconName: "power.svg"
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
            iconName: "desktop.svg"
            description: "Visual helpers and idle inhibition behavior."

            SettingsFieldGrid {
                maximumColumns: root.compactMode ? 1 : 2

                SettingsToggleRow {
                    label: "Screen Borders"
                    icon: "power-sleep.svg"
                    configKey: "showScreenBorders"
                }
                SettingsToggleRow {
                    label: "Hot Corners"
                    icon: "lock-closed-filled.svg"
                    configKey: "hotCornersEnabled"
                }
                SettingsToggleRow {
                    label: "Idle Inhibitor"
                    icon: "desktop-filled.svg"
                    configKey: "idleInhibitEnabled"
                }
                SettingsToggleRow {
                    label: "Prevent Idle When Playing"
                    icon: "battery-saver.svg"
                    configKey: "inhibitIdleWhenPlaying"
                }
            }
        }

        SettingsCard {
            title: "Battery Alerts"
            iconName: "battery-full.svg"
            description: "Get notified when battery is running low."

            SettingsToggleRow {
                label: "Battery Alerts"
                icon: "dark-theme.svg"
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
            iconName: "power.svg"
            description: "Preferred idle timings while external power is connected."

            SettingsSliderRow {
                label: "Monitor Off"
                icon: "desktop.svg"
                min: 1
                max: 1800
                step: 1
                value: Config.powerAcMonitorTimeout
                unit: "min"
                onMoved: v => Config.powerAcMonitorTimeout = v
            }

            SettingsSliderRow {
                label: "Lock Screen"
                icon: "lock-closed.svg"
                min: 1
                max: 2400
                step: 1
                value: Config.powerAcLockTimeout
                unit: "min"
                onMoved: v => Config.powerAcLockTimeout = v
            }

            SettingsSliderRow {
                label: "Suspend"
                icon: "power-sleep.svg"
                min: 1
                max: 3600
                step: 1
                value: Config.powerAcSuspendTimeout
                unit: "min"
                onMoved: v => Config.powerAcSuspendTimeout = v
            }

            SettingsModeRow {
                label: "Suspend Action"
                icon: "power-sleep-filled.svg"
                currentValue: Config.powerAcSuspendAction
                options: [
                    { value: "suspend", label: "Suspend", icon: "power-sleep.svg" },
                    { value: "hibernate", label: "Hibernate", icon: "power-sleep-filled.svg" },
                    { value: "poweroff", label: "Power Off", icon: "power.svg" }
                ]
                onModeSelected: value => Config.powerAcSuspendAction = value
            }
        }

        SettingsCard {
            title: "Battery Power Profile"
            iconName: "battery-saver.svg"
            description: "Preferred idle timings while running on battery."

            SettingsSliderRow {
                label: "Monitor Off"
                icon: "desktop.svg"
                min: 1
                max: 1200
                step: 1
                value: Config.powerBatMonitorTimeout
                unit: "min"
                onMoved: v => Config.powerBatMonitorTimeout = v
            }

            SettingsSliderRow {
                label: "Lock Screen"
                icon: "lock-closed.svg"
                min: 1
                max: 1800
                step: 1
                value: Config.powerBatLockTimeout
                unit: "min"
                onMoved: v => Config.powerBatLockTimeout = v
            }

            SettingsSliderRow {
                label: "Suspend"
                icon: "power-sleep.svg"
                min: 1
                max: 2400
                step: 1
                value: Config.powerBatSuspendTimeout
                unit: "min"
                onMoved: v => Config.powerBatSuspendTimeout = v
            }

            SettingsModeRow {
                label: "Suspend Action"
                icon: "power-sleep-filled.svg"
                currentValue: Config.powerBatSuspendAction
                options: [
                    { value: "suspend", label: "Suspend", icon: "power-sleep.svg" },
                    { value: "hibernate", label: "Hibernate", icon: "power-sleep-filled.svg" },
                    { value: "poweroff", label: "Power Off", icon: "power.svg" }
                ]
                onModeSelected: value => Config.powerBatSuspendAction = value
            }
        }

    }
}
