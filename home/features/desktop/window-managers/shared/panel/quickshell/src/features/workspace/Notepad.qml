import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../services"
import "../../widgets" as SharedWidgets
import "../../shared"

PanelWindow {
  id: root

  readonly property var edgeMargins: Config.reservedEdgesForScreen(screen, "")

  anchors {
    top: true
    right: true
    bottom: true
  }
  margins.top: edgeMargins.top
  margins.right: Math.max(edgeMargins.right, Appearance.spacingS)
  margins.bottom: edgeMargins.bottom

  implicitWidth: notepadWidth
  color: "transparent"
  mask: Region {
    item: slidePanel
  }
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  WlrLayershell.namespace: "quickshell"

  // --- State ---
  property bool showContent: false

  // Notepad data
  property int notepadWidth: 500
  readonly property int notepadMinWidth: 360
  readonly property int notepadMaxWidth: 800
  readonly property bool compactHeader: slidePanel.width < 420
  readonly property bool narrowHeader: slidePanel.width < 360
  property var tabs: [{ "id": 1, "title": "Note 1", "content": "" }]
  property int activeTabId: 1
  property int nextTabId: 2
  property string searchQuery: ""
  property bool isSearching: false

  readonly property string savePath: (Quickshell.env("HOME") || "/home") + "/.local/state/quickshell/notepad.json"
  property bool _loading: false

  function saveState() {
    if (_loading) return;
    if (!notepadFile || !notepadFile.path) return;
    var data = {
      tabs: root.tabs,
      activeTabId: root.activeTabId,
      nextTabId: root.nextTabId,
      notepadWidth: root.notepadWidth
    };
    notepadFile.setText(JSON.stringify(data, null, 2));
  }

  property FileView notepadFile: FileView {
    path: root.savePath
    blockLoading: true
    printErrors: false
    onLoaded: root.load()
    onLoadFailed: (error) => {
      if (error === 2) {
        // File doesn't exist yet — write defaults
        root.saveState();
        return;
      }
      Logger.e("Notepad", "failed to load file:", error);
    }
    onSaveFailed: (error) => Logger.e("Notepad", "failed to save file:", error)
  }

  function load() {
    var raw = notepadFile.text();
    if (!raw) return;
    _loading = true;
    try {
      var data = JSON.parse(raw);
      if (data.tabs && Array.isArray(data.tabs) && data.tabs.length > 0) {
        tabs = data.tabs;
        // Compute next id as max existing + 1
        var maxId = 0;
        for (var i = 0; i < tabs.length; i++) {
          if (tabs[i].id > maxId) maxId = tabs[i].id;
        }
        nextTabId = maxId + 1;
      }
      if (data.activeTabId !== undefined) {
        // Validate the id actually exists
        var found = false;
        for (var j = 0; j < tabs.length; j++) {
          if (tabs[j].id === data.activeTabId) { found = true; break; }
        }
        activeTabId = found ? data.activeTabId : tabs[0].id;
      }
      if (data.notepadWidth !== undefined) {
        notepadWidth = Math.max(notepadMinWidth, Math.min(notepadMaxWidth, data.notepadWidth === 400 ? 500 : data.notepadWidth));
      } else if (data.width !== undefined) {
        notepadWidth = Math.max(notepadMinWidth, Math.min(notepadMaxWidth, data.width === 400 ? 500 : data.width));
      }
    } catch (e) {
      Logger.e("Notepad", "failed to parse JSON:", e);
    }
    _loading = false;
    // Trigger UI sync
    notepadText.text = root.activeContent;
  }

  onTabsChanged: saveState()
  onActiveTabIdChanged: {
    if (!_loading) {
        notepadText.text = root.activeContent;
        saveState();
    }
  }
  onNotepadWidthChanged: saveState()

  signal closeRequested()
  signal openFileRequested()
  signal saveAsRequested(string content)

  function clearInteractiveFocus() {
    if (notepadText.activeFocus)
      notepadText.focus = false;
    if (searchInput.activeFocus)
      searchInput.focus = false;
    for (var i = 0; i < tabRepeater.count; i++) {
      var tabItem = tabRepeater.itemAt(i);
      if (tabItem && tabItem.isEditing)
        tabItem.isEditing = false;
    }
    if (slidePanel.activeFocus)
      slidePanel.focus = false;
  }

  // Called by shell.qml when a file is selected from FileBrowser
  function loadFile(filePath) {
    _pendingFilePath = filePath;
    fileReadProc.command = ["cat", filePath];
    fileReadProc.running = true;
  }

  function saveToFile(filePath, content) {
    fileWriteProc.stdinEnabled = true;
    fileWriteProc.command = ["sh", "-c", "cat > \"$1\"", "sh", filePath];
    fileWriteProc.running = true;
    // Write content after process starts
    _pendingWriteContent = content;
    _pendingWritePath = filePath;
  }

  property string _pendingFilePath: ""
  property string _pendingWriteContent: ""
  property string _pendingWritePath: ""

  Process {
    id: fileReadProc
    running: false
    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0 && root._pendingFilePath) {
        var filename = root._pendingFilePath.split("/").pop();
        root.addTab();
        root.renameTab(root.activeTabId, filename);
        root._loading = true;
        notepadText.text = fileReadProc.stdout;
        root._loading = false;
        root.updateTabContent(root.activeTabId, fileReadProc.stdout);
      }
      root._pendingFilePath = "";
    }
  }

  Process {
    id: fileWriteProc
    running: false
    stdinEnabled: true
    onStarted: {
      fileWriteProc.write(root._pendingWriteContent);
      fileWriteProc.stdinEnabled = false;
    }
    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0 && root._pendingWritePath) {
        var filename = root._pendingWritePath.split("/").pop();
        root.renameTab(root.activeTabId, filename);
      }
      root._pendingWriteContent = "";
      root._pendingWritePath = "";
    }
  }

  // Derived helpers
  readonly property int activeTabIndex: {
    for (var i = 0; i < tabs.length; i++) {
      if (tabs[i].id === activeTabId) return i;
    }
    return 0;
  }

  readonly property string activeContent: {
    var idx = activeTabIndex;
    return (idx >= 0 && idx < tabs.length) ? (tabs[idx].content || "") : "";
  }

  // Panel visibility: stay mapped during slide-out animation
  visible: showContent || slidePanel.x < notepadWidth

  // Focus text area when opened
  onShowContentChanged: {
    if (showContent) {
      focusRestoreTimer.restart();
    } else {
      focusRestoreTimer.stop();
      clearInteractiveFocus();
    }
  }

  readonly property int _saveDebounceMs: 500

  // Debounced save timer
  property Timer saveTimer: Timer {
    interval: root._saveDebounceMs
    onTriggered: root.saveState()
  }

  Timer {
    id: focusRestoreTimer
    interval: 180
    repeat: false
    onTriggered: {
      if (root.showContent)
        notepadText.forceActiveFocus();
    }
  }

  function scheduleSave() {
    if (!_loading) saveTimer.restart();
  }

  function defaultTabTitle(index) {
    return "Note " + Math.max(1, index);
  }

  function nextDefaultTabTitle() {
    var used = ({});
    for (var i = 0; i < tabs.length; i++) {
      used[String(tabs[i].title || "").toLowerCase()] = true;
    }
    var counter = 1;
    while (used[defaultTabTitle(counter).toLowerCase()])
      counter += 1;
    return defaultTabTitle(counter);
  }

  // --- Tab Management ---
  function addTab() {
    var newId = nextTabId++;
    var newTabs = tabs.slice();
    newTabs.push({ "id": newId, "title": nextDefaultTabTitle(), "content": "" });
    tabs = newTabs;
    activeTabId = newId;
    scheduleSave();
  }

  function syncProjectTab() {
        if (!Config.notepadProjectSync) return;
        var project = WorkspaceIdentityService.getActiveProject();
        if (!project) return;
        for (var i = 0; i < tabs.length; i++) {
            if (tabs[i].title.toLowerCase() === project.toLowerCase()) {
                activeTabId = tabs[i].id;
                return;
            }
        }
  }

  Connections {
    target: WorkspaceIdentityService
    function onWorkspaceDataChanged() {
        root.syncProjectTab();
    }
  }

  Connections {
    target: NiriService
    function onFocusedWorkspaceIdChanged() {
        root.syncProjectTab();
    }
  }

  function removeTab(tabId) {
    if (tabs.length <= 1) return; // Can't delete last tab
    var updatedTabs = [];
    for (var i = 0; i < tabs.length; i++) {
        if (tabs[i].id !== tabId) updatedTabs.push(tabs[i]);
    }
    // If we deleted the active tab, switch to previous or first
    if (activeTabId === tabId) {
      activeTabId = updatedTabs[0].id;
    }
    tabs = updatedTabs;
    scheduleSave();
  }

  function setActiveTab(tabId) {
    // Save current content before switching
    activeTabId = tabId;
  }

  function updateTabContent(tabId, content) {
    var newTabs = tabs.slice();
    for (var i = 0; i < newTabs.length; i++) {
      if (newTabs[i].id === tabId) {
        newTabs[i] = { "id": newTabs[i].id, "title": newTabs[i].title, "content": content };
        break;
      }
    }
    tabs = newTabs;
    scheduleSave();
  }

  function renameTab(tabId, newTitle) {
    var trimmed = newTitle.trim();
    if (!trimmed) return;
    var newTabs = tabs.slice();
    for (var i = 0; i < newTabs.length; i++) {
      if (newTabs[i].id === tabId) {
        newTabs[i] = { "id": newTabs[i].id, "title": trimmed, "content": newTabs[i].content };
        break;
      }
    }
    tabs = newTabs;
    scheduleSave();
  }

  // --- IPC ---
  IpcHandler {
    target: "Notepad"
    function toggle() { root.showContent ? root.closeRequested() : (root.showContent = true); }
    function open()  { root.showContent = true; }
    function close() { root.closeRequested(); }
  }

  // --- Drag-resize state ---
  property real _dragStartX: 0
  property real _dragStartWidth: 0

  // =========================================================
  //  Main panel rectangle — slides in from right
  // =========================================================
  Rectangle {
    id: slidePanel
    width: root.notepadWidth
    height: parent.height
    color: Colors.popupSurface
    border.color: Colors.border
    border.width: 1
    radius: Appearance.radiusLarge

    gradient: SharedWidgets.SurfaceGradient {}

    // Inner highlight
    SharedWidgets.InnerHighlight { highlightOpacity: 0.15 }

    x: root.showContent ? 0 : root.notepadWidth + 10
    opacity: root.showContent ? 1.0 : 0.0

    Behavior on x {
      NumberAnimation {
        id: npSlideAnim
        duration: Appearance.durationPanelOpen
        easing.type: Easing.OutBack
        easing.overshoot: 0.6
      }
    }
    Behavior on opacity {
      NumberAnimation { id: npFadeAnim; duration: Appearance.durationPanelClose }
    }
    layer.enabled: npSlideAnim.running || npFadeAnim.running

    Keys.onEscapePressed: root.closeRequested()
    Keys.onPressed: event => {
      if (!root.showContent)
        return;
      if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_N) {
        root.addTab();
        event.accepted = true;
      }
    }

    // ----------------------------------------------------------
    //  Left-edge drag handle for resizing
    // ----------------------------------------------------------
    Rectangle {
      id: dragHandle
      width: 6
      height: parent.height * 0.15
      radius: Appearance.radiusXS
      color: dragArea.containsMouse ? Colors.primary : Colors.border
      anchors.left: parent.left
      anchors.leftMargin: -3
      anchors.verticalCenter: parent.verticalCenter
      opacity: dragArea.containsMouse || dragArea.pressed ? 1.0 : 0.4
      Behavior on opacity { NumberAnimation { duration: Appearance.durationFast } }
      Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }

      MouseArea {
        id: dragArea
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.SizeHorCursor
        onPressed: (mouse) => {
          root._dragStartX = mapToGlobal(mouse.x, mouse.y).x;
          root._dragStartWidth = root.notepadWidth;
        }
        onPositionChanged: (mouse) => {
          if (!pressed) return;
          var globalX = mapToGlobal(mouse.x, mouse.y).x;
          var delta = root._dragStartX - globalX;
          var newW = Math.max(root.notepadMinWidth, Math.min(root.notepadMaxWidth, root._dragStartWidth + delta));
          root.notepadWidth = Math.round(newW);
          root.scheduleSave();
        }
      }
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Appearance.paddingLarge
      spacing: Appearance.spacingM

      // ---- Header ----
      RowLayout {
        Layout.fillWidth: true
        spacing: root.narrowHeader ? Appearance.spacingXS : Appearance.spacingS

        SharedWidgets.SvgIcon {
          source: "edit.svg"
          color: Colors.text
          size: root.narrowHeader ? Appearance.fontSizeLarge : Appearance.fontSizeXL
          Layout.alignment: Qt.AlignVCenter
        }
        Text {
          Layout.fillWidth: true
          Layout.minimumWidth: 0
          text: "Notepad"
          color: Colors.text
          font.pixelSize: root.narrowHeader ? Appearance.fontSizeLarge : Appearance.fontSizeXL
          font.weight: Font.DemiBold
          font.letterSpacing: Appearance.letterSpacingTight
          elide: Text.ElideRight
          maximumLineCount: 1
          Layout.alignment: Qt.AlignVCenter
        }

        Item {
          Layout.fillWidth: true
          visible: !root.narrowHeader
        }

        // Search bar
        Rectangle {
          visible: root.isSearching
          width: root.compactHeader ? 112 : 140
          height: 28
          radius: Appearance.radiusMedium
          color: Colors.cardSurface
          border.color: searchInput.activeFocus ? Colors.primary : Colors.border
          border.width: 1
          Layout.alignment: Qt.AlignVCenter
          
          TextInput {
            id: searchInput
            anchors.fill: parent; anchors.leftMargin: Appearance.paddingSmall; anchors.rightMargin: Appearance.paddingSmall
            verticalAlignment: Text.AlignVCenter
            color: Colors.text; font.pixelSize: Appearance.fontSizeSmall
            text: root.searchQuery
            onTextChanged: root.searchQuery = text
            onVisibleChanged: {
              if (visible) forceActiveFocus();
              else if (activeFocus) focus = false;
            }
          }
        }

        // Search toggle
        SharedWidgets.IconButton {
          size: 28; radius: Appearance.radiusXS
          icon: "search-visual.svg"
          iconColor: root.isSearching ? Colors.primary : Colors.textDisabled
          tooltipText: root.isSearching ? "Hide search" : "Search"
          Layout.alignment: Qt.AlignVCenter
          onClicked: {
            root.isSearching = !root.isSearching;
            if (!root.isSearching) root.searchQuery = "";
          }
        }

        // Word / char counts
        Item {
          visible: !root.narrowHeader
          Layout.alignment: Qt.AlignVCenter
          Layout.preferredHeight: 28
          Layout.rightMargin: Appearance.spacingXS
          implicitWidth: countText.implicitWidth

          Text {
            id: countText
            anchors.verticalCenter: parent.verticalCenter
            text: {
              var c = root.activeContent;
              var words = c.trim().length === 0 ? 0 : c.trim().split(/\s+/).length;
              return words + "w  " + c.length + "c";
            }
            color: Colors.textDisabled
            font.pixelSize: Appearance.fontSizeXS
            verticalAlignment: Text.AlignVCenter
          }
        }

        // Open file button
        SharedWidgets.IconButton {
          size: 28; radius: Appearance.radiusXS
          icon: "folder-open.svg"
          tooltipText: "Open file"
          Layout.alignment: Qt.AlignVCenter
          onClicked: root.openFileRequested()
        }

        // Save As button
        SharedWidgets.IconButton {
          size: 28; radius: Appearance.radiusXS
          icon: "save.svg"
          tooltipText: "Save as"
          Layout.alignment: Qt.AlignVCenter
          onClicked: root.saveAsRequested(root.activeContent)
        }

        // Close button
        SharedWidgets.IconButton {
          size: 28; radius: Appearance.radiusMedium
          icon: "dismiss.svg"
          tooltipText: "Close"
          Layout.alignment: Qt.AlignVCenter
          onClicked: root.closeRequested()
        }
      }

      // ---- Tab bar ----
      RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacingS

        // Scrollable tab strip
        Item {
          Layout.fillWidth: true
          height: Appearance.controlRowHeight
          clip: true

          Flickable {
            id: tabFlickable
            anchors.fill: parent
            contentWidth: tabRow.implicitWidth
            contentHeight: height
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            Row {
              id: tabRow
              spacing: Appearance.spacingXS
              height: parent.height

              Repeater {
                id: tabRepeater
                model: root.tabs

                delegate: Item {
                  id: tabDelegate
                  required property var modelData
                  required property int index
                  property bool isActive: modelData.id === root.activeTabId
                  property bool isEditing: false
                  readonly property bool hasSearchMatch: root.searchQuery !== "" && 
                    (modelData.title.toLowerCase().indexOf(root.searchQuery.toLowerCase()) !== -1 || 
                     modelData.content.toLowerCase().indexOf(root.searchQuery.toLowerCase()) !== -1)

                  width: isEditing
                    ? Math.min(tabEditInput.contentWidth + 26, 164)
                    : Math.min(tabLabelText.implicitWidth + 54, 164)
                  height: 32

                  Behavior on width { Anim { duration: Appearance.durationFast } }

                  Rectangle {
                    id: tabBg
                    anchors.fill: parent
                    radius: Appearance.radiusSmall
                    color: isActive
                      ? Colors.highlightLight
                      : (tabMouse.containsMouse ? Colors.withAlpha(Colors.text, 0.05)
                        : (hasSearchMatch ? Colors.withAlpha(Colors.accent, 0.12) : "transparent"))
                    border.color: isActive
                      ? Colors.primary
                      : (tabMouse.containsMouse ? Colors.withAlpha(Colors.text, 0.25)
                        : (hasSearchMatch ? Colors.accent : Colors.border))
                    border.width: (isActive || hasSearchMatch) ? 1.5 : 1
                    Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }
                    Behavior on border.color { enabled: !Colors.isTransitioning; CAnim {} }

                    SharedWidgets.StateLayer {
                      id: tabStateLayer
                      hovered: tabMouse.containsMouse
                      pressed: tabMouse.pressed
                    }
                  }

                  Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 1.5
                    width: isActive ? parent.width - 20 : 0
                    height: 2
                    radius: Appearance.radiusXXXS
                    color: Colors.primary
                    opacity: isActive ? 1 : 0
                    visible: width > 0

                    Behavior on width {
                      NumberAnimation { duration: Appearance.durationNormal; easing.type: Easing.OutBack }
                    }
                    Behavior on opacity {
                      NumberAnimation { duration: Appearance.durationFast }
                    }
                  }

                  // Tab label (shown when not editing)
                  Text {
                    id: tabLabelText
                    anchors.left: parent.left
                    anchors.leftMargin: Appearance.spacingS
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: deleteTabBtn.left
                    anchors.rightMargin: 8
                    text: modelData.title
                    color: isActive ? Colors.primary : (tabMouse.containsMouse ? Colors.text : Colors.textSecondary)
                    font.pixelSize: Appearance.fontSizeSmall
                    font.weight: isActive ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight
                    visible: !tabDelegate.isEditing
                  }

                  // Inline title edit input
                  TextInput {
                    id: tabEditInput
                    anchors.left: parent.left
                    anchors.leftMargin: Appearance.spacingS
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(60, contentWidth + 4)
                    text: modelData.title
                    color: Colors.primary
                    font.pixelSize: Appearance.fontSizeSmall
                    font.weight: Font.DemiBold
                    visible: tabDelegate.isEditing
                    selectByMouse: true
                    onVisibleChanged: {
                      if (visible) {
                        selectAll();
                        forceActiveFocus();
                      } else if (activeFocus) {
                        focus = false;
                      }
                    }
                    Keys.onReturnPressed: {
                      root.renameTab(modelData.id, text);
                      tabDelegate.isEditing = false;
                    }
                    Keys.onEscapePressed: {
                      tabDelegate.isEditing = false;
                    }
                    onEditingFinished: {
                      root.renameTab(modelData.id, text);
                      tabDelegate.isEditing = false;
                    }
                  }

                  // Delete tab button (visible on hover when more than 1 tab)
                  Rectangle {
                    id: deleteTabBtn
                    width: 16
                    height: 16
                    radius: width / 2
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    color: "transparent"
                    opacity: (tabMouse.containsMouse || tabDelegate.isActive) && root.tabs.length > 1 ? 1 : 0
                    visible: opacity > 0 && root.tabs.length > 1
                    Behavior on opacity { NumberAnimation { duration: Appearance.durationFast } }

                    SharedWidgets.StateLayer {
                      id: deleteTabStateLayer
                      hovered: deleteTabMouse.containsMouse
                      pressed: deleteTabMouse.pressed
                      stateColor: Colors.error
                    }

                    SharedWidgets.SvgIcon {
                      anchors.centerIn: parent
                      source: "dismiss.svg"
                      color: deleteTabMouse.containsMouse ? "white" : Colors.textDisabled
                      size: Appearance.fontSizeXS
                    }
                    MouseArea {
                      id: deleteTabMouse
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: (mouse) => {
                        deleteTabStateLayer.burst(mouse.x, mouse.y);
                        mouse.accepted = true;
                        root.removeTab(modelData.id);
                      }
                    }
                  }

                  MouseArea {
                    id: tabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: (mouse) => {
                      tabStateLayer.burst(mouse.x, mouse.y);
                      if (mouse.button === Qt.RightButton) {
                        tabDelegate.isEditing = true;
                        return;
                      }
                      if (!tabDelegate.isEditing) root.setActiveTab(modelData.id);
                    }
                    onDoubleClicked: tabDelegate.isEditing = true
                  }
                }
              }
            }
          }
        }

        // "+" add tab button
        Rectangle {
          width: 32
          height: 32
          radius: Appearance.radiusSmall
          color: addTabMouse.containsMouse ? Colors.primaryGhost : Colors.bgWidget
          border.color: addTabMouse.containsMouse ? Colors.primary : Colors.border
          border.width: 1

          Text {
            anchors.centerIn: parent
            text: "+"
            color: addTabMouse.containsMouse ? Colors.primary : Colors.textSecondary
            font.pixelSize: Appearance.fontSizeLarge
            font.weight: Font.Light
          }
          SharedWidgets.StateLayer {
            id: addTabStateLayer
            hovered: addTabMouse.containsMouse
            pressed: addTabMouse.pressed
          }
          MouseArea {
            id: addTabMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => {
              addTabStateLayer.burst(mouse.x, mouse.y);
              root.addTab();
            }
          }
        }
      }

      // ---- Text editing area ----
      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Colors.cardSurface
        border.color: notepadText.activeFocus ? Colors.primary : Colors.border
        border.width: notepadText.activeFocus ? 1.5 : 1
        radius: Appearance.radiusMedium
        Behavior on border.color { enabled: !Colors.isTransitioning; CAnim {} }
        clip: true

        Flickable {
          id: textFlickable
          anchors.fill: parent
          anchors.margins: 1
          contentWidth: width
          contentHeight: Math.max(height, notepadText.contentHeight + 24)
          flickableDirection: Flickable.VerticalFlick
          boundsBehavior: Flickable.StopAtBounds
          clip: true

          ScrollBar.vertical: ScrollBar {
            policy: textFlickable.contentHeight > textFlickable.height
              ? ScrollBar.AlwaysOn
              : ScrollBar.AlwaysOff
          }

          TextEdit {
            id: notepadText
            width: textFlickable.width - (textFlickable.contentHeight > textFlickable.height ? 12 : 0)
            leftPadding: 14
            rightPadding: 14
            topPadding: 12
            bottomPadding: 12
            text: root.activeContent
            color: Colors.text
            font.pixelSize: Appearance.fontSizeMedium
            font.family: Appearance.fontMono
            wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
            selectByMouse: true
            selectedTextColor: Colors.background
            selectionColor: Colors.primary

            // Placeholder
            Text {
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.leftMargin: 14
              anchors.topMargin: Appearance.spacingM
              text: "Start typing..."
              color: Colors.textDisabled
              font.pixelSize: Appearance.fontSizeMedium
              font.family: Appearance.fontMono
              visible: notepadText.text.length === 0 && !notepadText.activeFocus
            }

            // Keep Flickable scrolled to cursor position
            onCursorRectangleChanged: {
              var cursorY = cursorRectangle.y + cursorRectangle.height;
              var cursorTop = cursorRectangle.y;
              if (cursorY > textFlickable.contentY + textFlickable.height) {
                textFlickable.contentY = cursorY - textFlickable.height + 20;
              } else if (cursorTop < textFlickable.contentY) {
                textFlickable.contentY = Math.max(0, cursorTop - 10);
              }
            }

            // Sync text back to tab data on change
            onTextChanged: {
              if (!root._loading) {
                root.updateTabContent(root.activeTabId, text);
              }
            }
          }
        }
      }

      // ---- Footer: status bar ----
      RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacingS

        Text {
          text: {
            var c = root.activeContent;
            var words = c.trim().length === 0 ? 0 : c.trim().split(/\s+/).length;
            var lines = c.length === 0 ? 1 : c.split("\n").length;
            return lines + " lines  ·  " + words + " words  ·  " + c.length + " chars";
          }
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeXS
        }

        Item { Layout.fillWidth: true }

        Text {
          text: root.tabs.length + " tab" + (root.tabs.length !== 1 ? "s" : "")
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeXS
        }
      }
    }
  }
}
