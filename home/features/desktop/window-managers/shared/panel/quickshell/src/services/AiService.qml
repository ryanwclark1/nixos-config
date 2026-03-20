pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../features/ai/services/AiProviders.js" as Providers
import "../features/ai/services/AiProviderProfiles.js" as Profiles

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
    property var _closedConversationStack: []
    property string _sessionDraftMigrationText: ""
    property bool _sessionLoading: false
    property bool _sessionLoaded: false

    readonly property var activeConversation: {
        for (var i = 0; i < conversations.length; i++) {
            if (conversations[i].id === activeConversationId)
                return conversations[i];
        }
        return null;
    }

    readonly property var activeMessages: activeConversation ? activeConversation.messages : []
    readonly property string activeDraftText: activeConversation ? (activeConversation.draftText || "") : ""
    readonly property bool hasRestorableClosedConversation: _closedConversationStack.length > 0

    // ── Streaming state ─────────────────────────
    property bool isStreaming: false
    property string streamingContent: ""
    property string lastError: ""

    // ── Token usage (from last response) ──────
    property int lastPromptTokens: 0
    property int lastCompletionTokens: 0
    readonly property int lastTotalTokens: lastPromptTokens + lastCompletionTokens

    // ── Streaming elapsed time ──────────────────
    property real _streamStartTime: 0
    property int streamElapsedSec: 0

    property Timer _streamElapsedTimer: Timer {
        interval: 1000
        repeat: true
        running: root.isStreaming
        onTriggered: {
            if (root._streamStartTime > 0)
                root.streamElapsedSec = Math.floor((Date.now() - root._streamStartTime) / 1000);
        }
    }

    // ── Session-only API keys (not persisted) ───
    property string _sessionAnthropicKey: ""
    property string _sessionOpenaiKey: ""
    property string _sessionGeminiKey: ""
    property string _sessionCustomKey: ""

    function setSessionKey(provider, key) {
        switch (provider) {
            case "anthropic": _sessionAnthropicKey = key; break;
            case "openai":    _sessionOpenaiKey = key; break;
            case "gemini":    _sessionGeminiKey = key; break;
            case "custom":    _sessionCustomKey = key; break;
        }
    }

    function sessionKey(provider) {
        switch (provider) {
            case "anthropic": return _sessionAnthropicKey;
            case "openai":    return _sessionOpenaiKey;
            case "gemini":    return _sessionGeminiKey;
            case "custom":    return _sessionCustomKey;
            default:          return "";
        }
    }

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
        var cmd = ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && cat > \"$1\" && chmod +x \"$1\"", "sh", path];
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
    readonly property string sessionPath: (Quickshell.env("HOME") || "/home") + "/.local/state/quickshell/ai-chat-session.json"

    function saveSession() {
        if (_loading || _sessionLoading || !_sessionLoaded) return;
        var data = {
            activeConversationId: root.activeConversationId
        };
        sessionFile.setText(JSON.stringify(data));
    }

    property FileView sessionFile: FileView {
        path: root.sessionPath
        blockLoading: true
        printErrors: false
        atomicWrites: true
    }

    onActiveConversationIdChanged: {
        saveSession();
    }

    // ── Persistence ─────────────────────────────
    readonly property string savePath: (Quickshell.env("HOME") || "/home") + "/.local/state/quickshell/ai-chat.json"
    readonly property int _saveDebounceMs: 500
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
            Logger.e("AiService", "failed to load:", error);
        }
        onSaveFailed: error => Logger.e("AiService", "failed to save:", error)
    }

    property Timer _saveTimer: Timer {
        interval: root._saveDebounceMs
        onTriggered: root._saveData()
    }

    Component.onCompleted: _loadSession()

    function _scheduleSave() {
        if (!_loading) _saveTimer.restart();
    }

    function _loadSession() {
        _sessionLoading = true;
        try {
            var raw = (sessionFile.text() || "").trim();
            if (raw) {
                var data = JSON.parse(raw);
                activeConversationId = data.activeConversationId || "";
                _sessionDraftMigrationText = data.currentInputText || "";
            }
        } catch (e) {
            Logger.e("AiService", "failed to load session:", e);
        }
        _sessionLoading = false;
        _sessionLoaded = true;
        _applySessionDraftMigration();
    }

    function _copyMessages(messages) {
        var out = [];
        var list = Array.isArray(messages) ? messages : [];
        for (var i = 0; i < list.length; i++) {
            out.push({
                role: list[i].role || "assistant",
                content: list[i].content || "",
                timestamp: list[i].timestamp || Date.now()
            });
        }
        return out;
    }

    function _latestMessageTimestamp(messages, fallback) {
        var latest = fallback || Date.now();
        var list = Array.isArray(messages) ? messages : [];
        for (var i = 0; i < list.length; i++) {
            latest = Math.max(latest, list[i].timestamp || fallback || Date.now());
        }
        return latest;
    }

    function _normalizeConversation(conv) {
        var createdAt = conv && conv.createdAt ? conv.createdAt : Date.now();
        var messages = _copyMessages(conv && conv.messages ? conv.messages : []);
        return {
            id: conv && conv.id ? conv.id : "conv-" + _nextConversationNum++,
            title: conv && conv.title ? conv.title : "New Chat",
            messages: messages,
            provider: conv && conv.provider ? conv.provider : Config.aiProvider,
            model: conv && conv.model ? conv.model : activeModel,
            createdAt: createdAt,
            updatedAt: conv && conv.updatedAt ? conv.updatedAt : _latestMessageTimestamp(messages, createdAt),
            draftText: conv && typeof conv.draftText === "string" ? conv.draftText : ""
        };
    }

    function _makeConversation(seedDraft) {
        var now = Date.now();
        return {
            id: "conv-" + _nextConversationNum++,
            title: "New Chat",
            messages: [],
            provider: Config.aiProvider,
            model: activeModel,
            createdAt: now,
            updatedAt: now,
            draftText: seedDraft || ""
        };
    }

    function _applySessionDraftMigration() {
        if (!_sessionDraftMigrationText)
            return;
        if (!activeConversation)
            return;
        if ((activeConversation.draftText || "").length > 0) {
            _sessionDraftMigrationText = "";
            return;
        }
        setDraftText(activeConversation.id, _sessionDraftMigrationText);
        _sessionDraftMigrationText = "";
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
                var normalized = [];
                // Compute next number
                var maxNum = 0;
                for (var i = 0; i < data.conversations.length; i++) {
                    var conv = _normalizeConversation(data.conversations[i]);
                    normalized.push(conv);
                    var num = parseInt(String(conv.id).replace("conv-", "")) || 0;
                    if (num > maxNum) maxNum = num;
                }
                conversations = normalized;
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
            Logger.e("AiService", "failed to parse JSON:", e);
        }
        _loading = false;
        if (conversations.length === 0) {
            newConversation();
            return;
        }
        _applySessionDraftMigration();
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
    function newConversation(seedDraft) {
        var conv = _makeConversation(seedDraft || "");
        var newConvs = conversations.slice();
        newConvs.push(conv);
        conversations = newConvs;
        activeConversationId = conv.id;
        _scheduleSave();
        return conv.id;
    }

    function _pushClosedConversation(conv) {
        var closed = _cloneConv(conv);
        var stack = _closedConversationStack.slice();
        stack.push(closed);
        while (stack.length > 10)
            stack.shift();
        _closedConversationStack = stack;
    }

    function closeConversation(id) {
        if (!id) return;
        var target = null;
        for (var i = 0; i < conversations.length; i++) {
            if (conversations[i].id === id) {
                target = _cloneConv(conversations[i]);
                break;
            }
        }
        if (!target)
            return false;

        if (isStreaming && activeConversationId === id)
            cancelStream(false);

        _pushClosedConversation(target);

        var newConvs = [];
        for (var j = 0; j < conversations.length; j++) {
            if (conversations[j].id !== id)
                newConvs.push(conversations[j]);
        }

        if (newConvs.length === 0) {
            conversations = [];
            activeConversationId = "";
            newConversation();
            return true;
        }

        if (activeConversationId === id) {
            var nextActive = newConvs[0];
            for (var k = 1; k < newConvs.length; k++) {
                if ((newConvs[k].updatedAt || 0) > (nextActive.updatedAt || 0))
                    nextActive = newConvs[k];
            }
            activeConversationId = nextActive.id;
        }
        conversations = newConvs;
        _scheduleSave();
        return true;
    }

    function deleteConversation(id) {
        return closeConversation(id);
    }

    function restoreLastClosedConversation() {
        if (_closedConversationStack.length === 0)
            return "";
        var stack = _closedConversationStack.slice();
        var restored = _cloneConv(stack.pop());
        restored.updatedAt = Date.now();
        _closedConversationStack = stack;
        var newConvs = conversations.slice();
        newConvs.push(restored);
        conversations = newConvs;
        activeConversationId = restored.id;
        _scheduleSave();
        return restored.id;
    }

    function closeOtherConversations(id) {
        if (!id)
            return 0;
        var shouldCancelStream = isStreaming && activeConversationId !== id;
        var keep = null;
        var closing = [];
        for (var i = 0; i < conversations.length; i++) {
            if (conversations[i].id === id)
                keep = conversations[i];
            else
                closing.push(_cloneConv(conversations[i]));
        }
        if (!keep)
            return 0;
        closing.sort(function(a, b) {
            return (a.updatedAt || 0) - (b.updatedAt || 0);
        });
        for (var j = 0; j < closing.length; j++)
            _pushClosedConversation(closing[j]);
        conversations = [_cloneConv(keep)];
        activeConversationId = keep.id;
        if (shouldCancelStream)
            cancelStream(false);
        _scheduleSave();
        return closing.length;
    }

    function setActiveConversation(id) {
        if (!id || id === activeConversationId)
            return;
        activeConversationId = id;
        _scheduleSave();
    }

    function setDraftText(id, text) {
        if (!id)
            return;
        var nextText = text || "";
        var newConvs = conversations.slice();
        var changed = false;
        for (var i = 0; i < newConvs.length; i++) {
            if (newConvs[i].id === id) {
                if ((newConvs[i].draftText || "") === nextText)
                    return;
                newConvs[i] = _cloneConv(newConvs[i]);
                newConvs[i].draftText = nextText;
                changed = true;
                break;
            }
        }
        if (!changed)
            return;
        conversations = newConvs;
        _scheduleSave();
    }

    function setActiveDraftText(text) {
        if (!activeConversationId)
            return;
        setDraftText(activeConversationId, text || "");
    }

    function renameConversation(id, newTitle) {
        var trimmed = (newTitle || "").trim();
        if (!trimmed) return;
        _updateConv(id, function(c) { c.title = trimmed; });
        _scheduleSave();
    }

    function clearConversation(id) {
        if (!id)
            return;
        if (isStreaming && activeConversationId === id)
            cancelStream(false);
        _updateConv(id, function(c) { c.messages = []; c.draftText = ""; c.updatedAt = Date.now(); });
        _scheduleSave();
    }

    function _updateConv(id, mutator) {
        var newConvs = conversations.slice();
        for (var i = 0; i < newConvs.length; i++) {
            if (newConvs[i].id === id) {
                newConvs[i] = _cloneConv(newConvs[i]);
                mutator(newConvs[i]);
                break;
            }
        }
        conversations = newConvs;
    }

    function _cloneConv(conv) {
        return {
            id: conv.id,
            title: conv.title,
            messages: _copyMessages(conv.messages),
            provider: conv.provider,
            model: conv.model,
            createdAt: conv.createdAt,
            updatedAt: conv.updatedAt || conv.createdAt,
            draftText: conv.draftText || ""
        };
    }

    function duplicateConversationPrompt(id) {
        if (!id)
            return "";
        var source = null;
        for (var i = 0; i < conversations.length; i++) {
            if (conversations[i].id === id) {
                source = conversations[i];
                break;
            }
        }
        if (!source)
            return "";
        var seed = (source.draftText || "").trim();
        if (seed.length === 0) {
            for (var j = source.messages.length - 1; j >= 0; j--) {
                if (source.messages[j].role === "user") {
                    seed = source.messages[j].content || "";
                    break;
                }
            }
        }
        return newConversation(seed);
    }

    function _appendMessage(role, content) {
        _updateConv(activeConversationId, function(c) {
            while (c.messages.length >= Config.aiMaxMessages * 2)
                c.messages.shift();
            c.messages.push({ role: role, content: content, timestamp: Date.now() });
            c.updatedAt = Date.now();
        });
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
                root._streamStartTime = 0;
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

    function _syncActiveConversationRuntime() {
        if (!activeConversationId)
            return;
        _updateConv(activeConversationId, function(c) {
            c.provider = Config.aiProvider;
            c.model = activeModel;
        });
    }

    function _buildSystemPrompt(contextWindow, visualContext) {
        var prompt = Config.aiSystemPrompt;
        if (!prompt) {
            prompt = "You are a senior Linux desktop assistant for Quickshell on NixOS. " +
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
            if (root.lastOcrText)
                visInfo += "\nExtracted Text from Region:\n```\n" + root.lastOcrText + "\n```";
            contextInfo = contextInfo ? contextInfo + "\n" + visInfo : visInfo;
        }
        if (contextInfo)
            prompt = prompt ? prompt + "\n\n" + contextInfo : contextInfo;
        return prompt || "";
    }

    function _fuzzyMatch(items, query, accessor, allowContains) {
        var q = query.toLowerCase();
        var i;
        for (i = 0; i < items.length; i++) {
            if (String(accessor(items[i]) || "").toLowerCase() === q)
                return items[i];
        }
        for (i = 0; i < items.length; i++) {
            if (String(accessor(items[i]) || "").toLowerCase().indexOf(q) === 0)
                return items[i];
        }
        if (allowContains) {
            for (i = 0; i < items.length; i++) {
                if (String(accessor(items[i]) || "").toLowerCase().indexOf(q) !== -1)
                    return items[i];
            }
        }
        return null;
    }

    function _fuzzyMatchModel(query) {
        return _fuzzyMatch(availableModels, query, function(model) {
            return model;
        }, true);
    }

    function _fuzzyMatchProvider(query) {
        var all = Providers.allProviders();
        var providerKey = _fuzzyMatch(all, query, function(provider) {
            return provider;
        }, false);
        if (providerKey)
            return providerKey;
        return _fuzzyMatch(all, query, function(provider) {
            return Providers.providerLabel(provider);
        }, false);
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
        _streamStartTime = Date.now();
        streamElapsedSec = 0;

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

        _syncActiveConversationRuntime();

        // Append user message
        _appendMessage("user", text.trim());
        setActiveDraftText("");
        _autoTitle();

        // Build messages array for the script
        var msgs = [];

        var systemPrompt = _buildSystemPrompt(contextWindow, visualContext);
        if (systemPrompt)
            msgs.push({ role: "system", content: systemPrompt });

        // Conversation messages (skip system messages — those are local command output)
        var convMsgs = activeMessages;
        for (var i = 0; i < convMsgs.length; i++) {
            if (convMsgs[i].role === "system") continue;
            msgs.push({ role: convMsgs[i].role, content: convMsgs[i].content });
        }

        // Write messages to temp file, then start streaming
        var tmpFile = "/tmp/qs-ai-" + activeConversationId + "-" + Date.now() + ".json";
        var apiKey = _resolveApiKey(provider);
        var profile = Profiles.loadProfile(Config.aiProviderProfiles, provider);
        var endpoint = profile.endpoint || (provider === "custom" ? Config.aiCustomEndpoint : Providers.defaultEndpoint(provider));
        var model = activeModel;

        // Stage pending stream command — launched when temp file write completes
        var cmd = ["qs-ai-stream", provider, model, endpoint, apiKey, tmpFile,
                   Config.aiMaxTokens.toString(), Config.aiTemperature.toString()];
        
        // Add visual context (image path) if supported and provided
        if (visualContext && Providers.supportsVision(provider, model)) {
            cmd.push(visualContext);
        } else {
            cmd.push(""); // placeholder for image path
        }
        cmd.push(Config.aiTimeout.toString());

        _pendingStreamCommand = cmd;
        isStreaming = true;
        _writeTempFile(tmpFile, JSON.stringify(msgs));
    }

    function cancelStream(commitPartial) {
        if (!isStreaming) return;
        var shouldCommitPartial = commitPartial === undefined ? true : !!commitPartial;
        streamProc.signal(15); // SIGTERM
        // Commit partial response if any
        if (shouldCommitPartial && streamingContent.trim().length > 0) {
            _appendMessage("assistant", streamingContent + "\n\n*(cancelled)*");
            _autoTitle();
        }
        isStreaming = false;
        streamingContent = "";
        _streamStartTime = 0;
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

        _updateConv(activeConversationId, function(c) { c.messages = newMsgs; });

        // Re-send
        sendMessage(lastUserMsg);
    }

    function regenerateFromMessage(msgIndex) {
        if (isStreaming) return;
        var conv = activeConversation;
        if (!conv || conv.messages.length === 0) return;
        if (msgIndex < 0 || msgIndex >= conv.messages.length) return;

        // Walk back from msgIndex to find the preceding user message
        var userMsgIdx = -1;
        for (var i = msgIndex; i >= 0; i--) {
            if (conv.messages[i].role === "user") {
                userMsgIdx = i;
                break;
            }
        }
        if (userMsgIdx === -1) return;

        var userText = conv.messages[userMsgIdx].content;
        // Truncate to just before the user message
        var truncated = conv.messages.slice(0, userMsgIdx);
        _updateConv(activeConversationId, function(c) { c.messages = truncated; });

        sendMessage(userText);
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
                    Logger.e("AiService", "failed to parse models:", e);
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
        // Priority: env var → session key → config key
        var envKey = Providers.envKeyName(provider);
        if (envKey) {
            var envVal = Quickshell.env(envKey);
            if (envVal) return envVal;
        }
        var sessKey = sessionKey(provider);
        if (sessKey) return sessKey;
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
        ocrProc.command = ["sh", "-c", "tesseract \"$1\" stdout -l eng 2>/dev/null", "sh", imagePath];
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
        tempWriteProc.command = ["sh", "-c", "cat > \"$1\"", "sh", path];
        tempWriteProc.running = true;
    }

    // ── Provider change handler ─────────────────
    property string _previousProvider: ""

    onActiveProviderChanged: {
        // On first binding (_previousProvider is ""), just record the provider — don't
        // overwrite user settings with defaults when no profiles have been saved yet.
        if (!_previousProvider) {
            _previousProvider = activeProvider;
            refreshModels();
            return;
        }
        if (_previousProvider === activeProvider) {
            refreshModels();
            return;
        }
        // Save outgoing provider's settings to its profile
        Config.aiProviderProfiles = Profiles.saveProfile(
            Config.aiProviderProfiles, _previousProvider, {
                model: Config.aiModel,
                temperature: Config.aiTemperature,
                maxTokens: Config.aiMaxTokens,
                endpoint: Config.aiCustomEndpoint
            });
        // Load incoming provider's profile
        var profile = Profiles.loadProfile(Config.aiProviderProfiles, activeProvider);
        Config.aiModel = profile.model;
        Config.aiTemperature = profile.temperature;
        Config.aiMaxTokens = profile.maxTokens;
        if (profile.endpoint)
            Config.aiCustomEndpoint = profile.endpoint;
        _previousProvider = activeProvider;
        refreshModels();
    }

    // ── IPC ─────────────────────────────────────
    function _ensureIpcHandler() {
        if (_ipcHandler)
            return _ipcHandler;
        _ipcHandler = ipcHandlerComponent.createObject(root);
        return _ipcHandler;
    }

    Component.onCompleted: {
        // _previousProvider and refreshModels() are handled by onActiveProviderChanged
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
