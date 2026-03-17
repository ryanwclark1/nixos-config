import QtQuick
import QtQuick.Layouts
import Quickshell
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
        iconName: "󰒓"
        description: "Core shell visuals and transient notification behavior."

        SettingsFieldGrid {
            maximumColumns: root.compactMode ? 1 : 2

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
            icon: "󰂚"
            min: 280
            max: 520
            value: Config.notifWidth
            onMoved: v => Config.notifWidth = v
        }

        SettingsSliderRow {
            label: "Popup Duration"
            icon: "󰔛"
            min: 2000
            max: 10000
            step: 500
            value: Config.popupTimer
            unit: "ms"
            onMoved: v => Config.popupTimer = v
        }
    }
}
