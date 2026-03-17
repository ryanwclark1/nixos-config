pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "config/AiProviders.js" as Providers

QtObject {
    id: root

    // ── Provider state ──────────────────────────
    readonly property string activeProvider: Config.aiProvider
    readonly property string activeModel: {
        if (Config.aiModel)
            return Config.aiModel;
        if (Config.aiProvider === "ollama" && availableModels.length > 0)
            return availableModels[0];
        return Providers.defaultModel(Config.aiProvider);
    }
    property var availableModels: Providers.defaultModels(Config.aiProvider)

    // ── Conversation state ──────────────────────
    property var conversations: []
    property string activeConversationId: ""
    property int _nextConversationNum: 1

    readonly property var activeConversation: {
        for (var i = 0; i < conversations.length; i++) {
            if (conversations[i].id === activeConversationId)
                return conversations[i];
        }
        return null;
    }

    readonly property var activeMessages: activeConversation ? activeConversation.messages : []

    // ── Streaming state ─────────────────────────
    property bool isStreaming: false
    property string streamingContent: ""
    property string lastError: ""

    // ── Token usage (from last response) ──────
    property int lastPromptTokens: 0
    property int lastCompletionTokens: 0
    readonly property int lastTotalTokens: lastPromptTokens + lastCompletionTokens

    property var _statusConn: Connections {
        target: SystemStatus
        function onNewIncident(incident) {
            if (root.isStreaming) return;
            // Proactively ask the AI to explain and fix the incident
            var prompt = "I've detected a system incident: **" + incident.signature + "**\n\n" +
                "Summary: " + incident.summary + "\n" +
                "Severity: " + incident.severity + "\n\n" +
                "Please analyze this and suggest a fix using the [COMMAND: label | cmd args] format if possible.";
            
            root.sendMessage(prompt);
            // Open the AI chat surface automatically for high severity
            if (incident.severity === "error") {
                Quickshell.execDetached(["quickshell", "ipc", "call", "SurfaceService", "openSurface", "aiChat"]);
            }
        }
    }

    // ── Command & Script Execution ──────────────
    property var pendingCommand: null // { label: string, cmd: [] }
    property var pendingScript: null  // { name: string, content: string }
    
    function executePendingCommand() {
        if (!pendingCommand) return;
        Quickshell.execDetached(pendingCommand.cmd);
        _addSystemMessage("Executed: `" + pendingCommand.cmd.join(" ") + "`");
        pendingCommand = null;
    }

    function cancelPendingCommand() {
        pendingCommand = null;
    }

    function installPendingScript() {
        if (!pendingScript) return;
        _runInstallScript(pendingScript.name, pendingScript.content);
        pendingScript = null;
    }

    function cancelPendingScript() {
        pendingScript = null;
    }

    function _runInstallScript(name, content) {
        var binDir = (Quickshell.env("HOME") || "/home") + "/.local/bin";
        var path = binDir + "/" + name;
        
        // Ensure binDir exists and write file
        var cmd = ["sh", "-c", "mkdir -p '" + binDir + "' && cat > '" + path + "' && chmod +x '" + path + "'"];
        var proc = Qt.createQmlObject('import Quickshell.Io; Process { command: ' + JSON.stringify(cmd) + '; stdinEnabled: true }', root);
        proc.onStarted.connect(function() {
            proc.write(content);
            proc.stdinEnabled = false;
        });
        proc.onExited.connect(function(code) {
            if (code === 0) {
                _addSystemMessage("Successfully installed script to `" + path + "`.\nIt is now available in your PATH.");
            } else {
                _addSystemMessage("Failed to install script to `" + path + "`.");
            }
            proc.destroy();
        });
        proc.running = true;
    }

    function _extractCommands(content) {
        // 1. Look for [COMMAND: label | cmd arg1 arg2]
        var cmdRegex = /\[COMMAND:\s*([^|\]]+)\s*\|\s*([^\]]+)\]/g;
        var cmdMatch;
        while ((cmdMatch = cmdRegex.exec(content)) !== null) {
            var label = cmdMatch[1].trim();
            var cmdStr = cmdMatch[2].trim();
            var cmdParts = cmdStr.split(/\s+/);
            root.pendingCommand = { label: label, cmd: cmdParts };
        }

        // 2. Look for [SCRIPT: name | content]
        // Note: content can span multiple lines
        var scriptRegex = /\[SCRIPT:\s*([^|\]]+)\s*\|([\s\S]*?)\]/g;
        var scriptMatch;
        while ((scriptMatch = scriptRegex.exec(content)) !== null) {
            root.pendingScript = {
                name: scriptMatch[1].trim(),
                content: scriptMatch[2].trim()
            };
        }

        // 3. Look for [RENAME_WORKSPACE: id | name]
        var renameRegex = /\[RENAME_WORKSPACE:\s*([^|\]]+)\s*\|\s*([^\]]+)\]/g;
        var renameMatch;
        while ((renameMatch = renameRegex.exec(content)) !== null) {
            WorkspaceIdentityService.setWorkspaceName(renameMatch[1].trim(), renameMatch[2].trim());
        }
    }

    // ── Session Persistence ─────────────────────
    property string currentInputText: ""
    readonly property string sessionPath: (Quickshell.env("HOME") || "/home") + "/.local/state/quickshell/ai-chat-session.json"

    function saveSession() {
        if (_loading) return;
        var data = {
            activeConversationId: root.activeConversationId,
            currentInputText: root.currentInputText
        };
        sessionFile.setText(JSON.stringify(data));
    }

    property FileView sessionFile: FileView {
        path: root.sessionPath
        onLoaded: {
            try {
                var data = JSON.parse(this.text);
                root.activeConversationId = data.activeConversationId || "";
                root.currentInputText = data.currentInputText || "";
                if (root.activeConversationId) {
                    for (var i = 0; i < root.conversations.length; i++) {
                        if (root.conversations[i].id === root.activeConversationId) {
                            // Found active conversation
                            break;
                        }
                    }
                }
            } catch(e) {}
        }
    }

    onActiveConversationIdChanged: {
        saveSession();
    }

    onCurrentInputTextChanged: saveSession()

    // ── Persistence ─────────────────────────────
    readonly property string savePath: (Quickshell.env("HOME") || "/home") + "/.local/state/quickshell/ai-chat.json"
    property bool _loading: false

    property FileView _chatFile: FileView {
        path: root.savePath
        blockLoading: true
        printErrors: false
        onLoaded: root._loadData()
        onLoadFailed: error => {
            if (error === 2) {
                // File doesn't exist yet — create default
                root.newConversation();
                root._saveData();
                return;
            }
            console.error("AiService: failed to load: " + error);
        }
        onSaveFailed: error => console.error("AiService: failed to save: " + error)
    }

    property Timer _saveTimer: Timer {
        interval: 500
        onTriggered: root._saveData()
    }

    function _scheduleSave() {
        if (!_loading) _saveTimer.restart();
    }

    function _loadData() {
        var raw = _chatFile.text();
        if (!raw) {
            newConversation();
            return;
        }
        _loading = true;
        try {
            var data = JSON.parse(raw);
            if (data.conversations && Array.isArray(data.conversations) && data.conversations.length > 0) {
                conversations = data.conversations;
                // Compute next number
                var maxNum = 0;
                for (var i = 0; i < conversations.length; i++) {
                    var num = parseInt(conversations[i].id.replace("conv-", "")) || 0;
                    if (num > maxNum) maxNum = num;
                }
                _nextConversationNum = maxNum + 1;
            }
            if (data.activeConversationId) {
                var found = false;
                for (var j = 0; j < conversations.length; j++) {
                    if (conversations[j].id === data.activeConversationId) { found = true; break; }
                }
                activeConversationId = found ? data.activeConversationId : (conversations.length > 0 ? conversations[0].id : "");
            }
        } catch (e) {
            console.error("AiService: failed to parse JSON: " + e);
        }
        _loading = false;
        if (conversations.length === 0) {
            newConversation();
        }
    }

    function _saveData() {
        // Enforce max conversations
        var convs = conversations;
        while (convs.length > Config.aiMaxConversations) {
            // Remove oldest (first) that isn't active
            var removed = false;
            for (var i = 0; i < convs.length; i++) {
                if (convs[i].id !== activeConversationId) {
                    convs = convs.slice(0, i).concat(convs.slice(i + 1));
                    removed = true;
                    break;
                }
            }
            if (!removed) break;
        }
        conversations = convs;

        var data = {
            conversations: conversations,
            activeConversationId: activeConversationId
        };
        _chatFile.setText(JSON.stringify(data, null, 2));
    }

    // ── Conversation Management ─────────────────
    function newConversation() {
        var id = "conv-" + _nextConversationNum++;
        var conv = {
            id: id,
            title: "New Chat",
            messages: [],
            provider: Config.aiProvider,
            model: activeModel,
            createdAt: Date.now()
        };
        var newConvs = conversations.slice();
        newConvs.push(conv);
        conversations = newConvs;
        activeConversationId = id;
        _scheduleSave();
    }

    function deleteConversation(id) {
        if (conversations.length <= 1) return;
        var newConvs = [];
        for (var i = 0; i < conversations.length; i++) {
            if (conversations[i].id !== id) newConvs.push(conversations[i]);
        }
        if (activeConversationId === id) {
            activeConversationId = newConvs.length > 0 ? newConvs[newConvs.length - 1].id : "";
        }
        conversations = newConvs;
        _scheduleSave();
    }

    function setActiveConversation(id) {
        activeConversationId = id;
        _scheduleSave();
    }

    function renameConversation(id, newTitle) {
        var trimmed = (newTitle || "").trim();
        if (!trimmed) return;
        var newConvs = conversations.slice();
        for (var i = 0; i < newConvs.length; i++) {
            if (newConvs[i].id === id) {
                newConvs[i] = _cloneConv(newConvs[i]);
                newConvs[i].title = trimmed;
                break;
            }
        }
        conversations = newConvs;
        _scheduleSave();
    }

    function clearConversation(id) {
        var newConvs = conversations.slice();
        for (var i = 0; i < newConvs.length; i++) {
            if (newConvs[i].id === id) {
                newConvs[i] = _cloneConv(newConvs[i]);
                newConvs[i].messages = [];
                break;
            }
        }
        conversations = newConvs;
        _scheduleSave();
    }

    function _cloneConv(conv) {
        return {
            id: conv.id,
            title: conv.title,
            messages: conv.messages.slice(),
            provider: conv.provider,
            model: conv.model,
            createdAt: conv.createdAt
        };
    }

    function _appendMessage(role, content) {
        var newConvs = conversations.slice();
        for (var i = 0; i < newConvs.length; i++) {
            if (newConvs[i].id === activeConversationId) {
                newConvs[i] = _cloneConv(newConvs[i]);
                var msgs = newConvs[i].messages;
                // Enforce max messages
                while (msgs.length >= Config.aiMaxMessages * 2) {
                    msgs.shift();
                }
                msgs.push({
                    role: role,
                    content: content,
                    timestamp: Date.now()
                });
                break;
            }
        }
        conversations = newConvs;
    }

    // ── Streaming ───────────────────────────────
    property Process _streamProc: Process {
        id: streamProc
        running: false

        stdout: SplitParser {
            onRead: line => {
                if (line.indexOf("CONTENT:") === 0) {
                    root.streamingContent += line.substring(8);
                } else if (line.indexOf("ERROR:") === 0) {
                    root.lastError = line.substring(6);
                } else if (line.indexOf("USAGE:") === 0) {
                    try {
                        var usage = JSON.parse(line.substring(6));
                        if (usage.prompt !== undefined) root.lastPromptTokens = usage.prompt;
                        if (usage.completion !== undefined) root.lastCompletionTokens = usage.completion;
                    } catch (e) { /* ignore parse errors */ }
                }
                // "DONE" is handled by onExited
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (root.isStreaming) {
                // Commit whatever we have
                if (root.streamingContent.trim().length > 0) {
                    root._appendMessage("assistant", root.streamingContent);
                    root._extractCommands(root.streamingContent);
                    root._autoTitle();
                } else if (exitCode !== 0 && !root.lastError) {
                    root.lastError = "Process exited with code " + exitCode;
                }
                root.isStreaming = false;
                root._scheduleSave();
            }
        }
    }

    // ── Slash Commands ────────────────────────────
    readonly property var slashCommands: [
        { cmd: "/new",     desc: "Start a new conversation" },
        { cmd: "/clear",   desc: "Clear current conversation" },
        { cmd: "/model",   desc: "Switch model (/model name)" },
        { cmd: "/temp",    desc: "Set temperature (/temp 0.7)" },
        { cmd: "/provider",desc: "Switch provider (/provider ollama)" },
        { cmd: "/models",  desc: "List available models" },
        { cmd: "/help",    desc: "Show available commands" }
    ]

    function _handleSlashCommand(text) {
        var trimmed = text.trim();
        if (trimmed.charAt(0) !== "/") return false;

        var parts = trimmed.split(/\s+/);
        var cmd = parts[0].toLowerCase();
        var arg = parts.slice(1).join(" ").trim();

        switch (cmd) {
            case "/new":
                newConversation();
                return true;

            case "/clear":
                clearConversation(activeConversationId);
                _addSystemMessage("Conversation cleared.");
                return true;

            case "/model":
                if (!arg) {
                    _addSystemMessage("Current model: **" + activeModel + "**\nUsage: `/model <name>`");
                    return true;
                }
                // Fuzzy match against available models
                var matched = _fuzzyMatchModel(arg);
                if (matched) {
                    Config.aiModel = matched;
                    _addSystemMessage("Model switched to **" + matched + "**");
                } else {
                    _addSystemMessage("Model not found: `" + arg + "`\nAvailable: " +
                        (availableModels.length > 0 ? availableModels.join(", ") : "(refresh models first)"));
                }
                return true;

            case "/temp":
                if (!arg) {
                    _addSystemMessage("Temperature: **" + Config.aiTemperature + "**\nUsage: `/temp 0.0-2.0`");
                    return true;
                }
                var temp = parseFloat(arg);
                if (isNaN(temp) || temp < 0 || temp > 2.0) {
                    _addSystemMessage("Invalid temperature. Range: 0.0 - 2.0");
                    return true;
                }
                Config.aiTemperature = temp;
                _addSystemMessage("Temperature set to **" + temp + "**");
                return true;

            case "/provider":
                if (!arg) {
                    _addSystemMessage("Current provider: **" + Providers.providerLabel(Config.aiProvider) + "**\nAvailable: " +
                        Providers.allProviders().map(function(p) { return Providers.providerLabel(p); }).join(", "));
                    return true;
                }
                var providerMatch = _fuzzyMatchProvider(arg);
                if (providerMatch) {
                    Config.aiProvider = providerMatch;
                    Config.aiModel = ""; // Reset to provider default
                    _addSystemMessage("Provider switched to **" + Providers.providerLabel(providerMatch) + "** (model: " + activeModel + ")");
                } else {
                    _addSystemMessage("Unknown provider: `" + arg + "`");
                }
                return true;

            case "/models":
                refreshModels();
                var modelList = availableModels.length > 0
                    ? availableModels.join("\n- ")
                    : "(none loaded — try again after refresh)";
                _addSystemMessage("**Available models** (" + Providers.providerLabel(Config.aiProvider) + "):\n- " + modelList);
                return true;

            case "/help":
                var helpLines = slashCommands.map(function(c) {
                    return "`" + c.cmd + "` — " + c.desc;
                });
                _addSystemMessage("**Commands:**\n" + helpLines.join("\n"));
                return true;

            default:
                _addSystemMessage("Unknown command: `" + cmd + "`\nType `/help` for available commands.");
                return true;
        }
    }

    function _addSystemMessage(content) {
        _appendMessage("system", content);
        _scheduleSave();
    }

    function _fuzzyMatchModel(query) {
        var q = query.toLowerCase();
        // Exact match
        for (var i = 0; i < availableModels.length; i++) {
            if (availableModels[i].toLowerCase() === q) return availableModels[i];
        }
        // Prefix match
        for (var j = 0; j < availableModels.length; j++) {
            if (availableModels[j].toLowerCase().indexOf(q) === 0) return availableModels[j];
        }
        // Contains match
        for (var k = 0; k < availableModels.length; k++) {
            if (availableModels[k].toLowerCase().indexOf(q) !== -1) return availableModels[k];
        }
        return null;
    }

    function _fuzzyMatchProvider(query) {
        var q = query.toLowerCase();
        var all = Providers.allProviders();
        for (var i = 0; i < all.length; i++) {
            if (all[i] === q || Providers.providerLabel(all[i]).toLowerCase() === q) return all[i];
        }
        // Prefix match
        for (var j = 0; j < all.length; j++) {
            if (all[j].indexOf(q) === 0 || Providers.providerLabel(all[j]).toLowerCase().indexOf(q) === 0) return all[j];
        }
        return null;
    }

    function sendMessage(text, contextWindow, visualContext) {
        if (!text || text.trim().length === 0) return;
        if (isStreaming) return;

        // Handle slash commands locally
        if (text.trim().charAt(0) === "/" && _handleSlashCommand(text)) return;

        lastError = "";
        streamingContent = "";
        lastPromptTokens = 0;
        lastCompletionTokens = 0;

        // API key guard for cloud providers
        var provider = Config.aiProvider;
        if (Providers.needsApiKey(provider) && !apiKeyAvailable(provider)) {
            var envName = Providers.envKeyName(provider);
            _appendMessage("user", text.trim());
            _addSystemMessage("**API key required** for " + Providers.providerLabel(provider) +
                ".\n\nSet the `" + envName + "` environment variable, or configure it in settings." +
                "\n\nAlternatively, use `/provider ollama` for local models.");
            return;
        }

        if (provider === "ollama" && !Config.aiModel && availableModels.length === 0) {
            refreshModels();
            _appendMessage("user", text.trim());
            _addSystemMessage("**No Ollama model available yet**.\n\nStart Ollama if needed, then refresh models or wait a moment for `/api/tags` to load.");
            return;
        }

        // Append user message
        _appendMessage("user", text.trim());

        // Build messages array for the script
        var msgs = [];

        // System prompt
        var systemPrompt = Config.aiSystemPrompt;
        if (!systemPrompt) {
            systemPrompt = "You are a senior Linux desktop assistant for Quickshell on NixOS. " +
                "Your goal is to help the user manage their system, troubleshoot issues, and automate tasks. " +
                "\n\nCapabilities:\n" +
                "1. Suggest system actions: [COMMAND: Label | command args]. Example: [COMMAND: Update System | make update].\n" +
                "2. Propose scripts to ~/.local/bin: [SCRIPT: filename | content]. Ensure scripts have a proper shebang.\n" +
                "3. Rename workspaces: [RENAME_WORKSPACE: id | name].\n" +
                "\n\nGuidelines:\n" +
                "- Be concise and technical. Prefer shell commands over long explanations.\n" +
                "- When suggesting fixes, consider that this is a NixOS system (declarative config in ~/nixos-config).\n" +
                "- Use markdown for formatting. Use code blocks for all code or command output.\n" +
                "- If the user provides visual context or window titles, use them to provide more relevant help.\n" +
                "- You can see system stats like CPU/RAM usage when provided in context.";
        }
        var contextInfo = "";
        if (Config.aiSystemContext) {
            contextInfo = "System: " + (Quickshell.env("HOSTNAME") || "unknown") +
                " | CPU: " + SystemStatus.cpuUsage +
                " | RAM: " + SystemStatus.ramUsage +
                " | CPU temp: " + SystemStatus.cpuTemp;
        }
        
        if (contextWindow) {
            var winInfo = "Active Window: " + contextWindow;
            contextInfo = contextInfo ? contextInfo + "\n" + winInfo : winInfo;
        }

        if (visualContext) {
            var visInfo = "Visual Context (latest cropped region): " + visualContext + 
                "\n(Note: The assistant can reference this image if the multimodal backend supports it, otherwise it sees this path as a hint.)";
            if (root.lastOcrText) {
                visInfo += "\nExtracted Text from Region:\n```\n" + root.lastOcrText + "\n```";
            }
            contextInfo = contextInfo ? contextInfo + "\n" + visInfo : visInfo;
        }

        if (contextInfo) {
            systemPrompt = systemPrompt ? systemPrompt + "\n\n" + contextInfo : contextInfo;
        }
        if (systemPrompt) {
            msgs.push({ role: "system", content: systemPrompt });
        }

        // Conversation messages (skip system messages — those are local command output)
        var convMsgs = activeMessages;
        for (var i = 0; i < convMsgs.length; i++) {
            if (convMsgs[i].role === "system") continue;
            msgs.push({ role: convMsgs[i].role, content: convMsgs[i].content });
        }

        // Write messages to temp file, then start streaming
        var tmpFile = "/tmp/qs-ai-" + activeConversationId + "-" + Date.now() + ".json";
        var apiKey = _resolveApiKey(provider);
        var endpoint = provider === "custom" ? Config.aiCustomEndpoint : Providers.defaultEndpoint(provider);
        var model = activeModel;

        // Stage pending stream command — launched when temp file write completes
        var cmd = ["qs-ai-stream", provider, model, endpoint, apiKey, tmpFile,
                   Config.aiMaxTokens.toString(), Config.aiTemperature.toString()];
        
        // Add visual context (image path) if supported and provided
        if (visualContext && Providers.supportsVision(provider, model)) {
            cmd.push(visualContext);
        }

        _pendingStreamCommand = cmd;
        isStreaming = true;
        _writeTempFile(tmpFile, JSON.stringify(msgs));
    }

    function cancelStream() {
        if (!isStreaming) return;
        streamProc.signal(15); // SIGTERM
        // Commit partial response if any
        if (streamingContent.trim().length > 0) {
            _appendMessage("assistant", streamingContent + "\n\n*(cancelled)*");
            _autoTitle();
        }
        isStreaming = false;
        streamingContent = "";
        _scheduleSave();
    }

    function retryLastMessage() {
        if (isStreaming) return;
        var conv = activeConversation;
        if (!conv || conv.messages.length === 0) return;

        // Find the last user message and remove subsequent messages
        var lastUserMsg = "";
        var newMsgs = conv.messages.slice();

        // Pop until we find a user message
        while (newMsgs.length > 0) {
            var last = newMsgs[newMsgs.length - 1];
            if (last.role === "user") {
                lastUserMsg = last.content;
                newMsgs.pop();
                break;
            } else {
                newMsgs.pop();
            }
        }

        if (!lastUserMsg) return;

        // Update conversation messages
        var newConvs = conversations.slice();
        for (var i = 0; i < newConvs.length; i++) {
            if (newConvs[i].id === activeConversationId) {
                newConvs[i] = _cloneConv(newConvs[i]);
                newConvs[i].messages = newMsgs;
                break;
            }
        }
        conversations = newConvs;

        // Re-send
        sendMessage(lastUserMsg);
    }

    // ── Model Refresh ───────────────────────────
    property Process _modelProc: Process {
        id: modelProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text || "{}");
                    var models = data.models || [];
                    var names = [];
                    for (var i = 0; i < models.length; i++) {
                        if (models[i].name) names.push(models[i].name);
                    }
                    root.availableModels = names;
                } catch (e) {
                    console.error("AiService: failed to parse models: " + e);
                }
            }
        }
    }

    function refreshModels() {
        if (Config.aiProvider === "ollama") {
            var endpoint = Config.aiCustomEndpoint || Providers.defaultEndpoint("ollama");
            modelProc.command = ["curl", "-s", endpoint + "/api/tags"];
            modelProc.running = true;
        } else {
            availableModels = Providers.defaultModels(Config.aiProvider);
        }
    }

    // ── API Key Resolution ──────────────────────
    function _resolveApiKey(provider) {
        // Try environment variable first
        var envKey = Providers.envKeyName(provider);
        if (envKey) {
            var envVal = Quickshell.env(envKey);
            if (envVal) return envVal;
        }
        // Fallback to config
        switch (provider) {
            case "anthropic": return Config.aiAnthropicKey;
            case "openai":    return Config.aiOpenaiKey;
            case "gemini":    return Config.aiGeminiKey;
            default:          return "";
        }
    }

    function apiKeyAvailable(provider) {
        return _resolveApiKey(provider || Config.aiProvider).length > 0;
    }

    // ── Context Helpers ─────────────────────────
    readonly property string contextWindowTitle: CompositorAdapter.activeWindowTitle || ""
    function refreshActiveWindowTitle() {
        // Kept for API compatibility with existing callers.
        return;
    }

    property string lastSelectionText: ""
    property bool isSelectionBusy: false
    
    function fetchSelection() {
        if (isSelectionBusy) return;
        isSelectionBusy = true;
        lastSelectionText = "";
        selectionProc.command = ["wl-paste", "-p"];
        selectionProc.running = true;
    }

    property Process _selectionProc: Process {
        id: selectionProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.lastSelectionText = this.text.trim();
                root.isSelectionBusy = false;
            }
        }
    }

    // ── OCR Helpers ─────────────────────────────
    property string lastOcrText: ""
    property bool isOcrBusy: false
    
    function performOcr(imagePath) {
        if (!imagePath || isOcrBusy) return;
        isOcrBusy = true;
        lastOcrText = "";
        ocrProc.command = ["sh", "-c", "tesseract '" + imagePath + "' stdout -l eng 2>/dev/null"];
        ocrProc.running = true;
    }

    property Process _ocrProc: Process {
        id: ocrProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.lastOcrText = this.text.trim();
                root.isOcrBusy = false;
            }
        }
    }

    // ── Auto-title ──────────────────────────────
    function _autoTitle() {
        var conv = activeConversation;
        if (!conv) return;
        if (conv.title !== "New Chat") return; // Already titled
        if (conv.messages.length < 2) return;

        // Use first user message as title
        for (var i = 0; i < conv.messages.length; i++) {
            if (conv.messages[i].role === "user") {
                var title = conv.messages[i].content.substring(0, 40).trim();
                if (title.length >= 40) title = title.substring(0, 37) + "...";
                renameConversation(conv.id, title);
                return;
            }
        }
    }

    // ── Temp file writing ───────────────────────
    property Process _tempWriteProc: Process {
        id: tempWriteProc
        running: false
        stdinEnabled: true
        onStarted: {
            tempWriteProc.write(root._pendingTempContent);
            tempWriteProc.stdinEnabled = false;
        }
        onExited: (exitCode, exitStatus) => {
            // Launch the stream process now that the temp file is ready
            if (root._pendingStreamCommand.length > 0) {
                streamProc.command = root._pendingStreamCommand;
                root._pendingStreamCommand = [];
                streamProc.running = true;
            }
        }
    }

    property string _pendingTempContent: ""
    property var _pendingStreamCommand: []
    property var _ipcHandler: null

    function _writeTempFile(path, content) {
        _pendingTempContent = content;
        tempWriteProc.command = ["sh", "-c", "cat > '" + path.replace(/'/g, "'\\''") + "'"];
        tempWriteProc.running = true;
    }

    // ── Provider change handler ─────────────────
    onActiveProviderChanged: refreshModels()

    // ── IPC ─────────────────────────────────────
    function _ensureIpcHandler() {
        if (_ipcHandler)
            return _ipcHandler;
        _ipcHandler = ipcHandlerComponent.createObject(root);
        return _ipcHandler;
    }

    Component.onCompleted: {
        refreshModels();
        _ensureIpcHandler();
    }

    Component.onDestruction: {
        if (!_ipcHandler)
            return;
        _ipcHandler.destroy();
        _ipcHandler = null;
    }

    property Component ipcHandlerComponent: Component {
        IpcHandler {
            target: "AiService"
            function sendMessage(text: string) { root.sendMessage(text); }
            function cancelStream() { root.cancelStream(); }
            function newConversation() { root.newConversation(); }
            function refreshModels() { root.refreshModels(); }
        }
    }
}
