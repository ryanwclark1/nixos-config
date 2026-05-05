import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../shared"
import "../../services"
import "../../services/SearchUtils.js" as SU
import "../../widgets" as SharedWidgets
import "../settings/components"

BasePopupMenu {
  id: root
  popupMaxWidth: 460
  compactThreshold: 380
  implicitHeight: compactMode ? 780 : 820
  title: "UniFi Network"
  subtitle: UnifiNetworkService.busy ? "Refreshing..." : _subtitle
  contentSpacing: Appearance.spacingM
  focusOnOpen: true
  initialFocusTarget: searchBar.inputItem

  property var surfaceContext: null
  property string searchQuery: ""

  readonly property string _subtitle: {
    if (UnifiNetworkService.status === "unconfigured") return "Set API key in settings to connect";
    if (UnifiNetworkService.status === "error") return UnifiNetworkService.errorMessage;
    var n = UnifiNetworkService.onlineDevices;
    var t = UnifiNetworkService.totalDevices;
    return n + "/" + t + " devices online";
  }

  readonly property var filteredDevices: {
    var query = searchQuery.toLowerCase().trim();
    if (!query) return UnifiNetworkService.devices;
    return UnifiNetworkService.devices.filter(function(d) {
      if (!d) return false;
      var text = (String(d.name || "") + " " + String(d.model || "") + " " + String(d.ip || "") + " " + String(d.productLine || "")).toLowerCase();
      return text.indexOf(query) !== -1;
    });
  }

  readonly property bool hasDevices: UnifiNetworkService.devices.length > 0
  readonly property bool hasFilteredDevices: filteredDevices.length > 0

  headerExtras: [
    SharedWidgets.IconButton {
      icon: "arrow-clockwise.svg"
      tooltipText: "Refresh UniFi data"
      onClicked: UnifiNetworkService.refresh()
    }
  ]

  // ── ISP Health Card ────────────────────────────
  Rectangle {
    Layout.fillWidth: true
    implicitHeight: ispGrid.implicitHeight + 16
    radius: Appearance.radiusMedium
    color: Colors.cardSurface
    border.color: Colors.border
    border.width: 1
    visible: UnifiNetworkService.status === "ready" && Object.keys(UnifiNetworkService.ispMetrics).length > 0

    GridLayout {
      id: ispGrid
      anchors {
        left: parent.left
        right: parent.right
        top: parent.top
        margins: Appearance.spacingM
      }
      columns: root.compactMode ? 2 : 4
      columnSpacing: Appearance.spacingM
      rowSpacing: Appearance.spacingS

      ColumnLayout {
        spacing: Appearance.spacingXXS
        Text {
          text: {
            var up = UnifiNetworkService.ispMetrics.uptime;
            return (up !== undefined && up !== null) ? up + "%" : "--";
          }
          color: Colors.primary
          font.pixelSize: Appearance.fontSizeHuge
          font.weight: Font.Bold
        }
        Text {
          text: "Uptime"
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeXS
          font.weight: Font.Medium
        }
      }

      ColumnLayout {
        spacing: Appearance.spacingXXS
        Text {
          text: {
            var lat = UnifiNetworkService.ispMetrics.avgLatency;
            return (lat !== undefined && lat !== null) ? lat + " ms" : "--";
          }
          color: Colors.text
          font.pixelSize: Appearance.fontSizeHuge
          font.weight: Font.Bold
        }
        Text {
          text: "Latency"
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeXS
          font.weight: Font.Medium
        }
      }

      ColumnLayout {
        spacing: Appearance.spacingXXS
        Text {
          text: {
            var dl = UnifiNetworkService.ispMetrics.download_kbps;
            if (dl === undefined || dl === null) return "--";
            return dl > 1000 ? (dl / 1000).toFixed(1) + " Mbps" : dl + " kbps";
          }
          color: Colors.text
          font.pixelSize: Appearance.fontSizeHuge
          font.weight: Font.Bold
        }
        Text {
          text: "Download"
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeXS
          font.weight: Font.Medium
        }
      }

      ColumnLayout {
        spacing: Appearance.spacingXXS
        Text {
          text: {
            var ul = UnifiNetworkService.ispMetrics.upload_kbps;
            if (ul === undefined || ul === null) return "--";
            return ul > 1000 ? (ul / 1000).toFixed(1) + " Mbps" : ul + " kbps";
          }
          color: Colors.text
          font.pixelSize: Appearance.fontSizeHuge
          font.weight: Font.Bold
        }
        Text {
          text: "Upload"
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeXS
          font.weight: Font.Medium
        }
      }
    }
  }

  // ── Status summary card ────────────────────────
  Rectangle {
    Layout.fillWidth: true
    implicitHeight: statusGrid.implicitHeight + 16
    radius: Appearance.radiusMedium
    color: Colors.cardSurface
    border.color: UnifiNetworkService.status === "ready" ? Colors.border : Colors.warning
    border.width: 1
    visible: UnifiNetworkService.status !== "unconfigured"

    GridLayout {
      id: statusGrid
      anchors {
        left: parent.left
        right: parent.right
        top: parent.top
        margins: Appearance.spacingM
      }
      columns: root.compactMode ? 2 : 4
      columnSpacing: Appearance.spacingM
      rowSpacing: Appearance.spacingS

      ColumnLayout {
        spacing: Appearance.spacingXXS
        Text {
          text: String(UnifiNetworkService.totalDevices)
          color: Colors.text
          font.pixelSize: Appearance.fontSizeHuge
          font.weight: Font.Bold
        }
        Text {
          text: "Devices"
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeXS
          font.weight: Font.Medium
        }
      }

      ColumnLayout {
        spacing: Appearance.spacingXXS
        Text {
          text: String(UnifiNetworkService.onlineDevices)
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
          text: String(UnifiNetworkService.sites.length)
          color: Colors.text
          font.pixelSize: Appearance.fontSizeHuge
          font.weight: Font.Bold
        }
        Text {
          text: "Sites"
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeXS
          font.weight: Font.Medium
        }
      }

      ColumnLayout {
        spacing: Appearance.spacingXXS
        Text {
          text: String(UnifiNetworkService.hosts.length)
          color: Colors.text
          font.pixelSize: Appearance.fontSizeHuge
          font.weight: Font.Bold
        }
        Text {
          text: "Consoles"
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
    visible: UnifiNetworkService.status === "unconfigured"
    icon: "brands/ubiquiti-symbolic.svg"
    iconSize: Appearance.iconSizeLarge
    message: "Add your UniFi API key in Settings to get started"
  }

  // ── Search bar ────────────────────────────────
  SharedWidgets.SearchBar {
    id: searchBar
    placeholder: "Search devices by name, model, or IP..."
    preferredHeight: root.compactMode ? 34 : 36
    Layout.fillWidth: true
    visible: UnifiNetworkService.status !== "unconfigured"
    onTextChanged: root.searchQuery = text
    inputItem.Keys.onEscapePressed: {
      if (searchBar.text !== "")
        searchBar.text = "";
      else
        root.closeRequested();
    }
  }

  // ── Device list ───────────────────────────────
  SharedWidgets.ScrollableContent {
    Layout.fillWidth: true
    Layout.fillHeight: true
    columnSpacing: Appearance.spacingS
    visible: UnifiNetworkService.status !== "unconfigured"

    SharedWidgets.EmptyState {
      Layout.fillWidth: true
      Layout.topMargin: 32
      visible: !UnifiNetworkService.busy && !root.hasDevices && UnifiNetworkService.status === "ready"
      icon: "server.svg"
      iconSize: Appearance.iconSizeLarge
      message: "No UniFi devices found"
    }

    SharedWidgets.EmptyState {
      Layout.fillWidth: true
      Layout.topMargin: 32
      visible: !UnifiNetworkService.busy && root.hasDevices && searchQuery.trim() !== "" && !root.hasFilteredDevices
      icon: "search-visual.svg"
      iconSize: Appearance.iconSizeLarge
      message: "No devices match \"" + searchQuery + "\""
    }

    Repeater {
      model: ScriptModel { values: root.filteredDevices }

      delegate: Rectangle {
        required property var modelData

        Layout.fillWidth: true
        implicitHeight: deviceLayout.implicitHeight + 20
        radius: Appearance.radiusMedium
        color: Colors.cardSurface
        border.color: Colors.border
        border.width: 1

        ColumnLayout {
          id: deviceLayout
          anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Appearance.spacingM
          }
          spacing: Appearance.spacingS

          RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            SharedWidgets.SvgIcon {
              source: UnifiNetworkService.productLineIcon(modelData.productLine)
              color: modelData.status === "online" ? Colors.primary : Colors.textDisabled
              size: Appearance.fontSizeLarge
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: Appearance.spacingXXS

              Text {
                text: String(modelData.name || "Unknown")
                color: Colors.text
                font.pixelSize: Appearance.fontSizeMedium
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              Text {
                text: String(modelData.model || "") + (modelData.shortname ? " (" + modelData.shortname + ")" : "")
                color: Colors.textSecondary
                font.pixelSize: Appearance.fontSizeXS
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              RowLayout {
                spacing: Appearance.spacingS
                Layout.fillWidth: true

                Text {
                  text: String(modelData.ip || "")
                  color: Colors.textSecondary
                  font.pixelSize: Appearance.fontSizeXXS
                  font.family: Appearance.fontMono
                }

                Text {
                  text: modelData.status === "online" ? "Online" : "Offline"
                  color: modelData.status === "online" ? Colors.primary : Colors.textDisabled
                  font.pixelSize: Appearance.fontSizeXXS
                  font.weight: Font.Bold
                }

                Text {
                  text: String(modelData.version || "")
                  color: Colors.textDisabled
                  font.pixelSize: Appearance.fontSizeXXS
                  visible: modelData.version !== undefined && modelData.version !== ""
                }

                Text {
                  text: "Update available"
                  color: Colors.warning
                  font.pixelSize: Appearance.fontSizeXXS
                  font.weight: Font.Bold
                  visible: modelData.firmwareStatus === "upgradable" || (modelData.updateAvailable !== undefined && modelData.updateAvailable !== null && modelData.updateAvailable !== "")
                }
              }
            }
          }
        }
      }
    }
  }
}
