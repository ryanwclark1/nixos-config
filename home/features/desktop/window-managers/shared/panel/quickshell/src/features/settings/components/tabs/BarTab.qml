import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../../services"
import "../../../../widgets" as SharedWidgets
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
    readonly property int barCount: (Config.barConfigs || []).length
    readonly property string selectedBarName: root.selectedBar ? String(root.selectedBar.name || "Bar") : "No bar selected"
    readonly property string selectedBarPositionLabel: {
        var position = root.selectedBar ? String(root.selectedBar.position || "top") : "top";
        return position.charAt(0).toUpperCase() + position.slice(1);
    }
    readonly property string selectedBarDisplaySummary: {
        if (!root.selectedBar)
            return "Not assigned";
        var mode = String(root.selectedBar.displayMode || "all");
        if (mode === "primary")
            return "Primary display";
        if (mode === "specific")
            return ((root.selectedBar.displayTargets || []).length || 0) + " specific";
        return "All displays";
    }

    function candidateWith(patch) {
        if (!selectedBar)
            return null;
        var candidate = JSON.parse(JSON.stringify(selectedBar));
        var keys = Object.keys(patch || {});
        for (var i = 0; i < keys.length; ++i)
            candidate[keys[i]] = patch[keys[i]];
        return candidate;
    }

    function applyPatch(patch) {
        if (!selectedBar)
            return;
        var candidate = candidateWith(patch);
        validationMessage = "";
        if (!Config.updateBarConfig(selectedBar.id, patch))
            validationMessage = Config.barConflictMessage(candidate) || "That bar layout conflicts with another reserved edge.";
    }

    function toggleDisplayTarget(screenName) {
        if (!selectedBar)
            return;
        var targets = (selectedBar.displayTargets || []).slice();
        var idx = targets.indexOf(screenName);
        if (idx >= 0)
            targets.splice(idx, 1);
        else
            targets.push(screenName);
        applyPatch({
            displayTargets: targets
        });
    }

    SettingsTabPage {
        anchors.fill: parent
        settingsRoot: root.settingsRoot
        tabId: root.tabId
        title: "Bar Layout"
        iconName: "󰕮"
        subtitle: "Manage independent bars, monitor assignment, and per-bar layout settings."
        compactMode: root.compactMode
        tightSpacing: root.tightSpacing

        SettingsSectionGroup {
            title: "Bar Overview"
            description: "The surface layout at a glance, including the active bar, how many bars are configured, and where the selected bar is assigned."

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Colors.spacingM

                Repeater {
                    model: [
                        {
                            icon: "options.svg",
                            label: "Active Bar",
                            value: root.selectedBarName
                        },
                        {
                            icon: "󰐕",
                            label: "Configured Bars",
                            value: root.barCount + " / " + Config.maxBars
                        },
                        {
                            icon: "󰌷",
                            label: "Edge",
                            value: root.selectedBarPositionLabel
                        },
                        {
                            icon: "󰍹",
                            label: "Display Scope",
                            value: root.selectedBarDisplaySummary
                        }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        width: root.compactMode ? parent.width : Math.max(180, Math.floor((parent.width - Colors.spacingM * 2) / 3))
                        implicitHeight: metricColumn.implicitHeight + Colors.spacingM * 2
                        radius: Colors.radiusLarge
                        color: Colors.withAlpha(Colors.surface, 0.38)
                        border.color: Colors.withAlpha(Colors.primary, 0.14)
                        border.width: 1

                        ColumnLayout {
                            id: metricColumn
                            anchors.fill: parent
                            anchors.margins: Colors.spacingM
                            spacing: Colors.spacingXS

                            SettingsMetricIcon { icon: modelData.icon }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.label
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeXS
                                font.weight: Font.Black
                                font.letterSpacing: Colors.letterSpacingExtraWide
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.value
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeMedium
                                font.weight: Font.Bold
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }

        SettingsSectionGroup {
            title: "Bar Collection"
            description: "Manage the set of bars available to the shell and switch between them before editing per-bar layout details."

            SettingsCard {
                title: "Modular Layout"
                iconName: "󰕮"
                description: "Enable true dynamic layout arrays. (Experimental)"

                SettingsToggleRow {
                    label: "Use Modular Entries"
                    icon: "󰕮"
                    configKey: "barUseModularEntries"
                    enabledText: "Uses barLeftEntries, etc. from config.json"
                    disabledText: "Uses legacy barLeftEntries, etc. from config.json"
                }
            }

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
                            minimumHeight: root.compactMode ? 112 : 64

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
                                        text: Config.sectionLabel("left", modelData.position) + "/" + Config.sectionLabel("center", modelData.position) + "/" + Config.sectionLabel("right", modelData.position)
                                        color: Colors.textSecondary
                                        font.pixelSize: Colors.fontSizeXS
                                    }

                                    Rectangle {
                                        implicitWidth: metaText.implicitWidth + 16
                                        implicitHeight: 24
                                        radius: Colors.radiusPill
                                        color: Colors.primaryFaint
                                        border.color: Colors.border
                                        border.width: 1

                                        Text {
                                            id: metaText
                                            anchors.centerIn: parent
                                            text: (modelData.position || "top") + " • " + (modelData.displayMode || "all")
                                            color: Colors.textSecondary
                                            font.pixelSize: Colors.fontSizeXS
                                        }
                                    }
                                }
                            }

                            Flow {
                                Layout.fillWidth: true
                                width: parent.width
                                spacing: Colors.spacingS

                                SettingsActionButton {
                                    compact: true
                                    iconName: "edit.svg"
                                    label: "Select"
                                    emphasized: Config.selectedBarId === modelData.id
                                    onClicked: Config.setSelectedBar(modelData.id)
                                }

                                SettingsActionButton {
                                    compact: true
                                    iconName: "dismiss.svg"
                                    label: "Remove"
                                    enabled: Config.barConfigs.length > 1
                                    onClicked: {
                                        root.validationMessage = "";
                                        Config.removeBar(modelData.id);
                                    }
                                }
                            }
                        }
                    }

                    SettingsActionButton {
                        Layout.fillWidth: true
                        emphasized: true
                        iconName: "add.svg"
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

        SettingsSectionGroup {
            title: "Active Bar"
            description: "Placement, display targeting, density, and visual behavior for the currently selected bar."

            SettingsInfoCallout {
                visible: root.validationMessage !== ""
                iconName: "󰀪"
                title: "Layout warning"
                body: root.validationMessage
            }

            SettingsCard {
                title: "Selected Bar"
                iconName: "options.svg"
                description: root.selectedBar ? "Edit edge placement, displays, and bar styling." : "Select a bar to edit."
                visible: !!root.selectedBar

                SettingsSelectRow {
                    label: "Editing"
                    icon: "options.svg"
                    description: "Switch the active bar here while comparing layout settings."
                    currentValue: String(Config.selectedBarId || "")
                    options: Config.barConfigs.map(function (barConfig) {
                        return {
                            value: String(barConfig.id || ""),
                            label: String(barConfig.name || "Bar")
                        };
                    })
                    onOptionSelected: value => Config.setSelectedBar(value)
                }

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
                    onSubmitted: value => root.applyPatch({
                        name: value.trim() || "Bar"
                    })
                }

                SettingsModeRow {
                    label: "Position"
                    currentValue: root.selectedBar ? root.selectedBar.position : "top"
                    options: [
                        {
                            value: "top",
                            label: "Top"
                        },
                        {
                            value: "bottom",
                            label: "Bottom"
                        },
                        {
                            value: "left",
                            label: "Left"
                        },
                        {
                            value: "right",
                            label: "Right"
                        }
                    ]
                    onModeSelected: value => root.applyPatch({
                        position: value
                    })
                }

                SettingsModeRow {
                    label: "Enabled"
                    currentValue: root.selectedBar && root.selectedBar.enabled ? "enabled" : "disabled"
                    options: [
                        {
                            value: "enabled",
                            label: "Enabled"
                        },
                        {
                            value: "disabled",
                            label: "Disabled"
                        }
                    ]
                    onModeSelected: value => root.applyPatch({
                        enabled: value === "enabled"
                    })
                }

                SettingsModeRow {
                    label: "Display Mode"
                    description: "Assign this bar to every monitor, the primary monitor, or a specific set of displays."
                    currentValue: root.selectedBar ? root.selectedBar.displayMode : "all"
                    options: [
                        {
                            value: "all",
                            label: "All"
                        },
                        {
                            value: "primary",
                            label: "Primary"
                        },
                        {
                            value: "specific",
                            label: "Specific"
                        }
                    ]
                    onModeSelected: value => root.applyPatch({
                        displayMode: value,
                        displayTargets: value === "specific" ? (root.selectedBar.displayTargets || []) : []
                    })
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
                    onMoved: value => root.applyPatch({
                        height: value
                    })
                }

                SettingsSliderRow {
                    label: "Margin"
                    min: 0
                    max: 40
                    value: root.selectedBar ? root.selectedBar.margin : Config.barMargin
                    onMoved: value => root.applyPatch({
                        margin: value
                    })
                }

                SettingsSliderRow {
                    label: "Opacity"
                    min: 0.3
                    max: 1.0
                    step: 0.05
                    value: root.selectedBar ? root.selectedBar.opacity : Config.barOpacity
                    onMoved: value => root.applyPatch({
                        opacity: value
                    })
                }

                SettingsModeRow {
                    label: "Window Mode"
                    currentValue: root.selectedBar && root.selectedBar.floating ? "floating" : "flush"
                    options: [
                        {
                            value: "floating",
                            label: "Floating"
                        },
                        {
                            value: "flush",
                            label: "Flush"
                        }
                    ]
                    onModeSelected: value => root.applyPatch({
                        floating: value === "floating"
                    })
                }

                SettingsToggleRow {
                    label: "Auto-Hide"
                    icon: "󰘊"
                    checked: root.selectedBar ? !!root.selectedBar.autoHide : false
                    onToggled: root.applyPatch({
                        autoHide: !(root.selectedBar && root.selectedBar.autoHide)
                    })
                }

                SettingsSliderRow {
                    visible: root.selectedBar && root.selectedBar.autoHide
                    label: "Auto-Hide Delay"
                    min: 100
                    max: 2000
                    step: 100
                    unit: "ms"
                    value: root.selectedBar ? root.selectedBar.autoHideDelay : 300
                    onMoved: value => root.applyPatch({
                        autoHideDelay: value
                    })
                }

                SettingsToggleRow {
                    label: "No Background"
                    icon: "options.svg"
                    checked: root.selectedBar ? !!root.selectedBar.noBackground : false
                    onToggled: root.applyPatch({
                        noBackground: !(root.selectedBar && root.selectedBar.noBackground)
                    })
                }

                SettingsToggleRow {
                    label: "Hide on Fullscreen"
                    icon: "fullscreen.svg"
                    checked: root.selectedBar ? !!root.selectedBar.maximizeDetect : false
                    onToggled: root.applyPatch({
                        maximizeDetect: !(root.selectedBar && root.selectedBar.maximizeDetect)
                    })
                }

                SettingsModeRow {
                    label: "Scroll Behavior"
                    currentValue: root.selectedBar ? root.selectedBar.scrollBehavior : "none"
                    options: [
                        {
                            value: "none",
                            label: "None"
                        },
                        {
                            value: "workspace",
                            label: "Workspace"
                        },
                        {
                            value: "volume",
                            label: "Volume"
                        }
                    ]
                    onModeSelected: value => root.applyPatch({
                        scrollBehavior: value
                    })
                }

                SettingsToggleRow {
                    label: "Shadow"
                    icon: "󰘷"
                    checked: root.selectedBar ? !!root.selectedBar.shadowEnabled : false
                    onToggled: root.applyPatch({
                        shadowEnabled: !(root.selectedBar && root.selectedBar.shadowEnabled)
                    })
                }

                SettingsSliderRow {
                    visible: root.selectedBar && root.selectedBar.shadowEnabled
                    label: "Shadow Opacity"
                    min: 0.1
                    max: 1.0
                    step: 0.05
                    value: root.selectedBar ? root.selectedBar.shadowOpacity : 0.3
                    onMoved: value => root.applyPatch({
                        shadowOpacity: value
                    })
                }

                SettingsSliderRow {
                    label: "Font Scale"
                    min: 0.5
                    max: 2.0
                    step: 0.1
                    value: root.selectedBar ? root.selectedBar.fontScale : 1.0
                    onMoved: value => root.applyPatch({
                        fontScale: value
                    })
                }

                SettingsSliderRow {
                    label: "Icon Scale"
                    min: 0.5
                    max: 2.0
                    step: 0.1
                    value: root.selectedBar ? root.selectedBar.iconScale : 1.0
                    onMoved: value => root.applyPatch({
                        iconScale: value
                    })
                }
            }
        }
    }
}
