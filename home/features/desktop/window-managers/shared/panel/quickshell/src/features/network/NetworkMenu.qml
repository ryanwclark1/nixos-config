import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../shared"
import "../../shared" as Shared
import "../system/sections"
import "../../services"
import "../../services/ShellUtils.js" as SU
import "../../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  popupMinWidth: 340; popupMaxWidth: 396; compactThreshold: 420
  readonly property int detailColumns: compactMode ? 1 : 2
  implicitHeight: compactMode ? 620 : 552
  title: "Networking"
  subtitle: root.isOffline ? "Network inspector" : NetworkService.activePrimaryName

  readonly property bool isOffline: NetworkService.activePrimaryName === "Offline"
  readonly property bool primaryIsWifi: NetworkService.activePrimaryType === "wifi" || NetworkService.activePrimaryType === "802-11-wireless"
  readonly property bool primaryIsEthernet: NetworkService.activePrimaryType === "ethernet" || NetworkService.activePrimaryType === "802-3-ethernet"
  property bool confirmingDisconnect: false
  property string confirmingDisconnectSSID: ""

  Timer {
    id: disconnectConfirmTimer
    interval: 3000
    onTriggered: {
      root.confirmingDisconnect = false;
      root.confirmingDisconnectSSID = "";
    }
  }
  property string selectedSSID: ""
  property bool showAdvanced: false

  function openVpnHub() {
    root.closeRequested();
    Quickshell.execDetached(SU.ipcCall("Shell", "toggleSurface", "vpnMenu", ""));
  }

  // Subscriber-based polling: NetworkService polls only while we're visible.
  SharedWidgets.Ref { service: NetworkService; active: root.visible }

  onVisibleChanged: {
    if (visible) NetworkService.refreshData();
    else {
      selectedSSID = "";
      showAdvanced = false;
    }
  }

  headerExtras: [
    Rectangle {
      implicitWidth: wifiStatusLabel.implicitWidth + 20
      height: 28
      radius: Appearance.radiusMedium
      color: NetworkService.wifiRadioEnabled ? Colors.primaryMid : Colors.chipSurface
      border.color: NetworkService.wifiRadioEnabled ? Colors.primary : Colors.border
      border.width: 1
      Text {
        id: wifiStatusLabel
        anchors.centerIn: parent
        text: !NetworkService.wifiDeviceAvailable ? "No Wi-Fi" : (NetworkService.wifiRadioEnabled ? "Wi-Fi Radio On" : "Wi-Fi Radio Off")
        color: NetworkService.wifiRadioEnabled ? Colors.primary : Colors.textSecondary
        font.pixelSize: Appearance.fontSizeSmall
        font.weight: Font.Medium
      }
      MouseArea {
        anchors.fill: parent
        enabled: NetworkService.wifiDeviceAvailable
        cursorShape: Qt.PointingHandCursor
        onClicked: NetworkService.toggleWifiRadio()
      }
    },
    SharedWidgets.IconButton {
      icon: NetworkService.isRefreshing ? "arrow-sync.svg" : "arrow-clockwise.svg"
      tooltipText: "Refresh"
      onClicked: NetworkService.refreshData()
    }
  ]

  Component {
    id: networkDetailCardComponent
    SharedWidgets.ThemedContainer {
      variant: "card"
      required property var modelData
      Layout.fillWidth: true
      Layout.preferredHeight: 60
      clip: true

      Rectangle {
        anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
        width: 3; color: Colors.highlight
      }

      RowLayout {
        anchors.fill: parent
        anchors.margins: Appearance.spacingM
        spacing: Appearance.spacingS

        Column {
          Layout.fillWidth: true
          spacing: Appearance.spacingXS

          SharedWidgets.SectionLabel { label: modelData.label }
          Text {
            text: modelData.value
            color: Colors.text
            font.pixelSize: Appearance.fontSizeSmall
            font.weight: Font.Medium
            width: parent.width
            wrapMode: Text.WrapAnywhere
            maximumLineCount: 2
            elide: Text.ElideRight
          }
        }

        SharedWidgets.IconButton {
          Layout.alignment: Qt.AlignTop
          visible: String(modelData.copyValue || "").trim() !== ""
          icon: "copy.svg"
          iconSize: Appearance.fontSizeMedium
          tooltipText: String(modelData.copyTooltip || ("Copy " + modelData.label))
          onClicked: NetworkService.copyText(String(modelData.copyLabel || modelData.label), String(modelData.copyValue || ""))
        }
      }

      SharedWidgets.StateLayer { anchors.fill: parent; stateColor: Colors.primary; enableRipple: false; hovered: detailHover.containsMouse }
      MouseArea { id: detailHover; anchors.fill: parent; hoverEnabled: true }
    }
  }

  SharedWidgets.ScrollableContent {
    Layout.fillWidth: true
    Layout.fillHeight: true
    columnSpacing: Appearance.spacingM

        // ── NETWORK SUMMARY CARD ──────────────────────────────────────────────
        Rectangle {
          Layout.fillWidth: true
          radius: Appearance.radiusMedium
          color: root.isOffline ? Colors.cardSurface : Colors.primaryGhost
          border.color: root.isOffline ? Colors.border : Colors.primarySubtle
          border.width: 1
          implicitHeight: summaryCol.implicitHeight + 32

          ColumnLayout {
            id: summaryCol
            anchors {
              left: parent.left; right: parent.right
              verticalCenter: parent.verticalCenter
              margins: Appearance.spacingL
            }
            spacing: Appearance.spacingM

            RowLayout {
              Layout.fillWidth: true
              spacing: Appearance.spacingL

              SharedWidgets.SvgIcon {
                source: NetworkService.networkIcon()
                color: root.isOffline ? Colors.textDisabled : Colors.primary
                size: Appearance.fontSizeHuge
                Layout.alignment: Qt.AlignVCenter
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                  text: NetworkService.activePrimaryName
                  color: root.isOffline ? Colors.textSecondary : Colors.text
                  font.pixelSize: Appearance.fontSizeLarge
                  font.weight: Font.DemiBold
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }
                Text {
                  text: NetworkService.networkSubtitle()
                  color: Colors.textDisabled
                  font.pixelSize: Appearance.fontSizeSmall
                  font.weight: Font.Medium
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }
              }

              Rectangle {
                implicitWidth: Math.max(96, (root.confirmingDisconnect ? 80 : disconnectLabel.implicitWidth) + 24)
                height: 32
                radius: height / 2
                color: root.isOffline
                  ? Colors.primaryMid
                  : (root.confirmingDisconnect ? Colors.error : Colors.errorLight)
                border.color: root.isOffline ? Colors.primary : Colors.error
                border.width: 1
                Behavior on color { Shared.CAnim {} }

                Text {
                  id: disconnectLabel
                  anchors.centerIn: parent
                  text: root.isOffline
                    ? "Refresh"
                    : (root.confirmingDisconnect
                        ? "Confirm?"
                        : (root.primaryIsWifi
                            ? "Disconnect Wi-Fi"
                            : (root.primaryIsEthernet ? "Disconnect Ethernet" : "Disconnect")))
                  color: root.isOffline ? Colors.primary : (root.confirmingDisconnect ? Colors.background : Colors.error)
                  font.pixelSize: Appearance.fontSizeXS
                  font.weight: Font.Bold
                  font.capitalization: Font.AllUppercase
                }

                SharedWidgets.StateLayer {
                  anchors.fill: parent
                  radius: parent.radius
                  stateColor: root.isOffline ? Colors.primary : Colors.error
                  hovered: disconnectHover.containsMouse
                  pressed: disconnectHover.pressed
                }

                MouseArea {
                  id: disconnectHover
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (root.isOffline) {
                      NetworkService.refreshData();
                      return;
                    }

                    if (root.confirmingDisconnect) {
                      NetworkService.disconnectPrimary();
                      root.confirmingDisconnect = false;
                      disconnectConfirmTimer.stop();
                    } else {
                      root.confirmingDisconnect = true;
                      disconnectConfirmTimer.restart();
                    }
                  }
                }
              }
            }

            Flow {
              Layout.fillWidth: true
              width: parent.width
              spacing: Appearance.spacingS

              Rectangle {
                visible: NetworkService.primaryDevice !== ""
                radius: Appearance.radiusPill
                color: Colors.chipSurface
                border.color: Colors.border
                border.width: 1
                implicitWidth: deviceLabel.implicitWidth + 16
                implicitHeight: 22
                Text { id: deviceLabel; anchors.centerIn: parent; text: NetworkService.primaryDevice.toUpperCase(); color: Colors.textSecondary; font.pixelSize: Appearance.fontSizeXXS; font.weight: Font.Bold; font.capitalization: Font.AllUppercase }
              }

              Rectangle {
                radius: Appearance.radiusPill
                color: Colors.chipSurface
                border.color: Colors.border
                border.width: 1
                implicitWidth: reachabilityLabel.implicitWidth + 16
                implicitHeight: 22
                Text { id: reachabilityLabel; anchors.centerIn: parent; text: NetworkService.connectivityStatus.toUpperCase(); color: Colors.textSecondary; font.pixelSize: Appearance.fontSizeXXS; font.weight: Font.Bold; font.capitalization: Font.AllUppercase }
              }

              Rectangle {
                visible: NetworkService.primarySignal !== ""
                radius: Appearance.radiusPill
                color: Colors.chipSurface
                border.color: Colors.border
                border.width: 1
                implicitWidth: signalRow.implicitWidth + 16
                implicitHeight: 22
                Row {
                  id: signalRow
                  anchors.centerIn: parent
                  spacing: Appearance.spacingXS
                  SharedWidgets.SvgIcon { source: NetworkService.signalIcon(NetworkService.primarySignal); color: Colors.textSecondary; size: Appearance.fontSizeXXS; anchors.verticalCenter: parent.verticalCenter }
                  Text { text: NetworkService.primarySignal + "%"; color: Colors.textSecondary; font.pixelSize: Appearance.fontSizeXXS; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
                }
              }
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Appearance.spacingS
          SharedWidgets.SectionLabel { label: "Overview" }

          GridLayout {
            Layout.fillWidth: true
            columns: root.detailColumns
            columnSpacing: Appearance.paddingSmall
            rowSpacing: Appearance.paddingSmall

            Repeater {
              model: [
                { label: "IPv4", value: NetworkService.detailValue(NetworkService.primaryIpv4, "Unavailable") },
                { label: "Gateway", value: NetworkService.detailValue(NetworkService.primaryGateway, "Unavailable") },
                { label: "Default Route", value: NetworkService.detailValue(NetworkService.routeDevice, "Unavailable") + (NetworkService.routeSource !== "" ? " \u2022 " + NetworkService.routeSource : "") },
                { label: "DNS", value: NetworkService.dnsSummary() }
              ]
              delegate: networkDetailCardComponent
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Appearance.spacingS

          SharedWidgets.SectionLabel { label: "Internet" }

          GridLayout {
            Layout.fillWidth: true
            columns: root.detailColumns
            columnSpacing: Appearance.paddingSmall
            rowSpacing: Appearance.paddingSmall

            Repeater {
              model: [
                { label: "Connectivity", value: NetworkService.detailValue(NetworkService.connectivityStatus, "Unknown") },
                {
                  label: "Public IPv4",
                  value: NetworkService.detailValue(NetworkService.publicIpv4, "Unavailable"),
                  copyValue: NetworkService.publicIpv4,
                  copyLabel: "Public IPv4",
                  copyTooltip: "Copy public IPv4"
                },
                { label: "Downloaded", value: NetworkService.detailValue(NetworkService.totalReceived, "0 B") },
                { label: "Uploaded", value: NetworkService.detailValue(NetworkService.totalSent, "0 B") }
              ]
              delegate: networkDetailCardComponent
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Appearance.spacingS

          SharedWidgets.SectionLabel { label: "Live Traffic" }
          NetworkGraphs { Layout.fillWidth: true }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Appearance.spacingS
          visible: NetworkService.tailscaleInstalled || NetworkService.vpnHasSavedProfiles

          SharedWidgets.SectionLabel { label: "VPN Hub" }

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 72
            radius: Appearance.radiusMedium
            color: Colors.cardSurface
            border.color: Colors.border
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.margins: Appearance.spacingM
              spacing: Appearance.spacingS

              SharedWidgets.SvgIcon {
                source: "shield-lock.svg"
                color: NetworkService.vpnPrimaryStatus === "connected" ? Colors.success
                  : (NetworkService.vpnPrimaryStatus === "stopped" ? Colors.warning : Colors.textSecondary)
                size: Appearance.fontSizeXL
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                  text: "Tailscale"
                  color: Colors.text
                  font.pixelSize: Appearance.fontSizeMedium
                  font.weight: Font.DemiBold
                }

                Text {
                  text: NetworkService.vpnPrimaryDetail
                    + (NetworkService.vpnOtherCount > 0 ? " \u2022 " + (NetworkService.vpnOtherCount === 1 ? "1 active profile" : NetworkService.vpnOtherCount + " active profiles") : "")
                    + (NetworkService.vpnInactiveCount > 0 ? " \u2022 " + (NetworkService.vpnInactiveCount === 1 ? "1 saved profile" : NetworkService.vpnInactiveCount + " saved profiles") : "")
                  color: Colors.textSecondary
                  font.pixelSize: Appearance.fontSizeXS
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }
              }

              Rectangle {
                width: 86
                height: 28
                radius: Appearance.radiusMedium
                color: Colors.primaryAccent
                border.color: Colors.primary
                border.width: 1

                Text {
                  anchors.centerIn: parent
                  text: "Open Hub"
                  color: Colors.primary
                  font.pixelSize: Appearance.fontSizeSmall
                  font.weight: Font.Medium
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.openVpnHub()
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 40
          radius: Appearance.radiusMedium
          color: Colors.cardSurface
          border.color: detailsMouse.containsMouse ? Colors.primary : Colors.border
          border.width: 1
          Behavior on border.color { enabled: !Colors.isTransitioning; CAnim {} }

          RowLayout {
            anchors.fill: parent
            anchors.margins: Appearance.spacingM
            spacing: Appearance.spacingS

            SharedWidgets.SvgIcon {
              source: root.showAdvanced ? "chevron-right.svg" : "chevron-down.svg"
              color: detailsMouse.containsMouse ? Colors.primary : Colors.textSecondary
              Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }
              size: Appearance.fontSizeLarge
            }

            Text {
              text: root.showAdvanced ? "Hide technical details" : "Show technical details"
              color: detailsMouse.containsMouse ? Colors.primary : Colors.text
              Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }
              font.pixelSize: Appearance.fontSizeSmall
              font.weight: Font.Medium
            }

            Item { Layout.fillWidth: true }

            Text {
              text: root.showAdvanced ? "Less" : "More"
              color: Colors.textSecondary
              font.pixelSize: Appearance.fontSizeXS
            }
          }

          SharedWidgets.StateLayer { id: detailsStateLayer; anchors.fill: parent; radius: parent.radius; stateColor: Colors.primary; hovered: detailsMouse.containsMouse; pressed: detailsMouse.pressed }
          MouseArea {
            id: detailsMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => { detailsStateLayer.burst(mouse.x, mouse.y); root.showAdvanced = !root.showAdvanced; }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Appearance.spacingS
          visible: root.showAdvanced

          SharedWidgets.SectionLabel { label: "Technical Details" }

          GridLayout {
            Layout.fillWidth: true
            columns: root.detailColumns
            columnSpacing: Appearance.paddingSmall
            rowSpacing: Appearance.paddingSmall

            Repeater {
              model: [
                { label: "IPv6", value: NetworkService.detailValue(NetworkService.primaryIpv6, "Unavailable") },
                { label: "MAC", value: NetworkService.detailValue(NetworkService.primaryMac, "Unavailable") },
                { label: "Link Speed", value: NetworkService.detailValue(NetworkService.primaryLinkSpeed, "Unavailable") },
                { label: "Security", value: NetworkService.detailValue(NetworkService.primarySecurity, NetworkService.activePrimaryType === "wifi" ? "Unknown" : "N/A") },
                { label: "Channel / Band", value: NetworkService.primaryChannel !== "" ? (NetworkService.primaryChannel + (NetworkService.primaryBand !== "" ? " \u2022 " + NetworkService.primaryBand : "")) : "N/A" },
                { label: "Interface", value: NetworkService.detailValue(NetworkService.primaryDevice, "Unavailable") }
              ]
              delegate: networkDetailCardComponent
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Appearance.spacingS
          visible: root.showAdvanced && NetworkService.activeConnections.length > 0

          SharedWidgets.SectionLabel { label: "Active Connections" }

          Repeater {
            model: NetworkService.activeConnections
            delegate: Rectangle {
              Layout.fillWidth: true
              implicitHeight: 42
              radius: Appearance.radiusMedium
              color: Colors.cardSurface
              border.color: Colors.border
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.margins: Appearance.spacingM
                spacing: Appearance.paddingSmall
                SharedWidgets.SvgIcon {
                  source: modelData.type === "802-3-ethernet" || modelData.type === "ethernet" ? "ethernet.svg" : (modelData.type === "wifi" || modelData.type === "802-11-wireless" ? "wifi-4.svg" : "wifi-off.svg")
                  color: Colors.primary
                  size: Appearance.fontSizeLarge
                }
                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 0
                  Text { text: modelData.name; color: Colors.text; font.pixelSize: Appearance.fontSizeMedium; Layout.fillWidth: true; elide: Text.ElideRight }
                  Text { text: (modelData.device || "") + (modelData.type ? " \u2022 " + modelData.type : ""); color: Colors.textSecondary; font.pixelSize: Appearance.fontSizeXS; Layout.fillWidth: true; elide: Text.ElideRight }
                }
              }
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Appearance.spacingS

          SharedWidgets.SectionLabel { label: "Available Networks" }
          Text {
            text: NetworkService.wifiNetworks.length === 0 ? "No nearby networks right now" : "Select a network to connect or disconnect"
            color: Colors.textSecondary
            font.pixelSize: Appearance.fontSizeXS
          }

          Repeater {
            model: NetworkService.wifiNetworks
            delegate: ColumnLayout {
              width: parent.width
              spacing: Appearance.spacingS

              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 46
                radius: Appearance.radiusMedium
                color: networkMouse.containsMouse
                  ? Colors.primarySubtle
                  : (modelData.active ? (root.confirmingDisconnectSSID === modelData.ssid ? Colors.error : Colors.primaryStrong) : Colors.cardSurface)
                border.color: modelData.active ? (root.confirmingDisconnectSSID === modelData.ssid ? Colors.error : Colors.primary) : Colors.border
                border.width: 1
                Behavior on color { Shared.CAnim {} }

                SharedWidgets.InnerHighlight { hoveredOpacity: 0.25; hovered: modelData.active }

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: Appearance.spacingM
                  spacing: Appearance.paddingSmall

                  SharedWidgets.SvgIcon {
                    source: (root.confirmingDisconnectSSID === modelData.ssid) ? "checkmark.svg" : (modelData.active ? "checkmark.svg" : NetworkService.signalIcon(modelData.signal))
                    color: modelData.active ? (root.confirmingDisconnectSSID === modelData.ssid ? Colors.background : Colors.primary) : Colors.textSecondary
                    size: Appearance.fontSizeLarge
                  }

                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                      text: modelData.ssid
                      color: modelData.active && root.confirmingDisconnectSSID === modelData.ssid ? Colors.background : Colors.text
                      font.pixelSize: Appearance.fontSizeMedium
                      font.weight: modelData.active ? Font.DemiBold : Font.Normal
                      Layout.fillWidth: true
                      elide: Text.ElideRight
                    }
                    Text {
                      text: (modelData.security || "open") + " \u2022 " + (modelData.signal || "0") + "%"
                      color: modelData.active && root.confirmingDisconnectSSID === modelData.ssid ? Colors.background : Colors.textSecondary
                      font.pixelSize: Appearance.fontSizeXS
                      Layout.fillWidth: true
                      elide: Text.ElideRight
                    }
                  }

                  Text {
                    text: modelData.active ? (root.confirmingDisconnectSSID === modelData.ssid ? "Confirm?" : "Connected") : "Connect"
                    color: modelData.active ? (root.confirmingDisconnectSSID === modelData.ssid ? Colors.background : Colors.primary) : Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeSmall
                    font.weight: Font.Medium
                  }
                }

                MouseArea {
                  id: networkMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (modelData.active) {
                      if (root.confirmingDisconnectSSID === modelData.ssid) {
                        NetworkService.disconnectWifi(modelData.ssid);
                        root.confirmingDisconnectSSID = "";
                        disconnectConfirmTimer.stop();
                      } else {
                        root.confirmingDisconnectSSID = modelData.ssid;
                        disconnectConfirmTimer.restart();
                      }
                    } else if ((modelData.security || "") === "" || modelData.security === "--") {
                      NetworkService.connectWifi(modelData.ssid);
                    } else {
                      root.selectedSSID = root.selectedSSID === modelData.ssid ? "" : modelData.ssid;
                    }
                  }
                }
              }

              Rectangle {
                Layout.fillWidth: true
                visible: root.selectedSSID === modelData.ssid
                implicitHeight: visible ? 48 : 0
                radius: Appearance.radiusMedium
                color: Colors.cardSurface
                border.color: Colors.border
                border.width: 1

                TextInput {
                  id: passwordInput
                  anchors.fill: parent
                  anchors.margins: Appearance.spacingM
                  verticalAlignment: Text.AlignVCenter
                  color: Colors.text
                  font.pixelSize: Appearance.fontSizeMedium
                  echoMode: TextInput.Password
                  onVisibleChanged: {
                    if (visible) forceActiveFocus();
                    else if (activeFocus) focus = false;
                  }
                  onAccepted: {
                    NetworkService.connectWifiWithPassword(modelData.ssid, text);
                    root.selectedSSID = "";
                    text = "";
                  }
                }

                Text {
                  anchors.fill: parent
                  anchors.leftMargin: Appearance.spacingM
                  anchors.rightMargin: Appearance.spacingM
                  verticalAlignment: Text.AlignVCenter
                  text: "Enter Wi-Fi password and press Enter"
                  color: Colors.textDisabled
                  font.pixelSize: Appearance.fontSizeSmall
                  visible: passwordInput.text === "" && !passwordInput.activeFocus
                }
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            visible: NetworkService.wifiNetworks.length === 0
            radius: Appearance.radiusMedium
            color: Colors.cardSurface
            border.color: Colors.border
            border.width: 1
            implicitHeight: 72

            Column {
              anchors.centerIn: parent
              spacing: Appearance.spacingXS
              SharedWidgets.SvgIcon {
                source: NetworkService.wifiDeviceAvailable ? (NetworkService.wifiRadioEnabled ? "wifi-off.svg" : "wifi-off.svg") : "wifi-off.svg"
                color: Colors.textDisabled
                size: Appearance.fontSizeXL
                anchors.horizontalCenter: parent.horizontalCenter
              }
              Text {
                text: !NetworkService.wifiDeviceAvailable ? "No Wi-Fi device detected" : (NetworkService.wifiRadioEnabled ? "No Wi-Fi networks detected" : "Wi-Fi radio is turned off")
                color: Colors.textSecondary
                font.pixelSize: Appearance.fontSizeSmall
                anchors.horizontalCenter: parent.horizontalCenter
              }
            }
          }
        }

  }
}
