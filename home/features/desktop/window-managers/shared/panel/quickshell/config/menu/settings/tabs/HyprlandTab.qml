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

        SettingsCard {
            title: "Display Profiles"
            iconName: "󰍺"
            description: "Saved monitor configurations for quick switching."

            SettingsToggleRow {
                label: "Auto-Apply Profiles"
                icon: "󰔠"
                checked: Config.displayAutoProfile
                onToggled: Config.displayAutoProfile = !Config.displayAutoProfile
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingS
                visible: Config.displayProfiles.length > 0

                Repeater {
                    model: Config.displayProfiles
                    delegate: SettingsListRow {
                        required property var modelData
                        required property int index
                        minimumHeight: 56

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Colors.spacingXS

                            Text {
                                text: modelData.name || ("Profile " + (index + 1))
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeMedium
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: {
                                    var mons = modelData.monitors || [];
                                    var names = [];
                                    for (var i = 0; i < mons.length; i++)
                                        names.push(mons[i].name);
                                    return names.join(", ") || "No monitors";
                                }
                                color: Colors.fgSecondary
                                font.pixelSize: Colors.fontSizeXS
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        SettingsActionButton {
                            compact: true
                            iconName: "󰅖"
                            label: "Delete"
                            onClicked: {
                                var profiles = Config.displayProfiles.slice();
                                profiles.splice(index, 1);
                                Config.displayProfiles = profiles;
                            }
                        }
                    }
                }
            }

            Text {
                visible: Config.displayProfiles.length === 0
                text: "No saved profiles. Use the Display Configuration dialog to save profiles."
                color: Colors.fgDim
                font.pixelSize: Colors.fontSizeSmall
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }
    }
}
