import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../../services"
import "../../../widgets"

Scope {
  id: root
  property bool _destroyed: false
  property bool shouldShowOsd: false
  property string workspaceName: ""
  property bool isSpecial: false
  property bool initialized: false
  property string _lastWorkspaceName: ""

  readonly property int _displayMs: 1500

  Timer {
    id: hideTimer
    interval: root._displayMs
    onTriggered: root.shouldShowOsd = false
  }

  property string specialIcon: ""

  function _specialWorkspaceIcon(shortName) {
    var lower = shortName.toLowerCase();
    if (lower === "scratchpad") return "󱂬";
    if (lower === "communication" || lower === "chat") return "󰍡";
    if (lower === "music" || lower === "media") return "󰎆";
    if (lower === "terminal" || lower === "term") return "";
    if (lower === "browser" || lower === "web") return "󰖟";
    if (lower === "mail" || lower === "email") return "󰇰";
    return "";
  }

  function updateWorkspace(name) {
    if (!name || name === root._lastWorkspaceName) return;
    root._lastWorkspaceName = name;
    root.workspaceName = name;
    root.isSpecial = root.workspaceName.startsWith("special");
    if (root.isSpecial) {
      var shortName = root.workspaceName.substring(8);
      root.specialIcon = _specialWorkspaceIcon(shortName);
      root.workspaceName = shortName.charAt(0).toUpperCase() + shortName.substring(1);
    } else {
      root.specialIcon = "";
    }

    if (!root.initialized) {
      root.initialized = true;
      return;
    }
    root.shouldShowOsd = true;
    hideTimer.restart();
  }

  // ── Hyprland reactive path ──────────────────────
  Component.onCompleted: {
    if (CompositorAdapter.isHyprland)
      Hyprland.rawEvent.connect(_onHyprlandEvent);
    // Read initial workspace name
    _readFocusedWorkspaceName();
  }

  Component.onDestruction: {
    _destroyed = true;
    if (CompositorAdapter.isHyprland)
      Hyprland.rawEvent.disconnect(_onHyprlandEvent);
  }

  function _onHyprlandEvent(event) {
    if (event.name === "workspace" || event.name === "workspacev2")
      Qt.callLater(function() { if (root._destroyed) return; _readFocusedWorkspaceName(); });
    if (event.name === "activespecial") {
      var wsName = String(event.data || "").split(",")[0] || "";
      if (wsName.startsWith("special:"))
        updateWorkspace(wsName);
    }
  }

  function _readFocusedWorkspaceName() {
    if (CompositorAdapter.isHyprland) {
      var wsList = Hyprland.workspaces;
      if (!wsList) return;
      var wsValues = wsList.values || wsList;
      for (var i = 0; i < wsValues.length; i++) {
        if (wsValues[i].focused) {
          updateWorkspace(String(wsValues[i].name || wsValues[i].id));
          return;
        }
      }
      return;
    }
    if (CompositorAdapter.isNiri) {
      var all = NiriService.allWorkspaces || [];
      for (var j = 0; j < all.length; j++) {
        if (all[j].is_focused) {
          var ws = all[j];
          updateWorkspace(String(ws.name || ws.idx || ws.id));
          return;
        }
      }
    }
  }

  // ── Niri reactive path ──────────────────────────
  Connections {
    target: NiriService
    enabled: CompositorAdapter.isNiri && NiriService.available
    function onFocusedWorkspaceIdChanged() {
      root._readFocusedWorkspaceName();
    }
  }

  Variants {
    model: Quickshell.screens

    delegate: Component {
      PanelWindow {
        id: osdWindow
        required property ShellScreen modelData
        screen: modelData
        readonly property var edgeMargins: Config.reservedEdgesForScreen(modelData, "")
        readonly property int usableWidth: Math.max(0, screen.width - edgeMargins.left - edgeMargins.right)
        readonly property int usableHeight: Math.max(0, screen.height - edgeMargins.top - edgeMargins.bottom)

        property bool _wantVisible: CompositorAdapter.supportsWorkspaceOsd && root.shouldShowOsd
        visible: osdWindow._wantVisible || osdFadeAnim.running || osdScaleAnim.running

        anchors.top: true
        margins.top: edgeMargins.top + Math.max(0, (usableHeight - implicitHeight) / 2)
        anchors.left: true
        margins.left: edgeMargins.left + Math.max(0, (usableWidth - implicitWidth) / 2)

        exclusiveZone: 0
        implicitWidth: 200
        implicitHeight: 200
        color: "transparent"

        mask: Region { item: content }

        Rectangle {
          id: content
          anchors.fill: parent
          radius: Appearance.radiusLarge
          color: Colors.cardSurface
          border.color: Colors.border
          border.width: 1

          gradient: SurfaceGradient {}

          // Inner highlight
          InnerHighlight { highlightOpacity: 0.15 }

          opacity: _wantVisible ? 1.0 : 0.0
          scale: _wantVisible ? 1.0 : 0.92
          transform: Translate { y: _wantVisible ? 0 : 10 }

          Behavior on opacity {
            NumberAnimation {
              id: osdFadeAnim
              duration: _wantVisible ? 200 : 300
              easing.type: Easing.OutCubic
            }
          }
          Behavior on scale {
            SpringAnimation {
              id: osdScaleAnim
              spring: 4.5
              damping: 0.3
              epsilon: 0.005
            }
          }
          Behavior on transform {
            SpringAnimation {
              spring: 4.0
              damping: 0.35
              epsilon: 0.005
            }
          }

          layer.enabled: osdFadeAnim.running || osdScaleAnim.running

          ColumnLayout {
            anchors.centerIn: parent
            spacing: Appearance.spacingLG

            AppIcon {
              Layout.alignment: Qt.AlignHCenter
              iconSize: 64
              iconName: root.isSpecial ? "view-pin-symbolic" : "view-grid-symbolic"
              fallbackIcon: root.isSpecial ? (root.specialIcon !== "" ? root.specialIcon : "󰐃") : "󰖲"
              visible: !root.isSpecial || root.specialIcon === ""
            }

            Text {
              Layout.alignment: Qt.AlignHCenter
              text: root.specialIcon
              color: Colors.primary
              font.pixelSize: Appearance.fontSizeGigantic
              font.family: Appearance.fontMono
              visible: root.isSpecial && root.specialIcon !== ""
            }

            Text {
              Layout.alignment: Qt.AlignHCenter
              text: root.workspaceName
              color: Colors.text
              font.pixelSize: Appearance.fontSizeDisplay
              font.bold: true
            }
          }
        }
      }
    }
  }
}
