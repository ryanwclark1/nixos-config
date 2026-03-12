import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"
import "../widgets" as SharedWidgets

PanelWindow {
  id: settingsRoot

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

  property bool isOpen: false
  property string activeTab: "system"
  signal browseWallpaper(string monitorName)
  property real layoutGapsOut: 10
  property real layoutGapsIn: 5
  property real layoutActiveOpacity: 1.0
  property bool layoutIsMaster: false

  readonly property var launcherModeOptions: [
    { value: "drun", label: "Apps" },
    { value: "window", label: "Windows" },
    { value: "files", label: "Files" },
    { value: "ai", label: "AI" },
    { value: "clip", label: "Clipboard" },
    { value: "system", label: "System" },
    { value: "media", label: "Media" }
  ]

  function refreshHyprlandSettings() {
    if (!hyprStateProc.running) hyprStateProc.running = true;
  }

  // --- Wallpaper tab state ---
  // Which monitor slot is selected in the picker; "" means "all monitors"
  property string wallpaperSelectedMonitor: ""
  // List of connected monitor names, populated lazily when the tab opens
  property var wallpaperMonitorNames: []

  onActiveTabChanged: {
    if (activeTab === "keybinds" && !hyprBindsProc.running) hyprBindsProc.running = true;
    if (activeTab === "about"    && !aboutInfoProc.running)  aboutInfoProc.running = true;
    if (activeTab === "wallpaper") {
      // Refresh monitor list and rescan wallpapers when tab becomes active
      if (!wallpaperMonProc.running) wallpaperMonProc.running = true;
      if (WallpaperService.availableWallpapers.length === 0) WallpaperService.scanWallpapers();
    }
  }

  // Fetch connected monitor names via hyprctl
  Process {
    id: wallpaperMonProc
    command: ["hyprctl", "monitors", "-j"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var mons = JSON.parse(this.text || "[]");
          var names = [];
          for (var i = 0; i < mons.length; i++) {
            if (mons[i].name) names.push(mons[i].name);
          }
          settingsRoot.wallpaperMonitorNames = names;
          // Default selection to first monitor
          if (settingsRoot.wallpaperSelectedMonitor === "" && names.length > 0)
            settingsRoot.wallpaperSelectedMonitor = names[0];
        } catch (e) {
          console.error("Failed to parse hyprctl monitors: " + e);
        }
      }
    }
  }

  function open() {
    isOpen = true;
    refreshHyprlandSettings();
  }

  function close() {
    isOpen = false;
  }

  function toggle() {
    isOpen ? close() : open();
  }

  IpcHandler {
    target: "SettingsHub"
    function toggle() { settingsRoot.toggle(); }
    function open() { settingsRoot.open(); }
    function close() { settingsRoot.close(); }
  }

  Process {
    id: hyprStateProc
    command: [
      "sh",
      "-c",
      "hyprctl getoption general:gaps_out -j 2>/dev/null; "
      + "printf '\\n'; "
      + "hyprctl getoption general:gaps_in -j 2>/dev/null; "
      + "printf '\\n'; "
      + "hyprctl getoption decoration:active_opacity -j 2>/dev/null; "
      + "printf '\\n'; "
      + "hyprctl getoption general:layout -j 2>/dev/null"
    ]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = (this.text || "").trim().split("\n");
        try {
          if (lines[0]) {
            var gapsOut = JSON.parse(lines[0]);
            settingsRoot.layoutGapsOut = gapsOut.int !== undefined ? gapsOut.int : settingsRoot.layoutGapsOut;
          }
          if (lines[1]) {
            var gapsIn = JSON.parse(lines[1]);
            settingsRoot.layoutGapsIn = gapsIn.int !== undefined ? gapsIn.int : settingsRoot.layoutGapsIn;
          }
          if (lines[2]) {
            var activeOpacity = JSON.parse(lines[2]);
            settingsRoot.layoutActiveOpacity = activeOpacity.float !== undefined ? activeOpacity.float : settingsRoot.layoutActiveOpacity;
          }
          if (lines[3]) {
            var layout = JSON.parse(lines[3]);
            settingsRoot.layoutIsMaster = (layout.str === "master");
          }
        } catch (e) {
          console.error("Failed to parse Hyprland settings: " + e);
        }
      }
    }
  }

  // --- Keybinds tab state ---
  property var keybindsList: []
  property string keybindsFilter: ""

  Process {
    id: hyprBindsProc
    command: ["hyprctl", "binds", "-j"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var raw = JSON.parse(this.text || "[]");
          var result = [];
          for (var i = 0; i < raw.length; i++) {
            var b = raw[i];
            var mods = (b.modmask !== undefined && b.modmask !== 0) ? b.modString || "" : "";
            result.push({
              mods: mods,
              key: b.key || "",
              dispatcher: b.dispatcher || "",
              arg: b.arg || ""
            });
          }
          settingsRoot.keybindsList = result;
        } catch (e) {
          console.error("Failed to parse hyprctl binds: " + e);
        }
      }
    }
  }

  // --- About tab state ---
  property string aboutKernel: ""
  property string aboutHostname: ""
  property string aboutUptime: ""

  Process {
    id: aboutInfoProc
    command: ["sh", "-c", "uname -r; echo '---'; hostname; echo '---'; uptime -p"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var parts = (this.text || "").split("---");
        settingsRoot.aboutKernel   = parts[0] ? parts[0].trim() : "";
        settingsRoot.aboutHostname = parts[1] ? parts[1].trim() : "";
        settingsRoot.aboutUptime   = parts[2] ? parts[2].trim() : "";
      }
    }
  }

  Process {
    id: restartShellProc
    command: ["sh", "-c", "quickshell --restart || quickshell-restart || qs --restart || true"]
    running: false
  }

  MouseArea {
    anchors.fill: parent
    onClicked: settingsRoot.close()

    Rectangle {
      anchors.fill: parent
      color: Colors.background
      opacity: 0.5
    }
  }

  Rectangle {
    id: mainBox
    width: Math.min(parent.width - 40, 780)
    height: Math.min(parent.height - 40, 860)
    anchors.centerIn: parent
    color: Colors.bgGlass
    border.color: Colors.border
    border.width: 1
    radius: Colors.radiusLarge
    clip: true

    focus: settingsRoot.isOpen
    onVisibleChanged: if (visible) forceActiveFocus()
    Keys.onEscapePressed: settingsRoot.isOpen = false

    opacity: settingsRoot.isOpen ? 1.0 : 0.0
    scale: settingsRoot.isOpen ? 1.0 : 0.95
    Behavior on opacity { NumberAnimation { id: shFadeAnim; duration: 250; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { id: shScaleAnim; duration: 300; easing.type: Easing.OutBack } }
    layer.enabled: shFadeAnim.running || shScaleAnim.running

    MouseArea { anchors.fill: parent }

    RowLayout {
      anchors.fill: parent
      spacing: 0

      Rectangle {
        Layout.preferredWidth: 200
        Layout.fillHeight: true
        color: Qt.rgba(0, 0, 0, 0.1)

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Colors.paddingLarge
          spacing: Colors.spacingS

          Text {
            text: "SETTINGS"
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeXS
            font.weight: Font.Black
            font.letterSpacing: 1.5
            Layout.bottomMargin: 12
          }

          TabBtn { label: "System"; icon: "󰒓"; tabId: "system" }
          TabBtn { label: "Appearance"; icon: "󰸉"; tabId: "appearance" }
          TabBtn { label: "Wallpaper"; icon: "󰸉"; tabId: "wallpaper" }
          TabBtn { label: "Hyprland"; icon: "󱗼"; tabId: "layout" }
          TabBtn { label: "OSD"; icon: "󰍡"; tabId: "osd" }
          TabBtn { label: "Dock"; icon: "󰍜"; tabId: "dock" }
          TabBtn { label: "Widgets"; icon: "󰖲"; tabId: "widgets" }
          TabBtn { label: "Lock Screen"; icon: "󰌾"; tabId: "lockscreen" }
          TabBtn { label: "Privacy"; icon: "󰒃"; tabId: "privacy" }
          TabBtn { label: "Power"; icon: "󰌪"; tabId: "power" }
          TabBtn { label: "Keybinds"; icon: "󰌌"; tabId: "keybinds" }
          TabBtn { label: "Plugins"; icon: "󰏗"; tabId: "plugins" }
          TabBtn { label: "About"; icon: "󰋗"; tabId: "about" }

          Item { Layout.fillHeight: true }

          Rectangle {
            Layout.fillWidth: true
            height: 42
            radius: Colors.radiusSmall
            color: Colors.primary

            SharedWidgets.StateLayer {
              id: saveStateLayer
              hovered: saveHover.containsMouse
              pressed: saveHover.pressed
              stateColor: Colors.primary
            }

            RowLayout {
              anchors.centerIn: parent
              spacing: Colors.spacingS
              Text { text: "󰆓"; color: Colors.text; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeLarge }
              Text { text: "Save & Close"; color: Colors.text; font.weight: Font.Bold; font.pixelSize: Colors.fontSizeMedium }
            }

            MouseArea {
              id: saveHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: (mouse) => {
                saveStateLayer.burst(mouse.x, mouse.y);
                Config.save();
                settingsRoot.close();
              }
            }
          }
        }
      }

      SharedWidgets.ScrollableContent {
        Layout.fillWidth: true
        Layout.fillHeight: true
        columnSpacing: Colors.spacingXL

        // Padding wrapper — ScrollableContent's inner ColumnLayout is full-width,
        // so we nest the actual content column with margins.
        ColumnLayout {
          id: contentColumn
          Layout.fillWidth: true
          Layout.leftMargin: 32
          Layout.rightMargin: 32
          Layout.topMargin: 32
          Layout.bottomMargin: 32
          spacing: Colors.spacingXL

          Text {
            text: activeTab === "system" ? "Shell Behavior"
                  : activeTab === "appearance" ? "UI Appearance"
                  : activeTab === "wallpaper" ? "Wallpaper"
                  : activeTab === "layout" ? "Hyprland Layout"
                  : activeTab === "osd" ? "On-Screen Display"
                  : activeTab === "dock" ? "Dock"
                  : activeTab === "widgets" ? "Desktop Widgets"
                  : activeTab === "lockscreen" ? "Lock Screen"
                  : activeTab === "privacy" ? "Privacy"
                  : activeTab === "power" ? "Power & Sleep"
                  : activeTab === "keybinds" ? "Keybindings"
                  : activeTab === "plugins" ? "Plugins"
                  : activeTab === "about" ? "About"
                  : "Settings"
            color: Colors.text
            font.pixelSize: Colors.fontSizeHuge
            font.weight: Font.Bold
            font.letterSpacing: -0.5
          }

          ColumnLayout {
            visible: activeTab === "system"
            spacing: Colors.spacingXL
            Layout.fillWidth: true

            SectionLabel { text: "Shell" }

            GridLayout {
              columns: 2
              columnSpacing: Colors.spacingL
              rowSpacing: Colors.spacingL
              Layout.fillWidth: true

              ToggleCard { label: "Floating Bar"; icon: "󰖲"; configKey: "barFloating" }
              ToggleCard { label: "Blur Effects"; icon: "󰃠"; configKey: "blurEnabled" }
            }

            ConfigSlider {
              label: "Notification Width"
              min: 280
              max: 520
              value: Config.notifWidth
              onMoved: (v) => Config.notifWidth = v
            }

            ConfigSlider {
              label: "Popup Duration"
              min: 2000
              max: 10000
              step: 500
              value: Config.popupTimer
              unit: "ms"
              onMoved: (v) => Config.popupTimer = v
            }

            SectionLabel { text: "Launcher" }

            ModeSelector {
              label: "Default Mode"
              currentValue: Config.launcherDefaultMode
              options: settingsRoot.launcherModeOptions
              onModeSelected: (modeValue) => Config.launcherDefaultMode = modeValue
            }

            GridLayout {
              columns: 2
              columnSpacing: Colors.spacingL
              rowSpacing: Colors.spacingL
              Layout.fillWidth: true

              ToggleCard { label: "Show Mode Hints"; icon: "󰌌"; configKey: "launcherShowModeHints" }
              ToggleCard { label: "Show Home Sections"; icon: "󰆍"; configKey: "launcherShowHomeSections" }
            }

            SectionLabel { text: "Control Center" }

            GridLayout {
              columns: 2
              columnSpacing: Colors.spacingL
              rowSpacing: Colors.spacingL
              Layout.fillWidth: true

              ToggleCard { label: "Quick Links"; icon: "󰖩"; configKey: "controlCenterShowQuickLinks" }
              ToggleCard { label: "Media Widget"; icon: "󰝚"; configKey: "controlCenterShowMediaWidget" }
            }

            ConfigSlider {
              label: "Control Center Width"
              min: 320
              max: 460
              value: Config.controlCenterWidth
              onMoved: (v) => Config.controlCenterWidth = v
            }

          }

          ColumnLayout {
            visible: activeTab === "appearance"
            spacing: Colors.spacingXL
            Layout.fillWidth: true

            SectionLabel { text: "Bar" }

            ConfigSlider { label: "Bar Height"; min: 20; max: 60; value: Config.barHeight; onMoved: (v) => Config.barHeight = v }
            ConfigSlider { label: "Bar Margin"; min: 0; max: 40; value: Config.barMargin; onMoved: (v) => Config.barMargin = v }
            ConfigSlider { label: "Bar Opacity"; min: 0.3; max: 1.0; value: Config.barOpacity; step: 0.05; unit: "%"; onMoved: (v) => Config.barOpacity = v }
            ConfigSlider { label: "Glass Opacity"; min: 0.1; max: 1.0; value: Config.glassOpacity; step: 0.05; onMoved: (v) => Config.glassOpacity = v }

            RowLayout {
              spacing: Colors.spacingXL
              Text { text: "Floating Bar"; color: Colors.text; font.pixelSize: Colors.fontSizeLarge; Layout.fillWidth: true }
              SharedWidgets.DankToggle { checked: Config.barFloating; onToggled: Config.barFloating = !Config.barFloating }
            }

          }

          // ---- Wallpaper tab -----------------------------------------------
          ColumnLayout {
            visible: activeTab === "wallpaper"
            spacing: Colors.spacingXL
            Layout.fillWidth: true

            // ---- Monitor selector (shown only when >1 monitor) --------
            ColumnLayout {
              visible: settingsRoot.wallpaperMonitorNames.length > 1
              spacing: Colors.spacingS
              Layout.fillWidth: true

              SectionLabel { text: "MONITOR" }

              Flow {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                SharedWidgets.FilterChip {
                  label: "All"
                  selected: settingsRoot.wallpaperSelectedMonitor === "__all__"
                  onClicked: settingsRoot.wallpaperSelectedMonitor = "__all__"
                }

                Repeater {
                  model: settingsRoot.wallpaperMonitorNames
                  delegate: SharedWidgets.FilterChip {
                    required property string modelData
                    label: modelData
                    selected: settingsRoot.wallpaperSelectedMonitor === modelData
                    onClicked: settingsRoot.wallpaperSelectedMonitor = modelData
                  }
                }
              }
            }

            // ---- Current wallpaper preview ----------------------------
            SectionLabel { text: "CURRENT WALLPAPER" }

            Rectangle {
              id: previewContainer
              Layout.fillWidth: true
              height: 160
              radius: Colors.radiusMedium
              color: Colors.bgWidget
              border.color: Colors.border
              border.width: 1
              clip: true

              // Resolve what path to preview: use selected monitor key or __all__
              readonly property string previewPath: {
                var key = settingsRoot.wallpaperSelectedMonitor || "__all__";
                return WallpaperService.wallpapers[key]
                       || WallpaperService.wallpapers["__all__"]
                       || "";
              }

              // Double-buffer crossfade: _previewFlip toggles which image is "front"
              property bool _previewFlip: false

              onPreviewPathChanged: {
                if (!previewPath) return;
                // Load new wallpaper into the *back* image
                var src = "file://" + previewPath;
                if (_previewFlip) {
                  previewA.source = src;
                } else {
                  previewB.source = src;
                }
              }

              Image {
                id: previewA
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
                sourceSize: Qt.size(previewContainer.width * 2, previewContainer.height * 2)
                opacity: previewContainer._previewFlip ? 0.0 : 1.0
                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
                onStatusChanged: {
                  // When back image finishes loading, flip it to front
                  if (status === Image.Ready && previewContainer._previewFlip) {
                    previewContainer._previewFlip = false;
                  }
                }
              }

              Image {
                id: previewB
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                smooth: true
                sourceSize: Qt.size(previewContainer.width * 2, previewContainer.height * 2)
                opacity: previewContainer._previewFlip ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
                onStatusChanged: {
                  if (status === Image.Ready && !previewContainer._previewFlip) {
                    previewContainer._previewFlip = true;
                  }
                }
              }

              // Placeholder only when *both* images have no valid content
              ColumnLayout {
                anchors.centerIn: parent
                spacing: Colors.spacingS
                visible: previewContainer.previewPath === ""
                         || (previewA.status !== Image.Ready && previewB.status !== Image.Ready)

                Text {
                  text: "󰸉"
                  color: Colors.fgDim
                  font.family: Colors.fontMono
                  font.pixelSize: Colors.fontSizeHuge
                  Layout.alignment: Qt.AlignHCenter
                }
                Text {
                  text: previewContainer.previewPath !== "" ? "Loading preview…" : "No wallpaper set"
                  color: Colors.fgDim
                  font.pixelSize: Colors.fontSizeMedium
                  Layout.alignment: Qt.AlignHCenter
                }
              }

              // Filename chip at the bottom-right
              Rectangle {
                anchors {
                  bottom: parent.bottom
                  right: parent.right
                  margins: Colors.spacingM
                }
                visible: previewContainer.previewPath !== ""
                implicitWidth: previewName.implicitWidth + 16
                height: 22
                radius: Colors.radiusPill
                color: Qt.rgba(0, 0, 0, 0.55)

                Text {
                  id: previewName
                  anchors.centerIn: parent
                  text: {
                    var p = previewContainer.previewPath;
                    if (!p) return "";
                    var parts = p.split("/");
                    return parts[parts.length - 1];
                  }
                  color: "#ffffff"
                  font.pixelSize: Colors.fontSizeXS
                  font.family: Colors.fontMono
                  elide: Text.ElideLeft
                  maximumLineCount: 1
                }
              }
            }

            // ---- Quick action buttons ---------------------------------
            RowLayout {
              Layout.fillWidth: true
              spacing: Colors.spacingM

              // Next Wallpaper
              Rectangle {
                Layout.fillWidth: true
                height: 40
                radius: Colors.radiusSmall
                color: Colors.bgWidget
                border.color: Colors.border
                border.width: 1

                SharedWidgets.StateLayer {
                  id: nextWpStateLayer
                  hovered: nextWpHover.containsMouse
                  pressed: nextWpHover.pressed
                }

                RowLayout {
                  anchors.centerIn: parent
                  spacing: Colors.spacingS
                  Text { text: "󰒭"; color: Colors.fgSecondary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeLarge }
                  Text { text: "Next"; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.Medium }
                }

                MouseArea {
                  id: nextWpHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: (mouse) => {
                    nextWpStateLayer.burst(mouse.x, mouse.y);
                    var mon = settingsRoot.wallpaperSelectedMonitor === "__all__"
                              ? "" : settingsRoot.wallpaperSelectedMonitor;
                    WallpaperService.nextWallpaper(mon);
                  }
                }
              }

              // Random Wallpaper
              Rectangle {
                Layout.fillWidth: true
                height: 40
                radius: Colors.radiusSmall
                color: Colors.bgWidget
                border.color: Colors.border
                border.width: 1

                SharedWidgets.StateLayer {
                  id: randWpStateLayer
                  hovered: randWpHover.containsMouse
                  pressed: randWpHover.pressed
                }

                RowLayout {
                  anchors.centerIn: parent
                  spacing: Colors.spacingS
                  Text { text: "󰒝"; color: Colors.fgSecondary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeLarge }
                  Text { text: "Random"; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.Medium }
                }

                MouseArea {
                  id: randWpHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: (mouse) => {
                    randWpStateLayer.burst(mouse.x, mouse.y);
                    var mon = settingsRoot.wallpaperSelectedMonitor === "__all__"
                              ? "" : settingsRoot.wallpaperSelectedMonitor;
                    WallpaperService.randomWallpaper(mon);
                  }
                }
              }

              // Open Folder
              Rectangle {
                Layout.fillWidth: true
                height: 40
                radius: Colors.radiusSmall
                color: Colors.bgWidget
                border.color: Colors.border
                border.width: 1

                SharedWidgets.StateLayer {
                  id: openFolderStateLayer
                  hovered: openFolderHover.containsMouse
                  pressed: openFolderHover.pressed
                }

                RowLayout {
                  anchors.centerIn: parent
                  spacing: Colors.spacingS
                  Text { text: "󰝰"; color: Colors.fgSecondary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeLarge }
                  Text { text: "Open Folder"; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.Medium }
                }

                MouseArea {
                  id: openFolderHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: (mouse) => {
                    openFolderStateLayer.burst(mouse.x, mouse.y);
                    WallpaperService.openWallpaperFolder();
                  }
                }
              }

              // Browse custom image
              Rectangle {
                Layout.fillWidth: true
                height: 40
                radius: Colors.radiusSmall
                color: Colors.bgWidget
                border.color: Colors.border
                border.width: 1

                SharedWidgets.StateLayer {
                  id: browseWpStateLayer
                  hovered: browseWpHover.containsMouse
                  pressed: browseWpHover.pressed
                }

                RowLayout {
                  anchors.centerIn: parent
                  spacing: Colors.spacingS
                  Text { text: "󰉋"; color: Colors.fgSecondary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeLarge }
                  Text { text: "Browse..."; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.Medium }
                }

                MouseArea {
                  id: browseWpHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: (mouse) => {
                    browseWpStateLayer.burst(mouse.x, mouse.y);
                    var mon = settingsRoot.wallpaperSelectedMonitor === "__all__"
                              ? "" : settingsRoot.wallpaperSelectedMonitor;
                    settingsRoot.browseWallpaper(mon);
                  }
                }
              }
            }

            // ---- Settings section -------------------------------------
            SectionLabel { text: "SETTINGS" }

            GridLayout {
              columns: 2
              columnSpacing: Colors.spacingL
              rowSpacing: Colors.spacingL
              Layout.fillWidth: true

              // Pywal toggle card (custom — not a Config property but a direct bool)
              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 84
                radius: Colors.radiusMedium
                color: Colors.bgWidget
                border.color: Config.wallpaperRunPywal ? Colors.primary : Colors.border
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 150 } }

                SharedWidgets.StateLayer {
                  id: pywalStateLayer
                  hovered: pywalHover.containsMouse
                  pressed: pywalHover.pressed
                }

                RowLayout {
                  anchors { fill: parent; margins: Colors.spacingM }
                  spacing: Colors.spacingM

                  Text {
                    text: "󰏘"
                    color: Config.wallpaperRunPywal ? Colors.primary : Colors.textSecondary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeHuge
                    Behavior on color { ColorAnimation { duration: 150 } }
                  }

                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    Text { text: "Run pywal on change"; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.DemiBold }
                    Text { text: Config.wallpaperRunPywal ? "Enabled" : "Disabled"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeSmall }
                  }

                  SharedWidgets.DankToggle {
                    checked: Config.wallpaperRunPywal
                    onToggled: Config.wallpaperRunPywal = !Config.wallpaperRunPywal
                  }
                }

                MouseArea {
                  id: pywalHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: (mouse) => {
                    pywalStateLayer.burst(mouse.x, mouse.y);
                    Config.wallpaperRunPywal = !Config.wallpaperRunPywal;
                  }
                }
              }
            }

            // Auto-cycle interval slider (0 = disabled)
            ColumnLayout {
              spacing: Colors.spacingM
              Layout.fillWidth: true

              RowLayout {
                Text { text: "Auto-Cycle Interval"; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.Medium }
                Item { Layout.fillWidth: true }
                Text {
                  text: Config.wallpaperCycleInterval === 0
                        ? "Off"
                        : Config.wallpaperCycleInterval + " min"
                  color: Colors.fgSecondary
                  font.pixelSize: Colors.fontSizeSmall
                  font.family: Colors.fontMono
                }
              }

              Item {
                Layout.fillWidth: true
                height: 24

                // Track
                Rectangle {
                  id: cycleTrack
                  anchors.verticalCenter: parent.verticalCenter
                  width: parent.width
                  height: 6
                  color: Colors.surface
                  radius: 3

                  // Fill
                  Rectangle {
                    width: parent.width * (Config.wallpaperCycleInterval / 60)
                    height: parent.height
                    color: Config.wallpaperCycleInterval > 0 ? Colors.primary : Colors.border
                    radius: 3
                    Behavior on width { NumberAnimation { duration: 100 } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                  }
                }

                // Thumb handle
                Rectangle {
                  id: cycleThumb
                  width: 14
                  height: 14
                  radius: 7
                  color: Config.wallpaperCycleInterval > 0 ? Colors.primary : Colors.border
                  border.color: Colors.bgWidget
                  border.width: 2
                  x: Math.max(0, Math.min(parent.width - width, parent.width * (Config.wallpaperCycleInterval / 60) - width / 2))
                  anchors.verticalCenter: parent.verticalCenter
                  Behavior on x { NumberAnimation { duration: 100 } }
                  Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                  anchors.fill: parent
                  anchors.topMargin: -4
                  anchors.bottomMargin: -4
                  cursorShape: Qt.PointingHandCursor
                  function updateCycle(mouse) {
                    var raw = (mouse.x / width) * 60;
                    // Snap: 0-2 → 0 (off), then 5-minute steps
                    if (raw < 2) { Config.wallpaperCycleInterval = 0; return; }
                    var snapped = Math.round(raw / 5) * 5;
                    Config.wallpaperCycleInterval = Math.max(5, Math.min(60, snapped));
                  }
                  onPressed: (mouse) => updateCycle(mouse)
                  onPositionChanged: (mouse) => { if (pressed) updateCycle(mouse); }
                }
              }

              // Endpoint labels
              RowLayout {
                Layout.fillWidth: true
                Text { text: "Off"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS }
                Item { Layout.fillWidth: true }
                Text { text: "60 min"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS }
              }
            }

            // ---- Wallpaper grid --------------------------------------
            SectionLabel {
              text: WallpaperService.scanning
                    ? "SCANNING…"
                    : ("WALLPAPERS  (" + WallpaperService.availableWallpapers.length + ")")
            }

            // Rescan + empty-state row
            RowLayout {
              Layout.fillWidth: true
              spacing: Colors.spacingM
              visible: !WallpaperService.scanning

              SharedWidgets.EmptyState {
                visible: WallpaperService.availableWallpapers.length === 0
                icon: "󰸉"
                message: "No wallpapers found in search directories"
                Layout.fillWidth: true
              }

              Item { Layout.fillWidth: true; visible: WallpaperService.availableWallpapers.length > 0 }

              Rectangle {
                implicitWidth: rescanRow.implicitWidth + 20
                height: 32
                radius: Colors.radiusXS
                color: Colors.bgWidget
                border.color: Colors.border
                border.width: 1

                SharedWidgets.StateLayer {
                  id: rescanStateLayer
                  hovered: rescanHover.containsMouse
                  pressed: rescanHover.pressed
                }

                RowLayout {
                  id: rescanRow
                  anchors.centerIn: parent
                  spacing: Colors.spacingS
                  Text { text: "󰑐"; color: Colors.fgSecondary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeMedium }
                  Text { text: "Rescan"; color: Colors.text; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Medium }
                }

                MouseArea {
                  id: rescanHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: (mouse) => {
                    rescanStateLayer.burst(mouse.x, mouse.y);
                    WallpaperService.scanWallpapers();
                  }
                }
              }
            }

            // Scanning spinner placeholder
            ColumnLayout {
              visible: WallpaperService.scanning
              Layout.fillWidth: true
              spacing: Colors.spacingS

              SharedWidgets.LoadingSpinner {
                Layout.alignment: Qt.AlignHCenter
              }
              Text {
                text: "Scanning directories…"
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeMedium
                Layout.alignment: Qt.AlignHCenter
              }
            }

            // Grid of thumbnail cards
            // We use a Flow layout so thumbnails wrap naturally inside the panel width.
            Flow {
              visible: !WallpaperService.scanning && WallpaperService.availableWallpapers.length > 0
              Layout.fillWidth: true
              spacing: Colors.spacingS

              Repeater {
                model: WallpaperService.availableWallpapers

                delegate: Item {
                  id: thumbDelegate
                  required property var modelData
                  required property int index

                  // Resolve the active path for the selected monitor slot
                  readonly property string activePath: {
                    var key = settingsRoot.wallpaperSelectedMonitor || "__all__";
                    return WallpaperService.wallpapers[key]
                           || WallpaperService.wallpapers["__all__"]
                           || "";
                  }
                  readonly property bool isActive: modelData.path === activePath

                  width: 108
                  height: 80
                  scale: 1.0

                  SequentialAnimation {
                    id: thumbPulse
                    NumberAnimation { target: thumbDelegate; property: "scale"; to: 0.92; duration: 100; easing.type: Easing.InQuad }
                    NumberAnimation { target: thumbDelegate; property: "scale"; to: 1.0; duration: 100; easing.type: Easing.OutQuad }
                  }

                  Rectangle {
                    anchors.fill: parent
                    radius: Colors.radiusSmall
                    color: isActive ? Colors.highlight : Colors.bgWidget
                    border.color: isActive ? Colors.primary : Colors.border
                    border.width: isActive ? 2 : 1
                    clip: true

                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Image {
                      anchors.fill: parent
                      source: "file://" + modelData.path
                      fillMode: Image.PreserveAspectCrop
                      asynchronous: true
                      smooth: true
                      cache: false
                      sourceSize: Qt.size(216, 160)

                      // Fade-in when ready
                      opacity: status === Image.Ready ? 1.0 : 0.0
                      Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    // Loading placeholder
                    Text {
                      anchors.centerIn: parent
                      text: "󰸉"
                      color: Colors.fgDim
                      font.family: Colors.fontMono
                      font.pixelSize: Colors.fontSizeHuge
                      visible: parent.children[0].status !== Image.Ready
                    }

                    // Active badge
                    Rectangle {
                      anchors { top: parent.top; right: parent.right; margins: 5 }
                      visible: isActive
                      width: 18; height: 18; radius: height / 2
                      color: Colors.primary

                      Text {
                        anchors.centerIn: parent
                        text: "󰄬"
                        color: Colors.text
                        font.family: Colors.fontMono
                        font.pixelSize: Colors.fontSizeXS
                      }
                    }

                    // Hover overlay + filename tooltip
                    Rectangle {
                      anchors.fill: parent
                      color: thumbMouse.containsMouse ? Qt.rgba(0, 0, 0, 0.35) : "transparent"
                      Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    Text {
                      anchors {
                        bottom: parent.bottom
                        left: parent.left
                        right: parent.right
                        margins: 4
                      }
                      text: modelData.filename
                      color: "#ffffff"
                      font.pixelSize: Colors.fontSizeXS
                      elide: Text.ElideLeft
                      visible: thumbMouse.containsMouse
                    }

                    MouseArea {
                      id: thumbMouse
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        thumbPulse.restart();
                        var mon = settingsRoot.wallpaperSelectedMonitor === "__all__"
                                  ? "" : settingsRoot.wallpaperSelectedMonitor;
                        WallpaperService.setWallpaper(modelData.path, mon);
                      }
                    }
                  }
                }
              }
            }

            // Info callout
            Rectangle {
              Layout.fillWidth: true
              implicitHeight: wpInfoLayout.implicitHeight + 24
              radius: Colors.radiusMedium
              color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.07)
              border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.22)
              border.width: 1

              ColumnLayout {
                id: wpInfoLayout
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Colors.spacingM }
                spacing: Colors.spacingS

                RowLayout {
                  spacing: Colors.spacingS
                  Text {
                    text: "󰋗"
                    color: Colors.primary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeLarge
                    Layout.alignment: Qt.AlignTop
                  }
                  Text {
                    text: "Wallpaper search directories"
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeMedium
                    font.weight: Font.DemiBold
                  }
                }

                Repeater {
                  model: WallpaperService.wallpaperSearchDirs
                  delegate: Text {
                    required property string modelData
                    text: "  " + modelData
                    color: Colors.fgSecondary
                    font.pixelSize: Colors.fontSizeXS
                    font.family: Colors.fontMono
                    Layout.fillWidth: true
                    elide: Text.ElideLeft
                  }
                }

                Text {
                  text: "Requires swww, hyprctl hyprpaper, or swaybg to apply wallpapers."
                  color: Colors.fgDim
                  font.pixelSize: Colors.fontSizeXS
                  wrapMode: Text.WordWrap
                  Layout.fillWidth: true
                  Layout.topMargin: 4
                }
              }
            }
          }

          ColumnLayout {
            visible: activeTab === "layout"
            spacing: Colors.spacingXL
            Layout.fillWidth: true

            // Configure Displays entry point
            Rectangle {
              Layout.fillWidth: true
              height: 48
              radius: Colors.radiusSmall
              color: configDisplaysHover.containsMouse
                     ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.18)
                     : Colors.bgWidget
              border.color: Colors.primary
              border.width: 1
              Behavior on color { ColorAnimation { duration: 160 } }

              RowLayout {
                anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
                spacing: Colors.spacingM
                Text { text: "󰍺"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL }
                Text { text: "Configure Displays"; color: Colors.text; font.weight: Font.Bold; font.pixelSize: Colors.fontSizeMedium }
                Item { Layout.fillWidth: true }
                Text { text: "Arrange, resize & scale monitors →"; color: Colors.fgDim; font.pixelSize: Colors.fontSizeSmall }
              }

              MouseArea {
                id: configDisplaysHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  settingsRoot.close();
                  Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "toggleDisplayConfig"]);
                }
              }
            }

            RowLayout {
              spacing: Colors.spacingXL
              Text { text: "Master Layout"; color: Colors.text; font.pixelSize: Colors.fontSizeLarge; Layout.fillWidth: true }
              SharedWidgets.DankToggle {
                checked: settingsRoot.layoutIsMaster
                onToggled: {
                  var newLayout = !checked ? "master" : "dwindle";
                  Quickshell.execDetached(["hyprctl", "keyword", "general:layout", newLayout]);
                  settingsRoot.layoutIsMaster = !checked;
                }
              }
            }

            ConfigSlider {
              label: "Outer Gaps"
              min: 0
              max: 50
              value: settingsRoot.layoutGapsOut
              onMoved: (v) => {
                settingsRoot.layoutGapsOut = v;
                Quickshell.execDetached(["hyprctl", "keyword", "general:gaps_out", v.toString()]);
              }
            }

            ConfigSlider {
              label: "Inner Gaps"
              min: 0
              max: 30
              value: settingsRoot.layoutGapsIn
              onMoved: (v) => {
                settingsRoot.layoutGapsIn = v;
                Quickshell.execDetached(["hyprctl", "keyword", "general:gaps_in", v.toString()]);
              }
            }

            ConfigSlider {
              label: "Active Opacity"
              min: 0.5
              max: 1.0
              value: settingsRoot.layoutActiveOpacity
              step: 0.05
              onMoved: (v) => {
                settingsRoot.layoutActiveOpacity = v;
                Quickshell.execDetached(["hyprctl", "keyword", "decoration:active_opacity", v.toString()]);
              }
            }
          }

          // OSD tab
          ColumnLayout {
            visible: activeTab === "osd"
            spacing: Colors.spacingXL
            Layout.fillWidth: true

            SectionLabel { text: "POSITION" }

            ModeSelector {
              label: "Screen Position"
              currentValue: Config.osdPosition
              options: [
                { value: "top_left", label: "Top Left" },
                { value: "top", label: "Top" },
                { value: "top_right", label: "Top Right" },
                { value: "left", label: "Left" },
                { value: "center", label: "Center" },
                { value: "right", label: "Right" },
                { value: "bottom_left", label: "Bottom Left" },
                { value: "bottom", label: "Bottom" },
                { value: "bottom_right", label: "Bottom Right" }
              ]
              onModeSelected: (v) => Config.osdPosition = v
            }

            SectionLabel { text: "STYLE" }

            ModeSelector {
              label: "Display Style"
              currentValue: Config.osdStyle
              options: [
                { value: "circular", label: "Circular" },
                { value: "pill", label: "Pill" }
              ]
              onModeSelected: (v) => Config.osdStyle = v
            }

            GridLayout {
              columns: 2
              columnSpacing: Colors.spacingL
              rowSpacing: Colors.spacingL
              Layout.fillWidth: true

              ToggleCard { label: "Volume Overdrive"; icon: "󰝝"; configKey: "osdOverdrive" }
            }

            SectionLabel { text: "TIMING & SIZE" }

            ConfigSlider {
              label: "OSD Duration"
              min: 1000
              max: 5000
              step: 250
              value: Config.osdDuration
              unit: "ms"
              onMoved: (v) => Config.osdDuration = v
            }

            ConfigSlider {
              label: "OSD Size"
              min: 140
              max: 260
              value: Config.osdSize
              onMoved: (v) => Config.osdSize = v
            }
          }

          // Dock tab
          ColumnLayout {
            visible: activeTab === "dock"
            spacing: Colors.spacingXL
            Layout.fillWidth: true

            GridLayout {
              columns: 2
              columnSpacing: Colors.spacingL
              rowSpacing: Colors.spacingL
              Layout.fillWidth: true

              ToggleCard { label: "Dock Enabled"; icon: "󰍜"; configKey: "dockEnabled" }
              ToggleCard { label: "Auto Hide"; icon: "󰘊"; configKey: "dockAutoHide" }
              ToggleCard { label: "Group Windows"; icon: "󰖲"; configKey: "dockGroupApps" }
            }

            SectionLabel { text: "POSITION" }

            ModeSelector {
              label: "Dock Position"
              currentValue: Config.dockPosition
              options: [
                { value: "top", label: "Top" },
                { value: "bottom", label: "Bottom" }
              ]
              onModeSelected: (v) => Config.dockPosition = v
            }

            ConfigSlider {
              label: "Icon Size"
              min: 24
              max: 56
              value: Config.dockIconSize
              onMoved: (v) => Config.dockIconSize = v
            }
          }

          // Widgets tab
          ColumnLayout {
            visible: activeTab === "widgets"
            spacing: Colors.spacingXL
            Layout.fillWidth: true

            GridLayout {
              columns: 2
              columnSpacing: Colors.spacingL
              rowSpacing: Colors.spacingL
              Layout.fillWidth: true

              ToggleCard { label: "Desktop Widgets"; icon: "󰖲"; configKey: "desktopWidgetsEnabled" }
              ToggleCard { label: "Grid Snap"; icon: "󰕰"; configKey: "desktopWidgetsGridSnap" }
            }

            Rectangle {
              Layout.fillWidth: true
              height: 42
              radius: Colors.radiusSmall
              color: Colors.surface
              border.color: Colors.primary
              border.width: 1

              SharedWidgets.StateLayer {
                id: editWidgetsStateLayer
                hovered: editWidgetsHover.containsMouse
                pressed: editWidgetsHover.pressed
                stateColor: Colors.primary
              }

              RowLayout {
                anchors.centerIn: parent
                spacing: Colors.spacingS
                Text { text: "󰏫"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeLarge }
                Text { text: "Edit Widgets"; color: Colors.text; font.weight: Font.Bold; font.pixelSize: Colors.fontSizeMedium }
              }

              MouseArea {
                id: editWidgetsHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                  editWidgetsStateLayer.burst(mouse.x, mouse.y);
                  DesktopWidgetRegistry.editMode = true;
                  settingsRoot.close();
                }
              }
            }
          }

          // Lock Screen tab
          ColumnLayout {
            visible: activeTab === "lockscreen"
            spacing: Colors.spacingXL
            Layout.fillWidth: true

            GridLayout {
              columns: 2
              columnSpacing: Colors.spacingL
              rowSpacing: Colors.spacingL
              Layout.fillWidth: true

              ToggleCard { label: "Compact Mode"; icon: "󰘖"; configKey: "lockScreenCompact" }
              ToggleCard { label: "Media Controls"; icon: "󰝚"; configKey: "lockScreenMediaControls" }
              ToggleCard { label: "Weather"; icon: "󰖙"; configKey: "lockScreenWeather" }
              ToggleCard { label: "Session Buttons"; icon: "󰐥"; configKey: "lockScreenSessionButtons" }
            }

            ConfigSlider {
              label: "Lock Countdown"
              min: 1000
              max: 10000
              step: 500
              value: Config.lockScreenCountdown
              unit: "ms"
              onMoved: (v) => Config.lockScreenCountdown = v
            }
          }

          // Privacy tab
          ColumnLayout {
            visible: activeTab === "privacy"
            spacing: Colors.spacingXL
            Layout.fillWidth: true

            SectionLabel { text: "INDICATORS" }

            GridLayout {
              columns: 2
              columnSpacing: Colors.spacingL
              rowSpacing: Colors.spacingL
              Layout.fillWidth: true

              ToggleCard { label: "Privacy Indicators"; icon: "󰒃"; configKey: "privacyIndicatorsEnabled" }
              ToggleCard { label: "Camera Monitoring"; icon: "󰄀"; configKey: "privacyCameraMonitoring" }
            }

            Rectangle {
              Layout.fillWidth: true
              implicitHeight: noteRow.implicitHeight + 24
              radius: Colors.radiusMedium
              color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.08)
              border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.25)
              border.width: 1

              RowLayout {
                id: noteRow
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Colors.spacingM }
                spacing: Colors.spacingM

                Text {
                  text: "󰋗"
                  color: Colors.primary
                  font.family: Colors.fontMono
                  font.pixelSize: Colors.fontSizeXL
                  Layout.alignment: Qt.AlignTop
                }

                Text {
                  text: "Privacy indicators appear in the bar when microphone, camera, or screen sharing is active."
                  color: Colors.fgSecondary
                  font.pixelSize: Colors.fontSizeMedium
                  wrapMode: Text.WordWrap
                  Layout.fillWidth: true
                }
              }
            }
          }

          // Power tab
          ColumnLayout {
            visible: activeTab === "power"
            spacing: Colors.spacingXL
            Layout.fillWidth: true

            SectionLabel { text: "POWER MENU" }

            ConfigSlider {
              label: "Powermenu Countdown"
              min: 1000
              max: 10000
              step: 500
              value: Config.powermenuCountdown
              unit: "ms"
              onMoved: (v) => Config.powermenuCountdown = v
            }

            SectionLabel { text: "DISPLAY" }

            GridLayout {
              columns: 2
              columnSpacing: Colors.spacingL
              rowSpacing: Colors.spacingL
              Layout.fillWidth: true

              ToggleCard { label: "Screen Borders"; icon: "󰩪"; configKey: "showScreenBorders" }
              ToggleCard { label: "Idle Inhibitor"; icon: "󰈈"; configKey: "idleInhibitEnabled" }
            }
          }

          // Keybinds tab
          ColumnLayout {
            visible: activeTab === "keybinds"
            spacing: Colors.spacingL
            Layout.fillWidth: true

            // Search bar
            Rectangle {
              Layout.fillWidth: true
              height: 40
              radius: Colors.radiusSmall
              color: Colors.bgWidget
              border.color: keybindsSearch.activeFocus ? Colors.primary : Colors.border
              border.width: 1
              Behavior on border.color { ColorAnimation { duration: 150 } }

              RowLayout {
                anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                spacing: Colors.spacingS

                Text {
                  text: "󰍉"
                  color: Colors.fgDim
                  font.family: Colors.fontMono
                  font.pixelSize: Colors.fontSizeXL
                }

                TextInput {
                  id: keybindsSearch
                  Layout.fillWidth: true
                  color: Colors.text
                  font.pixelSize: Colors.fontSizeMedium
                  onTextChanged: settingsRoot.keybindsFilter = text.toLowerCase()

                  Text {
                    anchors.fill: parent
                    text: "Search keybindings..."
                    color: Colors.fgDim
                    font.pixelSize: parent.font.pixelSize
                    visible: parent.text.length === 0
                  }
                }

                Text {
                  text: "󰅖"
                  color: Colors.fgDim
                  font.family: Colors.fontMono
                  font.pixelSize: Colors.fontSizeLarge
                  visible: keybindsSearch.text.length > 0

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: keybindsSearch.text = ""
                  }
                }
              }
            }

            // Loading state
            Text {
              visible: keybindsList.length === 0
              text: "Loading keybindings…"
              color: Colors.fgDim
              font.pixelSize: Colors.fontSizeMedium
              Layout.alignment: Qt.AlignHCenter
              Layout.topMargin: 20
            }

            // Keybind rows via Repeater
            Repeater {
              model: {
                var filter = settingsRoot.keybindsFilter;
                var list = settingsRoot.keybindsList;
                if (!filter) return list;
                return list.filter(function(b) {
                  var haystack = (b.mods + " " + b.key + " " + b.dispatcher + " " + b.arg).toLowerCase();
                  return haystack.indexOf(filter) !== -1;
                });
              }

              delegate: Rectangle {
                Layout.fillWidth: true
                implicitHeight: kbRow.implicitHeight + 16
                radius: Colors.radiusXS
                color: Colors.bgWidget
                border.color: Colors.border
                border.width: 1

                RowLayout {
                  id: kbRow
                  anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: Colors.spacingM; rightMargin: Colors.spacingM }
                  spacing: Colors.spacingM

                  // Chord badge
                  Rectangle {
                    implicitWidth: chordText.implicitWidth + 16
                    height: 26
                    radius: 6
                    color: Colors.highlight
                    border.color: Colors.primary
                    border.width: 1

                    Text {
                      id: chordText
                      anchors.centerIn: parent
                      text: {
                        var parts = [];
                        if (modelData.mods) parts.push(modelData.mods);
                        if (modelData.key)  parts.push(modelData.key);
                        return parts.join(" + ");
                      }
                      color: Colors.primary
                      font.family: Colors.fontMono
                      font.pixelSize: Colors.fontSizeSmall
                      font.weight: Font.DemiBold
                    }
                  }

                  // Dispatcher + arg
                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                      text: modelData.dispatcher
                      color: Colors.text
                      font.pixelSize: Colors.fontSizeMedium
                      font.weight: Font.DemiBold
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                    }

                    Text {
                      text: modelData.arg || "—"
                      color: Colors.fgSecondary
                      font.pixelSize: Colors.fontSizeSmall
                      font.family: modelData.arg ? Colors.fontMono : ""
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                      visible: modelData.arg.length > 0 || true
                    }
                  }
                }
              }
            }

            // Refresh button
            Rectangle {
              Layout.fillWidth: true
              height: 42
              radius: Colors.radiusSmall
              color: Colors.bgWidget
              border.color: Colors.border
              border.width: 1

              SharedWidgets.StateLayer {
                id: kbRefreshStateLayer
                hovered: kbRefreshHover.containsMouse
                pressed: kbRefreshHover.pressed
              }

              RowLayout {
                anchors.centerIn: parent
                spacing: Colors.spacingS
                Text { text: "󰑐"; color: Colors.fgSecondary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeLarge }
                Text { text: "Refresh"; color: Colors.text; font.pixelSize: Colors.fontSizeMedium }
              }

              MouseArea {
                id: kbRefreshHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                  kbRefreshStateLayer.burst(mouse.x, mouse.y);
                  settingsRoot.keybindsList = [];
                  hyprBindsProc.running = true;
                }
              }
            }
          }

          // Plugins tab
          ColumnLayout {
            visible: activeTab === "plugins"
            spacing: Colors.spacingXL
            Layout.fillWidth: true

            // Header row: plugin count + scan button
            RowLayout {
              Layout.fillWidth: true
              spacing: Colors.spacingM

              ColumnLayout {
                spacing: 2
                Layout.fillWidth: true

                Text {
                  text: PluginService.plugins.length + " plugin" + (PluginService.plugins.length !== 1 ? "s" : "") + " found"
                  color: Colors.text
                  font.pixelSize: Colors.fontSizeMedium
                  font.weight: Font.Medium
                }

                Text {
                  text: PluginService.plugins.filter(function(p) { return p.enabled; }).length + " enabled"
                  color: Colors.fgSecondary
                  font.pixelSize: Colors.fontSizeSmall
                }
              }

              // Scan / Refresh button
              Rectangle {
                implicitWidth: scanRow.implicitWidth + 24
                height: 36
                radius: Colors.radiusSmall
                color: Colors.bgWidget
                border.color: Colors.border
                border.width: 1

                SharedWidgets.StateLayer {
                  id: scanStateLayer
                  hovered: scanHover.containsMouse
                  pressed: scanHover.pressed
                }

                RowLayout {
                  id: scanRow
                  anchors.centerIn: parent
                  spacing: Colors.spacingS
                  Text {
                    text: "󰑐"
                    color: Colors.fgSecondary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeLarge
                  }
                  Text {
                    text: "Scan"
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeMedium
                    font.weight: Font.Medium
                  }
                }

                MouseArea {
                  id: scanHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: (mouse) => {
                    scanStateLayer.burst(mouse.x, mouse.y);
                    PluginService.scanPlugins();
                  }
                }
              }
            }

            // Empty state
            ColumnLayout {
              visible: PluginService.plugins.length === 0
              Layout.fillWidth: true
              Layout.topMargin: 24
              spacing: Colors.spacingM

              Text {
                text: "󰏗"
                color: Colors.textDisabled
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeHuge
                Layout.alignment: Qt.AlignHCenter
              }

              Text {
                text: "No plugins found"
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeLarge
                font.weight: Font.DemiBold
                Layout.alignment: Qt.AlignHCenter
              }

              Text {
                text: "Add a folder with manifest.json to get started"
                color: Colors.fgDim
                font.pixelSize: Colors.fontSizeSmall
                Layout.alignment: Qt.AlignHCenter
              }
            }

            // Plugin list
            Repeater {
              model: PluginService.plugins

              delegate: Rectangle {
                Layout.fillWidth: true
                implicitHeight: pluginCardRow.implicitHeight + 28
                radius: Colors.radiusMedium
                color: Colors.bgWidget
                border.color: modelData.enabled ? Colors.primary : Colors.border
                border.width: 1

                Behavior on border.color { ColorAnimation { duration: 180 } }

                RowLayout {
                  id: pluginCardRow
                  anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: Colors.spacingM
                  }
                  spacing: Colors.spacingM

                  // Plugin icon
                  Rectangle {
                    width: 38
                    height: 38
                    radius: Colors.radiusSmall
                    color: modelData.enabled
                      ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.12)
                      : Colors.withAlpha(Colors.text, 0.06)
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                      anchors.centerIn: parent
                      text: modelData.type === "bar-widget" ? "󰖯" : "󰖲"
                      color: modelData.enabled ? Colors.primary : Colors.fgDim
                      font.family: Colors.fontMono
                      font.pixelSize: Colors.fontSizeXL
                      Behavior on color { ColorAnimation { duration: 180 } }
                    }
                  }

                  // Info column
                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    RowLayout {
                      spacing: Colors.spacingS

                      Text {
                        text: modelData.name
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeMedium
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                      }

                      // Version chip
                      Rectangle {
                        implicitWidth: verLabel.implicitWidth + 10
                        height: 18
                        radius: height / 2
                        color: Colors.withAlpha(Colors.text, 0.08)

                        Text {
                          id: verLabel
                          anchors.centerIn: parent
                          text: "v" + modelData.version
                          color: Colors.fgSecondary
                          font.pixelSize: Colors.fontSizeXS
                          font.family: Colors.fontMono
                        }
                      }

                      // Type badge
                      Rectangle {
                        implicitWidth: typeLabel.implicitWidth + 10
                        height: 18
                        radius: height / 2
                        color: modelData.type === "bar-widget"
                          ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.14)
                          : Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.14)

                        Text {
                          id: typeLabel
                          anchors.centerIn: parent
                          text: modelData.type === "bar-widget" ? "Bar" : "Desktop"
                          color: modelData.type === "bar-widget" ? Colors.accent : Colors.primary
                          font.pixelSize: Colors.fontSizeXS
                          font.weight: Font.DemiBold
                        }
                      }
                    }

                    Text {
                      visible: modelData.description.length > 0
                      text: modelData.description
                      color: Colors.fgSecondary
                      font.pixelSize: Colors.fontSizeSmall
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                    }

                    Text {
                      text: "by " + modelData.author
                      color: Colors.fgDim
                      font.pixelSize: Colors.fontSizeXS
                    }
                  }

                  // Enable/disable toggle
                  SharedWidgets.DankToggle {
                    checked: modelData.enabled
                    Layout.alignment: Qt.AlignVCenter
                    onToggled: {
                      if (modelData.enabled)
                        PluginService.disablePlugin(modelData.id);
                      else
                        PluginService.enablePlugin(modelData.id);
                    }
                  }
                }
              }
            }

            // Info callout
            Rectangle {
              Layout.fillWidth: true
              implicitHeight: pluginInfoRow.implicitHeight + 28
              radius: Colors.radiusMedium
              color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.07)
              border.color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.22)
              border.width: 1

              ColumnLayout {
                id: pluginInfoRow
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: Colors.spacingM }
                spacing: Colors.spacingS

                RowLayout {
                  spacing: Colors.spacingS

                  Text {
                    text: "󰋗"
                    color: Colors.primary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeLarge
                    Layout.alignment: Qt.AlignTop
                  }

                  Text {
                    text: "How to install plugins"
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeMedium
                    font.weight: Font.DemiBold
                  }
                }

                Text {
                  text: "Plugin directory:  ~/.config/quickshell/plugins/"
                  color: Colors.fgSecondary
                  font.pixelSize: Colors.fontSizeSmall
                  font.family: Colors.fontMono
                  Layout.fillWidth: true
                  wrapMode: Text.WrapAnywhere
                }

                Text {
                  text: "Each plugin is a folder containing a manifest.json and a QML file.\n"
                      + "manifest.json fields:  id, name, description, author, version, type (\"bar-widget\" or \"desktop-widget\"), main"
                  color: Colors.fgSecondary
                  font.pixelSize: Colors.fontSizeSmall
                  wrapMode: Text.WordWrap
                  Layout.fillWidth: true
                }
              }
            }
          }

          // About tab
          ColumnLayout {
            visible: activeTab === "about"
            spacing: Colors.spacingXL
            Layout.fillWidth: true

            // Shell identity card
            Rectangle {
              Layout.fillWidth: true
              implicitHeight: shellCard.implicitHeight + 32
              radius: Colors.radiusLarge
              color: Colors.bgWidget
              border.color: Colors.border
              border.width: 1

              ColumnLayout {
                id: shellCard
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
                spacing: Colors.spacingS

                RowLayout {
                  spacing: Colors.spacingM

                  Text {
                    text: "󱗼"
                    color: Colors.primary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeHuge
                  }

                  ColumnLayout {
                    spacing: 2
                    Text {
                      text: "Quickshell"
                      color: Colors.text
                      font.pixelSize: Colors.fontSizeHuge
                      font.weight: Font.Bold
                    }
                    Text {
                      text: "QML Desktop Shell"
                      color: Colors.fgSecondary
                      font.pixelSize: Colors.fontSizeMedium
                    }
                  }
                }
              }
            }

            SectionLabel { text: "SYSTEM INFO" }

            // Info rows
            Repeater {
              model: [
                { icon: "󰍹", label: "Hostname", value: settingsRoot.aboutHostname || "…" },
                { icon: "󰌢", label: "Kernel",   value: settingsRoot.aboutKernel   || "…" },
                { icon: "󱑎", label: "Uptime",   value: settingsRoot.aboutUptime   || "…" }
              ]

              delegate: Rectangle {
                Layout.fillWidth: true
                height: 52
                radius: Colors.radiusXS
                color: Colors.bgWidget
                border.color: Colors.border
                border.width: 1

                RowLayout {
                  anchors { fill: parent; leftMargin: Colors.spacingM; rightMargin: Colors.spacingM }
                  spacing: Colors.spacingM

                  Text {
                    text: modelData.icon
                    color: Colors.primary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeXL
                  }

                  Text {
                    text: modelData.label
                    color: Colors.fgSecondary
                    font.pixelSize: Colors.fontSizeMedium
                    Layout.preferredWidth: 80
                  }

                  Text {
                    text: modelData.value
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeMedium
                    font.family: Colors.fontMono
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                  }
                }
              }
            }

            SectionLabel { text: "ACTIONS" }

            // Restart Shell button
            Rectangle {
              Layout.fillWidth: true
              height: 48
              radius: Colors.radiusSmall
              color: Colors.primary

              SharedWidgets.StateLayer {
                id: restartStateLayer
                hovered: restartHover.containsMouse
                pressed: restartHover.pressed
                stateColor: Colors.primary
              }

              RowLayout {
                anchors.centerIn: parent
                spacing: Colors.spacingM
                Text { text: "󰜉"; color: Colors.text; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL }
                Text { text: "Restart Shell"; color: Colors.text; font.weight: Font.Bold; font.pixelSize: Colors.fontSizeMedium }
              }

              MouseArea {
                id: restartHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                  restartStateLayer.burst(mouse.x, mouse.y);
                  settingsRoot.close();
                  restartShellProc.running = true;
                }
              }
            }

            SectionLabel { text: "CREDITS" }

            Rectangle {
              Layout.fillWidth: true
              implicitHeight: creditsContent.implicitHeight + 24
              radius: Colors.radiusMedium
              color: Colors.bgWidget
              border.color: Colors.border
              border.width: 1

              ColumnLayout {
                id: creditsContent
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                spacing: Colors.spacingS

                Text {
                  text: "Built with Quickshell"
                  color: Colors.text
                  font.pixelSize: Colors.fontSizeMedium
                  font.weight: Font.DemiBold
                }
                Text {
                  text: "Powered by Qt / QML"
                  color: Colors.fgSecondary
                  font.pixelSize: Colors.fontSizeMedium
                }
                Text {
                  text: "Icons: Nerd Fonts"
                  color: Colors.fgSecondary
                  font.pixelSize: Colors.fontSizeMedium
                }
                Text {
                  text: "Theming: pywal"
                  color: Colors.fgSecondary
                  font.pixelSize: Colors.fontSizeMedium
                }
              }
            }
          }
        }
      }
    }

    component SectionLabel: Text {
      color: Colors.textDisabled
      font.pixelSize: Colors.fontSizeXS
      font.weight: Font.Black
      font.letterSpacing: 1.2
      Layout.topMargin: 6
    }

    component TabBtn: Rectangle {
      property string label
      property string icon
      property string tabId
      Layout.fillWidth: true
      height: 44
      radius: Colors.radiusSmall
      color: activeTab === tabId ? Colors.highlight : "transparent"
      Behavior on color { ColorAnimation { duration: 160 } }

      SharedWidgets.StateLayer {
        id: tabStateLayer
        hovered: tabMouse.containsMouse
        pressed: tabMouse.pressed
        visible: activeTab !== tabId
      }

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Colors.spacingL
        spacing: Colors.spacingM
        Text {
          text: icon
          color: activeTab === tabId ? Colors.primary : Colors.fgDim
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeXL
        }
        Text {
          text: label
          color: activeTab === tabId ? Colors.text : Colors.fgSecondary
          font.pixelSize: Colors.fontSizeMedium
          font.weight: activeTab === tabId ? Font.DemiBold : Font.Normal
        }
      }

      MouseArea {
        id: tabMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
          tabStateLayer.burst(mouse.x, mouse.y);
          activeTab = tabId;
        }
      }
    }

    component ConfigSlider: ColumnLayout {
      property string label
      property real min
      property real max
      property real value
      property real step: 1
      property string unit: step < 1 ? "%" : "px"
      signal moved(real v)
      spacing: Colors.spacingM
      Layout.fillWidth: true

      RowLayout {
        Text { text: label; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.Medium }
        Item { Layout.fillWidth: true }
        Text {
          text: (unit === "ms" ? Math.round(value) : (step < 1 ? Math.round(value * 100) : Math.round(value))) + unit
          color: Colors.fgSecondary
          font.pixelSize: Colors.fontSizeSmall
          font.family: Colors.fontMono
        }
      }

      Item {
        Layout.fillWidth: true
        height: 24

        // Track
        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width
          height: 6
          color: Colors.surface
          radius: 3
          Rectangle {
            width: parent.width * ((value - min) / (max - min))
            height: parent.height
            color: Colors.primary
            radius: 3
            Behavior on width { NumberAnimation { duration: 80 } }
          }
        }

        // Thumb handle
        Rectangle {
          width: 14
          height: 14
          radius: 7
          color: Colors.primary
          border.color: Colors.bgWidget
          border.width: 2
          x: Math.max(0, Math.min(parent.width - width, parent.width * ((value - min) / (max - min)) - width / 2))
          anchors.verticalCenter: parent.verticalCenter
          Behavior on x { NumberAnimation { duration: 80 } }
        }

        MouseArea {
          anchors.fill: parent
          anchors.topMargin: -4
          anchors.bottomMargin: -4
          cursorShape: Qt.PointingHandCursor
          function updateValue(mouse) {
            var raw = min + (mouse.x / width) * (max - min);
            var val = Math.round(raw / step) * step;
            moved(Math.max(min, Math.min(max, val)));
          }
          onPressed: (mouse) => updateValue(mouse)
          onPositionChanged: (mouse) => {
            if (pressed) updateValue(mouse);
          }
        }
      }
    }

    component ToggleCard: Rectangle {
      property string label
      property string icon
      property string configKey

      Layout.fillWidth: true
      implicitHeight: 84
      radius: Colors.radiusMedium
      color: Colors.bgWidget
      border.color: Config[configKey] ? Colors.primary : Colors.border
      border.width: 1

      SharedWidgets.StateLayer {
        id: toggleStateLayer
        hovered: toggleHover.containsMouse
        pressed: toggleHover.pressed
      }

      RowLayout {
        anchors.fill: parent
        anchors.margins: Colors.spacingM
        spacing: Colors.spacingM

        Text {
          text: icon
          color: Config[configKey] ? Colors.primary : Colors.textSecondary
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeHuge
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 3
          Text { text: label; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.DemiBold }
          Text { text: Config[configKey] ? "Enabled" : "Disabled"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeSmall }
        }

        SharedWidgets.DankToggle {
          checked: Config[configKey]
          onToggled: Config[configKey] = !Config[configKey]
        }
      }

      MouseArea {
        id: toggleHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
          toggleStateLayer.burst(mouse.x, mouse.y);
          Config[configKey] = !Config[configKey];
        }
      }
    }

    component ModeSelector: ColumnLayout {
      id: modeSelector
      property string label
      property string currentValue
      property var options: []
      signal modeSelected(string modeValue)
      spacing: Colors.spacingM
      Layout.fillWidth: true

      Text { text: label; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.Medium }

      Flow {
        Layout.fillWidth: true
        width: parent.width
        spacing: Colors.paddingSmall

        Repeater {
          model: options
          delegate: SharedWidgets.FilterChip {
            label: modelData.label
            selected: modeSelector.currentValue === modelData.value
            onClicked: modeSelector.modeSelected(modelData.value)
          }
        }
      }
    }
  }
}
