import QtQuick
import QtQuick.Layouts
import "../../../../services"
import ".."
import "../../../../features/ai/services/AiProviderProfiles.js" as Profiles

Item {
    id: root
    property var settingsRoot: null
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false

    function persistedKey(provider) {
        switch (provider) {
            case "anthropic": return Config.aiAnthropicKey || "";
            case "openai": return Config.aiOpenaiKey || "";
            case "gemini": return Config.aiGeminiKey || "";
            default: return "";
        }
    }

    function setPersistedKey(provider, value) {
        var nextValue = String(value || "");
        switch (provider) {
            case "anthropic":
                Config.aiAnthropicKey = nextValue;
                break;
            case "openai":
                Config.aiOpenaiKey = nextValue;
                break;
            case "gemini":
                Config.aiGeminiKey = nextValue;
                break;
        }
    }

    function effectiveKey(provider) {
        var persisted = persistedKey(provider);
        return persisted !== "" ? persisted : AiService.sessionKey(provider);
    }

    function setRememberedKey(provider, remember, value) {
        var nextValue = String(value || "");
        if (remember) {
            setPersistedKey(provider, nextValue);
            AiService.setSessionKey(provider, "");
        } else {
            setPersistedKey(provider, "");
            AiService.setSessionKey(provider, nextValue);
        }
    }

    function toggleRemember(provider, currentRemember) {
        var nextRemember = !currentRemember;
        setRememberedKey(provider, nextRemember, effectiveKey(provider));
        return nextRemember;
    }

    SettingsTabPage {
        anchors.fill: parent
        tabId: root.tabId
        title: "AI Assistant"
        iconName: "chat.svg"

        SettingsCard {
            title: "Provider"
            iconName: "chat.svg"
            description: "Choose AI backend and model for the chat assistant."

            SettingsSelectRow {
                label: "Provider"
                icon: "󱁍"
                description: "A dropdown scales better here because providers may expand over time."
                currentValue: Config.aiProvider
                options: [
                    { value: "ollama", label: "Ollama" },
                    { value: "anthropic", label: "Anthropic" },
                    { value: "openai", label: "OpenAI" },
                    { value: "gemini", label: "Gemini" },
                    { value: "custom", label: "Custom" }
                ]
                onOptionSelected: value => Config.aiProvider = value
            }

            SettingsTextInputRow {
                visible: Config.aiProvider !== "ollama"
                label: "Model"
                leadingIcon: "󰘦"
                placeholderText: Config.aiProvider === "ollama" ? "e.g. llama3.2" : "Leave empty for default"
                text: Config.aiModel
                onTextEdited: value => Config.aiModel = value
            }

            ColumnLayout {
                visible: Config.aiProvider === "ollama"
                Layout.fillWidth: true
                spacing: Colors.spacingS

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Colors.spacingS

                    Text {
                        Layout.fillWidth: true
                        text: AiService.availableModels.length > 0
                            ? "Available models: " + AiService.availableModels.length
                            : "Available models"
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeSmall
                        font.weight: Font.Medium
                        wrapMode: Text.WordWrap
                    }

                    SettingsActionButton {
                        label: "Refresh"
                        iconName: "arrow-clockwise.svg"
                        compact: true
                        onClicked: AiService.refreshModels()
                    }
                }

                SettingsSelectRow {
                    visible: AiService.availableModels.length > 0
                    label: "Detected Models"
                    icon: "󰘦"
                    description: "Choose from models reported by Ollama instead of scanning a large chip list."
                    currentValue: Config.aiModel !== "" ? Config.aiModel : AiService.activeModel
                    maxMenuHeight: 220
                    options: AiService.availableModels.map(function (modelName) {
                        return {
                            value: String(modelName),
                            label: String(modelName)
                        };
                    })
                    onOptionSelected: value => Config.aiModel = value
                }

                SettingsInfoCallout {
                    visible: AiService.availableModels.length === 0
                    body: "No Ollama models were returned yet. Start Ollama, then refresh to load models from " +
                        (Config.aiCustomEndpoint || "http://localhost:11434") + "/api/tags."
                }

                SettingsTextInputRow {
                    label: "Model Override"
                    leadingIcon: "󰘦"
                    placeholderText: "e.g. llama3.2"
                    text: Config.aiModel
                    onTextEdited: value => Config.aiModel = value
                }
            }

            SettingsTextInputRow {
                visible: Config.aiProvider === "custom"
                label: "Custom Endpoint"
                leadingIcon: "󰌘"
                placeholderText: "https://api.example.com"
                text: Config.aiCustomEndpoint
                onTextEdited: value => Config.aiCustomEndpoint = value
            }
        }

        SettingsCard {
            title: "API Keys"
            iconName: "key.svg"
            description: "Fallback keys used when environment variables are not set."
            collapsible: true
            expanded: Config.aiProvider !== "ollama"

            SettingsInfoCallout {
                body: "Set ANTHROPIC_API_KEY, OPENAI_API_KEY, or GEMINI_API_KEY environment variables for automatic detection. These fields are fallbacks. Keys stay session-only by default; enable \"Remember\" only when you want the current provider key written to disk."
            }

            ColumnLayout {
                visible: Config.aiProvider === "anthropic"
                Layout.fillWidth: true
                spacing: Colors.spacingXS
                property bool _remember: Config.aiAnthropicKey !== ""
                SettingsSecretInputRow {
                    label: "Anthropic API Key"
                    leadingIcon: "key.svg"
                    placeholderText: "sk-ant-..."
                    text: root.effectiveKey("anthropic")
                    onTextEdited: value => root.setRememberedKey("anthropic", parent._remember, value)
                }
                SettingsToggleRow {
                    label: "Remember key"
                    icon: "save.svg"
                    checked: parent._remember
                    enabledText: "Key is persisted to disk."
                    disabledText: "Key is session-only (default, cleared on restart)."
                    onToggled: parent._remember = root.toggleRemember("anthropic", parent._remember)
                }
            }

            ColumnLayout {
                visible: Config.aiProvider === "openai" || Config.aiProvider === "custom"
                Layout.fillWidth: true
                spacing: Colors.spacingXS
                property bool _remember: Config.aiOpenaiKey !== ""
                SettingsSecretInputRow {
                    label: "OpenAI API Key"
                    leadingIcon: "key.svg"
                    placeholderText: "sk-..."
                    text: root.effectiveKey("openai")
                    onTextEdited: value => root.setRememberedKey("openai", parent._remember, value)
                }
                SettingsToggleRow {
                    label: "Remember key"
                    icon: "save.svg"
                    checked: parent._remember
                    enabledText: "Key is persisted to disk."
                    disabledText: "Key is session-only (default, cleared on restart)."
                    onToggled: parent._remember = root.toggleRemember("openai", parent._remember)
                }
            }

            ColumnLayout {
                visible: Config.aiProvider === "gemini"
                Layout.fillWidth: true
                spacing: Colors.spacingXS
                property bool _remember: Config.aiGeminiKey !== ""
                SettingsSecretInputRow {
                    label: "Gemini API Key"
                    leadingIcon: "key.svg"
                    placeholderText: "AIza..."
                    text: root.effectiveKey("gemini")
                    onTextEdited: value => root.setRememberedKey("gemini", parent._remember, value)
                }
                SettingsToggleRow {
                    label: "Remember key"
                    icon: "save.svg"
                    checked: parent._remember
                    enabledText: "Key is persisted to disk."
                    disabledText: "Key is session-only (default, cleared on restart)."
                    onToggled: parent._remember = root.toggleRemember("gemini", parent._remember)
                }
            }
        }

        SettingsCard {
            title: "Endpoint Override"
            iconName: "󰌘"
            description: "Per-provider base URL. Saved independently for each provider."
            collapsible: true
            expanded: false

            SettingsTextInputRow {
                label: "Base URL for " + Config.aiProvider
                leadingIcon: "󰌘"
                placeholderText: Profiles.isLocalProvider(Config.aiProvider, "") ? "http://localhost:11434" : "https://api.example.com"
                text: {
                    var profile = Profiles.loadProfile(Config.aiProviderProfiles, Config.aiProvider);
                    return profile.endpoint || "";
                }
                onTextEdited: value => {
                    Config.aiProviderProfiles = Profiles.saveProfile(
                        Config.aiProviderProfiles, Config.aiProvider, {
                            model: Config.aiModel,
                            temperature: Config.aiTemperature,
                            maxTokens: Config.aiMaxTokens,
                            endpoint: value
                        });
                    if (Config.aiProvider === "custom")
                        Config.aiCustomEndpoint = value;
                }
            }
        }

        SettingsCard {
            title: "Generation"
            iconName: "󰘦"
            description: "Control response length and creativity."

            SettingsSliderRow {
                label: "Temperature"
                min: 0.0
                max: 2.0
                step: 0.1
                value: Config.aiTemperature
                onMoved: v => Config.aiTemperature = v
            }

            SettingsSliderRow {
                label: "Max Tokens"
                min: 256
                max: 16384
                step: 256
                value: Config.aiMaxTokens
                onMoved: v => Config.aiMaxTokens = Math.round(v)
            }

            SettingsSliderRow {
                label: "Timeout (seconds)"
                min: 30
                max: 600
                step: 30
                value: Config.aiTimeout
                onMoved: v => Config.aiTimeout = Math.round(v)
            }
        }

        SettingsCard {
            title: "System Prompt"
            iconName: "edit.svg"
            description: "Custom instructions prepended to every conversation."
            collapsible: true
            expanded: Config.aiSystemPrompt.length > 0

            SettingsToggleRow {
                label: "Include System Context"
                icon: "󰒍"
                configKey: "aiSystemContext"
                enabledText: "Hostname, OS, CPU, RAM, and uptime are included as context."
                disabledText: "No system information is sent to the AI provider."
            }

            SettingsTextInputRow {
                label: "Custom System Prompt"
                leadingIcon: "edit.svg"
                placeholderText: "You are a helpful assistant..."
                text: Config.aiSystemPrompt
                onTextEdited: value => Config.aiSystemPrompt = value
            }
        }

        SettingsCard {
            title: "Limits"
            iconName: "󰎞"
            description: "Conversation history limits to manage storage."

            SettingsSliderRow {
                label: "Max Conversations"
                min: 5
                max: 100
                step: 5
                value: Config.aiMaxConversations
                onMoved: v => Config.aiMaxConversations = Math.round(v)
            }

            SettingsSliderRow {
                label: "Max Messages per Conversation"
                min: 20
                max: 500
                step: 10
                value: Config.aiMaxMessages
                onMoved: v => Config.aiMaxMessages = Math.round(v)
            }
        }
    }
}
