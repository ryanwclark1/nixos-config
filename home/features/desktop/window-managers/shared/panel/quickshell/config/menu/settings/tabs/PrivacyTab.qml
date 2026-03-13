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
        title: "Privacy"
        iconName: "󰒃"

        SettingsCard {
            title: "Indicators"
            iconName: "󰒃"
            description: "Show active privacy-sensitive device usage in the bar."

            SettingsFieldGrid {
                SettingsToggleRow {
                    label: "Privacy Indicators"
                    icon: "󰒃"
                    configKey: "privacyIndicatorsEnabled"
                }
                SettingsToggleRow {
                    label: "Camera Monitoring"
                    icon: "󰄀"
                    configKey: "privacyCameraMonitoring"
                }
            }

            SettingsInfoCallout {
                iconName: "󰋗"
                title: "Privacy indicators"
                body: "Indicators appear in the bar when microphone, camera, or screen sharing is active."
            }
        }
    }
}
