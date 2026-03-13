import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"
import "../widgets" as SharedWidgets

PanelWindow {
  id: root

  anchors {
    top: true
    left: true
    right: true
    bottom: true
  }

  color: "transparent"
  visible: isOpen

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  WlrLayershell.namespace: "quickshell-filebrowser"

  // ── Public API ─────────────────────────────────────────────────────────────
  property bool isOpen: false

  // "open" or "save"
  property string mode: "open"
  property string title: mode === "open" ? "Open File" : (mode === "save" ? "Save File" : "Select Folder")

  // Current directory being browsed
  property string currentPath: Quickshell.env("HOME") || "/home"

  // Active file filters: [{ label: "Images", extensions: ["jpg","png","webp"] }]
  // Empty array = show all files
  property var fileFilters: []
  property int activeFilterIndex: 0

  // The file the user has highlighted / typed
  property string selectedFile: ""
  property string saveFileName: ""

  // Signals
  signal fileSelected(string filePath)
  signal folderSelected(string folderPath)
  signal cancelled()

  // Open the browser, optionally set path / filters / mode
  function open(initialPath, filters, browseMode) {
    if (initialPath && initialPath.length > 0) currentPath = initialPath;
    if (filters) fileFilters = filters;
    if (browseMode) mode = browseMode;
    selectedFile = "";
    saveFileName = "";
    activeFilterIndex = 0;
    isOpen = true;
    _listDirectory();
  }

  function close() {
    isOpen = false;
    _fileEntries = [];
  }

  function toggle() {
    isOpen ? close() : open(currentPath, fileFilters, mode);
  }

  IpcHandler {
    target: "FileBrowser"
    function toggle() { root.toggle(); }
    function open()   { root.open("", [], "open"); }
    function close()  { root.close(); }
  }

  // ── Internal state ─────────────────────────────────────────────────────────
  property var _fileEntries: []    // Array of parsed file objects
  property bool _loading: false
  property string _sortBy: "name"  // "name" | "date" | "size" | "type"
  property bool _sortAsc: true
  property bool _viewGrid: true    // true = grid, false = list

  readonly property var _quickLocations: [
    { label: "Home",      icon: "󰋜", path: Quickshell.env("HOME") || "/home" },
    { label: "Desktop",   icon: "󰧨", path: (Quickshell.env("HOME") || "/home") + "/Desktop" },
    { label: "Documents", icon: "󰈙", path: (Quickshell.env("HOME") || "/home") + "/Documents" },
    { label: "Downloads", icon: "󰉍", path: (Quickshell.env("HOME") || "/home") + "/Downloads" },
    { label: "Pictures",  icon: "󰉏", path: (Quickshell.env("HOME") || "/home") + "/Pictures" },
    { label: "Videos",    icon: "󰈫", path: (Quickshell.env("HOME") || "/home") + "/Videos" },
    { label: "Music",     icon: "󰝚", path: (Quickshell.env("HOME") || "/home") + "/Music" }
  ]

  // ── Helpers ────────────────────────────────────────────────────────────────
  function _listDirectory() {
    if (_loading) return;
    _loading = true;
    _fileEntries = [];
    // Use find -maxdepth 1 to list directory contents (skips '.' itself).
    // Output: fullpath TAB type TAB size TAB mtime
    // -printf format: %p = path, %y = type char (d/f/l/…), %s = size, %T@ = mtime float
    // We convert %y to a word via awk for easier JS parsing.
    var script =
      "find " + JSON.stringify(currentPath) + " -maxdepth 1 -mindepth 1 " +
      "-printf '%p\\t%y\\t%s\\t%T@\\n' 2>/dev/null | " +
      "awk -F'\\t' 'BEGIN{OFS=\"\\t\"} {" +
      "  t=$2; if(t==\"d\") t=\"directory\"; else t=\"regular file\";" +
      "  print $1, t, $3, int($4)" +
      "}'";
    listProc.command = ["sh", "-c", script];
    listProc.running = true;
  }

  function _navigate(path) {
    currentPath = path;
    selectedFile = "";
    _listDirectory();
  }

  function _navigateUp() {
    var parts = currentPath.replace(/\/+$/, "").split("/");
    if (parts.length <= 1) return;
    parts.pop();
    var parent = parts.join("/") || "/";
    _navigate(parent);
  }

  function _buildBreadcrumbs() {
    // Returns array of {label, path} segments
    var parts = currentPath.replace(/\/+$/, "").split("/").filter(s => s.length > 0);
    var crumbs = [{ label: "/", path: "/" }];
    var acc = "";
    for (var i = 0; i < parts.length; i++) {
      acc += "/" + parts[i];
      crumbs.push({ label: parts[i], path: acc });
    }
    return crumbs;
  }

  function _parseStatOutput(raw) {
    var lines = raw.trim().split("\n");
    var entries = [];
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      if (!line.trim()) continue;
      var parts = line.split("\t");
      if (parts.length < 4) continue;
      var fullPath = parts[0];
      var typStr   = parts[1];
      var size     = parseInt(parts[2]) || 0;
      var mtime    = parseInt(parts[3]) || 0;

      // Extract filename from full path
      var name = fullPath.replace(/\/$/, "").split("/").pop();
      if (!name || name === "." || name === "..") continue;

      var isDir = (typStr === "directory");
      var ext = isDir ? "" : (name.lastIndexOf(".") > 0 ? name.slice(name.lastIndexOf(".") + 1).toLowerCase() : "");
      var isImage = ["jpg","jpeg","png","webp","gif","bmp","svg","tiff","avif"].indexOf(ext) >= 0;

      entries.push({
        name: name,
        path: fullPath,
        isDir: isDir,
        size: size,
        mtime: mtime,
        extension: ext,
        isImage: isImage
      });
    }
    return entries;
  }

  function _sortEntries(entries) {
    var dirs  = entries.filter(e => e.isDir);
    var files = entries.filter(e => !e.isDir);

    function cmp(a, b) {
      var av, bv;
      if (_sortBy === "name") {
        av = a.name.toLowerCase(); bv = b.name.toLowerCase();
      } else if (_sortBy === "size") {
        av = a.size; bv = b.size;
      } else if (_sortBy === "date") {
        av = a.mtime; bv = b.mtime;
      } else if (_sortBy === "type") {
        av = a.extension.toLowerCase(); bv = b.extension.toLowerCase();
      } else {
        av = a.name.toLowerCase(); bv = b.name.toLowerCase();
      }
      if (av < bv) return _sortAsc ? -1 : 1;
      if (av > bv) return _sortAsc ? 1 : -1;
      return 0;
    }

    dirs.sort(cmp);
    files.sort(cmp);
    return dirs.concat(files);
  }

  function _applyFilters(entries) {
    if (fileFilters.length === 0) return entries;
    var filter = fileFilters[activeFilterIndex];
    if (!filter || !filter.extensions || filter.extensions.length === 0) return entries;
    return entries.filter(e => e.isDir || filter.extensions.indexOf(e.extension) >= 0);
  }

  function formatSize(bytes) {
    if (bytes < 1024)       return bytes + " B";
    if (bytes < 1048576)    return (bytes / 1024).toFixed(1)       + " KB";
    if (bytes < 1073741824) return (bytes / 1048576).toFixed(1)    + " MB";
    return                         (bytes / 1073741824).toFixed(1)  + " GB";
  }

  function formatDate(ts) {
    var d = new Date(ts * 1000);
    var y = d.getFullYear();
    var mo = ("0" + (d.getMonth() + 1)).slice(-2);
    var day = ("0" + d.getDate()).slice(-2);
    return y + "-" + mo + "-" + day;
  }

  function fileIcon(entry) {
    if (entry.isDir) return "󰉋";
    var ext = entry.extension;
    if (["jpg","jpeg","png","webp","gif","bmp","svg","tiff","avif"].indexOf(ext) >= 0) return "󰋩";
    if (["mp4","mkv","mov","avi","webm","flv"].indexOf(ext) >= 0) return "󰈫";
    if (["mp3","flac","wav","ogg","aac","opus"].indexOf(ext) >= 0) return "󰝚";
    if (["pdf"].indexOf(ext) >= 0) return "󰈦";
    if (["zip","tar","gz","bz2","xz","7z","rar","zst"].indexOf(ext) >= 0) return "󰗄";
    if (["sh","bash","zsh","fish"].indexOf(ext) >= 0) return "󰆍";
    if (["js","ts","jsx","tsx","py","rs","go","c","cpp","h","java","rb","cs"].indexOf(ext) >= 0) return "󰴭";
    if (["txt","md","rst","log"].indexOf(ext) >= 0) return "󰈙";
    if (["json","yaml","yml","toml","xml","ini","conf"].indexOf(ext) >= 0) return "󰘦";
    if (["nix"].indexOf(ext) >= 0) return "󱄅";
    if (["html","css","scss"].indexOf(ext) >= 0) return "󰌒";
    return "󰈔";
  }

  // ── Directory listing process ──────────────────────────────────────────────
  Process {
    id: listProc
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var raw = this.text || "";
        var parsed = root._parseStatOutput(raw);
        var filtered = root._applyFilters(parsed);
        var sorted = root._sortEntries(filtered);
        root._fileEntries = sorted;
        root._loading = false;
      }
    }
    onRunningChanged: {
      if (!running && root._loading) root._loading = false;
    }
  }

  // ── Background scrim ───────────────────────────────────────────────────────
  MouseArea {
    anchors.fill: parent
    onClicked: root.close()

    Rectangle {
      anchors.fill: parent
      color: Colors.background
      opacity: 0.62
    }
  }

  // ── Modal card ─────────────────────────────────────────────────────────────
  Rectangle {
    id: mainBox
    readonly property real modalMarginX: Math.max(16, parent.width * 0.03)
    readonly property real modalMarginY: Math.max(16, parent.height * 0.03)
    readonly property real modalMinWidth: 760
    readonly property real modalMaxWidth: 1200
    readonly property real modalMinHeight: 560
    readonly property real modalMaxHeight: 820
    readonly property real modalAvailWidth: Math.max(320, parent.width - modalMarginX * 2)
    readonly property real modalAvailHeight: Math.max(320, parent.height - modalMarginY * 2)
    width: modalAvailWidth < modalMinWidth
      ? modalAvailWidth
      : Math.min(modalAvailWidth, modalMaxWidth)
    height: modalAvailHeight < modalMinHeight
      ? modalAvailHeight
      : Math.min(modalAvailHeight, modalMaxHeight)
    anchors.centerIn: parent

    color: Colors.popupSurface
    border.color: Colors.border
    border.width: 1
    radius: Colors.radiusLarge
    clip: true

    focus: root.isOpen
    onVisibleChanged: if (visible) forceActiveFocus()
    Keys.onEscapePressed: root.close()

    opacity: root.isOpen ? 1.0 : 0.0
    scale:   root.isOpen ? 1.0 : 0.95
    Behavior on opacity { NumberAnimation { id: fbFadeAnim;  duration: 220; easing.type: Easing.OutCubic } }
    Behavior on scale   { NumberAnimation { id: fbScaleAnim; duration: 260; easing.type: Easing.OutBack  } }
    layer.enabled: fbFadeAnim.running || fbScaleAnim.running

    // Block click-through
    MouseArea { anchors.fill: parent }

    SharedWidgets.ElevationShadow { elevation: 20; shadowRadius: mainBox.radius }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 0
      spacing: 0

      // ── Header ──────────────────────────────────────────────────────────────
      Rectangle {
        Layout.fillWidth: true
        height: 52
        color: "transparent"
        // bottom border
        Rectangle {
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          anchors.right: parent.right
          height: 1
          color: Colors.border
        }

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: Colors.paddingLarge
          anchors.rightMargin: Colors.paddingMedium
          spacing: Colors.spacingM

          // Title
          Text {
            text: root.title
            color: Colors.text
            font.pixelSize: Colors.fontSizeLarge
            font.weight: Colors.fontWeightBold
            font.letterSpacing: -0.3
          }

          Item { Layout.fillWidth: true }

          // View-toggle: grid
          Rectangle {
            width: 30; height: 30; radius: Colors.radiusSmall
            color: root._viewGrid
              ? Colors.withAlpha(Colors.primary, 0.25)
              : "transparent"
            Behavior on color { ColorAnimation { duration: 130 } }

            Text {
              anchors.centerIn: parent
              text: "󰕴"
              color: root._viewGrid ? Colors.primary : Colors.textSecondary
              font.family: Colors.fontMono
              font.pixelSize: Colors.fontSizeLarge
            }
            SharedWidgets.StateLayer {
              id: gridToggleSL
              hovered: gridToggleHover.containsMouse
              pressed: gridToggleHover.containsPress
              visible: !root._viewGrid
            }
            MouseArea {
              id: gridToggleHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: (mouse) => { gridToggleSL.burst(mouse.x, mouse.y); root._viewGrid = true; }
            }
          }

          // View-toggle: list
          Rectangle {
            width: 30; height: 30; radius: Colors.radiusSmall
            color: !root._viewGrid
              ? Colors.withAlpha(Colors.primary, 0.25)
              : "transparent"
            Behavior on color { ColorAnimation { duration: 130 } }

            Text {
              anchors.centerIn: parent
              text: "󰕵"
              color: !root._viewGrid ? Colors.primary : Colors.textSecondary
              font.family: Colors.fontMono
              font.pixelSize: Colors.fontSizeLarge
            }
            SharedWidgets.StateLayer {
              id: listToggleSL
              hovered: listToggleHover.containsMouse
              pressed: listToggleHover.containsPress
              visible: root._viewGrid
            }
            MouseArea {
              id: listToggleHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: (mouse) => { listToggleSL.burst(mouse.x, mouse.y); root._viewGrid = false; }
            }
          }

          // Close
          Rectangle {
            width: 30; height: 30; radius: height / 2
            color: "transparent"

            Text {
              anchors.centerIn: parent
              text: "󰅖"
              color: Colors.textSecondary
              font.family: Colors.fontMono
              font.pixelSize: Colors.fontSizeLarge
            }
            SharedWidgets.StateLayer {
              id: closeSL
              hovered: closeHover.containsMouse
              pressed: closeHover.containsPress
            }
            MouseArea {
              id: closeHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: (mouse) => { closeSL.burst(mouse.x, mouse.y); root.cancelled(); root.close(); }
            }
          }
        }
      }

      // ── Body: sidebar + main area ──────────────────────────────────────────
      RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 0

        // ── Sidebar ───────────────────────────────────────────────────────────
        Rectangle {
          Layout.preferredWidth: 180
          Layout.fillHeight: true
          color: Colors.withAlpha(Colors.surface, 0.5)

          // right border
          Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: Colors.border
          }

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: Colors.spacingS
            spacing: 2

            // Section label
            Text {
              Layout.leftMargin: Colors.spacingS
              Layout.topMargin: Colors.spacingS
              text: "QUICK ACCESS"
              color: Colors.textDisabled
              font.pixelSize: Colors.fontSizeXS
              font.weight: Colors.fontWeightBold
              font.letterSpacing: 1.0
            }

            Repeater {
              model: root._quickLocations

              delegate: Rectangle {
                required property var modelData
                required property int index

                Layout.fillWidth: true
                height: 34
                radius: Colors.radiusSmall
                color: {
                  var isActive = root.currentPath === modelData.path;
                  if (isActive) return Colors.withAlpha(Colors.primary, 0.22);
                  if (locHover.containsMouse) return Colors.withAlpha(Colors.text, 0.07);
                  return "transparent";
                }
                Behavior on color { ColorAnimation { duration: 120 } }

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: Colors.spacingM
                  anchors.rightMargin: Colors.spacingS
                  spacing: Colors.spacingS

                  Text {
                    text: modelData.icon
                    color: root.currentPath === modelData.path ? Colors.primary : Colors.textSecondary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeLarge
                  }
                  Text {
                    text: modelData.label
                    color: root.currentPath === modelData.path ? Colors.text : Colors.textSecondary
                    font.pixelSize: Colors.fontSizeMedium
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                  }
                }

                MouseArea {
                  id: locHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root._navigate(modelData.path)
                }
              }
            }

            // Spacer
            Item { Layout.fillHeight: true }

            // Current path display
            Rectangle {
              Layout.fillWidth: true
              height: 1
              color: Colors.border
              Layout.bottomMargin: Colors.spacingS
            }

            Text {
              Layout.fillWidth: true
              Layout.leftMargin: Colors.spacingS
              Layout.bottomMargin: Colors.spacingS
              text: root.currentPath
              color: Colors.textDisabled
              font.pixelSize: Colors.fontSizeXS
              wrapMode: Text.WrapAnywhere
              maximumLineCount: 3
              elide: Text.ElideRight
            }
          }
        }

        // ── Main area ──────────────────────────────────────────────────────────
        ColumnLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: 0

          // ── Path bar (breadcrumbs + up button) ──────────────────────────────
          Rectangle {
            Layout.fillWidth: true
            height: 38
            color: Colors.withAlpha(Colors.surface, 0.3)

            Rectangle {
              anchors.bottom: parent.bottom
              anchors.left: parent.left
              anchors.right: parent.right
              height: 1
              color: Colors.border
            }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: Colors.spacingM
              anchors.rightMargin: Colors.spacingM
              spacing: Colors.spacingXS

              // Up button
              Rectangle {
                width: 26; height: 26; radius: Colors.radiusSmall
                color: "transparent"

                Text {
                  anchors.centerIn: parent
                  text: "󰁞"
                  color: Colors.textSecondary
                  font.family: Colors.fontMono
                  font.pixelSize: Colors.fontSizeMedium
                }
                SharedWidgets.StateLayer {
                  id: upSL
                  hovered: upHover.containsMouse
                  pressed: upHover.containsPress
                }
                MouseArea {
                  id: upHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: (mouse) => { upSL.burst(mouse.x, mouse.y); root._navigateUp(); }
                }
              }

              // Breadcrumbs
              Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: breadRow.implicitWidth
                contentHeight: height
                clip: true
                interactive: contentWidth > width

                Row {
                  id: breadRow
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: 0

                  Repeater {
                    model: root._buildBreadcrumbs()

                    delegate: Row {
                      required property var modelData
                      required property int index
                      spacing: 2

                      Text {
                        text: "›"
                        color: Colors.textDisabled
                        font.pixelSize: Colors.fontSizeSmall
                        anchors.verticalCenter: parent.verticalCenter
                        visible: index > 0
                      }

                      Rectangle {
                        width: crumbText.implicitWidth + 8
                        height: 22
                        radius: Colors.radiusSmall
                        color: {
                          // highlight last segment
                          var crumbs = root._buildBreadcrumbs();
                          var isLast = (index === crumbs.length - 1);
                          if (isLast) return Colors.withAlpha(Colors.primary, 0.18);
                          if (crumbHover.containsMouse) return Colors.withAlpha(Colors.text, 0.08);
                          return "transparent";
                        }
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                          id: crumbText
                          anchors.centerIn: parent
                          text: modelData.label
                          color: {
                            var crumbs = root._buildBreadcrumbs();
                            var isLast = (index === crumbs.length - 1);
                            if (isLast) return Colors.primary;
                            return Colors.textSecondary;
                          }
                          font.pixelSize: Colors.fontSizeSmall
                        }

                        MouseArea {
                          id: crumbHover
                          anchors.fill: parent
                          hoverEnabled: true
                          cursorShape: Qt.PointingHandCursor
                          onClicked: root._navigate(modelData.path)
                        }
                      }
                    }
                  }
                }
              }

              // Refresh button
              Rectangle {
                width: 26; height: 26; radius: Colors.radiusSmall
                color: "transparent"

                Text {
                  anchors.centerIn: parent
                  text: "󰑐"
                  color: Colors.textSecondary
                  font.family: Colors.fontMono
                  font.pixelSize: Colors.fontSizeMedium
                }
                SharedWidgets.StateLayer {
                  id: refreshSL
                  hovered: refreshHover.containsMouse
                  pressed: refreshHover.containsPress
                }
                MouseArea {
                  id: refreshHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: (mouse) => { refreshSL.burst(mouse.x, mouse.y); root._listDirectory(); }
                }
              }
            }
          }

          // ── Sort controls (list-mode only) ────────────────────────────────────
          Rectangle {
            Layout.fillWidth: true
            height: 32
            color: Colors.withAlpha(Colors.surface, 0.2)
            visible: !root._viewGrid

            Rectangle {
              anchors.bottom: parent.bottom
              anchors.left: parent.left
              anchors.right: parent.right
              height: 1
              color: Colors.border
            }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: Colors.spacingM
              anchors.rightMargin: Colors.spacingM
              spacing: 0

              // Name column header
              Item {
                Layout.fillWidth: true
                Layout.preferredWidth: 100
                height: parent.height

                RowLayout {
                  anchors.fill: parent
                  spacing: Colors.spacingXS
                  Text {
                    text: "Name"
                    color: root._sortBy === "name" ? Colors.primary : Colors.textSecondary
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Colors.fontWeightMedium
                  }
                  Text {
                    text: root._sortBy === "name" ? (root._sortAsc ? "↑" : "↓") : ""
                    color: Colors.primary
                    font.pixelSize: Colors.fontSizeSmall
                  }
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (root._sortBy === "name") root._sortAsc = !root._sortAsc;
                    else { root._sortBy = "name"; root._sortAsc = true; }
                    root._fileEntries = root._sortEntries(root._fileEntries);
                  }
                }
              }

              // Size column header
              Item {
                Layout.preferredWidth: 80
                height: parent.height

                RowLayout {
                  anchors.fill: parent
                  spacing: Colors.spacingXS
                  Text {
                    text: "Size"
                    color: root._sortBy === "size" ? Colors.primary : Colors.textSecondary
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Colors.fontWeightMedium
                  }
                  Text {
                    text: root._sortBy === "size" ? (root._sortAsc ? "↑" : "↓") : ""
                    color: Colors.primary
                    font.pixelSize: Colors.fontSizeSmall
                  }
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (root._sortBy === "size") root._sortAsc = !root._sortAsc;
                    else { root._sortBy = "size"; root._sortAsc = true; }
                    root._fileEntries = root._sortEntries(root._fileEntries);
                  }
                }
              }

              // Date column header
              Item {
                Layout.preferredWidth: 100
                height: parent.height

                RowLayout {
                  anchors.fill: parent
                  spacing: Colors.spacingXS
                  Text {
                    text: "Modified"
                    color: root._sortBy === "date" ? Colors.primary : Colors.textSecondary
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Colors.fontWeightMedium
                  }
                  Text {
                    text: root._sortBy === "date" ? (root._sortAsc ? "↑" : "↓") : ""
                    color: Colors.primary
                    font.pixelSize: Colors.fontSizeSmall
                  }
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (root._sortBy === "date") root._sortAsc = !root._sortAsc;
                    else { root._sortBy = "date"; root._sortAsc = false; }
                    root._fileEntries = root._sortEntries(root._fileEntries);
                  }
                }
              }

              // Type column header
              Item {
                Layout.preferredWidth: 60
                height: parent.height

                RowLayout {
                  anchors.fill: parent
                  spacing: Colors.spacingXS
                  Text {
                    text: "Type"
                    color: root._sortBy === "type" ? Colors.primary : Colors.textSecondary
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Colors.fontWeightMedium
                  }
                  Text {
                    text: root._sortBy === "type" ? (root._sortAsc ? "↑" : "↓") : ""
                    color: Colors.primary
                    font.pixelSize: Colors.fontSizeSmall
                  }
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (root._sortBy === "type") root._sortAsc = !root._sortAsc;
                    else { root._sortBy = "type"; root._sortAsc = true; }
                    root._fileEntries = root._sortEntries(root._fileEntries);
                  }
                }
              }
            }
          }

          // ── File grid / list area ─────────────────────────────────────────────
          Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            // Loading indicator
            Item {
              anchors.centerIn: parent
              visible: root._loading
              width: 120; height: 60

              ColumnLayout {
                anchors.centerIn: parent
                spacing: Colors.spacingS

                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: "󰑐"
                  color: Colors.textDisabled
                  font.family: Colors.fontMono
                  font.pixelSize: 28

                  RotationAnimator on rotation {
                    running: root._loading
                    from: 0; to: 360; duration: 900
                    loops: Animation.Infinite
                  }
                }
                Text {
                  Layout.alignment: Qt.AlignHCenter
                  text: "Loading…"
                  color: Colors.textDisabled
                  font.pixelSize: Colors.fontSizeSmall
                }
              }
            }

            // Empty state
            Item {
              anchors.centerIn: parent
              visible: !root._loading && root._fileEntries.length === 0

              SharedWidgets.EmptyState {
                anchors.centerIn: parent
                icon: "󰉋"
                message: "This folder is empty"
                iconSize: 36
              }
            }

            // Grid view
            Flickable {
              id: gridFlick
              anchors.fill: parent
              contentWidth: width
              contentHeight: gridContent.implicitHeight
              clip: true
              visible: root._viewGrid && !root._loading

              Item {
                id: gridContent
                width: gridFlick.width
                implicitHeight: gridFlow.implicitHeight + Colors.paddingMedium * 2

                // 5-column grid using Flow
                Flow {
                  id: gridFlow
                  anchors.top: parent.top
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.topMargin: Colors.paddingMedium
                  anchors.leftMargin: Colors.paddingMedium
                  anchors.rightMargin: Colors.paddingMedium
                  spacing: Colors.spacingM
                  readonly property real contentW: Math.max(1, width - anchors.leftMargin - anchors.rightMargin)
                  readonly property int minCols: 3
                  readonly property int maxCols: 8
                  readonly property real minCellW: 120
                  readonly property int colCount: Math.max(
                    minCols,
                    Math.min(
                      maxCols,
                      Math.floor((contentW + spacing) / (minCellW + spacing))
                    )
                  )
                  readonly property real cellW: Math.max(
                    minCellW,
                    Math.floor((contentW - (colCount - 1) * spacing) / colCount)
                  )

                  // Invisible repeater to feed the flow
                  Repeater {
                    id: gridRepeater
                    model: root._fileEntries

                    delegate: Rectangle {
                      required property var modelData
                      required property int index

                      width: gridFlow.cellW
                      height: gridFlow.cellW + 28

                      radius: Colors.radiusSmall
                      color: {
                        var isSel = (root.selectedFile === modelData.path);
                        if (isSel) return Colors.withAlpha(Colors.primary, 0.28);
                        if (gridItemHover.containsMouse) return Colors.withAlpha(Colors.text, 0.08);
                        return "transparent";
                      }
                      Behavior on color { ColorAnimation { duration: 110 } }

                      ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: Colors.spacingXS

                        // Icon area
                        Item {
                          Layout.fillWidth: true
                          Layout.fillHeight: true

                          // Image thumbnail (images only)
                          Image {
                            anchors.fill: parent
                            anchors.margins: 4
                            visible: modelData.isImage
                            source: modelData.isImage ? ("file://" + modelData.path) : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 120
                            sourceSize.height: 120
                            cache: true
                            smooth: true
                            mipmap: true

                            layer.enabled: true
                            layer.effect: null

                            Rectangle {
                              anchors.fill: parent
                              radius: Colors.radiusSmall - 4
                              color: "transparent"
                              border.color: Colors.withAlpha(Colors.border, 0.5)
                              border.width: 1
                              clip: true
                            }
                          }

                          // Fallback icon (non-images or failed load)
                          Text {
                            anchors.centerIn: parent
                            visible: !modelData.isImage
                            text: root.fileIcon(modelData)
                            color: modelData.isDir ? Colors.accent : Colors.textSecondary
                            font.family: Colors.fontMono
                            font.pixelSize: gridFlow.cellW < 80 ? 28 : 36
                          }
                        }

                        // Filename
                        Text {
                          Layout.fillWidth: true
                          Layout.alignment: Qt.AlignHCenter
                          horizontalAlignment: Text.AlignHCenter
                          text: modelData.name
                          color: Colors.text
                          font.pixelSize: Colors.fontSizeSmall
                          elide: Text.ElideRight
                          maximumLineCount: 1
                        }
                      }

                      MouseArea {
                        id: gridItemHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton

                        onClicked: {
                          if (modelData.isDir) {
                            if (root.mode === "folder") {
                              root.selectedFile = modelData.path;
                              root.saveFileName = modelData.name;
                            } else {
                              root._navigate(modelData.path);
                            }
                          } else {
                            if (root.mode !== "folder") {
                              root.selectedFile = modelData.path;
                              root.saveFileName = modelData.name;
                            }
                          }
                        }
                        onDoubleClicked: {
                          if (modelData.isDir) {
                            root._navigate(modelData.path);
                          } else if (root.mode !== "folder") {
                            root.fileSelected(modelData.path);
                            root.close();
                          }
                        }
                      }
                    }
                  }
                }
              }

            }

            // List view
            Flickable {
              id: listFlick
              anchors.fill: parent
              contentWidth: width
              contentHeight: listColumn.implicitHeight
              clip: true
              visible: !root._viewGrid && !root._loading

              Column {
                id: listColumn
                width: listFlick.width

                Repeater {
                  model: root._fileEntries

                  delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width: listColumn.width
                    height: 38

                    color: {
                      var isSel = (root.selectedFile === modelData.path);
                      if (isSel) return Colors.withAlpha(Colors.primary, 0.22);
                      if (listItemHover.containsMouse) return Colors.withAlpha(Colors.text, 0.06);
                      return index % 2 === 0 ? "transparent" : Colors.withAlpha(Colors.surface, 0.3);
                    }
                    Behavior on color { ColorAnimation { duration: 100 } }

                    // bottom separator
                    Rectangle {
                      anchors.bottom: parent.bottom
                      anchors.left: parent.left
                      anchors.right: parent.right
                      height: 1
                      color: Colors.withAlpha(Colors.border, 0.4)
                    }

                    RowLayout {
                      anchors.fill: parent
                      anchors.leftMargin: Colors.spacingM
                      anchors.rightMargin: Colors.spacingM
                      spacing: Colors.spacingM

                      // Icon
                      Item {
                        width: 22; height: 22

                        Image {
                          anchors.fill: parent
                          visible: modelData.isImage
                          source: modelData.isImage ? ("file://" + modelData.path) : ""
                          fillMode: Image.PreserveAspectCrop
                          asynchronous: true
                          sourceSize.width: 22
                          sourceSize.height: 22
                          cache: true
                        }

                        Text {
                          anchors.centerIn: parent
                          visible: !modelData.isImage
                          text: root.fileIcon(modelData)
                          color: modelData.isDir ? Colors.accent : Colors.textSecondary
                          font.family: Colors.fontMono
                          font.pixelSize: Colors.fontSizeLarge
                        }
                      }

                      // Name
                      Text {
                        Layout.fillWidth: true
                        text: modelData.name
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeMedium
                        elide: Text.ElideRight
                      }

                      // Size
                      Text {
                        Layout.preferredWidth: 80
                        text: modelData.isDir ? "—" : root.formatSize(modelData.size)
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeSmall
                        horizontalAlignment: Text.AlignRight
                      }

                      // Date
                      Text {
                        Layout.preferredWidth: 100
                        text: root.formatDate(modelData.mtime)
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeSmall
                        horizontalAlignment: Text.AlignRight
                      }

                      // Extension / type
                      Text {
                        Layout.preferredWidth: 60
                        text: modelData.isDir ? "folder" : (modelData.extension || "—")
                        color: Colors.textDisabled
                        font.pixelSize: Colors.fontSizeSmall
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                      }
                    }

                    MouseArea {
                      id: listItemHover
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      acceptedButtons: Qt.LeftButton

                      onClicked: {
                        if (modelData.isDir) {
                          if (root.mode === "folder") {
                            root.selectedFile = modelData.path;
                            root.saveFileName = modelData.name;
                          } else {
                            root._navigate(modelData.path);
                          }
                        } else {
                          if (root.mode !== "folder") {
                            root.selectedFile = modelData.path;
                            root.saveFileName = modelData.name;
                          }
                        }
                      }
                      onDoubleClicked: {
                        if (modelData.isDir) {
                          root._navigate(modelData.path);
                        } else if (root.mode !== "folder") {
                          root.fileSelected(modelData.path);
                          root.close();
                        }
                      }
                    }
                  }
                }
              }

            }

            SharedWidgets.DankScrollbar { flickable: gridFlick }
            SharedWidgets.DankScrollbar { flickable: listFlick }
          }

          // ── Footer ─────────────────────────────────────────────────────────────
          Rectangle {
            Layout.fillWidth: true
            height: root.mode === "save" ? 96 : 52
            color: Colors.withAlpha(Colors.surface, 0.4)

            // top border
            Rectangle {
              anchors.top: parent.top
              anchors.left: parent.left
              anchors.right: parent.right
              height: 1
              color: Colors.border
            }

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: Colors.spacingM
              spacing: Colors.spacingS

              // Save: filename text field
              Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: Colors.radiusSmall
                visible: root.mode === "save"
                color: Colors.withAlpha(Colors.surface, 0.7)
                border.color: saveField.activeFocus ? Colors.primary : Colors.border
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 120 } }

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: Colors.spacingM
                  anchors.rightMargin: Colors.spacingS
                  spacing: Colors.spacingS

                  Text {
                    text: "󰈙"
                    color: Colors.textDisabled
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeMedium
                  }

                  TextInput {
                    id: saveField
                    Layout.fillWidth: true
                    text: root.saveFileName
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeMedium
                    selectionColor: Colors.withAlpha(Colors.primary, 0.4)
                    clip: true

                    onTextChanged: root.saveFileName = text

                    Keys.onReturnPressed: {
                      if (root.saveFileName.length > 0) {
                        root.fileSelected(root.currentPath + "/" + root.saveFileName);
                        root.close();
                      }
                    }
                  }
                }
              }

              // Bottom row: selected path + filter + action buttons
              RowLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingM

                // Selected file or path display
                Rectangle {
                  Layout.fillWidth: true
                  height: 30
                  radius: Colors.radiusSmall
                  color: Colors.withAlpha(Colors.surface, 0.5)
                  border.color: Colors.border
                  border.width: 1
                  clip: true

                  Text {
                    anchors.fill: parent
                    anchors.leftMargin: Colors.spacingM
                    anchors.rightMargin: Colors.spacingS
                    verticalAlignment: Text.AlignVCenter
                    text: root.mode === "open"
                      ? (root.selectedFile.length > 0 ? root.selectedFile : root.currentPath)
                      : (root.mode === "save" ? (root.saveFileName.length > 0
                          ? root.currentPath + "/" + root.saveFileName
                          : root.currentPath)
                          : (root.selectedFile.length > 0 ? root.selectedFile : root.currentPath))
                    color: root.selectedFile.length > 0 || root.saveFileName.length > 0
                      ? Colors.text : Colors.textDisabled
                    font.pixelSize: Colors.fontSizeSmall
                    elide: Text.ElideLeft
                  }
                }

                // Filter selector (shown only when filters defined)
                Rectangle {
                  visible: root.fileFilters.length > 1
                  height: 30
                  width: filterText.implicitWidth + 28
                  radius: Colors.radiusSmall
                  color: filterHover.containsMouse
                    ? Colors.withAlpha(Colors.text, 0.1) : Colors.withAlpha(Colors.surface, 0.6)
                  border.color: Colors.border
                  border.width: 1
                  Behavior on color { ColorAnimation { duration: 120 } }

                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Colors.spacingS
                    anchors.rightMargin: Colors.spacingS
                    spacing: Colors.spacingXS

                    Text {
                      id: filterText
                      text: root.fileFilters.length > 0
                        ? root.fileFilters[root.activeFilterIndex].label
                        : "All Files"
                      color: Colors.textSecondary
                      font.pixelSize: Colors.fontSizeSmall
                    }
                    Text {
                      text: "󰅀"
                      color: Colors.textDisabled
                      font.family: Colors.fontMono
                      font.pixelSize: Colors.fontSizeSmall
                    }
                  }

                  MouseArea {
                    id: filterHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      root.activeFilterIndex = (root.activeFilterIndex + 1) % root.fileFilters.length;
                      root._listDirectory();
                    }
                  }
                }

                // Cancel button
                Rectangle {
                  Layout.minimumWidth: 96
                  height: 30
                  width: Math.max(Layout.minimumWidth, cancelText.implicitWidth + 24)
                  radius: Colors.radiusSmall
                  color: cancelHover.containsMouse
                    ? Colors.withAlpha(Colors.text, 0.1) : Colors.withAlpha(Colors.surface, 0.6)
                  border.color: Colors.border
                  border.width: 1
                  Behavior on color { ColorAnimation { duration: 120 } }

                  Text {
                    id: cancelText
                    anchors.centerIn: parent
                    text: "Cancel"
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeMedium
                  }

                  MouseArea {
                    id: cancelHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { root.cancelled(); root.close(); }
                  }
                }

                // Open/Save button
                Rectangle {
                  id: actionBtn
                  Layout.minimumWidth: root.mode === "folder" ? 128 : 96
                  height: 30
                  width: Math.max(Layout.minimumWidth, actionText.implicitWidth + 24)
                  radius: Colors.radiusSmall

                  readonly property bool canConfirm: root.mode === "open"
                    ? root.selectedFile.length > 0
                    : (root.mode === "save" ? root.saveFileName.length > 0 : true)

                  color: canConfirm
                    ? (actionHover.containsMouse ? Colors.primary : Colors.withAlpha(Colors.primary, 0.75))
                    : Colors.withAlpha(Colors.surface, 0.6)
                  border.color: canConfirm ? Colors.primary : Colors.border
                  border.width: 1
                  Behavior on color { ColorAnimation { duration: 120 } }

                  Text {
                    id: actionText
                    anchors.centerIn: parent
                    text: root.mode === "open" ? "Open" : (root.mode === "save" ? "Save" : "Select Folder")
                    color: actionBtn.canConfirm ? Colors.text : Colors.textDisabled
                    font.pixelSize: Colors.fontSizeMedium
                    font.weight: Colors.fontWeightMedium
                  }

                  MouseArea {
                    id: actionHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: actionBtn.canConfirm ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                      if (!actionBtn.canConfirm) return;
                      if (root.mode === "open") {
                        root.fileSelected(root.selectedFile);
                      } else if (root.mode === "save") {
                        root.fileSelected(root.currentPath + "/" + root.saveFileName);
                      } else {
                        root.folderSelected(root.selectedFile.length > 0 ? root.selectedFile : root.currentPath);
                      }
                      root.close();
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
