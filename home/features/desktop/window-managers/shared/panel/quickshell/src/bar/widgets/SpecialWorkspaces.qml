import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../services"
import "../../shared"
import "../../widgets" as SharedWidgets

Item {
  id: root
  property bool _destroyed: false

  property var widgetInstance: null
  property var anchorWindow: null
  property bool vertical: false

  readonly property var widgetSettings: widgetInstance && widgetInstance.settings ? widgetInstance.settings : ({})
  readonly property string mainIcon: widgetSettings.mainIcon || "󰖲"
  readonly property string expandDirection: widgetSettings.expandDirection || "right"
  readonly property bool showLabels: widgetSettings.showLabels === true

  visible: CompositorAdapter.isHyprland && hasSpecialWorkspaces

  // ── State tracking ────────────────────────────
  property var specialWorkspaces: []
  property string activeSpecial: ""

  readonly property bool hasSpecialWorkspaces: specialWorkspaces.length > 0
  readonly property bool isOnSpecial: activeSpecial !== ""
  property bool manuallyExpanded: false
  readonly property bool expanded: isOnSpecial || manuallyExpanded

  onIsOnSpecialChanged: {
    if (!isOnSpecial) manuallyExpanded = false;
  }

  // ── Hyprland integration ─────────────────────
  function updateSpecialWorkspaces() {
    if (!CompositorAdapter.isHyprland) {
      specialWorkspaces = [];
      return;
    }
    var wsList = Hyprland.workspaces;
    if (!wsList) { specialWorkspaces = []; return; }

    var wsValues = wsList.values || wsList;
    var specials = [];
    for (var i = 0; i < wsValues.length; i++) {
      var ws = wsValues[i];
      if (!ws || !ws.name) continue;
      var name = String(ws.name);
      if (!name.startsWith("special:")) continue;

      var shortName = name.substring(8);
      var windowCount = 0;
      if (ws.toplevels) {
        var tlArr = ws.toplevels.values || ws.toplevels;
        windowCount = tlArr.length || 0;
      }

      specials.push({
        name: name,
        shortName: shortName,
        windows: windowCount,
        icon: _iconForWorkspace(shortName)
      });
    }
    specials.sort(function(a, b) { return a.shortName.localeCompare(b.shortName); });
    specialWorkspaces = specials;
  }

  function _iconForWorkspace(shortName) {
    var lower = shortName.toLowerCase();
    if (lower === "scratchpad") return "app-generic.svg";
    if (lower === "communication" || lower === "chat") return "chat.svg";
    if (lower === "music" || lower === "media") return "music-note-2.svg";
    if (lower === "terminal" || lower === "term") return "terminal.svg";
    if (lower === "browser" || lower === "web") return "globe-search.svg";
    if (lower === "mail" || lower === "email") return "mail.svg";
    if (lower === "files" || lower === "file") return "folder.svg";
    if (lower === "monitor" || lower === "system") return "board.svg";
    return "apps.svg";
  }

  Connections {
    target: CompositorAdapter.isHyprland ? Hyprland : null
    function onRawEvent(event) {
      if (event.name === "activespecial") {
        var data = String(event.data || "");
        var wsName = data.split(",")[0] || "";
        root.activeSpecial = wsName.startsWith("special:") ? wsName : "";
      }
      if (["createworkspace", "createworkspacev2", "destroyworkspace", "destroyworkspacev2",
           "openwindow", "closewindow", "movewindow"].indexOf(event.name) !== -1) {
        Qt.callLater(function() { if (root._destroyed) return; updateSpecialWorkspaces(); });
      }
    }
  }

  Component.onDestruction: _destroyed = true

  Component.onCompleted: {
    if (CompositorAdapter.isHyprland) {
      updateSpecialWorkspaces();
      try {
        var initial = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.specialWorkspace : null;
        if (initial && initial.name && String(initial.name).startsWith("special:"))
          root.activeSpecial = String(initial.name);
      } catch(e) {}
    }
  }

  // ── Sizing ───────────────────────────────────
  readonly property int pillSize: Config.workspacePillSize === "compact" ? 16 : (Config.workspacePillSize === "large" ? 28 : 20)
  readonly property int pillFont: Config.workspacePillSize === "compact" ? Appearance.fontSizeXS : (Config.workspacePillSize === "large" ? Appearance.fontSizeMedium : Appearance.fontSizeSmall)
  readonly property int pillSpacing: Appearance.spacingSM

  readonly property int expandedCount: expanded ? specialWorkspaces.length : 0
  readonly property real totalSize: pillSize + (expandedCount > 0 ? pillSpacing + expandedCount * pillSize + (expandedCount - 1) * pillSpacing : 0)

  implicitWidth: vertical ? pillSize : totalSize
  implicitHeight: vertical ? totalSize : pillSize

  Behavior on implicitWidth { NumberAnimation { duration: Appearance.durationNormal; easing.type: Easing.OutCubic } }
  Behavior on implicitHeight { NumberAnimation { duration: Appearance.durationNormal; easing.type: Easing.OutCubic } }

  opacity: hasSpecialWorkspaces ? 1.0 : 0.3
  Behavior on opacity { NumberAnimation { duration: Appearance.durationNormal } }

  // ── Layout ───────────────────────────────────
  RowLayout {
    visible: !root.vertical
    anchors.centerIn: parent
    spacing: root.pillSpacing

    // Main button
    Rectangle {
      id: mainBtn
      Layout.alignment: Qt.AlignVCenter
      implicitWidth: root.pillSize
      implicitHeight: root.pillSize
      radius: Appearance.radiusXXS
      color: mainMouse.containsMouse ? Colors.highlightLight : (root.isOnSpecial ? Colors.withAlpha(Colors.primary, 0.2) : Colors.surface)
      border.color: root.isOnSpecial ? Colors.primary : Colors.border
      border.width: 1
      Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }
      Behavior on border.color { enabled: !Colors.isTransitioning; CAnim {} }

      scale: mainMouse.containsMouse ? 1.08 : 1.0
      Behavior on scale { SpringAnimation { spring: 4; damping: 0.3 } }

      Loader {
        anchors.centerIn: parent
        sourceComponent: root.mainIcon.endsWith(".svg") ? _mainSvgV : _mainNerdV
      }
      Component { id: _mainSvgV; SharedWidgets.SvgIcon { source: root.mainIcon; color: root.isOnSpecial ? Colors.primary : Colors.text; size: root.pillFont } }
      Component { id: _mainNerdV; Text { text: root.mainIcon; color: root.isOnSpecial ? Colors.primary : Colors.text; font.pixelSize: root.pillFont; font.family: Appearance.fontMono } }

      MouseArea {
        id: mainMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          if (root.expanded) {
            if (root.isOnSpecial)
              Quickshell.execDetached(["hyprctl", "dispatch", "togglespecialworkspace"]);
            root.manuallyExpanded = false;
          } else {
            root.manuallyExpanded = true;
          }
        }
      }
    }

    // Special workspace pills
    Repeater {
      model: root.specialWorkspaces

      Rectangle {
        id: wsPill
        visible: root.expanded
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: root.showLabels ? Math.max(root.pillSize, wsLabel.implicitWidth + 12) : root.pillSize
        implicitHeight: root.pillSize
        radius: Appearance.radiusXXS
        readonly property bool isFocused: root.activeSpecial === modelData.name

        color: wsHover.containsMouse ? Colors.highlightLight : (isFocused ? Colors.withAlpha(Colors.primary, 0.2) : Colors.surface)
        border.color: isFocused ? Colors.primary : Colors.border
        border.width: isFocused ? 2 : 1
        Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }
        Behavior on border.color { enabled: !Colors.isTransitioning; CAnim {} }

        scale: wsHover.containsMouse ? 1.08 : 1.0
        Behavior on scale { SpringAnimation { spring: 4; damping: 0.3 } }

        Row {
          id: wsLabel
          anchors.centerIn: parent
          spacing: Appearance.spacingXS

          Loader {
            anchors.verticalCenter: parent.verticalCenter
            sourceComponent: String(modelData.icon || "").endsWith(".svg") ? _wsSvg : _wsNerd
          }
          Component { id: _wsSvg; SharedWidgets.SvgIcon { source: modelData.icon; color: wsPill.isFocused ? Colors.primary : Colors.text; size: root.pillFont } }
          Component { id: _wsNerd; Text { text: modelData.icon; color: wsPill.isFocused ? Colors.primary : Colors.text; font.pixelSize: root.pillFont; font.family: Appearance.fontMono } }
          Text {
            visible: root.showLabels
            text: modelData.shortName
            color: wsPill.isFocused ? Colors.primary : Colors.text
            font.pixelSize: root.pillFont
            font.capitalization: Font.Capitalize
          }
        }

        // Window count indicator dots
        Row {
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 1
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: Appearance.spacingXXS
          visible: modelData.windows > 0 && !root.showLabels

          Repeater {
            model: Math.min(modelData.windows, 4)
            Rectangle {
              width: 3; height: 3
              radius: 1.5
              color: wsPill.isFocused ? Colors.primary : Colors.textDisabled
            }
          }
        }

        SharedWidgets.StateLayer {
          anchors.fill: parent
          radius: parent.radius
          hovered: wsHover.containsMouse
          pressed: wsHover.pressed
        }

        MouseArea {
          id: wsHover
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            Quickshell.execDetached(["hyprctl", "dispatch", "togglespecialworkspace", modelData.shortName]);
          }
        }

        SharedWidgets.BarTooltip {
          anchorItem: wsPill
          anchorWindow: root.anchorWindow
          hovered: wsHover.containsMouse
          text: modelData.shortName + (modelData.windows > 0 ? " (" + modelData.windows + " window" + (modelData.windows > 1 ? "s" : "") + ")" : " (empty)")
        }
      }
    }
  }

  // Vertical layout
  ColumnLayout {
    visible: root.vertical
    anchors.centerIn: parent
    spacing: root.pillSpacing

    Rectangle {
      Layout.alignment: Qt.AlignHCenter
      implicitWidth: root.pillSize
      implicitHeight: root.pillSize
      radius: Appearance.radiusXXS
      color: mainMouseV.containsMouse ? Colors.highlightLight : (root.isOnSpecial ? Colors.withAlpha(Colors.primary, 0.2) : Colors.surface)
      border.color: root.isOnSpecial ? Colors.primary : Colors.border
      border.width: 1
      Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }

      Loader {
        anchors.centerIn: parent
        sourceComponent: root.mainIcon.endsWith(".svg") ? _mainSvg : _mainNerd
      }
      Component { id: _mainSvg; SharedWidgets.SvgIcon { source: root.mainIcon; color: root.isOnSpecial ? Colors.primary : Colors.text; size: root.pillFont } }
      Component { id: _mainNerd; Text { text: root.mainIcon; color: root.isOnSpecial ? Colors.primary : Colors.text; font.pixelSize: root.pillFont; font.family: Appearance.fontMono } }

      MouseArea {
        id: mainMouseV
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          if (root.expanded) {
            if (root.isOnSpecial)
              Quickshell.execDetached(["hyprctl", "dispatch", "togglespecialworkspace"]);
            root.manuallyExpanded = false;
          } else {
            root.manuallyExpanded = true;
          }
        }
      }
    }

    Repeater {
      model: root.specialWorkspaces

      Rectangle {
        visible: root.expanded
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: root.pillSize
        implicitHeight: root.pillSize
        radius: Appearance.radiusXXS
        readonly property bool isFocused: root.activeSpecial === modelData.name

        color: wsHoverV.containsMouse ? Colors.highlightLight : (isFocused ? Colors.withAlpha(Colors.primary, 0.2) : Colors.surface)
        border.color: isFocused ? Colors.primary : Colors.border
        border.width: isFocused ? 2 : 1
        Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }

        Loader {
          anchors.centerIn: parent
          sourceComponent: String(modelData.icon || "").endsWith(".svg") ? _wsSvgV : _wsNerdV
        }
        Component { id: _wsSvgV; SharedWidgets.SvgIcon { source: modelData.icon; color: parent.isFocused ? Colors.primary : Colors.text; size: root.pillFont } }
        Component { id: _wsNerdV; Text { text: modelData.icon; color: parent.isFocused ? Colors.primary : Colors.text; font.pixelSize: root.pillFont; font.family: Appearance.fontMono } }

        MouseArea {
          id: wsHoverV
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "togglespecialworkspace", modelData.shortName])
        }
      }
    }
  }
}
