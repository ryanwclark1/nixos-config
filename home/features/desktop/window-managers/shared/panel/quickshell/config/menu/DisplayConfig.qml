import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"
import "../widgets" as SharedWidgets

PanelWindow {
  id: displayRoot
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
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  WlrLayershell.namespace: "quickshell"

  // ── Public API ────────────────────────────────────────────────────
  property bool isOpen: false

  function open() {
    if (!CompositorAdapter.supportsDisplayConfig) {
      CompositorAdapter.notifyUnsupported("Display configuration");
      return;
    }
    isOpen = true;
    _loadMonitors();
  }

  function close() {
    if (countdownActive) _revertConfig();
    _cancelCountdown();
    isOpen = false;
  }

  function toggle() {
    isOpen ? close() : open();
  }

  IpcHandler {
    target: "DisplayConfig"
    function toggle() { displayRoot.toggle(); }
    function open()   { displayRoot.open(); }
    function close()  { displayRoot.close(); }
  }

  // ── Monitor data ──────────────────────────────────────────────────
  property var monitors: []          // Array of monitor objects (mutable working copy)
  property var backupMonitors: []    // Snapshot taken before Apply
  property int selectedIndex: -1
  property bool loading: false

  // Canvas viewport / auto-fit
  readonly property real canvasW: 700
  readonly property real canvasH: 260

  // Recomputed whenever monitors changes
  property real scaleFactor: 1.0
  property real canvasOffsetX: 0
  property real canvasOffsetY: 0

  function _computeScaleFactor() {
    if (monitors.length === 0) { scaleFactor = 1.0; return; }
    var minX = 0, minY = 0, maxX = 0, maxY = 0;
    for (var i = 0; i < monitors.length; i++) {
      var m = monitors[i];
      if (m.x < minX) minX = m.x;
      if (m.y < minY) minY = m.y;
      if (m.x + m.width  > maxX) maxX = m.x + m.width;
      if (m.y + m.height > maxY) maxY = m.y + m.height;
    }
    var totalW = maxX - minX;
    var totalH = maxY - minY;
    if (totalW === 0 || totalH === 0) { scaleFactor = 1.0; return; }

    var padding = 40;
    var fitW = (canvasW - padding * 2) / totalW;
    var fitH = (canvasH - padding * 2) / totalH;
    scaleFactor = Math.min(fitW, fitH, 0.35);   // cap at 0.35 so rects aren't too big
    scaleFactor = Math.max(scaleFactor, 0.05);

    // Centre the arrangement in the canvas
    canvasOffsetX = (canvasW - totalW * scaleFactor) / 2 - minX * scaleFactor;
    canvasOffsetY = (canvasH - totalH * scaleFactor) / 2 - minY * scaleFactor;
  }

  // ── Monitor loading ───────────────────────────────────────────────
  function _loadMonitors() {
    loading = true;
    monitors = [];
    selectedIndex = -1;
    monitorLoadProc.running = true;
  }

  Process {
    id: monitorLoadProc
    command: CompositorAdapter.monitorListCommand()
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        displayRoot.loading = false;
        try {
          var raw = JSON.parse(this.text || "[]");
          var result = [];
          for (var i = 0; i < raw.length; i++) {
            var r = raw[i];
            // availableModes may be an array of strings like "2560x1440@165.00Hz"
            // or objects — handle both gracefully
            var modes = [];
            if (r.availableModes && Array.isArray(r.availableModes)) {
              for (var j = 0; j < r.availableModes.length; j++) {
                var m = r.availableModes[j];
                if (typeof m === "string") modes.push(m);
                else if (m && m.width && m.height && m.refreshRate)
                  modes.push(m.width + "x" + m.height + "@" + m.refreshRate.toFixed(2) + "Hz");
              }
            }
            // Always include the current mode if it's not already present
            var curMode = r.width + "x" + r.height + "@" + (r.refreshRate ? r.refreshRate.toFixed(2) : "60.00") + "Hz";
            if (modes.indexOf(curMode) === -1) modes.unshift(curMode);

            result.push({
              id: r.id,
              name: r.name || ("Monitor " + i),
              description: r.description || "",
              width: r.width || 1920,
              height: r.height || 1080,
              refreshRate: r.refreshRate || 60.0,
              x: r.x || 0,
              y: r.y || 0,
              scale: r.scale || 1.0,
              availableModes: modes,
              // Drag state (canvas pixels)
              dragX: 0,
              dragY: 0
            });
          }
          displayRoot.monitors = result;
          displayRoot._syncDragPositions();
          displayRoot._computeScaleFactor();
          if (result.length > 0) displayRoot.selectedIndex = 0;
        } catch (e) {
          console.error("DisplayConfig: failed to parse monitors: " + e);
        }
      }
    }
  }

  // Synchronise dragX/dragY from the monitor's real x/y (called after load or scale change)
  function _syncDragPositions() {
    for (var i = 0; i < monitors.length; i++) {
      var copy = _cloneMonitor(monitors[i]);
      copy.dragX = copy.x * scaleFactor + canvasOffsetX;
      copy.dragY = copy.y * scaleFactor + canvasOffsetY;
      monitors[i] = copy;
    }
    monitorsChanged();
  }

  function _cloneMonitor(m) {
    return {
      id: m.id, name: m.name, description: m.description,
      width: m.width, height: m.height, refreshRate: m.refreshRate,
      x: m.x, y: m.y, scale: m.scale,
      availableModes: m.availableModes,
      dragX: m.dragX, dragY: m.dragY
    };
  }

  // Update the logical x/y from drag position
  function _updateMonitorDrag(index, newDragX, newDragY) {
    var copy = _cloneMonitor(monitors[index]);
    copy.dragX = newDragX;
    copy.dragY = newDragY;
    copy.x = Math.round((newDragX - canvasOffsetX) / scaleFactor);
    copy.y = Math.round((newDragY - canvasOffsetY) / scaleFactor);
    monitors[index] = copy;
    monitorsChanged();
  }

  // Update a setting for a given monitor index
  function _updateMonitorSetting(index, key, value) {
    var copy = _cloneMonitor(monitors[index]);
    copy[key] = value;
    monitors[index] = copy;
    monitorsChanged();
  }

  // ── Apply / revert ────────────────────────────────────────────────
  property bool applyInProgress: false

  function _applyConfig() {
    if (monitors.length === 0) return;

    // Save backup (deep copy)
    var bk = [];
    for (var i = 0; i < monitors.length; i++) bk.push(_cloneMonitor(monitors[i]));
    backupMonitors = bk;

    // Build and run monitor update commands sequentially via a simple JS array queue
    applyInProgress = true;
    _applyQueue = _buildApplyCmds(monitors);
    _runNextApplyCmd();
  }

  property var _applyQueue: []

  function _buildApplyCmds(mons) {
    var cmds = [];
    for (var i = 0; i < mons.length; i++) {
      var m = mons[i];
      var rateStr = m.refreshRate.toFixed(2);
      var posStr  = m.x + "x" + m.y;
      var dimStr  = m.width + "x" + m.height + "@" + rateStr;
      var scaleStr = m.scale.toFixed(2);
      cmds.push(CompositorAdapter.monitorKeywordCommand(
        m.name + "," + dimStr + "," + posStr + "," + scaleStr
      ));
    }
    return cmds;
  }

  function _buildRevertCmds(mons) {
    return _buildApplyCmds(mons);
  }

  function _runNextApplyCmd() {
    if (_applyQueue.length === 0) {
      applyInProgress = false;
      _startCountdown();
      return;
    }
    var cmd = _applyQueue.shift();
    applyExecutor.command = cmd;
    applyExecutor.running = true;
  }

  Process {
    id: applyExecutor
    running: false
    stdout: StdioCollector { onStreamFinished: {} }
    onRunningChanged: {
      if (!running) displayRoot._runNextApplyCmd();
    }
  }

  // Revert queue
  property var _revertQueue: []

  function _revertConfig() {
    if (backupMonitors.length === 0) return;
    _cancelCountdown();
    _revertQueue = _buildRevertCmds(backupMonitors);
    _runNextRevertCmd();
  }

  function _runNextRevertCmd() {
    if (_revertQueue.length === 0) return;
    var cmd = _revertQueue.shift();
    revertExecutor.command = cmd;
    revertExecutor.running = true;
  }

  Process {
    id: revertExecutor
    running: false
    stdout: StdioCollector { onStreamFinished: {} }
    onRunningChanged: {
      if (!running && displayRoot._revertQueue.length > 0) displayRoot._runNextRevertCmd();
    }
  }

  // ── Display Profiles ──────────────────────────────────────────────
  function saveProfile(name) {
    if (!name || monitors.length === 0) return;
    var monData = [];
    for (var i = 0; i < monitors.length; i++) {
      var m = monitors[i];
      monData.push({
        name: m.name,
        width: m.width,
        height: m.height,
        refreshRate: m.refreshRate,
        scale: m.scale,
        x: m.x,
        y: m.y
      });
    }
    var profiles = Config.displayProfiles.slice();
    // Replace existing profile with same name
    var found = false;
    for (var j = 0; j < profiles.length; j++) {
      if (profiles[j].name === name) {
        profiles[j] = { name: name, monitors: monData };
        found = true;
        break;
      }
    }
    if (!found)
      profiles.push({ name: name, monitors: monData });
    Config.displayProfiles = profiles;
  }

  function loadProfile(profile) {
    if (!profile || !profile.monitors) return;
    var mons = [];
    for (var i = 0; i < profile.monitors.length; i++) {
      var pm = profile.monitors[i];
      mons.push({
        id: i,
        name: pm.name,
        description: "",
        width: pm.width,
        height: pm.height,
        refreshRate: pm.refreshRate,
        x: pm.x,
        y: pm.y,
        scale: pm.scale,
        availableModes: [pm.width + "x" + pm.height + "@" + pm.refreshRate.toFixed(2) + "Hz"],
        dragX: 0,
        dragY: 0
      });
    }
    monitors = mons;
    _computeScaleFactor();
    _syncDragPositions();
    if (mons.length > 0) selectedIndex = 0;
  }

  function deleteProfile(name) {
    var profiles = Config.displayProfiles.slice();
    for (var i = 0; i < profiles.length; i++) {
      if (profiles[i].name === name) {
        profiles.splice(i, 1);
        Config.displayProfiles = profiles;
        return;
      }
    }
  }

  // Auto-profile matching on monitor connect
  function _matchProfile() {
    if (!Config.displayAutoProfile || monitors.length === 0) return;
    var connectedNames = [];
    for (var i = 0; i < monitors.length; i++)
      connectedNames.push(monitors[i].name);
    connectedNames.sort();

    var profiles = Config.displayProfiles;
    for (var j = 0; j < profiles.length; j++) {
      var profileNames = [];
      for (var k = 0; k < profiles[j].monitors.length; k++)
        profileNames.push(profiles[j].monitors[k].name);
      profileNames.sort();

      if (connectedNames.length === profileNames.length &&
          connectedNames.join(",") === profileNames.join(",")) {
        loadProfile(profiles[j]);
        _applyConfig();
        return;
      }
    }
  }

  // ── 30-second confirmation countdown ─────────────────────────────
  property bool countdownActive: false
  property int  countdownSeconds: 30

  function _startCountdown() {
    countdownSeconds = 30;
    countdownActive  = true;
  }

  function _cancelCountdown() {
    countdownActive = false;
    countdownSeconds = 30;
  }

  function _confirmChanges() {
    _cancelCountdown();
    backupMonitors = [];
  }

  Timer {
    id: countdownTimer
    interval: 1000
    running: displayRoot.countdownActive
    repeat: true
    onTriggered: {
      displayRoot.countdownSeconds -= 1;
      if (displayRoot.countdownSeconds <= 0) {
        displayRoot._revertConfig();
        displayRoot._cancelCountdown();
      }
    }
  }

  // ── Helper: unique resolutions / rates for selector ──────────────
  function _uniqueResolutions(modes) {
    var seen = {};
    var result = [];
    for (var i = 0; i < modes.length; i++) {
      var parts = modes[i].split("@");
      var res = parts[0];
      if (!seen[res]) { seen[res] = true; result.push(res); }
    }
    return result;
  }

  function _ratesForResolution(modes, resolution) {
    var result = [];
    for (var i = 0; i < modes.length; i++) {
      var at = modes[i].indexOf("@");
      if (at === -1) continue;
      var res = modes[i].substring(0, at);
      if (res === resolution) {
        var rate = modes[i].substring(at + 1).replace("Hz", "");
        result.push(rate);
      }
    }
    return result;
  }

  function _currentResolution(mon) {
    return mon.width + "x" + mon.height;
  }

  function _applyModeString(index, resStr, rateStr) {
    var parts = resStr.split("x");
    var w = parseInt(parts[0]) || monitors[index].width;
    var h = parseInt(parts[1]) || monitors[index].height;
    var rate = parseFloat(rateStr) || monitors[index].refreshRate;
    var copy = _cloneMonitor(monitors[index]);
    copy.width = w; copy.height = h; copy.refreshRate = rate;
    monitors[index] = copy;
    monitorsChanged();
  }

  // ── UI ────────────────────────────────────────────────────────────
  // Backdrop
  MouseArea {
    anchors.fill: parent
    onClicked: {
      if (!countdownActive) displayRoot.close();
    }
    Rectangle {
      anchors.fill: parent
      color: Colors.background
      opacity: displayRoot.isOpen ? 0.55 : 0.0
      Behavior on opacity { NumberAnimation { duration: Colors.durationNormal; easing.type: Easing.OutCubic } }
    }
  }

  // Main dialog card
  Rectangle {
    id: mainCard
    width: Math.min(Math.max(420, displayRoot.usableWidth - 40), 740)
    height: Math.min(Math.max(420, displayRoot.usableHeight - 40), 560)
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.topMargin: displayRoot.edgeMargins.top + Math.max(20, (displayRoot.usableHeight - height) / 2)
    anchors.leftMargin: displayRoot.edgeMargins.left + Math.max(20, (displayRoot.usableWidth - width) / 2)
    color: Colors.bgGlass
    border.color: Colors.border
    border.width: 1
    radius: Colors.radiusLarge
    clip: true

    focus: displayRoot.isOpen
    onVisibleChanged: {
      if (visible)
        forceActiveFocus()
      else if (activeFocus)
        focus = false
    }
    Keys.onEscapePressed: {
      if (displayRoot.countdownActive) { displayRoot._revertConfig(); displayRoot._cancelCountdown(); }
      else displayRoot.close();
    }

    opacity: displayRoot.isOpen ? 1.0 : 0.0
    scale: displayRoot.isOpen ? 1.0 : 0.95
    Behavior on opacity { NumberAnimation { id: dcFadeAnim; duration: Colors.durationNormal; easing.type: Easing.OutCubic } }
    Behavior on scale   { NumberAnimation { id: dcScaleAnim; duration: Colors.durationSlow; easing.type: Easing.OutBack  } }
    layer.enabled: dcFadeAnim.running || dcScaleAnim.running

    // Eat mouse events so backdrop click doesn't reach through
    MouseArea { anchors.fill: parent }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 0
      spacing: 0

      // ── Header ───────────────────────────────────────────────
      Rectangle {
        Layout.fillWidth: true
        height: 56
        color: "transparent"
        radius: Colors.radiusLarge

        RowLayout {
          anchors { fill: parent; leftMargin: Colors.paddingLarge; rightMargin: Colors.spacingL }
          spacing: Colors.spacingM

          Text {
            text: "󰍺"
            color: Colors.primary
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeHuge
          }
          Text {
            text: "Display Configuration"
            color: Colors.text
            font.pixelSize: Colors.fontSizeXL
            font.weight: Font.Bold
          }
          Item { Layout.fillWidth: true }

          // Close button
          Rectangle {
            width: 32; height: 32; radius: height / 2
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
              onClicked: (mouse) => { closeSL.burst(mouse.x, mouse.y); displayRoot.close(); }
            }
          }
        }

        // Separator
        Rectangle {
          anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
          height: 1
          color: Colors.border
        }
      }

      // ── Canvas area ───────────────────────────────────────────
      Item {
        Layout.fillWidth: true
        height: displayRoot.canvasH + 16
        clip: true

        // Grid background
        Rectangle {
          anchors { fill: parent; margins: Colors.spacingS }
          color: Qt.rgba(0, 0, 0, 0.18)
          radius: Colors.radiusMedium
          border.color: Colors.border
          border.width: 1

          // Dot grid pattern via Canvas
          Canvas {
            anchors.fill: parent
            onPaint: {
              var ctx = getContext("2d");
              ctx.clearRect(0, 0, width, height);
              ctx.fillStyle = Qt.rgba(Colors.textDisabled.r, Colors.textDisabled.g, Colors.textDisabled.b, 0.18);
              var step = 24;
              for (var gx = step; gx < width; gx += step) {
                for (var gy = step; gy < height; gy += step) {
                  ctx.beginPath();
                  ctx.arc(gx, gy, 1.2, 0, Math.PI * 2);
                  ctx.fill();
                }
              }
            }
          }

          // Loading state
          Text {
            visible: displayRoot.loading
            anchors.centerIn: parent
            text: "Loading monitors…"
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeMedium
          }

          // Empty state
          Text {
            visible: !displayRoot.loading && displayRoot.monitors.length === 0
            anchors.centerIn: parent
            text: "No monitors detected"
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeMedium
          }

          // Monitor rectangles
          Repeater {
            model: displayRoot.monitors

            delegate: Item {
              id: monDelegate
              required property var modelData
              required property int index

              // Position and size on canvas (in scaled pixels)
              x: modelData.dragX
              y: modelData.dragY
              width:  modelData.width  * displayRoot.scaleFactor
              height: modelData.height * displayRoot.scaleFactor

              property bool isSelected: displayRoot.selectedIndex === index
              property bool isDragging: false
              property real _pressX: 0
              property real _pressY: 0
              property real _origDragX: 0
              property real _origDragY: 0

              // Monitor body
              Rectangle {
                anchors.fill: parent
                color: monDelegate.isSelected
                       ? Colors.withAlpha(Colors.primary, 0.18)
                       : Colors.cardSurface
                border.color: monDelegate.isSelected
                              ? Colors.primary
                              : (dragArea.containsMouse ? Colors.withAlpha(Colors.primary, 0.5) : Colors.border)
                border.width: monDelegate.isSelected ? 2 : 1
                radius: Colors.radiusSmall

                Behavior on color        { ColorAnimation { duration: Colors.durationFast } }
                Behavior on border.color { ColorAnimation { duration: Colors.durationFast } }

                // Monitor name
                Text {
                  anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: Colors.spacingS }
                  text: monDelegate.modelData.name
                  color: monDelegate.isSelected ? Colors.primary : Colors.text
                  font.pixelSize: Math.max(9, Math.min(13, monDelegate.height * 0.12))
                  font.weight: Font.Bold
                  elide: Text.ElideRight
                  width: parent.width - 8
                  horizontalAlignment: Text.AlignHCenter
                }

                // Resolution + rate
                Text {
                  anchors.centerIn: parent
                  text: monDelegate.modelData.width + "×" + monDelegate.modelData.height
                        + "\n" + monDelegate.modelData.refreshRate.toFixed(0) + "Hz"
                        + "  @" + monDelegate.modelData.scale.toFixed(2) + "×"
                  color: Colors.textSecondary
                  font.pixelSize: Math.max(8, Math.min(11, monDelegate.height * 0.10))
                  font.family: Colors.fontMono
                  horizontalAlignment: Text.AlignHCenter
                  lineHeight: 1.3
                }

                // Drag cursor indicator (bottom-right small glyph)
                Text {
                  anchors { bottom: parent.bottom; right: parent.right; margins: 5 }
                  text: "󰆾"
                  color: Colors.withAlpha(Colors.textDisabled, 0.6)
                  font.family: Colors.fontMono
                  font.pixelSize: Colors.fontSizeXS
                  visible: monDelegate.height > 40
                }
              }

              MouseArea {
                id: dragArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: isDragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                onPressed: (mouse) => {
                  displayRoot.selectedIndex = monDelegate.index;
                  monDelegate.isDragging    = true;
                  monDelegate._pressX   = mouse.x;
                  monDelegate._pressY   = mouse.y;
                  monDelegate._origDragX = monDelegate.modelData.dragX;
                  monDelegate._origDragY = monDelegate.modelData.dragY;
                }

                onPositionChanged: (mouse) => {
                  if (!monDelegate.isDragging) return;
                  var dx = mouse.x - monDelegate._pressX;
                  var dy = mouse.y - monDelegate._pressY;
                  var newX = monDelegate._origDragX + dx;
                  var newY = monDelegate._origDragY + dy;

                  // Clamp within canvas
                  var maxX = displayRoot.canvasW - monDelegate.width;
                  var maxY = displayRoot.canvasH - monDelegate.height;
                  newX = Math.max(0, Math.min(newX, maxX));
                  newY = Math.max(0, Math.min(newY, maxY));

                  displayRoot._updateMonitorDrag(monDelegate.index, newX, newY);
                }

                onReleased: {
                  monDelegate.isDragging = false;
                }
              }
            }
          }
        }
      }

      // Separator
      Rectangle { Layout.fillWidth: true; height: 1; color: Colors.border }

      // ── Selected monitor settings ──────────────────────────────
      Item {
        Layout.fillWidth: true
        implicitHeight: settingsPane.implicitHeight + 24
        visible: displayRoot.selectedIndex >= 0 && displayRoot.monitors.length > 0

        ColumnLayout {
          id: settingsPane
          anchors { left: parent.left; right: parent.right; top: parent.top; margins: Colors.spacingLG }
          spacing: 14

          // Section label
          Text {
            text: displayRoot.selectedIndex >= 0 && displayRoot.monitors.length > 0
                  ? ("Monitor: " + displayRoot.monitors[displayRoot.selectedIndex].name
                     + (displayRoot.monitors[displayRoot.selectedIndex].description
                        ? "  —  " + displayRoot.monitors[displayRoot.selectedIndex].description
                        : ""))
                  : ""
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeXS
            font.weight: Font.Black
            font.letterSpacing: Colors.letterSpacingExtraWide
            elide: Text.ElideRight
            Layout.fillWidth: true
          }

          RowLayout {
            spacing: Colors.spacingL
            Layout.fillWidth: true

            // Resolution selector
            ColumnLayout {
              spacing: Colors.spacingSM
              Layout.fillWidth: true

              Text { text: "RESOLUTION"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Black; font.letterSpacing: Colors.letterSpacingExtraWide }

              ScrollView {
                Layout.fillWidth: true
                height: 68
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ListView {
                  id: resList
                  model: displayRoot.selectedIndex >= 0 && displayRoot.monitors.length > 0
                         ? displayRoot._uniqueResolutions(displayRoot.monitors[displayRoot.selectedIndex].availableModes)
                         : []
                  clip: true
                  orientation: ListView.Horizontal
                  spacing: Colors.spacingSM

                  property string currentRes: displayRoot.selectedIndex >= 0 && displayRoot.monitors.length > 0
                                              ? displayRoot._currentResolution(displayRoot.monitors[displayRoot.selectedIndex])
                                              : ""

                  delegate: Rectangle {
                    required property string modelData
                    required property int index

                    width: resLabel.implicitWidth + 20
                    height: 34
                    radius: Colors.radiusXS
                    color: resList.currentRes === modelData
                           ? Colors.highlight : Colors.bgWidget
                    border.color: resList.currentRes === modelData
                                  ? Colors.primary : Colors.border
                    border.width: 1

                    Text {
                      id: resLabel
                      anchors.centerIn: parent
                      text: modelData
                      color: resList.currentRes === modelData
                             ? Colors.primary : Colors.text
                      font.pixelSize: Colors.fontSizeSmall
                      font.family: Colors.fontMono
                      font.weight: Font.DemiBold
                    }

                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        if (displayRoot.selectedIndex < 0) return;
                        var modes = displayRoot.monitors[displayRoot.selectedIndex].availableModes;
                        var rates = displayRoot._ratesForResolution(modes, modelData);
                        var rate = rates.length > 0 ? rates[0] : "60.00";
                        displayRoot._applyModeString(displayRoot.selectedIndex, modelData, rate);
                      }
                    }
                  }
                }
              }
            }

            // Refresh rate selector
            ColumnLayout {
              spacing: Colors.spacingSM
              Layout.preferredWidth: 180

              Text { text: "REFRESH RATE"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Black; font.letterSpacing: Colors.letterSpacingExtraWide }

              ScrollView {
                Layout.fillWidth: true
                height: 68
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ListView {
                  id: rateList
                  model: {
                    if (displayRoot.selectedIndex < 0 || displayRoot.monitors.length === 0) return [];
                    var mon = displayRoot.monitors[displayRoot.selectedIndex];
                    return displayRoot._ratesForResolution(mon.availableModes, displayRoot._currentResolution(mon));
                  }
                  clip: true
                  orientation: ListView.Horizontal
                  spacing: Colors.spacingSM

                  property string currentRate: displayRoot.selectedIndex >= 0 && displayRoot.monitors.length > 0
                                               ? displayRoot.monitors[displayRoot.selectedIndex].refreshRate.toFixed(2)
                                               : ""

                  delegate: Rectangle {
                    required property string modelData
                    required property int index

                    property bool isCurrent: {
                      if (displayRoot.selectedIndex < 0 || displayRoot.monitors.length === 0) return false;
                      var monRate = displayRoot.monitors[displayRoot.selectedIndex].refreshRate.toFixed(2);
                      return modelData === monRate;
                    }

                    width: rateLabel.implicitWidth + 20
                    height: 34
                    radius: Colors.radiusXS
                    color: isCurrent ? Colors.highlight : Colors.bgWidget
                    border.color: isCurrent ? Colors.primary : Colors.border
                    border.width: 1

                    Text {
                      id: rateLabel
                      anchors.centerIn: parent
                      text: modelData + "Hz"
                      color: isCurrent ? Colors.primary : Colors.text
                      font.pixelSize: Colors.fontSizeSmall
                      font.family: Colors.fontMono
                      font.weight: Font.DemiBold
                    }

                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        if (displayRoot.selectedIndex < 0 || displayRoot.monitors.length === 0) return;
                        var mon = displayRoot.monitors[displayRoot.selectedIndex];
                        displayRoot._applyModeString(displayRoot.selectedIndex,
                                                     displayRoot._currentResolution(mon), modelData);
                      }
                    }
                  }
                }
              }
            }

            // Scale selector
            ColumnLayout {
              spacing: Colors.spacingSM
              Layout.preferredWidth: 220

              Text { text: "SCALE"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Black; font.letterSpacing: Colors.letterSpacingExtraWide }

              Flow {
                Layout.fillWidth: true
                spacing: Colors.spacingSM

                Repeater {
                  model: ["1.00", "1.25", "1.50", "1.75", "2.00"]

                  delegate: Rectangle {
                    required property string modelData

                    property bool isCurrent: {
                      if (displayRoot.selectedIndex < 0 || displayRoot.monitors.length === 0) return false;
                      return Math.abs(displayRoot.monitors[displayRoot.selectedIndex].scale - parseFloat(modelData)) < 0.01;
                    }

                    width: scaleLabel.implicitWidth + 16
                    height: 30
                    radius: Colors.radiusXS
                    color: isCurrent ? Colors.highlight : Colors.bgWidget
                    border.color: isCurrent ? Colors.primary : Colors.border
                    border.width: 1

                    Text {
                      id: scaleLabel
                      anchors.centerIn: parent
                      text: modelData + "×"
                      color: isCurrent ? Colors.primary : Colors.text
                      font.pixelSize: Colors.fontSizeSmall
                      font.family: Colors.fontMono
                      font.weight: Font.DemiBold
                    }

                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        if (displayRoot.selectedIndex < 0) return;
                        displayRoot._updateMonitorSetting(displayRoot.selectedIndex,
                                                          "scale", parseFloat(modelData));
                      }
                    }
                  }
                }
              }
            }

            // Position readout
            ColumnLayout {
              spacing: Colors.spacingSM
              Layout.preferredWidth: 110

              Text { text: "POSITION"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Black; font.letterSpacing: Colors.letterSpacingExtraWide }

              Rectangle {
                width: 100; height: 46
                radius: Colors.radiusSmall
                color: Colors.bgWidget
                border.color: Colors.border
                border.width: 1

                ColumnLayout {
                  anchors.centerIn: parent
                  spacing: Colors.spacingXXS

                  Text {
                    text: displayRoot.selectedIndex >= 0 && displayRoot.monitors.length > 0
                          ? ("X: " + displayRoot.monitors[displayRoot.selectedIndex].x)
                          : "X: —"
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeSmall
                    font.family: Colors.fontMono
                    Layout.alignment: Qt.AlignHCenter
                  }
                  Text {
                    text: displayRoot.selectedIndex >= 0 && displayRoot.monitors.length > 0
                          ? ("Y: " + displayRoot.monitors[displayRoot.selectedIndex].y)
                          : "Y: —"
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeSmall
                    font.family: Colors.fontMono
                    Layout.alignment: Qt.AlignHCenter
                  }
                }
              }
            }
          }
        }
      }

      // Separator
      Rectangle { Layout.fillWidth: true; height: 1; color: Colors.border }

      // ── Profile buttons ─────────────────────────────────────────
      RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Colors.spacingLG
        Layout.rightMargin: Colors.spacingLG
        Layout.topMargin: Colors.spacingS
        spacing: Colors.spacingS

        Text {
          text: "PROFILES"
          color: Colors.textDisabled
          font.pixelSize: Colors.fontSizeXS
          font.weight: Font.Black
          font.letterSpacing: Colors.letterSpacingExtraWide
        }

        Item { Layout.fillWidth: true }

        // Save Profile
        Rectangle {
          height: 30; width: saveProfileRow.implicitWidth + 20
          radius: Colors.radiusXS
          color: Colors.bgWidget
          border.color: Colors.border; border.width: 1

          RowLayout {
            id: saveProfileRow
            anchors.centerIn: parent
            spacing: Colors.spacingXS
            Text { text: "󰆓"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeSmall }
            Text { text: "Save"; color: Colors.text; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Medium }
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              var name = "Profile " + (Config.displayProfiles.length + 1);
              displayRoot.saveProfile(name);
            }
          }
        }

        // Load Profile dropdown
        Repeater {
          model: Config.displayProfiles
          delegate: Rectangle {
            required property var modelData
            required property int index
            height: 30; width: loadLabel.implicitWidth + 20
            radius: Colors.radiusXS
            color: Colors.bgWidget
            border.color: Colors.border; border.width: 1

            Text {
              id: loadLabel
              anchors.centerIn: parent
              text: modelData.name || ("Profile " + (index + 1))
              color: Colors.text
              font.pixelSize: Colors.fontSizeXS
              font.weight: Font.Medium
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: displayRoot.loadProfile(modelData)
            }
          }
        }
      }

      // ── Action buttons ─────────────────────────────────────────
      RowLayout {
        Layout.fillWidth: true
        Layout.margins: Colors.spacingLG
        spacing: Colors.spacingM

        // Reload button
        Rectangle {
          height: 40
          width: 120
          radius: Colors.radiusSmall
          color: Colors.bgWidget
          border.color: Colors.border
          border.width: 1

          RowLayout {
            anchors.centerIn: parent
            spacing: Colors.spacingS
            Text { text: "󰑐"; color: Colors.textSecondary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeMedium }
            Text { text: "Reload"; color: Colors.text; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Medium }
          }

          SharedWidgets.StateLayer {
            id: reloadSL
            hovered: reloadHover.containsMouse
            pressed: reloadHover.containsPress
          }
          MouseArea {
            id: reloadHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => { reloadSL.burst(mouse.x, mouse.y); displayRoot._loadMonitors(); }
          }
        }

        Item { Layout.fillWidth: true }

        // Cancel / close button
        Rectangle {
          height: 40
          width: 120
          radius: Colors.radiusSmall
          color: Colors.bgWidget
          border.color: Colors.border
          border.width: 1

          RowLayout {
            anchors.centerIn: parent
            spacing: Colors.spacingS
            Text { text: "󰅖"; color: Colors.textSecondary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeMedium }
            Text { text: "Close"; color: Colors.text; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Medium }
          }

          SharedWidgets.StateLayer {
            id: cancelSL
            hovered: cancelHover.containsMouse
            pressed: cancelHover.containsPress
          }
          MouseArea {
            id: cancelHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => { cancelSL.burst(mouse.x, mouse.y); displayRoot.close(); }
          }
        }

        // Apply button
        Rectangle {
          height: 40
          width: 140
          radius: Colors.radiusSmall
          color: displayRoot.applyInProgress
                 ? Colors.withAlpha(Colors.primary, 0.4)
                 : Colors.primary
          Behavior on color { ColorAnimation { duration: Colors.durationFast } }

          RowLayout {
            anchors.centerIn: parent
            spacing: Colors.spacingS
            Text {
              text: displayRoot.applyInProgress ? "󰔟" : "󰄬"
              color: Colors.text
              font.family: Colors.fontMono
              font.pixelSize: Colors.fontSizeMedium

              // Simple spinning rotation when busy
              NumberAnimation on rotation {
                running: displayRoot.applyInProgress
                from: 0; to: 360
                duration: 800
                loops: Animation.Infinite
              }
            }
            Text {
              text: displayRoot.applyInProgress ? "Applying…" : "Apply"
              color: Colors.text
              font.pixelSize: Colors.fontSizeSmall
              font.weight: Font.Bold
            }
          }

          SharedWidgets.StateLayer {
            id: applySL
            hovered: applyHover.containsMouse
            pressed: applyHover.containsPress
            stateColor: Colors.primary
            visible: !displayRoot.applyInProgress
          }
          MouseArea {
            id: applyHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: displayRoot.applyInProgress ? Qt.BusyCursor : Qt.PointingHandCursor
            onClicked: (mouse) => {
              if (!displayRoot.applyInProgress && displayRoot.monitors.length > 0) {
                applySL.burst(mouse.x, mouse.y);
                displayRoot._applyConfig();
              }
            }
          }
        }
      }
    }

    // ── Countdown overlay (shown after Apply) ────────────────────
    Rectangle {
      anchors.fill: parent
      visible: displayRoot.countdownActive
      color: Colors.withAlpha(Colors.background, 0.82)
      radius: Colors.radiusLarge

      opacity: displayRoot.countdownActive ? 1.0 : 0.0
      Behavior on opacity { NumberAnimation { duration: Colors.durationNormal; easing.type: Easing.OutCubic } }

      ColumnLayout {
        anchors.centerIn: parent
        spacing: Colors.spacingXL

        // Big countdown ring / number
        Item {
          Layout.alignment: Qt.AlignHCenter
          width: 110; height: 110

          Canvas {
            id: cdCanvas
            anchors.fill: parent
            onPaint: {
              var ctx = getContext("2d");
              ctx.clearRect(0, 0, width, height);
              var cx = width / 2, cy = height / 2, r = 46;
              // Track
              ctx.beginPath();
              ctx.arc(cx, cy, r, 0, Math.PI * 2);
              ctx.strokeStyle = Qt.rgba(Colors.border.r, Colors.border.g, Colors.border.b, 0.4);
              ctx.lineWidth = 5;
              ctx.stroke();
              // Progress arc
              var progress = displayRoot.countdownSeconds / 30.0;
              ctx.beginPath();
              ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + progress * Math.PI * 2);
              ctx.strokeStyle = Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.9);
              ctx.lineWidth = 5;
              ctx.lineCap = "round";
              ctx.stroke();
            }

            Connections {
              target: displayRoot
              function onCountdownSecondsChanged() { cdCanvas.requestPaint(); }
            }
          }

          Text {
            anchors.centerIn: parent
            text: displayRoot.countdownSeconds.toString()
            color: displayRoot.countdownSeconds <= 5 ? Colors.error : Colors.text
            font.pixelSize: 36
            font.weight: Font.Bold
            Behavior on color { ColorAnimation { duration: Colors.durationSlow } }
          }
        }

        Text {
          text: "Keep this display configuration?"
          color: Colors.text
          font.pixelSize: Colors.fontSizeLarge
          font.weight: Font.Bold
          Layout.alignment: Qt.AlignHCenter
        }

        Text {
          text: "Reverting in " + displayRoot.countdownSeconds + " seconds…"
          color: Colors.textSecondary
          font.pixelSize: Colors.fontSizeSmall
          Layout.alignment: Qt.AlignHCenter
        }

        RowLayout {
          Layout.alignment: Qt.AlignHCenter
          spacing: Colors.spacingL

          // Revert Now
          Rectangle {
            width: 140; height: 44
            radius: Colors.radiusSmall
            color: Colors.withAlpha(Colors.error, 0.12)
            border.color: Colors.error
            border.width: 1

            RowLayout {
              anchors.centerIn: parent
              spacing: Colors.spacingS
              Text { text: "󰜺"; color: Colors.error; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeMedium }
              Text { text: "Revert Now"; color: Colors.error; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Bold }
            }

            SharedWidgets.StateLayer {
              id: revertNowSL
              hovered: revertNowHover.containsMouse
              pressed: revertNowHover.containsPress
              stateColor: Colors.error
            }
            MouseArea {
              id: revertNowHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: (mouse) => { revertNowSL.burst(mouse.x, mouse.y); displayRoot._revertConfig(); displayRoot._cancelCountdown(); }
            }
          }

          // Keep Changes
          Rectangle {
            width: 150; height: 44
            radius: Colors.radiusSmall
            color: Colors.withAlpha(Colors.secondary, 0.12)
            border.color: Colors.secondary
            border.width: 1

            RowLayout {
              anchors.centerIn: parent
              spacing: Colors.spacingS
              Text { text: "󰄬"; color: Colors.secondary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeMedium }
              Text { text: "Keep Changes"; color: Colors.secondary; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Bold }
            }

            SharedWidgets.StateLayer {
              id: keepSL
              hovered: keepHover.containsMouse
              pressed: keepHover.containsPress
              stateColor: Colors.secondary
            }
            MouseArea {
              id: keepHover
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: (mouse) => { keepSL.burst(mouse.x, mouse.y); displayRoot._confirmChanges(); }
            }
          }
        }
      }
    }
  }
}
