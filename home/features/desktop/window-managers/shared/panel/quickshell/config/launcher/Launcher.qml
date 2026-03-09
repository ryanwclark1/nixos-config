import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import "." // Implicitly includes Colors singleton
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
  visible: isOpen

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  WlrLayershell.namespace: "quickshell"

  property var hyprState: null
  property string searchText: ""
  property var allItems: []
  property var filteredItems: []
  property int selectedIndex: 0
  property string mode: "drun" // drun, window, dmenu, run, emoji, calc, clip, web, system
  
  // Confirmation state
  property string confirmTitle: ""
  property var confirmCallback: null
  readonly property bool showingConfirm: confirmTitle !== ""

  property bool isOpen: false

  function open(newMode, keepSearch) {
    if (showingConfirm) cancelConfirm();
    mode = newMode || "drun"
    if (!keepSearch) {
        searchText = ""
        if (searchInput) searchInput.text = ""
    }
    selectedIndex = 0
    isOpen = true
    if (searchInput) searchInput.forceActiveFocus()
    
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
    } else if (mode === "calc") {
      allItems = []
      filterItems()
    } else if (mode === "web") {
      loadWeb()
    } else if (mode === "system") {
      loadSystem()
    }
  }
  
  function close() {
    isOpen = false
    if (showingConfirm) confirmTitle = "";
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

  function loadWindows() {
    if (hyprState) {
      allItems = hyprState.clients;
      filterItems();
    }
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
      if (mode !== "web" && mode !== "system") {
          scoredItems.sort(function(a, b) { return b._score - a._score; });
      }
      filteredItems = scoredItems;
    }
    selectedIndex = Math.min(selectedIndex, Math.max(0, filteredItems.length - 1));
  }
  
  function executeSelection() {
    if (filteredItems.length > 0 && selectedIndex >= 0) {
      var item = filteredItems[selectedIndex];
      if (mode === "drun") {
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
      } else if (mode === "web") {
        Quickshell.execDetached(["xdg-open", item.exec + encodeURIComponent(item.query)]);
        close();
      } else if (mode === "system") {
        if (item.action) item.action();
        if (!showingConfirm) close();
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
    function openDmenu(itemsJson: string) {
      var items = [];
      try {
        items = JSON.parse(itemsJson);
      } catch (err) {}
      launcherRoot.mode = "dmenu";
      launcherRoot.allItems = items.map(function(it) { return { name: it, title: it }; });
      launcherRoot.open("dmenu");
    }
  }

  // Backdrop to catch clicks and close
  MouseArea {
    anchors.fill: parent
    onClicked: launcherRoot.close()
    
    Rectangle {
      anchors.fill: parent
      color: "#000000"
      opacity: 0.5
    }
  }

  Rectangle {
    id: mainBox
    width: 750
    height: 480
    anchors.centerIn: parent
    color: Colors.background
    opacity: 0.95
    border.color: Colors.border
    border.width: 1
    radius: Colors.radiusLarge

    // Prevent clicks from reaching the backdrop
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
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 12
            color: parent.color
        }

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 10
          spacing: 6
          
          Text {
            text: "LAUNCHER"
            color: Colors.textDisabled
            font.pixelSize: 11
            font.bold: true
            Layout.margins: 5
            Layout.topMargin: 10
          }

          Repeater {
             model: [
               { id: "drun", icon: "󰀻", label: "Apps" },
               { id: "window", icon: "󱗼", label: "Windows" },
               { id: "run", icon: "", label: "Run" },
               { id: "web", icon: "󰖟", label: "Web Search" },
               { id: "emoji", icon: "󰞅", label: "Emoji" },
               { id: "clip", icon: "󰅍", label: "Clipboard" },
               { id: "calc", icon: "󰪚", label: "Calculator" },
               { id: "system", icon: "⚙️", label: "System" }
             ]
             delegate: Rectangle {
                Layout.fillWidth: true
                height: 38
                radius: Colors.radiusSmall
                color: launcherRoot.mode === modelData.id ? Colors.highlight : (sidebarMouse.containsMouse ? Colors.highlightLight : "transparent")
                
                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 12
                  spacing: 12
                  Text { 
                    text: modelData.icon
                    color: launcherRoot.mode === modelData.id ? Colors.primary : Colors.textSecondary
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 16
                  }
                  Text { 
                    text: modelData.label
                    color: launcherRoot.mode === modelData.id ? Colors.text : Colors.textSecondary
                    font.pixelSize: 13
                  }
                }

                MouseArea {
                   id: sidebarMouse
                   anchors.fill: parent
                   hoverEnabled: true
                   onClicked: launcherRoot.open(modelData.id, launcherRoot.searchText !== "")
                }
             }
          }
          Item { Layout.fillHeight: true }
        }
      }

      Rectangle {
        width: 1
        Layout.fillHeight: true
        color: Colors.border
      }

      ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: 15
        spacing: 15

        // Search Bar
        Rectangle {
          Layout.fillWidth: true
          height: 50
          color: Colors.surface
          radius: Colors.radiusSmall
          border.color: searchInput.activeFocus ? Colors.primary : Colors.border
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 15
            anchors.rightMargin: 15
            spacing: 12

            Text {
              text: ""
              color: Colors.textSecondary
              font.family: "JetBrainsMono Nerd Font"
              font.pixelSize: 18
            }

            TextInput {
              id: searchInput
              Layout.fillWidth: true
              color: Colors.text
              font.pixelSize: 16
              clip: true
              text: launcherRoot.searchText
              enabled: !launcherRoot.showingConfirm
              
              onTextChanged: {
                var txt = text;
                if (txt.startsWith("=") && launcherRoot.mode !== "calc") {
                  launcherRoot.open("calc", true);
                } else if (txt.startsWith(">") && launcherRoot.mode !== "run") {
                  launcherRoot.open("run", true);
                } else if (txt.startsWith(":") && launcherRoot.mode !== "emoji") {
                  launcherRoot.open("emoji", true);
                } else if (txt.startsWith("?") && launcherRoot.mode !== "web") {
                  launcherRoot.open("web", true);
                }
                if (launcherRoot.searchText !== text) {
                  launcherRoot.searchText = text;
                  launcherRoot.filterItems();
                }
              }
              
              Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                  if (launcherRoot.mode === "dmenu") {
                    var fifoPath = "/tmp/qs-dmenu-result";
                    Quickshell.execDetached(["bash", "-c", "echo '' > " + fifoPath]);
                  }
                  launcherRoot.close();
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                  launcherRoot.executeSelection();
                } else if (event.key === Qt.Key_Up || (event.key === Qt.Key_K && (event.modifiers & Qt.ControlModifier))) {
                  launcherRoot.selectedIndex = Math.max(0, launcherRoot.selectedIndex - 1);
                  event.accepted = true;
                } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_J && (event.modifiers & Qt.ControlModifier))) {
                  launcherRoot.selectedIndex = Math.min(launcherRoot.filteredItems.length - 1, launcherRoot.selectedIndex + 1);
                  event.accepted = true;
                }
              }
            }
          }
        }

        // Results List
        ListView {
          id: resultsList
          Layout.fillWidth: true
          Layout.fillHeight: true
          model: launcherRoot.filteredItems
          clip: true
          spacing: 5
          currentIndex: launcherRoot.selectedIndex
          enabled: !launcherRoot.showingConfirm
          
          onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

          section.property: "category"
          section.delegate: Text {
            text: section
            color: Colors.primary
            font.pixelSize: 11
            font.bold: true
            Layout.margins: 5
            height: 25
            verticalAlignment: Text.AlignBottom
          }

          delegate: Rectangle {
            width: resultsList.width
            height: mode === "clip" ? 60 : 50
            color: index === launcherRoot.selectedIndex ? Colors.highlight : (itemMouseArea.containsMouse ? Colors.highlightLight : "transparent")
            radius: Colors.radiusSmall

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 12
              anchors.rightMargin: 12
              spacing: 12

              Rectangle {
                width: 32
                height: 32
                radius: Colors.radiusSmall
                color: Colors.surface
                visible: mode !== "dmenu" && mode !== "clip" && mode !== "calc"
                
                Image {
                  id: iconImage
                  anchors.fill: parent
                  anchors.margins: 4
                  source: modelData.icon && modelData.icon.startsWith("/") ? "file://" + modelData.icon : ""
                  fillMode: Image.PreserveAspectFit
                  visible: source != "" && status === Image.Ready
                }

                Text {
                  anchors.centerIn: parent
                  text: mode === "window" ? "󱗼" : 
                        (mode === "run" ? "" : 
                        (mode === "web" ? modelData.icon : 
                        (mode === "emoji" || mode === "system" ? modelData.icon : "󰀻")))
                  color: Colors.textSecondary
                  font.family: (mode === "emoji" || mode === "system") ? "Noto Color Emoji" : "JetBrainsMono Nerd Font"
                  font.pixelSize: (mode === "emoji" || mode === "system") ? 22 : 18
                  visible: !iconImage.visible
                }
              }

              ColumnLayout {
                spacing: 2
                Text {
                  text: mode === "drun" ? modelData.name : 
                        (mode === "run" ? modelData.name : 
                        (mode === "emoji" ? modelData.title : 
                        (mode === "calc" ? modelData.title :
                        (mode === "clip" ? modelData.name : 
                        (mode === "web" ? modelData.title : (modelData.title || modelData.name))))))
                  color: Colors.text
                  font.pixelSize: mode === "calc" ? 18 : 14
                  font.weight: index === launcherRoot.selectedIndex ? Font.Bold : Font.Normal
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                }
                Text {
                  text: mode === "drun" ? modelData.exec : (mode === "run" ? "" : (modelData.class || ""))
                  color: Colors.textSecondary
                  font.pixelSize: 11
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                  visible: text !== "" && mode !== "calc" && mode !== "emoji" && mode !== "web" && mode !== "system"
                }
              }
            }

            MouseArea {
              id: itemMouseArea
              anchors.fill: parent
              hoverEnabled: true
              onClicked: {
                launcherRoot.selectedIndex = index;
                launcherRoot.executeSelection();
              }
            }
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
            Text { text: "Yes"; color: "white"; anchors.centerIn: parent; font.bold: true }
            MouseArea { anchors.fill: parent; onClicked: launcherRoot.doConfirm() }
          }
          
          Rectangle {
            width: 120
            height: 45
            color: Colors.surface
            radius: Colors.radiusSmall
            Text { text: "No"; color: Colors.text; anchors.centerIn: parent; font.bold: true }
            MouseArea { anchors.fill: parent; onClicked: launcherRoot.cancelConfirm() }
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
      onVisibleChanged: if(visible) forceActiveFocus()
    }
  }
}
