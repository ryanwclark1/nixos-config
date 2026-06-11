import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../shared"
import "../../services"
import "../../services/SearchUtils.js" as SU
import "../../widgets" as SharedWidgets
import "../settings/components"
import "components"

BasePopupMenu {
  id: root
  popupMaxWidth: 480
  compactThreshold: 400
  implicitHeight: compactMode ? 780 : 840
  title: "UniFi Protect"
  subtitle: UnifiProtectService.busy ? "Refreshing..." : _subtitle
  contentSpacing: Appearance.spacingM
  focusOnOpen: true
  initialFocusTarget: searchBar.inputItem

  property var surfaceContext: null
  property string searchQuery: ""

  readonly property string _subtitle: {
    if (UnifiProtectService.status === "unconfigured") return "Set Protect host and API key in settings";
    if (UnifiProtectService.status === "error") return UnifiProtectService.errorMessage;
    var n = UnifiProtectService.onlineCameras;
    var t = UnifiProtectService.totalCameras;
    return n + "/" + t + " cameras online";
  }

  readonly property var filteredCameras: {
    var query = searchQuery.toLowerCase().trim();
    if (!query) return UnifiProtectService.cameras;
    return UnifiProtectService.cameras.filter(function(c) {
      if (!c) return false;
      var text = (String(c.name || "") + " " + String(c.marketName || "") + " " + String(c.type || "")).toLowerCase();
      return text.indexOf(query) !== -1;
    });
  }

  readonly property bool hasCameras: UnifiProtectService.cameras.length > 0
  readonly property bool hasFilteredCameras: filteredCameras.length > 0

  headerExtras: [
    SharedWidgets.IconButton {
      icon: "arrow-clockwise.svg"
      tooltipText: "Refresh cameras"
      onClicked: UnifiProtectService.refresh()
    }
  ]

  // ── Status summary ────────────────────────────
  Rectangle {
    Layout.fillWidth: true
    implicitHeight: statusRow.implicitHeight + 16
    radius: Appearance.radiusMedium
    color: Colors.cardSurface
    border.color: UnifiProtectService.status === "ready" ? Colors.border : Colors.warning
    border.width: 1
    visible: UnifiProtectService.status !== "unconfigured"

    RowLayout {
      id: statusRow
      anchors {
        left: parent.left
        right: parent.right
        top: parent.top
        margins: Appearance.spacingM
      }
      spacing: Appearance.spacingL

      ColumnLayout {
        spacing: Appearance.spacingXXS
        Text {
          text: String(UnifiProtectService.totalCameras)
          color: Colors.text
          font.pixelSize: Appearance.fontSizeHuge
          font.weight: Font.Bold
        }
        Text {
          text: "Cameras"
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeXS
          font.weight: Font.Medium
        }
      }

      ColumnLayout {
        spacing: Appearance.spacingXXS
        Text {
          text: String(UnifiProtectService.onlineCameras)
          color: Colors.primary
          font.pixelSize: Appearance.fontSizeHuge
          font.weight: Font.Bold
        }
        Text {
          text: "Online"
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeXS
          font.weight: Font.Medium
        }
      }

      ColumnLayout {
        spacing: Appearance.spacingXXS
        Text {
          text: String(UnifiProtectService.totalCameras - UnifiProtectService.onlineCameras)
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeHuge
          font.weight: Font.Bold
        }
        Text {
          text: "Offline"
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeXS
          font.weight: Font.Medium
        }
      }
    }
  }

  // ── Unconfigured state ────────────────────────
  SharedWidgets.EmptyState {
    Layout.fillWidth: true
    Layout.topMargin: 32
    visible: UnifiProtectService.status === "unconfigured"
    icon: "brands/unifi-protect-symbolic.svg"
    iconSize: Appearance.iconSizeLarge
    message: "Set Protect host and API key in Settings to view cameras"
  }

  // ── Search bar ────────────────────────────────
  SharedWidgets.SearchBar {
    id: searchBar
    placeholder: "Search cameras by name or model..."
    preferredHeight: root.compactMode ? 34 : 36
    Layout.fillWidth: true
    visible: UnifiProtectService.status !== "unconfigured" && !streamOverlay.visible
    onTextChanged: root.searchQuery = text
    inputItem.Keys.onEscapePressed: {
      if (searchBar.text !== "")
        searchBar.text = "";
      else
        root.closeRequested();
    }
  }

  // ── Camera list ───────────────────────────────
  SharedWidgets.ScrollableContent {
    Layout.fillWidth: true
    Layout.fillHeight: true
    columnSpacing: Appearance.spacingS
    visible: UnifiProtectService.status !== "unconfigured" && !streamOverlay.visible

    SharedWidgets.EmptyState {
      Layout.fillWidth: true
      Layout.topMargin: 32
      visible: !UnifiProtectService.busy && !root.hasCameras && UnifiProtectService.status === "ready"
      icon: "camera.svg"
      iconSize: Appearance.iconSizeLarge
      message: "No cameras found on Protect controller"
    }

    SharedWidgets.EmptyState {
      Layout.fillWidth: true
      Layout.topMargin: 32
      visible: !UnifiProtectService.busy && root.hasCameras && searchQuery.trim() !== "" && !root.hasFilteredCameras
      icon: "search-visual.svg"
      iconSize: Appearance.iconSizeLarge
      message: "No cameras match \"" + searchQuery + "\""
    }

    Repeater {
      model: ScriptModel { values: root.filteredCameras }

      delegate: CameraCard {
        required property var modelData
        camera: modelData
        snapshotUrl: UnifiProtectService.snapshotUrl(modelData.id || "")
        onViewStreamRequested: function(cam) {
          streamOverlay.camera = cam;
          streamOverlay.visible = true;
        }

        Component.onCompleted: {
          if (modelData && modelData.id && modelData.state === "CONNECTED") {
            UnifiProtectService.fetchSnapshot(modelData.id);
          }
        }
      }
    }
  }

  // ── Live stream overlay ───────────────────────
  LiveStreamOverlay {
    id: streamOverlay
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: false
    onCloseRequested: {
      visible = false;
      camera = null;
      streamUrl = "";
    }
  }
}
