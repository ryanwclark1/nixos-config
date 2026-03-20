import QtQuick
import "../../../../services"
import ".."

Item {
    id: root
    required property bool compactMode
    required property var settingsRoot

    implicitHeight: card.implicitHeight
    implicitWidth: card.implicitWidth

    SettingsCard {
        id: card
        anchors.fill: parent
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
}
