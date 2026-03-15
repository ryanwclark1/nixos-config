import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import "../services"
import "../widgets" as SharedWidgets

PanelWindow {
    id: launcherRoot

    property var screenRef: screen || Quickshell.cursorScreen || Config.primaryScreen()
    screen: screenRef
    readonly property var edgeMargins: Config.reservedEdgesForScreen(screenRef, "")
    readonly property int usableWidth: Math.max(0, width - edgeMargins.left - edgeMargins.right)
    readonly property int usableHeight: Math.max(0, height - edgeMargins.top - edgeMargins.bottom)
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
    property var featuredActions: []
    property string drunCategoryFilter: ""
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
    property var modeCache: ({})
    property var modeCacheTime: ({})
    property var fileQueryCache: ({})
    property var fileQueryCacheTime: ({})
    property string fileSearchBackend: ""
    property int fileSearchBackendResolvedAt: 0
    property string transientNoticeText: ""
    readonly property int fileSearchBackendRefreshMs: 180000
    readonly property int fileSearchBackendMissRefreshMs: 20000
    property int _lastFilterTriggerMs: 0
    property int openCount: 0
    property int _requestToken: 0
    property var _activeRequests: ({})
    property var commandAvailability: ({})
    property var _commandCheckProcs: ({})
    property var _commandWaiters: ({})
    property var mediaPlayers: []
    property var preloadFailureState: ({})
    readonly property var availableToplevels: (typeof ToplevelManager !== "undefined" && ToplevelManager.toplevels) ? (ToplevelManager.toplevels.values || []) : []
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

    // ── Hover anti-flicker ─────────────────────────
    property bool ignoreMouseHover: true
    property bool mouseTrackingReady: false
    property bool globalMouseInitialized: false
    property real globalLastMouseX: 0
    property real globalLastMouseY: 0

    readonly property bool showLauncherHome: Config.launcherShowHomeSections && searchText === "" && (mode === "drun" || mode === "system" || mode === "files")
    readonly property bool drunCategoryFiltersEnabled: Config.launcherDrunCategoryFiltersEnabled
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
    readonly property var allKnownModes: ["drun", "window", "files", "ai", "clip", "emoji", "calc", "web", "plugins", "run", "system", "keybinds", "media", "nixos", "wallpapers", "bookmarks", "settings", "devops"]
    readonly property var transientModes: ["dmenu"]
    readonly property var defaultModeOrder: ["drun", "window", "files", "ai", "clip", "emoji", "calc", "web", "plugins", "run", "system", "keybinds", "media", "nixos", "wallpapers", "bookmarks", "settings", "devops"]
    readonly property var defaultPrimaryModes: ["drun", "window", "files", "ai", "clip", "system", "media", "settings", "devops"]
    property var modeOrder: computeModeOrder()
    property var primaryModes: sanitizeModeList(Config.launcherEnabledModes, defaultPrimaryModes, allKnownModes).filter(function (modeKey) {
        return launcherRoot.isModeAllowedByCompositor(modeKey);
    })
    readonly property var modeMeta: ({
            "drun": {
                label: "Apps",
                hint: "Launch applications",
                prefix: ""
            },
            "window": {
                label: "Windows",
                hint: "Jump to an open window",
                prefix: ""
            },
            "files": {
                label: "Files",
                hint: "Search home with /",
                prefix: "/"
            },
            "ai": {
                label: "AI",
                hint: "Ask with !",
                prefix: "!"
            },
            "clip": {
                label: "Clipboard",
                hint: "Recent clipboard history",
                prefix: ""
            },
            "emoji": {
                label: "Emoji",
                hint: "Search with :",
                prefix: ":"
            },
            "calc": {
                label: "Calculator",
                hint: "Evaluate with =",
                prefix: "="
            },
            "web": {
                label: "Web",
                hint: "Search with ?",
                prefix: "?"
            },
            "plugins": {
                label: "Plugins",
                hint: "Search plugin providers",
                prefix: ""
            },
            "run": {
                label: "Run",
                hint: "Run commands with >",
                prefix: ">"
            },
            "system": {
                label: "System",
                hint: "Session and utility actions",
                prefix: ""
            },
            "keybinds": {
                label: "Keybinds",
                hint: "Inspect and trigger binds",
                prefix: ""
            },
            "media": {
                label: "Media",
                hint: "Control active players",
                prefix: ""
            },
            "nixos": {
                label: "NixOS",
                hint: "Nix maintenance actions",
                prefix: ""
            },
            "wallpapers": {
                label: "Wallpapers",
                hint: "Pick and apply wallpapers",
                prefix: ""
            },
            "bookmarks": {
                label: "Bookmarks",
                hint: "Open bookmarked destinations",
                prefix: "@"
            },
            "settings": {
                label: "Settings",
                hint: "Jump to a settings tab with ,",
                prefix: ","
            },
            "devops": {
                label: "DevOps",
                hint: "Control containers & services",
                prefix: ""
            }
        })
    readonly property var modeIcons: ({
            "drun": "󰀻",
            "window": "󱗼",
            "files": "󰈔",
            "ai": "󰚩",
            "clip": "󰅍",
            "emoji": "󰞅",
            "calc": "󰪚",
            "web": "󰖟",
            "plugins": "󰏗",
            "run": "󰆍",
            "system": "󰒓",
            "keybinds": "󰌌",
            "media": "󰝚",
            "nixos": "",
            "wallpapers": "󰸉",
            "bookmarks": "󰃭",
            "settings": "󰒓",
            "devops": "󰒍"
            })
    readonly property var webProviderCatalog: ({
            "google": {
                key: "google",
                name: "Google",
                exec: "https://www.google.com/search?q=",
                home: "https://www.google.com/",
                icon: "󰊯",
                isWeb: true
            },
            "duckduckgo": {
                key: "duckduckgo",
                name: "DuckDuckGo",
                exec: "https://duckduckgo.com/?q=",
                home: "https://duckduckgo.com/",
                icon: "󰇥",
                isWeb: true
            },
            "youtube": {
                key: "youtube",
                name: "YouTube",
                exec: "https://www.youtube.com/results?search_query=",
                home: "https://www.youtube.com/",
                icon: "󰗃",
                isWeb: true
            },
            "nixos": {
                key: "nixos",
                name: "NixOS Packages",
                exec: "https://search.nixos.org/packages?query=",
                home: "https://search.nixos.org/packages",
                icon: "",
                isWeb: true
            },
            "github": {
                key: "github",
                name: "GitHub",
                exec: "https://github.com/search?q=",
                home: "https://github.com/",
                icon: "󰊤",
                isWeb: true
            }
        })
    readonly property var launcherShortcuts: ({
            "drun": [
                {
                    icon: "󰀻",
                    label: "Applications",
                    description: "Installed desktop apps"
                },
                {
                    icon: "󱗼",
                    label: "Windows",
                    description: "Focus open clients",
                    openMode: "window"
                },
                shortcutAction("networkControls", "Networks"), shortcutAction("audioControls", "Audio")],
            "files": [
                {
                    icon: "󰈔",
                    label: "Home Search",
                    description: "Search under your home directory"
                },
                {
                    icon: "󰚩",
                    label: "Ask AI",
                    description: "Jump to AI mode",
                    openMode: "ai"
                }
            ],
            "system": [shortcutAction("commandCenter", "Command Center"), shortcutAction("audioControls", "Audio Controls"), shortcutAction("networkControls", "Network Controls")],
            "media": [
                {
                    icon: "󰝚",
                    label: "Media Players",
                    description: "Control active players"
                }
            ],
            "window": [
                {
                    icon: "󱗼",
                    label: "Window Switcher",
                    description: "Jump between open clients"
                }
            ],
            "clip": [
                {
                    icon: "󰅍",
                    label: "Clipboard",
                    description: "Reuse copied text"
                }
            ],
            "ai": [
                {
                    icon: "󰚩",
                    label: "AI Prompt",
                    description: "Copy result on execute"
                }
            ]
        })
    readonly property string modePrefixes: "!/@?>=:"
    readonly property string emptyStateTitle: {
        if (mode === "files")
            return "Type at least " + Config.launcherFileMinQueryLength + " characters to search files";
        if (mode === "ai")
            return "Describe what you want and press Enter";
        if (mode === "clip")
            return "Clipboard history is empty";
        if (mode === "window")
            return "No open windows found";
        return "No results";
    }
    readonly property string emptyStateSubtitle: {
        if (mode === "files")
            return "Search runs inside your home directory";
        if (mode === "ai")
            return "The response will be copied to your clipboard";
        if (mode === "clip")
            return "Copy something to populate clipboard history";
        if (mode === "window")
            return "Open some applications to see them here";
        return "Try another query or switch modes";
    }
    readonly property string emptyPrimaryCta: {
        var clean = stripModePrefix(searchText).trim();
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
        var clean = stripModePrefix(searchText).trim();
        var webSecondary = secondaryWebProvider();
        var webSecondaryName = webSecondary ? webSecondary.name : "Google";
        if (mode === "files")
            return "Open Folder";
        if (mode === "web")
            return clean !== "" ? "Search " + webSecondaryName : "Open " + webSecondaryName;
        if (mode === "system")
            return "Open Controls";
        if (mode === "run")
            return clean !== "" ? "Run In Terminal" : "Open Terminal";
        return searchText !== "" ? "Clear Query" : "";
    }
    readonly property string emptyPrimaryHint: {
        var clean = stripModePrefix(searchText).trim();
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
        var clean = stripModePrefix(searchText).trim();
        var webSecondary = secondaryWebProvider();
        var webSecondaryName = webSecondary ? webSecondary.name : "Google";
        if (mode === "files")
            return clean !== "" ? "Open folder target derived from query path." : "Open your home directory.";
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
            return "Tab: next mode • Shift+Tab: prev mode";
        if (launcherTabBehavior === "results")
            return "Tab: next result • Shift+Tab: prev mode";
        return hasResults ? "Tab: next result • Shift+Tab: prev mode" : "Tab: next mode • Shift+Tab: prev mode";
    }
    readonly property string launcherControlHintText: {
        var resultHint = hasResults ? "↑/↓/Ctrl+P/N/PgUp/PgDn/Home/End: results • " : "";
        var clearHint = searchText !== "" ? "Ctrl+L/U: clear • " : "";
        var escapeHint = (searchText !== "" || (drunCategoryFiltersEnabled && mode === "drun" && drunCategoryFilter !== "")) ? "Esc: reset/close" : "Esc: close";
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
        var action = itemActionLabel(selectedItem);
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
        if (searchText !== "" || (drunCategoryFiltersEnabled && mode === "drun" && drunCategoryFilter !== ""))
            return "Esc: Reset";
        return "Shift+Tab: Prev Mode";
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
            return itemProviderLabel(selectedItem);
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
                if (launcherRoot.onCommandOutput) {
                    var cb = launcherRoot.onCommandOutput;
                    launcherRoot.onCommandOutput = null;
                    cb(this.text || "");
                }
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

    Component {
        id: preloadProcComponent
        Process {
            id: _preloadProc
            property string _modeKey: ""
            property int _startedAt: 0
            running: false
            stdout: StdioCollector {
                onStreamFinished: {
                    launcherRoot._handlePreloadDone(_preloadProc, this.text || "");
                }
            }
        }
    }

    Component {
        id: commandCheckProcComponent
        Process {
            id: _checkProc
            property string _commandName: ""
            running: false
            stdout: StdioCollector {
                onStreamFinished: {
                    launcherRoot._finalizeCommandCheck(_checkProc, (this.text || "").trim() === "1");
                }
            }
        }
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
                }
            } else if (!launcherRoot._preloadProcs[waitingFor]) {
                // Preload finished but no cache entry (failed) — stop waiting
                running = false;
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
    property int _toplevelCount: availableToplevels.length
    on_ToplevelCountChanged: {
        if (launcherRoot.mode === "window" && launcherRoot.launcherOpacity > 0)
            launcherRoot.loadWindows();
    }

    property int _mprisCount: Mpris.players ? Mpris.players.length || 0 : 0
    on_MprisCountChanged: {
        if (launcherRoot.mode === "media" && launcherRoot.launcherOpacity > 0)
            launcherRoot.refreshMediaPlayers();
    }

    onSelectedIndexChanged: {
        launcherRoot.rememberCurrentWebProviderSelection();
    }

    function modeInfo(key) {
        return launcherRoot.modeMeta[key] || {
            label: key.toUpperCase(),
            hint: "",
            prefix: ""
        };
    }

    function sanitizeModeList(source, fallback, allowedList) {
        var out = [];
        var seen = ({});
        var allowed = ({});
        var i;
        for (i = 0; i < allowedList.length; ++i)
            allowed[allowedList[i]] = true;

        var list = Array.isArray(source) && source.length > 0 ? source : fallback;
        for (i = 0; i < list.length; ++i) {
            var modeKey = String(list[i] || "");
            if (!allowed[modeKey] || seen[modeKey])
                continue;
            out.push(modeKey);
            seen[modeKey] = true;
        }
        if (out.length === 0)
            return fallback.slice();
        return out;
    }

    function computeModeOrder() {
        var order = sanitizeModeList(Config.launcherModeOrder, defaultModeOrder, allKnownModes);
        var enabled = sanitizeModeList(Config.launcherEnabledModes, defaultModeOrder, allKnownModes);
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

    function modeDependencies(modeKey) {
        if (modeKey === "drun")
            return ["qs-apps"];
        if (modeKey === "run")
            return ["qs-run"];
        if (modeKey === "emoji")
            return ["qs-emoji"];
        if (modeKey === "clip")
            return ["qs-clip", "cliphist", "wl-copy"];
        if (modeKey === "keybinds")
            return ["qs-keybinds"];
        if (modeKey === "bookmarks")
            return ["qs-bookmarks"];
        if (modeKey === "wallpapers")
            return ["qs-wallpapers"];
        if (modeKey === "ai")
            return ["qs-ai", "wl-copy"];
        if (modeKey === "files")
            return [];
        if (modeKey === "plugins")
            return [];
        return [];
    }

    function missingDependencyMessage(modeKey, cmd) {
        if (modeKey === "files")
            return "Required command missing: " + cmd;
        return "Install '" + cmd + "' to use " + modeInfo(modeKey).label + " mode.";
    }

    function checkCommandAvailable(cmd, callback) {
        if (!cmd) {
            callback(false);
            return;
        }
        if (commandAvailability[cmd] !== undefined) {
            callback(commandAvailability[cmd] === true);
            return;
        }
        if (_commandCheckProcs[cmd]) {
            var queued = _commandWaiters[cmd] || [];
            queued.push(callback);
            var queuedMap = Object.assign({}, _commandWaiters);
            queuedMap[cmd] = queued;
            _commandWaiters = queuedMap;
            return;
        }

        var proc = commandCheckProcComponent.createObject(launcherRoot);
        proc._commandName = cmd;
        proc.command = ["bash", "-lc", "command -v " + shellQuote(cmd) + " >/dev/null 2>&1 && echo 1 || echo 0"];
        var nextProcMap = Object.assign({}, _commandCheckProcs);
        nextProcMap[cmd] = proc;
        _commandCheckProcs = nextProcMap;

        var waiters = Object.assign({}, _commandWaiters);
        waiters[cmd] = [callback];
        _commandWaiters = waiters;
        proc.running = true;
    }

    function _finalizeCommandCheck(proc, ok) {
        var cmd = proc._commandName;
        var nextAvailability = Object.assign({}, commandAvailability);
        nextAvailability[cmd] = ok;
        commandAvailability = nextAvailability;
        var next = Object.assign({}, _commandCheckProcs);
        delete next[cmd];
        _commandCheckProcs = next;
        var waiters = _commandWaiters[cmd] || [];
        var nextWaiters = Object.assign({}, _commandWaiters);
        delete nextWaiters[cmd];
        _commandWaiters = nextWaiters;
        for (var i = 0; i < waiters.length; ++i) {
            try {
                waiters[i](ok);
            } catch (e) {}
        }
        proc.destroy();
    }

    function ensureModeDependencies(modeKey, onReady) {
        var deps = modeDependencies(modeKey);
        if (!deps || deps.length === 0) {
            onReady(true, "");
            return;
        }

        var pending = deps.length;
        var failed = "";
        for (var i = 0; i < deps.length; ++i) {
            (function (depName) {
                    checkCommandAvailable(depName, function (ok) {
                        if (!ok && failed === "")
                            failed = depName;
                        pending--;
                        if (pending === 0)
                            onReady(failed === "", failed);
                    });
                })(deps[i]);
        }
    }

    function stripModePrefix(text) {
        if (text.length > 0 && modePrefixes.indexOf(text[0]) !== -1)
            return text.substring(1).trim();
        return text;
    }

    function configuredWebProviders() {
        var fallback = ["duckduckgo", "google", "youtube", "nixos", "github"];
        var order = Array.isArray(Config.launcherWebProviderOrder) ? Config.launcherWebProviderOrder : fallback;
        var out = [];
        var seen = ({});
        for (var i = 0; i < order.length; ++i) {
            var key = String(order[i] || "");
            var provider = webProviderCatalog[key];
            if (!provider || seen[key])
                continue;
            out.push(provider);
            seen[key] = true;
        }
        if (out.length === 0) {
            for (var j = 0; j < fallback.length; ++j) {
                var fallbackProvider = webProviderCatalog[fallback[j]];
                if (fallbackProvider)
                    out.push(fallbackProvider);
            }
        }
        return out;
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
        var key = String(token || "").toLowerCase();
        if (key === "")
            return "";
        if (webProviderCatalog[key])
            return key;
        var aliases = (Config.launcherWebAliases && typeof Config.launcherWebAliases === "object") ? Config.launcherWebAliases : ({});
        var providers = configuredWebProviders();
        for (var i = 0; i < providers.length; ++i) {
            var providerKey = String(providers[i].key || "");
            if (providerKey === "")
                continue;
            var list = aliases[providerKey];
            if (!Array.isArray(list))
                continue;
            for (var j = 0; j < list.length; ++j) {
                if (String(list[j] || "").toLowerCase() === key)
                    return providerKey;
            }
        }
        return "";
    }

    function parseWebQuery(text) {
        var clean = stripModePrefix(text || "").trim();
        var result = ({
                query: clean,
                providerKey: ""
            });
        if (clean === "")
            return result;
        var parts = clean.split(/\s+/);
        if (!parts || parts.length === 0)
            return result;
        var mapped = webAliasToProviderKey(parts[0]);
        if (mapped === "")
            return result;
        result.providerKey = mapped;
        result.query = parts.length > 1 ? clean.substring(parts[0].length).trim() : "";
        return result;
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

    function shellQuote(text) {
        return "'" + String(text || "").replace(/'/g, "'\\''") + "'";
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
        modeCache = ({});
        modeCacheTime = ({});
        fileQueryCache = ({});
        fileQueryCacheTime = ({});
    }

    function invalidateCommandAvailability(cmd) {
        if (commandAvailability[cmd] === undefined)
            return;
        var nextAvailability = Object.assign({}, commandAvailability);
        delete nextAvailability[cmd];
        commandAvailability = nextAvailability;
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
        var perMode = launcherMetrics.perMode || ({});
        return perMode[modeKey] || ({
                loads: 0,
                cacheHits: 0,
                cacheMisses: 0,
                failures: 0,
                lastLoadMs: 0,
                avgLoadMs: 0
            });
    }

    function clearLauncherMetrics() {
        launcherMetrics = ({
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
            });
    }

    function recordFilesBackendLoad(backend, durationMs) {
        var next = Object.assign({}, launcherMetrics);
        var took = Math.max(0, Math.round(durationMs || 0));
        if (backend === "fd") {
            var fdLoads = (next.filesFdLoads || 0) + 1;
            next.filesFdLoads = fdLoads;
            next.filesFdLastMs = took;
            next.filesFdAvgMs = Math.round((((next.filesFdAvgMs || 0) * (fdLoads - 1)) + took) / fdLoads);
        } else if (backend === "find") {
            var findLoads = (next.filesFindLoads || 0) + 1;
            next.filesFindLoads = findLoads;
            next.filesFindLastMs = took;
            next.filesFindAvgMs = Math.round((((next.filesFindAvgMs || 0) * (findLoads - 1)) + took) / findLoads);
        }
        launcherMetrics = next;
    }

    function recordFilesBackendResolveMetric(durationMs) {
        var next = Object.assign({}, launcherMetrics);
        var runs = (next.filesResolveRuns || 0) + 1;
        var took = Math.max(0, Math.round(durationMs || 0));
        next.filesResolveRuns = runs;
        next.filesResolveLastMs = took;
        next.filesResolveAvgMs = Math.round((((next.filesResolveAvgMs || 0) * (runs - 1)) + took) / runs);
        launcherMetrics = next;
    }

    function recordFilterMetric(durationMs) {
        var next = Object.assign({}, launcherMetrics);
        var runs = Math.max(0, Math.round(next.filterRuns || 0)) + 1;
        var last = Math.max(0, Math.round(durationMs || 0));
        var avg = Math.round((((next.avgFilterMs || 0) * (runs - 1)) + last) / runs);
        next.filterRuns = runs;
        next.lastFilterMs = last;
        next.avgFilterMs = avg;
        launcherMetrics = next;
    }

    function recordLoadMetric(modeKey, durationMs, cacheHit, success) {
        var next = Object.assign({}, launcherMetrics);
        if (!next.perMode)
            next.perMode = ({});
        var current = Object.assign({
            loads: 0,
            cacheHits: 0,
            cacheMisses: 0,
            failures: 0,
            lastLoadMs: 0,
            avgLoadMs: 0
        }, next.perMode[modeKey] || ({}));

        current.loads += 1;
        if (cacheHit) {
            current.cacheHits += 1;
            next.cacheHits = (next.cacheHits || 0) + 1;
        } else {
            current.cacheMisses += 1;
            next.cacheMisses = (next.cacheMisses || 0) + 1;
        }
        if (!success) {
            current.failures += 1;
            next.commandFailures = (next.commandFailures || 0) + 1;
        }

        var clampedDuration = Math.max(0, Math.round(durationMs || 0));
        current.lastLoadMs = clampedDuration;
        current.avgLoadMs = Math.round((((current.avgLoadMs || 0) * (current.loads - 1)) + clampedDuration) / current.loads);
        next.perMode[modeKey] = current;
        launcherMetrics = next;
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

    function itemMatchesDrunCategory(item, categoryKey) {
        var key = String(categoryKey || "");
        if (key === "")
            return true;
        ensureItemRankCache(item);
        var tokens = item._categoryTokens || [];
        for (var i = 0; i < tokens.length; ++i) {
            if (tokens[i] === key)
                return true;
        }
        return false;
    }

    function refreshDrunCategoryOptions(apps) {
        if (!drunCategoryFiltersEnabled) {
            drunCategoryFilter = "";
            drunCategoryOptions = [
                {
                    key: "",
                    label: "All",
                    count: Array.isArray(apps) ? apps.length : 0,
                    hotkey: "0"
                }
            ];
            return;
        }
        var source = Array.isArray(apps) ? apps : [];
        var counts = ({});
        var labels = ({});
        for (var i = 0; i < source.length; ++i) {
            var app = source[i];
            ensureItemRankCache(app);
            var key = String(app._primaryCategoryKey || "");
            if (key === "")
                continue;
            counts[key] = (counts[key] || 0) + 1;
            if (!labels[key])
                labels[key] = formatDrunCategoryLabel(key);
        }
        var keys = Object.keys(counts);
        keys.sort(function (a, b) {
            if ((counts[b] || 0) !== (counts[a] || 0))
                return (counts[b] || 0) - (counts[a] || 0);
            return String(labels[a] || a).localeCompare(String(labels[b] || b));
        });

        var next = [
            {
                key: "",
                label: "All",
                count: source.length,
                hotkey: "0"
            }
        ];
        var limit = Math.min(9, keys.length);
        for (var j = 0; j < limit; ++j) {
            var categoryKey = keys[j];
            next.push({
                key: categoryKey,
                label: String(labels[categoryKey] || categoryKey),
                count: counts[categoryKey] || 0,
                hotkey: String(j + 1)
            });
        }
        drunCategoryOptions = next;

        var exists = false;
        for (var k = 0; k < next.length; ++k) {
            if (String(next[k].key || "") === drunCategoryFilter) {
                exists = true;
                break;
            }
        }
        if (!exists)
            drunCategoryFilter = "";
    }

    function setDrunCategoryFilter(categoryKey) {
        if (!drunCategoryFiltersEnabled) {
            categoryKey = "";
        }
        var next = String(categoryKey || "");
        if (drunCategoryFilter === next)
            return false;
        drunCategoryFilter = next;
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
        var key = item.exec || item.address || item.fullPath || item.name || item.title || "";
        if (!key)
            return;
        var next = [
            {
                key: key,
                name: item.name || item.label || item.title || key,
                title: item.title || item.description || item.exec || "",
                icon: item.icon || modeIcons[mode] || "󰀻",
                exec: item.exec || "",
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
        }
        saveFrequency();
        rememberRecent(item || {});
        buildLauncherHome();
    }

    function buildLauncherHome() {
        featuredActions = launcherShortcuts[mode] || [];
        suggestionItems = [];
        if (mode === "drun") {
            var apps = getCached("drun") || [];
            refreshDrunCategoryOptions(apps);
            var recent = [];
            var seen = ({});
            var appsByExec = ({});
            var usageRanked = [];
            for (var i = 0; i < apps.length; ++i) {
                var app = apps[i];
                var execKey = String(app.exec || "");
                if (execKey !== "" && !appsByExec[execKey])
                    appsByExec[execKey] = app;
                var usageScore = UsageTrackerService.getUsageScore(execKey);
                if (usageScore > 0) {
                    var rankedByUsage = Object.assign({}, app);
                    rankedByUsage._usage = usageScore;
                    usageRanked.push(rankedByUsage);
                }
            }
            for (var j = 0; j < launchHistory.length; ++j) {
                var launch = launchHistory[j];
                var launchExec = String(launch.exec || "");
                var matchedApp = launchExec === "" ? null : appsByExec[launchExec];
                if (matchedApp && !seen[launchExec]) {
                    var matched = Object.assign({}, matchedApp);
                    matched._recent = launch.timestamp || 0;
                    recent.push(matched);
                    seen[launchExec] = true;
                }
            }
            usageRanked.sort(function (a, b) {
                if ((b._usage || 0) !== (a._usage || 0))
                    return (b._usage || 0) - (a._usage || 0);
                return compareLauncherItemsAlpha(a, b);
            });
            recent.sort(function (a, b) {
                if ((b._recent || 0) !== (a._recent || 0))
                    return (b._recent || 0) - (a._recent || 0);
                return compareLauncherItemsAlpha(a, b);
            });
            if (drunCategoryFilter !== "") {
                recent = recent.filter(function (item) {
                    return itemMatchesDrunCategory(item, drunCategoryFilter);
                });
            }
            if (recent.length < Config.launcherRecentAppsLimit) {
                for (var k = 0; k < usageRanked.length; ++k) {
                    var fallback = usageRanked[k];
                    var fallbackExec = String(fallback.exec || "");
                    if (fallbackExec === "" || seen[fallbackExec] || !itemMatchesDrunCategory(fallback, drunCategoryFilter))
                        continue;
                    var promoted = Object.assign({}, fallback);
                    promoted._recent = fallback._usage || 0;
                    recent.push(promoted);
                    seen[fallbackExec] = true;
                    if (recent.length >= Config.launcherRecentAppsLimit)
                        break;
                }
            }
            recentItems = recent.slice(0, Config.launcherRecentAppsLimit);
            var suggestions = [];
            for (var m = 0; m < usageRanked.length; ++m) {
                var candidate = usageRanked[m];
                var candidateExec = String(candidate.exec || "");
                if (candidateExec === "" || seen[candidateExec] || !itemMatchesDrunCategory(candidate, drunCategoryFilter))
                    continue;
                suggestions.push(candidate);
            }
            suggestionItems = suggestions.slice(0, Config.launcherSuggestionsLimit);
        } else if (mode === "system") {
            drunCategoryFilter = "";
            drunCategoryOptions = [
                {
                    key: "",
                    label: "All",
                    count: 0,
                    hotkey: "0"
                }
            ];
            recentItems = SystemActionRegistry.shellEntryActions;
        } else if (mode === "window" && availableToplevels.length > 0) {
            drunCategoryFilter = "";
            drunCategoryOptions = [
                {
                    key: "",
                    label: "All",
                    count: 0,
                    hotkey: "0"
                }
            ];
            recentItems = [
                {
                    name: "Focus open windows",
                    title: "Jump into current clients",
                    icon: "󱗼",
                    openMode: "window"
                }
            ];
        } else {
            drunCategoryFilter = "";
            drunCategoryOptions = [
                {
                    key: "",
                    label: "All",
                    count: 0,
                    hotkey: "0"
                }
            ];
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

        ensureModeDependencies(mode, function (ok, missingCmd) {
            if (!ok) {
                setModeHint("Dependency missing", missingDependencyMessage(mode, missingCmd), "󰋼");
                return;
            }

            if (mode === "drun")
                loadApps();
            else if (mode === "window") {
                allItems = [];
                filterItems();
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
            } else if (mode === "web")
                loadWeb();
            else if (mode === "plugins")
                loadPlugins();
            else if (mode === "system")
                loadSystem();
            else if (mode === "media") {
                allItems = [];
                filterItems();
                refreshMediaPlayers();
            } else if (mode === "nixos")
                loadNixos();
            else if (mode === "wallpapers")
                loadWallpapers();
            else if (mode === "files")
                loadFiles();
            else if (mode === "bookmarks")
                loadBookmarks();
            else if (mode === "settings")
                loadSettings();
            else if (mode === "devops")
                loadDevOps();
            else if (mode === "ai")
                loadAi();
            else if (mode === "keybinds")
                loadKeybinds();
            else if (mode === "dmenu")
                filterItems();
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

    function shortcutAction(actionId, labelOverride) {
        var action = SystemActionRegistry.actionById(actionId) || ({});
        return {
            icon: action.icon || "",
            label: labelOverride || action.label || action.name || "",
            description: action.title || action.subtitle || "",
            ipcTarget: action.ipcTarget || "",
            ipcAction: action.ipcAction || ""
        };
    }

    function makeConfirmedSystemAction(title, command) {
        return function () {
            askConfirm(title, function () {
                Quickshell.execDetached(command);
            });
        };
    }

    function makeDetachedSystemAction(command) {
        return function () {
            Quickshell.execDetached(command);
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

    function runCommand(command, callback) {
        if (commandProc.running)
            commandProc.running = false;
        onCommandOutput = callback;
        commandProc.command = command;
        commandProc.running = true;
    }

    function loadCached(modeKey, command, parseFunc) {
        var startedAt = Date.now();
        var cached = getCached(modeKey);
        if (cached) {
            allItems = cached;
            filterItems();
            recordLoadMetric(modeKey, 0, true, true);
            return;
        }
        // If a preload is already running for this mode, wait for it
        if (_preloadProcs[modeKey]) {
            allItems = [
                {
                    name: "Loading...",
                    isHint: true,
                    icon: "󰔟"
                }
            ];
            filterItems();
            _waitForPreload(modeKey);
            return;
        }
        allItems = [
            {
                name: "Loading...",
                isHint: true,
                icon: "󰔟"
            }
        ];
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
                }
            } catch (e) {
                recordLoadMetric(modeKey, Date.now() - startedAt, false, false);
                if (mode === modeKey)
                    setModeHint("Failed to load " + modeInfo(modeKey).label, "Check helper command output and logs.", "󰅚");
            }
        });
    }

    function loadApps() {
        loadCached("drun", ["qs-apps"], JSON.parse);
    }
    function loadRun() {
        loadCached("run", ["qs-run"], JSON.parse);
    }
    function loadWallpapers() {
        loadCached("wallpapers", ["qs-wallpapers"], JSON.parse);
    }
    function loadKeybinds() {
        loadCached("keybinds", ["qs-keybinds"], JSON.parse);
    }
    function loadBookmarks() {
        loadCached("bookmarks", ["qs-bookmarks"], JSON.parse);
    }

    function parseEmoji(raw) {
        var lines = raw.split("\n");
        var items = [];
        for (var i = 0; i < lines.length; i++) {
            if (lines[i].trim() !== "") {
                var parts = lines[i].split(" ");
                items.push({
                    name: parts[0],
                    title: parts.slice(1).join(" ")
                });
            }
        }
        return items;
    }

    function parseClip(raw) {
        return JSON.parse(raw).filter(function (it) {
            return it.content && it.content.indexOf("[[ binary data") === -1;
        }).map(function (it) {
            return {
                id: it.id,
                name: it.content,
                title: it.content,
                icon: "󰅍"
            };
        });
    }

    function loadEmojis() {
        loadCached("emoji", ["qs-emoji"], parseEmoji);
    }
    function loadClip() {
        loadCached("clip", ["qs-clip"], parseClip);
    }

    // ── Background preloading ───────────────────
    readonly property var preloadModes: ({
            "drun": {
                command: ["qs-apps"],
                parse: JSON.parse
            },
            "run": {
                command: ["qs-run"],
                parse: JSON.parse
            },
            "emoji": {
                command: ["qs-emoji"],
                parse: parseEmoji
            },
            "clip": {
                command: ["qs-clip"],
                parse: parseClip
            },
            "keybinds": {
                command: ["qs-keybinds"],
                parse: JSON.parse
            },
            "bookmarks": {
                command: ["qs-bookmarks"],
                parse: JSON.parse
            }
        })

    function startPreload() {
        if (!Config.launcherEnablePreload)
            return;
        var keys = Object.keys(preloadModes);
        for (var i = 0; i < keys.length; i++) {
            var key = keys[i];
            if (key !== mode && !shouldBackoffPreload(key) && !getCached(key) && !_preloadProcs[key]) {
                _spawnPreload(key);
            }
        }
    }

    function _spawnPreload(key) {
        var proc = preloadProcComponent.createObject(launcherRoot);
        proc._modeKey = key;
        proc._startedAt = Date.now();
        proc.command = preloadModes[key].command;
        _preloadProcs[key] = proc;
        proc.running = true;
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

    function buildFileItemsFromRaw(raw, homeDir) {
        var lines = raw ? raw.split("\n") : [];
        var items = new Array(lines.length);
        var count = 0;
        for (var i = 0; i < lines.length; ++i) {
            var path = String(lines[i] || "");
            if (path === "")
                continue;
            var fullPath = path.charCodeAt(0) === 47 ? path : (homeDir + "/" + path);
            var slash = fullPath.lastIndexOf("/");
            var name = slash >= 0 ? fullPath.substring(slash + 1) : fullPath;
            if (name === "")
                name = path;
            items[count] = {
                name: name,
                title: fullPath,
                fullPath: fullPath
            };
            count += 1;
        }
        if (count < items.length)
            items.length = count;
        return items;
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
            invalidateCommandAvailability("fd");
            invalidateCommandAvailability("find");
        }
        var startedAt = Date.now();
        checkCommandAvailable("fd", function (fdOk) {
            if (fdOk) {
                fileSearchBackend = "fd";
                fileSearchBackendResolvedAt = Date.now();
                recordFilesBackendResolveMetric(Date.now() - startedAt);
                callback("fd");
                return;
            }
            checkCommandAvailable("find", function (findOk) {
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
        var modeStats = modeMetric("files");
        var resolveRuns = launcherMetrics.filesResolveRuns || 0;
        var resolveAvgMs = launcherMetrics.filesResolveAvgMs || 0;
        var resolveLastMs = launcherMetrics.filesResolveLastMs || 0;
        var filesFdLoads = launcherMetrics.filesFdLoads || 0;
        var filesFindLoads = launcherMetrics.filesFindLoads || 0;
        var filesFdAvgMs = launcherMetrics.filesFdAvgMs || 0;
        var filesFdLastMs = launcherMetrics.filesFdLastMs || 0;
        var filesFindAvgMs = launcherMetrics.filesFindAvgMs || 0;
        var filesFindLastMs = launcherMetrics.filesFindLastMs || 0;
        var fileCacheHits = modeStats.cacheHits || 0;
        var fileCacheMisses = modeStats.cacheMisses || 0;
        return ({
                backend: filesBackendLabel,
                backendRaw: String(fileSearchBackend || ""),
                resolvedAt: fileSearchBackendResolvedAt,
                metrics: ({
                        filesResolveRuns: resolveRuns,
                        filesResolveAvgMs: resolveAvgMs,
                        filesResolveLastMs: resolveLastMs,
                        filesFdLoads: filesFdLoads,
                        filesFindLoads: filesFindLoads,
                        filesFdAvgMs: filesFdAvgMs,
                        filesFdLastMs: filesFdLastMs,
                        filesFindAvgMs: filesFindAvgMs,
                        filesFindLastMs: filesFindLastMs
                    }),
                cache: ({
                        hits: fileCacheHits,
                        misses: fileCacheMisses,
                        hitRateLabel: filesCacheStatsLabel
                    }),
                // Backward-compatible flat fields for existing consumers.
                resolveRuns: resolveRuns,
                resolveAvgMs: resolveAvgMs,
                resolveLastMs: resolveLastMs,
                filesFdLoads: filesFdLoads,
                filesFindLoads: filesFindLoads,
                filesFdAvgMs: filesFdAvgMs,
                filesFdLastMs: filesFdLastMs,
                filesFindAvgMs: filesFindAvgMs,
                filesFindLastMs: filesFindLastMs,
                fileCacheHits: fileCacheHits,
                fileCacheMisses: fileCacheMisses,
                fileCacheHitRateLabel: filesCacheStatsLabel
            });
    }

    function drunCategoryStateObject() {
        var options = Array.isArray(drunCategoryOptions) ? drunCategoryOptions : [];
        var normalized = [];
        var active = null;
        for (var i = 0; i < options.length; ++i) {
            var raw = options[i] || ({});
            var key = String(raw.key || "");
            var label = String(raw.label || formatDrunCategoryLabel(key));
            var count = Math.max(0, Math.round(Number(raw.count || 0)));
            var hotkey = String(raw.hotkey || "");
            var selected = key === drunCategoryFilter;
            var item = ({
                    key: key,
                    label: label,
                    count: count,
                    hotkey: hotkey,
                    selected: selected
                });
            if (selected && !active)
                active = item;
            normalized.push(item);
        }

        if (!active && normalized.length > 0) {
            var fallback = normalized[0];
            active = Object.assign({}, fallback, {
                selected: true
            });
            normalized[0] = active;
        }

        var totalCount = normalized.length > 0 ? Math.max(0, Math.round(Number(normalized[0].count || 0))) : 0;
        var activeCount = active ? Math.max(0, Math.round(Number(active.count || 0))) : totalCount;

        return ({
                enabled: drunCategoryFiltersEnabled === true,
                mode: String(mode || ""),
                showLauncherHome: showLauncherHome === true,
                visible: launcherRoot.showLauncherHome && launcherRoot.drunCategoryFiltersEnabled && launcherRoot.mode === "drun" && launcherRoot.drunCategoryOptions.length > 1,
                activeKey: active ? String(active.key || "") : "",
                activeLabel: active ? String(active.label || "All") : "All",
                activeCount: activeCount,
                totalCount: totalCount,
                options: normalized
            });
    }

    function escapeActionStateObject() {
        var action = "close";
        if (showingConfirm)
            action = "cancelConfirm";
        else if (searchText !== "")
            action = "resetQuery";
        else if (drunCategoryFiltersEnabled && mode === "drun" && drunCategoryFilter !== "")
            action = "resetCategory";

        return ({
                action: action,
                mode: String(mode || ""),
                showingConfirm: showingConfirm === true,
                hasQuery: searchText !== "",
                searchText: String(searchText || ""),
                hasCategoryFilter: drunCategoryFiltersEnabled && mode === "drun" && drunCategoryFilter !== "",
                drunCategoryFilter: String(drunCategoryFilter || "")
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

    function forceRedetectFileSearchBackend(announce, callback) {
        var shouldAnnounce = announce === true;
        fileSearchBackend = "";
        fileSearchBackendResolvedAt = 0;
        invalidateCommandAvailability("fd");
        invalidateCommandAvailability("find");
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
        forceRedetectFileSearchBackend(true, function (_) {});
        showTransientNotice("Launcher diagnostics reset", 2200);
    }

    function loadFiles() {
        var searchQuery = searchText.startsWith("/") ? searchText.substring(1).trim() : searchText;
        if (searchQuery.length < Config.launcherFileMinQueryLength) {
            allItems = [];
            filterItems();
            return;
        }
        var cacheKey = String(searchQuery).toLowerCase();
        var cachedItems = getFileQueryCached(cacheKey);
        if (cachedItems) {
            allItems = cachedItems;
            filterItems();
            recordLoadMetric("files", 0, true, true);
            return;
        }
        var token = beginRequest("files");
        var startedAt = Date.now();
        var homeDir = Quickshell.env("HOME") || "/";
        var maxResults = Math.max(20, Config.launcherFileMaxResults);
        resolveFileSearchBackend(function (backend) {
            if (!isRequestCurrent("files", token))
                return;
            if (backend === "none") {
                setModeHint("Dependency missing", "Install 'fd' or 'find' to use Files mode.", "󰋼");
                recordLoadMetric("files", Date.now() - startedAt, false, false);
                return;
            }

            var command = [];
            if (backend === "fd") {
                command = ["fd", "--base-directory", homeDir, "--max-results", String(maxResults), searchQuery];
            } else {
                var script = "find " + shellQuote(homeDir) + " -mindepth 1 -maxdepth 6 -iname '*" + searchQuery.replace(/'/g, "'\\''") + "*' 2>/dev/null | head -n " + maxResults;
                command = ["bash", "-lc", script];
            }

            runCommand(command, function (raw) {
                if (!isRequestCurrent("files", token))
                    return;
                var tookMs = Date.now() - startedAt;
                recordFilesBackendLoad(backend, tookMs);
                var items = buildFileItemsFromRaw(raw, homeDir);
                allItems = items;
                setFileQueryCached(cacheKey, items);
                filterItems();
                recordLoadMetric("files", tookMs, false, true);
            });
        });
    }

    function loadAi() {
        var query = searchText.startsWith("!") ? searchText.substring(1).trim() : searchText;
        if (query.length < 3) {
            allItems = [];
            filterItems();
            return;
        }
        allItems = [
            {
                name: "Thinking...",
                isHint: true,
                icon: "󰚩"
            }
        ];
        filterItems();
        var token = beginRequest("ai");
        var startedAt = Date.now();
        runCommand(["qs-ai", query], function (raw) {
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
            recordLoadMetric("ai", Date.now() - startedAt, false, true);
        });
    }

    function loadWeb() {
        allItems = configuredWebProviders();
        filterItems();
        applyRememberedWebProviderSelection();
    }

    function loadPlugins() {
        allItems = PluginService.queryLauncherItems(searchText, true);
        filterItems();
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
                action: (function(tId) { 
                    return function() {
                        Quickshell.execDetached(["quickshell", "ipc", "call", "SettingsHub", "openTab", tId]);
                        close();
                    }
                })(tab.id),
                _keywords: (tab.searchTerms || []).join(" ")
            });
        }
        allItems = items;
        filterItems();
    }

    function loadDevOps() {
        var items = [];
        
        // Docker Containers
        var containers = ServiceUnitService.dockerContainers;
        for (var i = 0; i < containers.length; i++) {
            var c = containers[i];
            items.push({
                category: "Docker",
                name: c.name,
                description: c.status + " (" + c.image + ")",
                icon: "󰡨",
                action: (function(id, state) {
                    return function() {
                        ServiceUnitService.runDockerAction(id, state === "running" ? "stop" : "start");
                        close();
                    }
                })(c.id, c.state)
            });
        }

        // SSH Sessions
        var ssh = ServiceUnitService.sshSessions;
        for (var j = 0; j < ssh.length; j++) {
            items.push({
                category: "SSH",
                name: ssh[j],
                icon: "󰣀",
                action: function() { close(); } // Just info for now
            });
        }

        // System Services
        var units = ServiceUnitService.userUnits;
        for (var k = 0; k < units.length; k++) {
            var u = units[k];
            if (u.active === "active" || u.name.indexOf("quickshell") !== -1) {
                items.push({
                    category: "Service",
                    name: u.name.replace(".service", ""),
                    icon: u.active === "active" ? "󰄬" : "󰅚",
                    action: (function(name) {
                        return function() {
                            ServiceUnitService.restartUnit("user", name);
                            close();
                        }
                    })(u.name)
                });
            }
        }

        allItems = items;
        filterItems();
    }

    function loadSystem() {
        var items = [];
        var powerActions = SystemActionRegistry.sessionActions;
        var controlActions = SystemActionRegistry.shellEntryActions;
        for (var i = 0; i < powerActions.length; ++i) {
            var action = powerActions[i];
            var item = {
                category: action.category,
                name: action.name,
                title: action.title,
                icon: action.icon
            };
            if (action.ipcTarget && action.ipcAction) {
                item.ipcTarget = action.ipcTarget;
                item.ipcAction = action.ipcAction;
            } else if (action.danger) {
                item.action = makeConfirmedSystemAction(action.title, action.cmd);
            } else {
                item.action = makeDetachedSystemAction(action.cmd);
            }
            items.push(item);
        }
        items = items.concat([
            {
                category: "Capture",
                name: "Screenshot (Area)",
                icon: "󰹑",
                action: () => Quickshell.execDetached(["screenshot.sh", "area", "--satty"])
            },
            {
                category: "Capture",
                name: "Screenshot (Display)",
                icon: "󰍹",
                action: () => Quickshell.execDetached(["screenshot.sh", "screen", "--satty"])
            },
            {
                category: "Capture",
                name: "Color Picker",
                icon: "󰏘",
                action: () => Quickshell.execDetached(["hyprpicker", "-a"])
            },
            {
                category: "Toggles",
                name: "Toggle Bluetooth",
                icon: "󰂯",
                action: () => {
                    if (Bluetooth.defaultAdapter)
                        Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
                }
            },
            {
                category: "Toggles",
                name: "Toggle Night Light",
                icon: "󰖔",
                action: () => Quickshell.execDetached(["os-toggle-nightlight"])
            }
        ]);
        for (var j = 0; j < controlActions.length; ++j) {
            var control = controlActions[j];
            items.push({
                category: control.category,
                name: control.name,
                title: control.title,
                icon: control.icon,
                ipcTarget: control.ipcTarget,
                ipcAction: control.ipcAction
            });
        }
        items = items.concat([
            {
                category: "Utilities",
                name: "System Monitor (btop)",
                icon: "󰄨",
                action: () => Quickshell.execDetached(["kitty", "-e", "btop"])
            },
            {
                category: "Utilities",
                name: "Audio Settings",
                icon: "󰕾",
                action: () => Quickshell.execDetached(["kitty", "-e", "wiremix"])
            }
        ]);
        allItems = items;
        filterItems();
    }

    function loadNixos() {
        allItems = [
            {
                category: "System",
                name: "Rebuild Switch (flake)",
                icon: "󰒓",
                action: () => Quickshell.execDetached(["kitty", "-e", "sudo", "nixos-rebuild", "switch", "--flake", ".#"])
            },
            {
                category: "System",
                name: "Update Flake Locks",
                icon: "󰚰",
                action: () => Quickshell.execDetached(["kitty", "-e", "nix", "flake", "update"])
            },
            {
                category: "System",
                name: "Collect Garbage",
                icon: "󰃢",
                action: () => Quickshell.execDetached(["kitty", "-e", "sudo", "nix-env", "--delete-generations", "old"])
            },
            {
                category: "Information",
                name: "System Generations",
                icon: "󰋚",
                action: () => Quickshell.execDetached(["kitty", "-e", "sudo", "nix-env", "-p", "/nix/var/nix/profiles/system", "--list-generations"])
            }
        ];
        runCommand(["nixos-version"], function (raw) {
            var ver = raw.trim();
            if (ver && mode === "nixos") {
                allItems.unshift({
                    category: "Information",
                    name: "Current Version: " + ver,
                    icon: "",
                    action: null
                });
                filterItems();
            }
        });
        filterItems();
    }

    function loadWindows() {
        var items = [];
        try {
            for (var i = 0; i < availableToplevels.length; i++) {
                var win = availableToplevels[i];
                if (!win)
                    continue;
                var cls = win.class || win.appId || "";
                items.push({
                    name: win.title || cls || "Window",
                    title: cls || "",
                    icon: "󱗼",
                    class: cls,
                    toplevel: win
                });
            }
        } catch (e) {
            console.error("Error loading windows: " + e);
        }
        allItems = items;
        filterItems();
    }

    function highlightMatch(fullText, query) {
        if (!query || !fullText)
            return fullText;
        var cleanQuery = stripModePrefix(query);
        if (!cleanQuery)
            return fullText;
        var idx = fullText.toLowerCase().indexOf(cleanQuery.toLowerCase());
        if (idx === -1)
            return fullText;
        return fullText.substring(0, idx) + "<b>" + fullText.substring(idx, idx + cleanQuery.length) + "</b>" + fullText.substring(idx + cleanQuery.length);
    }

    function fuzzyMatchLower(s, p) {
        if (!p)
            return 100;
        if (!s)
            return 0;
        if (!p)
            return 100;
        if (s.startsWith(p))
            return 100 + (p.length / s.length);
        if (s.indexOf(p) !== -1)
            return 50 + (p.length / s.length);
        var pIdx = 0;
        var sIdx = 0;
        while (sIdx < s.length && pIdx < p.length) {
            if (s[sIdx] === p[pIdx])
                pIdx++;
            sIdx++;
        }
        if (pIdx === p.length)
            return 10 + (p.length / s.length);
        return 0;
    }

    function ensureItemRankCache(item) {
        if (!item || item._rankCacheReady)
            return;
        item._nameLower = item.name ? String(item.name).toLowerCase() : "";
        item._titleLower = item.title ? String(item.title).toLowerCase() : "";
        item._execLower = item.exec ? String(item.exec).toLowerCase() : (item.class ? String(item.class).toLowerCase() : "");
        item._bodyLower = item.body ? String(item.body).toLowerCase() : "";
        var category = item.category ? String(item.category).toLowerCase() : "";
        var keywords = item.keywords ? String(item.keywords).toLowerCase() : "";
        var tokens = [];
        var rawTokens = category.split(/[\s;,/|]+/);
        for (var i = 0; i < rawTokens.length; ++i) {
            var token = String(rawTokens[i] || "").trim();
            if (token === "")
                continue;
            if (tokens.indexOf(token) === -1)
                tokens.push(token);
        }
        item._categoryTokens = tokens;
        item._primaryCategoryKey = tokens.length > 0 ? tokens[0] : "";
        item._categoryKeywordsLower = (category + " " + keywords).trim();
        item._rankCacheReady = true;
    }

    function rankItem(item, clean, cleanLower) {
        if (clean === "")
            return 1;
        ensureItemRankCache(item);
        var categoryScore = mode === "drun" ? (fuzzyMatchLower(item._categoryKeywordsLower, cleanLower) * Config.launcherScoreCategoryWeight) : 0;
        var bestScore = Math.max(fuzzyMatchLower(item._nameLower, cleanLower) * Config.launcherScoreNameWeight, fuzzyMatchLower(item._titleLower, cleanLower) * Config.launcherScoreTitleWeight, fuzzyMatchLower(item._execLower, cleanLower) * Config.launcherScoreExecWeight, fuzzyMatchLower(item._bodyLower, cleanLower) * Config.launcherScoreBodyWeight, categoryScore);
        if (mode === "drun") {
            // Blend raw frequency (legacy) with decay-weighted usage score
            var rawFreq = (appFrequency[item.exec] || 0) * 0.3;
            var decayScore = UsageTrackerService.getUsageScore(item.exec) * 1.5;
            bestScore += Math.max(rawFreq, decayScore);
        }
        return bestScore;
    }

    function compareLauncherItemsAlpha(a, b) {
        var aName = String(a && a.name ? a.name : "");
        var bName = String(b && b.name ? b.name : "");
        var byName = aName.localeCompare(bName);
        if (byName !== 0)
            return byName;
        var aExec = String(a && a.exec ? a.exec : "");
        var bExec = String(b && b.exec ? b.exec : "");
        var byExec = aExec.localeCompare(bExec);
        if (byExec !== 0)
            return byExec;
        var aTitle = String(a && a.title ? a.title : "");
        var bTitle = String(b && b.title ? b.title : "");
        return aTitle.localeCompare(bTitle);
    }

    function filterItems() {
        var startedAt = Date.now();
        var actualSearch = searchText;
        var webContext = null;
        if (mode === "calc") {
            actualSearch = searchText.startsWith("=") ? searchText.substring(1).trim() : searchText;
            try {
                if (actualSearch !== "") {
                    var result = eval(actualSearch.replace(/[^-+/*() .0-9]/g, ""));
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
            filteredItems = allItems.slice(0, Config.launcherMaxResults);
            selectedIndex = Math.min(selectedIndex, Math.max(0, filteredItems.length - 1));
            recordFilterMetric(Date.now() - startedAt);
            return;
        }

        if (mode === "run" && searchText.startsWith(">"))
            actualSearch = searchText.substring(1).trim();
        if (mode === "emoji" && searchText.startsWith(":"))
            actualSearch = searchText.substring(1).trim();
        if (mode === "web") {
            webContext = parseWebQuery(searchText);
            actualSearch = webContext.query;
        }
        if (mode === "ai" && searchText.startsWith("!"))
            actualSearch = searchText.substring(1).trim();
        if (mode === "files" && searchText.startsWith("/"))
            actualSearch = searchText.substring(1).trim();
        if (mode === "bookmarks" && searchText.startsWith("@"))
            actualSearch = searchText.substring(1).trim();
        if (mode === "settings" && searchText.startsWith(","))
            actualSearch = searchText.substring(1).trim();

        var clean = String(actualSearch || "");
        var cleanLower = clean.toLowerCase();

        if (clean === "" && mode !== "files" && mode !== "ai") {
            filteredItems = allItems;
        } else {
            var scoredItems = [];
            for (var i = 0; i < allItems.length; i++) {
                var item = allItems[i];
                if (mode === "web") {
                    var webItem = Object.assign({}, item);
                    webItem.title = "Search " + item.name + " for '" + clean + "'";
                    webItem.query = clean;
                    scoredItems.push(webItem);
                    continue;
                }
                var bestScore = rankItem(item, clean, cleanLower);
                if (bestScore > 0 || (clean === "" && (mode === "files" || mode === "ai"))) {
                    if (mode === "drun" && drunCategoryFilter !== "" && !itemMatchesDrunCategory(item, drunCategoryFilter))
                        continue;
                    item._score = bestScore;
                    scoredItems.push(item);
                }
            }
            if (mode !== "web" && mode !== "ai" && mode !== "files") {
                scoredItems.sort(function (a, b) {
                    if (b._score !== a._score)
                        return b._score - a._score;
                    if (mode === "drun") {
                        var usageDelta = UsageTrackerService.getUsageScore(b.exec) - UsageTrackerService.getUsageScore(a.exec);
                        if (Math.abs(usageDelta) > 0.01)
                            return usageDelta > 0 ? 1 : -1;
                    }
                    return compareLauncherItemsAlpha(a, b);
                });
            } else if (mode === "files") {
                scoredItems.sort(function (a, b) {
                    if (b._score !== a._score)
                        return b._score - a._score;
                    var aPath = a.fullPath || a.title || "";
                    var bPath = b.fullPath || b.title || "";
                    return aPath.localeCompare(bPath);
                });
            } else if (mode === "ai") {
                scoredItems.sort(function (a, b) {
                    if (b._score !== a._score)
                        return b._score - a._score;
                    return 0;
                });
            }
            filteredItems = scoredItems.slice(0, Config.launcherMaxResults);
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
        _lastFilterTriggerMs = Date.now();
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
        Quickshell.execDetached(["bash", "-lc", "printf %s " + shellQuote(text) + " | wl-copy"]);
    }

    function launchExecString(execString, runInTerminal) {
        if (!execString || String(execString).trim() === "")
            return;
        if (runInTerminal) {
            Quickshell.execDetached(["kitty", "-e", "bash", "-lc", String(execString)]);
            return;
        }
        Quickshell.execDetached(["bash", "-lc", String(execString)]);
    }

    function itemActionLabel(item) {
        if (!item || item.isHint)
            return "";
        if (mode === "clip" || mode === "emoji" || mode === "calc" || mode === "ai")
            return "Copy";
        if (mode === "window")
            return "Focus";
        if (mode === "files" || mode === "web" || mode === "bookmarks" || mode === "wallpapers")
            return "Open";
        if (mode === "drun" || mode === "run")
            return "Run";
        if (mode === "system" || mode === "nixos" || mode === "keybinds" || mode === "media" || mode === "plugins")
            return "Action";
        return "";
    }

    function itemProviderLabel(item) {
        if (!item || item.isHint)
            return "";
        if (mode === "web")
            return item.name || "";
        if (mode === "bookmarks") {
            var raw = String(item.exec || "");
            var match = raw.match(/^https?:\/\/([^\/?#]+)/i);
            return match && match.length > 1 ? match[1] : "";
        }
        return "";
    }

    function executeEmptyPrimary() {
        var clean = stripModePrefix(searchText).trim();
        if (mode === "files") {
            Quickshell.execDetached(["xdg-open", Quickshell.env("HOME") || "/"]);
            close();
            return;
        }
        if (mode === "web") {
            var webCtx = parseWebQuery(searchText);
            var primary = configuredWebProviderByKey(webCtx.providerKey) || primaryWebProvider();
            var url = primary ? String(primary.home || "") : "";
            if (url === "")
                url = "https://duckduckgo.com/";
            if (webCtx.query !== "" && primary && primary.exec)
                url = String(primary.exec) + encodeURIComponent(webCtx.query);
            Quickshell.execDetached(["xdg-open", url]);
            close();
            return;
        }
        if (mode === "ai" && clean.length >= 3) {
            loadAi();
            return;
        }
        if (mode === "run" && clean !== "") {
            launchExecString(clean, false);
            close();
            return;
        }
        if (mode === "bookmarks") {
            open("web", true);
            return;
        }
        if (mode === "plugins") {
            open("drun");
            return;
        }
        open("drun");
    }

    function executeEmptySecondary() {
        var clean = stripModePrefix(searchText).trim();
        if (mode === "files") {
            var target = Quickshell.env("HOME") || "/";
            if (clean.startsWith("~")) {
                target = (Quickshell.env("HOME") || "/") + clean.substring(1);
            } else if (clean.startsWith("/")) {
                target = clean;
            }
            Quickshell.execDetached(["xdg-open", target]);
            close();
            return;
        }
        if (mode === "web") {
            var secondary = secondaryWebProvider();
            var secondaryUrl = secondary ? String(secondary.home || "") : "";
            if (secondaryUrl === "")
                secondaryUrl = "https://www.google.com/";
            if (clean !== "" && secondary && secondary.exec)
                secondaryUrl = String(secondary.exec) + encodeURIComponent(clean);
            Quickshell.execDetached(["xdg-open", secondaryUrl]);
            close();
            return;
        }
        if (mode === "system") {
            runShellEntryAction("commandCenter");
            close();
            return;
        }
        if (mode === "run") {
            if (clean !== "") {
                launchExecString(clean, true);
            } else {
                Quickshell.execDetached(["kitty"]);
            }
            close();
            return;
        }
        clearSearchQuery();
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
        if (key === Qt.Key_1)
            return 1;
        if (key === Qt.Key_2)
            return 2;
        if (key === Qt.Key_3)
            return 3;
        if (key === Qt.Key_4)
            return 4;
        if (key === Qt.Key_5)
            return 5;
        if (key === Qt.Key_6)
            return 6;
        if (key === Qt.Key_7)
            return 7;
        if (key === Qt.Key_8)
            return 8;
        if (key === Qt.Key_9)
            return 9;
        return 0;
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

    function activateFeatured(item) {
        if (item.openMode) {
            open(item.openMode);
            return;
        }
        if (item.ipcTarget && item.ipcAction) {
            Quickshell.execDetached(["quickshell", "ipc", "call", item.ipcTarget, item.ipcAction]);
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

        if (mode === "drun") {
            trackLaunch(item);
            launchExecString(item.exec, item.terminal === "true" || item.terminal === "True");
            close();
        } else if (mode === "run") {
            rememberRecent({
                name: item.name || item.exec,
                title: item.exec || "",
                icon: "󰆍",
                exec: item.exec || ""
            });
            if (item.exec)
                Quickshell.execDetached(["bash", "-c", item.exec]);
            close();
        } else if (mode === "window") {
            rememberRecent({
                name: item.name || item.title || "Window",
                title: item.title || item.class || "",
                icon: "󱗼",
                openMode: "window"
            });
            if (item.toplevel && item.toplevel.activate)
                item.toplevel.activate();
            close();
        } else if (mode === "dmenu") {
            var fifoPath = "/tmp/qs-dmenu-result";
            Quickshell.execDetached(["bash", "-c", "echo " + shellQuote(item.name) + " > " + shellQuote(fifoPath)]);
            close();
        } else if (mode === "emoji" || mode === "calc") {
            copyToClipboard(item.name);
            close();
        } else if (mode === "clip") {
            if (item.id) {
                Quickshell.execDetached(["bash", "-lc", "cliphist decode " + shellQuote(item.id) + " | wl-copy"]);
                close();
            }
        } else if (mode === "web" || mode === "bookmarks") {
            rememberRecent({
                name: item.name || "Link",
                title: item.title || item.exec || "",
                icon: item.icon || "󰖟",
                exec: item.exec || ""
            });
            if (item.exec) {
                Quickshell.execDetached(["xdg-open", item.exec + (item.query ? encodeURIComponent(item.query) : "")]);
                close();
            }
        } else if (mode === "ai") {
            if (item.body) {
                copyToClipboard(item.body);
                close();
            }
        } else if (mode === "files") {
            if (!item.isHint && item.fullPath) {
                rememberRecent({
                    name: item.name || item.fullPath,
                    title: item.fullPath,
                    icon: "󰈔",
                    fullPath: item.fullPath
                });
                Quickshell.execDetached(["xdg-open", item.fullPath]);
                close();
            }
        } else if (mode === "system" || mode === "nixos") {
            rememberRecent({
                name: item.name || "Action",
                title: item.category || item.title || "",
                icon: item.icon || "󰒓",
                exec: item.exec || ""
            });
            if (item.ipcTarget && item.ipcAction)
                Quickshell.execDetached(["quickshell", "ipc", "call", item.ipcTarget, item.ipcAction]);
            else if (item.action)
                item.action();
            if (!showingConfirm)
                close();
        } else if (mode === "wallpapers") {
            Quickshell.execDetached(["swww", "img", item.path, "--transition-type", "grow", "--transition-pos", "0.5,0.5", "--transition-duration", "1.5"]);
            Quickshell.execDetached(["wallust", "run", item.path]);
            close();
        } else if (mode === "keybinds") {
            if (item.disp && CompositorAdapter.supportsDispatcherActions)
                CompositorAdapter.dispatchAction(item.disp, item.args || "", "Trigger keybind action");
            close();
        } else if (mode === "plugins") {
            var executed = PluginService.executeLauncherItem(item, searchText);
            if (executed)
                close();
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
        function drunCategoryState() {
            return JSON.stringify(launcherRoot.drunCategoryStateObject());
        }
        function escapeActionState() {
            return JSON.stringify(launcherRoot.escapeActionStateObject());
        }
        function diagnosticSetSearchText(text: string) {
            return launcherRoot.diagnosticSetSearchText(text);
        }
        function diagnosticSetDrunCategoryFilter(categoryKey: string) {
            return launcherRoot.diagnosticSetDrunCategoryFilter(categoryKey);
        }
        function invokeEscapeAction() {
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
        color: Qt.rgba(0, 0, 0, 0.5)
        opacity: launcherOpacity
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
        width: Math.min(960, Math.max(launcherRoot.sidebarCompact ? 360 : 420, launcherRoot.usableWidth - (launcherRoot.tightMode ? 24 : 40)))
        height: Math.min(760, Math.max(320, launcherRoot.usableHeight - (launcherRoot.tightMode ? 24 : 40)))
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: launcherRoot.edgeMargins.top + Math.max(20, (launcherRoot.usableHeight - height) / 2)
        anchors.leftMargin: launcherRoot.edgeMargins.left + Math.max(20, (launcherRoot.usableWidth - width) / 2)
        color: Colors.bgGlass
        radius: Colors.radiusLarge
        border.color: Colors.border
        border.width: 1
        scale: launcherRoot.scaleValue
        transform: Translate {
            y: launcherRoot.yOffset
        }
        clip: true

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
            anchors.fill: parent
            anchors.margins: launcherRoot.tightMode ? Colors.spacingM : Colors.paddingMedium
            spacing: launcherRoot.compactMode ? Colors.paddingSmall : 18

            LauncherSidebar {
                Layout.preferredWidth: launcherRoot.sidebarCompact ? 76 : Math.max(148, Math.min(210, Math.round(hudBox.width * (launcherRoot.compactMode ? 0.2 : 0.22))))
                Layout.fillHeight: true
                launcher: launcherRoot
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: launcherRoot.compactMode ? Colors.paddingSmall : Colors.paddingMedium

                LauncherSearchField {
                    id: searchInputComp
                    Layout.fillWidth: true
                    text: launcherRoot.searchText
                    accentColor: Colors.primary
                    placeholder: launcherRoot.modeMeta[launcherRoot.mode] ? launcherRoot.modeMeta[launcherRoot.mode].hint : "Search..."

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
                                searchInputComp.searchInput.focus = false 
                        }
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            if (launcherRoot.handleEscapeAction())
                                event.accepted = true;
                        } else if ((event.modifiers & Qt.ControlModifier) && !(event.modifiers & Qt.AltModifier) && (event.key === Qt.Key_L || event.key === Qt.Key_U)) {
                            launcherRoot.clearSearchQuery();
                            event.accepted = true;
                        } else if (Config.launcherWebNumberHotkeysEnabled && launcherRoot.mode === "web" && (event.modifiers & Qt.ControlModifier) && !(event.modifiers & Qt.AltModifier) && !(event.modifiers & Qt.ShiftModifier)) {
                            var openSlot = launcherRoot.webProviderSlotFromKey(event.key);
                            if (openSlot > 0 && launcherRoot.executeWebProviderBySlot(openSlot))
                                event.accepted = true;
                        } else if (Config.launcherWebNumberHotkeysEnabled && launcherRoot.mode === "web" && (event.modifiers & Qt.AltModifier) && !(event.modifiers & Qt.ControlModifier)) {
                            var slot = launcherRoot.webProviderSlotFromKey(event.key);
                            if (slot > 0 && launcherRoot.selectWebProviderBySlot(slot))
                                event.accepted = true;
                        } else if (launcherRoot.drunCategoryFiltersEnabled && launcherRoot.mode === "drun" && (event.modifiers & Qt.AltModifier) && !(event.modifiers & Qt.ControlModifier)) {
                            if (event.key === Qt.Key_Left) {
                                if (launcherRoot.cycleDrunCategoryFilter(-1))
                                    event.accepted = true;
                            } else if (event.key === Qt.Key_Right) {
                                if (launcherRoot.cycleDrunCategoryFilter(1))
                                    event.accepted = true;
                            } else if (event.key === Qt.Key_PageUp) {
                                if (launcherRoot.cycleDrunCategoryFilter(-1))
                                    event.accepted = true;
                            } else if (event.key === Qt.Key_PageDown) {
                                if (launcherRoot.cycleDrunCategoryFilter(1))
                                    event.accepted = true;
                            } else if (event.key === Qt.Key_Home) {
                                if (launcherRoot.jumpDrunCategoryBoundary(false))
                                    event.accepted = true;
                            } else if (event.key === Qt.Key_End) {
                                if (launcherRoot.jumpDrunCategoryBoundary(true))
                                    event.accepted = true;
                            } else if (event.key === Qt.Key_0 || event.key === Qt.Key_Backspace) {
                                if (launcherRoot.setDrunCategoryFilter(""))
                                    event.accepted = true;
                            } else {
                                var categorySlot = launcherRoot.webProviderSlotFromKey(event.key);
                                if (categorySlot > 0 && launcherRoot.selectDrunCategorySlot(categorySlot))
                                    event.accepted = true;
                            }
                        } else if (launcherRoot.drunCategoryFiltersEnabled && launcherRoot.mode === "drun" && launcherRoot.showLauncherHome && (event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Tab) {
                            var direction = (event.modifiers & Qt.ShiftModifier) ? -1 : 1;
                            if (launcherRoot.cycleDrunCategoryFilter(direction))
                                event.accepted = true;
                        } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                            launcherRoot.cycleMode(-1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Tab) {
                            if (launcherRoot.launcherTabBehavior === "mode")
                                launcherRoot.cycleMode(1);
                            else if (launcherRoot.launcherTabBehavior === "results")
                                launcherRoot.cycleSelection(1);
                            else if (launcherRoot.filteredItems.length > 0)
                                launcherRoot.cycleSelection(1);
                            else
                                launcherRoot.cycleMode(1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if ((event.modifiers & Qt.ControlModifier) && launcherRoot.mode === "web" && launcherRoot.filteredItems.length > 0)
                                launcherRoot.openSelectedWebHomepage();
                            else if (launcherRoot.mode === "web" && launcherRoot.filteredItems.length > 0 && !(event.modifiers & Qt.ShiftModifier) && Config.launcherWebEnterUsesPrimary)
                                launcherRoot.executePrimaryWebSearch();
                            else if ((event.modifiers & Qt.ShiftModifier) && launcherRoot.filteredItems.length === 0 && launcherRoot.emptySecondaryCta !== "")
                                launcherRoot.executeEmptySecondary();
                            else if (launcherRoot.mode === "ai" && launcherRoot.filteredItems.length === 0)
                                launcherRoot.loadAi();
                            else if (launcherRoot.mode === "files" && launcherRoot.stripModePrefix(launcherRoot.searchText).trim().length >= Config.launcherFileMinQueryLength && launcherRoot.filteredItems.length === 0)
                                launcherRoot.loadFiles();
                            else if (launcherRoot.filteredItems.length === 0)
                                launcherRoot.executeEmptyPrimary();
                            else
                                launcherRoot.executeSelection();
                        } else if ((event.modifiers & Qt.ControlModifier) && !(event.modifiers & Qt.AltModifier) && event.key === Qt.Key_P) {
                            if (launcherRoot.moveSelectionRelative(-1))
                                event.accepted = true;
                        } else if ((event.modifiers & Qt.ControlModifier) && !(event.modifiers & Qt.AltModifier) && event.key === Qt.Key_N) {
                            if (launcherRoot.moveSelectionRelative(1))
                                event.accepted = true;
                        } else if (event.key === Qt.Key_Up) {
                            if (launcherRoot.moveSelectionRelative(-1))
                                event.accepted = true;
                        } else if (event.key === Qt.Key_Down) {
                            if (launcherRoot.moveSelectionRelative(1))
                                event.accepted = true;
                        } else if (event.key === Qt.Key_PageUp) {
                            if (launcherRoot.pageSelection(-1))
                                event.accepted = true;
                        } else if (event.key === Qt.Key_PageDown) {
                            if (launcherRoot.pageSelection(1))
                                event.accepted = true;
                        } else if (event.key === Qt.Key_Home) {
                            if (launcherRoot.jumpSelectionBoundary(false))
                                event.accepted = true;
                        } else if (event.key === Qt.Key_End) {
                            if (launcherRoot.jumpSelectionBoundary(true))
                                event.accepted = true;
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Colors.paddingSmall
                    visible: Config.launcherShowModeHints && !launcherRoot.tightMode
                    Text {
                        Layout.fillWidth: true
                        text: launcherRoot.modeInfo(launcherRoot.mode).hint
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeSmall
                        elide: Text.ElideRight
                    }
                    Row {
                        spacing: Colors.spacingXS

                        Rectangle {
                            radius: Colors.radiusPill
                            color: Colors.withAlpha(Colors.primary, 0.12)
                            border.color: Colors.withAlpha(Colors.primary, 0.3)
                            border.width: 1
                            implicitHeight: 24
                            implicitWidth: footerPrimaryText.implicitWidth + 14

                            Text {
                                id: footerPrimaryText
                                anchors.centerIn: parent
                                text: launcherRoot.legendPrimaryAction
                                color: Colors.primary
                                font.pixelSize: Colors.fontSizeXS
                                font.weight: Font.DemiBold
                            }
                        }

                        Rectangle {
                            radius: Colors.radiusPill
                            color: Colors.withAlpha(Colors.textSecondary, 0.08)
                            border.color: Colors.withAlpha(Colors.primary, 0.14)
                            border.width: 1
                            implicitHeight: 24
                            implicitWidth: footerSecondaryText.implicitWidth + 14

                            Text {
                                id: footerSecondaryText
                                anchors.centerIn: parent
                                text: launcherRoot.legendSecondaryAction
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeXS
                                font.weight: Font.DemiBold
                            }
                        }

                        Rectangle {
                            radius: Colors.radiusPill
                            color: Colors.surface
                            border.color: Colors.withAlpha(Colors.primary, 0.12)
                            border.width: 1
                            implicitHeight: 24
                            implicitWidth: footerTertiaryText.implicitWidth + 14

                            Text {
                                id: footerTertiaryText
                                anchors.centerIn: parent
                                text: launcherRoot.legendTertiaryAction
                                color: Colors.textDisabled
                                font.pixelSize: Colors.fontSizeXS
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    visible: launcherRoot.mode === "web" && launcherRoot.filteredItems.length > 0
                    color: Colors.bgWidget
                    radius: Colors.radiusMedium
                    border.color: Colors.border
                    border.width: 1
                    implicitHeight: providerFlowContainer.implicitHeight + (Colors.spacingM * 2)

                    Column {
                        id: providerFlowContainer
                        anchors.fill: parent
                        anchors.margins: Colors.spacingM
                        spacing: Colors.spacingXS

                        Text {
                            color: Colors.textDisabled
                            font.pixelSize: Colors.fontSizeXS
                            font.weight: Font.Bold
                            text: "PROVIDERS"
                        }

                        Flow {
                            width: parent.width
                            spacing: Colors.spacingS

                            Repeater {
                                model: launcherRoot.configuredWebProviders()

                                delegate: Rectangle {
                                    required property var modelData

                                    readonly property bool selected: String(modelData.key || "") === launcherRoot.selectedWebProviderKey
                                    color: selected ? Colors.withAlpha(Colors.primary, 0.18) : Colors.surface
                                    radius: Colors.radiusPill
                                    border.color: selected ? Colors.withAlpha(Colors.primary, 0.6) : Colors.border
                                    border.width: 1
                                    implicitHeight: 28
                                    implicitWidth: Math.min(providerChipText.implicitWidth + 24, providerFlowContainer.width)

                                    Text {
                                        id: providerChipText
                                        anchors.centerIn: parent
                                        width: Math.min(implicitWidth, parent.width - 18)
                                        text: (modelData.icon || "󰖟") + " " + (modelData.name || "")
                                        color: parent.selected ? Colors.primary : Colors.textSecondary
                                        font.pixelSize: Colors.fontSizeXS
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: launcherRoot.selectWebProviderByKey(String(modelData.key || ""))
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    visible: Config.launcherShowModeHints && launcherRoot.mode === "web" && !launcherRoot.tightMode
                    color: Colors.bgWidget
                    radius: Colors.radiusMedium
                    border.color: Colors.border
                    border.width: 1
                    implicitHeight: webHintColumn.implicitHeight + (Colors.spacingS * 2)

                    Column {
                        id: webHintColumn
                        anchors.fill: parent
                        anchors.margins: Colors.spacingS
                        spacing: launcherRoot.webHintCompact ? 3 : Colors.spacingXS

                        Row {
                            width: parent.width
                            spacing: Colors.spacingS

                            Text {
                                text: "󰖟"
                                color: Colors.primary
                                font.family: Colors.fontMono
                                font.pixelSize: Colors.fontSizeSmall
                            }
                            Text {
                                width: parent.width - x
                                text: launcherRoot.webPrimaryEnterHint + " • " + launcherRoot.webSecondaryEnterHint + " • " + launcherRoot.webAliasHint
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeXS
                                wrapMode: Text.WordWrap
                            }
                        }

                        Text {
                            width: parent.width
                            text: launcherRoot.webHotkeyHint
                            color: Colors.textDisabled
                            font.pixelSize: Colors.fontSizeXS
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    visible: launcherRoot.transientNoticeText !== "" && !launcherRoot.tightMode
                    color: Colors.withAlpha(Colors.primary, 0.12)
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
                    Layout.fillWidth: true
                    visible: Config.launcherShowRuntimeMetrics && !launcherRoot.tightMode
                    color: Colors.bgWidget
                    radius: Colors.radiusMedium
                    border.color: Colors.border
                    border.width: 1
                    implicitHeight: 74

                    RowLayout {
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
                                text: "opens " + launcherRoot.launcherMetrics.opens + " • cache " + launcherRoot.launcherMetrics.cacheHits + "/" + launcherRoot.launcherMetrics.cacheMisses + " • failures " + launcherRoot.launcherMetrics.commandFailures + " • filter avg " + (launcherRoot.launcherMetrics.avgFilterMs || 0) + "ms" + " / last " + (launcherRoot.launcherMetrics.lastFilterMs || 0) + "ms" + (launcherRoot.mode === "files" ? (" • backend " + launcherRoot.filesBackendLabel + " • fd/find " + (launcherRoot.launcherMetrics.filesFdLoads || 0) + "/" + (launcherRoot.launcherMetrics.filesFindLoads || 0) + " • fd " + (launcherRoot.launcherMetrics.filesFdAvgMs || 0) + "/" + (launcherRoot.launcherMetrics.filesFdLastMs || 0) + "ms" + " • find " + (launcherRoot.launcherMetrics.filesFindAvgMs || 0) + "/" + (launcherRoot.launcherMetrics.filesFindLastMs || 0) + "ms" + " • resolve " + (launcherRoot.launcherMetrics.filesResolveAvgMs || 0) + "/" + (launcherRoot.launcherMetrics.filesResolveLastMs || 0) + "ms") : "")
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeXS
                                elide: Text.ElideRight
                            }
                            Text {
                                readonly property var modeStats: launcherRoot.modeMetric(launcherRoot.mode)
                                text: launcherRoot.modeInfo(launcherRoot.mode).label + ": avg " + modeStats.avgLoadMs + "ms" + " • last " + modeStats.lastLoadMs + "ms" + " • failures " + modeStats.failures + (launcherRoot.mode === "files" ? (" • cache " + launcherRoot.filesCacheStatsLabel) : "")
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeXS
                                elide: Text.ElideRight
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
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: mode === "media" ? 1 : 0

                    StackLayout {
                        currentIndex: launcherRoot.filteredItems.length > 0 ? 0 : 1

                        ListView {
                            id: resultsList
                            model: launcherRoot.filteredItems
                            clip: true
                            spacing: launcherRoot.compactMode ? Colors.spacingXS : Colors.spacingS
                            currentIndex: launcherRoot.selectedIndex
                            enabled: !launcherRoot.showingConfirm
                            section.property: "category"
                            section.delegate: Text {
                                text: section
                                color: Colors.primary
                                font.pixelSize: Colors.fontSizeXS
                                font.bold: true
                                height: launcherRoot.compactMode ? 21 : 25
                                verticalAlignment: Text.AlignBottom
                            }

                            delegate: LauncherResultDelegate {
                                selectedIndex: launcherRoot.selectedIndex
                                searchText: launcherRoot.searchText
                                mode: launcherRoot.mode
                                compactMode: launcherRoot.compactMode
                                tightMode: launcherRoot.tightMode
                                ignoreMouseHover: launcherRoot.ignoreMouseHover
                                modeIcons: launcherRoot.modeIcons
                                onClicked: launcherRoot.executeSelection()
                                onEntered: if (!launcherRoot.ignoreMouseHover) launcherRoot.selectedIndex = index
                            }
                        }

                        Rectangle {
                            color: Colors.bgWidget
                            radius: Colors.radiusMedium
                            border.color: Colors.border
                            border.width: 1
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: Colors.spacingS
                                Text {
                                    text: launcherRoot.modeIcons[launcherRoot.mode] || "󰈔"
                                    color: Colors.textDisabled
                                    font.family: Colors.fontMono
                                    font.pixelSize: 26
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: launcherRoot.emptyStateTitle
                                    color: Colors.text
                                    font.pixelSize: Colors.fontSizeMedium
                                    font.weight: Font.DemiBold
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: launcherRoot.emptyStateSubtitle
                                    color: Colors.textSecondary
                                    font.pixelSize: Colors.fontSizeSmall
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: Colors.spacingS
                                    Rectangle {
                                        radius: Colors.radiusPill
                                        color: Colors.primary
                                        implicitHeight: 30
                                        implicitWidth: emptyPrimaryText.implicitWidth + 20
                                        Text {
                                            id: emptyPrimaryText
                                            anchors.centerIn: parent
                                            text: launcherRoot.emptyPrimaryCta
                                            color: Colors.text
                                            font.pixelSize: Colors.fontSizeXS
                                            font.weight: Font.DemiBold
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: launcherRoot.executeEmptyPrimary()
                                        }
                                    }
                                    Rectangle {
                                        visible: launcherRoot.emptySecondaryCta !== ""
                                        radius: Colors.radiusPill
                                        color: Colors.surface
                                        border.color: Colors.border
                                        border.width: 1
                                        implicitHeight: 30
                                        implicitWidth: emptySecondaryText.implicitWidth + 20
                                        Text {
                                            id: emptySecondaryText
                                            anchors.centerIn: parent
                                            text: launcherRoot.emptySecondaryCta
                                            color: Colors.text
                                            font.pixelSize: Colors.fontSizeXS
                                            font.weight: Font.DemiBold
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: launcherRoot.executeEmptySecondary()
                                        }
                                    }
                                }
                                RowLayout {
                                    Layout.maximumWidth: Math.min(parent.width - 24, 460)
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: Colors.spacingXS
                                    Text {
                                        text: launcherRoot.emptyPrimaryHintIcon
                                        color: Colors.textDisabled
                                        font.family: Colors.fontMono
                                        font.pixelSize: Colors.fontSizeSmall
                                        visible: text !== ""
                                        Layout.alignment: Qt.AlignTop
                                    }
                                    Text {
                                        text: launcherRoot.emptyPrimaryHint
                                        color: Colors.textDisabled
                                        font.pixelSize: Colors.fontSizeXS
                                        wrapMode: Text.WordWrap
                                        horizontalAlignment: Text.AlignHCenter
                                        Layout.fillWidth: true
                                    }
                                }
                                RowLayout {
                                    visible: launcherRoot.emptySecondaryHint !== ""
                                    Layout.maximumWidth: Math.min(parent.width - 24, 460)
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: Colors.spacingXS
                                    Text {
                                        text: launcherRoot.emptySecondaryHintIcon
                                        color: Colors.textDisabled
                                        font.family: Colors.fontMono
                                        font.pixelSize: Colors.fontSizeSmall
                                        visible: text !== ""
                                        Layout.alignment: Qt.AlignTop
                                    }
                                    Text {
                                        text: launcherRoot.emptySecondaryHint
                                        color: Colors.textDisabled
                                        font.pixelSize: Colors.fontSizeXS
                                        wrapMode: Text.WordWrap
                                        horizontalAlignment: Text.AlignHCenter
                                        Layout.fillWidth: true
                                    }
                                }
                            }
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
