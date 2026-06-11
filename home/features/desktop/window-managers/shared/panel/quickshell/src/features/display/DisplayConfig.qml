import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../services"
import "../../widgets" as SharedWidgets
import "../../shared"
import "DisplayConfigHelpers.js" as Helpers

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
    openRefreshTimer.attempts = 0;
    openRefreshTimer.restart();
    _loadMonitors();
  }

  function close() {
    if (countdownActive) _revertConfig();
    _cancelCountdown();
    openRefreshTimer.stop();
    if (mainCard.activeFocus)
      mainCard.focus = false;
    isOpen = false;
  }

  function toggle() {
    isOpen ? close() : open();
  }

  onIsOpenChanged: {
    if (isOpen) {
      // Ensure we have a fresh command and trigger an immediate load attempt
      monitorLoadProc.command = CompositorAdapter.monitorListCommand();
      Qt.callLater(_loadMonitors);
    }
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
  property string monitorProbeStderr: ""

  // Canvas viewport / auto-fit
  readonly property real canvasW: 700
  readonly property real canvasH: 260
  readonly property real canvasViewportH: Math.max(190, Math.min(canvasH + 16, Math.round(usableHeight * 0.26)))

  // Recomputed whenever monitors changes
  property real scaleFactor: 1.0
  property real canvasOffsetX: 0
  property real canvasOffsetY: 0

  function _computeScaleFactor() {
    var r = Helpers.computeScaleFactor(monitors, canvasW, canvasH);
    scaleFactor   = r.scale;
    canvasOffsetX = r.offsetX;
    canvasOffsetY = r.offsetY;
  }

  // ── Monitor loading ───────────────────────────────────────────────
  function _loadMonitors() {
    // Ensure command is up to date before running
    monitorLoadProc.command = CompositorAdapter.monitorListCommand();
    if (monitorLoadProc.running) monitorLoadProc.running = false;
    loading = true;
    // Don't clear immediately if we already have some monitors to avoid flickering,
    // unless we have none at all.
    if (monitors.length === 0) selectedIndex = -1;
    monitorProbeStderr = "";
    monitorLoadProc.running = true;
  }

  Timer {
    id: openRefreshTimer
    interval: 600
    repeat: true
    property int attempts: 0
    onTriggered: {
      if (!displayRoot.isOpen) { stop(); return; }
      
      // If we have monitors, we can stop retrying.
      if (displayRoot.monitors.length > 0) {
        stop();
        return;
      }

      attempts++;
      if (attempts > 5) {
        // Give up after 5 attempts (~3 seconds total)
        stop();
        return;
      }

      // If not already running, try another load
      if (!monitorLoadProc.running) {
        displayRoot._loadMonitors();
      }
    }
  }

  Process {
    id: monitorLoadProc
    command: CompositorAdapter.monitorListCommand()
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        displayRoot.loading = false;
        try {
          var raw = Helpers.parseJsonOutput(this.text || "[]", []);
          var result = Helpers.normalizeMonitorList(raw);
          if (result.length === 0) {
            result = Helpers.fallbackMonitorsFromScreens(Quickshell.screens);
            if (result.length > 0)
              Logger.w("DisplayConfig", "Monitor probe returned no monitors; using Quickshell screen fallback.");
          }
          displayRoot.monitors = result;
          displayRoot._syncDragPositions();
          displayRoot._computeScaleFactor();
          if (result.length > 0) displayRoot.selectedIndex = 0;
        } catch (e) {
          var fallback = Helpers.fallbackMonitorsFromScreens(Quickshell.screens);
          if (fallback.length > 0) {
            Logger.w("DisplayConfig",
                     "Failed to parse monitor probe output; using Quickshell screen fallback.",
                     e,
                     displayRoot.monitorProbeStderr ? "stderr:" + displayRoot.monitorProbeStderr : "");
            displayRoot.monitors = fallback;
            displayRoot._syncDragPositions();
            displayRoot._computeScaleFactor();
            displayRoot.selectedIndex = 0;
            return;
          }

          Logger.e("DisplayConfig",
                   "failed to parse monitors:",
                   e,
                   displayRoot.monitorProbeStderr ? "stderr:" + displayRoot.monitorProbeStderr : "");
        }
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        displayRoot.monitorProbeStderr = String(this.text || "").trim();
        if (displayRoot.monitorProbeStderr.length > 0)
          Logger.w("DisplayConfig", "monitor probe stderr:", displayRoot.monitorProbeStderr);
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

  function _cloneMonitor(m) { return Helpers.cloneMonitor(m); }

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
      if (m.disabled) {
        cmds.push(CompositorAdapter.monitorKeywordCommand(
          m.name + ",disable"
        ));
        continue;
      }
      var rateStr = m.refreshRate.toFixed(2);
      var posStr  = m.x + "x" + m.y;
      var dimStr  = m.width + "x" + m.height + "@" + rateStr;
      var scaleStr = m.scale.toFixed(2);
      var spec = m.name + "," + dimStr + "," + posStr + "," + scaleStr;
      if (m.mirrorOf)
        spec += ",mirror," + m.mirrorOf;
      cmds.push(CompositorAdapter.monitorKeywordCommand(
        spec
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
        y: m.y,
        mirrorOf: m.mirrorOf || "",
        disabled: !!m.disabled
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
        mirrorOf: pm.mirrorOf || "",
        disabled: !!pm.disabled,
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


  // ── 30-second confirmation countdown ─────────────────────────────
  readonly property int _revertCountdownSec: 30
  property bool countdownActive: false
  property int  countdownSeconds: _revertCountdownSec

  function _startCountdown() {
    countdownSeconds = _revertCountdownSec;
    countdownActive  = true;
  }

  function _cancelCountdown() {
    countdownActive = false;
    countdownSeconds = _revertCountdownSec;
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

  // ── Quick-layout presets ──────────────────────────────────────────
  function _applyPreset(arrangeFn) {
    if (monitors.length < 2) return;
    monitors = arrangeFn(monitors);
    _computeScaleFactor();
    _syncDragPositions();
  }

  // ── Helper: unique resolutions / rates for selector ──────────────
  function _uniqueResolutions(modes)              { return Helpers.uniqueResolutions(modes); }
  function _ratesForResolution(modes, resolution) { return Helpers.ratesForResolution(modes, resolution); }

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
      Behavior on opacity { Anim {} }
    }
  }

  SharedWidgets.ElasticNumber {
    id: _dcElasticScale
    target: displayRoot.isOpen ? 1.0 : 0.95
    fastDuration: Appearance.durationSnap
    slowDuration: Appearance.durationSlow
    fastWeight: 0.45
  }

  // Main dialog card
  Rectangle {
    id: mainCard
    width: Math.min(Math.max(420, displayRoot.usableWidth - 40), 820)
    // Use most of the available work area so footer actions stay reachable.
    height: Math.max(420, Math.min(displayRoot.usableHeight - 20, 720))
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.topMargin: displayRoot.edgeMargins.top + Math.max(10, (displayRoot.usableHeight - height) / 2)
    anchors.leftMargin: displayRoot.edgeMargins.left + Math.max(20, (displayRoot.usableWidth - width) / 2)
    color: Colors.bgGlass
    border.color: Colors.border
    border.width: 1
    radius: Appearance.radiusLarge
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
    scale: _dcElasticScale.value
    Behavior on opacity { NumberAnimation { id: dcFadeAnim; duration: Appearance.durationNormal; easing.type: Easing.OutCubic } }
    layer.enabled: dcFadeAnim.running || _dcElasticScale.running

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
        radius: Appearance.radiusLarge

        RowLayout {
          anchors { fill: parent; leftMargin: Appearance.paddingLarge; rightMargin: Appearance.spacingL }
          spacing: Appearance.spacingM

          SharedWidgets.SvgIcon {
            source: "desktop.svg"
            color: Colors.primary
            size: Appearance.fontSizeHuge
          }
          Text {
            text: "Display Configuration"
            color: Colors.text
            font.pixelSize: Appearance.fontSizeXL
            font.weight: Font.Bold
          }
          Item { Layout.fillWidth: true }

          // Close button
          Rectangle {
            width: 32; height: 32; radius: height / 2
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
      DisplayConfigCanvas {
        Layout.fillWidth: true
        height: displayRoot.canvasViewportH
        monitors: displayRoot.monitors
        selectedIndex: displayRoot.selectedIndex
        scaleFactor: displayRoot.scaleFactor
        canvasOffsetX: displayRoot.canvasOffsetX
        canvasOffsetY: displayRoot.canvasOffsetY
        canvasW: displayRoot.canvasW
        canvasH: displayRoot.canvasH
        loading: displayRoot.loading
        onMonitorSelected: index => displayRoot.selectedIndex = index
        onMonitorDragged: (index, newDragX, newDragY) => displayRoot._updateMonitorDrag(index, newDragX, newDragY)
      }

      // Separator
      Rectangle { Layout.fillWidth: true; height: 1; color: Colors.border }

      ScrollView {
        id: contentScroll
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: 0
        Layout.minimumHeight: 0
        clip: true
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
          width: contentScroll.availableWidth
          spacing: 0

          // ── Quick-layout presets ─────────────────────────────────────
          RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Appearance.spacingLG
            Layout.rightMargin: Appearance.spacingLG
            Layout.topMargin: Appearance.spacingS
            Layout.bottomMargin: Appearance.spacingXS
            spacing: Appearance.spacingS
            visible: displayRoot.monitors.length >= 2

            Text {
              text: "LAYOUT"
              color: Colors.textDisabled
              font.pixelSize: Appearance.fontSizeXS
              font.weight: Font.Black
              font.letterSpacing: Appearance.letterSpacingExtraWide
            }

            Item { Layout.fillWidth: true }

            Repeater {
              model: [
                { icon: "desktop.svg", label: "Primary Only", preset: "primary" },
                { icon: "image-copy.svg", label: "Mirror",       preset: "mirror"  },
                { icon: "fullscreen.svg", label: "Extend",       preset: "extend"  }
              ]

              delegate: Rectangle {
                required property var modelData
                required property int index

                height: 30
                width: presetRow.implicitWidth + 18
                radius: Appearance.radiusXS
                color: Colors.bgWidget
                border.color: Colors.border
                border.width: 1

                RowLayout {
                  id: presetRow
                  anchors.centerIn: parent
                  spacing: Appearance.spacingXS
                  Loader {
                    property string _ic: modelData.icon || ""
                    sourceComponent: String(_ic).endsWith(".svg") ? _presetSvg : _presetNerd
                  }
                  Component { id: _presetSvg; SharedWidgets.SvgIcon { source: parent._ic; color: Colors.primary; size: Appearance.fontSizeSmall } }
                  Component { id: _presetNerd; Text { text: parent._ic; color: Colors.primary; font.family: Appearance.fontMono; font.pixelSize: Appearance.fontSizeSmall } }
                  Text {
                    text: modelData.label
                    color: Colors.text
                    font.pixelSize: Appearance.fontSizeXS
                    font.weight: Font.Medium
                  }
                }

                SharedWidgets.StateLayer {
                  id: presetSL
                  hovered: presetMA.containsMouse
                  pressed: presetMA.containsPress
                }
                MouseArea {
                  id: presetMA
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: (mouse) => {
                    presetSL.burst(mouse.x, mouse.y);
                    if (modelData.preset === "primary")
                      displayRoot._applyPreset(Helpers.arrangePrimaryOnly);
                    else if (modelData.preset === "mirror")
                      displayRoot._applyPreset(Helpers.arrangeMirror);
                    else
                      displayRoot._applyPreset(Helpers.arrangeExtend);
                  }
                }
              }
            }
          }

          // ── Selected monitor settings ──────────────────────────────
          Item {
            Layout.fillWidth: true
            implicitHeight: settingsPane.implicitHeight + Appearance.paddingLarge
            visible: displayRoot.selectedIndex >= 0 && displayRoot.monitors.length > 0

            ColumnLayout {
              id: settingsPane
              anchors { left: parent.left; right: parent.right; top: parent.top; margins: Appearance.spacingLG }
              spacing: Appearance.spacingL

              // Section label
              Text {
                text: displayRoot.selectedIndex >= 0 && displayRoot.monitors.length > 0
                      ? ("Monitor: " + displayRoot.monitors[displayRoot.selectedIndex].name
                         + (displayRoot.monitors[displayRoot.selectedIndex].description
                            ? "  —  " + displayRoot.monitors[displayRoot.selectedIndex].description
                            : ""))
                      : ""
                color: Colors.textDisabled
                font.pixelSize: Appearance.fontSizeXS
                font.weight: Font.Black
                font.letterSpacing: Appearance.letterSpacingExtraWide
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              GridLayout {
                columns: 2
                columnSpacing: Appearance.spacingXL
                rowSpacing: Appearance.spacingL
                Layout.fillWidth: true

                // 1. Resolution
                ColumnLayout {
                  Layout.fillWidth: true
                  Layout.columnSpan: 2
                  spacing: Appearance.spacingS

                  Text { text: "RESOLUTION"; color: Colors.textDisabled; font.pixelSize: Appearance.fontSizeXS; font.weight: Font.Black; font.letterSpacing: Appearance.letterSpacingExtraWide }

                  Flow {
                    id: resFlow
                    Layout.fillWidth: true
                    spacing: Appearance.spacingS
                    property string currentRes: displayRoot.selectedIndex >= 0 && displayRoot.monitors.length > 0
                                                  ? displayRoot._currentResolution(displayRoot.monitors[displayRoot.selectedIndex])
                                                  : ""
                    Repeater {
                      model: displayRoot.selectedIndex >= 0 && displayRoot.monitors.length > 0
                             ? displayRoot._uniqueResolutions(displayRoot.monitors[displayRoot.selectedIndex].availableModes)
                             : []
                      delegate: Rectangle {
                        required property string modelData
                        width: resLabel.implicitWidth + 24; height: 32; radius: Appearance.radiusXS
                        color: resFlow.currentRes === modelData ? Colors.highlight : Colors.bgWidget
                        border.color: resFlow.currentRes === modelData ? Colors.primary : Colors.border; border.width: 1
                        Text { id: resLabel; anchors.centerIn: parent; text: modelData; color: resFlow.currentRes === modelData ? Colors.primary : Colors.text; font.pixelSize: Appearance.fontSizeSmall; font.family: Appearance.fontMono; font.weight: Font.DemiBold }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: {
                          if (displayRoot.selectedIndex < 0) return;
                          var modes = displayRoot.monitors[displayRoot.selectedIndex].availableModes;
                          var rates = displayRoot._ratesForResolution(modes, modelData);
                          var rate = rates.length > 0 ? rates[0] : "60.00";
                          displayRoot._applyModeString(displayRoot.selectedIndex, modelData, rate);
                        }}
                      }
                    }
                  }
                }

                // 2. Refresh Rate
                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: Appearance.spacingS
                  Text { text: "REFRESH RATE"; color: Colors.textDisabled; font.pixelSize: Appearance.fontSizeXS; font.weight: Font.Black; font.letterSpacing: Appearance.letterSpacingExtraWide }
                  Flow {
                    id: rateFlow
                    Layout.fillWidth: true
                    spacing: Appearance.spacingS
                    property string currentRate: displayRoot.selectedIndex >= 0 && displayRoot.monitors.length > 0
                                                   ? displayRoot.monitors[displayRoot.selectedIndex].refreshRate.toFixed(2)
                                                   : ""
                    Repeater {
                      model: {
                        if (displayRoot.selectedIndex < 0 || displayRoot.monitors.length === 0) return [];
                        var mon = displayRoot.monitors[displayRoot.selectedIndex];
                        return displayRoot._ratesForResolution(mon.availableModes, displayRoot._currentResolution(mon));
                      }
                      delegate: Rectangle {
                        required property string modelData
                        width: rateLabel.implicitWidth + 24; height: 32; radius: Appearance.radiusXS
                        color: modelData === rateFlow.currentRate ? Colors.highlight : Colors.bgWidget
                        border.color: modelData === rateFlow.currentRate ? Colors.primary : Colors.border; border.width: 1
                        Text { id: rateLabel; anchors.centerIn: parent; text: modelData + "Hz"; color: modelData === rateFlow.currentRate ? Colors.primary : Colors.text; font.pixelSize: Appearance.fontSizeSmall; font.family: Appearance.fontMono; font.weight: Font.DemiBold }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: {
                          if (displayRoot.selectedIndex < 0 || displayRoot.monitors.length === 0) return;
                          var mon = displayRoot.monitors[displayRoot.selectedIndex];
                          displayRoot._applyModeString(displayRoot.selectedIndex, displayRoot._currentResolution(mon), modelData);
                        }}
                      }
                    }
                  }
                }

                // 3. Scale & Position
                RowLayout {
                  Layout.fillWidth: true
                  spacing: Appearance.spacingXL

                  ColumnLayout {
                    spacing: Appearance.spacingS
                    Text { text: "SCALE"; color: Colors.textDisabled; font.pixelSize: Appearance.fontSizeXS; font.weight: Font.Black; font.letterSpacing: Appearance.letterSpacingExtraWide }
                    Flow {
                      spacing: Appearance.spacingS
                      Repeater {
                        model: ["1.00", "1.25", "1.50", "1.75", "2.00"]
                        delegate: Rectangle {
                          required property string modelData
                          property bool isCurrent: {
                            if (displayRoot.selectedIndex < 0 || displayRoot.monitors.length === 0) return false;
                            return Math.abs(displayRoot.monitors[displayRoot.selectedIndex].scale - parseFloat(modelData)) < 0.01;
                          }
                          width: scaleLabel.implicitWidth + 20; height: 32; radius: Appearance.radiusXS
                          color: isCurrent ? Colors.highlight : Colors.bgWidget
                          border.color: isCurrent ? Colors.primary : Colors.border; border.width: 1
                          Text { id: scaleLabel; anchors.centerIn: parent; text: modelData + "×"; color: isCurrent ? Colors.primary : Colors.text; font.pixelSize: Appearance.fontSizeSmall; font.family: Appearance.fontMono; font.weight: Font.DemiBold }
                          MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: {
                            if (displayRoot.selectedIndex < 0) return;
                            displayRoot._updateMonitorSetting(displayRoot.selectedIndex, "scale", parseFloat(modelData));
                          }}
                        }
                      }
                    }
                  }

                  ColumnLayout {
                    spacing: Appearance.spacingS
                    Text { text: "POSITION"; color: Colors.textDisabled; font.pixelSize: Appearance.fontSizeXS; font.weight: Font.Black; font.letterSpacing: Appearance.letterSpacingExtraWide }
                    Rectangle {
                      width: 120; height: 40; radius: Appearance.radiusXS; color: Colors.bgWidget; border.color: Colors.border; border.width: 1
                      RowLayout {
                        anchors.centerIn: parent; spacing: Appearance.spacingM
                        Text { text: displayRoot.selectedIndex >= 0 && displayRoot.monitors.length > 0 ? ("X: " + displayRoot.monitors[displayRoot.selectedIndex].x) : "X: —"; color: Colors.text; font.pixelSize: Appearance.fontSizeSmall; font.family: Appearance.fontMono }
                        Text { text: displayRoot.selectedIndex >= 0 && displayRoot.monitors.length > 0 ? ("Y: " + displayRoot.monitors[displayRoot.selectedIndex].y) : "Y: —"; color: Colors.text; font.pixelSize: Appearance.fontSizeSmall; font.family: Appearance.fontMono }
                      }
                    }
                  }
                }
              }
            }
          }

          // Separator
          Rectangle { Layout.fillWidth: true; height: 1; color: Colors.border }
        }
      }

      // ── Profile buttons ─────────────────────────────────────────
      RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Appearance.spacingLG
        Layout.rightMargin: Appearance.spacingLG
        Layout.topMargin: Appearance.spacingS
        spacing: Appearance.spacingS

        Text {
          text: "PROFILES"
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeXS
          font.weight: Font.Black
          font.letterSpacing: Appearance.letterSpacingExtraWide
        }

        Item { Layout.fillWidth: true }

        // Save Profile
        Rectangle {
          height: 30; width: saveProfileRow.implicitWidth + 20
          radius: Appearance.radiusXS
          color: Colors.bgWidget
          border.color: Colors.border; border.width: 1

          RowLayout {
            id: saveProfileRow
            anchors.centerIn: parent
            spacing: Appearance.spacingXS
            SharedWidgets.SvgIcon { source: "save.svg"; color: Colors.primary; size: Appearance.fontSizeSmall }
            Text { text: "Save"; color: Colors.text; font.pixelSize: Appearance.fontSizeXS; font.weight: Font.Medium }
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
            radius: Appearance.radiusXS
            color: Colors.bgWidget
            border.color: Colors.border; border.width: 1

            Text {
              id: loadLabel
              anchors.centerIn: parent
              text: modelData.name || ("Profile " + (index + 1))
              color: Colors.text
              font.pixelSize: Appearance.fontSizeXS
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
        Layout.margins: Appearance.spacingLG
        spacing: Appearance.spacingM

        // Reload button
        Rectangle {
          height: 40
          width: 120
          radius: Appearance.radiusSmall
          color: Colors.bgWidget
          border.color: Colors.border
          border.width: 1

          RowLayout {
            anchors.centerIn: parent
            spacing: Appearance.spacingS
            SharedWidgets.SvgIcon { source: "arrow-clockwise.svg"; color: Colors.textSecondary; size: Appearance.fontSizeMedium }
            Text { text: "Reload"; color: Colors.text; font.pixelSize: Appearance.fontSizeSmall; font.weight: Font.Medium }
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
          radius: Appearance.radiusSmall
          color: Colors.bgWidget
          border.color: Colors.border
          border.width: 1

          RowLayout {
            anchors.centerIn: parent
            spacing: Appearance.spacingS
            SharedWidgets.SvgIcon { source: "dismiss.svg"; color: Colors.textSecondary; size: Appearance.fontSizeMedium }
            Text { text: "Close"; color: Colors.text; font.pixelSize: Appearance.fontSizeSmall; font.weight: Font.Medium }
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
          radius: Appearance.radiusSmall
          color: displayRoot.applyInProgress
                 ? Colors.withAlpha(Colors.primary, 0.4)
                 : Colors.primary
          Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }

          RowLayout {
            anchors.centerIn: parent
            spacing: Appearance.spacingS
            SharedWidgets.SvgIcon {
              source: displayRoot.applyInProgress ? "timer.svg" : "checkmark.svg"
              color: Colors.text
              size: Appearance.fontSizeMedium

              // Simple spinning rotation when busy
              NumberAnimation on rotation {
                running: displayRoot.applyInProgress
                from: 0; to: 360
                duration: Appearance.durationLong
                loops: Animation.Infinite
              }
            }
            Text {
              text: displayRoot.applyInProgress ? "Applying…" : "Apply"
              color: Colors.text
              font.pixelSize: Appearance.fontSizeSmall
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
    DisplayConfigCountdown {
      anchors.fill: parent
      active: displayRoot.countdownActive
      seconds: displayRoot.countdownSeconds
      onRevertRequested: { displayRoot._revertConfig(); displayRoot._cancelCountdown(); }
      onConfirmRequested: displayRoot._confirmChanges()
    }
  }
}
