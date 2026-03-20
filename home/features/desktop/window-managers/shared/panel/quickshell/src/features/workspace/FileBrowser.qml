import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../services"
import "../../widgets" as SharedWidgets
import "FileBrowserHelpers.js" as FBH

PanelWindow {
  id: root
  property var screenRef: Quickshell.cursorScreen || Config.primaryScreen()
  screen: screenRef
  readonly property var edgeMargins: Config.reservedEdgesForScreen(screenRef, "")
  readonly property int usableWidth: Math.max(0, width - edgeMargins.left - edgeMargins.right)
  readonly property int usableHeight: Math.max(0, height - edgeMargins.top - edgeMargins.bottom)

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
  property bool _destroyed: false
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
    clearInteractiveFocus();
    isOpen = false;
    _fileEntries = [];
  }

  function toggle() {
    isOpen ? close() : open(currentPath, fileFilters, mode);
  }

  function clearInteractiveFocus() {
    var item = root.activeFocusItem;
    var depth = 0;
    while (item && depth < 24) {
      if (item.focus !== undefined)
        item.focus = false;
      item = item.parent;
      depth++;
    }
  }

  Component.onDestruction: _destroyed = true

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
  readonly property bool _compactActions: mainBox.width < 940
  readonly property bool _showListDetailColumns: mainBox.width >= 1020

  readonly property var _quickLocations: [
    { label: "Home",      icon: "home.svg", path: Quickshell.env("HOME") || "/home" },
    { label: "Desktop",   icon: "desktop.svg", path: (Quickshell.env("HOME") || "/home") + "/Desktop" },
    { label: "Documents", icon: "document.svg", path: (Quickshell.env("HOME") || "/home") + "/Documents" },
    { label: "Downloads", icon: "download.svg", path: (Quickshell.env("HOME") || "/home") + "/Downloads" },
    { label: "Pictures",  icon: "image.svg", path: (Quickshell.env("HOME") || "/home") + "/Pictures" },
    { label: "Videos",    icon: "video.svg", path: (Quickshell.env("HOME") || "/home") + "/Videos" },
    { label: "Music",     icon: "music-note-2.svg", path: (Quickshell.env("HOME") || "/home") + "/Music" }
  ]

  // ── Navigation helpers ───────────────────────────────────────────────────────
  function _listDirectory() {
    if (_loading) return;
    _loading = true;
    _fileEntries = [];
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

  function _handleItemClick(entry) {
    if (entry.isDir) {
      if (mode === "folder") {
        selectedFile = entry.path;
        saveFileName = entry.name;
      } else {
        _navigate(entry.path);
      }
    } else {
      if (mode !== "folder") {
        selectedFile = entry.path;
        saveFileName = entry.name;
      }
    }
  }

  function _handleItemDoubleClick(entry) {
    if (entry.isDir) {
      _navigate(entry.path);
    } else if (mode !== "folder") {
      fileSelected(entry.path);
      close();
    }
  }

  function _handleSortChanged(field, ascending) {
    _sortBy = field;
    _sortAsc = ascending;
    _fileEntries = FBH.sortEntries(_fileEntries, _sortBy, _sortAsc);
  }

  function _handleConfirm() {
    if (mode === "open") {
      fileSelected(selectedFile);
    } else if (mode === "save") {
      fileSelected(currentPath + "/" + saveFileName);
    } else {
      folderSelected(selectedFile.length > 0 ? selectedFile : currentPath);
    }
    close();
  }

  // ── Directory listing process ──────────────────────────────────────────────
  Process {
    id: listProc
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var raw = this.text || "";
        var parsed = FBH.parseStatOutput(raw);
        var filtered = FBH.applyFilters(parsed, root.fileFilters, root.activeFilterIndex);
        var sorted = FBH.sortEntries(filtered, root._sortBy, root._sortAsc);
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

  SharedWidgets.ElasticNumber {
    id: _fbElasticScale
    target: root.isOpen ? 1.0 : 0.95
    fastDuration: Appearance.durationSnap
    slowDuration: Appearance.durationPanelClose
    fastWeight: 0.45
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
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.topMargin: root.edgeMargins.top + Math.max(20, (root.usableHeight - height) / 2)
    anchors.leftMargin: root.edgeMargins.left + Math.max(20, (root.usableWidth - width) / 2)

    color: Colors.popupSurface
    border.color: Colors.border
    border.width: 1
    radius: Appearance.radiusLarge
    clip: true

    focus: root.isOpen
    onVisibleChanged: {
      if (visible) {
        if (root.mode === "save") {
          Qt.callLater(function() {
            if (root._destroyed) return;
            if (root.isOpen && root.mode === "save")
              footer.saveFieldItem.forceActiveFocus();
          });
        } else {
          Qt.callLater(function() {
            if (root._destroyed) return;
            if (root.isOpen && root.mode !== "save")
              focusSink.forceActiveFocus();
          });
        }
      } else {
        root.clearInteractiveFocus();
        if (activeFocus)
          focus = false;
      }
    }
    Keys.onEscapePressed: root.close()

    opacity: root.isOpen ? 1.0 : 0.0
    scale:   _fbElasticScale.value
    Behavior on opacity { NumberAnimation { id: fbFadeAnim;  duration: Appearance.durationMedium; easing.type: Easing.OutCubic } }
    layer.enabled: fbFadeAnim.running || _fbElasticScale.running

    // Block click-through
    MouseArea { anchors.fill: parent }

    Item {
      id: focusSink
      width: 0
      height: 0
      focus: false
    }

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
          anchors.leftMargin: Appearance.paddingLarge
          anchors.rightMargin: Appearance.paddingMedium
          spacing: Appearance.spacingM

          // Title
          Text {
            text: root.title
            color: Colors.text
            font.pixelSize: Appearance.fontSizeLarge
            font.weight: Font.Bold
            font.letterSpacing: Appearance.letterSpacingTight
          }

          Item { Layout.fillWidth: true }

          // View-toggle: grid
          Rectangle {
            width: 30; height: 30; radius: Appearance.radiusSmall
            color: root._viewGrid
              ? Colors.highlight
              : "transparent"
            Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationSnap } }

            SharedWidgets.SvgIcon {
              anchors.centerIn: parent
              source: "sort.svg"
              color: root._viewGrid ? Colors.primary : Colors.textSecondary
              size: Appearance.fontSizeLarge
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
            width: 30; height: 30; radius: Appearance.radiusSmall
            color: !root._viewGrid
              ? Colors.highlight
              : "transparent"
            Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationSnap } }

            SharedWidgets.SvgIcon {
              anchors.centerIn: parent
              source: "sort.svg"
              color: !root._viewGrid ? Colors.primary : Colors.textSecondary
              size: Appearance.fontSizeLarge
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

            SharedWidgets.SvgIcon {
              anchors.centerIn: parent
              source: "dismiss.svg"
              color: Colors.textSecondary
              size: Appearance.fontSizeLarge
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

        // ── Sidebar ─────────────────────────────────────────────────────────
        FileBrowserSidebar {
          currentPath: root.currentPath
          quickLocations: root._quickLocations
          onNavigate: (path) => root._navigate(path)
        }

        // ── Main area ────────────────────────────────────────────────────────
        ColumnLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: 0

          // ── Path bar ───────────────────────────────────────────────────────
          FileBrowserPathBar {
            currentPath: root.currentPath
            onNavigate: (path) => root._navigate(path)
            onNavigateUp: root._navigateUp()
            onRefresh: root._listDirectory()
          }

          // ── Sort controls (list-mode only) ─────────────────────────────────
          FileBrowserSortHeader {
            visible: !root._viewGrid
            sortBy: root._sortBy
            sortAsc: root._sortAsc
            showDetailColumns: root._showListDetailColumns
            onSortChanged: (field, ascending) => root._handleSortChanged(field, ascending)
          }

          // ── File grid / list area ──────────────────────────────────────────
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
                spacing: Appearance.spacingS

                SharedWidgets.SvgIcon {
                  Layout.alignment: Qt.AlignHCenter
                  source: "arrow-clockwise.svg"
                  color: Colors.textDisabled
                  size: Appearance.fontSizeDisplay

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
                  font.pixelSize: Appearance.fontSizeSmall
                }
              }
            }

            // Empty state
            Item {
              anchors.centerIn: parent
              visible: !root._loading && root._fileEntries.length === 0

              SharedWidgets.EmptyState {
                anchors.centerIn: parent
                icon: "folder.svg"
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
                implicitHeight: gridFlow.implicitHeight + Appearance.paddingMedium * 2

                Flow {
                  id: gridFlow
                  anchors.top: parent.top
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.topMargin: Appearance.paddingMedium
                  anchors.leftMargin: Appearance.paddingMedium
                  anchors.rightMargin: Appearance.paddingMedium
                  spacing: Appearance.spacingM
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

                  Repeater {
                    model: root._fileEntries

                    delegate: FileBrowserGridItem {
                      cellWidth: gridFlow.cellW
                      selectedFile: root.selectedFile
                      browseMode: root.mode
                      onItemClicked: (entry) => root._handleItemClick(entry)
                      onItemDoubleClicked: (entry) => root._handleItemDoubleClick(entry)
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

                  delegate: FileBrowserListItem {
                    selectedFile: root.selectedFile
                    browseMode: root.mode
                    showDetailColumns: root._showListDetailColumns
                    onItemClicked: (entry) => root._handleItemClick(entry)
                    onItemDoubleClicked: (entry) => root._handleItemDoubleClick(entry)
                  }
                }
              }
            }

            SharedWidgets.Scrollbar { flickable: gridFlick }
            SharedWidgets.Scrollbar { flickable: listFlick }
          }

          // ── Footer ─────────────────────────────────────────────────────────
          FileBrowserFooter {
            id: footer
            mode: root.mode
            currentPath: root.currentPath
            selectedFile: root.selectedFile
            saveFileName: root.saveFileName
            fileFilters: root.fileFilters
            activeFilterIndex: root.activeFilterIndex
            compactActions: root._compactActions
            isOpen: root.isOpen
            onSaveFileNameEdited: (name) => { root.saveFileName = name; }
            onFilterCycled: {
              root.activeFilterIndex = (root.activeFilterIndex + 1) % root.fileFilters.length;
              root._listDirectory();
            }
            onConfirmAction: root._handleConfirm()
            onCancelAction: { root.cancelled(); root.close(); }
            onSaveConfirmed: (path) => { root.fileSelected(path); root.close(); }
          }
        }
      }
    }
  }
}
