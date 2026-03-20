import QtQuick
import QtQuick.Layouts
import "../../../../services"
import ".."

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false

    readonly property string _editorSummary: {
        switch (Config.screenshotEditor) {
            case "swappy": return "Swappy";
            case "satty": return "Satty";
            default: return "None";
        }
    }
    readonly property string _delaySummary: Config.screenshotDelay > 0
        ? Config.screenshotDelay + "s"
        : "Instant"

    SettingsTabPage {
        anchors.fill: parent
        settingsRoot: root.settingsRoot
        tabId: root.tabId
        title: "Screenshot"
        iconName: "󰹑"
        compactMode: root.compactMode
        tightSpacing: root.tightSpacing

        SettingsSectionGroup {
            title: "Screenshot Overview"
            description: "Editor, capture delay, and history retention at a glance."

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Colors.spacingM

                Repeater {
                    model: [
                        {
                            icon: "󰏫",
                            label: "Editor",
                            value: root._editorSummary
                        },
                        {
                            icon: "󰔛",
                            label: "Delay",
                            value: root._delaySummary
                        },
                        {
                            icon: "󰋚",
                            label: "History",
                            value: (Config.screenshotHistory || []).length + " / " + Config.screenshotHistoryMax
                        }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        width: root.compactMode ? parent.width : Math.max(180, Math.floor((parent.width - Colors.spacingM * 2) / 3))
                        implicitHeight: metricCol.implicitHeight + Colors.spacingM * 2
                        radius: Colors.radiusLarge
                        color: Colors.withAlpha(Colors.surface, 0.38)
                        border.color: Colors.withAlpha(Colors.primary, 0.14)
                        border.width: 1

                        ColumnLayout {
                            id: metricCol
                            anchors.fill: parent
                            anchors.margins: Colors.spacingM
                            spacing: Colors.spacingXS

                            Text {
                                text: modelData.icon
                                color: Colors.primary
                                font.family: Colors.fontMono
                                font.pixelSize: Colors.fontSizeLarge
                            }

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
            title: "Capture Behavior"
            description: "Post-capture editor, shutter delay, and OCR language for text extraction."

            SettingsCard {
                title: "Editor"
                iconName: "󰏫"
                description: "Open the screenshot in an annotation editor after capture."

                SettingsToggleRow {
                    label: "Edit After Capture"
                    icon: "󰏫"
                    checked: Config.screenshotEditAfterCapture
                    enabledText: "Screenshots open in editor automatically"
                    disabledText: "Screenshots saved directly"
                    onToggled: Config.screenshotEditAfterCapture = !Config.screenshotEditAfterCapture
                }

                SettingsModeRow {
                    label: "Editor Application"
                    icon: "󰀻"
                    currentValue: Config.screenshotEditor
                    options: [
                        { value: "none", label: "None" },
                        { value: "swappy", label: "Swappy" },
                        { value: "satty", label: "Satty" }
                    ]
                    onModeSelected: v => Config.screenshotEditor = v
                }

                SettingsInfoCallout {
                    visible: Config.screenshotEditAfterCapture && Config.screenshotEditor === "none"
                    iconName: "󰋗"
                    title: "No editor selected"
                    body: "\"Edit After Capture\" is enabled but no editor is selected. Choose Swappy or Satty above."
                }
            }

            SettingsCard {
                title: "Capture Delay"
                iconName: "󰔛"
                description: "Wait before taking the screenshot, useful for capturing menus or tooltips."

                SettingsModeRow {
                    label: "Delay"
                    currentValue: String(Config.screenshotDelay)
                    options: [
                        { value: "0", label: "None" },
                        { value: "3", label: "3s" },
                        { value: "5", label: "5s" },
                        { value: "10", label: "10s" }
                    ]
                    onModeSelected: v => Config.screenshotDelay = parseInt(v)
                }
            }

            SettingsCard {
                title: "OCR Language"
                iconName: "󰗊"
                description: "Tesseract language code for text recognition from screenshots."

                SettingsModeRow {
                    label: "Language"
                    currentValue: Config.ocrLanguage
                    options: [
                        { value: "eng", label: "English" },
                        { value: "deu", label: "German" },
                        { value: "fra", label: "French" },
                        { value: "spa", label: "Spanish" },
                        { value: "jpn", label: "Japanese" },
                        { value: "chi_sim", label: "Chinese (Simplified)" }
                    ]
                    onModeSelected: v => Config.ocrLanguage = v
                }
            }
        }

        SettingsSectionGroup {
            title: "History"
            description: "Recent screenshot retention for quick access."

            SettingsCard {
                title: "Screenshot History"
                iconName: "󰋚"
                description: "Number of recent screenshots to retain in the history list."

                SettingsSliderRow {
                    label: "Max History Count"
                    min: 5
                    max: 100
                    step: 5
                    value: Config.screenshotHistoryMax
                    onMoved: v => Config.screenshotHistoryMax = v
                }
            }
        }
    }
}
