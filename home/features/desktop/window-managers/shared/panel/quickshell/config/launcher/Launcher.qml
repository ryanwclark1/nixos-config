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
  property string mode: "drun" // drun, window, dmenu, run, emoji, calc, clip, web, system, nixos, media, wallpapers, files, bookmarks, ai, keybinds
  
  // Confirmation state
  property string confirmTitle: ""
  property var confirmCallback: null
  readonly property bool showingConfirm: confirmTitle !== ""

  Behavior on launcherOpacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

  property real scaleValue: 0.95
  Behavior on scaleValue { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

  function open(newMode, keepSearch) {
    loadFrequency();
    if (showingConfirm) cancelConfirm();
    mode = newMode || "drun"
    if (!keepSearch) {
        searchText = ""
        if (searchInput) searchInput.text = ""
    }
    selectedIndex = 0
    launcherRoot.launcherOpacity = 1
    launcherRoot.scaleValue = 1.0
    if (searchInput) searchInput.forceActiveFocus()
    
    if (mode === "drun") loadApps()
    else if (mode === "window") loadWindows()
    else if (mode === "run") loadRun()
    else if (mode === "emoji") loadEmojis()
    else if (mode === "clip") loadClip()
    else if (mode === "calc") { allItems = []; filterItems(); }
    else if (mode === "web") loadWeb()
    else if (mode === "system") loadSystem()
    else if (mode === "media") { allItems = []; filterItems(); }
    else if (mode === "nixos") loadNixos()
    else if (mode === "wallpapers") loadWallpapers()
    else if (mode === "files") loadFiles()
    else if (mode === "bookmarks") loadBookmarks()
    else if (mode === "ai") loadAi()
    else if (mode === "keybinds") loadKeybinds()
    else if (mode === "dmenu") filterItems()
  }

  function close() {
    launcherRoot.launcherOpacity = 0
    launcherRoot.scaleValue = 0.95
    if (showingConfirm) confirmTitle = "";
    launcherRoot.WlrLayershell.keyboardFocus = WlrKeyboardFocus.None
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

  property var onCommandOutput: null
  
  property Process commandProc: Process {
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        if (launcherRoot.onCommandOutput) {
          launcherRoot.onCommandOutput(this.text || "");
        }
      }
    }
  }

  function runCommand(command, callback) {
    onCommandOutput = callback;
    commandProc.command = command;
    commandProc.running = true;
  }

  // --- Search Logic (Simplified) ---
  function loadApps() {
    runCommand(["qs-apps"], function(raw) { try { if (raw) { allItems = JSON.parse(raw); filterItems(); } } catch (e) {} });
  }
  function loadRun() {
    runCommand(["qs-run"], function(raw) { try { if (raw) { allItems = JSON.parse(raw); filterItems(); } } catch (e) {} });
  }
  function loadEmojis() {
    runCommand(["qs-emoji"], function(raw) { if (raw) { var lines = raw.split("\n"); var items = []; for (var i = 0; i < lines.length; i++) { if (lines[i].trim() !== "") { var parts = lines[i].split(" "); items.push({ name: parts[0], title: parts.slice(1).join(" ") }); } } allItems = items; filterItems(); } });
  }
  function loadClip() {
    runCommand(["qs-clip"], function(raw) { try { if (raw) { var data = JSON.parse(raw); allItems = data.map(function(it) { return { id: it.id, name: it.content, title: it.content }; }); filterItems(); } } catch (e) {} });
  }
  function loadWallpapers() {
    runCommand(["qs-wallpapers"], function(raw) { try { if (raw) { allItems = JSON.parse(raw); filterItems(); } } catch (e) {} });
  }
  function loadKeybinds() {
    runCommand(["qs-keybinds"], function(raw) { try { if (raw) { allItems = JSON.parse(raw); filterItems(); } } catch (e) {} });
  }
  function loadFiles() {
    var searchQuery = searchText.startsWith("/") ? searchText.substring(1).trim() : searchText;
    if (searchQuery.length < 2) { allItems = [{ name: "Type to search files...", isHint: true, icon: "󰈔", fullPath: "" }]; filterItems(); return; }
    runCommand(["fd", "--base-directory", Quickshell.env("HOME"), "--max-results", "100", searchQuery], function(raw) { if (raw) { var lines = raw.split("\n"); var items = []; for (var i = 0; i < lines.length; i++) { if (lines[i].trim() !== "") { var path = lines[i]; var parts = path.split("/"); items.push({ name: parts[parts.length - 1] || path, title: path, fullPath: Quickshell.env("HOME") + "/" + path }); } } if (items.length === 0) items = [{ name: "No files found", isHint: true, icon: "󰈔", fullPath: "" }]; allItems = items; filterItems(); } });
  }
  function loadBookmarks() {
    runCommand(["qs-bookmarks"], function(raw) { try { if (raw) { allItems = JSON.parse(raw); filterItems(); } } catch (e) {} });
  }
  function loadAi() {
    var query = searchText.startsWith("!") ? searchText.substring(1).trim() : searchText;
    if (query.length < 3) { allItems = [{ name: "Type your prompt...", isHint: true, icon: "󰚩" }]; filterItems(); return; }
    allItems = [{ name: "Thinking...", isHint: true, icon: "󰚩" }]; filterItems();
    runCommand(["qs-ai", query], function(raw) { raw = raw.trim(); if (raw) { allItems = [{ name: "AI Response", title: "Click to copy response", body: raw, icon: "󰚩" }]; filterItems(); } else { allItems = [{ name: "AI error or no response", isHint: true, icon: "󰚩" }]; filterItems(); } });
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
        { category: "Power", name: "Shutdown", icon: "⏻", action: () => askConfirm("Shutdown system?", () => Quickshell.execDetached(["systemctl", "poweroff"])) },
        { category: "Power", name: "Reboot", icon: "🔄", action: () => askConfirm("Reboot system?", () => Quickshell.execDetached(["systemctl", "reboot"])) },
        { category: "Power", name: "Suspend", icon: "💤", action: () => Quickshell.execDetached(["systemctl", "suspend"]) },
        { category: "Power", name: "Lock Screen", icon: "🔒", action: () => Quickshell.execDetached(["hyprlock"]) },
        { category: "Power", name: "Log Out", icon: "🏠", action: () => askConfirm("Log out of session?", () => Quickshell.execDetached(["hyprctl", "dispatch", "exit"])) },
        { category: "Capture", name: "Screenshot (Area)", icon: "📷", action: () => Quickshell.execDetached(["screenshot-enhanced", "region"]) },
        { category: "Capture", name: "Screenshot (Display)", icon: "🖥️", action: () => Quickshell.execDetached(["screenshot-enhanced", "output"]) },
        { category: "Capture", name: "Color Picker", icon: "🎨", action: () => Quickshell.execDetached(["hyprpicker", "-a"]) },
        { category: "Toggles", name: "Toggle Bluetooth", icon: "󰂯", action: () => { if(Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled; } },
        { category: "Toggles", name: "Toggle Night Light", icon: "🌙", action: () => { Quickshell.execDetached(["os-toggle-nightlight"]); } },
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
    runCommand(["nixos-version"], function(raw) { var ver = raw.trim(); if (ver && mode === "nixos") { allItems.unshift({ category: "Information", name: "Current Version: " + ver, icon: "", action: null }); filterItems(); } });
    filterItems();
  }
  function loadWindows() { 
    try {
      allItems = Hyprland.toplevels; 
    } catch(e) {
      allItems = [];
    }
    filterItems(); 
  }
  
  property var appFrequency: ({})
  readonly property string freqPath: Quickshell.statePath("app_frequency.json")
  
  property FileView freqFile: FileView {
    path: ""
    onLoaded: {
      try { launcherRoot.appFrequency = JSON.parse(text); } catch(e) {}
    }
  }

  function loadFrequency() {
    if (freqFile.path === "") freqFile.path = launcherRoot.freqPath;
    Quickshell.execDetached(["sh", "-c", "mkdir -p $(dirname " + freqPath + ") && touch " + freqPath]);
    freqFile.reload();
  }
  function saveFrequency() { freqFile.setText(JSON.stringify(appFrequency)); }
  function trackLaunch(exec) { if (!exec) return; appFrequency[exec] = (appFrequency[exec] || 0) + 1; saveFrequency(); }

  function highlightMatch(fullText, query) {
    if (!query || !fullText) return fullText;
    var cleanQuery = query.startsWith("!") || query.startsWith("/") || query.startsWith("@") || query.startsWith("?") || query.startsWith(">") || query.startsWith(":") || query.startsWith("=") ? query.substring(1).trim() : query;
    if (!cleanQuery) return fullText;
    var idx = fullText.toLowerCase().indexOf(cleanQuery.toLowerCase());
    if (idx === -1) return fullText;
    return fullText.substring(0, idx) + "<b>" + fullText.substring(idx, idx + cleanQuery.length) + "</b>" + fullText.substring(idx + cleanQuery.length);
  }

  function fuzzyMatch(str, pattern) {
    if (!pattern) return 100; if (!str) return 0;
    var s = str.toLowerCase();
    var p = (pattern.startsWith("!") || pattern.startsWith("/") || pattern.startsWith("@") || pattern.startsWith("?") || pattern.startsWith(">") || pattern.startsWith(":") || pattern.startsWith("=")) ? pattern.substring(1).trim() : pattern;
    p = p.toLowerCase(); if (!p) return 100;
    if (s.startsWith(p)) return 100 + (p.length / s.length);
    if (s.includes(p)) return 50 + (p.length / s.length);
    var pIdx = 0; var sIdx = 0; while (sIdx < s.length && pIdx < p.length) { if (s[sIdx] === p[pIdx]) { pIdx++; } sIdx++; }
    if (pIdx === p.length) return 10 + (p.length / s.length);
    return 0;
  }

  function filterItems() {
    var actualSearch = searchText;
    if (mode === "calc") {
      actualSearch = searchText.startsWith("=") ? searchText.substring(1).trim() : searchText;
      try { if (actualSearch !== "") { var result = eval(actualSearch.replace(/[^-+/*() .0-9]/g, '')); if (result !== undefined && !isNaN(result)) { filteredItems = [{ name: result.toString(), title: "Result: " + result, isCalc: true }]; selectedIndex = 0; return; } } } catch (e) {}
      filteredItems = []; return;
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
      var searchLower = actualSearch.toLowerCase();
      var scoredItems = [];
      for (var i = 0; i < allItems.length; i++) {
        var item = allItems[i];
        if (mode === "web") { var webItem = Object.assign({}, item); webItem.title = "Search " + item.name + " for '" + actualSearch + "'"; webItem.query = actualSearch; scoredItems.push(webItem); continue; }
        var name = (item.name || item.title || "");
        var exec = (item.exec || item.class || "");
        var bestScore = Math.max(fuzzyMatch(name, actualSearch), fuzzyMatch(exec, actualSearch));
        if (bestScore > 0 || (actualSearch === "" && (mode === "files" || mode === "ai"))) { item._score = bestScore; scoredItems.push(item); }
      }
      if (mode !== "web" && mode !== "system" && mode !== "nixos" && mode !== "wallpapers" && mode !== "keybinds" && mode !== "bookmarks" && mode !== "ai" && mode !== "files") {
          scoredItems.sort(function(a, b) { if (b._score !== a._score) return b._score - a._score; if (mode === "drun") { var freqA = appFrequency[a.exec] || 0; var freqB = appFrequency[b.exec] || 0; return freqB - freqA; } return 0; });
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
        if (item.terminal && (item.terminal === "true" || item.terminal === "True")) Quickshell.execDetached(["kitty", "-e", "bash", "-c", item.exec]);
        else if (item.exec) Quickshell.execDetached(item.exec.split(" "));
        close();
      } else if (mode === "run") { if (item.exec) Quickshell.execDetached(["bash", "-c", item.exec]); close(); }
      else if (mode === "window") { Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "address:" + item.address]); close(); }
      else if (mode === "dmenu") { var fifoPath = "/tmp/qs-dmenu-result"; Quickshell.execDetached(["bash", "-c", "echo '" + item.name + "' > " + fifoPath]); close(); }
      else if (mode === "emoji" || mode === "calc") { Quickshell.execDetached(["bash", "-c", "echo -n '" + item.name + "' | wl-copy"]); close(); }
      else if (mode === "clip") { Quickshell.execDetached(["bash", "-c", "cliphist decode " + item.id + " | wl-copy"]); close(); }
      else if (mode === "web" || mode === "bookmarks") { Quickshell.execDetached(["xdg-open", item.exec + (item.query ? encodeURIComponent(item.query) : "")]); close(); }
      else if (mode === "ai") { if (item.body) { Quickshell.execDetached(["bash", "-c", "echo -n '" + item.body.replace(/'/g, "'\\''") + "' | wl-copy"]); close(); } }
      else if (mode === "files") { if (!item.isHint && item.fullPath) { Quickshell.execDetached(["xdg-open", item.fullPath]); close(); } }
      else if (mode === "system" || mode === "nixos") { if (item.action) item.action(); if (!showingConfirm) close(); }
      else if (mode === "wallpapers") { Quickshell.execDetached(["swww", "img", item.path, "--transition-type", "grow", "--transition-pos", "0.5,0.5", "--transition-duration", "1.5"]); Quickshell.execDetached(["wallust", "run", item.path]); close(); }
      else if (mode === "keybinds") { if (item.disp) Quickshell.execDetached(["hyprctl", "dispatch", item.disp, item.args]); close(); }
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
      var items = []; try { items = JSON.parse(itemsJson); } catch (err) {}
      launcherRoot.mode = "dmenu";
      launcherRoot.allItems = items.map(function(it) { return { name: it, title: it }; });
      launcherRoot.open("dmenu");
    }
    function toggle() { if (launcherRoot.launcherOpacity > 0) launcherRoot.close(); else launcherRoot.open("drun"); }
  }

  // --- BACKGROUND ---
  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(0,0,0,0.5)
    opacity: launcherRoot.launcherOpacity
    MouseArea { anchors.fill: parent; onClicked: launcherRoot.close() }
  }

  // --- HUD CONTAINER ---
  Rectangle {
    id: hudBox
    width: 700; height: Math.min(650, 100 + (mode === "media" ? 400 : (filteredItems.length > 0 ? (Math.min(filteredItems.length, 8) * 60) + 20 : 0)))
    anchors.centerIn: parent
    color: Colors.bgGlass
    radius: Colors.radiusLarge
    border.color: Colors.border
    border.width: 1
    scale: launcherRoot.scaleValue
    clip: true

    Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }

    ColumnLayout {
      anchors.fill: parent; anchors.margins: Colors.paddingMedium; spacing: 15

      // Search Bar Pill
      Rectangle {
        Layout.fillWidth: true; height: 55; color: Colors.bgWidget; radius: 27.5
        border.color: searchInput.activeFocus ? Colors.primary : "transparent"
        border.width: 1

        RowLayout {
          anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 15
          Text { text: ""; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: 20 }
          TextInput {
            id: searchInput; Layout.fillWidth: true; color: Colors.text; font.pixelSize: 18; clip: true; text: launcherRoot.searchText; enabled: !launcherRoot.showingConfirm
            onTextChanged: {
              var txt = text;
              if (txt.startsWith("=") && launcherRoot.mode !== "calc") launcherRoot.open("calc", true);
              else if (txt.startsWith(">") && launcherRoot.mode !== "run") launcherRoot.open("run", true);
              else if (txt.startsWith(":") && launcherRoot.mode !== "emoji") launcherRoot.open("emoji", true);
              else if (txt.startsWith("?") && launcherRoot.mode !== "web") launcherRoot.open("web", true);
              else if (txt.startsWith("!") && launcherRoot.mode !== "ai") launcherRoot.open("ai", true);
              else if (txt.startsWith("@") && launcherRoot.mode !== "bookmarks") launcherRoot.open("bookmarks", true);
              else if (txt.startsWith("/") && launcherRoot.mode !== "files") launcherRoot.open("files", true);
              if (launcherRoot.searchText !== text) { launcherRoot.searchText = text; launcherRoot.filterItems(); }
            }
            Keys.onPressed: (event) => {
              if (event.key === Qt.Key_Escape) launcherRoot.close();
              else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { 
                  if (launcherRoot.mode === "ai" && launcherRoot.filteredItems.length > 0 && !launcherRoot.filteredItems[0].body) launcherRoot.loadAi();
                  else if (launcherRoot.mode === "files" && launcherRoot.searchText.length > 1 && (!launcherRoot.allItems[0] || launcherRoot.allItems[0].isHint)) launcherRoot.loadFiles();
                  else launcherRoot.executeSelection(); 
              }
              else if (event.key === Qt.Key_Up) { launcherRoot.selectedIndex = Math.max(0, launcherRoot.selectedIndex - 1); event.accepted = true; }
              else if (event.key === Qt.Key_Down) { launcherRoot.selectedIndex = Math.min(launcherRoot.filteredItems.length - 1, launcherRoot.selectedIndex + 1); event.accepted = true; }
            }
          }
          // Mode Indicator
          Rectangle {
            height: 24; width: modeText.implicitWidth + 20; radius: 12; color: Colors.highlight
            Text { id: modeText; anchors.centerIn: parent; text: launcherRoot.mode.toUpperCase(); color: Colors.primary; font.pixelSize: 9; font.weight: Font.Bold }
          }
        }
      }

      // Quick Modes Row
      RowLayout {
        Layout.fillWidth: true; spacing: 10
        visible: launcherRoot.searchText === ""
        Repeater {
          model: [
            { id: "drun", icon: "󰀻" }, { id: "window", icon: "󱗼" }, { id: "files", icon: "󰈔" }, { id: "ai", icon: "󰚩" }, { id: "clip", icon: "󰅍" }, { id: "media", icon: "󰝚" }, { id: "system", icon: "⚙️" }
          ]
          delegate: Rectangle {
            width: 40; height: 40; radius: 20; color: launcherRoot.mode === modelData.id ? Colors.primary : Colors.bgWidget
            Text { anchors.centerIn: parent; text: modelData.icon; color: launcherRoot.mode === modelData.id ? Colors.background : Colors.text; font.family: Colors.fontMono; font.pixelSize: 18 }
            MouseArea { anchors.fill: parent; hoverEnabled: true; onClicked: launcherRoot.open(modelData.id) }
          }
        }
      }

      // Results Area
      StackLayout {
        Layout.fillWidth: true; Layout.fillHeight: true; currentIndex: mode === "media" ? 1 : 0
        
        ListView {
          id: resultsList; model: launcherRoot.filteredItems; clip: true; spacing: 8; currentIndex: launcherRoot.selectedIndex; enabled: !launcherRoot.showingConfirm
          section.property: "category"; section.delegate: Text { text: section; color: Colors.primary; font.pixelSize: 10; font.bold: true; height: 25; verticalAlignment: Text.AlignBottom }
          delegate: Rectangle {
            width: resultsList.width; height: 50; color: index === launcherRoot.selectedIndex ? Colors.highlight : "transparent"; radius: Colors.radiusSmall
            RowLayout {
              anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 15
              Rectangle {
                width: 32; height: 32; radius: 8; color: Colors.surface
                Image { id: iconImage; anchors.fill: parent; anchors.margins: 4; source: modelData.icon && modelData.icon.startsWith("/") ? "file://" + modelData.icon : ""; fillMode: Image.PreserveAspectCrop; visible: source != "" && status === Image.Ready }
                Text { anchors.centerIn: parent; text: modelData.icon || (mode === "window" ? "󱗼" : (mode === "run" ? "" : (mode === "files" ? "󰈔" : "󰀻"))); color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: 18; visible: !iconImage.visible }
              }
              ColumnLayout {
                spacing: 1
                Text { text: highlightMatch(modelData.name || modelData.title || "", searchText); color: Colors.text; textFormat: Text.StyledText; font.pixelSize: 14; font.weight: index === launcherRoot.selectedIndex ? Font.Bold : Font.Normal; elide: Text.ElideRight; Layout.fillWidth: true }
                Text { text: modelData.exec || modelData.class || ""; color: Colors.textSecondary; font.pixelSize: 10; elide: Text.ElideRight; Layout.fillWidth: true; visible: text !== "" }
              }
            }
            MouseArea { anchors.fill: parent; hoverEnabled: true; onClicked: { launcherRoot.selectedIndex = index; launcherRoot.executeSelection(); } }
          }
        }

        // Media View
        ColumnLayout {
          spacing: 15
          Repeater {
            model: Mpris.players
            delegate: Rectangle {
                Layout.fillWidth: true; height: 120; color: Colors.bgWidget; radius: Colors.radiusMedium; border.color: Colors.border; border.width: 1
                RowLayout {
                    anchors.fill: parent; anchors.margins: Colors.paddingMedium; spacing: 15
                    Rectangle { width: 90; height: 90; radius: 8; color: Colors.surface; clip: true
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

    // Confirmation Overlay
    Rectangle {
      id: confirmOverlay; anchors.fill: parent; visible: launcherRoot.showingConfirm; color: Colors.withAlpha(Colors.background, 0.9); radius: Colors.radiusLarge
      ColumnLayout {
        anchors.centerIn: parent; spacing: 25
        Text { text: launcherRoot.confirmTitle; color: Colors.text; font.pixelSize: 20; font.bold: true; Layout.alignment: Qt.AlignHCenter }
        RowLayout { spacing: 15; Layout.alignment: Qt.AlignHCenter
          Rectangle { width: 100; height: 40; color: Colors.error; radius: 20; Text { text: "Yes"; color: Colors.text; anchors.centerIn: parent; font.bold: true } MouseArea { anchors.fill: parent; onClicked: launcherRoot.doConfirm() } }
          Rectangle { width: 100; height: 40; color: Colors.surface; radius: 20; Text { text: "No"; color: Colors.text; anchors.centerIn: parent; font.bold: true } MouseArea { anchors.fill: parent; onClicked: launcherRoot.cancelConfirm() } }
        }
      }
      Keys.onPressed: (event) => { if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) launcherRoot.doConfirm(); else if (event.key === Qt.Key_Escape) launcherRoot.cancelConfirm(); event.accepted = true; }
    }
  }
}
