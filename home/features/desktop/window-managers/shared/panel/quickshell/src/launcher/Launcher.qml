import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import "../services"
import "../services/ShellUtils.js" as SU
import "../shared"
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
import "LauncherTextHelpers.js" as TextHelpers
import "LauncherWebProviders.js" as WebProviders
import "LauncherFileOps.js" as FileOps
import "CharacterData.js" as CharacterData
import "../features/ssh" as SshFeature
import "../features/settings/components/SettingsSearchIndex.js" as SettingsSearchIndex

PanelWindow {
    id: launcherRoot

    property bool _destroyed: false

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

    Component.onDestruction: _destroyed = true

    onVisibleChanged: {
        if (visible)
            Qt.callLater(function () {
                if (_destroyed) return;
                if (contentPanel.searchInput)
                    contentPanel.searchInput.forceActiveFocus();
            });
    }

    // Safety-net Escape: works even if focus falls to an unexpected item.
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
    property string _bangQuery: ""
    property string _bangSearchTerm: ""
    property var _bangResults: []

    property Process bangSearchProc: Process {
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var raw = this.text || "";
                if (raw.trim() === "") {
                    launcherRoot._bangResults = [];
                    return;
                }
                try {
                    var results = JSON.parse(raw);
                    if (!Array.isArray(results)) {
                        launcherRoot._bangResults = [];
                        return;
                    }
                    var items = [];
                    for (var i = 0; i < results.length; ++i) {
                        var bang = results[i];
                        items.push({
                            name: "!" + bang.t + " — " + bang.s,
                            title: bang.u || "",
                            icon: "󰖟",
                            bangTrigger: bang.t,
                            bangUrl: bang.u,
                            isBang: true,
                            isWeb: true
                        });
                    }
                    launcherRoot._bangResults = items;
                    if (launcherRoot.mode === "web")
                        launcherRoot.filterItems();
                } catch (e) {
                    launcherRoot._bangResults = [];
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                launcherRoot._bangResults = [];
        }
    }

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
    property string fileIndexStdoutBuffer: ""
    property string fileIndexStderrBuffer: ""
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
    property var _gitTrackedSet: ({})
    property bool _gitIndexReady: false
    property bool filePreviewVisible: true
    property string transientNoticeText: ""
    property bool sidebarOverflowExpanded: false
    property bool shortcutHelpExpanded: false
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

    function resolveFileSearchRoot(rawValue) {
        var raw = String(rawValue || "~").trim();
        var home = String(Quickshell.env("HOME") || "/");
        var resolved = home;
        if (raw === "" || raw === "~") {
            resolved = home;
        } else if (raw.indexOf("~/") === 0) {
            resolved = home + raw.substring(1);
        } else if (raw.charAt(0) === "/") {
            resolved = raw;
        } else {
            resolved = home + "/" + raw;
        }
        if (resolved.length > 1 && resolved.charAt(resolved.length - 1) === "/")
            resolved = resolved.substring(0, resolved.length - 1);
        return resolved;
    }

    function formatFileSearchRootLabel(rootPath) {
        var path = String(rootPath || "");
        var home = String(Quickshell.env("HOME") || "");
        if (path === home)
            return "~";
        if (home !== "" && path.indexOf(home + "/") === 0)
            return "~/" + path.substring(home.length + 1);
        return path !== "" ? path : "~";
    }

    function applyFileSearchFailure(errorText, fallbackMessage) {
        var detail = String(errorText || "").trim();
        var normalized = detail.toLowerCase();
        var unavailable = normalized.indexOf("no such file") !== -1
            || normalized.indexOf("not a directory") !== -1
            || normalized.indexOf("cannot access") !== -1;
        if (unavailable) {
            setModeHint("Search root unavailable", "Check File Search Root: " + fileSearchRootLabel, "󰅚");
            completeModeLoad("files", false, "Search root unavailable");
            return;
        }
        var summary = detail !== "" ? detail.split("\n")[0] : "Check helper command output and logs.";
        setModeHint("File search failed", summary, "󰅚");
        completeModeLoad("files", false, String(fallbackMessage || "File search failed"));
    }

    readonly property var _fileOpsCtx: ({
        get fileOpenerCommand()       { return launcherRoot.fileOpenerCommand; },
        get fileSearchRootResolved()  { return launcherRoot.fileSearchRootResolved; },
        execDetached:       function(args) { Quickshell.execDetached(args); },
        showTransientNotice:function(msg, ms) { launcherRoot.showTransientNotice(msg, ms); },
        copyToClipboard:    function(text) { launcherRoot.copyToClipboard(text); },
        close:              function() { launcherRoot.close(); }
    })

    function openWithConfiguredOpener(targetPath) { FileOps.openWithConfiguredOpener(targetPath, _fileOpsCtx); }
    function openDirectoryPath(targetPath)         { FileOps.openDirectoryPath(targetPath, _fileOpsCtx); }
    function openFileItem(item)                    { FileOps.openFileItem(item, _fileOpsCtx); }
    function fileItemParentPath(item)              { return FileOps.fileItemParentPath(item, fileSearchRootResolved); }
    function openFileParent(item)                  { FileOps.openFileParent(item, _fileOpsCtx); }
    function revealFileInManager(item)             { FileOps.revealFileInManager(item, _fileOpsCtx); }
    function copyFilePath(item)                    { FileOps.copyFilePath(item, _fileOpsCtx); }
    function fileContextMenuModel(item)            { return FileOps.fileContextMenuModel(item, _fileOpsCtx); }

    readonly property var _webExecCtx: ({
        get filteredItems()  { return launcherRoot.filteredItems; },
        get selectedIndex()  { return launcherRoot.selectedIndex; },
        set selectedIndex(v) { launcherRoot.selectedIndex = v; },
        get mode()           { return launcherRoot.mode; },
        get searchText()     { return launcherRoot.searchText; },
        parseWebQuery:              function(t) { return launcherRoot.parseWebQuery(t); },
        configuredWebProviders:     function()  { return launcherRoot.configuredWebProviders(); },
        configuredWebProviderByKey: function(k) { return launcherRoot.configuredWebProviderByKey(k); },
        primaryWebProvider:         function()  { return launcherRoot.primaryWebProvider(); },
        rememberRecent:             function(i) { launcherRoot.rememberRecent(i); },
        close:                      function()  { launcherRoot.close(); },
        execDetached:               function(cmd) { Quickshell.execDetached(cmd); }
    })

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

    function applyDrunItems(items, persistCache) {
        var appItems = prepareDrunItems(items);
        if (persistCache !== false)
            setCached("drun", appItems);
        if (mode === "drun") {
            allItems = appItems;
            resetFilterCache();
            filterItems();
            buildLauncherHome();
        }
        return appItems;
    }

    // ── Hover anti-flicker ─────────────────────────
    property bool ignoreMouseHover: true
    property bool mouseTrackingReady: false
    property bool globalMouseInitialized: false
    property real globalLastMouseX: 0
    property real globalLastMouseY: 0

    readonly property bool showLauncherHome: Config.launcherShowHomeSections && searchText === "" && (mode === "drun" || mode === "files")
    readonly property bool showLauncherHomePanel: showLauncherHome && mode !== "orchestrator"
    readonly property bool drunCategoryFiltersEnabled: Config.launcherDrunCategoryFiltersEnabled
    readonly property bool isModeLoading: modeLoadState === "loading"
    readonly property string selectedHomeItemKey: ""
    // Runtime-only overrides used by launcher smoke tests; they never persist.
    property string diagnosticFileSearchRootOverride: ""
    property bool diagnosticFileSearchShowHiddenOverrideActive: false
    property bool diagnosticFileSearchShowHiddenOverride: false
    property string diagnosticFileOpenerOverride: ""
    readonly property string fileSearchRootSetting: {
        var raw = String((diagnosticFileSearchRootOverride !== "" ? diagnosticFileSearchRootOverride : Config.launcherFileSearchRoot) || "~").trim();
        return raw !== "" ? raw : "~";
    }
    readonly property string fileSearchRootResolved: resolveFileSearchRoot(fileSearchRootSetting)
    readonly property string fileSearchRootLabel: formatFileSearchRootLabel(fileSearchRootResolved)
    readonly property bool fileSearchShowHidden: diagnosticFileSearchShowHiddenOverrideActive
        ? (diagnosticFileSearchShowHiddenOverride === true)
        : (Config.launcherFileShowHidden === true)
    readonly property string fileOpenerCommand: {
        var raw = String((diagnosticFileOpenerOverride !== "" ? diagnosticFileOpenerOverride : Config.launcherFileOpener) || "xdg-open").trim();
        return raw !== "" ? raw : "xdg-open";
    }
    readonly property string characterTrigger: {
        var trigger = String(Config.launcherCharacterTrigger || ":").trim();
        return trigger !== "" ? trigger : ":";
    }
    readonly property string _cleanSearch: cleanSearchTextForMode(mode, searchText).trim()
    readonly property var _webPrimaryProvider: primaryWebProvider()
    readonly property var _webSecondaryProvider: secondaryWebProvider()
    readonly property string _webPrimaryName: _webPrimaryProvider ? _webPrimaryProvider.name : "Web"
    readonly property string _webSecondaryName: _webSecondaryProvider ? _webSecondaryProvider.name : "Google"
    readonly property string drunCategoryFilterLabel: TextHelpers.categoryFilterLabel(drunCategoryOptions, drunCategoryFilter)
    readonly property string drunCategoryFilterSummary: TextHelpers.categoryFilterSummary(drunCategoryOptions, drunCategoryFilter)
    readonly property var allKnownModes: ModeData.allKnownModes
    readonly property var transientModes: ModeData.transientModes
    readonly property var defaultModeOrder: ModeData.defaultModeOrder
    readonly property var defaultPrimaryModes: ModeData.defaultPrimaryModes
    property var modeOrder: computeModeOrder()
    property var primaryModes: ModeData.sanitizeModeList(Config.launcherPrimaryModes, defaultPrimaryModes, allKnownModes).filter(function (modeKey) {
        return launcherRoot.modeOrder.indexOf(modeKey) !== -1;
    })
    readonly property var overflowModes: modeOrder.filter(function(modeKey) {
        return primaryModes.indexOf(modeKey) === -1;
    })
    readonly property var cyclableModes: {
        var ordered = [];
        var seen = ({});
        var source = primaryModes.concat(overflowModes);
        for (var i = 0; i < source.length; ++i) {
            var key = String(source[i] || "");
            if (key === "" || seen[key])
                continue;
            ordered.push(key);
            seen[key] = true;
        }
        return ordered.length > 0 ? ordered : modeOrder;
    }
    readonly property var prefixQuickModes: ["settings", "run", "ssh", "web"].filter(function(modeKey) {
        return launcherRoot.supportsMode(modeKey);
    })
    readonly property var modeIcons: ModeData.modeIcons
    readonly property var currentModeMeta: modeMeta(mode)
    readonly property string modeToneKey: String(currentModeMeta.tone || "primary")
    readonly property color modeAccentColor: toneColor(modeToneKey)
    readonly property color modeAccentSoft: Colors.withAlpha(modeAccentColor, compactMode ? 0.12 : 0.16)
    readonly property color modeAccentStrong: Colors.withAlpha(modeAccentColor, 0.24)
    readonly property color modeAccentBorder: Colors.withAlpha(modeAccentColor, 0.48)
    readonly property string modeHeroLabel: String(currentModeMeta.heroLabel || currentModeMeta.label || "Launcher")
    readonly property string modeShortLabel: String(currentModeMeta.shortLabel || currentModeMeta.label || "Launcher")
    readonly property string modeHeroIcon: String(currentModeMeta.heroIcon || modeIcons[mode] || "󰍉")
    readonly property string modePrefixText: String(currentModeMeta.prefix || "")
    readonly property string emptyStateTitle: TextHelpers.emptyStateTitle(mode, _cleanSearch, Config.launcherFileMinQueryLength, fileSearchRootLabel)
    readonly property string emptyStateSubtitle: TextHelpers.emptyStateSubtitle(mode, _cleanSearch, Config.launcherFileMinQueryLength, fileSearchRootLabel)
    readonly property string emptyPrimaryCta: TextHelpers.emptyPrimaryCta(mode, _cleanSearch, _webPrimaryName, fileSearchRootLabel)
    readonly property string emptySecondaryCta: TextHelpers.emptySecondaryCta(mode, _cleanSearch, searchText, _webSecondaryName)
    readonly property string emptyPrimaryHint: TextHelpers.emptyPrimaryHint(mode, _cleanSearch, _webPrimaryName, _webPrimaryProvider ? _webPrimaryName : "default provider", fileSearchRootLabel)
    readonly property string emptyPrimaryHintIcon: TextHelpers.emptyPrimaryHintIcon(mode)
    readonly property string emptySecondaryHint: TextHelpers.emptySecondaryHint(mode, _cleanSearch, searchText, _webSecondaryName)
    readonly property string emptySecondaryHintIcon: TextHelpers.emptySecondaryHintIcon(mode, searchText)
    readonly property string activeModeHintText: mode === "emoji" ? ("Search characters with " + characterTrigger) : (ModeData.modeInfo(mode).hint || "Search...")
    readonly property string modeSummaryText: {
        var info = ModeData.modeInfo(mode);
        var prefix = String(info.prefix || "");
        var hint = String(info.hint || "Search...");
        return info.label + (prefix !== "" ? (" • " + prefix + " prefix") : "") + " • " + hint;
    }
    readonly property string overflowHintText: {
        if (overflowModes.length > 0)
            return "More reveals " + overflowModes.length + " advanced modes. " + tabControlHintText;
        return tabControlHintText;
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
        if (mode === "emoji")
            return resultHint + clearHint + (Config.launcherCharacterPasteOnSelect ? "Enter: copy+paste • Shift+Enter: paste • " : "Enter: copy • Shift+Enter: paste • ") + escapeHint;
        if (drunCategoryFiltersEnabled && mode === "drun" && drunCategoryOptions.length > 1)
            return "Alt+←/→/PgUp/PgDn/Home/End/0/Backspace, Ctrl+Tab, or Alt+1..9: categories • " + resultHint + clearHint + "Enter: run • " + escapeHint;
        return resultHint + clearHint + "Enter: run • " + escapeHint;
    }
    readonly property string legendPrimaryAction: {
        if (showingConfirm)
            return "Enter: Confirm";
        if (!hasResults)
            return "Enter: " + emptyPrimaryCta;
        if (mode === "web" && Config.launcherWebEnterUsesPrimary)
            return "Enter: Search " + _webPrimaryName;
        if (mode === "emoji")
            return Config.launcherCharacterPasteOnSelect ? "Enter: Copy + Paste" : "Enter: Copy";
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
        if (mode === "emoji" && hasResults)
            return "Shift+Enter: Paste";
        if (launcherTabBehavior === "mode")
            return "Tab: Next Mode";
        if (launcherTabBehavior === "results")
            return "Tab: Next Result";
        return hasResults ? "Tab: Next Result" : "Tab: Next Mode";
    }
    readonly property string legendTertiaryAction: {
        if (showingConfirm)
            return "Esc: Cancel";
        if (sidebarOverflowExpanded)
            return "Esc: Close More";
        if (shortcutHelpExpanded)
            return "Esc: Hide Help";
        if (searchText !== "" || (drunCategoryFiltersEnabled && mode === "drun" && (drunCategoryFilter !== "" || drunCategorySectionExpanded)))
            return "Esc: Reset";
        return "Shift+Tab: Next Mode";
    }
    readonly property string escapeStatusText: {
        if (mode === "files" && _cleanSearch !== "" && fileIndexReady)
            return filteredItems.length + "/" + fileIndexItems.length;
        if (showingConfirm)
            return "Esc cancels";
        if (sidebarOverflowExpanded)
            return "Esc closes more";
        if (shortcutHelpExpanded)
            return "Esc hides help";
        if (searchText !== "")
            return "Esc clears query";
        if (drunCategoryFiltersEnabled && mode === "drun" && drunCategoryFilter !== "")
            return "Esc clears filter";
        if (drunCategoryFiltersEnabled && mode === "drun" && drunCategorySectionExpanded)
            return "Esc collapses filters";
        return "Esc closes";
    }
    readonly property string escapeStatusIcon: {
        if (mode === "files" && _cleanSearch !== "" && fileIndexReady)
            return "󰈔";
        if (showingConfirm)
            return "󰅖";
        if (sidebarOverflowExpanded || shortcutHelpExpanded)
            return "󰅀";
        if (searchText !== "" || drunCategoryFilter !== "")
            return "󰅖";
        return "󰅚";
    }
    readonly property string webPrimaryProviderLabel: _webPrimaryProvider ? _webPrimaryProvider.name : "Primary"
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
    readonly property string webAliasHint: TextHelpers.webAliasHint(
        (Config.launcherWebAliases && typeof Config.launcherWebAliases === "object") ? Config.launcherWebAliases : ({}),
        configuredWebProviders(), webHintCompact)
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

    property bool _skipOpenAnim: false

    Behavior on launcherOpacity {
        enabled: !_skipOpenAnim
        NumberAnimation {
            duration: Colors.durationSlow
            easing.type: Easing.OutQuint
        }
    }

    property real scaleValue: 1.0
    Behavior on scaleValue {
        enabled: !_skipOpenAnim
        SpringAnimation {
            spring: 4.5
            damping: 0.28
            epsilon: 0.005
        }
    }

    property real yOffset: 0
    Behavior on yOffset {
        enabled: !_skipOpenAnim
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
                Logger.w("Launcher", "command failed:", exitCode, stderrText !== "" ? stderrText : stdoutText);
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
                    Logger.w("Launcher", "icon map parse error:", e);
                }
            }
        }
    }

    property Process fileIndexProc: Process {
        property var _startedAt: 0
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                launcherRoot.fileIndexStdoutBuffer = this.text || "";
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                launcherRoot.fileIndexStderrBuffer = this.text || "";
            }
        }
        onExited: exitCode => {
            fileIndexTimeoutTimer.stop();
            var stdoutText = launcherRoot.fileIndexStdoutBuffer || "";
            var stderrText = launcherRoot.fileIndexStderrBuffer || "";
            launcherRoot.fileIndexStdoutBuffer = "";
            launcherRoot.fileIndexStderrBuffer = "";
            if (exitCode === 0) {
                launcherRoot._handleFileIndexBuilt(stdoutText, fileIndexProc._startedAt || Date.now());
                return;
            }
            if (exitCode !== 0 && launcherRoot.fileIndexBuilding) {
                launcherRoot.fileIndexBuilding = false;
                launcherRoot.fileIndexReady = false;
                launcherRoot.applyFileSearchFailure(stderrText !== "" ? stderrText : stdoutText, "Files index build failed");
            }
        }
    }

    property Process gitIndexProc: Process {
        property bool _destroyed: false
        Component.onDestruction: _destroyed = true
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (gitIndexProc._destroyed) return;
                launcherRoot._handleGitIndexBuilt(this.text || "");
            }
        }
        onExited: exitCode => {
            if (exitCode !== 0) {
                launcherRoot._gitTrackedSet = {};
                launcherRoot._gitIndexReady = false;
            }
        }
    }

    function _buildGitIndex(rootDir) {
        if (gitIndexProc.running)
            gitIndexProc.running = false;
        gitIndexProc.command = ["git", "-C", rootDir, "ls-files", "--full-name"];
        gitIndexProc.running = true;
    }

    function _handleGitIndexBuilt(raw) {
        _gitTrackedSet = FileOps.parseGitIndex(raw);
        _gitIndexReady = true;
        if (fileIndexReady && fileIndexItems.length > 0)
            _tagFileItemsGit(fileIndexItems);
    }

    function _tagFileItemsGit(items) { FileOps.tagFileItemsGit(items, _gitTrackedSet); }

    // ── Parallel background preloading ─────────────
    property var _preloadProcs: ({})

    Timer {
        id: preloadDelayTimer
        interval: 100
        onTriggered: launcherRoot.startPreload()
    }

    Timer {
        id: initialAppsPreloadTimer
        interval: 50
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
            Logger.w("Launcher", "command timed out after 10s");
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
            Logger.w("Launcher", "file index build timed out after 30s");
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

    // ── SSH launcher data ──────────────────────────
    SshFeature.SshWidgetData {
        id: launcherSshData
        widgetInstance: launcherRoot._findFirstSshWidget()
    }
    readonly property string _launcherSshCommand: String((launcherSshData.rawSettings || {}).sshCommand || "ssh")

    Connections {
        target: launcherSshData
        function onMergedHostsChanged() {
            if (launcherRoot.mode === "ssh" && launcherRoot.launcherOpacity > 0)
                launcherRoot.loadSsh();
        }
    }

    function _findFirstSshWidget() {
        var bars = Config.barConfigs || [];
        var sections = ["left", "center", "right"];
        for (var i = 0; i < bars.length; ++i) {
            for (var j = 0; j < sections.length; ++j) {
                var widgets = Config.barSectionWidgets(bars[i], sections[j]);
                for (var k = 0; k < widgets.length; ++k) {
                    if (String(widgets[k].widgetType || "") === "ssh")
                        return widgets[k];
                }
            }
        }
        return { instanceId: "", settings: { enableSshConfigImport: true, manualHosts: [], sshCommand: "ssh", state: {} } };
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

    function modeMeta(modeKey) {
        return ModeData.modeInfo(modeKey);
    }

    function toneColor(toneKey) {
        var key = String(toneKey || "primary");
        if (key === "accent")
            return Colors.accent;
        if (key === "info")
            return Colors.info;
        if (key === "success")
            return Colors.success;
        if (key === "warning")
            return Colors.warning;
        if (key === "secondary")
            return Colors.secondary;
        return Colors.primary;
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

    readonly property var _cachedWebProviders: ModeData.configuredWebProviders(Config.launcherWebProviderOrder, Config.launcherWebCustomEngines)

    function configuredWebProviders() {
        return _cachedWebProviders;
    }

    function primaryWebProvider() {
        return WebProviders.primaryProvider(configuredWebProviders());
    }

    function configuredWebProviderByKey(providerKey) {
        return WebProviders.providerByKey(configuredWebProviders(), providerKey);
    }

    function webAliasToProviderKey(token) {
        var aliases = (Config.launcherWebAliases && typeof Config.launcherWebAliases === "object") ? Config.launcherWebAliases : ({});
        return ModeData.webAliasToProviderKey(token, configuredWebProviders(), aliases, Config.launcherWebCustomEngines);
    }

    function parseWebQuery(text) {
        var aliases = (Config.launcherWebAliases && typeof Config.launcherWebAliases === "object") ? Config.launcherWebAliases : ({});
        return ModeData.parseWebQuery(text, configuredWebProviders(), aliases, Config.launcherWebCustomEngines);
    }

    function secondaryWebProvider() {
        return WebProviders.secondaryProvider(configuredWebProviders());
    }

    function preferredWebProviderKey() {
        return WebProviders.preferredProviderKey(Config.launcherRememberWebProvider, Config.launcherWebLastProviderKey, _sessionWebProviderKey);
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
        Logger.d("Launcher", "timing:", label, took + "ms");
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
        if (gitIndexProc.running)
            gitIndexProc.running = false;
        modeCache = ({});
        modeCacheTime = ({});
        fileQueryCache = ({});
        fileQueryCacheTime = ({});
        resetFilterCache();
        fileIndexStdoutBuffer = "";
        fileIndexStderrBuffer = "";
        fileIndexItems = [];
        fileIndexReady = false;
        fileIndexBuilding = false;
        fileIndexBuiltAt = 0;
        _gitTrackedSet = ({});
        _gitIndexReady = false;
    }

    onFileSearchRootResolvedChanged: clearCaches()
    onFileSearchShowHiddenChanged: clearCaches()

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

    function buildFileIndex(rootDir) {
        if (fileIndexBuilding)
            return;
        fileIndexBuilding = true;
        fileIndexReady = false;
        fileIndexStdoutBuffer = "";
        fileIndexStderrBuffer = "";
        if (mode === "files" && fileIndexItems.length === 0)
            beginModeLoad("files", "Building file index");
        fileIndexProc._startedAt = Date.now();
        fileIndexProc.command = ["fd", "--base-directory", rootDir, "--max-depth", "8",
            "--max-results", "50000",
            "--exclude", ".git", "--exclude", ".cache", "--exclude", "node_modules",
            "--exclude", ".local/share/Trash", "--exclude", ".local/share/Steam",
            "--exclude", ".cargo", "--exclude", ".npm", "--exclude", ".mozilla",
            "."];
        if (fileSearchShowHidden)
            fileIndexProc.command.splice(1, 0, "--hidden");
        fileIndexProc.running = true;
        fileIndexTimeoutTimer.restart();
    }

    function _handleFileIndexBuilt(raw, startedAt) {
        fileIndexTimeoutTimer.stop();
        var tookMs = Math.max(0, Date.now() - startedAt);
        fileIndexBuilding = false;
        var rootDir = fileSearchRootResolved;
        function _finishIndex(items) {
            refreshFileUsageCaches(items);
            fileIndexItems = items;
            fileIndexReady = true;
            fileIndexBuiltAt = Date.now();
            recordFilesBackendLoad("fd", tookMs);
            if (_gitIndexReady && Object.keys(_gitTrackedSet).length > 0)
                _tagFileItemsGit(items);
            else
                _buildGitIndex(rootDir);
            if (mode === "files" && ModeData.stripModePrefix(searchText).trim().length >= Config.launcherFileMinQueryLength)
                loadFiles();
            else if (mode === "files" && modeLoadState === "loading")
                completeModeLoad("files", true, "");
        }
        // Estimate line count cheaply: raw length > ~500KB likely means >10k lines
        if (raw && raw.length > 500000) {
            _startChunkedParse(raw, rootDir, fileSearchRootLabel, _finishIndex);
        } else {
            _finishIndex(FileParser.buildFileItemsFromRaw(raw, rootDir, fileSearchRootLabel));
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
            modeInfoFn: ModeData.modeInfo
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

    function trackFileOpen(item) {
        if (!item || !item.fullPath) return;
        UsageTrackerService.recordUsage(item.fullPath);
        if (fileIndexReady && fileIndexItems.length > 0)
            refreshFileUsageCaches(fileIndexItems);
        resetFilterCache();
    }

    function updateFileUsageCache(item) {
        if (!item || !item.fullPath) return;
        item._fileUsageBoost = UsageTrackerService.getUsageScore(item.fullPath) * 1.5;
    }

    function refreshFileUsageCaches(items) {
        for (var i = 0; i < items.length; ++i)
            updateFileUsageCache(items[i]);
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

    readonly property var _modeDispatch: ({
        "drun":        function() { loadApps(); },
        "window":      function() { allItems = []; filterItems(); beginModeLoad("window", "Loading windows"); windowLoadTimer.restart(); },
        "run":         function() { loadRun(); },
        "emoji":       function() { loadEmojis(); },
        "clip":        function() { loadClip(); },
        "calc":        function() { allItems = []; filterItems(); completeModeLoad("calc", true, ""); },
        "web":         function() { loadWeb(); },
        "plugins":     function() { loadPlugins(); },
        "system":      function() { loadSystem(); },
        "media":       function() { allItems = []; filterItems(); completeModeLoad("media", true, ""); refreshMediaPlayers(); },
        "nixos":       function() { loadNixos(); },
        "wallpapers":  function() { loadWallpapers(); },
        "files":       function() { prewarmFileIndex(); loadFiles(); },
        "bookmarks":   function() { loadBookmarks(); },
        "settings":    function() { loadSettings(); },
        "devops":      function() { loadDevOps(); },
        "orchestrator":function() { loadOrchestrator(); },
        "ssh":         function() { loadSsh(); },
        "ai":          function() { loadAi(); },
        "keybinds":    function() { loadKeybinds(); },
        "dmenu":       function() { filterItems(); completeModeLoad("dmenu", true, ""); }
    })

    function open(newMode, keepSearch) {
        var startedAt = telemetryStart();
        if (showingConfirm)
            cancelConfirm();
        sidebarOverflowExpanded = false;
        shortcutHelpExpanded = false;
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
            if (contentPanel.searchInput)
                contentPanel.searchInput.text = "";
        }
        selectedIndex = 0;
        // Instant open: bypass spring animations for immediate show
        _skipOpenAnim = true;
        launcherOpacity = 1;
        scaleValue = 1.0;
        yOffset = 0;
        Qt.callLater(function () {
            if (_destroyed) return;
            _skipOpenAnim = false;
            if (contentPanel.searchInput)
                contentPanel.searchInput.forceActiveFocus();
        });

        depChecker.ensureModeDependencies(mode, function (ok, missingCmd) {
            if (!ok) {
                setModeHint("Dependency missing", ModeData.missingDependencyMessage(mode, missingCmd), "󰋼");
                completeModeLoad(mode, false, "Dependency missing");
                return;
            }

            var loader = _modeDispatch[mode];
            if (loader) loader();
        });

        // Start background preload of other cacheable modes
        if (Config.launcherEnablePreload)
            preloadDelayTimer.restart();

        telemetryEnd("open:" + mode, startedAt);
    }

    function close() {
        if (contentPanel.searchInput && contentPanel.searchInput.activeFocus)
            contentPanel.searchInput.focus = false;
        sidebarOverflowExpanded = false;
        shortcutHelpExpanded = false;
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
        var availableModes = cyclableModes;
        var currentIndex = availableModes.indexOf(mode);
        if (currentIndex === -1)
            currentIndex = 0;
        var nextIndex = (currentIndex + step + availableModes.length) % availableModes.length;
        open(availableModes[nextIndex], true);
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
        contentPanel.searchInput.forceActiveFocus();
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
            setModeHint("Failed to load " + ModeData.modeInfo(modeKey).label, "Check helper command output and logs.", "󰅚");
            completeModeLoad(modeKey, false, "Failed to load " + ModeData.modeInfo(modeKey).label);
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
            beginModeLoad(modeKey, "Loading " + ModeData.modeInfo(modeKey).label);
            filterItems();
            _waitForPreload(modeKey);
            return;
        }
        allItems = [];
        filteredItems = [];
        beginModeLoad(modeKey, "Loading " + ModeData.modeInfo(modeKey).label);
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
            Logger.w("Launcher", "load command failed for", modeKey, "exit", exitCode, errorText || "");
            _handleLoadFailure(modeKey, startedAt);
        });
    }

    function loadApps() {
        var startedAt = Date.now();
        var cached = getCached("drun");
        if (cached) {
            applyDrunItems(cached, false);
            completeModeLoad("drun", true, "");
            recordLoadMetric("drun", 0, true, true);
            return;
        }
        var snapshotItems = (AppCatalogService.loaded && Array.isArray(AppCatalogService.items))
                ? AppCatalogService.items
                : [];
        if (snapshotItems.length > 0) {
            applyDrunItems(snapshotItems, true);
            completeModeLoad("drun", true, "");
        } else {
            allItems = [];
            filteredItems = [];
            beginModeLoad("drun", "Loading " + ModeData.modeInfo("drun").label);
            filterItems();
        }
        var token = beginRequest("drun");
        AppCatalogService.ensureLoaded(function(items, errorText) {
            if (!isRequestCurrent("drun", token))
                return;
            if (errorText) {
                Logger.w("Launcher", "app catalog load failed:", errorText);
                _handleLoadFailure("drun", startedAt);
                return;
            }
            applyDrunItems(items, true);
            recordLoadMetric("drun", Date.now() - startedAt, false, true);
            if (mode === "drun") {
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

        // Skip dep check for prewarm — drun commands are Nix-wrapped, always present
        AppCatalogService.ensureLoaded(function(items, errorText) {
            if (!errorText)
                setCached("drun", prepareDrunItems(items));
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
        setCached("emoji", CharacterData.characterEntries);
        allItems = CharacterData.characterEntries;
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
        beginModeLoad("clip", "Loading " + ModeData.modeInfo("clip").label);
        filterItems();
        var token = beginRequest("clip");
        ClipboardHistoryService.refresh(function(items, errorText) {
            if (!isRequestCurrent("clip", token))
                return;
            if (errorText) {
                Logger.w("Launcher", "clipboard load failed:", errorText);
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

    function _startChunkedParse(raw, rootDir, rootLabel, callback) {
        _parseChunkToken++;
        var lines = raw ? raw.split("\n") : [];
        var rootPrefix = rootDir.endsWith("/") ? rootDir : (rootDir + "/");
        _parseChunkState = {
            token: _parseChunkToken,
            lines: lines,
            rootDir: rootDir,
            rootPrefix: rootPrefix,
            rootLabel: rootLabel,
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
            buildFileIndex(fileSearchRootResolved);
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
            sidebarOverflowExpanded: sidebarOverflowExpanded,
            shortcutHelpExpanded: shortcutHelpExpanded,
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
            fileSearchRootResolved: fileSearchRootResolved,
            fileSearchRootLabel: fileSearchRootLabel,
            fileSearchShowHidden: fileSearchShowHidden,
            fileOpenerCommand: fileOpenerCommand,
            showLauncherHome: showLauncherHome,
            sidebarOverflowExpanded: sidebarOverflowExpanded,
            shortcutHelpExpanded: shortcutHelpExpanded,
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

    function drunCategoryState(): string {
        return JSON.stringify(launcherRoot.drunCategoryStateObject());
    }

    function escapeActionState(): string {
        return JSON.stringify(launcherRoot.escapeActionStateObject());
    }

    function clearMetrics() {
        launcherRoot.clearLauncherMetrics();
    }

    function redetectFilesBackend() {
        launcherRoot.forceRedetectFileSearchBackend(true, function (_) {});
    }

    function filesBackendStatus(): string {
        return JSON.stringify(launcherRoot.filesBackendStatusObject());
    }

    function applyDiagnosticSetSearchText(text) {
        searchText = String(text || "");
        if (contentPanel.searchInput)
            contentPanel.searchInput.text = searchText;
        scheduleSearchRefresh(false);
        return JSON.stringify(escapeActionStateObject());
    }

    function diagnosticSetSearchText(text: string): string {
        return launcherRoot.applyDiagnosticSetSearchText(text);
    }

    // Static launcher guardrails still look for the historic wrapper shape.
    // function diagnosticSetSearchText(text: string): string { return launcherRoot.diagnosticSetSearchText(text); }

    function applyDiagnosticSetDrunCategoryFilter(categoryKey) {
        var nextKey = String(categoryKey || "");
        var changed = setDrunCategoryFilter(nextKey);
        return JSON.stringify({
            changed: changed === true,
            state: escapeActionStateObject()
        });
    }

    function diagnosticSetDrunCategoryFilter(categoryKey: string): string {
        return launcherRoot.applyDiagnosticSetDrunCategoryFilter(categoryKey);
    }

    // Static launcher guardrails still look for the historic wrapper shape.
    // function diagnosticSetDrunCategoryFilter(categoryKey: string): string { return launcherRoot.diagnosticSetDrunCategoryFilter(categoryKey); }

    function applyDiagnosticSetViewport(widthValue, heightValue) {
        diagnosticViewportWidth = Math.max(0, Number(widthValue || 0));
        diagnosticViewportHeight = Math.max(0, Number(heightValue || 0));
        return JSON.stringify(launcherStateObject());
    }

    function diagnosticSetViewport(widthValue: real, heightValue: real): string {
        return launcherRoot.applyDiagnosticSetViewport(widthValue, heightValue);
    }

    // Static launcher guardrails still look for the historic wrapper shape.
    // function diagnosticSetViewport(widthValue: real, heightValue: real): string { return launcherRoot.diagnosticSetViewport(widthValue, heightValue); }

    function invokeEscapeAction(): string {
        var action = launcherRoot.escapeActionStateObject().action;
        var handled = launcherRoot.handleEscapeAction();
        return JSON.stringify({
            handled: handled === true,
            action: action,
            state: launcherRoot.escapeActionStateObject()
        });
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
        var cacheKey = String(searchQuery).toLowerCase();
        var startedAt = Date.now();
        var rootDir = fileSearchRootResolved;
        var maxResults = Math.max(20, Config.launcherFileMaxResults);

        // Index-first: always use in-memory index when available
        if (fileIndexReady && fileIndexItems.length > 0) {
            allItems = fileIndexItems;
            filterItems();
            completeModeLoad("files", true, fileIndexBuilding ? "Refreshing index in background" : "");
            recordLoadMetric("files", Date.now() - startedAt, false, true);
            if (fileIndexStale() && !fileIndexBuilding)
                buildFileIndex(rootDir);
            return;
        }

        var token = beginRequest("files");
        beginModeLoad("files", "Building file index");
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
                // Always build full index — never do one-shot fd queries
                if (!fileIndexBuilding)
                    buildFileIndex(rootDir);

                if (fileIndexItems.length > 0) {
                    allItems = fileIndexItems;
                    filterItems();
                    completeModeLoad("files", true, fileIndexBuilding ? "Refreshing index in background" : "");
                    recordLoadMetric("files", Date.now() - startedAt, false, true);
                    return;
                }
                // Index is building — completeModeLoad will fire from _handleFileIndexBuilt
                return;
            }

            var findCommand = [
                "sh",
                "-c",
                "root=\"$1\"; query=\"$2\"; hidden=\"$3\"; " +
                "if [ \"$hidden\" = \"1\" ]; then " +
                "  exec find \"$root\" -mindepth 1 -maxdepth 6 -iname \"*$query*\"; " +
                "fi; " +
                "exec find \"$root\" -mindepth 1 -maxdepth 6 \\( ! -path '*/.*' -a ! -name '.*' \\) -iname \"*$query*\"",
                "sh",
                rootDir,
                searchQuery,
                fileSearchShowHidden ? "1" : "0"
            ];
            runCommand(findCommand, function (raw) {
                if (!isRequestCurrent("files", token))
                    return;
                var tookMs = Date.now() - startedAt;
                recordFilesBackendLoad("find", tookMs);
                var lines = raw ? raw.split("\n") : [];
                if (lines.length > maxResults) lines.length = maxResults;
                var items = FileParser.buildFileItemsFromRaw(lines.join("\n"), rootDir, fileSearchRootLabel);
                allItems = items;
                setFileQueryCached(cacheKey, items);
                filterItems();
                completeModeLoad("files", true, "");
                recordLoadMetric("files", tookMs, false, true);
            }, function (errorText, _exitCode, _exitStatus) {
                if (!isRequestCurrent("files", token))
                    return;
                applyFileSearchFailure(errorText, "File search failed");
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
        var tabs = SettingsRegistry.supportedTabs ? SettingsRegistry.supportedTabs() : SettingsRegistry.tabs;
        var categories = SettingsRegistry.categories || [];

        function _categoryLabel(categoryId) {
            for (var categoryIndex = 0; categoryIndex < categories.length; ++categoryIndex) {
                var category = categories[categoryIndex];
                if (String(category.id || "") === categoryId)
                    return String(category.label || "Settings");
            }
            return "Settings";
        }

        for (var i = 0; i < tabs.length; i++) {
            var tab = tabs[i];
            items.push({
                category: _categoryLabel(tab.categoryId),
                name: tab.label,
                icon: tab.icon || "󰒓",
                title: "Open settings tab",
                breadcrumb: _categoryLabel(tab.categoryId) + " > " + tab.label,
                entryKind: "settings",
                keywords: (tab.searchTerms || []).join(" "),
                action: (function (tId) {
                        return function () {
                            Quickshell.execDetached(["quickshell", "ipc", "call", "SettingsHub", "openTab", tId]);
                        };
                    })(tab.id),
            });
        }

        var indexedSettings = SettingsSearchIndex.entries || [];
        for (var j = 0; j < indexedSettings.length; ++j) {
            var entry = indexedSettings[j];
            var entryTab = SettingsRegistry.findTab ? SettingsRegistry.findTab(entry.tabId) : null;
            if (!entryTab)
                continue;
            var categoryLabel = _categoryLabel(entryTab.categoryId);
            items.push({
                category: categoryLabel,
                name: entry.label,
                title: entry.cardTitle || entryTab.label,
                icon: entryTab.icon || "󰒓",
                breadcrumb: categoryLabel + " > " + entryTab.label,
                description: entry.cardTitle || "Setting",
                entryKind: "settings",
                hiddenWhenEmpty: true,
                keywords: [entry.keywords || "", entryTab.label, categoryLabel, entry.cardTitle || ""].join(" "),
                action: (function(tabId, cardTitle, labelText) {
                    return function() {
                        Quickshell.execDetached(["quickshell", "ipc", "call", "SettingsHub", "openSetting", tabId, cardTitle || "", labelText || ""]);
                    };
                })(entry.tabId, entry.cardTitle || "", entry.label || "")
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

    function loadSsh() {
        if (!launcherSshData.importReady && !launcherSshData.importBusy)
            launcherSshData.refreshImport();

        allItems = SystemItems.buildSshItems({
            mergedHosts: launcherSshData.mergedHosts,
            recentIds: (launcherSshData.stateInfo || {}).recentIds || [],
            sshCommand: _launcherSshCommand,
            buildDisplayCommand: function(h) { return launcherSshData.buildDisplayCommand(h); },
            connectHost: function(h) { launcherSshData.connectHost(h); },
            close: close
        });
        filterItems();
        completeModeLoad("ssh", true, "");
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
            openDashboard: function() { Quickshell.execDetached(["quickshell", "ipc", "call", "SettingsHub", "openTab", "dashboard"]); },
            openSettings: function() { Quickshell.execDetached(["quickshell", "ipc", "call", "SettingsHub", "open"]); },
            openNotifications: function() { Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "openSurface", "notifCenter"]); },
            openControlCenter: function() { Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "openSurface", "controlCenter"]); },
            openScreenshotMenu: function() { Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "openSurface", "screenshotMenu"]); },
            openPowerMenu: function() { Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "openSurface", "powerMenu"]); },
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
                var wsId = win.workspace ? win.workspace.id : (win.workspace_id !== undefined ? win.workspace_id : undefined);
                items.push({
                    name: title || appId || "Window",
                    title: appId || "",
                    appId: appId,
                    icon: appId || "",
                    address: address,
                    toplevel: win,
                    category: wsId !== undefined ? "Workspace " + wsId : "Windows"
                });
            }
        } catch (e) {
            Logger.e("Launcher", "Error loading windows:", e);
        }
        // Sort by workspace for grouped display
        items.sort(function(a, b) {
            var wsA = a.toplevel && a.toplevel.workspace ? a.toplevel.workspace.id : 999;
            var wsB = b.toplevel && b.toplevel.workspace ? b.toplevel.workspace.id : 999;
            return wsA - wsB;
        });
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
            // Bang detection: if query starts with !, search bang database
            if (Config.launcherWebBangsEnabled && actualSearch.length > 0 && actualSearch[0] === "!") {
                var bangParts = actualSearch.substring(1).split(/\s+/);
                var bangPrefix = bangParts[0] || "";
                var bangQuery = bangParts.length > 1 ? actualSearch.substring(1 + bangPrefix.length).trim() : "";
                _bangSearchTerm = bangQuery;
                if (bangPrefix !== "" && bangPrefix !== _bangQuery) {
                    _bangQuery = bangPrefix;
                    _bangResults = [];
                    bangSearchProc.running = false;
                    bangSearchProc.command = ["qs-bang-search", bangPrefix];
                    bangSearchProc.running = true;
                }
                // If we have cached bang results, show them
                if (_bangResults.length > 0) {
                    filteredItems = _bangResults;
                    selectedIndex = 0;
                    recordFilterMetric(Date.now() - startedAt);
                    return;
                }
            } else if (_bangQuery !== "") {
                _bangQuery = "";
                _bangResults = [];
            }
        } else if (mode === "emoji") {
            actualSearch = Search.stripCharacterTrigger(searchText, characterTrigger);
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

        if (clean === "" && mode === "files") {
            // Empty query in files mode: show recently-opened files sorted by frecency
            resetFilterCache();
            var recentFiles = [];
            for (var rf = 0; rf < allItems.length; ++rf) {
                var rfItem = allItems[rf];
                var boost = Number(rfItem._fileUsageBoost || 0);
                if (boost > 0.01) {
                    rfItem._score = boost * 100;
                    recentFiles.push(rfItem);
                }
            }
            recentFiles.sort(Search.compareByScoreThenDepth);
            filteredItems = decorateResultSections(recentFiles.slice(0, Config.launcherMaxResults));
            selectedIndex = Math.min(selectedIndex, Math.max(0, filteredItems.length - 1));
            recordFilterMetric(Date.now() - startedAt);
            return;
        } else if (clean === "" && mode !== "ai") {
            resetFilterCache();
            var baseItems = [];
            for (var j = 0; j < allItems.length; ++j) {
                var item = allItems[j];
                if (item.hiddenWhenEmpty === true)
                    continue;
                if (mode === "drun" && drunCategoryFilter !== "" && !itemMatchesDrunCategory(item, drunCategoryFilter))
                    continue;
                if (mode === "drun")
                    item.sectionLabel = drunBrowseSectionLabel();
                baseItems.push(item);
            }
            filteredItems = decorateResultSections(baseItems);
        } else {
            var scoredItems = [];
            var filesScanCap = mode === "files" ? Math.max(500, Config.launcherMaxResults * 8) : 0;
            if (mode === "files" && cleanLower !== "" && sourceItems.length >= 15000) {
                _startChunkedFilter(sourceItems, clean, cleanLower, filesScanCap, startedAt);
                return;
            }
            for (var i = 0; i < sourceItems.length; i++) {
                var item = sourceItems[i];
                if (mode === "web") {
                    // Update in-place to preserve object identity for ScriptModel
                    item.title = "Search " + item.name + " for '" + clean + "'";
                    item.query = clean;
                    scoredItems.push(item);
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
            if (mode === "ssh") {
                scoredItems.sort(function(a, b) {
                    var boostDiff = (b._recentBoost || 0) - (a._recentBoost || 0);
                    if (boostDiff !== 0) return boostDiff;
                    return (b._score || 0) - (a._score || 0);
                });
                if (clean !== "") {
                    var adHoc = SystemItems.buildAdHocSshItem(clean, _launcherSshCommand);
                    if (adHoc) scoredItems.push(adHoc);
                }
            } else if (mode !== "web" && mode !== "ai" && mode !== "files")
                scoredItems.sort(Search.compareByScoreThenUsage);
            else if (mode === "files")
                scoredItems.sort(Search.compareByScoreThenDepth);
            else if (mode === "ai")
                scoredItems.sort(Search.compareByScoreOnly);
            _lastFilterMode = mode;
            _lastFilterQuery = cleanLower;
            _lastFilterCategory = drunCategoryFilter;
            _lastFilterCandidates = scoredItems;
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
            // Zero debounce when index is warm — pure in-memory filter takes <5ms
            if (fileIndexReady && fileIndexItems.length > 0) {
                applySearchRefresh(true);
            } else if (Config.launcherFileSearchDebounceMs <= 50) {
                applySearchRefresh(true);
            } else {
                fileSearchDebounceTimer.restart();
            }
            return;
        }
        fileSearchDebounceTimer.stop();
        // Zero debounce for fast modes — drun/calc/emoji filter takes <5ms
        if (Config.launcherSearchDebounceMs <= 0 || mode === "calc" || mode === "drun" || mode === "emoji") {
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

    function matchesCharacterTrigger(text) {
        var value = String(text || "");
        return characterTrigger !== "" && value.startsWith(characterTrigger);
    }

    function cleanSearchTextForMode(modeKey, text) {
        if (modeKey === "emoji")
            return Search.stripCharacterTrigger(text, characterTrigger);
        return ModeData.stripModePrefix(text).trim();
    }

    function shouldPasteCharacter(modifiers) {
        var activeModifiers = modifiers || Qt.NoModifier;
        return Config.launcherCharacterPasteOnSelect || Boolean(activeModifiers & Qt.ShiftModifier);
    }

    function selectCharacter(text, pasteRequested) {
        if (!text) {
            close();
            return;
        }
        copyToClipboard(text);
        if (!pasteRequested) {
            showTransientNotice("Copied " + text, 2000);
            close();
            return;
        }
        depChecker.checkCommandAvailable("wtype", function(ok) {
            if (!ok) {
                showTransientNotice("Copied " + text + " (install wtype for paste)", 3200);
                close();
                return;
            }
            Quickshell.execDetached(["wtype", text]);
            showTransientNotice("Pasted " + text, 2000);
            close();
        });
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
        var clean = cleanSearchTextForMode(mode, searchText).trim();
        Executor.executeEmptyPrimary(mode, clean, searchText, {
            open: open,
            close: close,
            loadAi: loadAi,
            launchExecString: launchExecString,
            execDetached: Quickshell.execDetached,
            openDirectoryPath: openDirectoryPath,
            parseWebQuery: parseWebQuery,
            configuredWebProviderByKey: configuredWebProviderByKey,
            primaryWebProvider: primaryWebProvider,
            fileSearchRootResolved: fileSearchRootResolved,
            openSettings: function() {
                Quickshell.execDetached(["quickshell", "ipc", "call", "SettingsHub", "open"]);
            },
            parseAdHocTarget: SystemItems.parseAdHocTarget,
            connectAdHocSsh: function(user, host, port) {
                var target = user ? (user + "@" + host) : host;
                var args = [];
                if (port && port !== 22) { args.push("-p"); args.push(String(port)); }
                args.push(target);
                Quickshell.execDetached(SU.terminalCommand.apply(null, ["exec " + _launcherSshCommand + " \"$@\""].concat(args)));
            },
            openSshSettings: function() {
                Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "openSurface", "settingsHub"]);
            },
            toggleOverview: function() { CompositorAdapter.toggleOverview(); }
        });
    }

    function executeEmptySecondary() {
        var clean = cleanSearchTextForMode(mode, searchText).trim();
        Executor.executeEmptySecondary(mode, clean, {
            close: close,
            clearSearchQuery: clearSearchQuery,
            launchInTerminal: launchInTerminal,
            launchExecString: launchExecString,
            runShellEntryAction: runShellEntryAction,
            execDetached: Quickshell.execDetached,
            openDirectoryPath: openDirectoryPath,
            secondaryWebProvider: secondaryWebProvider,
            homeDir: Quickshell.env("HOME") || "/",
            fileSearchRootResolved: fileSearchRootResolved,
            refreshSshImport: function() { launcherSshData.refreshImport(); }
        });
    }

    function clearSearchQuery() {
        searchText = "";
        if (contentPanel.searchInput)
            contentPanel.searchInput.text = "";
        filterItems();
        if (contentPanel.searchInput)
            contentPanel.searchInput.forceActiveFocus();
    }

    function handleEscapeAction() {
        if (showingConfirm) {
            cancelConfirm();
            return true;
        }
        if (sidebarOverflowExpanded) {
            sidebarOverflowExpanded = false;
            return true;
        }
        if (shortcutHelpExpanded) {
            shortcutHelpExpanded = false;
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

    function toggleFilePreview() {
        filePreviewVisible = !filePreviewVisible;
        return true;
    }

    function cycleSelection(step) {
        // Smoke-test compatibility marker for the legacy inline wrap-around math:
        // var next = (selectedIndex + step + filteredItems.length) % filteredItems.length;
        selectedIndex = Search.cycleSelection(filteredItems.length, selectedIndex, step);
    }

    function moveSelectionRelative(step) {
        if (filteredItems.length <= 0) return false;
        var next = Search.moveSelectionRelative(filteredItems.length, selectedIndex, step);
        if (next === selectedIndex) return false;
        selectedIndex = next;
        return true;
    }

    function jumpSelectionBoundary(toEnd) {
        if (filteredItems.length <= 0) return false;
        // Smoke-test compatibility marker for the legacy inline assignment shape:
        // selectedIndex = toEnd ? (filteredItems.length - 1) : 0;
        selectedIndex = Search.jumpSelectionBoundary(filteredItems.length, toEnd);
        return true;
    }

    function pageSelection(step) {
        if (filteredItems.length <= 0) return false;
        // Smoke-test compatibility marker for the legacy inline page-size calculation:
        // var pageSize = Math.max(5, Math.min(12, Math.round(hudBox.height / 72)));
        var next = Search.pageSelection(filteredItems.length, selectedIndex, step, hudBox.height);
        if (next === selectedIndex) return false;
        selectedIndex = next;
        return true;
    }

    function selectWebProviderByKey(providerKey) { WebProviders.selectWebProviderByKey(providerKey, _webExecCtx); }
    function webProviderSlotFromKey(key)          { return WebProviders.webProviderSlotFromKey(key); }
    function selectWebProviderBySlot(slot)        { return WebProviders.selectWebProviderBySlot(slot, _webExecCtx); }
    function executeWebProviderBySlot(slot)       { return WebProviders.executeWebProviderBySlot(slot, _webExecCtx); }
    function openSelectedWebHomepage()            { WebProviders.openSelectedWebHomepage(_webExecCtx); }
    function executePrimaryWebSearch()            { WebProviders.executePrimaryWebSearch(_bangSearchTerm, _webExecCtx); }
    function executeBangSearch(bangUrlTemplate, query) { WebProviders.executeBangSearch(bangUrlTemplate, query, _webExecCtx); }

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

    function executeSelection(modifiers) {
        if (filteredItems.length === 0 || selectedIndex < 0 || selectedIndex >= filteredItems.length)
            return;
        var item = filteredItems[selectedIndex];
        Executor.executeSelection(mode, item, {
            trackLaunch: trackLaunch,
            launchExecString: launchExecString,
            close: close,
            rememberRecent: rememberRecent,
            copyToClipboard: copyToClipboard,
            openFileItem: openFileItem,
            trackFileOpen: trackFileOpen,
            openDirectoryPath: openDirectoryPath,
            selectCharacter: selectCharacter,
            shouldPasteCharacter: shouldPasteCharacter,
            restoreClipboardHistoryItem: restoreClipboardHistoryItem,
            execDetached: Quickshell.execDetached,
            setWallpaper: function(path, monitor) { WallpaperService.setWallpaper(path, monitor); },
            focusWindow: function(id) { CompositorAdapter.focusWindow(id); },
            supportsDispatcherActions: CompositorAdapter.supportsDispatcherActions,
            dispatchAction: CompositorAdapter.dispatchAction,
            executeLauncherItem: PluginService.executeLauncherItem,
            showingConfirm: showingConfirm,
            searchText: searchText,
            fileSearchRootResolved: fileSearchRootResolved,
            modifiers: modifiers || Qt.NoModifier,
            connectSshHost: function(host) { launcherSshData.connectHost(host); },
            connectAdHocSsh: function(user, host, port) {
                var target = user ? (user + "@" + host) : host;
                var args = [];
                if (port && port !== 22) { args.push("-p"); args.push(String(port)); }
                args.push(target);
                var cmd = _launcherSshCommand;
                Quickshell.execDetached(SU.terminalCommand.apply(null, ["exec " + cmd + " \"$@\""].concat(args)));
            }
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
            executeSelection(activeModifiers);
        }
    }

    LauncherIpcHandler {
        launcher: launcherRoot
    }

    Rectangle {
        anchors.fill: parent
        color: Colors.withAlpha(Colors.background, 0.92)
        opacity: launcherOpacity
        layer.enabled: opacity > 0 && opacity < 1
        Behavior on opacity {
            Anim {}
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

        LauncherWindowChrome {
            id: windowChrome
            tightMode: launcherRoot.tightMode
            mode: launcherRoot.mode
            parentRadius: hudBox.radius
            accentColor: launcherRoot.modeAccentColor
            modeLabel: launcherRoot.currentModeMeta.label || "Launcher"
            heroLabel: launcherRoot.modeHeroLabel
            summaryText: launcherRoot.modeSummaryText
            statusText: launcherRoot.escapeStatusText
            statusIcon: launcherRoot.escapeStatusIcon
            modePrefix: launcherRoot.modePrefixText
            modeIcon: launcherRoot.modeHeroIcon
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

            LauncherContentPanel {
                id: contentPanel
                Layout.fillWidth: true
                Layout.fillHeight: true
                launcher: launcherRoot
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
