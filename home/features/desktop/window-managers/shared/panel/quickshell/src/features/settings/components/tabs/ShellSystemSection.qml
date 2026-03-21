import QtQuick
import QtQuick.Layouts
import "../../../../services"
import ".."

Item {
    id: root
    required property bool compactMode
    required property var settingsRoot

    implicitHeight: col.implicitHeight
    implicitWidth: col.implicitWidth

    readonly property var _panelDefs: [
        { id: "notifCenter", label: "Notification Center", icon: "alert.svg" },
        { id: "controlCenter", label: "Control Center", icon: "options.svg" },
        { id: "notepad", label: "Notepad", icon: "document.svg" },
        { id: "aiChat", label: "AI Chat", icon: "chat.svg" },
        { id: "commandPalette", label: "Command Palette", icon: "search-visual.svg" },
        { id: "powerMenu", label: "Power Menu", icon: "power.svg" },
        { id: "colorPicker", label: "Color Picker", icon: "color-palette.svg" },
        { id: "displayConfig", label: "Display Config", icon: "desktop.svg" },
        { id: "fileBrowser", label: "File Browser", icon: "folder.svg" },
        { id: "systemMonitor", label: "System Monitor", icon: "heart-pulse.svg" }
    ]

    function _togglePanel(panelId) {
        var list = Config.enabledPanels.slice();
        var idx = list.indexOf(panelId);
        if (idx !== -1)
            list.splice(idx, 1);
        else
            list.push(panelId);
        Config.enabledPanels = list;
        Config.scheduleSave();
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        spacing: Appearance.spacingL

        SettingsCard {
            id: card
            Layout.fillWidth: true
            title: "Shell"
            iconName: "settings.svg"
            description: "Core shell visuals and transient notification behavior."

            SettingsFieldGrid {
                maximumColumns: root.compactMode ? 1 : 2

                SettingsToggleRow {
                    label: "Floating Bar"
                    icon: "settings.svg"
                    configKey: "barFloating"
                }
                SettingsToggleRow {
                    label: "Blur Effects"
                    icon: "weather-sunny.svg"
                    configKey: "blurEnabled"
                }
                SettingsToggleRow {
                    label: "Debug Logging"
                    icon: "bug.svg"
                    configKey: "debug"
                }
                SettingsToggleRow {
                    label: "Bar Widget Load Logging"
                    icon: "alert.svg"
                    description: "Log to journal when bar widgets are disabled, fail to load, stay pending, or report zero size."
                    configKey: "barWidgetLoadLogging"
                }
            }

            SettingsSliderRow {
                label: "Notification Width"
                icon: "alert.svg"
                min: 280
                max: 520
                value: Config.notifWidth
                onMoved: v => Config.notifWidth = v
            }

            SettingsSliderRow {
                label: "Popup Duration"
                icon: "timer.svg"
                min: 2000
                max: 10000
                step: 500
                value: Config.popupTimer
                unit: "ms"
                onMoved: v => Config.popupTimer = v
            }
        }

        SettingsCard {
            Layout.fillWidth: true
            title: "Panel Enablement"
            iconName: "options.svg"
            description: "Disable unused panels to reduce memory. Changes take effect on next toggle."

            SettingsFieldGrid {
                maximumColumns: root.compactMode ? 1 : 2

                Repeater {
                    model: root._panelDefs
                    delegate: SettingsToggleRow {
                        required property var modelData
                        label: modelData.label
                        icon: modelData.icon
                        checked: Config.enabledPanels.indexOf(modelData.id) !== -1
                        onToggled: root._togglePanel(modelData.id)
                    }
                }
            }

            SettingsInfoCallout {
                iconName: "info.svg"
                title: "Memory savings"
                body: "Disabled panels are never created, saving memory and startup time. Re-enable any time."
            }
        }
    }
}
