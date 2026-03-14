import QtQuick
import QtQuick.Layouts
import "../../../services"
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false

    // Local state for the add-rule form
    property string _newRuleAppName: ""
    property string _newRuleAction: "mute"

    function _msLabel(ms) {
        if (ms <= 0)
            return "Never";
        if (ms < 1000)
            return ms + "ms";
        return (ms / 1000).toFixed(ms % 1000 === 0 ? 0 : 1) + "s";
    }

    function _removeRule(index) {
        var rules = Config.notifRules ? Config.notifRules.slice() : [];
        rules.splice(index, 1);
        Config.notifRules = rules;
    }

    function _addRule() {
        var name = root._newRuleAppName.trim();
        if (name === "")
            return;
        var rules = Config.notifRules ? Config.notifRules.slice() : [];
        rules.push({
            appName: name,
            action: root._newRuleAction
        });
        Config.notifRules = rules;
        root._newRuleAppName = "";
        newAppNameInput.text = "";
    }

    SettingsTabPage {
        anchors.fill: parent
        tabId: root.tabId
        title: "Notifications"
        iconName: "󰂚"

        // ── 1. Popup Position ──────────────────────────────────────────────
        SettingsCard {
            title: "Popup Position"
            iconName: "󰞕"
            description: "Where notification popups appear on-screen."

            SettingsModeRow {
                label: "Screen Corner"
                currentValue: Config.notifPosition
                options: [
                    {
                        value: "top_left",
                        label: "Top Left"
                    },
                    {
                        value: "top",
                        label: "Top"
                    },
                    {
                        value: "top_right",
                        label: "Top Right"
                    },
                    {
                        value: "bottom_left",
                        label: "Bottom Left"
                    },
                    {
                        value: "bottom",
                        label: "Bottom"
                    },
                    {
                        value: "bottom_right",
                        label: "Bottom Right"
                    }
                ]
                onModeSelected: v => Config.notifPosition = v
            }
        }

        // ── 2. Popup Appearance ────────────────────────────────────────────
        SettingsCard {
            title: "Popup Appearance"
            iconName: "󰏘"
            description: "Visual style and layout of notification popups."

            SettingsSliderRow {
                label: "Popup Width"
                min: 200
                max: 600
                step: 10
                value: Config.notifWidth
                unit: "px"
                onMoved: v => Config.notifWidth = v
            }

            SettingsFieldGrid {
                maximumColumns: root.compactMode ? 1 : 2

                SettingsToggleRow {
                    label: "Compact Style"
                    icon: "󰉻"
                    checked: Config.notifCompact
                    enabledText: "Reduced padding and smaller artwork"
                    disabledText: "Full-size popup with artwork"
                    onToggled: Config.notifCompact = !Config.notifCompact
                }

                SettingsToggleRow {
                    label: "Privacy Mode"
                    icon: "󰒇"
                    checked: Config.notifPrivacyMode
                    enabledText: "Notification body hidden in popups"
                    disabledText: "Full body shown in popups"
                    onToggled: Config.notifPrivacyMode = !Config.notifPrivacyMode
                }
            }
        }

        // ── 3. Timeouts ────────────────────────────────────────────────────
        SettingsCard {
            title: "Timeouts"
            iconName: "󰔛"
            description: "How long popups stay visible per urgency level. Set to 0 for persistent."

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                SettingsSliderRow {
                    label: "Low Urgency"
                    min: 0
                    max: 10000
                    step: 500
                    value: Config.notifTimeoutLow
                    unit: "ms"
                    onMoved: v => Config.notifTimeoutLow = v
                }

                Text {
                    visible: Config.notifTimeoutLow <= 0
                    text: "Never auto-dismiss"
                    color: Colors.fgSecondary
                    font.pixelSize: Colors.fontSizeXS
                    leftPadding: Colors.spacingM
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                SettingsSliderRow {
                    label: "Normal Urgency"
                    min: 0
                    max: 15000
                    step: 500
                    value: Config.notifTimeoutNormal
                    unit: "ms"
                    onMoved: v => Config.notifTimeoutNormal = v
                }

                Text {
                    visible: Config.notifTimeoutNormal <= 0
                    text: "Never auto-dismiss"
                    color: Colors.fgSecondary
                    font.pixelSize: Colors.fontSizeXS
                    leftPadding: Colors.spacingM
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                SettingsSliderRow {
                    label: "Critical Urgency"
                    min: 0
                    max: 15000
                    step: 500
                    value: Config.notifTimeoutCritical
                    unit: "ms"
                    onMoved: v => Config.notifTimeoutCritical = v
                }

                Text {
                    visible: Config.notifTimeoutCritical <= 0
                    text: "Never auto-dismiss — requires manual action"
                    color: Colors.fgSecondary
                    font.pixelSize: Colors.fontSizeXS
                    leftPadding: Colors.spacingM
                }
            }
        }

        // ── 4. History ─────────────────────────────────────────────────────
        SettingsCard {
            title: "History"
            iconName: "󰋚"
            description: "Retain dismissed notifications in the Notification Center."

            SettingsFieldGrid {
                maximumColumns: root.compactMode ? 1 : 2

                SettingsToggleRow {
                    label: "Notification History"
                    icon: "󰋚"
                    checked: Config.notifHistoryEnabled
                    enabledText: "Dismissed notifications are saved"
                    disabledText: "Dismissed notifications are discarded"
                    onToggled: Config.notifHistoryEnabled = !Config.notifHistoryEnabled
                }
            }

            SettingsSliderRow {
                label: "Max Stored Count"
                min: 10
                max: 200
                step: 10
                value: Config.notifHistoryMaxCount
                enabled: Config.notifHistoryEnabled
                onMoved: v => Config.notifHistoryMaxCount = v
            }

            SettingsSliderRow {
                label: "Max Age"
                min: 1
                max: 30
                step: 1
                value: Config.notifHistoryMaxAgeDays
                unit: "d"
                enabled: Config.notifHistoryEnabled
                onMoved: v => Config.notifHistoryMaxAgeDays = v
            }
        }

        // ── 5. Rules ───────────────────────────────────────────────────────
        SettingsCard {
            title: "Rules"
            iconName: "󰑓"
            description: "Per-application overrides for notification handling."

            // Empty state
            ColumnLayout {
                visible: !Config.notifRules || Config.notifRules.length === 0
                Layout.fillWidth: true
                Layout.topMargin: Colors.spacingS
                Layout.bottomMargin: Colors.spacingS
                spacing: Colors.spacingS

                Text {
                    text: "󰂛"
                    color: Colors.textDisabled
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeHuge
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "No rules configured"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeMedium
                    font.weight: Font.DemiBold
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Add a rule below to override behaviour per application."
                    color: Colors.fgDim
                    font.pixelSize: Colors.fontSizeSmall
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }
            }

            // Existing rules list
            Repeater {
                model: Config.notifRules || []

                delegate: SettingsListRow {
                    required property var modelData
                    required property int index

                    active: false
                    contentInset: Colors.spacingM
                    rowSpacing: Colors.spacingS

                    // App icon badge
                    Rectangle {
                        width: 34
                        height: 34
                        radius: Colors.radiusSmall
                        color: Colors.withAlpha(Colors.text, 0.07)
                        border.color: Colors.border
                        border.width: 1
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            anchors.centerIn: parent
                            text: modelData.action === "mute" ? "󰂛" : "󰔛"
                            color: Colors.fgSecondary
                            font.family: Colors.fontMono
                            font.pixelSize: Colors.fontSizeLarge
                        }
                    }

                    // App name + action badge
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            text: modelData.appName
                            color: Colors.text
                            font.pixelSize: Colors.fontSizeMedium
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            implicitWidth: actionPillText.implicitWidth + 12
                            height: 18
                            radius: height / 2
                            color: Colors.withAlpha(Colors.primary, 0.14)

                            Text {
                                id: actionPillText
                                anchors.centerIn: parent
                                text: modelData.action === "mute" ? "mute" : "timeout override"
                                color: Colors.primary
                                font.pixelSize: Colors.fontSizeXS
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    // Remove button
                    SettingsActionButton {
                        label: "Remove"
                        iconName: "󰅖"
                        compact: true
                        Layout.alignment: Qt.AlignVCenter
                        onClicked: root._removeRule(index)
                    }
                }
            }

            // Divider between list and add form
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.withAlpha(Colors.border, 0.6)
                visible: Config.notifRules && Config.notifRules.length > 0
            }

            // Add-rule form
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingM

                Text {
                    text: "Add Rule"
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Font.DemiBold
                }

                SettingsTextInputRow {
                    id: newAppNameInput
                    Layout.fillWidth: true
                    label: ""
                    leadingIcon: "󰀻"
                    placeholderText: "Application name (e.g. Spotify)"
                    showClearButton: true
                    onTextEdited: value => root._newRuleAppName = value
                    onSubmitted: root._addRule()
                }

                SettingsModeRow {
                    label: "Action"
                    currentValue: root._newRuleAction
                    options: [
                        {
                            value: "mute",
                            label: "Mute"
                        },
                        {
                            value: "timeout_override",
                            label: "Timeout Override"
                        }
                    ]
                    onModeSelected: value => root._newRuleAction = value
                }

                SettingsInfoCallout {
                    visible: root._newRuleAction === "timeout_override"
                    iconName: "󰋗"
                    title: "Timeout Override"
                    body: "Applies the Low Urgency timeout to all notifications from this application, regardless of their urgency level."
                }

                SettingsActionButton {
                    label: "Add Rule"
                    iconName: "󰐕"
                    emphasized: root._newRuleAppName.trim() !== ""
                    enabled: root._newRuleAppName.trim() !== ""
                    onClicked: root._addRule()
                }
            }
        }
    }
}
