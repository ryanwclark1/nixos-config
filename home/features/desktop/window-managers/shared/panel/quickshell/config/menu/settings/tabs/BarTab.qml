import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../services"
import "../../../widgets" as SharedWidgets
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false
    property string validationMessage: ""
    readonly property var selectedBar: Config.selectedBar()
    readonly property string selectedBarDockMessage: root.selectedBar ? Config.barDockConflictMessage(root.selectedBar) : ""

    function candidateWith(patch) {
        if (!selectedBar) return null;
        var candidate = JSON.parse(JSON.stringify(selectedBar));
        var keys = Object.keys(patch || {});
        for (var i = 0; i < keys.length; ++i)
            candidate[keys[i]] = patch[keys[i]];
        return candidate;
    }

    function applyPatch(patch) {
        if (!selectedBar) return;
        var candidate = candidateWith(patch);
        validationMessage = "";
        if (!Config.updateBarConfig(selectedBar.id, patch))
            validationMessage = Config.barConflictMessage(candidate) || "That bar layout conflicts with another reserved edge.";
    }

    function toggleDisplayTarget(screenName) {
        if (!selectedBar) return;
        var targets = (selectedBar.displayTargets || []).slice();
        var idx = targets.indexOf(screenName);
        if (idx >= 0) targets.splice(idx, 1);
        else targets.push(screenName);
        applyPatch({ displayTargets: targets });
    }

    SettingsTabPage {
        anchors.fill: parent
        tabId: root.tabId
        title: "Bars"
        iconName: "󰕮"
        subtitle: "Manage independent bars, monitor assignment, and per-bar layout settings."

        SettingsCard {
            title: "Bar Configurations"
            iconName: "󰕮"
            description: "Select, add, and remove up to four independent bars."

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                Repeater {
                    model: Config.barConfigs
                    delegate: SettingsListRow {
                        required property var modelData
                        active: Config.selectedBarId === modelData.id
                        minimumHeight: root.compactMode ? 88 : 64

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Colors.spacingXS

                            Text {
                                text: modelData.name || "Bar"
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeMedium
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: Colors.spacingS

                                Text {
                                    text: (Config.sectionLabel("left", modelData.position) + "/" + Config.sectionLabel("center", modelData.position) + "/" + Config.sectionLabel("right", modelData.position))
                                    color: Colors.fgSecondary
                                    font.pixelSize: Colors.fontSizeXS
                                }

                                Rectangle {
                                    implicitWidth: metaText.implicitWidth + 16
                                    implicitHeight: 24
                                    radius: Colors.radiusPill
                                    color: Colors.withAlpha(Colors.primary, 0.08)
                                    border.color: Colors.border
                                    border.width: 1

                                    Text {
                                        id: metaText
                                        anchors.centerIn: parent
                                        text: (modelData.position || "top") + " • " + (modelData.displayMode || "all")
                                        color: Colors.fgSecondary
                                        font.pixelSize: Colors.fontSizeXS
                                    }
                                }
                            }
                        }

                        SettingsActionButton {
                            compact: true
                            iconName: "󰏫"
                            label: "Select"
                            emphasized: Config.selectedBarId === modelData.id
                            onClicked: Config.setSelectedBar(modelData.id)
                        }

                        SettingsActionButton {
                            compact: true
                            iconName: "󰅖"
                            label: "Remove"
                            enabled: Config.barConfigs.length > 1
                            onClicked: {
                                root.validationMessage = "";
                                Config.removeBar(modelData.id);
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Colors.spacingS

                    SettingsActionButton {
                        Layout.fillWidth: true
                        emphasized: true
                        iconName: "󰐕"
                        label: "Add Bar"
                        enabled: Config.barConfigs.length < Config.maxBars
                        onClicked: {
                            root.validationMessage = "";
                            if (!Config.addBar())
                                root.validationMessage = "No free edge is available for another enabled bar.";
                        }
                    }
                }
            }
        }

        SettingsCard {
            title: "Selected Bar"
            iconName: "󰖲"
            description: root.selectedBar ? "Edit edge placement, displays, and bar styling." : "Select a bar to edit."
            visible: !!root.selectedBar

            SettingsInfoCallout {
                visible: !!root.selectedBar && root.selectedBarDockMessage !== ""
                iconName: "󰀪"
                title: "Dock overlap"
                body: root.selectedBarDockMessage
            }

            SettingsTextInputRow {
                label: "Bar Name"
                leadingIcon: "󰓩"
                text: root.selectedBar ? root.selectedBar.name : ""
                onSubmitted: value => root.applyPatch({ name: value.trim() || "Bar" })
            }

            SettingsModeRow {
                label: "Position"
                currentValue: root.selectedBar ? root.selectedBar.position : "top"
                options: [
                    { value: "top", label: "Top" },
                    { value: "bottom", label: "Bottom" },
                    { value: "left", label: "Left" },
                    { value: "right", label: "Right" }
                ]
                onModeSelected: value => root.applyPatch({ position: value })
            }

            SettingsModeRow {
                label: "Enabled"
                currentValue: root.selectedBar && root.selectedBar.enabled ? "enabled" : "disabled"
                options: [
                    { value: "enabled", label: "Enabled" },
                    { value: "disabled", label: "Disabled" }
                ]
                onModeSelected: value => root.applyPatch({ enabled: value === "enabled" })
            }

            SettingsModeRow {
                label: "Display Mode"
                description: "Assign this bar to every monitor, the primary monitor, or a specific set of displays."
                currentValue: root.selectedBar ? root.selectedBar.displayMode : "all"
                options: [
                    { value: "all", label: "All" },
                    { value: "primary", label: "Primary" },
                    { value: "specific", label: "Specific" }
                ]
                onModeSelected: value => root.applyPatch({ displayMode: value, displayTargets: value === "specific" ? (root.selectedBar.displayTargets || []) : [] })
            }

            ColumnLayout {
                visible: root.selectedBar && root.selectedBar.displayMode === "specific"
                Layout.fillWidth: true
                spacing: Colors.spacingS

                Text {
                    text: "Specific Displays"
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeMedium
                    font.weight: Font.Medium
                }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Colors.spacingS

                    Repeater {
                        model: Quickshell.screens
                        delegate: SharedWidgets.FilterChip {
                            required property var modelData
                            label: modelData.name || "Display"
                            selected: root.selectedBar && (root.selectedBar.displayTargets || []).indexOf(modelData.name) !== -1
                            onClicked: root.toggleDisplayTarget(modelData.name)
                        }
                    }
                }
            }

            SettingsSliderRow {
                label: "Thickness"
                min: 24
                max: 72
                value: root.selectedBar ? root.selectedBar.height : Config.barHeight
                onMoved: value => root.applyPatch({ height: value })
            }

            SettingsSliderRow {
                label: "Margin"
                min: 0
                max: 40
                value: root.selectedBar ? root.selectedBar.margin : Config.barMargin
                onMoved: value => root.applyPatch({ margin: value })
            }

            SettingsSliderRow {
                label: "Opacity"
                min: 0.3
                max: 1.0
                step: 0.05
                value: root.selectedBar ? root.selectedBar.opacity : Config.barOpacity
                onMoved: value => root.applyPatch({ opacity: value })
            }

            SettingsModeRow {
                label: "Window Mode"
                currentValue: root.selectedBar && root.selectedBar.floating ? "floating" : "flush"
                options: [
                    { value: "floating", label: "Floating" },
                    { value: "flush", label: "Flush" }
                ]
                onModeSelected: value => root.applyPatch({ floating: value === "floating" })
            }
        }
    }
}
