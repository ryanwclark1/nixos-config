import QtQuick
import QtQuick.Layouts
import "../../../services"
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""

    SettingsTabPage {
        anchors.fill: parent
        tabId: root.tabId
        title: "Shell Behavior"
        iconName: "󰒓"

        SettingsCard {
            title: "Shell"
            iconName: "󰒓"
            description: "Core shell visuals and transient notification behavior."

            SettingsFieldGrid {
                SettingsToggleRow {
                    label: "Floating Bar"
                    icon: "󰖲"
                    configKey: "barFloating"
                }
                SettingsToggleRow {
                    label: "Blur Effects"
                    icon: "󰃠"
                    configKey: "blurEnabled"
                }
            }

            SettingsSliderRow {
                label: "Notification Width"
                min: 280
                max: 520
                value: Config.notifWidth
                onMoved: v => Config.notifWidth = v
            }

            SettingsSliderRow {
                label: "Popup Duration"
                min: 2000
                max: 10000
                step: 500
                value: Config.popupTimer
                unit: "ms"
                onMoved: v => Config.popupTimer = v
            }
        }

        SettingsCard {
            title: "Launcher"
            iconName: "󰍉"
            description: "Default launcher mode and home screen hinting."

            SettingsModeRow {
                label: "Default Mode"
                currentValue: Config.launcherDefaultMode
                options: [
                    {
                        value: "drun",
                        label: "Apps"
                    },
                    {
                        value: "window",
                        label: "Windows"
                    },
                    {
                        value: "files",
                        label: "Files"
                    },
                    {
                        value: "ai",
                        label: "AI"
                    },
                    {
                        value: "clip",
                        label: "Clipboard"
                    },
                    {
                        value: "system",
                        label: "System"
                    },
                    {
                        value: "media",
                        label: "Media"
                    },
                    {
                        value: "run",
                        label: "Run"
                    },
                    {
                        value: "web",
                        label: "Web"
                    },
                    {
                        value: "emoji",
                        label: "Emoji"
                    },
                    {
                        value: "calc",
                        label: "Calc"
                    },
                    {
                        value: "bookmarks",
                        label: "Bookmarks"
                    },
                    {
                        value: "keybinds",
                        label: "Keybinds"
                    },
                    {
                        value: "nixos",
                        label: "NixOS"
                    },
                    {
                        value: "wallpapers",
                        label: "Wallpapers"
                    }
                ]
                onModeSelected: modeValue => Config.launcherDefaultMode = modeValue
            }

            SettingsFieldGrid {
                SettingsToggleRow {
                    label: "Show Mode Hints"
                    icon: "󰌌"
                    configKey: "launcherShowModeHints"
                }
                SettingsToggleRow {
                    label: "Show Home Sections"
                    icon: "󰆍"
                    configKey: "launcherShowHomeSections"
                }
                SettingsToggleRow {
                    label: "Background Preload"
                    icon: "󰔟"
                    configKey: "launcherEnablePreload"
                }
                SettingsToggleRow {
                    label: "Keep Query on Mode Switch"
                    icon: "󰍉"
                    configKey: "launcherKeepSearchOnModeSwitch"
                }
                SettingsToggleRow {
                    label: "Debug Launcher Timings"
                    icon: "󰔛"
                    configKey: "launcherEnableDebugTimings"
                }
            }

            SettingsSliderRow {
                label: "Max Results"
                min: 20
                max: 200
                step: 5
                value: Config.launcherMaxResults
                onMoved: v => Config.launcherMaxResults = v
            }

            SettingsSliderRow {
                label: "File Query Min Length"
                min: 1
                max: 6
                value: Config.launcherFileMinQueryLength
                onMoved: v => Config.launcherFileMinQueryLength = v
            }

            SettingsSliderRow {
                label: "File Search Max Results"
                min: 20
                max: 300
                step: 10
                value: Config.launcherFileMaxResults
                onMoved: v => Config.launcherFileMaxResults = v
            }

            SettingsSliderRow {
                label: "Cache TTL"
                min: 30
                max: 1800
                step: 30
                value: Config.launcherCacheTtlSec
                unit: "s"
                onMoved: v => Config.launcherCacheTtlSec = v
            }
        }

        SettingsCard {
            title: "Control Center"
            iconName: "󰖲"
            description: "Visibility and width of control center modules."

            SettingsFieldGrid {
                SettingsToggleRow {
                    label: "Quick Links"
                    icon: "󰖩"
                    configKey: "controlCenterShowQuickLinks"
                }
                SettingsToggleRow {
                    label: "Media Widget"
                    icon: "󰝚"
                    configKey: "controlCenterShowMediaWidget"
                }
            }

            SettingsSliderRow {
                label: "Control Center Width"
                min: 320
                max: 460
                value: Config.controlCenterWidth
                onMoved: v => Config.controlCenterWidth = v
            }
        }
    }
}
