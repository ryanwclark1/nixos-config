import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import "../services"

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
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  WlrLayershell.namespace: "quickshell"

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
  property int openCount: 0

  readonly property bool showLauncherHome: Config.launcherShowHomeSections && searchText === "" && (mode === "drun" || mode === "system" || mode === "files")
  readonly property var modeOrder: ["drun", "window", "files", "ai", "clip", "emoji", "calc", "web", "run", "system", "keybinds", "media"]
  readonly property var primaryModes: ["drun", "window", "files", "ai", "clip", "system", "media"]
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
    "media": { label: "Media", hint: "Control active players", prefix: "" }
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
    "media": "󰝚"
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
    if (mode === "files") return "Type at least two characters to search files";
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

  function modeInfo(key) {
    return launcherRoot.modeMeta[key] || { label: key.toUpperCase(), hint: "", prefix: "" };
  }

  function stripModePrefix(text) {
    if (text.length > 0 && modePrefixes.indexOf(text[0]) !== -1)
      return text.substring(1).trim();
    return text;
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
      if (next.length >= 12) break;
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
      var apps = modeCache["drun"] || [];
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
      if (recent.length < 6) {
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
      recentItems = recent.slice(0, 6);
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
      suggestionItems = suggestions.slice(0, 4);
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

  function open(newMode, keepSearch) {
    if (showingConfirm) cancelConfirm();
    openCount++;
    if (openCount % 10 === 0) modeCache = {};
    mode = newMode || "drun";
    buildLauncherHome();
    if (!keepSearch) {
      searchText = "";
      if (searchInput) searchInput.text = "";
    }
    selectedIndex = 0;
    launcherOpacity = 1;
    scaleValue = 1.0;
    if (searchInput) searchInput.forceActiveFocus();

    if (mode === "drun") loadApps();
    else if (mode === "window") loadWindows();
    else if (mode === "run") loadRun();
    else if (mode === "emoji") loadEmojis();
    else if (mode === "clip") loadClip();
    else if (mode === "calc") { allItems = []; filterItems(); }
    else if (mode === "web") loadWeb();
    else if (mode === "system") loadSystem();
    else if (mode === "media") { allItems = []; filterItems(); }
    else if (mode === "nixos") loadNixos();
    else if (mode === "wallpapers") loadWallpapers();
    else if (mode === "files") loadFiles();
    else if (mode === "bookmarks") loadBookmarks();
    else if (mode === "ai") loadAi();
    else if (mode === "keybinds") loadKeybinds();
    else if (mode === "dmenu") filterItems();
  }

  function close() {
    if (searchInput && searchInput.activeFocus) searchInput.focus = false;
    launcherOpacity = 0;
    scaleValue = 0.95;
    if (showingConfirm) confirmTitle = "";
    WlrLayershell.keyboardFocus = WlrKeyboardFocus.None;
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
    if (modeCache[modeKey]) {
      allItems = modeCache[modeKey];
      filterItems();
      return;
    }
    allItems = [{ name: "Loading...", isHint: true, icon: "󰔟" }];
    filterItems();
    runCommand(command, function(raw) {
      try {
        if (raw) {
          var items = parseFunc(raw);
          modeCache[modeKey] = items;
          if (mode === modeKey) {
            allItems = items;
            filterItems();
            buildLauncherHome();
          }
        }
      } catch (e) {}
    });
  }

  function loadApps() { loadCached("drun", ["qs-apps"], JSON.parse); }
  function loadRun() { loadCached("run", ["qs-run"], JSON.parse); }
  function loadWallpapers() { loadCached("wallpapers", ["qs-wallpapers"], JSON.parse); }
  function loadKeybinds() { loadCached("keybinds", ["qs-keybinds"], JSON.parse); }
  function loadBookmarks() { loadCached("bookmarks", ["qs-bookmarks"], JSON.parse); }

  function loadEmojis() {
    loadCached("emoji", ["qs-emoji"], function(raw) {
      var lines = raw.split("\n");
      var items = [];
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].trim() !== "") {
          var parts = lines[i].split(" ");
          items.push({ name: parts[0], title: parts.slice(1).join(" ") });
        }
      }
      return items;
    });
  }

  function loadClip() {
    loadCached("clip", ["qs-clip"], function(raw) {
      return JSON.parse(raw).filter(function(it) {
        return it.content && it.content.indexOf("[[ binary data") === -1;
      }).map(function(it) {
        return { id: it.id, name: it.content, title: it.content, icon: "󰅍" };
      });
    });
  }

  function loadFiles() {
    var searchQuery = searchText.startsWith("/") ? searchText.substring(1).trim() : searchText;
    if (searchQuery.length < 2) {
      allItems = [];
      filterItems();
      return;
    }
    runCommand(["fd", "--base-directory", Quickshell.env("HOME"), "--max-results", "100", searchQuery], function(raw) {
      if (raw) {
        var lines = raw.split("\n");
        var items = [];
        for (var i = 0; i < lines.length; i++) {
          if (lines[i].trim() !== "") {
            var path = lines[i];
            var parts = path.split("/");
            items.push({ name: parts[parts.length - 1] || path, title: path, fullPath: Quickshell.env("HOME") + "/" + path });
          }
        }
        allItems = items;
        filterItems();
      }
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
    runCommand(["qs-ai", query], function(raw) {
      raw = raw.trim();
      if (raw) allItems = [{ name: "AI Response", title: "Click to copy response", body: raw, icon: "󰚩" }];
      else allItems = [];
      filterItems();
    });
  }

  function loadWeb() {
    allItems = [
      { name: "Google", exec: "https://www.google.com/search?q=", icon: "󰊯", isWeb: true },
      { name: "DuckDuckGo", exec: "https://duckduckgo.com/?q=", icon: "󰇥", isWeb: true },
      { name: "YouTube", exec: "https://www.youtube.com/results?search_query=", icon: "󰗃", isWeb: true },
      { name: "NixOS Packages", exec: "https://search.nixos.org/packages?query=", icon: "", isWeb: true },
      { name: "GitHub", exec: "https://github.com/search?q=", icon: "󰊤", isWeb: true }
    ];
    filterItems();
  }

  function loadSystem() {
    allItems = [
      { category: "Power", name: "Shutdown", icon: "󰐥", action: () => askConfirm("Shutdown system?", () => Quickshell.execDetached(["systemctl", "poweroff"])) },
      { category: "Power", name: "Reboot", icon: "󰑐", action: () => askConfirm("Reboot system?", () => Quickshell.execDetached(["systemctl", "reboot"])) },
      { category: "Power", name: "Lock Screen", icon: "󰌾", action: () => Quickshell.execDetached(["hyprlock"]) },
      { category: "Power", name: "Log Out", icon: "󰍃", action: () => askConfirm("Log out of session?", () => Quickshell.execDetached(["hyprctl", "dispatch", "exit"])) },
      { category: "Capture", name: "Screenshot (Area)", icon: "󰹑", action: () => Quickshell.execDetached(["screenshot-enhanced", "region"]) },
      { category: "Capture", name: "Screenshot (Display)", icon: "󰍹", action: () => Quickshell.execDetached(["screenshot-enhanced", "output"]) },
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
      fuzzyMatch(name, clean),
      fuzzyMatch(title, clean) * 0.92,
      fuzzyMatch(exec, clean) * 0.88,
      fuzzyMatch(body, clean) * 0.75
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
      filteredItems = scoredItems;
    }
    selectedIndex = Math.min(selectedIndex, Math.max(0, filteredItems.length - 1));
  }

  function copyToClipboard(text) {
    Quickshell.execDetached(["bash", "-c", "echo -n '" + text.replace(/'/g, "'\\''") + "' | wl-copy"]);
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
    if (filteredItems.length === 0 || selectedIndex < 0) return;
    var item = filteredItems[selectedIndex];

    if (mode === "drun") {
      trackLaunch(item);
      if (item.terminal === "true" || item.terminal === "True") Quickshell.execDetached(["kitty", "-e", "bash", "-c", item.exec]);
      else if (item.exec) Quickshell.execDetached(item.exec.split(" "));
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
      Quickshell.execDetached(["bash", "-c", "cliphist decode " + item.id + " | wl-copy"]);
      close();
    } else if (mode === "web" || mode === "bookmarks") {
      rememberRecent({ name: item.name || "Link", title: item.title || item.exec || "", icon: item.icon || "󰖟", exec: item.exec || "" });
      Quickshell.execDetached(["xdg-open", item.exec + (item.query ? encodeURIComponent(item.query) : "")]);
      close();
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
      if (item.disp) Quickshell.execDetached(["hyprctl", "dispatch", item.disp, item.args]);
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
    function toggle() { if (launcherRoot.launcherOpacity > 0) launcherRoot.close(); else launcherRoot.open(Config.launcherDefaultMode || "drun"); }
  }

  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.5)
    opacity: launcherOpacity
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
          anchors.margins: 14
          spacing: 10

          Text { text: "Launcher"; color: Colors.fgMain; font.pixelSize: 20; font.weight: Font.DemiBold }
          Text { text: "Modes"; color: Colors.textDisabled; font.pixelSize: 10; font.weight: Font.Bold }

          Repeater {
            model: launcherRoot.primaryModes
            delegate: Rectangle {
              Layout.fillWidth: true
              implicitHeight: 46
              radius: Colors.radiusMedium
              color: launcherRoot.mode === modelData ? Colors.highlight : Colors.bgWidget
              border.color: launcherRoot.mode === modelData ? Colors.primary : "transparent"
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10
                Text { text: launcherRoot.modeIcons[modelData] || "•"; color: launcherRoot.mode === modelData ? Colors.primary : Colors.textSecondary; font.family: Colors.fontMono; font.pixelSize: 16 }
                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 0
                  Text { text: launcherRoot.modeInfo(modelData).label; color: Colors.fgMain; font.pixelSize: 12; font.weight: Font.DemiBold }
                  Text { text: launcherRoot.modeInfo(modelData).hint; color: Colors.textSecondary; font.pixelSize: 9; elide: Text.ElideRight; Layout.fillWidth: true }
                }
              }

              MouseArea { anchors.fill: parent; onClicked: launcherRoot.open(modelData, true) }
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
              anchors.margins: 12
              spacing: 2
              Text { text: "Controls"; color: Colors.textDisabled; font.pixelSize: 10; font.weight: Font.Bold }
              Text { text: "Tab to cycle modes"; color: Colors.fgMain; font.pixelSize: 12 }
              Text { text: "Enter to run • Esc to close"; color: Colors.textSecondary; font.pixelSize: 10 }
            }
          }
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 15

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
            spacing: 15
            Text { text: ""; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: 20 }
            TextInput {
              id: searchInput
              Layout.fillWidth: true
              color: Colors.text
              font.pixelSize: 18
              clip: true
              text: launcherRoot.searchText
              enabled: !launcherRoot.showingConfirm
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
                  launcherRoot.filterItems();
                }
              }
              Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) launcherRoot.close();
                else if (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier)) {
                  launcherRoot.cycleMode(-1);
                  event.accepted = true;
                } else if (event.key === Qt.Key_Tab) {
                  launcherRoot.cycleMode(1);
                  event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                  if (launcherRoot.mode === "ai" && launcherRoot.filteredItems.length === 0) launcherRoot.loadAi();
                  else if (launcherRoot.mode === "files" && launcherRoot.searchText.length > 1 && launcherRoot.filteredItems.length === 0) launcherRoot.loadFiles();
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
              height: 28
              width: modeText.implicitWidth + 32
              radius: height / 2
              color: Colors.highlight
              Text { 
                id: modeText
                anchors.centerIn: parent
                text: launcherRoot.modeInfo(launcherRoot.mode).label
                color: Colors.primary
                font.pixelSize: 11
                font.weight: Font.DemiBold
              }
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: 10
          visible: Config.launcherShowModeHints && launcherRoot.showLauncherHome
          Text { Layout.fillWidth: true; text: launcherRoot.modeInfo(launcherRoot.mode).hint; color: Colors.textSecondary; font.pixelSize: 11; elide: Text.ElideRight }
          Text { text: "Balanced keyboard + mouse flow"; color: Colors.textDisabled; font.pixelSize: 10 }
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
            anchors.margins: 14
            spacing: 12
            Text { text: "Featured"; color: Colors.textDisabled; font.pixelSize: 10; font.weight: Font.Bold }
            RowLayout {
              Layout.fillWidth: true
              spacing: 10
              Repeater {
                model: launcherRoot.featuredActions
                delegate: Rectangle {
                  Layout.fillWidth: true
                  implicitHeight: 74
                  radius: Colors.radiusMedium
                  color: featureHover.containsMouse ? Colors.highlightLight : Colors.surface
                  border.color: Colors.border
                  border.width: 1

                  ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 4
                    Text { text: modelData.icon; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: 18 }
                    Text { text: modelData.label; color: Colors.fgMain; font.pixelSize: 12; font.weight: Font.DemiBold; elide: Text.ElideRight }
                    Text { text: modelData.description; color: Colors.textSecondary; font.pixelSize: 10; elide: Text.ElideRight }
                  }

                  MouseArea { id: featureHover; anchors.fill: parent; hoverEnabled: true; onClicked: launcherRoot.activateFeatured(modelData) }
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
            anchors.margins: 14
            spacing: 8
            Text { text: "Recent"; color: Colors.textDisabled; font.pixelSize: 10; font.weight: Font.Bold }

            Repeater {
              model: launcherRoot.recentItems
              delegate: Rectangle {
                Layout.fillWidth: true
                implicitHeight: 40
                radius: Colors.radiusSmall
                color: recentHover.containsMouse ? Colors.highlightLight : "transparent"

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: 8
                  spacing: 10
                  Text { text: modelData.icon || "󰀻"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: 14 }
                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text { text: modelData.name || modelData.label; color: Colors.fgMain; font.pixelSize: 12; font.weight: Font.DemiBold; elide: Text.ElideRight }
                    Text { text: modelData.title || modelData.description || ""; color: Colors.textSecondary; font.pixelSize: 10; elide: Text.ElideRight }
                  }
                }

                MouseArea { id: recentHover; anchors.fill: parent; hoverEnabled: true; onClicked: launcherRoot.activateFeatured(modelData) }
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
            anchors.margins: 14
            spacing: 8
            Text { text: "Suggested"; color: Colors.textDisabled; font.pixelSize: 10; font.weight: Font.Bold }

            Repeater {
              model: launcherRoot.suggestionItems
              delegate: Rectangle {
                Layout.fillWidth: true
                implicitHeight: 42
                radius: Colors.radiusSmall
                color: suggestionHover.containsMouse ? Colors.highlightLight : "transparent"

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: 8
                  spacing: 10
                  Text { text: modelData.icon || "󰀻"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: 14 }
                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text { text: modelData.name || modelData.label; color: Colors.fgMain; font.pixelSize: 12; font.weight: Font.DemiBold; elide: Text.ElideRight }
                    Text { text: (modelData.exec || modelData.title || "Frequently used"); color: Colors.textSecondary; font.pixelSize: 10; elide: Text.ElideRight }
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
                      font.pixelSize: 10
                      font.weight: Font.Medium
                    }
                  }
                }

                MouseArea {
                  id: suggestionHover
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: {
                    launcherRoot.selectedIndex = 0;
                    if (modelData.exec) {
                      launcherRoot.trackLaunch(modelData);
                      if (modelData.terminal === "true" || modelData.terminal === "True") Quickshell.execDetached(["kitty", "-e", "bash", "-c", modelData.exec]);
                      else Quickshell.execDetached(modelData.exec.split(" "));
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
              spacing: 8
              currentIndex: launcherRoot.selectedIndex
              enabled: !launcherRoot.showingConfirm
              section.property: "category"
              section.delegate: Text { text: section; color: Colors.primary; font.pixelSize: 10; font.bold: true; height: 25; verticalAlignment: Text.AlignBottom }

              delegate: Rectangle {
                width: resultsList.width
                height: 58
                color: index === launcherRoot.selectedIndex ? Colors.highlight : "transparent"
                radius: Colors.radiusSmall

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 12
                  anchors.rightMargin: 12
                  spacing: 15

                  Rectangle {
                    width: 34
                    height: 34
                    radius: 8
                    color: Colors.surface
                    Image {
                      id: iconImage
                      anchors.fill: parent
                      anchors.margins: 4
                      source: modelData.icon && modelData.icon.startsWith("/") ? "file://" + modelData.icon : ""
                      fillMode: Image.PreserveAspectCrop
                      visible: source !== "" && status === Image.Ready
                    }
                    Text {
                      anchors.centerIn: parent
                      text: modelData.icon || launcherRoot.modeIcons[launcherRoot.mode] || "󰀻"
                      color: Colors.primary
                      font.family: Colors.fontMono
                      font.pixelSize: 18
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
                      font.pixelSize: 14
                      font.weight: index === launcherRoot.selectedIndex ? Font.Bold : Font.Normal
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                    }
                    Text {
                      text: modelData.exec || modelData.class || modelData.title || ""
                      color: Colors.textSecondary
                      font.pixelSize: 10
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                      visible: text !== "" && text !== (modelData.name || "")
                    }
                  }

                  Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: index === launcherRoot.selectedIndex ? Colors.withAlpha(Colors.primary, 0.18) : "transparent"
                    Text { anchors.centerIn: parent; text: "󰄮"; color: index === launcherRoot.selectedIndex ? Colors.primary : Colors.textDisabled; font.family: Colors.fontMono; font.pixelSize: 12 }
                  }
                }

                MouseArea { anchors.fill: parent; hoverEnabled: true; onClicked: { launcherRoot.selectedIndex = index; launcherRoot.executeSelection(); } }
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
                spacing: 8
                Text { text: launcherRoot.modeIcons[launcherRoot.mode] || "󰈔"; color: Colors.textDisabled; font.family: Colors.fontMono; font.pixelSize: 26; Layout.alignment: Qt.AlignHCenter }
                Text { text: launcherRoot.emptyStateTitle; color: Colors.fgMain; font.pixelSize: 14; font.weight: Font.DemiBold; Layout.alignment: Qt.AlignHCenter }
                Text { text: launcherRoot.emptyStateSubtitle; color: Colors.textSecondary; font.pixelSize: 11; Layout.alignment: Qt.AlignHCenter }
              }
            }
          }

          ColumnLayout {
            spacing: 15
            Repeater {
              model: Mpris.players
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
                  spacing: 15
                  Rectangle {
                    width: 90
                    height: 90
                    radius: 8
                    color: Colors.surface
                    clip: true
                    Image { anchors.fill: parent; source: modelData.trackArtUrl || ""; fillMode: Image.PreserveAspectCrop }
                  }
                  ColumnLayout {
                    Layout.fillWidth: true
                    Text { text: modelData.trackTitle || "Unknown"; color: Colors.text; font.pixelSize: 16; font.weight: Font.Bold; elide: Text.ElideRight }
                    Text { text: modelData.trackArtist || "Unknown"; color: Colors.textSecondary; font.pixelSize: 12 }
                    Item { Layout.fillHeight: true }
                    RowLayout {
                      spacing: 15
                      Text { text: "󰒮"; color: Colors.text; font.family: Colors.fontMono; font.pixelSize: 18; MouseArea { anchors.fill: parent; onClicked: modelData.previous() } }
                      Text { text: modelData.playbackState === Mpris.Playing ? "󰏤" : "󰐊"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: 24; MouseArea { anchors.fill: parent; onClicked: modelData.playPause() } }
                      Text { text: "󰒭"; color: Colors.text; font.family: Colors.fontMono; font.pixelSize: 18; MouseArea { anchors.fill: parent; onClicked: modelData.next() } }
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
        Text { text: launcherRoot.confirmTitle; color: Colors.text; font.pixelSize: 20; font.bold: true; Layout.alignment: Qt.AlignHCenter }
        RowLayout {
          spacing: 15
          Layout.alignment: Qt.AlignHCenter
          Rectangle { width: 100; height: 40; color: Colors.error; radius: 20; Text { text: "Yes"; color: Colors.text; anchors.centerIn: parent; font.bold: true } MouseArea { anchors.fill: parent; onClicked: launcherRoot.doConfirm() } }
          Rectangle { width: 100; height: 40; color: Colors.surface; radius: 20; Text { text: "No"; color: Colors.text; anchors.centerIn: parent; font.bold: true } MouseArea { anchors.fill: parent; onClicked: launcherRoot.cancelConfirm() } }
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
