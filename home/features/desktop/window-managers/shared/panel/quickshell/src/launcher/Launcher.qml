import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import "../services"
import "../services/ShellUtils.js" as SU
import "../widgets" as SharedWidgets
import "LauncherModeData.js" as ModeData
import "LauncherSearch.js" as Search
import "LauncherDiagnostics.js" as Diag
import "LauncherFileParser.js" as FileParser
import "LauncherExecutor.js" as Executor
import "LauncherMetrics.js" as Metrics
import "LauncherSystemItems.js" as SystemItems
import "LauncherHomeBuilder.js" as HomeBuilder
import "LauncherCategoryHelpers.js" as CategoryHelpers
import "EmojiData.js" as EmojiData

PanelWindow {
    id: launcherRoot

    Component.onCompleted: {
        initialAppsPreloadTimer.restart();
    }

    property var screenRef: screen || Quickshell.cursorScreen || Config.primaryScreen()
    screen: screenRef
    readonly property var edgeMargins: Config.reservedEdgesForScreen(screenRef, "")
    property real diagnosticViewportWidth: 0
    property real diagnosticViewportHeight: 0
    readonly property real actualViewportWidth: Math.max(width, screenRef ? screenRef.width : 0)
    readonly property real actualViewportHeight: Math.max(height, screenRef ? screenRef.height : 0)
    readonly property real viewportWidth: diagnosticViewportWidth > 0 ? diagnosticViewportWidth : actualViewportWidth
    readonly property real viewportHeight: diagnosticViewportHeight > 0 ? diagnosticViewportHeight : actualViewportHeight
    readonly property real usableWidth: Math.max(0, viewportWidth - edgeMargins.left - edgeMargins.right)
    readonly property real usableHeight: Math.max(0, viewportHeight - edgeMargins.top - edgeMargins.bottom)
    readonly property real actualUsableWidth: Math.max(0, actualViewportWidth - edgeMargins.left - edgeMargins.right)
    readonly property real actualUsableHeight: Math.max(0, actualViewportHeight - edgeMargins.top - edgeMargins.bottom)
    readonly property real diagnosticViewportOffsetX: diagnosticViewportWidth > 0 ? Math.max(0, (actualUsableWidth - usableWidth) / 2) : 0
    readonly property real diagnosticViewportOffsetY: diagnosticViewportHeight > 0 ? Math.max(0, (actualUsableHeight - usableHeight) / 2) : 0
    readonly property bool compactMode: usableWidth < 900 || usableHeight < 640
    readonly property bool sidebarCompact: usableWidth < 720
    readonly property bool tightMode: usableWidth < 560 || usableHeight < 500
    readonly property bool webHintCompact: usableWidth < 760 || usableHeight < 560

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    color: "transparent"
    property real launcherOpacity: 0
    visible: launcherOpacity > 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: launcherOpacity > 0 ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell"

    onVisibleChanged: {
        if (visible)
            Qt.callLater(function () {
                if (searchInputComp.searchInput)
                    searchInputComp.searchInput.forceActiveFocus();
            });
    }

    // Safety-net Escape: works even if focus falls to an unexpected item
    // (Shortcut doesn't depend on the QML focus chain)
    Shortcut {
        enabled: launcherRoot.launcherOpacity > 0
        sequence: "Escape"
        onActivated: launcherRoot.handleEscapeAction()
    }

    property string searchText: ""
    property var allItems: []
    property var filteredItems: []
    property int selectedIndex: 0
    property string mode: "drun"

    property string confirmTitle: ""
    property var confirmCallback: null
    readonly property bool showingConfirm: confirmTitle !== ""

    property var recentItems: []
    property var suggestionItems: []
    property string drunCategoryFilter: ""
    property bool drunCategorySectionExpanded: false
    property var drunCategoryOptions: [
        {
            key: "",
            label: "All",
            count: 0,
            hotkey: "0"
        }
    ]
    property string _sessionWebProviderKey: ""
    property var appFrequency: ({})
    property var launchHistory: []
    property var onCommandOutput: null
    property var onCommandError: null
    property string commandStdoutBuffer: ""
    property string commandStderrBuffer: ""
    property var pendingCommand: null
    property var pendingCommandOutput: null
    property var pendingCommandError: null
    property bool suppressNextCommandExit: false
    property string modeLoadState: "idle"
    property string modeLoadMessage: ""
    property string modeLoadTarget: ""
    property var modeCache: ({})
    property var modeCacheTime: ({})
    property string _lastFilterMode: ""
    property string _lastFilterQuery: ""
    property string _lastFilterCategory: ""
    property var _lastFilterCandidates: []
    property int _filterChunkToken: 0
    property var _filterChunkState: null
    property bool _filterChunking: false
    property int _parseChunkToken: 0
    property var _parseChunkState: null
    property var fileQueryCache: ({})
    property var fileQueryCacheTime: ({})
    property string fileSearchBackend: ""
    property int fileSearchBackendResolvedAt: 0
    property var fileIndexItems: []
    property bool fileIndexReady: false
    property bool fileIndexBuilding: false
    property var fileIndexBuiltAt: 0
    property string transientNoticeText: ""
    readonly property int fileSearchBackendRefreshMs: 180000
    readonly property int fileSearchBackendMissRefreshMs: 20000
    property int openCount: 0
    property int _requestToken: 0
    property var _activeRequests: ({})
    property var mediaPlayers: []
    property var preloadFailureState: ({})
    property var launcherIconMap: ({})
    readonly property var availableToplevels: CompositorAdapter.toplevels || []
    property var launcherMetrics: ({
            opens: 0,
            cacheHits: 0,
            cacheMisses: 0,
            commandFailures: 0,
            filterRuns: 0,
            lastFilterMs: 0,
            avgFilterMs: 0,
            filesFdLoads: 0,
            filesFindLoads: 0,
            filesFdLastMs: 0,
            filesFindLastMs: 0,
            filesFdAvgMs: 0,
            filesFindAvgMs: 0,
            filesResolveRuns: 0,
            filesResolveLastMs: 0,
            filesResolveAvgMs: 0,
            perMode: ({})
        })
    function refreshMediaPlayers() {
        mediaPlayers = MediaService.getAvailablePlayers();
    }

    function setModeLoadState(nextState, targetMode, message) {
        modeLoadState = String(nextState || "idle");
        modeLoadTarget = String(targetMode || mode || "");
        modeLoadMessage = String(message || "");
    }

    function beginModeLoad(targetMode, message) {
        setModeLoadState("loading", targetMode, message);
    }

    function completeModeLoad(targetMode, success, message) {
        var target = String(targetMode || "");
        if (target !== "" && target !== mode)
            return;
        setModeLoadState(success ? "ready" : "error", targetMode, message);
    }

    function resetFilterCache() {
        _lastFilterMode = "";
        _lastFilterQuery = "";
        _lastFilterCategory = "";
        _lastFilterCandidates = [];
    }

    function updateDrunUsageCache(item) {
        if (!item)
            return;
        var execKey = String(item.exec || "");
        var rawFreq = (appFrequency[execKey] || 0) * 0.3;
        var usageScore = UsageTrackerService.getUsageScore(execKey);
        item._rawFrequencyScore = rawFreq;
        item._usageScore = usageScore;
        item._drunUsageBoost = Math.max(rawFreq, usageScore * 1.5);
    }

    function refreshDrunUsageCaches(items) {
        var source = Array.isArray(items) ? items : [];
        for (var i = 0; i < source.length; ++i)
            updateDrunUsageCache(source[i]);
    }

    function prepareDrunItems(items) {
        var source = Array.isArray(items) ? items : [];
        for (var i = 0; i < source.length; ++i) {
            var item = source[i];
            Search.ensureItemRankCache(item);
            updateDrunUsageCache(item);
        }
        return source;
    }

    // ── Hover anti-flicker ─────────────────────────
    property bool ignoreMouseHover: true
    property bool mouseTrackingReady: false
    property bool globalMouseInitialized: false
    property real globalLastMouseX: 0
    property real globalLastMouseY: 0

    readonly property bool showLauncherHome: Config.launcherShowHomeSections && searchText === "" && (mode === "system" || mode === "files")
    readonly property bool showLauncherHomePanel: showLauncherHome && mode !== "orchestrator"
    readonly property bool drunCategoryFiltersEnabled: Config.launcherDrunCategoryFiltersEnabled
    readonly property bool isModeLoading: modeLoadState === "loading"
    readonly property string selectedHomeItemKey: ""
    readonly property string drunCategoryFilterLabel: {
        for (var i = 0; i < drunCategoryOptions.length; ++i) {
            var option = drunCategoryOptions[i];
            if (String(option.key || "") === drunCategoryFilter)
                return String(option.label || "All");
        }
        return "All";
    }
    readonly property string drunCategoryFilterSummary: {
        var options = Array.isArray(drunCategoryOptions) ? drunCategoryOptions : [];
        var totalCount = options.length > 0 ? Math.max(0, Math.round(Number((options[0] || {}).count || 0))) : 0;
        var activeCount = totalCount;
        for (var i = 0; i < options.length; ++i) {
            var option = options[i] || ({});
            if (String(option.key || "") === drunCategoryFilter) {
                activeCount = Math.max(0, Math.round(Number(option.count || 0)));
                break;
            }
        }
        if (drunCategoryFilter === "")
            return activeCount + " apps ready";
        return activeCount + " of " + totalCount + " apps";
    }
    readonly property var allKnownModes: ModeData.allKnownModes
    readonly property var transientModes: ModeData.transientModes
    readonly property var defaultModeOrder: ModeData.defaultModeOrder
    readonly property var defaultPrimaryModes: ModeData.defaultPrimaryModes
    property var modeOrder: computeModeOrder()
    property var primaryModes: ModeData.sanitizeModeList(Config.launcherEnabledModes, defaultPrimaryModes, allKnownModes).filter(function (modeKey) {
        return launcherRoot.isModeAllowedByCompositor(modeKey);
    })
    readonly property var modeIcons: ModeData.modeIcons
    readonly property string emptyStateTitle: {
        var clean = ModeData.stripModePrefix(searchText).trim();
        if (mode === "files") {
            if (clean.length < Config.launcherFileMinQueryLength)
                return "Start typing to search Home";
            return "No files match '" + clean + "'";
        }
        if (mode === "ai")
            return "Describe what you want and press Enter";
        if (mode === "clip")
            return "Clipboard history is empty";
        if (mode === "window")
            return "No open windows found";
        return "No results";
    }
    readonly property string emptyStateSubtitle: {
        var clean = ModeData.stripModePrefix(searchText).trim();
        if (mode === "files") {
            if (clean.length < Config.launcherFileMinQueryLength)
                return "Filename-first search across your home directory. Prefix with / to jump here from any mode.";
            return "Try a shorter filename fragment or browse Home directly.";
        }
        if (mode === "ai")
            return "The response will be copied to your clipboard";
        if (mode === "clip")
            return "Copy something to populate clipboard history";
        if (mode === "window")
            return "Open some applications to see them here";
        return "Try another query or switch modes";
    }
    readonly property string emptyPrimaryCta: {
        var clean = ModeData.stripModePrefix(searchText).trim();
        var webPrimary = primaryWebProvider();
        var webPrimaryName = webPrimary ? webPrimary.name : "Web";
        if (mode === "files")
            return "Open Home";
        if (mode === "web")
            return clean !== "" ? "Search " + webPrimaryName : "Open " + webPrimaryName;
        if (mode === "ai")
            return clean.length >= 3 ? "Ask AI" : "Switch to Apps";
        if (mode === "run")
            return clean !== "" ? "Run Command" : "Switch to Apps";
        if (mode === "window")
            return "Open Apps";
        if (mode === "bookmarks")
            return "Switch to Web";
        if (mode === "clip")
            return "Switch to Apps";
        return "Switch to Apps";
    }
    readonly property string emptySecondaryCta: {
        var clean = ModeData.stripModePrefix(searchText).trim();
        var webSecondary = secondaryWebProvider();
        var webSecondaryName = webSecondary ? webSecondary.name : "Google";
        if (mode === "files")
            return FileParser.fileQueryLooksLikePath(clean) ? "Open Folder" : (searchText !== "" ? "Clear Query" : "");
        if (mode === "web")
            return clean !== "" ? "Search " + webSecondaryName : "Open " + webSecondaryName;
        if (mode === "system")
            return "Open Controls";
        if (mode === "run")
            return clean !== "" ? "Run In Terminal" : "Open Terminal";
        return searchText !== "" ? "Clear Query" : "";
    }
    readonly property string emptyPrimaryHint: {
        var clean = ModeData.stripModePrefix(searchText).trim();
        var webPrimary = primaryWebProvider();
        var webPrimaryName = webPrimary ? webPrimary.name : "default provider";
        if (mode === "files")
            return "Open your home directory in the default file manager.";
        if (mode === "web")
            return clean !== "" ? "Search " + webPrimaryName + " using the current query." : "Open " + webPrimaryName + " homepage.";
        if (mode === "ai")
            return clean.length >= 3 ? "Send prompt to AI helper and show copyable result." : "Switch back to app launcher mode.";
        if (mode === "run")
            return clean !== "" ? "Execute command directly in shell." : "Switch back to app launcher mode.";
        if (mode === "system")
            return "Switch back to app launcher mode.";
        if (mode === "bookmarks")
            return "Switch to web mode for broader search.";
        return "Switch to app launcher mode.";
    }
    readonly property string emptyPrimaryHintIcon: {
        if (mode === "files")
            return "󰉋";
        if (mode === "web")
            return "󰖟";
        if (mode === "ai")
            return "󰚩";
        if (mode === "run")
            return "󰆍";
        if (mode === "bookmarks")
            return "󰃀";
        return "󰀻";
    }
    readonly property string emptySecondaryHint: {
        var clean = ModeData.stripModePrefix(searchText).trim();
        var webSecondary = secondaryWebProvider();
        var webSecondaryName = webSecondary ? webSecondary.name : "Google";
        if (mode === "files")
            return FileParser.fileQueryLooksLikePath(clean) ? "Open the folder implied by the current path-like query." : (searchText !== "" ? "Clear the current query text." : "");
        if (mode === "web")
            return clean !== "" ? "Search " + webSecondaryName + " using the current query." : "Open " + webSecondaryName + " homepage.";
        if (mode === "system")
            return "Open quickshell control center panel.";
        if (mode === "run")
            return clean !== "" ? "Run command inside terminal for interactive output." : "Open terminal app.";
        if (searchText !== "")
            return "Clear the current query text.";
        return "";
    }
    readonly property string emptySecondaryHintIcon: {
        if (mode === "files")
            return "󰉋";
        if (mode === "web")
            return "󰇥";
        if (mode === "system")
            return "󰒓";
        if (mode === "run")
            return "󰆍";
        if (searchText !== "")
            return "󰅖";
        return "";
    }
    readonly property bool hasResults: filteredItems.length > 0
    readonly property var selectedItem: hasResults && selectedIndex >= 0 && selectedIndex < filteredItems.length ? filteredItems[selectedIndex] : null
    readonly property string launcherTabBehavior: {
        var value = String(Config.launcherTabBehavior || "contextual");
        return ["contextual", "results", "mode"].indexOf(value) !== -1 ? value : "contextual";
    }
    readonly property string tabControlHintText: {
        if (launcherTabBehavior === "mode")
            return "Tab: next mode • Shift+Tab: next mode";
        if (launcherTabBehavior === "results")
            return "Tab: next result • Shift+Tab: next mode";
        return hasResults ? "Tab: next result • Shift+Tab: next mode" : "Tab: next mode • Shift+Tab: next mode";
    }
    readonly property string launcherControlHintText: {
        var resultHint = hasResults ? "↑/↓/Ctrl+P/N/PgUp/PgDn/Home/End: results • " : "";
        var clearHint = searchText !== "" ? "Ctrl+L/U: clear • " : "";
        var escapeHint = (searchText !== "" || (drunCategoryFiltersEnabled && mode === "drun" && (drunCategoryFilter !== "" || drunCategorySectionExpanded))) ? "Esc: reset/close" : "Esc: close";
        if (drunCategoryFiltersEnabled && mode === "drun" && drunCategoryOptions.length > 1)
            return "Alt+←/→/PgUp/PgDn/Home/End/0/Backspace, Ctrl+Tab, or Alt+1..9: categories • " + resultHint + clearHint + "Enter: run • " + escapeHint;
        return resultHint + clearHint + "Enter: run • " + escapeHint;
    }
    readonly property string legendPrimaryAction: {
        if (showingConfirm)
            return "Enter: Confirm";
        if (!hasResults)
            return "Enter: " + emptyPrimaryCta;
        if (mode === "web" && Config.launcherWebEnterUsesPrimary) {
            var primary = primaryWebProvider();
            var label = primary ? primary.name : "Web";
            return "Enter: Search " + label;
        }
        var action = Executor.itemActionLabel(mode, selectedItem);
        if (action === "")
            action = "Open";
        return "Enter: " + action;
    }
    readonly property string legendSecondaryAction: {
        if (showingConfirm)
            return "Esc: Cancel";
        if (!hasResults && emptySecondaryCta !== "")
            return "Shift+Enter: " + emptySecondaryCta;
        if (launcherTabBehavior === "mode")
            return "Tab: Next Mode";
        if (launcherTabBehavior === "results")
            return "Tab: Next Result";
        return hasResults ? "Tab: Next Result" : "Tab: Next Mode";
    }
    readonly property string legendTertiaryAction: {
        if (showingConfirm)
            return "Esc: Cancel";
        if (searchText !== "" || (drunCategoryFiltersEnabled && mode === "drun" && (drunCategoryFilter !== "" || drunCategorySectionExpanded)))
            return "Esc: Reset";
        return "Shift+Tab: Next Mode";
    }
    readonly property string webPrimaryProviderLabel: {
        var provider = primaryWebProvider();
        return provider ? provider.name : "Primary";
    }
    readonly property string webHotkeyHint: {
        if (!Config.launcherWebNumberHotkeysEnabled)
            return "Ctrl+Enter: Home";
        return webHintCompact ? "Ctrl+Enter: Home • Ctrl/Alt+1..9" : "Ctrl+Enter: Home • Ctrl+1..9: Open • Alt+1..9: Select";
    }
    readonly property string filesBackendLabel: {
        if (fileSearchBackend === "fd")
            return "fd";
        if (fileSearchBackend === "find")
            return "find";
        if (fileSearchBackend === "none")
            return "none";
        return "auto";
    }
    readonly property string filesCacheStatsLabel: {
        var stats = modeMetric("files");
        var hits = Math.max(0, Math.round(stats.cacheHits || 0));
        var misses = Math.max(0, Math.round(stats.cacheMisses || 0));
        var total = hits + misses;
        var pct = total > 0 ? Math.round((hits * 100) / total) : 0;
        return hits + "/" + misses + " (" + pct + "%)";
    }
    readonly property string webSelectedProviderLabel: activeProviderLabel !== "" ? activeProviderLabel : "Selected"
    readonly property string webPrimaryEnterHint: Config.launcherWebEnterUsesPrimary ? ("Enter: " + webPrimaryProviderLabel) : ("Enter: " + webSelectedProviderLabel)
    readonly property string webSecondaryEnterHint: Config.launcherWebEnterUsesPrimary ? ("Shift+Enter: " + webSelectedProviderLabel) : ("Shift+Enter: " + emptySecondaryCta)
    readonly property string webAliasHint: {
        var aliases = (Config.launcherWebAliases && typeof Config.launcherWebAliases === "object") ? Config.launcherWebAliases : ({});
        var providers = configuredWebProviders();
        var parts = [];
        for (var i = 0; i < providers.length; ++i) {
            var providerKey = String(providers[i].key || "");
            if (providerKey === "")
                continue;
            var list = aliases[providerKey];
            if (!Array.isArray(list) || list.length === 0)
                continue;
            var first = String(list[0] || "").trim();
            if (first !== "")
                parts.push("?" + first);
        }
        if (parts.length > 0)
            return (webHintCompact ? "Aliases: " : "Alias: ") + parts.join(" ");
        return webHintCompact ? "Aliases: provider key" : "Alias: provider key";
    }
    readonly property string activeProviderLabel: {
        if (mode !== "web")
            return "";
        if (selectedItem)
            return Executor.itemProviderLabel(mode, selectedItem);
        return "";
    }
    readonly property string selectedWebProviderKey: {
        if (mode !== "web" || !selectedItem)
            return "";
        return String(selectedItem.key || "");
    }

    readonly property string freqPath: Quickshell.env("HOME") + "/.local/state/quickshell/app_frequency.json"
    readonly property string historyPath: Quickshell.env("HOME") + "/.local/state/quickshell/launcher_history.json"

    Behavior on launcherOpacity {
        NumberAnimation {
            duration: Colors.durationSlow
            easing.type: Easing.OutQuint
        }
    }

    property real scaleValue: 1.0
    Behavior on scaleValue {
        SpringAnimation {
            spring: 4.5
            damping: 0.28
            epsilon: 0.005
        }
    }

    property real yOffset: 0
    Behavior on yOffset {
        SpringAnimation {
            spring: 4.0
            damping: 0.3
            epsilon: 0.005
        }
    }
    property bool seedFrequencyFile: false
    property bool seedHistoryFile: false

    property FileView freqFile: FileView {
        path: launcherRoot.freqPath
        blockLoading: true
        printErrors: false
        onLoaded: {
            try {
                launcherRoot.appFrequency = JSON.parse(freqFile.text());
            } catch (e) {}
        }
        onLoadFailed: error => {
            if (error === 2) {
                launcherRoot.seedFrequencyFile = true;
                seedFrequencyTimer.restart();
            }
        }
    }

    property FileView historyFile: FileView {
        path: launcherRoot.historyPath
        blockLoading: true
        printErrors: false
        onLoaded: {
            try {
                launcherRoot.launchHistory = JSON.parse(historyFile.text());
            } catch (e) {
                launcherRoot.launchHistory = [];
            }
        }
        onLoadFailed: error => {
            if (error === 2) {
                launcherRoot.seedHistoryFile = true;
                seedHistoryTimer.restart();
            }
        }
    }

    Timer {
        id: seedFrequencyTimer
        interval: 0
        repeat: false
        onTriggered: {
            if (!launcherRoot.seedFrequencyFile)
                return;
            launcherRoot.seedFrequencyFile = false;
            freqFile.setText("{}");
        }
    }

    Timer {
        id: seedHistoryTimer
        interval: 0
        repeat: false
        onTriggered: {
            if (!launcherRoot.seedHistoryFile)
                return;
            launcherRoot.seedHistoryFile = false;
            historyFile.setText("[]");
        }
    }

    property Process commandProc: Process {
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                launcherRoot.commandStdoutBuffer = this.text || "";
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                launcherRoot.commandStderrBuffer = this.text || "";
            }
        }
        onExited: (exitCode, exitStatus) => {
            commandTimeoutTimer.stop();
            var outputCb = launcherRoot.onCommandOutput;
            var errorCb = launcherRoot.onCommandError;
            var stdoutText = launcherRoot.commandStdoutBuffer || "";
            var stderrText = launcherRoot.commandStderrBuffer || "";
            var suppressExit = launcherRoot.suppressNextCommandExit;
            launcherRoot.onCommandOutput = null;
            launcherRoot.onCommandError = null;
            launcherRoot.commandStdoutBuffer = "";
            launcherRoot.commandStderrBuffer = "";
            launcherRoot.suppressNextCommandExit = false;

            var nextCommand = launcherRoot.pendingCommand;
            var nextOutput = launcherRoot.pendingCommandOutput;
            var nextError = launcherRoot.pendingCommandError;
            launcherRoot.pendingCommand = null;
            launcherRoot.pendingCommandOutput = null;
            launcherRoot.pendingCommandError = null;

            if (suppressExit) {
                if (nextCommand)
                    launcherRoot.startCommand(nextCommand, nextOutput, nextError);
                return;
            }

            if (nextCommand)
                launcherRoot.startCommand(nextCommand, nextOutput, nextError);

            if (exitCode === 0) {
                if (outputCb)
                    outputCb(stdoutText);
                return;
            }
            if (errorCb) {
                errorCb(stderrText !== "" ? stderrText : stdoutText, exitCode, exitStatus);
            } else {
                console.warn("Launcher command failed:", exitCode, stderrText !== "" ? stderrText : stdoutText);
            }
        }
    }

    property Process iconResolverProc: Process {
        running: true
        command: ["qs-icon-resolver"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    launcherRoot.launcherIconMap = JSON.parse(this.text || "{}");
                } catch (e) {
                    console.warn("Launcher: icon map parse error:", e);
                }
            }
        }
    }

    property Process fileIndexProc: Process {
        property var _startedAt: 0
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                launcherRoot._handleFileIndexBuilt(this.text || "", fileIndexProc._startedAt || Date.now());
            }
        }
        stderr: StdioCollector {}
        onExited: exitCode => {
            fileIndexTimeoutTimer.stop();
            if (exitCode !== 0 && launcherRoot.fileIndexBuilding) {
                launcherRoot.fileIndexBuilding = false;
                launcherRoot.fileIndexReady = false;
                launcherRoot.completeModeLoad("files", false, "Files index build failed");
            }
        }
    }

    // ── Parallel background preloading ─────────────
    property var _preloadProcs: ({})

    Timer {
        id: preloadDelayTimer
        interval: 100
        onTriggered: launcherRoot.startPreload()
    }

    Timer {
        id: initialAppsPreloadTimer
        interval: 150
        repeat: false
        onTriggered: launcherRoot.prewarmAppsCache()
    }

    Timer {
        id: searchDebounceTimer
        interval: Math.max(0, Config.launcherSearchDebounceMs)
        repeat: false
        onTriggered: launcherRoot.applySearchRefresh(false)
    }

    Timer {
        id: fileSearchDebounceTimer
        interval: Math.max(50, Config.launcherFileSearchDebounceMs)
        repeat: false
        onTriggered: launcherRoot.applySearchRefresh(true)
    }

    // Kill commandProc if it runs longer than 10 seconds
    Timer {
        id: commandTimeoutTimer
        interval: 10000
        repeat: false
        onTriggered: {
            if (!commandProc.running)
                return;
            console.warn("Launcher: command timed out after 10s");
            launcherRoot.suppressNextCommandExit = true;
            commandProc.running = false;
            if (!launcherRoot.pendingCommand && launcherRoot.modeLoadState === "loading")
                launcherRoot.completeModeLoad(launcherRoot.mode, false, "Command timed out");
        }
    }

    // Kill fileIndexProc if it runs longer than 30 seconds
    Timer {
        id: fileIndexTimeoutTimer
        interval: 30000
        repeat: false
        onTriggered: {
            if (!fileIndexProc.running)
                return;
            console.warn("Launcher: file index build timed out after 30s");
            fileIndexProc.running = false;
            launcherRoot.fileIndexBuilding = false;
            if (launcherRoot.modeLoadState === "loading" && launcherRoot.mode === "files")
                launcherRoot.completeModeLoad("files", false, "File index timed out");
        }
    }

    Timer {
        id: filterChunkTimer
        interval: 0
        repeat: false
        onTriggered: launcherRoot._processFilterChunk()
    }

    Timer {
        id: parseChunkTimer
        interval: 0
        repeat: false
        onTriggered: launcherRoot._processParseChunk()
    }

    Component {
        id: preloadProcComponent
        Process {
            id: _preloadProc
            property string _modeKey: ""
            property var _startedAt: 0
            running: false
            stdout: StdioCollector {
                onStreamFinished: {
                    launcherRoot._handlePreloadDone(_preloadProc, this.text || "");
                }
            }
        }
    }

    LauncherDependencyChecker {
        id: depChecker
    }

    Timer {
        id: preloadWaitTimer
        interval: 50
        repeat: true
        property string waitingFor: ""
        onTriggered: {
            var cached = launcherRoot.getCached(waitingFor);
            if (cached) {
                running = false;
                if (launcherRoot.mode === waitingFor) {
                    launcherRoot.allItems = cached;
                    launcherRoot.filterItems();
                    launcherRoot.buildLauncherHome();
                    launcherRoot.completeModeLoad(waitingFor, true, "");
                }
            } else if (!launcherRoot._preloadProcs[waitingFor]) {
                // Preload finished but no cache entry (failed) — stop waiting
                running = false;
                launcherRoot.completeModeLoad(waitingFor, false, "Preload failed");
            }
        }
    }

    Timer {
        id: windowLoadTimer
        interval: 100
        repeat: false
        onTriggered: launcherRoot.loadWindows()
    }

    Timer {
        id: transientNoticeTimer
        interval: 2800
        repeat: false
        onTriggered: launcherRoot.transientNoticeText = ""
    }

    // Reactive watchers: ObjectModel doesn't expose countChanged as a signal,
    // so we use property bindings that re-evaluate when the model count changes.
    readonly property int _toplevelCount: availableToplevels ? availableToplevels.length || 0 : 0
    on_ToplevelCountChanged: {
        if (launcherRoot.mode === "window" && launcherRoot.launcherOpacity > 0)
            launcherRoot.loadWindows();
    }

    readonly property int _mprisCount: Mpris.players ? Mpris.players.length || 0 : 0
    on_MprisCountChanged: {
        if (launcherRoot.mode === "media" && launcherRoot.launcherOpacity > 0)
            launcherRoot.refreshMediaPlayers();
    }

    property var _nixGens: NixOS.generations
    on_NixGensChanged: {
        if (launcherRoot.mode === "nixos" && launcherRoot.launcherOpacity > 0)
            launcherRoot.loadNixos();
    }

    onSelectedIndexChanged: {
        launcherRoot.rememberCurrentWebProviderSelection();
    }

    function computeModeOrder() {
        var order = ModeData.sanitizeModeList(Config.launcherModeOrder, defaultModeOrder, allKnownModes);
        var enabled = ModeData.sanitizeModeList(Config.launcherEnabledModes, defaultModeOrder, allKnownModes);
        var enabledSet = ({});
        var i;
        for (i = 0; i < enabled.length; ++i)
            enabledSet[enabled[i]] = true;
        var filtered = [];
        for (i = 0; i < order.length; ++i) {
            var modeKey = order[i];
            if (enabledSet[modeKey] && isModeAllowedByCompositor(modeKey))
                filtered.push(modeKey);
        }
        if (filtered.length === 0)
            return ["drun"];
        return filtered;
    }

    function isModeAllowedByCompositor(modeKey) {
        if (modeKey === "window" && !CompositorAdapter.supportsWindowListing)
            return false;
        if (modeKey === "keybinds" && !CompositorAdapter.supportsHotkeysListing)
            return false;
        return true;
    }

    function supportsMode(modeKey) {
        return modeOrder.indexOf(modeKey) !== -1 || transientModes.indexOf(modeKey) !== -1;
    }

    function effectiveDefaultMode() {
        if (supportsMode(Config.launcherDefaultMode))
            return Config.launcherDefaultMode;
        return modeOrder.length > 0 ? modeOrder[0] : "drun";
    }

    function setModeHint(title, subtitle, iconName) {
        allItems = [
            {
                name: title,
                title: subtitle || "",
                icon: iconName || (modeIcons[mode] || "󰋼"),
                isHint: true
            }
        ];
        filterItems();
    }

    readonly property var _cachedWebProviders: ModeData.configuredWebProviders(Config.launcherWebProviderOrder)

    function configuredWebProviders() {
        return _cachedWebProviders;
    }

    function primaryWebProvider() {
        var list = configuredWebProviders();
        return list.length > 0 ? list[0] : null;
    }

    function configuredWebProviderByKey(providerKey) {
        var key = String(providerKey || "");
        if (key === "")
            return null;
        var list = configuredWebProviders();
        for (var i = 0; i < list.length; ++i) {
            if (String(list[i].key || "") === key)
                return list[i];
        }
        return null;
    }

    function webAliasToProviderKey(token) {
        var aliases = (Config.launcherWebAliases && typeof Config.launcherWebAliases === "object") ? Config.launcherWebAliases : ({});
        return ModeData.webAliasToProviderKey(token, configuredWebProviders(), aliases);
    }

    function parseWebQuery(text) {
        var aliases = (Config.launcherWebAliases && typeof Config.launcherWebAliases === "object") ? Config.launcherWebAliases : ({});
        return ModeData.parseWebQuery(text, configuredWebProviders(), aliases);
    }

    function secondaryWebProvider() {
        var list = configuredWebProviders();
        if (list.length <= 1)
            return null;
        return list[1];
    }

    function preferredWebProviderKey() {
        if (Config.launcherRememberWebProvider) {
            var persisted = String(Config.launcherWebLastProviderKey || "");
            if (persisted !== "")
                return persisted;
        }
        return String(_sessionWebProviderKey || "");
    }

    function applyRememberedWebProviderSelection() {
        if (mode !== "web" || filteredItems.length <= 0)
            return;
        var preferred = preferredWebProviderKey();
        if (preferred === "")
            return;
        for (var i = 0; i < filteredItems.length; ++i) {
            if (String(filteredItems[i].key || "") === preferred) {
                selectedIndex = i;
                return;
            }
        }
    }

    function rememberCurrentWebProviderSelection() {
        if (mode !== "web" || !selectedItem)
            return;
        var key = String(selectedItem.key || "");
        if (key === "")
            return;
        _sessionWebProviderKey = key;
        if (Config.launcherRememberWebProvider && Config.launcherWebLastProviderKey !== key)
            Config.launcherWebLastProviderKey = key;
    }

    function telemetryStart() {
        return Date.now();
    }

    function telemetryEnd(label, startedAt) {
        if (!Config.launcherEnableDebugTimings)
            return;
        var took = Math.max(0, Date.now() - startedAt);
        console.debug("Launcher timing:", label, took + "ms");
    }

    function beginRequest(modeKey) {
        _requestToken += 1;
        var next = Object.assign({}, _activeRequests);
        next[modeKey] = _requestToken;
        _activeRequests = next;
        return _requestToken;
    }

    function isRequestCurrent(modeKey, token) {
        return _activeRequests[modeKey] === token;
    }

    function getCached(modeKey) {
        var items = modeCache[modeKey];
        if (!items)
            return null;
        var ttlMs = Math.max(1, Config.launcherCacheTtlSec) * 1000;
        var last = modeCacheTime[modeKey] || 0;
        if (Date.now() - last > ttlMs) {
            var nextCache = Object.assign({}, modeCache);
            var nextTimes = Object.assign({}, modeCacheTime);
            delete nextCache[modeKey];
            delete nextTimes[modeKey];
            modeCache = nextCache;
            modeCacheTime = nextTimes;
            return null;
        }
        return items;
    }

    function setCached(modeKey, items) {
        var nextCache = Object.assign({}, modeCache);
        var nextTimes = Object.assign({}, modeCacheTime);
        nextCache[modeKey] = items;
        nextTimes[modeKey] = Date.now();
        modeCache = nextCache;
        modeCacheTime = nextTimes;
    }

    function clearCaches() {
        if (fileIndexProc.running)
            fileIndexProc.running = false;
        modeCache = ({});
        modeCacheTime = ({});
        fileQueryCache = ({});
        fileQueryCacheTime = ({});
        fileIndexItems = [];
        fileIndexReady = false;
        fileIndexBuilding = false;
        fileIndexBuiltAt = 0;
    }

    function getFileQueryCached(queryKey) {
        var items = fileQueryCache[queryKey];
        if (!items)
            return null;
        var ttlMs = Math.max(1, Config.launcherCacheTtlSec) * 1000;
        var last = fileQueryCacheTime[queryKey] || 0;
        if (Date.now() - last > ttlMs) {
            var nextCache = Object.assign({}, fileQueryCache);
            var nextTimes = Object.assign({}, fileQueryCacheTime);
            delete nextCache[queryKey];
            delete nextTimes[queryKey];
            fileQueryCache = nextCache;
            fileQueryCacheTime = nextTimes;
            return null;
        }
        return items;
    }

    function setFileQueryCached(queryKey, items) {
        var nextCache = Object.assign({}, fileQueryCache);
        var nextTimes = Object.assign({}, fileQueryCacheTime);
        nextCache[queryKey] = items;
        nextTimes[queryKey] = Date.now();
        fileQueryCache = nextCache;
        fileQueryCacheTime = nextTimes;
    }

    function modeMetric(modeKey) {
        return Metrics.modeMetric(launcherMetrics, modeKey);
    }

    function clearLauncherMetrics() {
        launcherMetrics = Metrics.freshMetrics();
    }

    function fileIndexStale() {
        if (!fileIndexReady)
            return true;
        var ttlMs = Math.max(1, Config.launcherCacheTtlSec) * 1000;
        return (Date.now() - fileIndexBuiltAt) > ttlMs;
    }

    function buildFileIndex(homeDir) {
        if (fileIndexBuilding)
            return;
        fileIndexBuilding = true;
        fileIndexReady = false;
        if (mode === "files" && fileIndexItems.length === 0)
            beginModeLoad("files", "Building file index");
        fileIndexProc._startedAt = Date.now();
        fileIndexProc.command = ["fd", "--hidden", "--base-directory", homeDir, "--max-depth", "8",
            "--max-results", "50000",
            "--exclude", ".git", "--exclude", ".cache", "--exclude", "node_modules",
            "--exclude", ".local/share/Trash", "--exclude", ".local/share/Steam",
            "--exclude", ".cargo", "--exclude", ".npm", "--exclude", ".mozilla",
            "."];
        fileIndexProc.running = true;
        fileIndexTimeoutTimer.restart();
    }

    function _handleFileIndexBuilt(raw, startedAt) {
        fileIndexTimeoutTimer.stop();
        var tookMs = Math.max(0, Date.now() - startedAt);
        fileIndexBuilding = false;
        var homeDir = Quickshell.env("HOME") || "/";
        function _finishIndex(items) {
            fileIndexItems = items;
            fileIndexReady = true;
            fileIndexBuiltAt = Date.now();
            recordFilesBackendLoad("fd", tookMs);
            if (mode === "files" && ModeData.stripModePrefix(searchText).trim().length >= Config.launcherFileMinQueryLength)
                loadFiles();
            else if (mode === "files" && modeLoadState === "loading")
                completeModeLoad("files", true, "");
        }
        // Estimate line count cheaply: raw length > ~500KB likely means >10k lines
        if (raw && raw.length > 500000) {
            _startChunkedParse(raw, homeDir, _finishIndex);
        } else {
            _finishIndex(FileParser.buildFileItemsFromRaw(raw, homeDir));
        }
    }

    function recordFilesBackendLoad(backend, durationMs) {
        launcherMetrics = Metrics.recordFilesBackendLoad(launcherMetrics, backend, durationMs);
    }

    function recordFilesBackendResolveMetric(durationMs) {
        launcherMetrics = Metrics.recordFilesBackendResolveMetric(launcherMetrics, durationMs);
    }

    function recordFilterMetric(durationMs) {
        launcherMetrics = Metrics.recordFilterMetric(launcherMetrics, durationMs);
    }

    function recordLoadMetric(modeKey, durationMs, cacheHit, success) {
        launcherMetrics = Metrics.recordLoadMetric(launcherMetrics, modeKey, durationMs, cacheHit, success);
    }

    function shouldBackoffPreload(modeKey) {
        var state = preloadFailureState[modeKey];
        if (!state)
            return false;
        var threshold = Math.max(1, Config.launcherPreloadFailureThreshold);
        if ((state.failures || 0) < threshold)
            return false;
        var backoffMs = Math.max(10, Config.launcherPreloadFailureBackoffSec) * 1000;
        return (Date.now() - (state.lastFailure || 0)) < backoffMs;
    }

    function markPreloadFailure(modeKey) {
        var next = Object.assign({}, preloadFailureState);
        var current = Object.assign({
            failures: 0,
            lastFailure: 0
        }, next[modeKey] || ({}));
        current.failures += 1;
        current.lastFailure = Date.now();
        next[modeKey] = current;
        preloadFailureState = next;
    }

    function markPreloadSuccess(modeKey) {
        if (!preloadFailureState[modeKey])
            return;
        var next = Object.assign({}, preloadFailureState);
        delete next[modeKey];
        preloadFailureState = next;
    }

    function saveFrequency() {
        freqFile.setText(JSON.stringify(appFrequency));
    }
    function saveHistory() {
        historyFile.setText(JSON.stringify(launchHistory));
    }

    function formatDrunCategoryLabel(categoryKey) {
        var key = String(categoryKey || "");
        if (key === "")
            return "All";
        return key.charAt(0).toUpperCase() + key.slice(1);
    }

    function drunBrowseSectionLabel() {
        if (String(drunCategoryFilter || "") !== "")
            return formatDrunCategoryLabel(drunCategoryFilter);
        return "All Apps";
    }

    function resultSectionLabel(item) {
        return SystemItems.resultSectionLabel(mode, item, {
            drunCategoryFiltersEnabled: drunCategoryFiltersEnabled,
            formatDrunCategoryLabel: formatDrunCategoryLabel,
            ensureItemRankCache: Search.ensureItemRankCache,
            modeInfoFn: modeInfo
        });
    }

    function homeItemKey(item) {
        if (!item)
            return "";
        var keys = [item._homeKey, item.exec, item.address, item.appId, item.desktopId, item.fullPath, item.name, item.title];
        for (var i = 0; i < keys.length; ++i) {
            var value = String(keys[i] || "").trim();
            if (value !== "")
                return value;
        }
        return "";
    }

    function decorateResultSections(items) {
        var source = Array.isArray(items) ? items : [];
        for (var i = 0; i < source.length; ++i) {
            var entry = source[i];
            if (!entry)
                continue;
            if (String(entry.sectionLabel || "") === "")
                entry.sectionLabel = resultSectionLabel(entry);
        }
        return source;
    }

    function itemMatchesDrunCategory(item, categoryKey) {
        var key = String(categoryKey || "");
        if (key === "")
            return true;
        Search.ensureItemRankCache(item);
        var tokens = item._categoryTokens || [];
        for (var i = 0; i < tokens.length; ++i) {
            if (tokens[i] === key)
                return true;
        }
        return false;
    }

    function resetDrunCategoryState(count) {
        drunCategoryFilter = "";
        drunCategoryOptions = [{ key: "", label: "All", count: count || 0, hotkey: "0" }];
    }

    function refreshDrunCategoryOptions(apps) {
        if (!drunCategoryFiltersEnabled) {
            resetDrunCategoryState(Array.isArray(apps) ? apps.length : 0);
            return;
        }
        var next = CategoryHelpers.buildCategoryOptions(apps, formatDrunCategoryLabel);
        drunCategoryOptions = next;
        drunCategoryFilter = CategoryHelpers.validateCategoryFilter(drunCategoryFilter, next);
    }

    function setDrunCategoryFilter(categoryKey) {
        if (!drunCategoryFiltersEnabled) {
            categoryKey = "";
        }
        var next = String(categoryKey || "");
        if (drunCategoryFilter === next)
            return false;
        drunCategoryFilter = next;
        drunCategorySectionExpanded = next !== "";
        scheduleSearchRefresh(true);
        return true;
    }

    function cycleDrunCategoryFilter(step) {
        if (!drunCategoryFiltersEnabled || mode !== "drun" || drunCategoryOptions.length <= 1)
            return false;
        var currentIndex = 0;
        for (var i = 0; i < drunCategoryOptions.length; ++i) {
            if (String(drunCategoryOptions[i].key || "") === drunCategoryFilter) {
                currentIndex = i;
                break;
            }
        }
        var nextIndex = (currentIndex + step + drunCategoryOptions.length) % drunCategoryOptions.length;
        return setDrunCategoryFilter(String((drunCategoryOptions[nextIndex] || {}).key || ""));
    }

    function jumpDrunCategoryBoundary(toEnd) {
        if (!drunCategoryFiltersEnabled || mode !== "drun" || drunCategoryOptions.length <= 1)
            return false;
        var targetIndex = toEnd ? (drunCategoryOptions.length - 1) : 0;
        return setDrunCategoryFilter(String((drunCategoryOptions[targetIndex] || {}).key || ""));
    }

    function selectDrunCategorySlot(slot) {
        if (!drunCategoryFiltersEnabled || mode !== "drun" || slot < 1)
            return false;
        if (slot >= drunCategoryOptions.length)
            return false;
        return setDrunCategoryFilter(String((drunCategoryOptions[slot] || {}).key || ""));
    }

    function rememberRecent(item) {
        var key = item.exec || item.address || item.appId || item.fullPath || item.name || item.title || "";
        if (!key)
            return;
        var next = [
            {
                key: key,
                name: item.name || item.label || item.title || key,
                title: item.title || item.description || item.exec || "",
                icon: item.icon || modeIcons[mode] || "󰀻",
                appId: item.appId || "",
                exec: item.exec || "",
                address: item.address || "",
                openMode: item.openMode || "",
                timestamp: Date.now()
            }
        ];
        for (var i = 0; i < launchHistory.length; ++i) {
            if (launchHistory[i].key !== key)
                next.push(launchHistory[i]);
            if (next.length >= Config.launcherRecentsLimit)
                break;
        }
        launchHistory = next;
        saveHistory();
    }

    function trackLaunch(item) {
        var exec = item && item.exec ? item.exec : "";
        if (exec) {
            appFrequency[exec] = (appFrequency[exec] || 0) + 1;
            UsageTrackerService.recordUsage(exec);
            var cached = getCached("drun");
            if (cached) {
                refreshDrunUsageCaches(cached);
                if (allItems !== cached)
                    refreshDrunUsageCaches(allItems);
            }
            resetFilterCache();
        }
        saveFrequency();
        rememberRecent(item || {});
        buildLauncherHome();
    }

    function buildLauncherHome() {
        suggestionItems = [];
        if (mode === "drun") {
            var apps = getCached("drun") || [];
            refreshDrunCategoryOptions(apps);
            var result = HomeBuilder.buildDrunHome(apps, launchHistory, drunCategoryFilter, UsageTrackerService, {
                recentAppsLimit: Config.launcherRecentAppsLimit,
                suggestionsLimit: Config.launcherSuggestionsLimit,
                itemMatchesDrunCategory: itemMatchesDrunCategory
            });
            recentItems = result.recentItems;
            suggestionItems = result.suggestionItems;
        } else if (mode === "system") {
            resetDrunCategoryState(0);
            recentItems = SystemActionRegistry.shellEntryActions;
        } else if (mode === "window" && availableToplevels.length > 0) {
            resetDrunCategoryState(0);
            recentItems = [
                {
                    name: "Focus open windows",
                    title: "Jump into current clients",
                    icon: "󰖯",
                    openMode: "window"
                }
            ];
        } else {
            resetDrunCategoryState(0);
            recentItems = [];
        }
    }

    Timer {
        id: mouseTrackingDelayTimer
        interval: 350
        onTriggered: {
            launcherRoot.mouseTrackingReady = true;
            launcherRoot.globalMouseInitialized = false;
        }
    }

    function open(newMode, keepSearch) {
        var startedAt = telemetryStart();
        if (showingConfirm)
            cancelConfirm();
        var nextMetrics = Object.assign({}, launcherMetrics);
        nextMetrics.opens = (nextMetrics.opens || 0) + 1;
        if (!nextMetrics.perMode)
            nextMetrics.perMode = ({});
        launcherMetrics = nextMetrics;
        openCount++;
        if (openCount % 10 === 0)
            clearCaches();
        ignoreMouseHover = true;
        searchDebounceTimer.stop();
        fileSearchDebounceTimer.stop();
        mouseTrackingReady = false;
        globalMouseInitialized = false;
        mouseTrackingDelayTimer.restart();
        var requestedMode = newMode || effectiveDefaultMode();
        if (!supportsMode(requestedMode))
            requestedMode = effectiveDefaultMode();
        mode = requestedMode;
        setModeLoadState("idle", mode, "");
        drunCategorySectionExpanded = false;
        buildLauncherHome();
        var shouldKeepSearch = keepSearch === true && Config.launcherKeepSearchOnModeSwitch;
        if (!shouldKeepSearch) {
            searchText = "";
            if (searchInputComp.searchInput)
                searchInputComp.searchInput.text = "";
        }
        selectedIndex = 0;
        launcherOpacity = 1;
        scaleValue = 1.0;
        Qt.callLater(function () {
            if (searchInputComp.searchInput)
                searchInputComp.searchInput.forceActiveFocus();
        });

        depChecker.ensureModeDependencies(mode, function (ok, missingCmd) {
            if (!ok) {
                setModeHint("Dependency missing", ModeData.missingDependencyMessage(mode, missingCmd), "󰋼");
                completeModeLoad(mode, false, "Dependency missing");
                return;
            }

            if (mode === "drun")
                loadApps();
            else if (mode === "window") {
                allItems = [];
                filterItems();
                beginModeLoad("window", "Loading windows");
                windowLoadTimer.restart();
            } else if (mode === "run")
                loadRun();
            else if (mode === "emoji")
                loadEmojis();
            else if (mode === "clip")
                loadClip();
            else if (mode === "calc") {
                allItems = [];
                filterItems();
                completeModeLoad("calc", true, "");
            } else if (mode === "web")
                loadWeb();
            else if (mode === "plugins")
                loadPlugins();
            else if (mode === "system")
                loadSystem();
            else if (mode === "media") {
                allItems = [];
                filterItems();
                completeModeLoad("media", true, "");
                refreshMediaPlayers();
            } else if (mode === "nixos")
                loadNixos();
            else if (mode === "wallpapers")
                loadWallpapers();
            else if (mode === "files") {
                prewarmFileIndex();
                loadFiles();
            } else if (mode === "bookmarks")
                loadBookmarks();
            else if (mode === "settings")
                loadSettings();
            else if (mode === "devops")
                loadDevOps();
            else if (mode === "orchestrator")
                loadOrchestrator();
            else if (mode === "ai")
                loadAi();
            else if (mode === "keybinds")
                loadKeybinds();
            else if (mode === "dmenu") {
                filterItems();
                completeModeLoad("dmenu", true, "");
            }
        });

        // Start background preload of other cacheable modes
        if (Config.launcherEnablePreload)
            preloadDelayTimer.restart();

        telemetryEnd("open:" + mode, startedAt);
    }

    function close() {
        if (searchInputComp.searchInput && searchInputComp.searchInput.activeFocus)
            searchInputComp.searchInput.focus = false;
        launcherOpacity = 0;
        scaleValue = 0.94;
        yOffset = 15;
        ignoreMouseHover = true;
        mouseTrackingDelayTimer.stop();
        searchDebounceTimer.stop();
        fileSearchDebounceTimer.stop();
        commandTimeoutTimer.stop();
        fileIndexTimeoutTimer.stop();
        _cancelChunkedFilter();
        _parseChunkToken++;
        parseChunkTimer.stop();
        _parseChunkState = null;
        if (commandProc.running) {
            suppressNextCommandExit = true;
            pendingCommand = null;
            pendingCommandOutput = null;
            pendingCommandError = null;
            commandProc.running = false;
        }
        preloadDelayTimer.stop();
        preloadWaitTimer.stop();
        var _keys = Object.keys(_preloadProcs);
        for (var _i = 0; _i < _keys.length; _i++) {
            if (_preloadProcs[_keys[_i]].running)
                _preloadProcs[_keys[_i]].running = false;
            _preloadProcs[_keys[_i]].destroy();
        }
        _preloadProcs = {};
        if (showingConfirm)
            confirmTitle = "";
        setModeLoadState("idle", mode, "");
    }

    function cycleMode(step) {
        var currentIndex = modeOrder.indexOf(mode);
        if (currentIndex === -1)
            currentIndex = 0;
        var nextIndex = (currentIndex + step + modeOrder.length) % modeOrder.length;
        open(modeOrder[nextIndex], true);
    }

    function askConfirm(title, callback) {
        confirmTitle = title;
        confirmCallback = callback;
    }

    function makeConfirmedSystemAction(title, actionId) {
        return function () {
            askConfirm(title, function () {
                SystemActionRegistry.execute(actionId);
            });
        };
    }

    function makeDetachedSystemAction(actionId) {
        return function () {
            SystemActionRegistry.execute(actionId);
        };
    }

    function runShellEntryAction(actionId) {
        var action = SystemActionRegistry.actionById(actionId) || ({});
        var command = Array.isArray(action.clickCommand) ? action.clickCommand : [];
        if (command.length > 0)
            Quickshell.execDetached(command);
    }

    function cancelConfirm() {
        confirmTitle = "";
        confirmCallback = null;
        searchInputComp.searchInput.forceActiveFocus();
    }

    function doConfirm() {
        if (confirmCallback)
            confirmCallback();
        confirmTitle = "";
        confirmCallback = null;
        close();
    }

    function startCommand(command, callback, errorCallback) {
        onCommandOutput = callback;
        onCommandError = errorCallback || null;
        commandStdoutBuffer = "";
        commandStderrBuffer = "";
        commandProc.command = command;
        commandProc.running = true;
        commandTimeoutTimer.restart();
    }

    function runCommand(command, callback, errorCallback) {
        if (commandProc.running) {
            pendingCommand = command;
            pendingCommandOutput = callback;
            pendingCommandError = errorCallback || null;
            suppressNextCommandExit = true;
            commandProc.running = false;
            return;
        }
        startCommand(command, callback, errorCallback);
    }

    function _handleLoadFailure(modeKey, startedAt) {
        recordLoadMetric(modeKey, Date.now() - startedAt, false, false);
        if (mode === modeKey) {
            setModeHint("Failed to load " + modeInfo(modeKey).label, "Check helper command output and logs.", "󰅚");
            completeModeLoad(modeKey, false, "Failed to load " + modeInfo(modeKey).label);
        }
    }

    function loadCached(modeKey, command, parseFunc) {
        var startedAt = Date.now();
        var cached = getCached(modeKey);
        if (cached) {
            allItems = cached;
            filterItems();
            buildLauncherHome();
            completeModeLoad(modeKey, true, "");
            recordLoadMetric(modeKey, 0, true, true);
            return;
        }
        // If a preload is already running for this mode, wait for it
        if (_preloadProcs[modeKey]) {
            allItems = [];
            filteredItems = [];
            beginModeLoad(modeKey, "Loading " + modeInfo(modeKey).label);
            filterItems();
            _waitForPreload(modeKey);
            return;
        }
        allItems = [];
        filteredItems = [];
        beginModeLoad(modeKey, "Loading " + modeInfo(modeKey).label);
        filterItems();
        var token = beginRequest(modeKey);
        runCommand(command, function (raw) {
            if (!isRequestCurrent(modeKey, token))
                return;
            try {
                var items = raw ? parseFunc(raw) : [];
                if (!Array.isArray(items))
                    items = [];
                setCached(modeKey, items);
                recordLoadMetric(modeKey, Date.now() - startedAt, false, true);
                if (mode === modeKey) {
                    allItems = items;
                    filterItems();
                    buildLauncherHome();
                    completeModeLoad(modeKey, true, "");
                }
            } catch (e) {
                _handleLoadFailure(modeKey, startedAt);
            }
        }, function (errorText, exitCode, _exitStatus) {
            if (!isRequestCurrent(modeKey, token))
                return;
            console.warn("Launcher load command failed for", modeKey, "exit", exitCode, errorText || "");
            _handleLoadFailure(modeKey, startedAt);
        });
    }

    function loadApps() {
        var startedAt = Date.now();
        var cached = getCached("drun");
        if (cached) {
            allItems = cached;
            refreshDrunUsageCaches(allItems);
            resetFilterCache();
            filterItems();
            buildLauncherHome();
            completeModeLoad("drun", true, "");
            recordLoadMetric("drun", 0, true, true);
            return;
        }
        allItems = [];
        filteredItems = [];
        beginModeLoad("drun", "Loading " + modeInfo("drun").label);
        filterItems();
        var token = beginRequest("drun");
        AppCatalogService.ensureLoaded(function(items, errorText) {
            if (!isRequestCurrent("drun", token))
                return;
            if (errorText) {
                console.warn("Launcher app catalog load failed:", errorText);
                _handleLoadFailure("drun", startedAt);
                return;
            }
            var appItems = prepareDrunItems(items);
            setCached("drun", appItems);
            recordLoadMetric("drun", Date.now() - startedAt, false, true);
            if (mode === "drun") {
                allItems = appItems;
                resetFilterCache();
                filterItems();
                buildLauncherHome();
                completeModeLoad("drun", true, "");
            }
        });
    }

    function prewarmAppsCache() {
        if (!supportsMode("drun"))
            return;
        if (getCached("drun"))
            return;
        if (shouldBackoffPreload("drun"))
            return;

        depChecker.ensureModeDependencies("drun", function (ok, _missingCmd) {
            if (!ok)
                return;
            if (getCached("drun"))
                return;
            AppCatalogService.ensureLoaded(function(items, errorText) {
                if (!errorText)
                    setCached("drun", prepareDrunItems(items));
            });
        });
    }
    function loadRun() {
        loadCached("run", DependencyService.resolveCommand("qs-run"), JSON.parse);
    }
    function loadWallpapers() {
        loadCached("wallpapers", DependencyService.resolveCommand("qs-wallpapers"), JSON.parse);
    }
    function loadKeybinds() {
        loadCached("keybinds", DependencyService.resolveCommand("qs-keybinds"), JSON.parse);
    }
    function loadBookmarks() {
        loadCached("bookmarks", DependencyService.resolveCommand("qs-bookmarks"), JSON.parse);
    }


    function clipModeItems(items) {
        return (Array.isArray(items) ? items : []).map(function (it) {
            return {
                id: it.id,
                name: it.content,
                title: it.content,
                icon: "󰅍"
            };
        });
    }
    function loadEmojis() {
        var cached = getCached("emoji");
        if (cached) {
            allItems = cached;
            filterItems();
            buildLauncherHome();
            completeModeLoad("emoji", true, "");
            recordLoadMetric("emoji", 0, true, true);
            return;
        }
        setCached("emoji", EmojiData.emojis);
        allItems = EmojiData.emojis;
        filterItems();
        buildLauncherHome();
        completeModeLoad("emoji", true, "");
        recordLoadMetric("emoji", 0, false, true);
    }
    function loadClip() {
        var startedAt = Date.now();
        var cached = getCached("clip");
        if (cached) {
            allItems = cached;
            filterItems();
            buildLauncherHome();
            completeModeLoad("clip", true, "");
            recordLoadMetric("clip", 0, true, true);
            return;
        }
        allItems = [];
        filteredItems = [];
        beginModeLoad("clip", "Loading " + modeInfo("clip").label);
        filterItems();
        var token = beginRequest("clip");
        ClipboardHistoryService.refresh(function(items, errorText) {
            if (!isRequestCurrent("clip", token))
                return;
            if (errorText) {
                console.warn("Launcher clipboard load failed:", errorText);
                _handleLoadFailure("clip", startedAt);
                return;
            }
            var clipItems = clipModeItems(items);
            setCached("clip", clipItems);
            recordLoadMetric("clip", Date.now() - startedAt, false, true);
            if (mode === "clip") {
                allItems = clipItems;
                filterItems();
                buildLauncherHome();
                completeModeLoad("clip", true, "");
            }
        });
    }

    // ── Background preloading ───────────────────
    readonly property var preloadModes: ({
            "run": {
                command: DependencyService.resolveCommand("qs-run"),
                parse: JSON.parse
            },
            "keybinds": {
                command: DependencyService.resolveCommand("qs-keybinds"),
                parse: JSON.parse
            },
            "bookmarks": {
                command: DependencyService.resolveCommand("qs-bookmarks"),
                parse: JSON.parse
            }
        })

    function startPreload() {
        if (!Config.launcherEnablePreload)
            return;
        prewarmAppsCache();
        prewarmClipCache();
        var keys = Object.keys(preloadModes);
        for (var i = 0; i < keys.length; i++) {
            var key = keys[i];
            if (key !== mode && !shouldBackoffPreload(key) && !getCached(key) && !_preloadProcs[key]) {
                _spawnPreload(key);
            }
        }
    }

    function _spawnPreload(key) {
        if (!preloadModes[key])
            return;
        var command = preloadModes[key].command;
        if (!command || command.length === 0)
            return;
        var proc = preloadProcComponent.createObject(launcherRoot);
        proc._modeKey = key;
        proc._startedAt = Date.now();
        proc.command = command;
        _preloadProcs[key] = proc;
        proc.running = true;
    }

    function prewarmClipCache() {
        if (!supportsMode("clip"))
            return;
        if (getCached("clip"))
            return;
        if (shouldBackoffPreload("clip"))
            return;
        depChecker.ensureModeDependencies("clip", function(ok, _missingCmd) {
            if (!ok)
                return;
            ClipboardHistoryService.ensureLoaded(function(items, errorText) {
                if (!errorText)
                    setCached("clip", clipModeItems(items));
            });
        });
    }

    function _handlePreloadDone(proc, raw) {
        var key = proc._modeKey;
        var tookMs = Math.max(0, Date.now() - (proc._startedAt || Date.now()));
        var ok = false;
        if (raw && key && preloadModes[key]) {
            try {
                setCached(key, preloadModes[key].parse(raw));
                ok = true;
            } catch (e) {}
        }
        if (ok) {
            markPreloadSuccess(key);
            recordLoadMetric(key, tookMs, false, true);
        } else {
            markPreloadFailure(key);
            recordLoadMetric(key, tookMs, false, false);
        }
        delete _preloadProcs[key];
        proc.destroy();
    }

    function _waitForPreload(modeKey) {
        preloadWaitTimer.waitingFor = modeKey;
        preloadWaitTimer.restart();
    }

    function _startChunkedParse(raw, homeDir, callback) {
        _parseChunkToken++;
        var lines = raw ? raw.split("\n") : [];
        var homePrefix = homeDir.endsWith("/") ? homeDir : (homeDir + "/");
        _parseChunkState = {
            token: _parseChunkToken,
            lines: lines,
            homeDir: homeDir,
            homePrefix: homePrefix,
            items: new Array(lines.length),
            idx: 0,
            count: 0,
            callback: callback
        };
        parseChunkTimer.restart();
    }

    function _processParseChunk() {
        var state = _parseChunkState;
        if (!state || state.token !== _parseChunkToken)
            return;
        var result = FileParser.processParseChunk(state, 5000);
        if (state.token !== _parseChunkToken)
            return;
        if (result.done) {
            var cb = state.callback;
            _parseChunkState = null;
            cb(result.items);
        } else {
            parseChunkTimer.restart();
        }
    }

    function prewarmFileIndex() {
        resolveFileSearchBackend(function (backend) {
            if (backend !== "fd" || !fileIndexStale())
                return;
            buildFileIndex(Quickshell.env("HOME") || "/");
        });
    }

    function resolveFileSearchBackend(callback) {
        if (fileSearchBackend === "fd" || fileSearchBackend === "find" || fileSearchBackend === "none") {
            var now = Date.now();
            var maxAge = fileSearchBackend === "none" ? fileSearchBackendMissRefreshMs : fileSearchBackendRefreshMs;
            if ((now - fileSearchBackendResolvedAt) <= Math.max(1000, maxAge)) {
                callback(fileSearchBackend);
                return;
            }
            fileSearchBackend = "";
            fileSearchBackendResolvedAt = 0;
            depChecker.invalidateCommandAvailability("fd");
            depChecker.invalidateCommandAvailability("find");
        }
        var startedAt = Date.now();
        depChecker.checkCommandAvailable("fd", function (fdOk) {
            if (fdOk) {
                fileSearchBackend = "fd";
                fileSearchBackendResolvedAt = Date.now();
                recordFilesBackendResolveMetric(Date.now() - startedAt);
                callback("fd");
                return;
            }
            depChecker.checkCommandAvailable("find", function (findOk) {
                fileSearchBackend = findOk ? "find" : "none";
                fileSearchBackendResolvedAt = Date.now();
                recordFilesBackendResolveMetric(Date.now() - startedAt);
                callback(fileSearchBackend);
            });
        });
    }

    function showTransientNotice(message, durationMs) {
        transientNoticeText = String(message || "");
        if (transientNoticeText === "") {
            transientNoticeTimer.stop();
            return;
        }
        transientNoticeTimer.interval = Math.max(1200, Math.round(durationMs || 2800));
        transientNoticeTimer.restart();
    }

    function filesBackendStatusObject() {
        return Diag.filesBackendStatusObject({
            filesBackendLabel: filesBackendLabel,
            fileSearchBackend: fileSearchBackend,
            fileSearchBackendResolvedAt: fileSearchBackendResolvedAt,
            fileIndexReady: fileIndexReady,
            fileIndexBuilding: fileIndexBuilding,
            fileIndexItemsLength: fileIndexItems.length,
            launcherMetrics: launcherMetrics,
            filesCacheStatsLabel: filesCacheStatsLabel,
            modeMetricFn: modeMetric
        });
    }

    function drunCategoryStateObject() {
        return Diag.drunCategoryStateObject({
            drunCategoryOptions: drunCategoryOptions,
            drunCategoryFilter: drunCategoryFilter,
            drunCategoryFiltersEnabled: drunCategoryFiltersEnabled,
            mode: mode,
            showLauncherHome: showLauncherHome,
            formatLabelFn: formatDrunCategoryLabel
        });
    }

    function escapeActionStateObject() {
        return Diag.escapeActionStateObject({
            showingConfirm: showingConfirm,
            searchText: searchText,
            drunCategoryFiltersEnabled: drunCategoryFiltersEnabled,
            mode: mode,
            drunCategoryFilter: drunCategoryFilter,
            drunCategorySectionExpanded: drunCategorySectionExpanded
        });
    }

    function launcherStateObject() {
        return Diag.launcherStateObject({
            launcherOpacity: launcherOpacity,
            mode: mode,
            searchText: searchText,
            showLauncherHome: showLauncherHome,
            drunCategoryFilter: drunCategoryFilter,
            drunCategorySectionExpanded: drunCategorySectionExpanded,
            filteredItemsLength: filteredItems.length,
            modeLoadState: modeLoadState,
            modeLoadMessage: modeLoadMessage,
            allItemsLength: allItems.length,
            recentItemsLength: recentItems.length,
            suggestionItemsLength: suggestionItems.length,
            fileIndexReady: fileIndexReady,
            fileIndexBuilding: fileIndexBuilding,
            fileIndexItemsLength: fileIndexItems.length,
            selectedIndex: selectedIndex,
            width: width,
            height: height,
            screenWidth: screenRef ? screenRef.width : 0,
            screenHeight: screenRef ? screenRef.height : 0,
            actualViewportWidth: actualViewportWidth,
            actualViewportHeight: actualViewportHeight,
            viewportWidth: viewportWidth,
            viewportHeight: viewportHeight,
            usableWidth: usableWidth,
            usableHeight: usableHeight,
            actualUsableWidth: actualUsableWidth,
            actualUsableHeight: actualUsableHeight,
            diagnosticViewportOffsetX: diagnosticViewportOffsetX,
            diagnosticViewportOffsetY: diagnosticViewportOffsetY,
            hudX: hudBox.x,
            hudY: hudBox.y + yOffset,
            hudWidth: hudBox.width,
            hudHeight: hudBox.height,
            hudScale: scaleValue
        });
    }

    function diagnosticSetSearchText(text) {
        searchText = String(text || "");
        if (searchInputComp.searchInput)
            searchInputComp.searchInput.text = searchText;
        scheduleSearchRefresh(false);
        return JSON.stringify(escapeActionStateObject());
    }

    function diagnosticSetDrunCategoryFilter(categoryKey) {
        var nextKey = String(categoryKey || "");
        var changed = setDrunCategoryFilter(nextKey);
        return JSON.stringify({
            changed: changed === true,
            state: escapeActionStateObject()
        });
    }

    function diagnosticSetViewport(widthValue, heightValue) {
        diagnosticViewportWidth = Math.max(0, Number(widthValue || 0));
        diagnosticViewportHeight = Math.max(0, Number(heightValue || 0));
        return JSON.stringify(launcherStateObject());
    }

    function forceRedetectFileSearchBackend(announce, callback) {
        var shouldAnnounce = announce === true;
        if (fileIndexProc.running)
            fileIndexProc.running = false;
        fileSearchBackend = "";
        fileSearchBackendResolvedAt = 0;
        fileIndexItems = [];
        fileIndexReady = false;
        fileIndexBuilding = false;
        fileIndexBuiltAt = 0;
        depChecker.invalidateCommandAvailability("fd");
        depChecker.invalidateCommandAvailability("find");
        resolveFileSearchBackend(function (backend) {
            if (shouldAnnounce)
                showTransientNotice("Files backend re-detected: " + backend, 2600);
            if (callback)
                callback(backend);
        });
    }

    function diagnosticReset() {
        clearLauncherMetrics();
        clearCaches();
        diagnosticSetViewport(0, 0);
        forceRedetectFileSearchBackend(true, function (_) {});
        showTransientNotice("Launcher diagnostics reset", 2200);
    }

    function loadFiles() {
        var searchQuery = searchText.startsWith("/") ? searchText.substring(1).trim() : searchText;
        if (searchQuery.length < Config.launcherFileMinQueryLength) {
            allItems = [];
            filterItems();
            completeModeLoad("files", true, "");
            return;
        }
        var cacheKey = String(searchQuery).toLowerCase();
        var startedAt = Date.now();
        var homeDir = Quickshell.env("HOME") || "/";
        var maxResults = Math.max(20, Config.launcherFileMaxResults);

        // Fast path: index already loaded — filter in-memory, skip backend resolution
        if (fileIndexReady && fileIndexItems.length > 0) {
            allItems = fileIndexItems;
            var cachedItems = getFileQueryCached(cacheKey);
            if (cachedItems) {
                filteredItems = decorateResultSections(cachedItems.slice(0, Config.launcherMaxResults));
                selectedIndex = Math.min(selectedIndex, Math.max(0, filteredItems.length - 1));
                completeModeLoad("files", true, fileIndexBuilding ? "Refreshing index in background" : "");
                recordLoadMetric("files", 0, true, true);
                return;
            }
            filterItems();
            setFileQueryCached(cacheKey, filteredItems.slice());
            completeModeLoad("files", true, fileIndexBuilding ? "Refreshing index in background" : "");
            recordLoadMetric("files", Date.now() - startedAt, false, true);
            if (fileIndexStale() && !fileIndexBuilding)
                buildFileIndex(homeDir);
            return;
        }

        var token = beginRequest("files");
        beginModeLoad("files", "Searching files");
        resolveFileSearchBackend(function (backend) {
            if (!isRequestCurrent("files", token))
                return;
            if (backend === "none") {
                setModeHint("Dependency missing", "Install 'fd' or 'find' to use Files mode.", "󰋼");
                completeModeLoad("files", false, "Missing files backend");
                recordLoadMetric("files", Date.now() - startedAt, false, false);
                return;
            }

            if (backend === "fd") {
                if (fileIndexStale() && !fileIndexBuilding)
                    buildFileIndex(homeDir);

                if (fileIndexItems.length > 0) {
                    allItems = fileIndexItems;
                    filterItems();
                    setFileQueryCached(cacheKey, filteredItems.slice());
                    completeModeLoad("files", true, fileIndexBuilding ? "Refreshing index in background" : "");
                    recordLoadMetric("files", Date.now() - startedAt, false, true);
                    return;
                }

                runCommand(["fd", "--base-directory", homeDir, "--max-results", String(maxResults), searchQuery], function (raw) {
                    if (!isRequestCurrent("files", token))
                        return;
                    var tookMs = Date.now() - startedAt;
                    recordFilesBackendLoad("fd", tookMs);
                    var items = FileParser.buildFileItemsFromRaw(raw, homeDir);
                    allItems = items;
                    setFileQueryCached(cacheKey, items);
                    filterItems();
                    completeModeLoad("files", true, fileIndexBuilding ? "Indexing in background" : "");
                    recordLoadMetric("files", tookMs, false, true);
                });
                return;
            }

            runCommand(["find", homeDir, "-mindepth", "1", "-maxdepth", "6", "-iname", "*" + searchQuery + "*"], function (raw) {
                if (!isRequestCurrent("files", token))
                    return;
                var tookMs = Date.now() - startedAt;
                recordFilesBackendLoad("find", tookMs);
                var lines = raw ? raw.split("\n") : [];
                if (lines.length > maxResults) lines.length = maxResults;
                var items = FileParser.buildFileItemsFromRaw(lines.join("\n"), homeDir);
                allItems = items;
                setFileQueryCached(cacheKey, items);
                filterItems();
                completeModeLoad("files", true, "");
                recordLoadMetric("files", tookMs, false, true);
            }, function (_errorText, _exitCode, _exitStatus) {
                if (!isRequestCurrent("files", token))
                    return;
                completeModeLoad("files", false, "File search failed");
                recordLoadMetric("files", Date.now() - startedAt, false, false);
            });
        });
    }

    function loadAi() {
        var query = searchText.startsWith("!") ? searchText.substring(1).trim() : searchText;
        if (query.length < 3) {
            allItems = [];
            filterItems();
            completeModeLoad("ai", true, "");
            return;
        }
        allItems = [];
        beginModeLoad("ai", "Thinking");
        filterItems();
        var token = beginRequest("ai");
        var startedAt = Date.now();
        runCommand(DependencyService.resolveCommand("qs-ai", [query]), function (raw) {
            if (!isRequestCurrent("ai", token))
                return;
            raw = raw.trim();
            if (raw)
                allItems = [
                    {
                        name: "AI Response",
                        title: "Click to copy response",
                        body: raw,
                        icon: "󰚩"
                    }
                ];
            else
                allItems = [];
            filterItems();
            completeModeLoad("ai", true, "");
            recordLoadMetric("ai", Date.now() - startedAt, false, true);
        }, function (_errorText, _exitCode, _exitStatus) {
            if (!isRequestCurrent("ai", token))
                return;
            allItems = [];
            filterItems();
            completeModeLoad("ai", false, "AI helper failed");
            recordLoadMetric("ai", Date.now() - startedAt, false, false);
        });
    }

    function loadWeb() {
        allItems = configuredWebProviders();
        filterItems();
        completeModeLoad("web", true, "");
        applyRememberedWebProviderSelection();
    }

    function loadPlugins() {
        allItems = PluginService.queryLauncherItems(searchText, true);
        filterItems();
        completeModeLoad("plugins", true, "");
    }

    function loadSettings() {
        var items = [];
        var tabs = SettingsRegistry.tabs;
        for (var i = 0; i < tabs.length; i++) {
            var tab = tabs[i];
            items.push({
                category: "Settings",
                name: tab.label,
                icon: tab.icon || "󰒓",
                action: (function (tId) {
                        return function () {
                            Quickshell.execDetached(["quickshell", "ipc", "call", "SettingsHub", "openTab", tId]);
                            close();
                        };
                    })(tab.id),
                _keywords: (tab.searchTerms || []).join(" ")
            });
        }
        allItems = items;
        filterItems();
        completeModeLoad("settings", true, "");
    }

    function loadDevOps() {
        allItems = SystemItems.buildDevOpsItems({
            dockerContainers: ServiceUnitService.dockerContainers,
            sshSessions: ServiceUnitService.sshSessions,
            userUnits: ServiceUnitService.userUnits,
            runDockerAction: function(id, op) { ServiceUnitService.runDockerAction(id, op); },
            restartUnit: function(scope, name) { ServiceUnitService.restartUnit(scope, name); },
            close: close
        });
        filterItems();
        completeModeLoad("devops", true, "");
    }

    function loadOrchestrator() {
        allItems = [];
        filterItems();
        completeModeLoad("orchestrator", true, "");
    }

    function loadSystem() {
        allItems = SystemItems.buildSystemItems({
            sessionActions: SystemActionRegistry.sessionActions,
            shellEntryActions: SystemActionRegistry.shellEntryActions,
            makeConfirmedSystemAction: makeConfirmedSystemAction,
            makeDetachedSystemAction: makeDetachedSystemAction,
            execDetached: function(cmd) { Quickshell.execDetached(cmd); },
            resolveCommand: function(name, args) { return DependencyService.resolveCommand(name, args); },
            launchInTerminal: launchInTerminal,
            defaultAdapter: Bluetooth.defaultAdapter
        });
        filterItems();
        completeModeLoad("system", true, "");
    }

    function loadNixos() {
        NixOS.refresh();
        allItems = SystemItems.buildNixosItems({
            launchInTerminal: launchInTerminal,
            close: close,
            generations: NixOS.generations,
            rollbackTo: function(id) { NixOS.rollbackTo(id); }
        });
        filterItems();
        completeModeLoad("nixos", true, "");
    }

    function loadWindows() {
        var items = [];
        try {
            for (var i = 0; i < availableToplevels.length; i++) {
                var win = availableToplevels[i];
                if (!win)
                    continue;
                var appId = CompositorAdapter.windowAppId(win);
                var title = CompositorAdapter.windowTitle(win);
                var address = CompositorAdapter.windowIdentifier(win);
                items.push({
                    name: title || appId || "Window",
                    title: title || "",
                    appId: appId,
                    icon: appId || "",
                    address: address,
                    toplevel: win
                });
            }
        } catch (e) {
            console.error("Error loading windows: " + e);
        }
        allItems = items;
        filterItems();
        completeModeLoad("window", true, "");
    }

    readonly property var _rankWeights: ({
        name: Config.launcherScoreNameWeight,
        title: Config.launcherScoreTitleWeight,
        exec: Config.launcherScoreExecWeight,
        body: Config.launcherScoreBodyWeight,
        category: Config.launcherScoreCategoryWeight
    })

    function _startChunkedFilter(sourceItems, clean, cleanLower, filesScanCap, startedAt) {
        _filterChunkToken++;
        _filterChunkState = {
            token: _filterChunkToken,
            sourceItems: sourceItems,
            clean: clean,
            cleanLower: cleanLower,
            filesScanCap: filesScanCap,
            startedAt: startedAt,
            scoredItems: [],
            idx: 0
        };
        _filterChunking = true;
        filterChunkTimer.restart();
    }

    function _processFilterChunk() {
        var state = _filterChunkState;
        if (!state || state.token !== _filterChunkToken)
            return;
        var chunkSize = 2000;
        var end = Math.min(state.idx + chunkSize, state.sourceItems.length);
        for (var i = state.idx; i < end; i++) {
            var item = state.sourceItems[i];
            var bestScore = Search.rankItem(item, state.clean, state.cleanLower, mode, _rankWeights);
            if (bestScore > 0 || state.clean === "") {
                item._score = bestScore;
                state.scoredItems.push(item);
                if (state.filesScanCap > 0 && state.scoredItems.length >= state.filesScanCap)
                    break;
            }
        }
        state.idx = end;
        var done = state.idx >= state.sourceItems.length
            || (state.filesScanCap > 0 && state.scoredItems.length >= state.filesScanCap);
        if (state.token !== _filterChunkToken)
            return;
        if (done) {
            state.scoredItems.sort(Search.compareByScoreThenDepth);
            _lastFilterMode = mode;
            _lastFilterQuery = state.cleanLower;
            _lastFilterCategory = drunCategoryFilter;
            _lastFilterCandidates = state.scoredItems.slice();
            filteredItems = decorateResultSections(state.scoredItems.slice(0, Config.launcherMaxResults));
            selectedIndex = Math.min(selectedIndex, Math.max(0, filteredItems.length - 1));
            _filterChunking = false;
            _filterChunkState = null;
            recordFilterMetric(Date.now() - state.startedAt);
        } else {
            // Progressive partial results after first chunk
            if (state.scoredItems.length > 0) {
                var partial = state.scoredItems.slice();
                partial.sort(Search.compareByScoreOnly);
                filteredItems = decorateResultSections(partial.slice(0, Config.launcherMaxResults));
                selectedIndex = Math.min(selectedIndex, Math.max(0, filteredItems.length - 1));
            }
            filterChunkTimer.restart();
        }
    }

    function _cancelChunkedFilter() {
        _filterChunkToken++;
        filterChunkTimer.stop();
        _filterChunking = false;
        _filterChunkState = null;
    }

    function filterItems() {
        if (_filterChunking)
            _cancelChunkedFilter();
        var startedAt = Date.now();
        var actualSearch = searchText;
        var webContext = null;
        if (mode === "calc") {
            actualSearch = searchText.startsWith("=") ? searchText.substring(1).trim() : searchText;
            try {
                if (actualSearch !== "") {
                    var result = Search.safeCalcEval(actualSearch);
                    if (result !== undefined && !isNaN(result)) {
                        filteredItems = [
                            {
                                name: result.toString(),
                                title: "Result: " + result,
                                isCalc: true
                            }
                        ];
                        selectedIndex = 0;
                        recordFilterMetric(Date.now() - startedAt);
                        return;
                    }
                }
            } catch (e) {}
            filteredItems = [];
            recordFilterMetric(Date.now() - startedAt);
            return;
        }

        if (mode === "plugins") {
            filteredItems = decorateResultSections(allItems.slice(0, Config.launcherMaxResults));
            selectedIndex = Math.min(selectedIndex, Math.max(0, filteredItems.length - 1));
            recordFilterMetric(Date.now() - startedAt);
            return;
        }

        if (mode === "web") {
            webContext = parseWebQuery(searchText);
            actualSearch = webContext.query;
        } else {
            actualSearch = Search.stripSearchPrefix(mode, searchText);
        }

        var clean = String(actualSearch || "");
        var cleanLower = clean.toLowerCase();
        var canReusePreviousCandidates = (mode === "drun" || mode === "files")
                && cleanLower !== ""
                && _lastFilterMode === mode
                && (mode !== "drun" || _lastFilterCategory === drunCategoryFilter)
                && _lastFilterQuery !== ""
                && cleanLower.indexOf(_lastFilterQuery) === 0;
        var sourceItems = canReusePreviousCandidates ? _lastFilterCandidates : allItems;

        if (clean === "" && mode !== "files" && mode !== "ai") {
            resetFilterCache();
            var baseItems = [];
            for (var j = 0; j < allItems.length; ++j) {
                var item = allItems[j];
                if (mode === "drun" && drunCategoryFilter !== "" && !itemMatchesDrunCategory(item, drunCategoryFilter))
                    continue;
                if (mode === "drun")
                    item.sectionLabel = drunBrowseSectionLabel();
                baseItems.push(item);
            }
            filteredItems = decorateResultSections(baseItems);
        } else {
            var scoredItems = [];
            var filesScanCap = mode === "files" ? Math.max(200, Config.launcherMaxResults * 4) : 0;
            if (mode === "files" && cleanLower !== "" && sourceItems.length >= 5000) {
                _startChunkedFilter(sourceItems, clean, cleanLower, filesScanCap, startedAt);
                return;
            }
            for (var i = 0; i < sourceItems.length; i++) {
                var item = sourceItems[i];
                if (mode === "web") {
                    var webItem = Object.assign({}, item);
                    webItem.title = "Search " + item.name + " for '" + clean + "'";
                    webItem.query = clean;
                    scoredItems.push(webItem);
                    continue;
                }
                var bestScore = Search.rankItem(item, clean, cleanLower, mode, _rankWeights);
                if (bestScore > 0 || (clean === "" && (mode === "files" || mode === "ai"))) {
                    if (mode === "drun" && drunCategoryFilter !== "" && !itemMatchesDrunCategory(item, drunCategoryFilter))
                        continue;
                    item._score = bestScore;
                    scoredItems.push(item);
                    if (filesScanCap > 0 && scoredItems.length >= filesScanCap)
                        break;
                }
            }
            if (mode !== "web" && mode !== "ai" && mode !== "files")
                scoredItems.sort(Search.compareByScoreThenUsage);
            else if (mode === "files")
                scoredItems.sort(Search.compareByScoreThenDepth);
            else if (mode === "ai")
                scoredItems.sort(Search.compareByScoreOnly);
            _lastFilterMode = mode;
            _lastFilterQuery = cleanLower;
            _lastFilterCategory = drunCategoryFilter;
            _lastFilterCandidates = scoredItems.slice();
            filteredItems = decorateResultSections(scoredItems.slice(0, Config.launcherMaxResults));
        }
        selectedIndex = Math.min(selectedIndex, Math.max(0, filteredItems.length - 1));
        if (mode === "web" && webContext && webContext.providerKey !== "")
            selectWebProviderByKey(webContext.providerKey);
        recordFilterMetric(Date.now() - startedAt);
    }

    function scheduleSearchRefresh(forceNow) {
        if (forceNow === true) {
            applySearchRefresh(mode === "files");
            return;
        }
        if (mode === "files") {
            searchDebounceTimer.stop();
            if (Config.launcherFileSearchDebounceMs <= 50) {
                applySearchRefresh(true);
            } else {
                fileSearchDebounceTimer.restart();
            }
            return;
        }
        fileSearchDebounceTimer.stop();
        if (Config.launcherSearchDebounceMs <= 0 || mode === "calc") {
            applySearchRefresh(false);
            return;
        }
        searchDebounceTimer.restart();
    }

    function applySearchRefresh(isFileRefresh) {
        if (mode === "plugins") {
            loadPlugins();
            return;
        }
        if (isFileRefresh === true || mode === "files") {
            loadFiles();
            return;
        }
        filterItems();
    }

    function copyToClipboard(text) {
        Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | wl-copy", "sh", text]);
    }

    function restoreClipboardHistoryItem(id) {
        ClipboardHistoryService.restore(id);
    }

    function launchInTerminal(cmd) {
        if (cmd && String(cmd).trim() !== "") {
            Quickshell.execDetached(SU.terminalCommand(cmd));
        } else {
            Quickshell.execDetached(["sh", "-c",
                "for t in ghostty kitty foot alacritty wezterm; do " +
                "if command -v $t >/dev/null 2>&1; then exec $t; fi; done"]);
        }
    }

    function launchExecString(execString, runInTerminal) {
        if (!execString || String(execString).trim() === "")
            return;
        if (runInTerminal) {
            launchInTerminal(execString);
            return;
        }
        Quickshell.execDetached(["bash", "-lc", String(execString)]);
    }

    function executeEmptyPrimary() {
        var clean = ModeData.stripModePrefix(searchText).trim();
        Executor.executeEmptyPrimary(mode, clean, searchText, {
            open: open,
            close: close,
            loadAi: loadAi,
            launchExecString: launchExecString,
            execDetached: Quickshell.execDetached,
            parseWebQuery: parseWebQuery,
            configuredWebProviderByKey: configuredWebProviderByKey,
            primaryWebProvider: primaryWebProvider,
            homeDir: Quickshell.env("HOME") || "/"
        });
    }

    function executeEmptySecondary() {
        var clean = ModeData.stripModePrefix(searchText).trim();
        Executor.executeEmptySecondary(mode, clean, {
            close: close,
            clearSearchQuery: clearSearchQuery,
            launchInTerminal: launchInTerminal,
            launchExecString: launchExecString,
            runShellEntryAction: runShellEntryAction,
            execDetached: Quickshell.execDetached,
            secondaryWebProvider: secondaryWebProvider,
            homeDir: Quickshell.env("HOME") || "/"
        });
    }

    function clearSearchQuery() {
        searchText = "";
        if (searchInputComp.searchInput)
            searchInputComp.searchInput.text = "";
        filterItems();
        if (searchInputComp.searchInput)
            searchInputComp.searchInput.forceActiveFocus();
    }

    function handleEscapeAction() {
        if (showingConfirm) {
            cancelConfirm();
            return true;
        }
        if (searchText !== "") {
            clearSearchQuery();
            return true;
        }
        if (drunCategoryFiltersEnabled && mode === "drun" && drunCategoryFilter !== "") {
            return setDrunCategoryFilter("");
        }
        if (drunCategoryFiltersEnabled && mode === "drun" && drunCategorySectionExpanded) {
            drunCategorySectionExpanded = false;
            return true;
        }
        close();
        return true;
    }

    function cycleSelection(step) {
        if (filteredItems.length <= 0)
            return;
        var next = (selectedIndex + step + filteredItems.length) % filteredItems.length;
        selectedIndex = next;
    }

    function moveSelectionRelative(step) {
        if (filteredItems.length <= 0)
            return false;
        var next = Math.max(0, Math.min(filteredItems.length - 1, selectedIndex + step));
        if (next === selectedIndex)
            return false;
        selectedIndex = next;
        return true;
    }

    function jumpSelectionBoundary(toEnd) {
        if (filteredItems.length <= 0)
            return false;
        selectedIndex = toEnd ? (filteredItems.length - 1) : 0;
        return true;
    }

    function pageSelection(step) {
        if (filteredItems.length <= 0)
            return false;
        var pageSize = Math.max(5, Math.min(12, Math.round(hudBox.height / 72)));
        var next = Math.max(0, Math.min(filteredItems.length - 1, selectedIndex + (step * pageSize)));
        if (next === selectedIndex)
            return false;
        selectedIndex = next;
        return true;
    }

    function selectWebProviderByKey(providerKey) {
        if (mode !== "web" || providerKey === "")
            return;
        for (var i = 0; i < filteredItems.length; ++i) {
            if (String(filteredItems[i].key || "") === providerKey) {
                selectedIndex = i;
                return;
            }
        }
    }

    function webProviderSlotFromKey(key) {
        var slot = key - Qt.Key_0;
        return (slot >= 1 && slot <= 9) ? slot : 0;
    }

    function selectWebProviderBySlot(slot) {
        if (mode !== "web" || slot < 1)
            return false;
        var providers = configuredWebProviders();
        if (slot > providers.length)
            return false;
        var key = String((providers[slot - 1] || {}).key || "");
        if (key === "")
            return false;
        selectWebProviderByKey(key);
        return true;
    }

    function executeWebProviderBySlot(slot) {
        if (mode !== "web" || slot < 1)
            return false;
        var providers = configuredWebProviders();
        if (slot > providers.length)
            return false;
        var provider = providers[slot - 1];
        if (!provider)
            return false;
        var webCtx = parseWebQuery(searchText);
        var query = String(webCtx.query || "");
        var target = "";
        if (query !== "" && provider.exec)
            target = String(provider.exec) + encodeURIComponent(query);
        else
            target = String(provider.home || provider.exec || "");
        if (target === "")
            return false;
        rememberRecent({
            name: provider.name || "Web",
            title: target,
            icon: provider.icon || "󰖟",
            exec: String(provider.exec || "")
        });
        Quickshell.execDetached(["xdg-open", target]);
        close();
        return true;
    }

    function openSelectedWebHomepage() {
        if (mode !== "web" || filteredItems.length <= 0 || selectedIndex < 0 || selectedIndex >= filteredItems.length)
            return;
        var item = filteredItems[selectedIndex];
        var home = String(item.home || "");
        if (home === "") {
            var exec = String(item.exec || "");
            var qIndex = exec.indexOf("?");
            home = qIndex >= 0 ? exec.substring(0, qIndex) : exec;
            if (home !== "" && home.charAt(home.length - 1) !== "/")
                home += "/";
        }
        if (home !== "") {
            Quickshell.execDetached(["xdg-open", home]);
            close();
        }
    }

    function executePrimaryWebSearch() {
        if (mode !== "web")
            return;
        var webCtx = parseWebQuery(searchText);
        var provider = configuredWebProviderByKey(webCtx.providerKey) || primaryWebProvider();
        if (!provider)
            return;
        var clean = webCtx.query;
        var target = "";
        if (clean !== "" && provider.exec)
            target = String(provider.exec) + encodeURIComponent(clean);
        else
            target = String(provider.home || provider.exec || "");
        if (target === "")
            return;
        rememberRecent({
            name: provider.name || "Web",
            title: target,
            icon: provider.icon || "󰖟",
            exec: String(provider.exec || "")
        });
        Quickshell.execDetached(["xdg-open", target]);
        close();
    }

    function activateHomeItem(item) {
        if (item.openMode) {
            open(item.openMode);
            return;
        }
        if (item.ipcTarget && item.ipcAction) {
            Quickshell.execDetached(["quickshell", "ipc", "call", item.ipcTarget, item.ipcAction]);
            close();
            return;
        }
        if (mode === "drun" && item && item.exec) {
            trackLaunch(item);
            launchExecString(item.exec, item.terminal === "true" || item.terminal === "True");
            close();
            return;
        }
        if (item.action)
            item.action();
    }

    function executeSelection() {
        if (filteredItems.length === 0 || selectedIndex < 0 || selectedIndex >= filteredItems.length)
            return;
        var item = filteredItems[selectedIndex];
        Executor.executeSelection(mode, item, {
            trackLaunch: trackLaunch,
            launchExecString: launchExecString,
            close: close,
            rememberRecent: rememberRecent,
            copyToClipboard: copyToClipboard,
            restoreClipboardHistoryItem: restoreClipboardHistoryItem,
            execDetached: Quickshell.execDetached,
            supportsDispatcherActions: CompositorAdapter.supportsDispatcherActions,
            dispatchAction: CompositorAdapter.dispatchAction,
            executeLauncherItem: PluginService.executeLauncherItem,
            showingConfirm: showingConfirm,
            searchText: searchText
        });
    }

    function handleSearchAccepted(modifiers) {
        var activeModifiers = modifiers || Qt.NoModifier;
        if ((activeModifiers & Qt.ControlModifier) && mode === "web" && filteredItems.length > 0) {
            openSelectedWebHomepage();
        } else if (mode === "web" && filteredItems.length > 0 && !(activeModifiers & Qt.ShiftModifier) && Config.launcherWebEnterUsesPrimary) {
            executePrimaryWebSearch();
        } else if ((activeModifiers & Qt.ShiftModifier) && filteredItems.length === 0 && emptySecondaryCta !== "") {
            executeEmptySecondary();
        } else if (mode === "ai" && filteredItems.length === 0) {
            loadAi();
        } else if (mode === "files" && ModeData.stripModePrefix(searchText).trim().length >= Config.launcherFileMinQueryLength && filteredItems.length === 0) {
            loadFiles();
        } else if (filteredItems.length === 0) {
            executeEmptyPrimary();
        } else {
            executeSelection();
        }
    }

    IpcHandler {
        target: "Launcher"
        function openDrun() {
            launcherRoot.open("drun");
        }
        function openWindow() {
            launcherRoot.open("window");
        }
        function openRun() {
            launcherRoot.open("run");
        }
        function openEmoji() {
            launcherRoot.open("emoji");
        }
        function openCalc() {
            launcherRoot.open("calc");
        }
        function openClip() {
            launcherRoot.open("clip");
        }
        function openWeb() {
            launcherRoot.open("web");
        }
        function openPlugins() {
            launcherRoot.open("plugins");
        }
        function openSystem() {
            launcherRoot.open("system");
        }
        function openNixos() {
            launcherRoot.open("nixos");
        }
        function openMedia() {
            launcherRoot.open("media");
        }
        function openWallpapers() {
            launcherRoot.open("wallpapers");
        }
        function openKeybinds() {
            launcherRoot.open("keybinds");
        }
        function openBookmarks() {
            launcherRoot.open("bookmarks");
        }
        function openAi() {
            launcherRoot.open("ai");
        }
        function openFiles() {
            launcherRoot.open("files");
        }
        function openDmenu(itemsJson: string) {
            var items = [];
            try {
                items = JSON.parse(itemsJson);
            } catch (err) {}
            launcherRoot.mode = "dmenu";
            launcherRoot.allItems = items.map(function (it) {
                return {
                    name: it,
                    title: it
                };
            });
            launcherRoot.open("dmenu");
        }
        function clearMetrics() {
            launcherRoot.clearLauncherMetrics();
        }
        function redetectFilesBackend() {
            launcherRoot.forceRedetectFileSearchBackend(true, function (_) {});
        }
        function diagnosticReset() {
            launcherRoot.diagnosticReset();
        }
        function filesBackendStatus(): string {
            return JSON.stringify(launcherRoot.filesBackendStatusObject());
        }
        function drunCategoryState(): string {
            return JSON.stringify(launcherRoot.drunCategoryStateObject());
        }
        function escapeActionState(): string {
            return JSON.stringify(launcherRoot.escapeActionStateObject());
        }
        function launcherState(): string {
            return JSON.stringify(launcherRoot.launcherStateObject());
        }
        function diagnosticSetSearchText(text: string): string {
            return launcherRoot.diagnosticSetSearchText(text);
        }
        function diagnosticSetDrunCategoryFilter(categoryKey: string): string {
            return launcherRoot.diagnosticSetDrunCategoryFilter(categoryKey);
        }
        function diagnosticSetViewport(widthValue: real, heightValue: real): string {
            return launcherRoot.diagnosticSetViewport(widthValue, heightValue);
        }
        function invokeEscapeAction(): string {
            var action = launcherRoot.escapeActionStateObject().action;
            var handled = launcherRoot.handleEscapeAction();
            return JSON.stringify({
                handled: handled === true,
                action: action,
                state: launcherRoot.escapeActionStateObject()
            });
        }
        function toggle() {
            if (launcherRoot.launcherOpacity > 0)
                launcherRoot.close();
            else
                launcherRoot.open(launcherRoot.effectiveDefaultMode());
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Colors.withAlpha(Colors.background, 0.92)
        opacity: launcherOpacity
        layer.enabled: opacity > 0 && opacity < 1
        Behavior on opacity {
            NumberAnimation {
                duration: Colors.durationNormal
                easing.type: Easing.OutCubic
            }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: launcherRoot.close()
        }
    }

    Rectangle {
        id: hudBox
        width: Math.min(1120, Math.max(launcherRoot.sidebarCompact ? 380 : 460, launcherRoot.usableWidth - (launcherRoot.tightMode ? 24 : 40)))
        height: Math.min(980, Math.max(520, launcherRoot.usableHeight - (launcherRoot.tightMode ? 24 : 28)))
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: launcherRoot.edgeMargins.top + launcherRoot.diagnosticViewportOffsetY + Math.max(20, (launcherRoot.usableHeight - height) / 2)
        anchors.leftMargin: launcherRoot.edgeMargins.left + launcherRoot.diagnosticViewportOffsetX + Math.max(20, (launcherRoot.usableWidth - width) / 2)
        
        color: Colors.cardSurface
        radius: Colors.radiusLarge
        border.color: Colors.border
        border.width: 1
        scale: launcherRoot.scaleValue
        transform: Translate {
            y: launcherRoot.yOffset
        }
        layer.enabled: scaleValue !== 1.0 || launcherRoot.yOffset !== 0
        clip: true

        SharedWidgets.InnerHighlight { highlightOpacity: 0.15 }
        SharedWidgets.SurfaceGradient {}

        Rectangle {
            id: windowChrome
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: launcherRoot.tightMode ? 34 : 44
            radius: hudBox.radius
            color: Colors.withAlpha(Colors.surface, 0.98)
            border.color: Colors.border
            border.width: 1

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: Colors.border
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: launcherRoot.tightMode ? Colors.spacingS : Colors.spacingM
                anchors.rightMargin: launcherRoot.tightMode ? Colors.spacingS : Colors.spacingM
                spacing: launcherRoot.tightMode ? Colors.spacingXS : Colors.spacingS

                Row {
                    spacing: Colors.spacingS
                    Repeater {
                        model: [Qt.rgba(0.98, 0.36, 0.31, 0.9), Qt.rgba(0.96, 0.74, 0.28, 0.9), Qt.rgba(0.18, 0.8, 0.44, 0.9)]
                        delegate: Rectangle {
                            required property color modelData
                            width: 12
                            height: 12
                            radius: width / 2
                            color: modelData
                            opacity: 0.9
                            SharedWidgets.InnerHighlight { highlightOpacity: 0.2 }
                        }
                    }
                }

                Item { Layout.preferredWidth: Colors.spacingS }

                Text {
                    text: "Launcher"
                    color: Colors.text
                    font.pixelSize: launcherRoot.tightMode ? Colors.fontSizeSmall : Colors.fontSizeMedium
                    font.weight: Font.Black
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: Colors.letterSpacingWide
                }

                Rectangle {
                    radius: Colors.radiusPill
                    color: Colors.primaryMarked
                    border.color: Colors.withAlpha(Colors.primary, 0.35)
                    border.width: 1
                    implicitHeight: launcherRoot.tightMode ? 22 : 24
                    implicitWidth: chromeModeLabel.implicitWidth + 16

                    Text {
                        id: chromeModeLabel
                        anchors.centerIn: parent
                        text: ModeData.modeInfo(launcherRoot.mode).label
                        color: Colors.primary
                        font.pixelSize: Colors.fontSizeXXS
                        font.weight: Font.Black
                        font.capitalization: Font.AllUppercase
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    visible: !launcherRoot.tightMode
                    text: "V3.0"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXXS
                    font.weight: Font.Black
                }
            }
        }

        // Anti-flicker: track mouse movement after open to enable hover-select
        HoverHandler {
            id: hudHoverHandler
            onPointChanged: {
                if (!launcherRoot.mouseTrackingReady)
                    return;
                if (!launcherRoot.globalMouseInitialized) {
                    launcherRoot.globalLastMouseX = point.position.x;
                    launcherRoot.globalLastMouseY = point.position.y;
                    launcherRoot.globalMouseInitialized = true;
                    return;
                }
                var dx = point.position.x - launcherRoot.globalLastMouseX;
                var dy = point.position.y - launcherRoot.globalLastMouseY;
                if (Math.sqrt(dx * dx + dy * dy) >= 5) {
                    launcherRoot.ignoreMouseHover = false;
                }
            }
        }

        RowLayout {
            anchors.top: windowChrome.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: launcherRoot.tightMode ? Colors.spacingM : Colors.spacingXL
            anchors.topMargin: launcherRoot.tightMode ? Colors.spacingS : Colors.spacingM
            spacing: launcherRoot.compactMode ? Colors.paddingSmall : 18

            LauncherSidebar {
                Layout.preferredWidth: launcherRoot.sidebarCompact ? 76 : Math.max(148, Math.min(210, Math.round(hudBox.width * (launcherRoot.compactMode ? 0.2 : 0.22))))
                Layout.fillHeight: true
                launcher: launcherRoot
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: launcherRoot.compactMode ? Colors.spacingS : Colors.spacingM

                LauncherSearchField {
                    id: searchInputComp
                    Layout.fillWidth: true
                    Layout.bottomMargin: launcherRoot.tightMode ? 0 : Colors.spacingXXS
                    text: launcherRoot.searchText
                    accentColor: Colors.primary
                    placeholder: ModeData.modeInfo(launcherRoot.mode).hint || "Search..."
                    onAccepted: modifiers => launcherRoot.handleSearchAccepted(modifiers)

                    onTextChanged: {
                        if (text.startsWith("=") && launcherRoot.mode !== "calc")
                            launcherRoot.open("calc", true);
                        else if (text.startsWith(">") && launcherRoot.mode !== "run")
                            launcherRoot.open("run", true);
                        else if (text.startsWith(":") && launcherRoot.mode !== "emoji")
                            launcherRoot.open("emoji", true);
                        else if (text.startsWith("?") && launcherRoot.mode !== "web")
                            launcherRoot.open("web", true);
                        else if (text.startsWith("!") && launcherRoot.mode !== "ai")
                            launcherRoot.open("ai", true);
                        else if (text.startsWith("@") && launcherRoot.mode !== "bookmarks")
                            launcherRoot.open("bookmarks", true);
                        else if (text.startsWith("/") && launcherRoot.mode !== "files")
                            launcherRoot.open("files", true);
                        else if (text.startsWith(",") && launcherRoot.mode !== "settings")
                            launcherRoot.open("settings", true);
                        else if (PluginService.shouldOpenPluginsModeForQuery(text) && launcherRoot.mode !== "plugins")
                            launcherRoot.open("plugins", true);
                        if (launcherRoot.searchText !== text) {
                            launcherRoot.searchText = text;
                            launcherRoot.scheduleSearchRefresh(false);
                        }
                    }

                    Connections {
                        target: searchInputComp.searchInput
                        function onVisibleChanged() {
                            if (!searchInputComp.searchInput.visible && searchInputComp.searchInput.activeFocus)
                                searchInputComp.searchInput.focus = false;
                        }
                    }

                    LauncherKeyHandler {
                        id: keyHandler
                        launcher: launcherRoot
                    }

                    Keys.onPressed: event => keyHandler.handleKeyPress(event)
                }

                LauncherActionLegend {
                    visible: Config.launcherShowModeHints && !launcherRoot.tightMode
                    Layout.bottomMargin: visible ? Colors.spacingXXS : 0
                    hintText: ModeData.modeInfo(launcherRoot.mode).hint
                    primaryAction: launcherRoot.legendPrimaryAction
                    secondaryAction: launcherRoot.legendSecondaryAction
                    tertiaryAction: launcherRoot.legendTertiaryAction
                    compact: launcherRoot.compactMode || launcherRoot.webHintCompact
                }

                LauncherWebProviderBar {
                    visible: launcherRoot.mode === "web" && launcherRoot.filteredItems.length > 0
                    providers: launcherRoot.configuredWebProviders()
                    selectedKey: launcherRoot.selectedWebProviderKey
                    onProviderSelected: key => launcherRoot.selectWebProviderByKey(key)
                }

                LauncherWebHints {
                    visible: Config.launcherShowModeHints && launcherRoot.mode === "web" && !launcherRoot.tightMode
                    primaryEnterHint: launcherRoot.webPrimaryEnterHint
                    secondaryEnterHint: launcherRoot.webSecondaryEnterHint
                    aliasHint: launcherRoot.webAliasHint
                    hotkeyHint: launcherRoot.webHotkeyHint
                    compact: launcherRoot.webHintCompact
                }

                Rectangle {
                    Layout.fillWidth: true
                    visible: launcherRoot.transientNoticeText !== "" && !launcherRoot.tightMode
                    color: Colors.primarySubtle
                    radius: Colors.radiusMedium
                    border.color: Colors.withAlpha(Colors.primary, 0.5)
                    border.width: 1
                    implicitHeight: transientNoticeLabel.implicitHeight + (Colors.spacingS * 2)

                    Text {
                        id: transientNoticeLabel
                        anchors.fill: parent
                        anchors.margins: Colors.spacingS
                        text: launcherRoot.transientNoticeText
                        color: Colors.primary
                        font.pixelSize: Colors.fontSizeXS
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                    }
                }

                Rectangle {
                    id: metricsBox
                    Layout.fillWidth: true
                    visible: Config.launcherShowRuntimeMetrics && !launcherRoot.tightMode
                    color: Colors.bgWidget
                    radius: Colors.radiusMedium
                    border.color: Colors.border
                    border.width: 1
                    implicitHeight: metricsLayout.implicitHeight + (Colors.spacingM * 2)

                    RowLayout {
                        id: metricsLayout
                        anchors.fill: parent
                        anchors.margins: Colors.spacingM
                        spacing: Colors.spacingM

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Colors.spacingXXS
                            Text {
                                text: "Launcher Metrics"
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeSmall
                                font.weight: Font.DemiBold
                            }
                            Text {
                                Layout.fillWidth: true
                                text: "opens " + launcherRoot.launcherMetrics.opens + " • cache " + launcherRoot.launcherMetrics.cacheHits + "/" + launcherRoot.launcherMetrics.cacheMisses + " • failures " + launcherRoot.launcherMetrics.commandFailures + " • filter avg " + (launcherRoot.launcherMetrics.avgFilterMs || 0) + "ms" + " / last " + (launcherRoot.launcherMetrics.lastFilterMs || 0) + "ms" + (launcherRoot.mode === "files" ? (" • backend " + launcherRoot.filesBackendLabel + " • fd/find " + (launcherRoot.launcherMetrics.filesFdLoads || 0) + "/" + (launcherRoot.launcherMetrics.filesFindLoads || 0) + " • fd " + (launcherRoot.launcherMetrics.filesFdAvgMs || 0) + "/" + (launcherRoot.launcherMetrics.filesFdLastMs || 0) + "ms" + " • find " + (launcherRoot.launcherMetrics.filesFindAvgMs || 0) + "/" + (launcherRoot.launcherMetrics.filesFindLastMs || 0) + "ms" + " • resolve " + (launcherRoot.launcherMetrics.filesResolveAvgMs || 0) + "/" + (launcherRoot.launcherMetrics.filesResolveLastMs || 0) + "ms") : "")
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeXS
                                wrapMode: Text.WordWrap
                            }
                            Text {
                                readonly property var modeStats: launcherRoot.modeMetric(launcherRoot.mode)
                                Layout.fillWidth: true
                                text: ModeData.modeInfo(launcherRoot.mode).label + ": avg " + modeStats.avgLoadMs + "ms" + " • last " + modeStats.lastLoadMs + "ms" + " • failures " + modeStats.failures + (launcherRoot.mode === "files" ? (" • cache " + launcherRoot.filesCacheStatsLabel) : "")
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeXS
                                wrapMode: Text.WordWrap
                            }
                        }

                        Rectangle {
                            radius: Colors.radiusPill
                            color: Colors.surface
                            border.color: Colors.border
                            border.width: 1
                            implicitHeight: 28
                            implicitWidth: metricResetText.implicitWidth + 18

                            Text {
                                id: metricResetText
                                anchors.centerIn: parent
                                text: "Reset"
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeXS
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: launcherRoot.clearLauncherMetrics()
                            }
                        }
                    }
                }

                LauncherHome {
                    Layout.fillWidth: true
                    launcher: launcherRoot
                    visible: launcherRoot.showLauncherHomePanel && !launcherRoot.isModeLoading
                    showHomeSections: false
                }

                OrchestratorView {
                    visible: launcherRoot.mode === "orchestrator" && launcherRoot.searchText === ""
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: mode === "media" ? 1 : 0

                    StackLayout {
                        currentIndex: launcherRoot.filteredItems.length > 0 ? 0 : (launcherRoot.isModeLoading ? 1 : 2)

                        ListView {
                            id: resultsList
                            model: launcherRoot.filteredItems
                            clip: true
                            spacing: launcherRoot.compactMode ? Colors.spacingXS : Colors.spacingS
                            currentIndex: launcherRoot.selectedIndex
                            enabled: !launcherRoot.showingConfirm
                            topMargin: launcherRoot.compactMode ? Colors.spacingXXS : Colors.spacingXS
                            section.property: "sectionLabel"
                            section.delegate: Item {
                                width: resultsList.width
                                height: launcherRoot.compactMode ? 26 : 30

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.topMargin: launcherRoot.compactMode ? Colors.spacingXXS : Colors.spacingXS
                                    spacing: launcherRoot.compactMode ? Colors.spacingXS : Colors.spacingS

                                    Rectangle {
                                        radius: Colors.radiusPill
                                        color: Colors.primarySubtle
                                        border.color: Colors.primaryMarked
                                        border.width: 1
                                        implicitHeight: launcherRoot.compactMode ? 18 : 20
                                        implicitWidth: sectionHeaderLabel.implicitWidth + (launcherRoot.compactMode ? 12 : 14)

                                        SharedWidgets.SectionLabel {
                                            id: sectionHeaderLabel
                                            anchors.centerIn: parent
                                            label: section
                                            color: Colors.primary
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        implicitHeight: 1
                                        radius: Colors.radiusXXXS
                                        color: Colors.withAlpha(Colors.border, 0.9)
                                    }
                                }
                            }

                            delegate: LauncherResultDelegate {
                                itemData: modelData
                                itemIndex: index
                                selectedIndex: launcherRoot.selectedIndex
                                searchText: launcherRoot.searchText
                                mode: launcherRoot.mode
                                compactMode: launcherRoot.compactMode
                                tightMode: launcherRoot.tightMode
                                ignoreMouseHover: launcherRoot.ignoreMouseHover
                                modeIcons: launcherRoot.modeIcons
                                iconMap: launcherRoot.launcherIconMap
                                onClicked: launcherRoot.executeSelection()
                                onEntered: if (!launcherRoot.ignoreMouseHover)
                                    launcherRoot.selectedIndex = index
                            }
                        }

                        Rectangle {
                            color: Colors.bgWidget
                            radius: Colors.radiusMedium
                            border.color: Colors.border
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: Colors.spacingS

                                SharedWidgets.LoadingSpinner {
                                    Layout.alignment: Qt.AlignHCenter
                                    size: launcherRoot.compactMode ? 18 : 24
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: launcherRoot.modeLoadMessage !== "" ? launcherRoot.modeLoadMessage : ("Loading " + ModeData.modeInfo(launcherRoot.mode).label)
                                    color: Colors.text
                                    font.pixelSize: Colors.fontSizeSmall
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "Please wait"
                                    color: Colors.textSecondary
                                    font.pixelSize: Colors.fontSizeXS
                                }
                            }
                        }

                        LauncherEmptyState {
                            icon: launcherRoot.modeIcons[launcherRoot.mode] || "󰈔"
                            title: launcherRoot.emptyStateTitle
                            subtitle: launcherRoot.emptyStateSubtitle
                            primaryCta: launcherRoot.emptyPrimaryCta
                            secondaryCta: launcherRoot.emptySecondaryCta
                            primaryHint: launcherRoot.emptyPrimaryHint
                            primaryHintIcon: launcherRoot.emptyPrimaryHintIcon
                            secondaryHint: launcherRoot.emptySecondaryHint
                            secondaryHintIcon: launcherRoot.emptySecondaryHintIcon
                            onPrimaryClicked: launcherRoot.executeEmptyPrimary()
                            onSecondaryClicked: launcherRoot.executeEmptySecondary()
                        }
                    }

                    LauncherMediaView {
                        mediaPlayers: launcherRoot.mediaPlayers
                        compactMode: launcherRoot.compactMode
                        tightMode: launcherRoot.tightMode
                    }
                }
            }
        }

        LauncherConfirmDialog {
            anchors.fill: parent
            showingConfirm: launcherRoot.showingConfirm
            confirmTitle: launcherRoot.confirmTitle
            onConfirmed: launcherRoot.doConfirm()
            onCancelled: launcherRoot.cancelConfirm()
        }
    }
}
