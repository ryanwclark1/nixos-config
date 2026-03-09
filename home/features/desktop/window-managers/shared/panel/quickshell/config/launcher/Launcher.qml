import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
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
  visible: windowOpacity > 0

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  WlrLayershell.namespace: "quickshell"

  property var hyprState: null
  property string searchText: ""
  property var allItems: []
  property var filteredItems: []
  property int selectedIndex: 0
  property string mode: "drun" // drun, window, dmenu, run, emoji, calc, clip, web, system, nixos, media, wallpapers

  // Confirmation state
  property string confirmTitle: ""
  property var confirmCallback: null
  readonly property bool showingConfirm: confirmTitle !== ""

  property real windowOpacity: 0
  property real scaleValue: 0.95

  Behavior on windowOpacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

  // Spring animation for opening
  onWindowOpacityChanged: {
    if (windowOpacity > 0) {
        scaleValueAnimation.to = 1.0;
        scaleValueAnimation.start();
    } else {
        scaleValue = 0.95;
    }
  }
  SpringAnimation {
    id: scaleValueAnimation
    target: launcherRoot
    property: "scaleValue"
    spring: 3
    damping: 0.2
    mass: 1.0
  }

  function open(newMode, keepSearch) {
    loadFrequency();
    if (showingConfirm) cancelConfirm();
    mode = newMode || "drun"
    if (!keepSearch) {
        searchText = ""
        if (searchInput) searchInput.text = ""
    }
    selectedIndex = 0;
    windowOpacity = 1;
    if (searchInput) searchInput.forceActiveFocus();
    
    if (mode === "drun") {
      loadApps()
    } else if (mode === "window") {
      loadWindows()
    } else if (mode === "run") {
      loadRun()
    } else if (mode === "emoji") {
      loadEmojis()
    } else if (mode === "clip") {
      loadClip()
    } else if (mode === "files") {
      loadFiles()
    } else if (mode === "calc") {
      allItems = []
      filterItems()
    } else if (mode === "web") {
      loadWeb()
    } else if (mode === "system") {
      loadSystem()
    } else if (mode === "media") {
      allItems = []
      filterItems()
    } else if (mode === "nixos") {
      loadNixos()
    } else if (mode === "wallpapers") {
      loadWallpapers()
    } else if (mode === "keybinds") {
      loadKeybinds()
    } else if (mode === "bookmarks") {
      loadBookmarks()
    } else if (mode === "ai") {
      loadAi()
    }
    }

    function close() {
    opacity = 0
    if (showingConfirm) confirmTitle = "";
    }

    function loadBookmarks() {
    var proc = Qt.createQmlObject('import Quickshell.Io; Process { running: false; command: ["qs-bookmarks"] }', launcherRoot);
    proc.finished.connect(function() {
      try {
        var raw = proc.stdout.readAll();
        if (raw) {
          allItems = JSON.parse(raw);
          filterItems();
        }
      } catch (e) { console.error("Failed to parse bookmarks JSON: " + e); }
    });
    proc.running = true;
    }

    function loadAi() {
    var query = searchText.startsWith("!") ? searchText.substring(1).trim() : searchText;
    if (query.length < 3) {
       allItems = [{ name: "Type your prompt...", isHint: true, icon: "󰚩" }];
       filterItems();
       return;
    }

    // We update the results list to show "Thinking..."
    allItems = [{ name: "Thinking...", isHint: true, icon: "󰚩" }];
    filterItems();

    var proc = Qt.createQmlObject('import Quickshell.Io; Process { running: false; command: ["qs-ai", "' + query.replace(/"/g, '\\"') + '"] }', launcherRoot);
    proc.finished.connect(function() {
      var raw = proc.stdout.readAll().trim();
      if (raw) {
        allItems = [{ name: "AI Response", title: "Click to copy response", body: raw, icon: "󰚩" }];
        filterItems();
      } else {
        allItems = [{ name: "AI error or no response", isHint: true, icon: "󰚩" }];
        filterItems();
      }
    });
    proc.running = true;
    }
    function loadKeybinds() {
    var proc = Qt.createQmlObject('import Quickshell.Io; Process { running: false; command: ["qs-keybinds"] }', launcherRoot);
    proc.finished.connect(function() {
      try {
        var raw = proc.stdout.readAll();
        if (raw) {
          allItems = JSON.parse(raw);
          filterItems();
        }
      } catch (e) { console.error("Failed to parse keybinds JSON: " + e); }
    });
    proc.running = true;
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
  
  function loadApps() {
    var proc = Qt.createQmlObject('import Quickshell.Io; Process { running: false; command: ["qs-apps"] }', launcherRoot);
    proc.finished.connect(function() {
      try {
        var raw = proc.stdout.readAll();
        if (raw) {
          allItems = JSON.parse(raw);
          filterItems();
        }
      } catch (e) { console.error("Failed to parse apps JSON: " + e); }
    });
    proc.running = true;
  }
  
  function loadRun() {
    var proc = Qt.createQmlObject('import Quickshell.Io; Process { running: false; command: ["qs-run"] }', launcherRoot);
    proc.finished.connect(function() {
      try {
        var raw = proc.stdout.readAll();
        if (raw) {
          allItems = JSON.parse(raw);
          filterItems();
        }
      } catch (e) { console.error("Failed to parse run JSON: " + e); }
    });
    proc.running = true;
  }

  function loadEmojis() {
    var proc = Qt.createQmlObject('import Quickshell.Io; Process { running: false; command: ["qs-emoji"] }', launcherRoot);
    proc.finished.connect(function() {
      var raw = proc.stdout.readAll();
      if (raw) {
        var lines = raw.split("\n");
        var items = [];
        for (var i = 0; i < lines.length; i++) {
          if (lines[i].trim() !== "") {
            var parts = lines[i].split(" ");
            var emoji = parts[0];
            var name = parts.slice(1).join(" ");
            items.push({ name: emoji, title: name });
          }
        }
        allItems = items;
        filterItems();
      }
    });
    proc.running = true;
  }

  function loadClip() {
    var proc = Qt.createQmlObject('import Quickshell.Io; Process { running: false; command: ["qs-clip"] }', launcherRoot);
    proc.finished.connect(function() {
      try {
        var raw = proc.stdout.readAll();
        if (raw) {
          var data = JSON.parse(raw);
          allItems = data.map(function(it) { return { id: it.id, name: it.content, title: it.content }; });
          filterItems();
        }
      } catch (e) { console.error("Failed to parse clip JSON: " + e); }
    });
    proc.running = true;
  }

  function loadFiles() {
    var searchQuery = searchText.startsWith("/") ? searchText.substring(1).trim() : searchText;
    if (searchQuery.length < 2) {
       allItems = [{ name: "Type to search files...", isHint: true, icon: "󰈔", fullPath: "" }];
       filterItems();
       return;
    }
    var proc = Qt.createQmlObject('import Quickshell.Io; Process { running: false; command: ["fd", "--base-directory", "/home/administrator", "--max-results", "100", "' + searchQuery.replace(/"/g, '\\"') + '"] }', launcherRoot);
    proc.finished.connect(function() {
      var raw = proc.stdout.readAll();
      if (raw) {
        var lines = raw.split("\n");
        var items = [];
        for (var i = 0; i < lines.length; i++) {
          if (lines[i].trim() !== "") {
            var path = lines[i];
            var parts = path.split("/");
            var filename = parts[parts.length - 1] || path;
            items.push({ name: filename, title: path, fullPath: "/home/administrator/" + path });
          }
        }
        if (items.length === 0) items = [{ name: "No files found", isHint: true, icon: "󰈔", fullPath: "" }];
        allItems = items;
        filterItems();
      }
    });
    proc.running = true;
  }

  function loadWallpapers() {
    var proc = Qt.createQmlObject('import Quickshell.Io; Process { running: false; command: ["qs-wallpapers"] }', launcherRoot);
    proc.finished.connect(function() {
      try {
        var raw = proc.stdout.readAll();
        if (raw) {
          allItems = JSON.parse(raw);
          filterItems();
        }
      } catch (e) { console.error("Failed to parse wallpapers JSON: " + e); }
    });
    proc.running = true;
  }
  
  function loadWeb() {
      allItems = [
        { name: "Google", exec: "https://www.google.com/search?q=", icon: "󰊯", isWeb: true },
        { name: "DuckDuckGo", exec: "https://duckduckgo.com/?q=", icon: "󰇥", isWeb: true },
        { name: "YouTube", exec: "https://www.youtube.com/results?search_query=", icon: "󰗃", isWeb: true },
        { name: "NixOS Packages", exec: "https://search.nixos.org/packages?query=", icon: "", isWeb: true },
        { name: "GitHub", exec: "https://github.com/search?q=", icon: "󰊤", isWeb: true }
      ]
      filterItems()
  }

  function loadSystem() {
      allItems = [
        // Power
        { category: "Power", name: "Shutdown", icon: "⏻", action: () => askConfirm("Shutdown system?", () => Quickshell.execDetached(["systemctl", "poweroff"])) },
        { category: "Power", name: "Reboot", icon: "🔄", action: () => askConfirm("Reboot system?", () => Quickshell.execDetached(["systemctl", "reboot"])) },
        { category: "Power", name: "Suspend", icon: "💤", action: () => Quickshell.execDetached(["systemctl", "suspend"]) },
        { category: "Power", name: "Lock Screen", icon: "🔒", action: () => Quickshell.execDetached(["hyprlock"]) },
        { category: "Power", name: "Log Out", icon: "🏠", action: () => askConfirm("Log out of session?", () => Quickshell.execDetached(["hyprctl", "dispatch", "exit"])) },
        
        // Capture
        { category: "Capture", name: "Screenshot (Area)", icon: "📷", action: () => Quickshell.execDetached(["screenshot-enhanced", "region"]) },
        { category: "Capture", name: "Screenshot (Display)", icon: "🖥️", action: () => Quickshell.execDetached(["screenshot-enhanced", "output"]) },
        { category: "Capture", name: "Color Picker", icon: "🎨", action: () => Quickshell.execDetached(["hyprpicker", "-a"]) },
        
        // Toggles
        { category: "Toggles", name: "Toggle Bluetooth", icon: "󰂯", action: () => { if(Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled; } },
        { category: "Toggles", name: "Toggle Night Light", icon: "🌙", action: () => { Quickshell.execDetached(["bash", "-c", "pgrep hyprsunset && pkill hyprsunset || hyprsunset &"]); } },
        
        // Utilities
        { category: "Utilities", name: "System Monitor (btop)", icon: "📊", action: () => Quickshell.execDetached(["kitty", "-e", "btop"]) },
        { category: "Utilities", name: "Audio Settings", icon: "🔊", action: () => Quickshell.execDetached(["kitty", "-e", "wiremix"]) }
      ]
      filterItems()
  }

  function loadNixos() {
    allItems = [
      { category: "System", name: "Rebuild Switch (flake)", icon: "󰒓", action: () => Quickshell.execDetached(["kitty", "-e", "sudo", "nixos-rebuild", "switch", "--flake", ".#"]) },
      { category: "System", name: "Update Flake Locks", icon: "󰚰", action: () => Quickshell.execDetached(["kitty", "-e", "nix", "flake", "update"]) },
      { category: "System", name: "Collect Garbage", icon: "󰃢", action: () => Quickshell.execDetached(["kitty", "-e", "sudo", "nix-env", "--delete-generations", "old"]) },
      { category: "Information", name: "System Generations", icon: "󰋚", action: () => Quickshell.execDetached(["kitty", "-e", "sudo", "nix-env", "-p", "/nix/var/nix/profiles/system", "--list-generations"]) }
    ]
    
    var proc = Qt.createQmlObject('import Quickshell.Io; Process { running: false; command: ["nixos-version"] }', launcherRoot);
    proc.finished.connect(function() {
      var ver = proc.stdout.readAll().trim();
      if (ver && mode === "nixos") {
        allItems.unshift({ category: "Information", name: "Current Version: " + ver, icon: "", action: null });
        filterItems();
      }
    });
    proc.running = true;
    
    filterItems();
  }

  function loadWindows() {
    if (hyprState) {
      allItems = hyprState.clients;
      filterItems();
    }
  }
  
  property var appFrequency: ({})
  readonly property string freqPath: Quickshell.statePath("app_frequency.json")

  function loadFrequency() {
    var file = Quickshell.openFile(freqPath, File.ReadOnly);
    if (file) {
      try {
        appFrequency = JSON.parse(file.readAll());
      } catch(e) {}
      file.close();
    }
  }

  function saveFrequency() {
    var file = Quickshell.openFile(freqPath, File.WriteOnly | File.Truncate);
    if (file) {
      file.write(JSON.stringify(appFrequency));
      file.close();
    }
  }

  function trackLaunch(exec) {
    if (!exec) return;
    appFrequency[exec] = (appFrequency[exec] || 0) + 1;
    saveFrequency();
  }

  function highlightMatch(fullText, query) {
    if (!query || !fullText) return fullText;
    var idx = fullText.toLowerCase().indexOf(query.toLowerCase());
    if (idx === -1) return fullText;
    return fullText.substring(0, idx) + "<b>" + fullText.substring(idx, idx + query.length) + "</b>" + fullText.substring(idx + query.length);
  }

  function fuzzyMatch(str, pattern) {
    if (!pattern) return 100;
    if (!str) return 0;
    var s = str.toLowerCase();
    var p = pattern.toLowerCase();
    if (s.startsWith(p)) return 100 + (p.length / s.length);
    if (s.includes(p)) return 50 + (p.length / s.length);
    
    var pIdx = 0;
    var sIdx = 0;
    while (sIdx < s.length && pIdx < p.length) {
      if (s[sIdx] === p[pIdx]) { pIdx++; }
      sIdx++;
    }
    if (pIdx === p.length) return 10 + (p.length / s.length);
    return 0;
  }

  function filterItems() {
    var actualSearch = searchText;
    
    if (mode === "calc") {
      actualSearch = searchText.startsWith("=") ? searchText.substring(1).trim() : searchText;
      try {
        if (actualSearch !== "") {
          var result = eval(actualSearch.replace(/[^-+/*() .0-9]/g, ''));
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

    if (actualSearch === "") {
      filteredItems = allItems;
    } else {
      var searchLower = actualSearch.toLowerCase();
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

        var name = (item.name || item.title || "");
        var exec = (item.exec || item.class || "");
        var bestScore = Math.max(fuzzyMatch(name, searchLower), fuzzyMatch(exec, searchLower));
        if (bestScore > 0) {
          item._score = bestScore;
          scoredItems.push(item);
        }
      }
      if (mode !== "web" && mode !== "system" && mode !== "nixos" && mode !== "wallpapers" && mode !== "keybinds" && mode !== "bookmarks" && mode !== "ai") {
          scoredItems.sort(function(a, b) { 
            if (b._score !== a._score) return b._score - a._score;
            // Frequency boost for equal scores
            if (mode === "drun") {
              var freqA = appFrequency[a.exec] || 0;
              var freqB = appFrequency[b.exec] || 0;
              return freqB - freqA;
            }
            return 0;
          });
      }
      filteredItems = scoredItems;
    }
    selectedIndex = Math.min(selectedIndex, Math.max(0, filteredItems.length - 1));
  }
  
  function executeSelection() {
    if (filteredItems.length > 0 && selectedIndex >= 0) {
      var item = filteredItems[selectedIndex];
      if (mode === "drun") {
        trackLaunch(item.exec);
        if (item.terminal && (item.terminal === "true" || item.terminal === "True")) {
          Quickshell.execDetached(["kitty", "-e", "bash", "-c", item.exec]);
        } else {
          Quickshell.execDetached(item.exec.split(" "));
        }
        close();
      } else if (mode === "run") {
        Quickshell.execDetached(["bash", "-c", item.exec]);
        close();
      } else if (mode === "window") {
        Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "address:" + item.address]);
        close();
      } else if (mode === "dmenu") {
        var fifoPath = "/tmp/qs-dmenu-result";
        Quickshell.execDetached(["bash", "-c", "echo '" + item.name + "' > " + fifoPath]);
        close();
      } else if (mode === "emoji") {
        Quickshell.execDetached(["bash", "-c", "echo -n '" + item.name + "' | wl-copy"]);
        close();
      } else if (mode === "calc") {
        Quickshell.execDetached(["bash", "-c", "echo -n '" + item.name + "' | wl-copy"]);
        close();
      } else if (mode === "clip") {
        Quickshell.execDetached(["bash", "-c", "cliphist decode " + item.id + " | wl-copy"]);
        close();
      } else if (mode === "web" || mode === "bookmarks") {
        Quickshell.execDetached(["xdg-open", item.exec + (item.query ? encodeURIComponent(item.query) : "")]);
        close();
      } else if (mode === "ai") {
        if (item.body) {
          Quickshell.execDetached(["bash", "-c", "echo -n '" + item.body.replace(/'/g, "'\\''") + "' | wl-copy"]);
          close();
        }
      } else if (mode === "files") {
        if (!item.isHint && item.fullPath) {
          Quickshell.execDetached(["xdg-open", item.fullPath]);
          close();
        }
      } else if (mode === "system" || mode === "nixos") {
        if (item.action) item.action();
        if (!showingConfirm) close();
      } else if (mode === "wallpapers") {
        Quickshell.execDetached(["swww", "img", item.path, "--transition-type", "grow", "--transition-pos", "0.5,0.5", "--transition-duration", "1.5"]);
        // Trigger wallust
        Quickshell.execDetached(["wallust", "run", item.path]);
        close();
      } else if (mode === "keybinds") {
        if (item.disp) {
          Quickshell.execDetached(["hyprctl", "dispatch", item.disp, item.args]);
        }
        close();
      }
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
  }

  // Backdrop
  MouseArea {
    anchors.fill: parent
    onClicked: launcherRoot.close()
    Rectangle { anchors.fill: parent; color: "#000000"; opacity: launcherRoot.windowOpacity * 0.5 }
  }

  Rectangle {
    id: mainBox
    width: 900
    height: 520
    anchors.centerIn: parent
    color: Colors.background
    opacity: launcherRoot.windowOpacity * 0.95
    border.color: Colors.border
    border.width: 1
    radius: Colors.radiusLarge
    scale: launcherRoot.scaleValue

    MouseArea { anchors.fill: parent }

    RowLayout {
      anchors.fill: parent
      spacing: 0

      // Sidebar
      Rectangle {
        width: 160
        Layout.fillHeight: true
        color: Qt.darker(Colors.background, 1.2)
        radius: Colors.radiusLarge
        
        Rectangle {
            anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
            width: 12; color: parent.color
        }

        ColumnLayout {
          anchors.fill: parent; anchors.margins: 10; spacing: 6
          Text { text: "LAUNCHER"; color: Colors.textDisabled; font.pixelSize: 11; font.bold: true; Layout.margins: 5; Layout.topMargin: 10 }

          Repeater {
             model: [
               { id: "drun", icon: "󰀻", label: "Apps" },
               { id: "window", icon: "󱗼", label: "Windows" },
               { id: "run", icon: "", label: "Run" },
               { id: "files", icon: "󰈔", label: "Files" },
               { id: "bookmarks", icon: "󰖟", label: "Bookmarks" },
               { id: "ai", icon: "󰚩", label: "AI Assistant" },
               { id: "web", icon: "󰖟", label: "Web Search" },
               { id: "emoji", icon: "󰞅", label: "Emoji" },
               { id: "clip", icon: "󰅍", label: "Clipboard" },
               { id: "calc", icon: "󰪚", label: "Calculator" },
               { id: "media", icon: "󰝚", label: "Media" },
               { id: "wallpapers", icon: "󰸉", label: "Wallpapers" },
               { id: "keybinds", icon: "󰌌", label: "Keybinds" },
               { id: "nixos", icon: "", label: "NixOS" },
               { id: "system", icon: "⚙️", label: "System" }
             ]
             delegate: Rectangle {
                Layout.fillWidth: true; height: 38; radius: Colors.radiusSmall
                color: launcherRoot.mode === modelData.id ? Colors.highlight : (sidebarMouse.containsMouse ? Colors.highlightLight : "transparent")
                RowLayout {
                  anchors.fill: parent; anchors.leftMargin: 12; spacing: 12
                  Text { text: modelData.icon; color: launcherRoot.mode === modelData.id ? Colors.primary : Colors.textSecondary; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16 }
                  Text { text: modelData.label; color: launcherRoot.mode === modelData.id ? Colors.text : Colors.textSecondary; font.pixelSize: 13 }
                }
                MouseArea { id: sidebarMouse; anchors.fill: parent; hoverEnabled: true; onClicked: launcherRoot.open(modelData.id, launcherRoot.searchText !== "") }
             }
          }
          Item { Layout.fillHeight: true }
        }
      }

      Rectangle { width: 1; Layout.fillHeight: true; color: Colors.border }

      ColumnLayout {
        Layout.fillWidth: true; Layout.fillHeight: true; Layout.margins: 15; spacing: 15

        // Search Bar
        Rectangle {
          Layout.fillWidth: true; height: 50; color: Colors.surface; radius: Colors.radiusSmall
          border.color: searchInput.activeFocus ? Colors.primary : Colors.border; border.width: 1
          RowLayout {
            anchors.fill: parent; anchors.leftMargin: 15; anchors.rightMargin: 15; spacing: 12
            Text { text: ""; color: Colors.textSecondary; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18 }
            TextInput {
              id: searchInput
              Layout.fillWidth: true; color: Colors.text; font.pixelSize: 16; clip: true; text: launcherRoot.searchText; enabled: !launcherRoot.showingConfirm
              onTextChanged: {
                var txt = text;
                if (txt.startsWith("=") && launcherRoot.mode !== "calc") launcherRoot.open("calc", true);
                else if (txt.startsWith(">") && launcherRoot.mode !== "run") launcherRoot.open("run", true);
                else if (txt.startsWith(":") && launcherRoot.mode !== "emoji") launcherRoot.open("emoji", true);
                else if (txt.startsWith("?") && launcherRoot.mode !== "web") launcherRoot.open("web", true);
                else if (txt.startsWith("!") && launcherRoot.mode !== "ai") launcherRoot.open("ai", true);
                else if (txt.startsWith("@") && launcherRoot.mode !== "bookmarks") launcherRoot.open("bookmarks", true);
                if (launcherRoot.searchText !== text) { launcherRoot.searchText = text; launcherRoot.filterItems(); }
              }
              Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                  if (launcherRoot.mode === "dmenu") { var fifoPath = "/tmp/qs-dmenu-result"; Quickshell.execDetached(["bash", "-c", "echo '' > " + fifoPath]); }
                  launcherRoot.close();
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { 
                    if (launcherRoot.mode === "ai" && !launcherRoot.filteredItems[0].body) {
                        launcherRoot.loadAi();
                    } else {
                        launcherRoot.executeSelection(); 
                    }
                }
                else if (event.key === Qt.Key_Up || (event.key === Qt.Key_K && (event.modifiers & Qt.ControlModifier))) { launcherRoot.selectedIndex = Math.max(0, launcherRoot.selectedIndex - 1); event.accepted = true; }
                else if (event.key === Qt.Key_Down || (event.key === Qt.Key_J && (event.modifiers & Qt.ControlModifier))) { launcherRoot.selectedIndex = Math.min(launcherRoot.filteredItems.length - 1, launcherRoot.selectedIndex + 1); event.accepted = true; }
              }
            }
          }
        }

        // Results List
        ListView {
          id: resultsList
          visible: mode !== "media"
          Layout.fillWidth: true; Layout.fillHeight: true; model: launcherRoot.filteredItems; clip: true; spacing: 5; currentIndex: launcherRoot.selectedIndex; enabled: !launcherRoot.showingConfirm
          onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
          section.property: "category"
          section.delegate: Text { text: section; color: Colors.primary; font.pixelSize: 11; font.bold: true; Layout.margins: 5; height: 25; verticalAlignment: Text.AlignBottom }

          delegate: Rectangle {
            width: resultsList.width; height: mode === "clip" ? 60 : (mode === "wallpapers" ? 80 : 50); color: index === launcherRoot.selectedIndex ? Colors.highlight : (itemMouseArea.containsMouse ? Colors.highlightLight : "transparent"); radius: Colors.radiusSmall
            RowLayout {
              anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 12
              Rectangle {
                width: mode === "wallpapers" ? 100 : 32; height: mode === "wallpapers" ? 60 : 32; radius: 6; color: Colors.surface; visible: mode !== "dmenu" && mode !== "clip" && mode !== "calc"
                Image {
                  id: iconImage; anchors.fill: parent; anchors.margins: mode === "wallpapers" ? 0 : 4
                  source: modelData.path ? "file://" + modelData.path : (modelData.icon && modelData.icon.startsWith("/") ? "file://" + modelData.icon : "")
                  fillMode: Image.PreserveAspectCrop; visible: source != "" && status === Image.Ready
                }
                Text {
                  anchors.centerIn: parent; text: mode === "window" ? "󱗼" : (mode === "run" ? "" : (mode === "web" ? modelData.icon : (mode === "emoji" ? modelData.name : (mode === "keybinds" ? "󰌌" : (mode === "nixos" || mode === "system" ? modelData.icon : "󰀻")))))
                  color: Colors.textSecondary; font.family: (mode === "emoji" || mode === "system" || mode === "nixos" || mode === "keybinds") ? "Noto Color Emoji" : "JetBrainsMono Nerd Font"; font.pixelSize: (mode === "emoji" || mode === "system" || mode === "nixos" || mode === "keybinds") ? 22 : 18; visible: !iconImage.visible
                }
              }
              ColumnLayout {
                spacing: 2
                Text { 
                  text: {
                    var base = mode === "drun" ? modelData.name : (mode === "run" ? modelData.name : (mode === "emoji" ? modelData.title : (mode === "calc" ? modelData.title : (mode === "clip" ? modelData.name : (mode === "web" ? modelData.title : (mode === "nixos" ? modelData.name : (mode === "wallpapers" ? modelData.name : (mode === "keybinds" ? modelData.name : (mode === "files" ? modelData.name : (modelData.title || modelData.name))))))))));
                    return highlightMatch(base, searchText);
                  }
                  color: Colors.text
                  textFormat: Text.StyledText
                  font.pixelSize: mode === "calc" ? 18 : 14
                  font.weight: index === launcherRoot.selectedIndex ? Font.Bold : Font.Normal
                  elide: Text.ElideRight
                  Layout.fillWidth: true 
                }
                Text { 
                  text: {
                    var base = mode === "drun" ? modelData.exec : (mode === "run" ? "" : (mode === "wallpapers" ? modelData.path : (mode === "keybinds" ? modelData.desc : (mode === "files" ? modelData.title : (modelData.class || "")))));
                    return highlightMatch(base, searchText);
                  }
                  color: Colors.textSecondary
                  textFormat: Text.StyledText
                  font.pixelSize: 11
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                  visible: text !== "" && mode !== "calc" && mode !== "emoji" && mode !== "web" && mode !== "system" 
                }
              }
            }
            MouseArea { id: itemMouseArea; anchors.fill: parent; hoverEnabled: true; onClicked: { launcherRoot.selectedIndex = index; launcherRoot.executeSelection(); } }
          }
        }

        // Media View
        Flickable {
          id: mediaDashboard
          visible: mode === "media"
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true
          boundsBehavior: Flickable.StopAtBounds
          flickableDirection: Flickable.VerticalFlick
          contentWidth: mediaColumn.implicitWidth
          contentHeight: mediaColumn.implicitHeight

          ColumnLayout {
            id: mediaColumn
            width: parent.width
            spacing: 20
            Repeater {
              model: Mpris.players
              delegate: Rectangle {
                Layout.fillWidth: true; height: 180; color: Colors.highlightLight; radius: Colors.radiusLarge; border.color: Colors.border; border.width: 1; clip: true
                RowLayout {
                  anchors.fill: parent; anchors.margins: 20; spacing: 20
                  Rectangle { width: 140; height: 140; radius: Colors.radiusMedium; color: Colors.surface; clip: true
                    Image { anchors.fill: parent; source: modelData.trackArtUrl || ""; fillMode: Image.PreserveAspectCrop; visible: status === Image.Ready }
                    Text { anchors.centerIn: parent; text: "󰝚"; color: Colors.textDisabled; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 64; visible: parent.children[0].status !== Image.Ready }
                  }
                  ColumnLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true; spacing: 5
                    Text { text: modelData.identity || "Media Player"; color: Colors.primary; font.pixelSize: 12; font.weight: Font.Bold }
                    Text { text: modelData.trackTitle || "Unknown Track"; color: Colors.text; font.pixelSize: 22; font.weight: Font.Bold; Layout.fillWidth: true; elide: Text.ElideRight }
                    Text { text: modelData.trackArtist || "Unknown Artist"; color: Colors.textSecondary; font.pixelSize: 16; Layout.fillWidth: true; elide: Text.ElideRight }
                    Item { Layout.fillHeight: true }
                    Rectangle { Layout.fillWidth: true; height: 6; radius: 3; color: Colors.surface; visible: modelData.length > 0
                      Rectangle { height: parent.height; width: modelData.length > 0 ? parent.width * (modelData.position / modelData.length) : 0; radius: 3; color: Colors.primary }
                      MouseArea { anchors.fill: parent; onClicked: (mouse) => { if (modelData.length > 0) modelData.position = modelData.length * (mouse.x / width); } }
                    }
                    Item { Layout.preferredHeight: 5 }
                    RowLayout { 
                      spacing: 30
                      Layout.alignment: Qt.AlignHCenter
                      Rectangle {
                        width: 40
                        height: 40
                        radius: 20
                        color: prevHover.containsMouse ? Colors.surface : "transparent"
                        Text {
                          text: "󰒮"
                          color: Colors.text
                          font.family: "JetBrainsMono Nerd Font"
                          font.pixelSize: 24
                          anchors.centerIn: parent
                        }
                        MouseArea {
                          id: prevHover
                          anchors.fill: parent
                          hoverEnabled: true
                          onClicked: modelData.previous()
                        }
                      }
                      Rectangle {
                        width: 50
                        height: 50
                        radius: 25
                        color: Colors.primary
                        Text {
                          text: modelData.playbackState === Mpris.Playing ? "󰏤" : "󰐊"
                          color: Colors.background
                          font.family: "JetBrainsMono Nerd Font"
                          font.pixelSize: 28
                          anchors.centerIn: parent
                        }
                        MouseArea {
                          anchors.fill: parent
                          onClicked: modelData.playPause()
                        }
                      }
                      Rectangle {
                        width: 40
                        height: 40
                        radius: 20
                        color: nextHover.containsMouse ? Colors.surface : "transparent"
                        Text {
                          text: "󰒭"
                          color: Colors.text
                          font.family: "JetBrainsMono Nerd Font"
                          font.pixelSize: 24
                          anchors.centerIn: parent
                        }
                        MouseArea {
                          id: nextHover
                          anchors.fill: parent
                          hoverEnabled: true
                          onClicked: modelData.next()
                        }
                      }
                    }
                  }
                }
              }
            }
            Text { visible: Mpris.players.length === 0; text: "No active media players found."; color: Colors.textDisabled; font.pixelSize: 18; Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 40 }
          }
        }
      }

      Rectangle { width: 1; Layout.fillHeight: true; color: Colors.border; visible: mode === "drun" || mode === "window" || mode === "run" || mode === "clip" || mode === "emoji" || mode === "wallpapers" }

      // Preview Pane
      Rectangle {
        width: 250
        Layout.fillHeight: true
        color: "transparent"
        visible: mode === "drun" || mode === "window" || mode === "run" || mode === "clip" || mode === "emoji" || mode === "wallpapers" || mode === "files"
        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 20
          spacing: 15
          property var currentItem: launcherRoot.filteredItems.length > 0 && launcherRoot.selectedIndex >= 0 && launcherRoot.selectedIndex < launcherRoot.filteredItems.length ? launcherRoot.filteredItems[launcherRoot.selectedIndex] : null
          
          onCurrentItemChanged: {
            if (mode === "files" && currentItem && currentItem.fullPath) {
               if (!currentItem.fullPath.match(/\.(jpg|jpeg|png|webp|gif|pdf|zip|tar|gz|mp4|mkv|mp3|flac|wav)$/i)) {
                   filePreviewProc.command = ["head", "-n", "15", currentItem.fullPath];
                   filePreviewProc.running = true;
               } else {
                   previewTextContent.text = "Binary or media file.";
               }
            } else {
               previewTextContent.text = "";
            }
          }

          Process {
            id: filePreviewProc
            command: ["echo", ""]
            running: false
            stdout: StdioCollector {
              onStreamFinished: {
                if (mode === "files") {
                  previewTextContent.text = this.text;
                }
              }
            }
          }

          Rectangle {
            width: mode === "wallpapers" || (mode === "files" && parent.currentItem && parent.currentItem.fullPath && parent.currentItem.fullPath.match(/\.(jpg|jpeg|png|webp)$/i)) ? 210 : 128
            height: mode === "wallpapers" || (mode === "files" && parent.currentItem && parent.currentItem.fullPath && parent.currentItem.fullPath.match(/\.(jpg|jpeg|png|webp)$/i)) ? 140 : 128
            radius: Colors.radiusMedium
            color: Colors.surface
            Layout.alignment: Qt.AlignHCenter
            
            Image {
              id: previewIcon
              anchors.fill: parent
              anchors.margins: (mode === "wallpapers" || (mode === "files" && parent.parent.currentItem && parent.parent.currentItem.fullPath && parent.parent.currentItem.fullPath.match(/\.(jpg|jpeg|png|webp)$/i))) ? 0 : 10
              source: parent.parent.currentItem ? (parent.parent.currentItem.path ? "file://" + parent.parent.currentItem.path : (parent.parent.currentItem.icon && parent.parent.currentItem.icon.startsWith("/") ? "file://" + parent.parent.currentItem.icon : (mode === "files" && parent.parent.currentItem.fullPath && parent.parent.currentItem.fullPath.match(/\.(jpg|jpeg|png|webp)$/i) ? "file://" + parent.parent.currentItem.fullPath : ""))) : ""
              fillMode: Image.PreserveAspectFit
              visible: source != "" && status === Image.Ready
            }
            Text {
              anchors.centerIn: parent
              text: mode === "window" ? "󱗼" : (mode === "run" ? "" : (mode === "emoji" ? (parent.parent.currentItem ? parent.parent.currentItem.name : "") : (mode === "clip" ? "󰅍" : (mode === "files" ? "󰈔" : "󰀻"))))
              color: mode === "emoji" ? Colors.fgMain : Colors.textSecondary
              font.family: mode === "emoji" ? "Noto Color Emoji" : "JetBrainsMono Nerd Font"
              font.pixelSize: 64
              visible: !previewIcon.visible
            }
          }
          
          Text {
            text: parent.currentItem ? (mode === "drun" ? parent.currentItem.name : (mode === "window" ? parent.currentItem.title : (mode === "emoji" ? parent.currentItem.title : (mode === "clip" ? "Clipboard Item" : (mode === "wallpapers" ? "Wallpaper Preview" : (mode === "files" ? parent.currentItem.name : parent.currentItem.name)))))) : ""
            color: Colors.text
            font.pixelSize: 18
            font.weight: Font.Bold
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            maximumLineCount: 3
            elide: Text.ElideRight 
          }
          
          Text {
            id: subText
            text: parent.currentItem ? (mode === "drun" ? parent.currentItem.exec : (mode === "window" ? parent.currentItem.class : (mode === "clip" ? parent.currentItem.name : (mode === "wallpapers" ? parent.currentItem.name : (mode === "files" ? parent.currentItem.title : ""))))) : ""
            color: Colors.textSecondary
            font.pixelSize: 12
            Layout.fillWidth: true
            horizontalAlignment: (mode === "clip" || mode === "files") ? Text.AlignLeft : Text.AlignHCenter
            wrapMode: Text.Wrap
            maximumLineCount: mode === "clip" ? 10 : 2
            elide: Text.ElideRight
            visible: text !== "" && mode !== "emoji"
          }
          
          Rectangle { 
            Layout.fillWidth: true
            height: 1
            color: Colors.border
            Layout.topMargin: 10
            Layout.bottomMargin: 10 
          }
          
          Text {
            id: previewTextContent
            color: Colors.textSecondary
            font.pixelSize: 10
            font.family: "JetBrainsMono Nerd Font"
            Layout.fillWidth: true
            Layout.fillHeight: true
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            clip: true
            visible: mode === "files" && text !== ""
          }

          Text { 
            text: mode === "drun" ? "Press Enter to launch" : (mode === "window" ? "Press Enter to focus" : (mode === "emoji" || mode === "clip" ? "Press Enter to copy" : (mode === "wallpapers" ? "Press Enter to apply" : (mode === "files" ? "Press Enter to open" : "Press Enter to run"))))
            color: Colors.textDisabled
            font.pixelSize: 12
            Layout.alignment: Qt.AlignHCenter
          }
          
          Item {
            Layout.fillHeight: true
            visible: mode !== "files"
          }
        }
      }
    }

    // Confirmation Overlay
    Rectangle {
      id: confirmOverlay
      anchors.fill: parent
      visible: launcherRoot.showingConfirm
      color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.95)
      radius: Colors.radiusLarge

      ColumnLayout {
        anchors.centerIn: parent
        spacing: 30

        Text {
          text: launcherRoot.confirmTitle
          color: Colors.text
          font.pixelSize: 24
          font.bold: true
          Layout.alignment: Qt.AlignHCenter
        }

        RowLayout {
          spacing: 20
          Layout.alignment: Qt.AlignHCenter

          Rectangle {
            width: 120
            height: 45
            color: Colors.error
            radius: Colors.radiusSmall
            Text {
              text: "Yes"
              color: "white"
              anchors.centerIn: parent
              font.bold: true
            }
            MouseArea {
              anchors.fill: parent
              onClicked: launcherRoot.doConfirm()
            }
          }

          Rectangle {
            width: 120
            height: 45
            color: Colors.surface
            radius: Colors.radiusSmall
            Text {
              text: "No"
              color: Colors.text
              anchors.centerIn: parent
              font.bold: true
            }
            MouseArea {
              anchors.fill: parent
              onClicked: launcherRoot.cancelConfirm()
            }
          }
        }

        Text {
          text: "Press Enter for Yes, Esc for No"
          color: Colors.textSecondary
          font.pixelSize: 12
          Layout.alignment: Qt.AlignHCenter
        }
      }

      Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          launcherRoot.doConfirm();
        } else if (event.key === Qt.Key_Escape) {
          launcherRoot.cancelConfirm();
        }
        event.accepted = true;
      }
      Component.onCompleted: forceActiveFocus()
      onVisibleChanged: if (visible) forceActiveFocus()
    }
  }
}
