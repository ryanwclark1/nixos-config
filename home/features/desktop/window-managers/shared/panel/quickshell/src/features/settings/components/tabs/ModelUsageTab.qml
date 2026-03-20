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
        title: "Model Usage"
        iconName: "board.svg"

        SettingsCard {
            title: "Providers"
            iconName: "settings.svg"
            description: "Enable or disable usage tracking for each AI coding assistant."

            SettingsToggleRow {
                label: "Claude Code"
                icon: "brands/github-symbolic.svg"
                configKey: "modelUsageClaudeEnabled"
                enabledText: "Claude Code usage is tracked and shown in the bar."
                disabledText: "Claude Code usage tracking is disabled."
            }

            SettingsToggleRow {
                label: "Codex CLI"
                icon: "terminal.svg"
                configKey: "modelUsageCodexEnabled"
                enabledText: "Codex CLI usage is tracked and shown in the bar."
                disabledText: "Codex CLI usage tracking is disabled."
            }

            SettingsToggleRow {
                label: "Gemini CLI"
                icon: "data-trending.svg"
                configKey: "modelUsageGeminiEnabled"
                enabledText: "Gemini CLI usage is tracked and shown in the bar."
                disabledText: "Gemini CLI usage tracking is disabled."
            }
        }

        SettingsCard {
            title: "Display"
            iconName: "widgets.svg"
            description: "Choose which provider and metric to show in the bar widget."

            SettingsModeRow {
                label: "Active Provider"
                currentValue: Config.modelUsageActiveProvider
                options: [
                    {
                        value: "claude",
                        label: "Claude"
                    },
                    {
                        value: "codex",
                        label: "Codex"
                    },
                    {
                        value: "gemini",
                        label: "Gemini"
                    }
                ]
                onModeSelected: value => Config.modelUsageActiveProvider = value
            }

            SettingsModeRow {
                label: "Bar Metric"
                currentValue: Config.modelUsageBarMetric
                options: [
                    {
                        value: "prompts",
                        label: "Prompts"
                    },
                    {
                        value: "tokens",
                        label: "Tokens"
                    }
                ]
                onModeSelected: value => Config.modelUsageBarMetric = value
            }
        }

        SettingsCard {
            title: "Polling"
            iconName: "timer.svg"
            description: "How often to refresh usage data from local files."

            SettingsModeRow {
                label: "Refresh Interval"
                currentValue: String(Config.modelUsageRefreshSec)
                options: [
                    {
                        value: "15",
                        label: "15s"
                    },
                    {
                        value: "30",
                        label: "30s"
                    },
                    {
                        value: "60",
                        label: "60s"
                    },
                    {
                        value: "120",
                        label: "120s"
                    }
                ]
                onModeSelected: value => Config.modelUsageRefreshSec = parseInt(value, 10) || 30
            }
        }
    }
}
