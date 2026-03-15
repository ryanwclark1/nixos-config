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

  readonly property var edgeMargins: Config.reservedEdgesForScreen(screen, "")

  anchors {
    top: true
    right: true
    bottom: true
  }
  margins.top: edgeMargins.top
  margins.right: edgeMargins.right
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
  property int notepadWidth: 400
  readonly property int notepadMinWidth: 300
  readonly property int notepadMaxWidth: 600
  property var tabs: [{ "id": 1, "title": "Notes", "content": "" }]
  property int activeTabId: 1
  property int nextTabId: 2

  signal closeRequested()
  signal openFileRequested()
  signal saveAsRequested(string content)

  // Called by shell.qml when a file is selected from FileBrowser
  function loadFile(filePath) {
    _pendingFilePath = filePath;
    fileReadProc.command = ["cat", filePath];
    fileReadProc.running = true;
  }

  function saveToFile(filePath, content) {
    fileWriteProc.stdinEnabled = true;
    fileWriteProc.command = ["sh", "-c", "cat > '" + filePath.replace(/'/g, "'\\''") + "'"];
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
      notepadText.forceActiveFocus();
    } else if (notepadText.activeFocus) {
      notepadText.focus = false;
    }
  }

  // --- Persistence ---
  readonly property string savePath: Quickshell.env("HOME") + "/.local/state/quickshell/notepad.json"

  property bool _loading: false

  property FileView notepadFile: FileView {
    path: root.savePath
    blockLoading: true
    printErrors: false
    onLoaded: root.load()
    onLoadFailed: (error) => {
      if (error === 2) {
        // File doesn't exist yet — write defaults
        root.save();
        return;
      }
      console.error("Notepad: failed to load file: " + error);
    }
    onSaveFailed: (error) => console.error("Notepad: failed to save file: " + error)
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
      if (data.width !== undefined) {
        notepadWidth = Math.max(notepadMinWidth, Math.min(notepadMaxWidth, data.width));
      }
    } catch (e) {
      console.error("Notepad: failed to parse JSON: " + e);
    }
    _loading = false;
  }

  // Debounced save timer
  property Timer saveTimer: Timer {
    interval: 500
    onTriggered: root.save()
  }

  function scheduleSave() {
    if (!_loading) saveTimer.restart();
  }

  function save() {
    var data = {
      "tabs": tabs,
      "activeTabId": activeTabId,
      "width": notepadWidth
    };
    notepadFile.setText(JSON.stringify(data, null, 2));
  }

  // --- Tab Management ---
  function addTab() {
    var newId = nextTabId++;
    var newTabs = tabs.slice();
    newTabs.push({ "id": newId, "title": "Tab " + newId, "content": "" });
    tabs = newTabs;
    activeTabId = newId;
    scheduleSave();
  }

  function removeTab(tabId) {
    if (tabs.length <= 1) return; // Can't delete last tab
    var newTabs = [];
    for (var i = 0; i < tabs.length; i++) {
      if (tabs[i].id !== tabId) newTabs.push(tabs[i]);
    }
    // If we deleted the active tab, switch to previous or first
    if (activeTabId === tabId) {
      activeTabId = newTabs[0].id;
    }
    tabs = newTabs;
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

  // Keyboard shortcuts
  Shortcut {
    sequence: "Escape"
    enabled: root.showContent
    onActivated: root.closeRequested()
  }

  Shortcut {
    sequence: "Ctrl+N"
    enabled: root.showContent
    onActivated: root.addTab()
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
    color: Colors.bgGlass
    border.color: Colors.border
    border.width: 1
    radius: Colors.radiusLarge

    x: root.showContent ? 0 : root.notepadWidth + 10
    opacity: root.showContent ? 1.0 : 0.0

    Behavior on x {
      NumberAnimation {
        id: npSlideAnim
        duration: 320
        easing.type: Easing.OutBack
        easing.overshoot: 0.6
      }
    }
    Behavior on opacity {
      NumberAnimation { id: npFadeAnim; duration: 260 }
    }
    layer.enabled: npSlideAnim.running || npFadeAnim.running

    Keys.onEscapePressed: root.closeRequested()

    // ----------------------------------------------------------
    //  Left-edge drag handle for resizing
    // ----------------------------------------------------------
    Rectangle {
      id: dragHandle
      width: 6
      height: parent.height * 0.15
      radius: 3
      color: dragArea.containsMouse ? Colors.primary : Colors.border
      anchors.left: parent.left
      anchors.leftMargin: -3
      anchors.verticalCenter: parent.verticalCenter
      opacity: dragArea.containsMouse || dragArea.pressed ? 1.0 : 0.4
      Behavior on opacity { NumberAnimation { duration: Colors.durationFast } }
      Behavior on color { ColorAnimation { duration: Colors.durationFast } }

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
      anchors.margins: Colors.paddingLarge
      spacing: Colors.spacingM

      // ---- Header ----
      RowLayout {
        Layout.fillWidth: true

        Text {
          text: "󰠮  Notepad"
          color: Colors.text
          font.pixelSize: Colors.fontSizeXL
          font.weight: Font.DemiBold
          font.letterSpacing: Colors.letterSpacingTight
        }

        Item { Layout.fillWidth: true }

        // Word / char counts
        Text {
          text: {
            var c = root.activeContent;
            var words = c.trim().length === 0 ? 0 : c.trim().split(/\s+/).length;
            return words + "w  " + c.length + "c";
          }
          color: Colors.textDisabled
          font.pixelSize: Colors.fontSizeXS
          Layout.alignment: Qt.AlignVCenter
          Layout.rightMargin: Colors.spacingXS
        }

        // Open file button
        SharedWidgets.IconButton {
          size: 28; radius: Colors.radiusXS
          icon: "󰏗"
          onClicked: root.openFileRequested()
        }

        // Save As button
        SharedWidgets.IconButton {
          size: 28; radius: Colors.radiusXS
          icon: "󰆓"
          onClicked: root.saveAsRequested(root.activeContent)
        }

        // Close button
        SharedWidgets.IconButton {
          size: 28; radius: Colors.radiusMedium
          icon: "󰅖"
          onClicked: root.closeRequested()
        }
      }

      // ---- Tab bar ----
      RowLayout {
        Layout.fillWidth: true
        spacing: Colors.spacingSM

        // Scrollable tab strip
        Item {
          Layout.fillWidth: true
          height: 32
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
              spacing: Colors.spacingXS
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

                  width: isEditing ? tabEditInput.width + 16 : Math.min(tabLabelText.contentWidth + 36, 140)
                  height: 28

                  Behavior on width { NumberAnimation { duration: Colors.durationFast; easing.type: Easing.OutCubic } }

                  Rectangle {
                    id: tabBg
                    anchors.fill: parent
                    radius: Colors.radiusXXS
                    color: isActive
                      ? Colors.withAlpha(Colors.primary, 0.18)
                      : Colors.bgWidget
                    border.color: isActive ? Colors.primary : Colors.border
                    border.width: isActive ? 1.5 : 1
                    Behavior on color { ColorAnimation { duration: Colors.durationFast } }

                    SharedWidgets.StateLayer {
                      id: tabStateLayer
                      hovered: tabMouse.containsMouse
                      pressed: tabMouse.pressed
                    }
                  }

                  // Tab label (shown when not editing)
                  Text {
                    id: tabLabelText
                    anchors.left: parent.left
                    anchors.leftMargin: Colors.spacingS
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: deleteTabBtn.left
                    anchors.rightMargin: Colors.spacingXS
                    text: modelData.title
                    color: isActive ? Colors.primary : Colors.textSecondary
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: isActive ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight
                    visible: !tabDelegate.isEditing
                  }

                  // Inline title edit input
                  TextInput {
                    id: tabEditInput
                    anchors.left: parent.left
                    anchors.leftMargin: Colors.spacingS
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(60, contentWidth + 4)
                    text: modelData.title
                    color: Colors.primary
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Font.DemiBold
                    visible: tabDelegate.isEditing
                    selectByMouse: true
                    onVisibleChanged: if (visible) { selectAll(); forceActiveFocus(); }
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
                    width: 14; height: 14; radius: width / 2
                    anchors.right: parent.right
                    anchors.rightMargin: 5
                    anchors.verticalCenter: parent.verticalCenter
                    color: "transparent"
                    opacity: (tabMouse.containsMouse || tabDelegate.isActive) && root.tabs.length > 1 ? 1 : 0
                    visible: root.tabs.length > 1
                    Behavior on opacity { NumberAnimation { duration: Colors.durationFast } }

                    SharedWidgets.StateLayer {
                      id: deleteTabStateLayer
                      hovered: deleteTabMouse.containsMouse
                      pressed: deleteTabMouse.pressed
                      stateColor: Colors.error
                    }

                    Text {
                      anchors.centerIn: parent
                      text: "󰅖"
                      color: deleteTabMouse.containsMouse ? "white" : Colors.textDisabled
                      font.family: Colors.fontMono
                      font.pixelSize: Colors.fontSizeXS
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
          width: 28; height: 28; radius: Colors.radiusXS
          color: Colors.bgWidget
          border.color: Colors.border; border.width: 1

          Text {
            anchors.centerIn: parent
            text: "+"
            color: Colors.textSecondary
            font.pixelSize: Colors.fontSizeLarge
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
        color: Colors.bgWidget
        border.color: notepadText.activeFocus ? Colors.primary : Colors.border
        border.width: notepadText.activeFocus ? 1.5 : 1
        radius: Colors.radiusMedium
        Behavior on border.color { ColorAnimation { duration: Colors.durationFast } }
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
            font.pixelSize: Colors.fontSizeMedium
            font.family: Colors.fontMono
            wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
            selectByMouse: true
            selectedTextColor: Colors.background
            selectionColor: Colors.primary

            // Placeholder
            Text {
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.leftMargin: 14
              anchors.topMargin: Colors.spacingM
              text: "Start typing..."
              color: Colors.textDisabled
              font.pixelSize: Colors.fontSizeMedium
              font.family: Colors.fontMono
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
        spacing: Colors.spacingS

        Text {
          text: {
            var c = root.activeContent;
            var words = c.trim().length === 0 ? 0 : c.trim().split(/\s+/).length;
            var lines = c.length === 0 ? 1 : c.split("\n").length;
            return lines + " lines  ·  " + words + " words  ·  " + c.length + " chars";
          }
          color: Colors.textDisabled
          font.pixelSize: Colors.fontSizeXS
        }

        Item { Layout.fillWidth: true }

        Text {
          text: root.tabs.length + " tab" + (root.tabs.length !== 1 ? "s" : "")
          color: Colors.textDisabled
          font.pixelSize: Colors.fontSizeXS
        }
      }
    }
  }

  // When active tab changes, push updated text into TextEdit
  onActiveTabIdChanged: {
    _loading = true;
    notepadText.text = root.activeContent;
    _loading = false;
    notepadText.forceActiveFocus();
  }
}
