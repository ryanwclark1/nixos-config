import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../../services"
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false

    property string _newRuleAppName: ""
    property string _newRuleAction: "mute"
    property string _newTtsExcludedApp: ""

    readonly property int _ruleCount: (Config.notifRules || []).length
    readonly property int _ttsExcludedCount: (Config.notifTtsExcludedApps || []).length
    readonly property string _positionSummary: {
        switch (Config.notifPosition) {
            case "top_left": return "Top Left";
            case "top": return "Top";
            case "top_right": return "Top Right";
            case "bottom_left": return "Bottom Left";
            case "bottom": return "Bottom";
            case "bottom_right": return "Bottom Right";
            default: return "Top Right";
        }
    }
    readonly property string _historySummary: !Config.notifHistoryEnabled
        ? "Disabled"
        : (Config.notifHistoryMaxCount + " kept / " + Config.notifHistoryMaxAgeDays + "d")
    readonly property string _ttsSummary: !Config.notifTtsEnabled
        ? "Disabled"
        : (Config.notifTtsEngine + " / " + Config.notifTtsRate + " wpm")

    function _timeoutLabel(milliseconds) {
        if (milliseconds <= 0)
            return "Persistent";
        var seconds = milliseconds / 1000;
        return (seconds % 1 === 0 ? seconds.toFixed(0) : seconds.toFixed(1)) + "s";
    }

    function _addTtsExcludedApp() {
        var name = root._newTtsExcludedApp.trim();
        if (name === "")
            return;
        var list = Config.notifTtsExcludedApps ? Config.notifTtsExcludedApps.slice() : [];
        for (var i = 0; i < list.length; i++) {
            if (String(list[i]).toLowerCase() === name.toLowerCase())
                return;
        }
        list.push(name);
        Config.notifTtsExcludedApps = list;
        root._newTtsExcludedApp = "";
        ttsExcludedAppInput.text = "";
    }

    function _removeTtsExcludedApp(index) {
        var list = Config.notifTtsExcludedApps ? Config.notifTtsExcludedApps.slice() : [];
        list.splice(index, 1);
        Config.notifTtsExcludedApps = list;
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
        settingsRoot: root.settingsRoot
        tabId: root.tabId
        title: "Notifications"
        iconName: "󰂚"
        compactMode: root.compactMode
        tightSpacing: root.tightSpacing

        SettingsSectionGroup {
            title: "Notification Overview"
            description: "Keep the most important delivery, retention, and speech state visible before drilling into per-feature controls."

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Colors.spacingM

                Repeater {
                    model: [
                        {
                            icon: "󰞕",
                            label: "Popups",
                            value: root._positionSummary
                        },
                        {
                            icon: "󰔛",
                            label: "Normal Timeout",
                            value: root._timeoutLabel(Config.notifTimeoutNormal)
                        },
                        {
                            icon: "arrow-counterclockwise.svg",
                            label: "History",
                            value: root._historySummary
                        },
                        {
                            icon: "󰗆",
                            label: "Speech",
                            value: root._ttsSummary
                        },
                        {
                            icon: "󰑓",
                            label: "Rules",
                            value: root._ruleCount + " override" + (root._ruleCount === 1 ? "" : "s")
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
            title: "Popup Behavior"
            description: "Placement, visual density, and urgency timeout rules for notification toasts."

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
                        icon: "eye-off.svg"
                        checked: Config.notifPrivacyMode
                        enabledText: "Notification body hidden in popups"
                        disabledText: "Full body shown in popups"
                        onToggled: Config.notifPrivacyMode = !Config.notifPrivacyMode
                    }
                }
            }

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
                        color: Colors.textSecondary
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
                        color: Colors.textSecondary
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
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeXS
                        leftPadding: Colors.spacingM
                    }
                }
            }
        }

        SettingsSectionGroup {
            title: "History & Speech"
            description: "Retention controls for the notification center, plus spoken alerts and app-level exclusions."

            SettingsCard {
                title: "History"
                iconName: "󰋚"
                description: "Retain dismissed notifications in the Notification Center."

                SettingsFieldGrid {
                    maximumColumns: root.compactMode ? 1 : 2

                    SettingsToggleRow {
                        label: "Notification History"
                        icon: "arrow-counterclockwise.svg"
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

            SettingsCard {
                title: "Text-to-Speech"
                iconName: "󰗆"
                description: "Read incoming notifications aloud using a TTS engine."

                SettingsToggleRow {
                    label: "Enable TTS"
                    icon: "󰗆"
                    checked: Config.notifTtsEnabled
                    enabledText: "Notifications are read aloud"
                    disabledText: "TTS is off"
                    onToggled: Config.notifTtsEnabled = !Config.notifTtsEnabled
                }

                SettingsModeRow {
                    label: "Engine"
                    icon: "󰓃"
                    currentValue: Config.notifTtsEngine
                    enabled: Config.notifTtsEnabled
                    options: [
                        { value: "espeak-ng", label: "espeak-ng" },
                        { value: "piper", label: "Piper" },
                        { value: "speak", label: "speak" }
                    ]
                    onModeSelected: v => Config.notifTtsEngine = v
                }

                SettingsSliderRow {
                    label: "Speech Rate"
                    min: 50
                    max: 400
                    step: 25
                    value: Config.notifTtsRate
                    unit: "wpm"
                    enabled: Config.notifTtsEnabled
                    onMoved: v => Config.notifTtsRate = v
                }

                SettingsSliderRow {
                    label: "Volume"
                    min: 0
                    max: 200
                    step: 10
                    value: Config.notifTtsVolume
                    enabled: Config.notifTtsEnabled
                    onMoved: v => Config.notifTtsVolume = v
                }

                SettingsActionButton {
                    label: "Test Voice"
                    iconName: "󰐊"
                    enabled: Config.notifTtsEnabled
                    onClicked: Quickshell.execDetached([
                        "qs-tts-speak",
                        "--rate=" + Config.notifTtsRate,
                        "--volume=" + Config.notifTtsVolume,
                        "--engine=" + Config.notifTtsEngine,
                        "This is a test of the notification read-aloud voice."
                    ])
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Colors.spacingS
                    enabled: Config.notifTtsEnabled

                    Text {
                        text: "Excluded Apps"
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeSmall
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: "Notifications from these apps will not be read aloud."
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeXS
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: Colors.spacingS
                        visible: Config.notifTtsExcludedApps && Config.notifTtsExcludedApps.length > 0

                        Repeater {
                            model: Config.notifTtsExcludedApps || []
                            delegate: SettingsRemovableChip {
                                required property var modelData
                                required property int index
                                onRemoved: root._removeTtsExcludedApp(index)
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Colors.spacingS

                        SettingsTextInputRow {
                            id: ttsExcludedAppInput
                            Layout.fillWidth: true
                            label: ""
                            leadingIcon: "󰀻"
                            placeholderText: "App name (e.g. Spotify)"
                            showClearButton: true
                            onTextEdited: value => root._newTtsExcludedApp = value
                            onSubmitted: root._addTtsExcludedApp()
                        }

                        SettingsActionButton {
                            label: "Add"
                            iconName: "󰐕"
                            compact: true
                            emphasized: root._newTtsExcludedApp.trim() !== ""
                            enabled: root._newTtsExcludedApp.trim() !== ""
                            onClicked: root._addTtsExcludedApp()
                        }
                    }
                }
            }
        }

        SettingsSectionGroup {
            title: "Application Rules"
            description: "Per-app overrides for muting or forcing timeout behavior when a particular source needs special handling."

            SettingsCard {
                title: "Rules"
                iconName: "󰑓"
                description: "Per-application overrides for notification handling."

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
                        color: Colors.textDisabled
                        font.pixelSize: Colors.fontSizeSmall
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                    }
                }

                Repeater {
                    model: Config.notifRules || []

                    delegate: SettingsListRow {
                        required property var modelData
                        required property int index

                        active: false
                        contentInset: Colors.spacingM
                        rowSpacing: Colors.spacingS

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
                                color: Colors.textSecondary
                                font.family: Colors.fontMono
                                font.pixelSize: Colors.fontSizeLarge
                            }
                        }

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
                                color: Colors.primaryAccent

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

                        SettingsActionButton {
                            label: "Remove"
                            iconName: "dismiss.svg"
                            compact: true
                            Layout.alignment: Qt.AlignVCenter
                            onClicked: root._removeRule(index)
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Colors.borderMedium
                    visible: Config.notifRules && Config.notifRules.length > 0
                }

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
                        iconName: "info.svg"
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
}
