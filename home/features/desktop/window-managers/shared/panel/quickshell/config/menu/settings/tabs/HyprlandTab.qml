import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../services"
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
        title: "Hyprland Layout"
        iconName: "󱗼"

        SettingsCard {
            title: "Display Configuration"
            iconName: "󰍺"
            description: "Open monitor arrangement, scaling, and output settings."

            SettingsActionButton {
                Layout.fillWidth: true
                iconName: "󰍺"
                label: "Configure Displays"
                emphasized: true
                onClicked: {
                    if (root.settingsRoot)
                        root.settingsRoot.close();
                    Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "toggleDisplayConfig"]);
                }
            }
        }

        SettingsCard {
            title: "Window Layout"
            iconName: "󱗼"
            description: "Select layout mode and tune gap and opacity values."

            SettingsToggleRow {
                label: "Master Layout"
                icon: "󱗼"
                checked: root.settingsRoot ? root.settingsRoot.layoutIsMaster : false
                enabledText: "Master"
                disabledText: "Dwindle"
                onToggled: {
                    if (!root.settingsRoot)
                        return;
                    var isMaster = !root.settingsRoot.layoutIsMaster;
                    CompositorAdapter.setHyprKeyword("general:layout", isMaster ? "master" : "dwindle", "Set layout");
                    root.settingsRoot.layoutIsMaster = isMaster;
                }
            }

            SettingsSliderRow {
                label: "Outer Gaps"
                min: 0
                max: 50
                value: root.settingsRoot ? root.settingsRoot.layoutGapsOut : 10
                onMoved: v => {
                    if (!root.settingsRoot)
                        return;
                    root.settingsRoot.layoutGapsOut = v;
                    CompositorAdapter.setHyprKeyword("general:gaps_out", v.toString(), "Set outer gaps");
                }
            }

            SettingsSliderRow {
                label: "Inner Gaps"
                min: 0
                max: 30
                value: root.settingsRoot ? root.settingsRoot.layoutGapsIn : 5
                onMoved: v => {
                    if (!root.settingsRoot)
                        return;
                    root.settingsRoot.layoutGapsIn = v;
                    CompositorAdapter.setHyprKeyword("general:gaps_in", v.toString(), "Set inner gaps");
                }
            }

            SettingsSliderRow {
                label: "Active Opacity"
                min: 0.5
                max: 1.0
                step: 0.05
                value: root.settingsRoot ? root.settingsRoot.layoutActiveOpacity : 1.0
                onMoved: v => {
                    if (!root.settingsRoot)
                        return;
                    root.settingsRoot.layoutActiveOpacity = v;
                    CompositorAdapter.setHyprKeyword("decoration:active_opacity", v.toString(), "Set active opacity");
                }
            }
        }
    }
}
