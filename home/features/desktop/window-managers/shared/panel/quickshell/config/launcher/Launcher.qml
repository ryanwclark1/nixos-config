import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import "../services"
import "../widgets" as SharedWidgets

PanelWindow {
  id: launcherRoot

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
    if (visible) Qt.callLater(function() { if (searchInput) searchInput.forceActiveFocus(); });
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
  property var appFrequency: ({})
  property var launchHistory: []
  property var onCommandOutput: null
  property var modeCache: ({})
  property var modeCacheTime: ({})
  property var fileQueryCache: ({})
  property var fileQueryCacheTime: ({})
  property int _lastFilterTriggerMs: 0
  property int openCount: 0
  property int _requestToken: 0
  property var _activeRequests: ({})
  property var commandAvailability: ({})
  property var _commandCheckProcs: ({})
  property var _commandWaiters: ({})
  property var mediaPlayers: []
  property var preloadFailureState: ({})
  property var launcherMetrics: ({
    opens: 0,
    cacheHits: 0,
    cacheMisses: 0,
    commandFailures: 0,
    perMode: ({})
  })

  function refreshMediaPlayers() { mediaPlayers = MediaService.getAvailablePlayers(); }

  // ── Hover anti-flicker ─────────────────────────
  property bool ignoreMouseHover: true
  property bool mouseTrackingReady: false
  property bool globalMouseInitialized: false
  property real globalLastMouseX: 0
  property real globalLastMouseY: 0

  readonly property bool showLauncherHome: Config.launcherShowHomeSections && searchText === "" && (mode === "drun" || mode === "system" || mode === "files")
  readonly property var allKnownModes: ["drun", "window", "files", "ai", "clip", "emoji", "calc", "web", "run", "system", "keybinds", "media", "nixos", "wallpapers", "bookmarks"]
  readonly property var transientModes: ["dmenu"]
  readonly property var defaultModeOrder: ["drun", "window", "files", "ai", "clip", "emoji", "calc", "web", "run", "system", "keybinds", "media", "nixos", "wallpapers", "bookmarks"]
  readonly property var defaultPrimaryModes: ["drun", "window", "files", "ai", "clip", "system", "media"]
  property var modeOrder: computeModeOrder()
  property var primaryModes: sanitizeModeList(Config.launcherEnabledModes, defaultPrimaryModes, allKnownModes)
  readonly property var modeMeta: ({
    "drun": { label: "Apps", hint: "Launch applications", prefix: "" },
    "window": { label: "Windows", hint: "Jump to an open window", prefix: "" },
    "files": { label: "Files", hint: "Search home with /", prefix: "/" },
    "ai": { label: "AI", hint: "Ask with !", prefix: "!" },
    "clip": { label: "Clipboard", hint: "Recent clipboard history", prefix: "" },
    "emoji": { label: "Emoji", hint: "Search with :", prefix: ":" },
    "calc": { label: "Calculator", hint: "Evaluate with =", prefix: "=" },
    "web": { label: "Web", hint: "Search with ?", prefix: "?" },
    "run": { label: "Run", hint: "Run commands with >", prefix: ">" },
    "system": { label: "System", hint: "Session and utility actions", prefix: "" },
    "keybinds": { label: "Keybinds", hint: "Inspect and trigger binds", prefix: "" },
    "media": { label: "Media", hint: "Control active players", prefix: "" },
    "nixos": { label: "NixOS", hint: "Nix maintenance actions", prefix: "" },
    "wallpapers": { label: "Wallpapers", hint: "Pick and apply wallpapers", prefix: "" },
    "bookmarks": { label: "Bookmarks", hint: "Open bookmarked destinations", prefix: "@" }
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
    "run": "󰆍",
    "system": "󰒓",
    "keybinds": "󰌌",
    "media": "󰝚",
    "nixos": "",
    "wallpapers": "󰸉",
    "bookmarks": "󰃀"
  })
  readonly property var webProviderCatalog: ({
    "google": { key: "google", name: "Google", exec: "https://www.google.com/search?q=", home: "https://www.google.com/", icon: "󰊯", isWeb: true },
    "duckduckgo": { key: "duckduckgo", name: "DuckDuckGo", exec: "https://duckduckgo.com/?q=", home: "https://duckduckgo.com/", icon: "󰇥", isWeb: true },
    "youtube": { key: "youtube", name: "YouTube", exec: "https://www.youtube.com/results?search_query=", home: "https://www.youtube.com/", icon: "󰗃", isWeb: true },
    "nixos": { key: "nixos", name: "NixOS Packages", exec: "https://search.nixos.org/packages?query=", home: "https://search.nixos.org/packages", icon: "", isWeb: true },
    "github": { key: "github", name: "GitHub", exec: "https://github.com/search?q=", home: "https://github.com/", icon: "󰊤", isWeb: true }
  })
  readonly property var launcherShortcuts: ({
    "drun": [
      { icon: "󰀻", label: "Applications", description: "Installed desktop apps" },
      { icon: "󱗼", label: "Windows", description: "Focus open clients", openMode: "window" },
      { icon: "󰖩", label: "Networks", description: "Open network menu", ipcTarget: "Shell", ipcAction: "toggleNetworkMenu" },
      { icon: "󰕾", label: "Audio", description: "Open audio menu", ipcTarget: "Shell", ipcAction: "toggleAudioMenu" }
    ],
    "files": [
      { icon: "󰈔", label: "Home Search", description: "Search under your home directory" },
      { icon: "󰚩", label: "Ask AI", description: "Jump to AI mode", openMode: "ai" }
    ],
    "system": [
      { icon: "󰒓", label: "Command Center", description: "Open system hub", ipcTarget: "Shell", ipcAction: "toggleControls" },
      { icon: "󰕾", label: "Audio Controls", description: "Open audio menu", ipcTarget: "Shell", ipcAction: "toggleAudioMenu" },
      { icon: "󰖩", label: "Network Controls", description: "Open network menu", ipcTarget: "Shell", ipcAction: "toggleNetworkMenu" }
    ],
    "media": [
      { icon: "󰝚", label: "Media Players", description: "Control active players" }
    ],
    "window": [
      { icon: "󱗼", label: "Window Switcher", description: "Jump between open clients" }
    ],
    "clip": [
      { icon: "󰅍", label: "Clipboard", description: "Reuse copied text" }
    ],
    "ai": [
      { icon: "󰚩", label: "AI Prompt", description: "Copy result on execute" }
    ]
  })
  readonly property string modePrefixes: "!/@?>=:"
  readonly property string emptyStateTitle: {
    if (mode === "files") return "Type at least " + Config.launcherFileMinQueryLength + " characters to search files";
    if (mode === "ai") return "Describe what you want and press Enter";
    if (mode === "clip") return "Clipboard history is empty";
    if (mode === "window") return "No open windows found";
    return "No results";
  }
  readonly property string emptyStateSubtitle: {
    if (mode === "files") return "Search runs inside your home directory";
    if (mode === "ai") return "The response will be copied to your clipboard";
    if (mode === "clip") return "Copy something to populate clipboard history";
    if (mode === "window") return "Open some applications to see them here";
    return "Try another query or switch modes";
  }
  readonly property string emptyPrimaryCta: {
    var clean = stripModePrefix(searchText).trim();
    var webPrimary = primaryWebProvider();
    var webPrimaryName = webPrimary ? webPrimary.name : "Web";
    if (mode === "files") return "Open Home";
    if (mode === "web") return clean !== "" ? "Search " + webPrimaryName : "Open " + webPrimaryName;
    if (mode === "ai") return clean.length >= 3 ? "Ask AI" : "Switch to Apps";
    if (mode === "run") return clean !== "" ? "Run Command" : "Switch to Apps";
    if (mode === "window") return "Open Apps";
    if (mode === "bookmarks") return "Switch to Web";
    if (mode === "clip") return "Switch to Apps";
    return "Switch to Apps";
  }
  readonly property string emptySecondaryCta: {
    var clean = stripModePrefix(searchText).trim();
    var webSecondary = secondaryWebProvider();
    var webSecondaryName = webSecondary ? webSecondary.name : "Google";
    if (mode === "files") return "Open Folder";
    if (mode === "web") return clean !== "" ? "Search " + webSecondaryName : "Open " + webSecondaryName;
    if (mode === "system") return "Open Controls";
    if (mode === "run") return clean !== "" ? "Run In Terminal" : "Open Terminal";
    return searchText !== "" ? "Clear Query" : "";
  }
  readonly property string emptyPrimaryHint: {
    var clean = stripModePrefix(searchText).trim();
    var webPrimary = primaryWebProvider();
    var webPrimaryName = webPrimary ? webPrimary.name : "default provider";
    if (mode === "files") return "Open your home directory in the default file manager.";
    if (mode === "web") return clean !== "" ? "Search " + webPrimaryName + " using the current query." : "Open " + webPrimaryName + " homepage.";
    if (mode === "ai") return clean.length >= 3 ? "Send prompt to AI helper and show copyable result." : "Switch back to app launcher mode.";
    if (mode === "run") return clean !== "" ? "Execute command directly in shell." : "Switch back to app launcher mode.";
    if (mode === "system") return "Switch back to app launcher mode.";
    if (mode === "bookmarks") return "Switch to web mode for broader search.";
    return "Switch to app launcher mode.";
  }
  readonly property string emptyPrimaryHintIcon: {
    if (mode === "files") return "󰉋";
    if (mode === "web") return "󰖟";
    if (mode === "ai") return "󰚩";
    if (mode === "run") return "󰆍";
    if (mode === "bookmarks") return "󰃀";
    return "󰀻";
  }
  readonly property string emptySecondaryHint: {
    var clean = stripModePrefix(searchText).trim();
    var webSecondary = secondaryWebProvider();
    var webSecondaryName = webSecondary ? webSecondary.name : "Google";
    if (mode === "files") return clean !== "" ? "Open folder target derived from query path." : "Open your home directory.";
    if (mode === "web") return clean !== "" ? "Search " + webSecondaryName + " using the current query." : "Open " + webSecondaryName + " homepage.";
    if (mode === "system") return "Open quickshell control center panel.";
    if (mode === "run") return clean !== "" ? "Run command inside terminal for interactive output." : "Open terminal app.";
    if (searchText !== "") return "Clear the current query text.";
    return "";
  }
  readonly property string emptySecondaryHintIcon: {
    if (mode === "files") return "󰉋";
    if (mode === "web") return "󰇥";
    if (mode === "system") return "󰒓";
    if (mode === "run") return "󰆍";
    if (searchText !== "") return "󰅖";
    return "";
  }
  readonly property bool hasResults: filteredItems.length > 0
  readonly property var selectedItem: hasResults && selectedIndex >= 0 && selectedIndex < filteredItems.length ? filteredItems[selectedIndex] : null
  readonly property string legendPrimaryAction: {
    if (showingConfirm) return "Enter: Confirm";
    if (!hasResults) return "Enter: " + emptyPrimaryCta;
    if (mode === "web" && Config.launcherWebEnterUsesPrimary) {
      var primary = primaryWebProvider();
      var label = primary ? primary.name : "Web";
      return "Enter: Search " + label;
    }
    var action = itemActionLabel(selectedItem);
    if (action === "") action = "Open";
    return "Enter: " + action;
  }
  readonly property string legendSecondaryAction: {
    if (showingConfirm) return "Esc: Cancel";
    if (!hasResults && emptySecondaryCta !== "") return "Shift+Enter: " + emptySecondaryCta;
    if (mode === "web" && hasResults) return "Tab: Next Provider";
    return "Tab: Next Mode";
  }
  readonly property string legendTertiaryAction: mode === "web" && hasResults ? "Ctrl+Enter: Open Provider Home" : "Esc: Close"
  readonly property string webPrimaryProviderLabel: {
    var provider = primaryWebProvider();
    return provider ? provider.name : "Primary";
  }
  readonly property string webSelectedProviderLabel: activeProviderLabel !== "" ? activeProviderLabel : "Selected"
  readonly property string webPrimaryEnterHint: Config.launcherWebEnterUsesPrimary ? ("Enter: " + webPrimaryProviderLabel) : ("Enter: " + webSelectedProviderLabel)
  readonly property string webSecondaryEnterHint: Config.launcherWebEnterUsesPrimary ? ("Shift+Enter: " + webSelectedProviderLabel) : ("Shift+Enter: " + emptySecondaryCta)
  readonly property string activeProviderLabel: {
    if (mode !== "web")
      return "";
    if (selectedItem)
      return itemProviderLabel(selectedItem);
    return "";
  }

  readonly property string freqPath: Quickshell.env("HOME") + "/.local/state/quickshell/app_frequency.json"
  readonly property string historyPath: Quickshell.env("HOME") + "/.local/state/quickshell/launcher_history.json"

  Behavior on launcherOpacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

  property real scaleValue: 0.95
  Behavior on scaleValue { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
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
    onLoadFailed: (error) => {
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
    onLoadFailed: (error) => {
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
      if (!launcherRoot.seedFrequencyFile) return;
      launcherRoot.seedFrequencyFile = false;
      freqFile.setText("{}");
    }
  }

  Timer {
    id: seedHistoryTimer
    interval: 0
    repeat: false
    onTriggered: {
      if (!launcherRoot.seedHistoryFile) return;
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

  // Reactive watchers: ObjectModel doesn't expose countChanged as a signal,
  // so we use property bindings that re-evaluate when the model count changes.
  property int _toplevelCount: Hyprland.toplevels ? Hyprland.toplevels.count || 0 : 0
  on_ToplevelCountChanged: {
    if (launcherRoot.mode === "window" && launcherRoot.launcherOpacity > 0)
      launcherRoot.loadWindows();
  }

  property int _mprisCount: Mpris.players ? Mpris.players.length || 0 : 0
  on_MprisCountChanged: {
    if (launcherRoot.mode === "media" && launcherRoot.launcherOpacity > 0)
      launcherRoot.refreshMediaPlayers();
  }

  function modeInfo(key) {
    return launcherRoot.modeMeta[key] || { label: key.toUpperCase(), hint: "", prefix: "" };
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
      if (!allowed[modeKey] || seen[modeKey]) continue;
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
      if (enabledSet[modeKey])
        filtered.push(modeKey);
    }
    if (filtered.length === 0)
      return ["drun"];
    return filtered;
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
    allItems = [{
      name: title,
      title: subtitle || "",
      icon: iconName || (modeIcons[mode] || "󰋼"),
      isHint: true
    }];
    filterItems();
  }

  function modeDependencies(modeKey) {
    if (modeKey === "drun") return ["qs-apps"];
    if (modeKey === "run") return ["qs-run"];
    if (modeKey === "emoji") return ["qs-emoji"];
    if (modeKey === "clip") return ["qs-clip", "cliphist", "wl-copy"];
    if (modeKey === "keybinds") return ["qs-keybinds"];
    if (modeKey === "bookmarks") return ["qs-bookmarks"];
    if (modeKey === "wallpapers") return ["qs-wallpapers"];
    if (modeKey === "ai") return ["qs-ai", "wl-copy"];
    if (modeKey === "files") return ["bash"];
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
      (function(depName) {
        checkCommandAvailable(depName, function(ok) {
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

  function secondaryWebProvider() {
    var list = configuredWebProviders();
    if (list.length <= 1)
      return null;
    return list[1];
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
    console.log("Launcher timing:", label, took + "ms");
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
      perMode: ({})
    });
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
    var current = Object.assign({ failures: 0, lastFailure: 0 }, next[modeKey] || ({}));
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

  function saveFrequency() { freqFile.setText(JSON.stringify(appFrequency)); }
  function saveHistory() { historyFile.setText(JSON.stringify(launchHistory)); }

  function rememberRecent(item) {
    var key = item.exec || item.address || item.fullPath || item.name || item.title || "";
    if (!key) return;
    var next = [{
      key: key,
      name: item.name || item.label || item.title || key,
      title: item.title || item.description || item.exec || "",
      icon: item.icon || modeIcons[mode] || "󰀻",
      exec: item.exec || "",
      openMode: item.openMode || "",
      timestamp: Date.now()
    }];
    for (var i = 0; i < launchHistory.length; ++i) {
      if (launchHistory[i].key !== key) next.push(launchHistory[i]);
      if (next.length >= Config.launcherRecentsLimit) break;
    }
    launchHistory = next;
    saveHistory();
  }

  function trackLaunch(item) {
    var exec = item && item.exec ? item.exec : "";
    if (exec) appFrequency[exec] = (appFrequency[exec] || 0) + 1;
    saveFrequency();
    rememberRecent(item || {});
    buildLauncherHome();
  }

  function buildLauncherHome() {
    featuredActions = launcherShortcuts[mode] || [];
    suggestionItems = [];
    if (mode === "drun") {
      var apps = getCached("drun") || [];
      var recent = [];
      var seen = ({});
      for (var i = 0; i < launchHistory.length; ++i) {
        var launch = launchHistory[i];
        for (var j = 0; j < apps.length; ++j) {
          var app = apps[j];
          if (app.exec === launch.exec && !seen[app.exec]) {
            var matched = Object.assign({}, app);
            matched._recent = launch.timestamp || 0;
            recent.push(matched);
            seen[app.exec] = true;
            break;
          }
        }
      }
      if (recent.length < Config.launcherRecentAppsLimit) {
        var scored = [];
        for (var k = 0; k < apps.length; ++k) {
          var ranked = apps[k];
          var count = appFrequency[ranked.exec] || 0;
          if (count > 0 && !seen[ranked.exec]) {
            var copy = Object.assign({}, ranked);
            copy._recent = count;
            scored.push(copy);
          }
        }
        scored.sort(function(a, b) { return b._recent - a._recent; });
        recent = recent.concat(scored);
      }
      recentItems = recent.slice(0, Config.launcherRecentAppsLimit);
      var suggestions = [];
      for (var m = 0; m < apps.length; ++m) {
        var candidate = apps[m];
        if (seen[candidate.exec]) continue;
        var usage = appFrequency[candidate.exec] || 0;
        if (usage > 0) {
          var suggested = Object.assign({}, candidate);
          suggested._usage = usage;
          suggestions.push(suggested);
        }
      }
      suggestions.sort(function(a, b) { return (b._usage || 0) - (a._usage || 0); });
      suggestionItems = suggestions.slice(0, Config.launcherSuggestionsLimit);
    } else if (mode === "system") {
      recentItems = [
        { name: "Open Audio Controls", title: "Open the audio popup", icon: "󰕾", ipcTarget: "Shell", ipcAction: "toggleAudioMenu" },
        { name: "Open Network Controls", title: "Open the network popup", icon: "󰖩", ipcTarget: "Shell", ipcAction: "toggleNetworkMenu" },
        { name: "Open Command Center", title: "Open the system hub", icon: "󰒓", ipcTarget: "Shell", ipcAction: "toggleControls" }
      ];
    } else if (mode === "window" && Hyprland.toplevels && Hyprland.toplevels.count > 0) {
      recentItems = [{ name: "Focus open windows", title: "Jump into current clients", icon: "󱗼", openMode: "window" }];
    } else {
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
    if (showingConfirm) cancelConfirm();
    var nextMetrics = Object.assign({}, launcherMetrics);
    nextMetrics.opens = (nextMetrics.opens || 0) + 1;
    if (!nextMetrics.perMode) nextMetrics.perMode = ({});
    launcherMetrics = nextMetrics;
    openCount++;
    if (openCount % 10 === 0) clearCaches();
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
      if (searchInput) searchInput.text = "";
    }
    selectedIndex = 0;
    launcherOpacity = 1;
    scaleValue = 1.0;
    Qt.callLater(function() { if (searchInput) searchInput.forceActiveFocus(); });

    ensureModeDependencies(mode, function(ok, missingCmd) {
      if (!ok) {
        setModeHint("Dependency missing", missingDependencyMessage(mode, missingCmd), "󰋼");
        return;
      }

      if (mode === "drun") loadApps();
      else if (mode === "window") { allItems = []; filterItems(); windowLoadTimer.restart(); }
      else if (mode === "run") loadRun();
      else if (mode === "emoji") loadEmojis();
      else if (mode === "clip") loadClip();
      else if (mode === "calc") { allItems = []; filterItems(); }
      else if (mode === "web") loadWeb();
      else if (mode === "system") loadSystem();
      else if (mode === "media") { allItems = []; filterItems(); refreshMediaPlayers(); }
      else if (mode === "nixos") loadNixos();
      else if (mode === "wallpapers") loadWallpapers();
      else if (mode === "files") loadFiles();
      else if (mode === "bookmarks") loadBookmarks();
      else if (mode === "ai") loadAi();
      else if (mode === "keybinds") loadKeybinds();
      else if (mode === "dmenu") filterItems();
    });

    // Start background preload of other cacheable modes
    if (Config.launcherEnablePreload)
      preloadDelayTimer.restart();

    telemetryEnd("open:" + mode, startedAt);
  }

  function close() {
    if (searchInput && searchInput.activeFocus) searchInput.focus = false;
    launcherOpacity = 0;
    scaleValue = 0.95;
    ignoreMouseHover = true;
    mouseTrackingDelayTimer.stop();
    searchDebounceTimer.stop();
    fileSearchDebounceTimer.stop();
    preloadDelayTimer.stop();
    preloadWaitTimer.stop();
    var _keys = Object.keys(_preloadProcs);
    for (var _i = 0; _i < _keys.length; _i++) {
      if (_preloadProcs[_keys[_i]].running) _preloadProcs[_keys[_i]].running = false;
      _preloadProcs[_keys[_i]].destroy();
    }
    _preloadProcs = {};
    if (showingConfirm) confirmTitle = "";
  }

  function cycleMode(step) {
    var currentIndex = modeOrder.indexOf(mode);
    if (currentIndex === -1) currentIndex = 0;
    var nextIndex = (currentIndex + step + modeOrder.length) % modeOrder.length;
    open(modeOrder[nextIndex], true);
  }

  function askConfirm(title, callback) {
    confirmTitle = title;
    confirmCallback = callback;
  }

  function cancelConfirm() {
    confirmTitle = "";
    confirmCallback = null;
    searchInput.forceActiveFocus();
  }

  function doConfirm() {
    if (confirmCallback) confirmCallback();
    confirmTitle = "";
    confirmCallback = null;
    close();
  }

  function runCommand(command, callback) {
    if (commandProc.running) commandProc.running = false;
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
      allItems = [{ name: "Loading...", isHint: true, icon: "󰔟" }];
      filterItems();
      _waitForPreload(modeKey);
      return;
    }
    allItems = [{ name: "Loading...", isHint: true, icon: "󰔟" }];
    filterItems();
    var token = beginRequest(modeKey);
    runCommand(command, function(raw) {
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

  function loadApps() { loadCached("drun", ["qs-apps"], JSON.parse); }
  function loadRun() { loadCached("run", ["qs-run"], JSON.parse); }
  function loadWallpapers() { loadCached("wallpapers", ["qs-wallpapers"], JSON.parse); }
  function loadKeybinds() { loadCached("keybinds", ["qs-keybinds"], JSON.parse); }
  function loadBookmarks() { loadCached("bookmarks", ["qs-bookmarks"], JSON.parse); }

  function parseEmoji(raw) {
    var lines = raw.split("\n");
    var items = [];
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].trim() !== "") {
        var parts = lines[i].split(" ");
        items.push({ name: parts[0], title: parts.slice(1).join(" ") });
      }
    }
    return items;
  }

  function parseClip(raw) {
    return JSON.parse(raw).filter(function(it) {
      return it.content && it.content.indexOf("[[ binary data") === -1;
    }).map(function(it) {
      return { id: it.id, name: it.content, title: it.content, icon: "󰅍" };
    });
  }

  function loadEmojis() { loadCached("emoji", ["qs-emoji"], parseEmoji); }
  function loadClip() { loadCached("clip", ["qs-clip"], parseClip); }

  // ── Background preloading ───────────────────
  readonly property var preloadModes: ({
    "drun":      { command: ["qs-apps"],      parse: JSON.parse },
    "run":       { command: ["qs-run"],       parse: JSON.parse },
    "emoji":     { command: ["qs-emoji"],     parse: parseEmoji },
    "clip":      { command: ["qs-clip"],      parse: parseClip },
    "keybinds":  { command: ["qs-keybinds"],  parse: JSON.parse },
    "bookmarks": { command: ["qs-bookmarks"], parse: JSON.parse }
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
    var script = "if command -v fd >/dev/null 2>&1; then "
      + "fd --base-directory " + shellQuote(homeDir) + " --max-results " + maxResults + " " + shellQuote(searchQuery) + "; "
      + "else find " + shellQuote(homeDir) + " -mindepth 1 -maxdepth 6 -iname '*" + searchQuery.replace(/'/g, "'\\''") + "*' 2>/dev/null | head -n " + maxResults + "; fi";
    runCommand(["bash", "-lc", script], function(raw) {
      if (!isRequestCurrent("files", token))
        return;
      var lines = raw ? raw.split("\n") : [];
      var items = [];
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trim() !== "") {
          var path = lines[i];
          var parts = path.split("/");
          var fullPath = path.startsWith("/") ? path : (homeDir + "/" + path);
          items.push({ name: parts[parts.length - 1] || path, title: fullPath, fullPath: fullPath });
        }
      }
      allItems = items;
      setFileQueryCached(cacheKey, items);
      filterItems();
      recordLoadMetric("files", Date.now() - startedAt, false, true);
    });
  }

  function loadAi() {
    var query = searchText.startsWith("!") ? searchText.substring(1).trim() : searchText;
    if (query.length < 3) {
      allItems = [];
      filterItems();
      return;
    }
    allItems = [{ name: "Thinking...", isHint: true, icon: "󰚩" }];
    filterItems();
    var token = beginRequest("ai");
    var startedAt = Date.now();
    runCommand(["qs-ai", query], function(raw) {
      if (!isRequestCurrent("ai", token))
        return;
      raw = raw.trim();
      if (raw) allItems = [{ name: "AI Response", title: "Click to copy response", body: raw, icon: "󰚩" }];
      else allItems = [];
      filterItems();
      recordLoadMetric("ai", Date.now() - startedAt, false, true);
    });
  }

  function loadWeb() {
    allItems = configuredWebProviders();
    filterItems();
  }

  function loadSystem() {
    allItems = [
      { category: "Power", name: "Shutdown", icon: "󰐥", action: () => askConfirm("Shutdown system?", () => Quickshell.execDetached(["systemctl", "poweroff"])) },
      { category: "Power", name: "Reboot", icon: "󰑐", action: () => askConfirm("Reboot system?", () => Quickshell.execDetached(["systemctl", "reboot"])) },
      { category: "Power", name: "Lock Screen", icon: "󰌾", action: () => Quickshell.execDetached(["hyprlock"]) },
      { category: "Power", name: "Log Out", icon: "󰍃", action: () => askConfirm("Log out of session?", () => Quickshell.execDetached(["hyprctl", "dispatch", "exit"])) },
      { category: "Capture", name: "Screenshot (Area)", icon: "󰹑", action: () => Quickshell.execDetached(["screenshot.sh", "area", "--satty"]) },
      { category: "Capture", name: "Screenshot (Display)", icon: "󰍹", action: () => Quickshell.execDetached(["screenshot.sh", "screen", "--satty"]) },
      { category: "Capture", name: "Color Picker", icon: "󰏘", action: () => Quickshell.execDetached(["hyprpicker", "-a"]) },
      { category: "Toggles", name: "Toggle Bluetooth", icon: "󰂯", action: () => { if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled; } },
      { category: "Toggles", name: "Toggle Night Light", icon: "󰖔", action: () => Quickshell.execDetached(["os-toggle-nightlight"]) },
      { category: "Controls", name: "Open Audio Controls", icon: "󰕾", ipcTarget: "Shell", ipcAction: "toggleAudioMenu" },
      { category: "Controls", name: "Open Network Controls", icon: "󰖩", ipcTarget: "Shell", ipcAction: "toggleNetworkMenu" },
      { category: "Controls", name: "Open Command Center", icon: "󰒓", ipcTarget: "Shell", ipcAction: "toggleControls" },
      { category: "Utilities", name: "System Monitor (btop)", icon: "󰄨", action: () => Quickshell.execDetached(["kitty", "-e", "btop"]) },
      { category: "Utilities", name: "Audio Settings", icon: "󰕾", action: () => Quickshell.execDetached(["kitty", "-e", "wiremix"]) }
    ];
    filterItems();
  }

  function loadNixos() {
    allItems = [
      { category: "System", name: "Rebuild Switch (flake)", icon: "󰒓", action: () => Quickshell.execDetached(["kitty", "-e", "sudo", "nixos-rebuild", "switch", "--flake", ".#"]) },
      { category: "System", name: "Update Flake Locks", icon: "󰚰", action: () => Quickshell.execDetached(["kitty", "-e", "nix", "flake", "update"]) },
      { category: "System", name: "Collect Garbage", icon: "󰃢", action: () => Quickshell.execDetached(["kitty", "-e", "sudo", "nix-env", "--delete-generations", "old"]) },
      { category: "Information", name: "System Generations", icon: "󰋚", action: () => Quickshell.execDetached(["kitty", "-e", "sudo", "nix-env", "-p", "/nix/var/nix/profiles/system", "--list-generations"]) }
    ];
    runCommand(["nixos-version"], function(raw) {
      var ver = raw.trim();
      if (ver && mode === "nixos") {
        allItems.unshift({ category: "Information", name: "Current Version: " + ver, icon: "", action: null });
        filterItems();
      }
    });
    filterItems();
  }

  function loadWindows() {
    var items = [];
    try {
      if (Hyprland.toplevels) {
        for (var i = 0; i < Hyprland.toplevels.count; i++) {
          var win = Hyprland.toplevels.get(i);
          if (win) {
            items.push({
              name: win.title || win.class || "Window",
              title: win.class || "",
              icon: "󱗼",
              address: win.address,
              class: win.class
            });
          }
        }
      }
    } catch (e) {
      console.error("Error loading windows: " + e);
    }
    allItems = items;
    filterItems();
  }

  function highlightMatch(fullText, query) {
    if (!query || !fullText) return fullText;
    var cleanQuery = stripModePrefix(query);
    if (!cleanQuery) return fullText;
    var idx = fullText.toLowerCase().indexOf(cleanQuery.toLowerCase());
    if (idx === -1) return fullText;
    return fullText.substring(0, idx) + "<b>" + fullText.substring(idx, idx + cleanQuery.length) + "</b>" + fullText.substring(idx + cleanQuery.length);
  }

  function fuzzyMatch(str, pattern) {
    if (!pattern) return 100;
    if (!str) return 0;
    var s = str.toLowerCase();
    var p = stripModePrefix(pattern).toLowerCase();
    if (!p) return 100;
    if (s.startsWith(p)) return 100 + (p.length / s.length);
    if (s.indexOf(p) !== -1) return 50 + (p.length / s.length);
    var pIdx = 0;
    var sIdx = 0;
    while (sIdx < s.length && pIdx < p.length) {
      if (s[sIdx] === p[pIdx]) pIdx++;
      sIdx++;
    }
    if (pIdx === p.length) return 10 + (p.length / s.length);
    return 0;
  }

  function rankItem(item, query) {
    var clean = stripModePrefix(query);
    if (clean === "") return 1;
    var name = item.name || "";
    var title = item.title || "";
    var exec = item.exec || item.class || "";
    var body = item.body || "";
    var bestScore = Math.max(
      fuzzyMatch(name, clean) * Config.launcherScoreNameWeight,
      fuzzyMatch(title, clean) * Config.launcherScoreTitleWeight,
      fuzzyMatch(exec, clean) * Config.launcherScoreExecWeight,
      fuzzyMatch(body, clean) * Config.launcherScoreBodyWeight
    );
    if (mode === "drun") bestScore += (appFrequency[item.exec] || 0) * 0.6;
    return bestScore;
  }

  function filterItems() {
    var actualSearch = searchText;
    if (mode === "calc") {
      actualSearch = searchText.startsWith("=") ? searchText.substring(1).trim() : searchText;
      try {
        if (actualSearch !== "") {
          var result = eval(actualSearch.replace(/[^-+/*() .0-9]/g, ""));
          if (result !== undefined && !isNaN(result)) {
            filteredItems = [{ name: result.toString(), title: "Result: " + result, isCalc: true }];
            selectedIndex = 0;
            return;
          }
        }
      } catch (e) {}
      filteredItems = [];
      return;
    }

    if (mode === "run" && searchText.startsWith(">")) actualSearch = searchText.substring(1).trim();
    if (mode === "emoji" && searchText.startsWith(":")) actualSearch = searchText.substring(1).trim();
    if (mode === "web" && searchText.startsWith("?")) actualSearch = searchText.substring(1).trim();
    if (mode === "ai" && searchText.startsWith("!")) actualSearch = searchText.substring(1).trim();
    if (mode === "files" && searchText.startsWith("/")) actualSearch = searchText.substring(1).trim();
    if (mode === "bookmarks" && searchText.startsWith("@")) actualSearch = searchText.substring(1).trim();

    if (actualSearch === "" && mode !== "files" && mode !== "ai") {
      filteredItems = allItems;
    } else {
      var scoredItems = [];
      for (var i = 0; i < allItems.length; i++) {
        var item = allItems[i];
        if (mode === "web") {
          var webItem = Object.assign({}, item);
          webItem.title = "Search " + item.name + " for '" + actualSearch + "'";
          webItem.query = actualSearch;
          scoredItems.push(webItem);
          continue;
        }
        var bestScore = rankItem(item, actualSearch);
        if (bestScore > 0 || (actualSearch === "" && (mode === "files" || mode === "ai"))) {
          item._score = bestScore;
          scoredItems.push(item);
        }
      }
      if (mode !== "web" && mode !== "ai" && mode !== "files") {
        scoredItems.sort(function(a, b) {
          if (b._score !== a._score) return b._score - a._score;
          if (mode === "drun") return (appFrequency[b.exec] || 0) - (appFrequency[a.exec] || 0);
          return (a.name || "").localeCompare(b.name || "");
        });
      } else if (mode === "files") {
        scoredItems.sort(function(a, b) {
          if (b._score !== a._score) return b._score - a._score;
          var aPath = a.fullPath || a.title || "";
          var bPath = b.fullPath || b.title || "";
          return aPath.localeCompare(bPath);
        });
      } else if (mode === "ai") {
        scoredItems.sort(function(a, b) {
          if (b._score !== a._score) return b._score - a._score;
          return 0;
        });
      }
      filteredItems = scoredItems.slice(0, Config.launcherMaxResults);
    }
    selectedIndex = Math.min(selectedIndex, Math.max(0, filteredItems.length - 1));
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
    if (!item || item.isHint) return "";
    if (mode === "clip" || mode === "emoji" || mode === "calc" || mode === "ai") return "Copy";
    if (mode === "window") return "Focus";
    if (mode === "files" || mode === "web" || mode === "bookmarks" || mode === "wallpapers") return "Open";
    if (mode === "drun" || mode === "run") return "Run";
    if (mode === "system" || mode === "nixos" || mode === "keybinds" || mode === "media") return "Action";
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
      var primary = primaryWebProvider();
      var url = primary ? String(primary.home || "") : "";
      if (url === "")
        url = "https://duckduckgo.com/";
      if (clean !== "" && primary && primary.exec)
        url = String(primary.exec) + encodeURIComponent(clean);
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
      Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "toggleControls"]);
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
    searchText = "";
    if (searchInput) searchInput.text = "";
    filterItems();
    if (searchInput) searchInput.forceActiveFocus();
  }

  function cycleSelection(step) {
    if (filteredItems.length <= 0) return;
    var next = (selectedIndex + step + filteredItems.length) % filteredItems.length;
    selectedIndex = next;
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
    var provider = primaryWebProvider();
    if (!provider)
      return;
    var clean = stripModePrefix(searchText).trim();
    var target = "";
    if (clean !== "" && provider.exec)
      target = String(provider.exec) + encodeURIComponent(clean);
    else
      target = String(provider.home || provider.exec || "");
    if (target === "")
      return;
    rememberRecent({ name: provider.name || "Web", title: target, icon: provider.icon || "󰖟", exec: String(provider.exec || "") });
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
    if (item.action) item.action();
  }

  function executeSelection() {
    if (filteredItems.length === 0 || selectedIndex < 0 || selectedIndex >= filteredItems.length) return;
    var item = filteredItems[selectedIndex];

    if (mode === "drun") {
      trackLaunch(item);
      launchExecString(item.exec, item.terminal === "true" || item.terminal === "True");
      close();
    } else if (mode === "run") {
      rememberRecent({ name: item.name || item.exec, title: item.exec || "", icon: "󰆍", exec: item.exec || "" });
      if (item.exec) Quickshell.execDetached(["bash", "-c", item.exec]);
      close();
    } else if (mode === "window") {
      rememberRecent({ name: item.name || item.title || "Window", title: item.title || item.class || "", icon: "󱗼", address: item.address || "", openMode: "window" });
      Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "address:" + item.address]);
      close();
    } else if (mode === "dmenu") {
      var fifoPath = "/tmp/qs-dmenu-result";
      Quickshell.execDetached(["bash", "-c", "echo '" + item.name.replace(/'/g, "'\\''") + "' > " + fifoPath]);
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
      rememberRecent({ name: item.name || "Link", title: item.title || item.exec || "", icon: item.icon || "󰖟", exec: item.exec || "" });
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
        rememberRecent({ name: item.name || item.fullPath, title: item.fullPath, icon: "󰈔", fullPath: item.fullPath });
        Quickshell.execDetached(["xdg-open", item.fullPath]);
        close();
      }
    } else if (mode === "system" || mode === "nixos") {
      rememberRecent({ name: item.name || "Action", title: item.category || item.title || "", icon: item.icon || "󰒓", exec: item.exec || "" });
      if (item.ipcTarget && item.ipcAction) Quickshell.execDetached(["quickshell", "ipc", "call", item.ipcTarget, item.ipcAction]);
      else if (item.action) item.action();
      if (!showingConfirm) close();
    } else if (mode === "wallpapers") {
      Quickshell.execDetached(["swww", "img", item.path, "--transition-type", "grow", "--transition-pos", "0.5,0.5", "--transition-duration", "1.5"]);
      Quickshell.execDetached(["wallust", "run", item.path]);
      close();
    } else if (mode === "keybinds") {
      if (item.disp) Quickshell.execDetached(["hyprctl", "dispatch", item.disp, item.args || ""]);
      close();
    }
  }

  IpcHandler {
    target: "Launcher"
    function openDrun() { launcherRoot.open("drun"); }
    function openWindow() { launcherRoot.open("window"); }
    function openRun() { launcherRoot.open("run"); }
    function openEmoji() { launcherRoot.open("emoji"); }
    function openCalc() { launcherRoot.open("calc"); }
    function openClip() { launcherRoot.open("clip"); }
    function openWeb() { launcherRoot.open("web"); }
    function openSystem() { launcherRoot.open("system"); }
    function openNixos() { launcherRoot.open("nixos"); }
    function openMedia() { launcherRoot.open("media"); }
    function openWallpapers() { launcherRoot.open("wallpapers"); }
    function openKeybinds() { launcherRoot.open("keybinds"); }
    function openBookmarks() { launcherRoot.open("bookmarks"); }
    function openAi() { launcherRoot.open("ai"); }
    function openFiles() { launcherRoot.open("files"); }
    function openDmenu(itemsJson: string) {
      var items = [];
      try { items = JSON.parse(itemsJson); } catch (err) {}
      launcherRoot.mode = "dmenu";
      launcherRoot.allItems = items.map(function(it) { return { name: it, title: it }; });
      launcherRoot.open("dmenu");
    }
    function clearMetrics() { launcherRoot.clearLauncherMetrics(); }
    function toggle() { if (launcherRoot.launcherOpacity > 0) launcherRoot.close(); else launcherRoot.open(launcherRoot.effectiveDefaultMode()); }
  }

  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.5)
    opacity: launcherOpacity
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    MouseArea { anchors.fill: parent; onClicked: launcherRoot.close() }
  }

  Rectangle {
    id: hudBox
    width: 960
    height: Math.min(760, parent.height - 100)
    anchors.centerIn: parent
    color: Colors.bgGlass
    radius: Colors.radiusLarge
    border.color: Colors.border
    border.width: 1
    scale: launcherRoot.scaleValue
    clip: true

    // Anti-flicker: track mouse movement after open to enable hover-select
    HoverHandler {
      id: hudHoverHandler
      onPointChanged: {
        if (!launcherRoot.mouseTrackingReady) return;
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
      anchors.margins: Colors.paddingMedium
      spacing: 18

      Rectangle {
        Layout.preferredWidth: 210
        Layout.fillHeight: true
        radius: Colors.radiusLarge
        color: Colors.withAlpha(Colors.surface, 0.45)
        border.color: Colors.border
        border.width: 1

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Colors.spacingM
          spacing: Colors.paddingSmall

          Text { text: "Launcher"; color: Colors.text; font.pixelSize: Colors.fontSizeXL; font.weight: Font.DemiBold }
          Text { text: "Modes"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold }

          Repeater {
            model: launcherRoot.primaryModes
            delegate: Rectangle {
              Layout.fillWidth: true
              implicitHeight: 46
              radius: Colors.radiusMedium
              color: launcherRoot.mode === modelData ? Colors.highlight : Colors.bgWidget
              Behavior on color { ColorAnimation { duration: 160 } }
              border.color: launcherRoot.mode === modelData ? Colors.primary : "transparent"
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.margins: Colors.paddingSmall
                spacing: Colors.paddingSmall
                Text { text: launcherRoot.modeIcons[modelData] || "•"; color: launcherRoot.mode === modelData ? Colors.primary : Colors.textSecondary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeLarge }
                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 0
                  Text { text: launcherRoot.modeInfo(modelData).label; color: Colors.text; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.DemiBold }
                  Text { text: launcherRoot.modeInfo(modelData).hint; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; elide: Text.ElideRight; Layout.fillWidth: true }
                }
              }

              SharedWidgets.StateLayer { id: modeStateLayer; hovered: modeHover.containsMouse; pressed: modeHover.pressed; visible: launcherRoot.mode !== modelData }
              MouseArea {
                id: modeHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                  modeStateLayer.burst(mouse.x, mouse.y);
                  launcherRoot.open(modelData, true);
                }
              }
            }
          }

          Item { Layout.fillHeight: true }

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 74
            radius: Colors.radiusMedium
            color: Colors.bgWidget
            border.color: Colors.border
            border.width: 1
            visible: Config.launcherShowModeHints

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: Colors.spacingM
              spacing: 2
              Text { text: "Controls"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold }
              Text { text: "Tab to cycle modes"; color: Colors.text; font.pixelSize: Colors.fontSizeSmall }
              Text { text: "Enter to run • Esc to close"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS }
            }
          }
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Colors.paddingMedium

        Rectangle {
          Layout.fillWidth: true
          height: 55
          color: Colors.bgWidget
          radius: 27.5
          border.color: searchInput.activeFocus ? Colors.primary : "transparent"
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: Colors.paddingMedium
            Text { text: ""; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL }
            TextInput {
              id: searchInput
              Layout.fillWidth: true
              color: Colors.text
              font.pixelSize: Colors.fontSizeXL
              clip: true
              text: launcherRoot.searchText
              enabled: !launcherRoot.showingConfirm
              onVisibleChanged: if (!visible && activeFocus) focus = false
              onTextChanged: {
                if (text.startsWith("=") && launcherRoot.mode !== "calc") launcherRoot.open("calc", true);
                else if (text.startsWith(">") && launcherRoot.mode !== "run") launcherRoot.open("run", true);
                else if (text.startsWith(":") && launcherRoot.mode !== "emoji") launcherRoot.open("emoji", true);
                else if (text.startsWith("?") && launcherRoot.mode !== "web") launcherRoot.open("web", true);
                else if (text.startsWith("!") && launcherRoot.mode !== "ai") launcherRoot.open("ai", true);
                else if (text.startsWith("@") && launcherRoot.mode !== "bookmarks") launcherRoot.open("bookmarks", true);
                else if (text.startsWith("/") && launcherRoot.mode !== "files") launcherRoot.open("files", true);
                if (launcherRoot.searchText !== text) {
                  launcherRoot.searchText = text;
                  launcherRoot.scheduleSearchRefresh(false);
                }
              }
              Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) launcherRoot.close();
                else if (event.key === Qt.Key_Tab && launcherRoot.mode === "web" && (event.modifiers & Qt.ShiftModifier) && !(event.modifiers & Qt.ControlModifier)) {
                  launcherRoot.cycleSelection(-1);
                  event.accepted = true;
                } else if (event.key === Qt.Key_Tab && launcherRoot.mode === "web" && !(event.modifiers & Qt.ShiftModifier) && !(event.modifiers & Qt.ControlModifier)) {
                  launcherRoot.cycleSelection(1);
                  event.accepted = true;
                } else if (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier)) {
                  launcherRoot.cycleMode(-1);
                  event.accepted = true;
                } else if (event.key === Qt.Key_Tab) {
                  launcherRoot.cycleMode(1);
                  event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                  if ((event.modifiers & Qt.ControlModifier) && launcherRoot.mode === "web" && launcherRoot.filteredItems.length > 0) launcherRoot.openSelectedWebHomepage();
                  else if (launcherRoot.mode === "web" && launcherRoot.filteredItems.length > 0 && !(event.modifiers & Qt.ShiftModifier) && Config.launcherWebEnterUsesPrimary) launcherRoot.executePrimaryWebSearch();
                  else if ((event.modifiers & Qt.ShiftModifier) && launcherRoot.filteredItems.length === 0 && launcherRoot.emptySecondaryCta !== "") launcherRoot.executeEmptySecondary();
                  else if (launcherRoot.mode === "ai" && launcherRoot.filteredItems.length === 0) launcherRoot.loadAi();
                  else if (launcherRoot.mode === "files" && launcherRoot.stripModePrefix(launcherRoot.searchText).trim().length >= Config.launcherFileMinQueryLength && launcherRoot.filteredItems.length === 0) launcherRoot.loadFiles();
                  else if (launcherRoot.filteredItems.length === 0) launcherRoot.executeEmptyPrimary();
                  else launcherRoot.executeSelection();
                } else if (event.key === Qt.Key_Up) {
                  launcherRoot.selectedIndex = Math.max(0, launcherRoot.selectedIndex - 1);
                  event.accepted = true;
                } else if (event.key === Qt.Key_Down) {
                  launcherRoot.selectedIndex = Math.min(launcherRoot.filteredItems.length - 1, launcherRoot.selectedIndex + 1);
                  event.accepted = true;
                }
              }
            }
            Rectangle {
              visible: launcherRoot.mode === "web" && launcherRoot.activeProviderLabel !== ""
              height: 28
              width: Math.min(providerText.implicitWidth + 28, 210)
              radius: height / 2
              color: Colors.withAlpha(Colors.primary, 0.12)
              border.color: Colors.withAlpha(Colors.primary, 0.5)
              border.width: 1
              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 12
                spacing: Colors.spacingXS
                Text {
                  text: "󰖟"
                  color: Colors.primary
                  font.family: Colors.fontMono
                  font.pixelSize: Colors.fontSizeSmall
                }
                Text {
                  id: providerText
                  Layout.fillWidth: true
                  text: launcherRoot.activeProviderLabel
                  color: Colors.primary
                  font.pixelSize: Colors.fontSizeXS
                  font.weight: Font.DemiBold
                  elide: Text.ElideRight
                }
              }
            }
            Rectangle {
              height: 28
              width: Math.min(modeText.implicitWidth + 32, 110)
              radius: height / 2
              color: Colors.highlight
              Text {
                id: modeText
                anchors.centerIn: parent
                width: Math.min(implicitWidth, parent.width - 20)
                text: launcherRoot.modeInfo(launcherRoot.mode).label
                color: Colors.primary
                font.pixelSize: Colors.fontSizeSmall
                font.weight: Font.DemiBold
                elide: Text.ElideRight
              }
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Colors.paddingSmall
          visible: Config.launcherShowModeHints
          Text { Layout.fillWidth: true; text: launcherRoot.modeInfo(launcherRoot.mode).hint; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeSmall; elide: Text.ElideRight }
          Text {
            text: launcherRoot.legendPrimaryAction + " • " + launcherRoot.legendSecondaryAction + " • " + launcherRoot.legendTertiaryAction
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeXS
          }
        }

        Rectangle {
          Layout.fillWidth: true
          visible: Config.launcherShowModeHints && launcherRoot.mode === "web"
          color: Colors.bgWidget
          radius: Colors.radiusMedium
          border.color: Colors.border
          border.width: 1
          implicitHeight: 34

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Colors.spacingM
            anchors.rightMargin: Colors.spacingM
            spacing: Colors.spacingS

            Text {
              text: "󰖟"
              color: Colors.primary
              font.family: Colors.fontMono
              font.pixelSize: Colors.fontSizeSmall
            }
            Text {
              Layout.fillWidth: true
              text: launcherRoot.webPrimaryEnterHint + " • " + launcherRoot.webSecondaryEnterHint
              color: Colors.textSecondary
              font.pixelSize: Colors.fontSizeXS
              elide: Text.ElideRight
            }
            Text {
              text: "Ctrl+Enter: Home"
              color: Colors.textDisabled
              font.pixelSize: Colors.fontSizeXS
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          visible: Config.launcherShowRuntimeMetrics
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
              spacing: 2
              Text { text: "Launcher Metrics"; color: Colors.text; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.DemiBold }
              Text {
                text: "opens " + launcherRoot.launcherMetrics.opens
                  + " • cache " + launcherRoot.launcherMetrics.cacheHits + "/" + launcherRoot.launcherMetrics.cacheMisses
                  + " • failures " + launcherRoot.launcherMetrics.commandFailures
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeXS
                elide: Text.ElideRight
              }
              Text {
                readonly property var modeStats: launcherRoot.modeMetric(launcherRoot.mode)
                text: launcherRoot.modeInfo(launcherRoot.mode).label
                  + ": avg " + modeStats.avgLoadMs + "ms"
                  + " • last " + modeStats.lastLoadMs + "ms"
                  + " • failures " + modeStats.failures
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

        Rectangle {
          Layout.fillWidth: true
          visible: launcherRoot.showLauncherHome
          color: Colors.bgWidget
          radius: Colors.radiusMedium
          border.color: Colors.border
          border.width: 1
          implicitHeight: 130

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: Colors.spacingM
            spacing: Colors.spacingM
            Text { text: "Featured"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold }
            RowLayout {
              Layout.fillWidth: true
              spacing: Colors.paddingSmall
              Repeater {
                model: launcherRoot.featuredActions
                delegate: Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 74
                  radius: Colors.radiusMedium
                  color: Colors.surface
                  border.color: Colors.border
                  border.width: 1

                  ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Colors.spacingM
                    spacing: Colors.spacingXS
                    Text { text: modelData.icon; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL }
                    Text { text: modelData.label; color: Colors.text; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.DemiBold; elide: Text.ElideRight }
                    Text { text: modelData.description; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; elide: Text.ElideRight }
                  }

                  SharedWidgets.StateLayer { id: featureStateLayer; hovered: featureHover.containsMouse; pressed: featureHover.pressed }
                  MouseArea {
                    id: featureHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                      featureStateLayer.burst(mouse.x, mouse.y);
                      launcherRoot.activateFeatured(modelData);
                    }
                  }
                }
              }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          visible: launcherRoot.showLauncherHome && launcherRoot.recentItems.length > 0
          color: Colors.bgWidget
          radius: Colors.radiusMedium
          border.color: Colors.border
          border.width: 1
          implicitHeight: recentColumn.implicitHeight + 24

          ColumnLayout {
            id: recentColumn
            anchors.fill: parent
            anchors.margins: Colors.spacingM
            spacing: Colors.spacingS
            Text { text: "Recent"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold }

            Repeater {
              model: launcherRoot.recentItems
              delegate: Rectangle {
                Layout.fillWidth: true
                implicitHeight: 40
                radius: Colors.radiusSmall
                color: "transparent"

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: Colors.spacingS
                  spacing: Colors.paddingSmall
                  Text { text: modelData.icon || "󰀻"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeMedium }
                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text { text: modelData.name || modelData.label; color: Colors.text; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.DemiBold; elide: Text.ElideRight }
                    Text { text: modelData.title || modelData.description || ""; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; elide: Text.ElideRight }
                  }
                }

                SharedWidgets.StateLayer { id: recentStateLayer; hovered: recentHover.containsMouse; pressed: recentHover.pressed }
                MouseArea {
                  id: recentHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: (mouse) => {
                    recentStateLayer.burst(mouse.x, mouse.y);
                    launcherRoot.activateFeatured(modelData);
                  }
                }
              }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          visible: launcherRoot.showLauncherHome && launcherRoot.mode === "drun" && launcherRoot.suggestionItems.length > 0
          color: Colors.bgWidget
          radius: Colors.radiusMedium
          border.color: Colors.border
          border.width: 1
          implicitHeight: suggestionColumn.implicitHeight + 24

          ColumnLayout {
            id: suggestionColumn
            anchors.fill: parent
            anchors.margins: Colors.spacingM
            spacing: Colors.spacingS
            Text { text: "Suggested"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold }

            Repeater {
              model: launcherRoot.suggestionItems
              delegate: Rectangle {
                Layout.fillWidth: true
                implicitHeight: 42
                radius: Colors.radiusSmall
                color: "transparent"

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: Colors.spacingS
                  spacing: Colors.paddingSmall
                  Text { text: modelData.icon || "󰀻"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeMedium }
                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text { text: modelData.name || modelData.label; color: Colors.text; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.DemiBold; elide: Text.ElideRight }
                    Text { text: (modelData.exec || modelData.title || "Frequently used"); color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; elide: Text.ElideRight }
                  }
                  Rectangle {
                    radius: 11
                    color: Colors.surface
                    border.color: Colors.border
                    border.width: 1
                    implicitWidth: suggestionBadge.implicitWidth + 16
                    implicitHeight: 22
                    Text {
                      id: suggestionBadge
                      anchors.centerIn: parent
                      text: (modelData._usage || 0) + "x"
                      color: Colors.textSecondary
                      font.pixelSize: Colors.fontSizeXS
                      font.weight: Font.Medium
                    }
                  }
                }

                SharedWidgets.StateLayer { id: suggestionStateLayer; hovered: suggestionHover.containsMouse; pressed: suggestionHover.pressed }
                MouseArea {
                  id: suggestionHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: (mouse) => {
                    suggestionStateLayer.burst(mouse.x, mouse.y);
                    launcherRoot.selectedIndex = 0;
                    if (modelData.exec) {
                      launcherRoot.trackLaunch(modelData);
                      launcherRoot.launchExecString(modelData.exec, modelData.terminal === "true" || modelData.terminal === "True");
                      launcherRoot.close();
                    }
                  }
                }
              }
            }
          }
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
              spacing: Colors.spacingS
              currentIndex: launcherRoot.selectedIndex
              enabled: !launcherRoot.showingConfirm
              section.property: "category"
              section.delegate: Text { text: section; color: Colors.primary; font.pixelSize: Colors.fontSizeXS; font.bold: true; height: 25; verticalAlignment: Text.AlignBottom }

              delegate: Rectangle {
                width: resultsList.width
                height: 58
                color: index === launcherRoot.selectedIndex ? Colors.highlight : "transparent"
                radius: Colors.radiusSmall
                border.color: index === launcherRoot.selectedIndex ? Colors.withAlpha(Colors.primary, 0.6) : "transparent"
                border.width: index === launcherRoot.selectedIndex ? 1 : 0
                readonly property string actionLabel: launcherRoot.itemActionLabel(modelData)
                readonly property string providerLabel: launcherRoot.itemProviderLabel(modelData)

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: Colors.spacingM
                  anchors.rightMargin: Colors.spacingM
                  spacing: Colors.paddingMedium

                  Rectangle {
                    width: 34
                    height: 34
                    radius: Colors.radiusXS
                    color: Colors.surface
                    Image {
                      id: iconImage
                      anchors.fill: parent
                      anchors.margins: Colors.spacingXS
                      source: Config.resolveIconSource(modelData.icon || "")
                      sourceSize: Qt.size(64, 64)
                      asynchronous: true
                      fillMode: Image.PreserveAspectCrop
                      visible: source !== "" && status === Image.Ready
                    }
                    Text {
                      anchors.centerIn: parent
                      text: modelData.icon || launcherRoot.modeIcons[launcherRoot.mode] || "󰀻"
                      color: Colors.primary
                      font.family: Colors.fontMono
                      font.pixelSize: Colors.fontSizeXL
                      visible: !iconImage.visible
                    }
                  }

                  ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true
                    Text {
                      text: highlightMatch(modelData.name || modelData.title || "", searchText)
                      color: Colors.text
                      textFormat: Text.StyledText
                      font.pixelSize: Colors.fontSizeMedium
                      font.weight: index === launcherRoot.selectedIndex ? Font.Bold : Font.Normal
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                    }
                    Text {
                      text: modelData.exec || modelData.class || modelData.title || ""
                      color: Colors.textSecondary
                      font.pixelSize: Colors.fontSizeXS
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                      visible: text !== "" && text !== (modelData.name || "")
                    }
                  }

                  RowLayout {
                    spacing: Colors.spacingXS
                    Rectangle {
                      visible: providerLabel !== ""
                      radius: Colors.radiusPill
                      color: index === launcherRoot.selectedIndex ? Colors.withAlpha(Colors.primary, 0.22) : Colors.highlight
                      border.color: Colors.withAlpha(Colors.primary, 0.45)
                      border.width: 1
                      implicitHeight: 22
                      implicitWidth: providerBadgeText.implicitWidth + 12
                      Text {
                        id: providerBadgeText
                        anchors.centerIn: parent
                        text: providerLabel
                        color: Colors.primary
                        font.pixelSize: Colors.fontSizeXS
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, 150)
                      }
                    }
                    Rectangle {
                      visible: actionLabel !== ""
                      radius: Colors.radiusPill
                      color: index === launcherRoot.selectedIndex ? Colors.withAlpha(Colors.primary, 0.18) : Colors.surface
                      border.color: Colors.border
                      border.width: 1
                      implicitHeight: 22
                      implicitWidth: actionBadgeText.implicitWidth + 12
                      Text {
                        id: actionBadgeText
                        anchors.centerIn: parent
                        text: actionLabel
                        color: index === launcherRoot.selectedIndex ? Colors.primary : Colors.textSecondary
                        font.pixelSize: Colors.fontSizeXS
                        font.weight: Font.DemiBold
                      }
                    }
                    Rectangle {
                      width: 28
                      height: 28
                      radius: Colors.radiusMedium
                      color: index === launcherRoot.selectedIndex ? Colors.withAlpha(Colors.primary, 0.18) : "transparent"
                      Text { anchors.centerIn: parent; text: "󰄮"; color: index === launcherRoot.selectedIndex ? Colors.primary : Colors.textDisabled; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeSmall }
                    }
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onEntered: if (!launcherRoot.ignoreMouseHover) launcherRoot.selectedIndex = index
                  onClicked: { launcherRoot.selectedIndex = index; launcherRoot.executeSelection(); }
                }
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
                Text { text: launcherRoot.modeIcons[launcherRoot.mode] || "󰈔"; color: Colors.textDisabled; font.family: Colors.fontMono; font.pixelSize: 26; Layout.alignment: Qt.AlignHCenter }
                Text { text: launcherRoot.emptyStateTitle; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.DemiBold; Layout.alignment: Qt.AlignHCenter }
                Text { text: launcherRoot.emptyStateSubtitle; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeSmall; Layout.alignment: Qt.AlignHCenter }
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

          ColumnLayout {
            spacing: Colors.paddingMedium
            Repeater {
              model: launcherRoot.mediaPlayers
              delegate: Rectangle {
                Layout.fillWidth: true
                height: 120
                color: Colors.bgWidget
                radius: Colors.radiusMedium
                border.color: Colors.border
                border.width: 1

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: Colors.paddingMedium
                  spacing: Colors.paddingMedium
                  Rectangle {
                    width: 90
                    height: 90
                    radius: Colors.radiusXS
                    color: Colors.surface
                    clip: true
                    Image { anchors.fill: parent; source: modelData.trackArtUrl || ""; sourceSize: Qt.size(128, 128); asynchronous: true; fillMode: Image.PreserveAspectCrop }
                  }
                  ColumnLayout {
                    Layout.fillWidth: true
                    Text { text: modelData.trackTitle || "Unknown"; color: Colors.text; font.pixelSize: Colors.fontSizeLarge; font.weight: Font.Bold; elide: Text.ElideRight }
                    Text { text: modelData.trackArtist || "Unknown"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeSmall }
                    Item { Layout.fillHeight: true }
                    RowLayout {
                      spacing: Colors.paddingMedium
                      Rectangle {
                        width: 30; height: 30; radius: height / 2
                        color: "transparent"
                        Text { anchors.centerIn: parent; text: "󰒮"; color: Colors.text; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL }
                        SharedWidgets.StateLayer { id: prevStateLayer; hovered: prevHover.containsMouse; pressed: prevHover.pressed }
                        MouseArea {
                          id: prevHover
                          anchors.fill: parent
                          hoverEnabled: true
                          cursorShape: Qt.PointingHandCursor
                          onClicked: (mouse) => {
                            prevStateLayer.burst(mouse.x, mouse.y);
                            (modelData._controlTarget || modelData).previous();
                          }
                        }
                      }
                      Rectangle {
                        width: 36; height: 36; radius: height / 2
                        color: "transparent"
                        Text { anchors.centerIn: parent; text: (modelData._controlTarget || modelData).playbackState === Mpris.Playing ? "󰏤" : "󰐊"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeHuge }
                        SharedWidgets.StateLayer { id: playStateLayer; hovered: playHover.containsMouse; pressed: playHover.pressed }
                        MouseArea {
                          id: playHover
                          anchors.fill: parent
                          hoverEnabled: true
                          cursorShape: Qt.PointingHandCursor
                          onClicked: (mouse) => {
                            playStateLayer.burst(mouse.x, mouse.y);
                            (modelData._controlTarget || modelData).playPause();
                          }
                        }
                      }
                      Rectangle {
                        width: 30; height: 30; radius: height / 2
                        color: "transparent"
                        Text { anchors.centerIn: parent; text: "󰒭"; color: Colors.text; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL }
                        SharedWidgets.StateLayer { id: nextStateLayer; hovered: nextHover.containsMouse; pressed: nextHover.pressed }
                        MouseArea {
                          id: nextHover
                          anchors.fill: parent
                          hoverEnabled: true
                          cursorShape: Qt.PointingHandCursor
                          onClicked: (mouse) => {
                            nextStateLayer.burst(mouse.x, mouse.y);
                            (modelData._controlTarget || modelData).next();
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }

    Rectangle {
      anchors.fill: parent
      visible: launcherRoot.showingConfirm
      color: Colors.withAlpha(Colors.background, 0.9)
      radius: Colors.radiusLarge

      ColumnLayout {
        anchors.centerIn: parent
        spacing: 25
        Text { text: launcherRoot.confirmTitle; color: Colors.text; font.pixelSize: Colors.fontSizeXL; font.bold: true; Layout.alignment: Qt.AlignHCenter }
        RowLayout {
          spacing: Colors.paddingMedium
          Layout.alignment: Qt.AlignHCenter
          Rectangle {
            width: 100; height: 40; radius: Colors.radiusLarge
            color: Colors.error
            Text { text: "Yes"; color: Colors.text; anchors.centerIn: parent; font.bold: true }
            SharedWidgets.StateLayer { id: yesStateLayer; hovered: yesHover.containsMouse; pressed: yesHover.pressed; stateColor: Colors.error }
            MouseArea {
              id: yesHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: (mouse) => {
                yesStateLayer.burst(mouse.x, mouse.y);
                launcherRoot.doConfirm();
              }
            }
          }
          Rectangle {
            width: 100; height: 40; radius: Colors.radiusLarge
            color: Colors.surface
            Text { text: "No"; color: Colors.text; anchors.centerIn: parent; font.bold: true }
            SharedWidgets.StateLayer { id: noStateLayer; hovered: noHover.containsMouse; pressed: noHover.pressed }
            MouseArea {
              id: noHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: (mouse) => {
                noStateLayer.burst(mouse.x, mouse.y);
                launcherRoot.cancelConfirm();
              }
            }
          }
        }
      }

      Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) launcherRoot.doConfirm();
        else if (event.key === Qt.Key_Escape) launcherRoot.cancelConfirm();
        event.accepted = true;
      }
    }
  }
}
