import QtQuick
import "../../../../services"
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
        title: "AI Model Usage"
        iconName: "board.svg"

        SettingsCard {
            title: "Providers"
            iconName: "settings.svg"
            description: "Enable the providers that should appear as tabs in the AI Model Usage popup."

            SettingsToggleRow {
                label: "Claude Code"
                icon: "brands/anthropic-symbolic.svg"
                configKey: "modelUsageClaudeEnabled"
                enabledText: "Claude Code appears as an available provider in AI Model Usage."
                disabledText: "Claude Code usage tracking is disabled."
            }

            SettingsToggleRow {
                label: "Codex CLI"
                icon: "brands/openai-symbolic.svg"
                configKey: "modelUsageCodexEnabled"
                enabledText: "Codex CLI appears as an available provider in AI Model Usage."
                disabledText: "Codex CLI usage tracking is disabled."
            }

            SettingsToggleRow {
                label: "Gemini CLI"
                icon: "brands/google-gemini-symbolic.svg"
                configKey: "modelUsageGeminiEnabled"
                enabledText: "Gemini CLI appears as an available provider in AI Model Usage."
                disabledText: "Gemini CLI usage tracking is disabled."
            }
        }


    }
}
