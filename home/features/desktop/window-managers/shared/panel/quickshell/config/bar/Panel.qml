import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Wayland
import "."
import "widgets"
import "../modules"
import "../services"
import "../widgets" as SharedWidgets

Item {
  id: root

  SharedWidgets.Ref { service: RecordingService }
  SharedWidgets.Ref { service: PrivacyService }
  SharedWidgets.Ref { service: PrinterService }
  SharedWidgets.Ref { service: SpectrumService }
  SharedWidgets.Ref { service: SystemStatus }

  property var manager: null
  property var anchorWindow: null
  property var screenRef: null
  property var barConfig: null
  property string activeSurfaceId: ""

  readonly property string position: (barConfig && barConfig.position) || "top"
  readonly property bool vertical: Config.isVerticalBar(position)
  readonly property int thickness: Config.barThickness(barConfig)
  readonly property var sectionWidgets: (barConfig && barConfig.sectionWidgets) || ({ left: [], center: [], right: [] })
  readonly property int outerPadding: Colors.spacingM
  readonly property int sectionSpacing: Colors.spacingS
  readonly property int runtimeSpacing: Colors.spacingM
  readonly property real computedOpacity: (barConfig && barConfig.opacity !== undefined) ? barConfig.opacity : Config.barOpacity
  readonly property bool floatingBar: barConfig && barConfig.floating !== undefined ? !!barConfig.floating : Config.barFloating
  readonly property bool autoHide: !!(barConfig && barConfig.autoHide)
  readonly property int autoHideDelay: (barConfig && barConfig.autoHideDelay) || 300
  readonly property bool noBackground: !!(barConfig && barConfig.noBackground)
  readonly property bool maximizeDetect: !!(barConfig && barConfig.maximizeDetect)
  readonly property string scrollBehavior: (barConfig && barConfig.scrollBehavior) || "none"
  readonly property bool shadowEnabled: !!(barConfig && barConfig.shadowEnabled)
  readonly property real shadowOpacity: (barConfig && barConfig.shadowOpacity !== undefined) ? barConfig.shadowOpacity : 0.3
  readonly property real barFontScale: (barConfig && barConfig.fontScale !== undefined) ? barConfig.fontScale : 1.0
  readonly property real barIconScale: (barConfig && barConfig.iconScale !== undefined) ? barConfig.iconScale : 1.0
  property bool _autoHidden: false
  property bool _hovered: false
  // Expose to shell.qml for exclusiveZone control
  readonly property bool isAutoHidden: _autoHidden
  readonly property string fullCavaData: {
    var vals = (SpectrumService && SpectrumService.values) ? SpectrumService.values : [];
    var blocks = ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"];
    var s = "";
    for (var i = 0; i < vals.length; ++i) {
      var idx = Math.min(7, Math.floor(vals[i] * 8));
      s += blocks[Math.max(0, idx)];
    }
    return s;
  }

  signal surfaceRequested(string surfaceId, var context)

  implicitHeight: vertical ? 0 : thickness
  implicitWidth: vertical ? Math.max(thickness, Math.max(leftColumn.implicitWidth, Math.max(centerColumn.implicitWidth, rightColumn.implicitWidth)) + outerPadding * 2) : 0

  function sectionItems(section) {
    var items = sectionWidgets && sectionWidgets[section] ? sectionWidgets[section] : [];
    return items;
  }

  function widgetSettings(widgetInstance) {
    return widgetInstance && widgetInstance.settings ? widgetInstance.settings : {};
  }

  function requestSurface(surfaceId, item) {
    if (!item) return;
    var topLeft = item.mapToItem(root, 0, 0);
    root.surfaceRequested(surfaceId, {
      surfaceId: surfaceId,
      barId: barConfig ? barConfig.id : "",
      position: position,
      screen: screenRef,
      screenName: Config.screenName(screenRef),
      triggerRect: {
        x: topLeft.x,
        y: topLeft.y,
        width: item.width,
        height: item.height
      }
    });
  }

  function isSurfaceActive(surfaceId) {
    return root.activeSurfaceId === surfaceId;
  }

  function compactPercentText(value) {
    return Math.round(Math.max(0, Math.min(1, Number(value) || 0)) * 100) + "%";
  }

  function widgetValueStyle(widgetInstance, widgetType) {
    var settings = widgetSettings(widgetInstance);
    var fallback = widgetType === "ramStatus" ? "usage" : "percent";
    var style = String(settings.valueStyle || fallback);
    if (widgetType === "ramStatus")
      return ["usage", "percent"].indexOf(style) !== -1 ? style : fallback;
    return ["percent", "usage", "usageTemp"].indexOf(style) !== -1 ? style : fallback;
  }

  function statDisplayText(widgetType, widgetInstance) {
    var style = widgetValueStyle(widgetInstance, widgetType);
    if (widgetType === "cpuStatus") {
      if (style === "usageTemp") return SystemStatus.cpuUsage + " • " + SystemStatus.cpuTemp;
      return SystemStatus.cpuUsage;
    }
    if (widgetType === "ramStatus") {
      if (style === "percent") return compactPercentText(SystemStatus.ramPercent);
      return SystemStatus.ramUsage;
    }
    if (widgetType === "gpuStatus") {
      if (style === "usageTemp") return SystemStatus.gpuUsage + " • " + SystemStatus.gpuTemp;
      return SystemStatus.gpuUsage;
    }
    return "";
  }

  function compactStatDisplayText(widgetType, widgetInstance) {
    var style = widgetValueStyle(widgetInstance, widgetType);
    if (style === "percent")
      return statDisplayText(widgetType, widgetInstance);

    if (widgetType === "ramStatus") {
      var ramUsage = statDisplayText(widgetType, widgetInstance);
      return ramUsage.length <= 5 ? ramUsage : compactPercentText(SystemStatus.ramPercent);
    }

    if (style === "usageTemp")
      return widgetType === "cpuStatus" ? SystemStatus.cpuUsage : SystemStatus.gpuUsage;

    var usage = statDisplayText(widgetType, widgetInstance);
    return usage.length <= 5 ? usage : (widgetType === "cpuStatus" ? SystemStatus.cpuUsage : SystemStatus.gpuUsage);
  }

  function statTooltipText(widgetType, widgetInstance) {
    if (widgetType === "cpuStatus")
      return "CPU " + statDisplayText(widgetType, widgetInstance);
    if (widgetType === "ramStatus")
      return "RAM " + statDisplayText(widgetType, widgetInstance) + " • " + compactPercentText(SystemStatus.ramPercent);
    if (widgetType === "gpuStatus")
      return "GPU " + statDisplayText(widgetType, widgetInstance);
    return "";
  }

  function widgetDisplayMode(widgetInstance) {
    var settings = widgetSettings(widgetInstance);
    var mode = String(settings.displayMode || "auto");
    return ["auto", "full", "compact", "icon"].indexOf(mode) !== -1 ? mode : "auto";
  }

  function isCompactStatWidget(widgetInstance) {
    var mode = widgetDisplayMode(widgetInstance);
    if (mode === "compact") return true;
    if (mode === "icon" || mode === "full") return false;
    return root.vertical;
  }

  function isIconOnlyStatWidget(widgetInstance) {
    return widgetDisplayMode(widgetInstance) === "icon";
  }

  function componentForWidget(widgetType) {
    if (widgetType === "logo") return logoComponent;
    if (widgetType === "workspaces") return workspacesComponent;
    if (widgetType === "taskbar") return taskbarComponent;
    if (widgetType === "cpuStatus") return cpuStatusComponent;
    if (widgetType === "ramStatus") return ramStatusComponent;
    if (widgetType === "gpuStatus") return gpuStatusComponent;
    if (widgetType === "systemMonitor") return legacySystemMonitorComponent;
    if (widgetType === "dateTime") return dateTimeComponent;
    if (widgetType === "mediaBar") return mediaBarComponent;
    if (widgetType === "updates") return updatesComponent;
    if (widgetType === "cava") return cavaComponent;
    if (widgetType === "idleInhibitor") return idleInhibitorComponent;
    if (widgetType === "weather") return weatherComponent;
    if (widgetType === "network") return networkComponent;
    if (widgetType === "bluetooth") return bluetoothComponent;
    if (widgetType === "audio") return audioComponent;
    if (widgetType === "music") return musicComponent;
    if (widgetType === "privacy") return privacyComponent;
    if (widgetType === "recording") return recordingComponent;
    if (widgetType === "battery") return batteryComponent;
    if (widgetType === "printer") return printerComponent;
    if (widgetType === "notepad") return notepadComponent;
    if (widgetType === "controlCenter") return controlCenterComponent;
    if (widgetType === "tray") return trayComponent;
    if (widgetType === "clipboard") return clipboardComponent;
    if (widgetType === "notifications") return notificationsComponent;
    if (widgetType === "spacer") return spacerComponent;
    if (widgetType === "separator") return separatorComponent;
    if (String(widgetType || "").indexOf("plugin:") === 0) return pluginComponent;
    return unknownComponent;
  }

  // ── Auto-hide logic ─────────────────────────
  Timer {
    id: autoHideTimer
    interval: root.autoHideDelay
    onTriggered: {
      if (root.autoHide && !root._hovered)
        root._autoHidden = true;
    }
  }

  onAutoHideChanged: {
    if (!autoHide) root._autoHidden = false;
  }

  on_HoveredChanged: {
    if (_hovered) {
      root._autoHidden = false;
      autoHideTimer.stop();
    } else if (root.autoHide) {
      autoHideTimer.restart();
    }
  }

  // Hover sensor for auto-hide (covers the full bar area)
  HoverHandler {
    id: barHoverHandler
    onHoveredChanged: root._hovered = barHoverHandler.hovered
  }

  // Auto-hide: slide bar off-screen and fade out
  property real _slideOffset: root._autoHidden
    ? (root.position === "bottom" ? root.thickness : -root.thickness)
    : 0

  Behavior on _slideOffset {
    NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
  }

  opacity: root._autoHidden ? 0 : 1
  Behavior on opacity {
    NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
  }

  transform: Translate { y: root._slideOffset }

  // ── Scroll behavior ───────────────────────────
  WheelHandler {
    enabled: root.scrollBehavior !== "none"
    onWheel: event => {
      var delta = event.angleDelta.y;
      if (delta === 0) return;
      if (root.scrollBehavior === "workspace") {
        if (delta > 0)
          CompositorAdapter.focusWorkspace("e-1");
        else
          CompositorAdapter.focusWorkspace("e+1");
      } else if (root.scrollBehavior === "volume") {
        var step = delta > 0 ? 0.02 : -0.02;
        AudioService.setVolume("@DEFAULT_AUDIO_SINK@", Math.max(0, Math.min(1, AudioService.outputVolume + step)));
      }
    }
  }

  // ── Shadow (layered for soft-shadow effect) ──
  Repeater {
    model: root.shadowEnabled ? 3 : 0
    Rectangle {
      readonly property real spread: [2, 5, 8][index]
      readonly property real baseAlpha: [0.5, 0.25, 0.1][index]
      visible: !root._autoHidden
      anchors.fill: parent
      anchors.margins: -spread
      z: -1 - index
      radius: floatingBar ? Colors.radiusMedium + spread : 0
      color: Qt.rgba(0, 0, 0, root.shadowOpacity * baseAlpha)
    }
  }

  // ── Background ────────────────────────────────
  Rectangle {
    anchors.fill: parent
    color: root.noBackground ? "transparent" : Colors.bgGlass
    opacity: root.noBackground ? 0 : computedOpacity
    radius: floatingBar ? Colors.radiusMedium : 0
    border.color: (floatingBar && !root.noBackground) ? Colors.border : "transparent"
    border.width: (floatingBar && !root.noBackground) ? 1 : 0
  }

  Row {
    id: leftSection
    visible: !vertical
    anchors.left: parent.left
    anchors.leftMargin: outerPadding
    anchors.verticalCenter: parent.verticalCenter
    spacing: runtimeSpacing
    Repeater {
      model: root.sectionItems("left")
      delegate: widgetLoaderDelegate
    }
  }

  Row {
    id: centerSection
    visible: !vertical
    anchors.centerIn: parent
    spacing: runtimeSpacing
    Repeater {
      model: root.sectionItems("center")
      delegate: widgetLoaderDelegate
    }
  }

  Row {
    id: rightSection
    visible: !vertical
    anchors.right: parent.right
    anchors.rightMargin: outerPadding
    anchors.verticalCenter: parent.verticalCenter
    spacing: runtimeSpacing
    Repeater {
      model: root.sectionItems("right")
      delegate: widgetLoaderDelegate
    }
  }

  Column {
    id: leftColumn
    visible: vertical
    anchors.top: parent.top
    anchors.topMargin: outerPadding
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: runtimeSpacing
    Repeater {
      model: root.sectionItems("left")
      delegate: widgetLoaderDelegate
    }
  }

  Column {
    id: centerColumn
    visible: vertical
    anchors.centerIn: parent
    spacing: runtimeSpacing
    Repeater {
      model: root.sectionItems("center")
      delegate: widgetLoaderDelegate
    }
  }

  Column {
    id: rightColumn
    visible: vertical
    anchors.bottom: parent.bottom
    anchors.bottomMargin: outerPadding
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: runtimeSpacing
    Repeater {
      model: root.sectionItems("right")
      delegate: widgetLoaderDelegate
    }
  }

  Component {
    id: widgetLoaderDelegate
    Loader {
      required property var modelData
      property var widgetInstance: modelData
      active: !!widgetInstance && widgetInstance.enabled !== false
      sourceComponent: root.componentForWidget(widgetInstance ? widgetInstance.widgetType : "")
      onLoaded: {
        if (item && item.widgetInstance !== undefined)
          item.widgetInstance = widgetInstance;
      }
    }
  }

  Component {
    id: logoComponent
    Logo {
      property var widgetInstance: null
      tooltipText: "Application launcher"
      anchorWindow: root.anchorWindow
    }
  }

  Component {
    id: workspacesComponent
    Workspaces {
      property var widgetInstance: null
      vertical: root.vertical
      anchorWindow: root.anchorWindow
    }
  }

  Component {
    id: taskbarComponent
    Taskbar {
      property var widgetInstance: null
      vertical: root.vertical
      anchorWindow: root.anchorWindow
    }
  }

  Component {
    id: cpuStatusComponent
    StatPill {
      property var widgetInstance: null
      statKey: "cpuStatus"; icon: ""; iconColor: Colors.primary; label: "CPU"
      anchorWindow: root.anchorWindow
      compact: root.isCompactStatWidget(widgetInstance)
      iconOnly: root.isIconOnlyStatWidget(widgetInstance)
      valueText: root.statDisplayText("cpuStatus", widgetInstance)
      compactValueText: root.compactStatDisplayText("cpuStatus", widgetInstance)
      tooltipText: root.statTooltipText("cpuStatus", widgetInstance)
      isActive: root.isSurfaceActive("systemStatsMenu")
      onClicked: root.requestSurface("systemStatsMenu", this)
    }
  }

  Component {
    id: ramStatusComponent
    StatPill {
      property var widgetInstance: null
      statKey: "ramStatus"; icon: "󰍛"; iconColor: Colors.accent; label: "RAM"
      anchorWindow: root.anchorWindow
      compact: root.isCompactStatWidget(widgetInstance)
      iconOnly: root.isIconOnlyStatWidget(widgetInstance)
      valueText: root.statDisplayText("ramStatus", widgetInstance)
      compactValueText: root.compactStatDisplayText("ramStatus", widgetInstance)
      tooltipText: root.statTooltipText("ramStatus", widgetInstance)
      isActive: root.isSurfaceActive("systemStatsMenu")
      onClicked: root.requestSurface("systemStatsMenu", this)
    }
  }

  Component {
    id: gpuStatusComponent
    StatPill {
      property var widgetInstance: null
      statKey: "gpuStatus"; icon: "󰢮"; iconColor: Colors.secondary; label: "GPU"
      anchorWindow: root.anchorWindow
      compact: root.isCompactStatWidget(widgetInstance)
      iconOnly: root.isIconOnlyStatWidget(widgetInstance)
      valueText: root.statDisplayText("gpuStatus", widgetInstance)
      compactValueText: root.compactStatDisplayText("gpuStatus", widgetInstance)
      tooltipText: root.statTooltipText("gpuStatus", widgetInstance)
      isActive: root.isSurfaceActive("systemStatsMenu")
      onClicked: root.requestSurface("systemStatsMenu", this)
    }
  }

  Component {
    id: legacySystemMonitorComponent
    SystemMonitor {
      property var widgetInstance: null
      anchorWindow: root.anchorWindow
      isActive: root.isSurfaceActive("systemStatsMenu")
      onStatsClicked: root.requestSurface("systemStatsMenu", this)
    }
  }

  Component {
    id: dateTimeComponent
    Item {
      id: dateTimeRoot
      property var widgetInstance: null
      implicitWidth: dateTimePill.implicitWidth
      implicitHeight: dateTimePill.implicitHeight

      SystemClock {
        id: centerClock
        precision: Config.timeShowSeconds ? SystemClock.Seconds : SystemClock.Minutes
      }

      SharedWidgets.BarPill {
        id: dateTimePill
        anchors.centerIn: parent
        isActive: root.isSurfaceActive("dateTimeMenu")
        anchorWindow: root.anchorWindow
        tooltipText: Qt.formatDateTime(centerClock.date, "dddd, MMMM d yyyy")
        onClicked: root.requestSurface("dateTimeMenu", this)

        Text {
          visible: root.vertical
          text: "󰥔"
          color: Colors.text
          font.pixelSize: Colors.fontSizeLarge
          font.family: Colors.fontMono
        }

        Row {
          visible: !root.vertical
          spacing: Colors.spacingXS

          Text {
            color: Colors.text
            font.pixelSize: Colors.fontSizeMedium
            font.weight: Font.Bold
            text: Qt.formatDateTime(
              centerClock.date,
              Config.timeUse24Hour
                ? (Config.timeShowSeconds ? "HH:mm:ss" : "HH:mm")
                : (Config.timeShowSeconds ? "hh:mm:ss AP" : "hh:mm AP")
            )
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            visible: Config.timeShowBarDate
            color: Colors.textSecondary
            font.pixelSize: Colors.fontSizeSmall
            font.weight: Font.Medium
            text: {
              if (Config.timeBarDateStyle === "month_day")
                return Qt.formatDateTime(centerClock.date, "MMM d");
              if (Config.timeBarDateStyle === "weekday_month_day")
                return Qt.formatDateTime(centerClock.date, "ddd MMM d");
              return Qt.formatDateTime(centerClock.date, "ddd d");
            }
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }
    }
  }

  Component {
    id: mediaBarComponent
    SharedWidgets.MediaBar {
      property var widgetInstance: null
      vertical: root.vertical
      anchorWindow: root.anchorWindow
    }
  }

  Component {
    id: updatesComponent
    Item {
      id: updatesRoot
      property var widgetInstance: null
      property string updatesIcon: "󰚰"
      property string updatesCount: "0"
      implicitWidth: updatesPill.implicitWidth
      implicitHeight: updatesPill.implicitHeight

      SharedWidgets.CommandPoll {
        id: updatePoll
        interval: 600000
        running: updatesRoot.visible
        command: ["sh", "-c",
          "nix=$(cat \"${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/updates/nixos\" 2>/dev/null || echo 0); "
          + "flat=$(cat \"${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/updates/flatpak\" 2>/dev/null || echo 0); "
          + "total=$(( (nix > 0 ? nix : 0) + (flat > 0 ? flat : 0) )); "
          + "echo $total"
        ]
        parse: function(out) { return parseInt(String(out || "").trim(), 10) || 0 }
        onUpdated: {
          var count = updatePoll.value || 0;
          updatesRoot.updatesCount = count > 0 ? count.toString() : "0";
          updatesRoot.updatesIcon = count > 0 ? "󰮯" : "󰚰";
        }
      }

      SharedWidgets.BarPill {
        id: updatesPill
        visible: updatesRoot.updatesCount !== "0" && updatesRoot.updatesCount !== ""
        anchors.centerIn: parent
        anchorWindow: root.anchorWindow
        tooltipText: "System updates"

        Row {
          spacing: Colors.spacingXS
          Text { text: updatesRoot.updatesIcon; color: Colors.accent; font.pixelSize: Colors.fontSizeXL; font.family: Colors.fontMono; anchors.verticalCenter: parent.verticalCenter }
          Text { visible: !root.vertical; text: updatesRoot.updatesCount; color: Colors.text; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
        }
      }
    }
  }

  Component {
    id: cavaComponent
    Item {
      id: cavaRoot
      property var widgetInstance: null
      readonly property string cavaBarText: {
        var full = root.fullCavaData || "";
        return full.length >= 8 ? full.substring(0, 8) : (full.length > 0 ? full : "▁▂▃▄▅▆▇█");
      }
      visible: !root.vertical
      implicitWidth: cavaPill.implicitWidth
      implicitHeight: cavaPill.implicitHeight

      SharedWidgets.BarPill {
        id: cavaPill
        anchors.centerIn: parent
        isActive: root.isSurfaceActive("cavaPopup")
        normalColor: "transparent"
        anchorWindow: root.anchorWindow
        tooltipText: "Audio visualizer"
        cursorShape: Qt.PointingHandCursor
        clip: true
        onClicked: root.requestSurface("cavaPopup", this)

        Text {
          text: cavaRoot.cavaBarText
          color: Colors.primary
          font.pixelSize: Colors.fontSizeMedium
        }
      }
    }
  }

  Component {
    id: idleInhibitorComponent
    Item {
      id: inhibitorRoot
      property var widgetInstance: null
      property bool inhibitorActive: false
      implicitWidth: inhibitorPill.implicitWidth
      implicitHeight: inhibitorPill.implicitHeight

      SharedWidgets.CommandPoll {
        id: inhibitorPoll
        interval: 5000
        running: inhibitorRoot.visible
        command: ["sh", "-c", "[ -f /tmp/wayland_idle_inhibitor.pid ] && echo true || echo false"]
        parse: function(out) { return String(out || "").trim() === "true" }
        onUpdated: inhibitorRoot.inhibitorActive = inhibitorPoll.value
      }

      SharedWidgets.BarPill {
        id: inhibitorPill
        anchors.centerIn: parent
        anchorWindow: root.anchorWindow
        normalColor: inhibitorRoot.inhibitorActive ? Colors.withAlpha(Colors.primary, 0.2) : Colors.bgWidget
        hoverColor: inhibitorRoot.inhibitorActive ? Colors.withAlpha(Colors.primary, 0.35) : Colors.highlightLight
        tooltipText: inhibitorRoot.inhibitorActive ? "Idle inhibitor enabled" : "Idle inhibitor"
        onClicked: {
          Quickshell.execDetached(["qs-inhibitor"]);
          inhibitorCheckTimer.restart();
        }

        Text {
          text: "󰒲"
          color: inhibitorRoot.inhibitorActive ? Colors.primary : Colors.text
          font.pixelSize: Colors.fontSizeXL
          font.family: Colors.fontMono
        }

        Timer {
          id: inhibitorCheckTimer
          interval: 500
          running: false
          repeat: false
          onTriggered: inhibitorPoll.poll()
        }
      }
    }
  }

  Component {
    id: weatherComponent
    SharedWidgets.BarPill {
      property var widgetInstance: null
      isActive: root.isSurfaceActive("weatherMenu")
      anchorWindow: root.anchorWindow
      tooltipText: WeatherService.condition || "Weather"
      onClicked: root.requestSurface("weatherMenu", this)

      Row {
        spacing: Colors.spacingS

        Text {
          text: Colors.weatherIcon(WeatherService.condition)
          color: Colors.accent
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeLarge
          anchors.verticalCenter: parent.verticalCenter
        }

        Text {
          visible: !root.vertical
          text: WeatherService.temp
          color: Colors.text
          font.pixelSize: Colors.fontSizeSmall
          font.weight: Font.DemiBold
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }

  Component {
    id: networkComponent
    SharedWidgets.BarPill {
      property var widgetInstance: null
      isActive: root.isSurfaceActive("networkMenu")
      anchorWindow: root.anchorWindow
      tooltipText: networkWidget.tooltipText
      onClicked: root.requestSurface("networkMenu", this)

      Row {
        spacing: Colors.spacingS
        SharedWidgets.NetworkWidget {
          id: networkWidget
          iconOnly: root.vertical
        }
      }
    }
  }

  Component {
    id: bluetoothComponent
    SharedWidgets.BarPill {
      property var widgetInstance: null
      isActive: root.isSurfaceActive("bluetoothMenu")
      anchorWindow: root.anchorWindow
      tooltipText: {
        if (!Bluetooth.defaultAdapter || !Bluetooth.defaultAdapter.enabled) return "Bluetooth off";
        var count = 0;
        for (var i = 0; i < Bluetooth.devices.values.length; i++) {
          if (Bluetooth.devices.values[i].connected) count++;
        }
        return count > 0 ? count + " device" + (count > 1 ? "s" : "") + " connected" : "Bluetooth";
      }
      onClicked: root.requestSurface("bluetoothMenu", this)

      Row {
        spacing: Colors.spacingS

        Text {
          text: (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) ? "󰂯" : "󰂲"
          color: (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) ? Colors.primary : Colors.textDisabled
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeLarge
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }

  Component {
    id: audioComponent
    SharedWidgets.BarPill {
      property var widgetInstance: null
      isActive: root.isSurfaceActive("audioMenu")
      anchorWindow: root.anchorWindow
      tooltipText: audioWidget.tooltipText
      onClicked: root.requestSurface("audioMenu", this)

      Row {
        spacing: Colors.spacingS
        SharedWidgets.AudioWidget {
          id: audioWidget
          iconOnly: root.vertical
        }
      }
    }
  }

  Component {
    id: musicComponent
    SharedWidgets.BarPill {
      property var widgetInstance: null
      visible: SystemStatus.hasActivePlayer
      isActive: root.isSurfaceActive("musicMenu")
      anchorWindow: root.anchorWindow
      tooltipText: {
        var players = SystemStatus.activeMprisPlayers;
        if (!players || players.length === 0) return "Music controls";
        var p = players[0];
        return (p.trackTitle || "Music") + (p.trackArtist ? " - " + p.trackArtist : "");
      }
      onClicked: root.requestSurface("musicMenu", this)

      Behavior on width { NumberAnimation { duration: Colors.durationSlow; easing.type: Easing.OutCubic } }

      Row {
        spacing: Colors.spacingS

        Text {
          text: "󰝚"
          color: Colors.primary
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeLarge
          anchors.verticalCenter: parent.verticalCenter
        }

        Item {
          visible: !root.vertical
          width: visible ? Math.min(musicTitleText.contentWidth, 100) : 0
          height: 20
          clip: true
          anchors.verticalCenter: parent.verticalCenter

          Text {
            id: musicTitleText
            text: SystemStatus.activeMprisPlayers.length > 0 ? (SystemStatus.activeMprisPlayers[0].trackTitle || "") : ""
            color: Colors.text
            font.pixelSize: Colors.fontSizeSmall
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }
    }
  }

  Component {
    id: privacyComponent
    SharedWidgets.BarPill {
      property var widgetInstance: null
      visible: PrivacyService.anyActive
      isActive: root.isSurfaceActive("privacyMenu")
      anchorWindow: root.anchorWindow
      activeColor: Colors.withAlpha(Colors.warning, 0.22)
      normalColor: Colors.withAlpha(Colors.warning, 0.15)
      hoverColor: Colors.withAlpha(Colors.warning, 0.28)
      tooltipText: PrivacyService.activeLabel || "Privacy"
      onClicked: root.requestSurface("privacyMenu", this)

      Behavior on width { NumberAnimation { duration: Colors.durationNormal; easing.type: Easing.OutCubic } }

      Row {
        spacing: Colors.spacingXS

        Rectangle {
          width: 7; height: 7; radius: 3.5
          color: Colors.warning
          anchors.verticalCenter: parent.verticalCenter
          SequentialAnimation on opacity {
            running: PrivacyService.anyActive
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 0.25; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { from: 0.25; to: 1.0; duration: 700; easing.type: Easing.InOutSine }
          }
        }

        Text {
          text: PrivacyService.activeIcon
          color: Colors.warning
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeLarge
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }

  Component {
    id: recordingComponent
    SharedWidgets.BarPill {
      property var widgetInstance: null
      visible: SystemStatus.isRecording
      isActive: root.isSurfaceActive("recordingMenu")
      anchorWindow: root.anchorWindow
      activeColor: Colors.withAlpha(Colors.error, 0.22)
      normalColor: Colors.withAlpha(Colors.error, 0.15)
      hoverColor: Colors.withAlpha(Colors.error, 0.25)
      tooltipText: "Screen recording in progress"
      onClicked: root.requestSurface("recordingMenu", this)

      Row {
        spacing: Colors.spacingS

        Rectangle {
          width: 8; height: 8; radius: 4
          color: Colors.error
          anchors.verticalCenter: parent.verticalCenter
          SequentialAnimation on opacity {
            running: SystemStatus.isRecording
            loops: Animation.Infinite
            NumberAnimation { from: 1.0; to: 0.3; duration: 600 }
            NumberAnimation { from: 0.3; to: 1.0; duration: 600 }
          }
        }

        Text {
          visible: !root.vertical
          text: "REC"
          color: Colors.error
          font.pixelSize: Colors.fontSizeXS
          font.weight: Font.Bold
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }

  Component {
    id: batteryComponent
    SharedWidgets.BarPill {
      property var widgetInstance: null
      visible: batteryWidget.showBattery
      isActive: root.isSurfaceActive("batteryMenu")
      anchorWindow: root.anchorWindow
      tooltipText: batteryWidget.tooltipText
      onClicked: root.requestSurface("batteryMenu", this)

      Row {
        spacing: Colors.spacingXS
        SharedWidgets.BatteryWidget {
          id: batteryWidget
          iconOnly: root.vertical
        }
      }
    }
  }

  Component {
    id: printerComponent
    SharedWidgets.BarPill {
      property var widgetInstance: null
      visible: PrinterService.hasPrinters
      isActive: root.isSurfaceActive("printerMenu")
      anchorWindow: root.anchorWindow
      tooltipText: PrinterService.activeJobs > 0
        ? PrinterService.activeJobs + " print job" + (PrinterService.activeJobs !== 1 ? "s" : "") + " active"
        : (PrinterService.defaultPrinter ? PrinterService.defaultPrinter : "Printers")
      onClicked: root.requestSurface("printerMenu", this)

      Behavior on width { NumberAnimation { duration: Colors.durationNormal; easing.type: Easing.OutCubic } }

      Row {
        spacing: Colors.spacingXS

        Text {
          text: "󰐪"
          color: PrinterService.activeJobs > 0 ? Colors.warning : Colors.text
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeLarge
          anchors.verticalCenter: parent.verticalCenter
          Behavior on color { ColorAnimation { duration: Colors.durationNormal } }
        }

        Rectangle {
          visible: PrinterService.activeJobs > 0 && !root.vertical
          width: printerJobsBadge.contentWidth + 8
          height: 16
          radius: Colors.radiusXS
          color: Colors.withAlpha(Colors.warning, 0.20)
          anchors.verticalCenter: parent.verticalCenter

          Text {
            id: printerJobsBadge
            anchors.centerIn: parent
            text: PrinterService.activeJobs
            color: Colors.warning
            font.pixelSize: Colors.fontSizeXS
            font.weight: Font.Bold
          }
        }
      }
    }
  }

  Component {
    id: notepadComponent
    SharedWidgets.BarPill {
      property var widgetInstance: null
      isActive: root.isSurfaceActive("notepad")
      anchorWindow: root.anchorWindow
      tooltipText: "Notepad"
      onClicked: root.requestSurface("notepad", this)

      Text {
        color: Colors.text
        font.pixelSize: Colors.fontSizeLarge
        font.family: Colors.fontMono
        text: "󰠮"
      }
    }
  }

  Component {
    id: controlCenterComponent
    SharedWidgets.BarPill {
      property var widgetInstance: null
      isActive: root.isSurfaceActive("controlCenter")
      anchorWindow: root.anchorWindow
      tooltipText: "System controls"
      onClicked: root.requestSurface("controlCenter", this)

      Text {
        color: Colors.text
        font.pixelSize: Colors.fontSizeXL
        font.family: Colors.fontMono
        text: "󰒓"
      }
    }
  }

  Component {
    id: trayComponent
    SharedWidgets.TrayWidget {
      property var widgetInstance: null
      vertical: root.vertical
      anchorWindow: root.anchorWindow
    }
  }

  Component {
    id: clipboardComponent
    SharedWidgets.BarPill {
      property var widgetInstance: null
      isActive: root.isSurfaceActive("clipboardMenu")
      anchorWindow: root.anchorWindow
      tooltipText: "Clipboard history"
      onClicked: root.requestSurface("clipboardMenu", this)

      Text {
        text: "󰅍"
        color: Colors.text
        font.family: Colors.fontMono
        font.pixelSize: Colors.fontSizeXL
      }
    }
  }

  Component {
    id: notificationsComponent
    SharedWidgets.BarPill {
      id: notifPill
      property var widgetInstance: null
      isActive: root.isSurfaceActive("notifCenter")
      anchorWindow: root.anchorWindow
      tooltipText: root.manager && root.manager.dndEnabled ? "Notifications paused" : "Notifications"
      onClicked: root.requestSurface("notifCenter", this)

      readonly property bool hasDnd: !!(root.manager && root.manager.dndEnabled)
      readonly property bool hasUnread: !!(root.manager && root.manager.notifications && root.manager.notifications.count > 0)

      Text {
        color: Colors.text
        font.pixelSize: Colors.fontSizeXL
        font.family: Colors.fontMono
        text: notifPill.hasDnd ? "󰂛" : "󰂚"
      }

      Rectangle {
        parent: notifPill
        width: 8
        height: 8
        radius: 4
        color: Colors.error
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 2
        anchors.rightMargin: 2
        visible: notifPill.hasUnread && !notifPill.hasDnd
        z: 10
      }
    }
  }

  Component {
    id: spacerComponent
    Item {
      property var widgetInstance: null
      readonly property int spacerSize: {
        var settings = root.widgetSettings(widgetInstance);
        return Math.max(8, parseInt(settings.size !== undefined ? settings.size : 24, 10) || 24);
      }
      width: root.vertical ? 1 : spacerSize
      height: root.vertical ? spacerSize : 1
      implicitWidth: width
      implicitHeight: height
    }
  }

  Component {
    id: separatorComponent
    Rectangle {
      property var widgetInstance: null
      implicitWidth: root.vertical ? Math.max(24, root.thickness - 8) : 1
      implicitHeight: root.vertical ? 1 : 20
      width: implicitWidth
      height: implicitHeight
      radius: 1
      color: Colors.border
      opacity: 0.8
    }
  }

  Component {
    id: pluginComponent
    Loader {
      property var widgetInstance: null
      readonly property var pluginMeta: BarWidgetRegistry.pluginByWidgetType(widgetInstance ? widgetInstance.widgetType : "")
      source: pluginMeta ? pluginMeta.path + pluginMeta.entryFile : ""
      onStatusChanged: {
        if (status === Loader.Error && widgetInstance)
          console.warn("BarWidgetRegistry: failed to load plugin widget " + widgetInstance.widgetType + " from " + source);
        if (status === Loader.Ready && item && pluginMeta) {
          var api = PluginService.getPluginAPI(pluginMeta.id);
          if (api && item.hasOwnProperty("pluginApi"))
            item.pluginApi = api;
          if (item.hasOwnProperty("pluginManifest"))
            item.pluginManifest = pluginMeta;
          if (item.hasOwnProperty("pluginService"))
            item.pluginService = PluginService;
        }
      }
    }
  }

  Component {
    id: unknownComponent
    SharedWidgets.BarPill {
      property var widgetInstance: null
      anchorWindow: root.anchorWindow
      enabled: false
      tooltipText: "Unknown widget: " + (widgetInstance ? widgetInstance.widgetType : "")
      Text {
        text: "?"
        color: Colors.textDisabled
        font.pixelSize: Colors.fontSizeMedium
      }
    }
  }
}
