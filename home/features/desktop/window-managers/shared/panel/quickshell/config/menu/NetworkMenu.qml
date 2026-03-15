import QtQuick
import QtQuick.Layouts
import Quickshell
import "../modules"
import "../services"
import "../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  popupMinWidth: 340; popupMaxWidth: 396; compactThreshold: 420
  readonly property int detailColumns: compactMode ? 1 : 2
  implicitHeight: compactMode ? 620 : 552
  title: "Networking"
  subtitle: NetworkService.activePrimaryName === "Offline" ? "Network inspector" : NetworkService.activePrimaryName
  toggleMethod: "toggleNetworkMenu"

  property string selectedSSID: ""
  property bool showAdvanced: false

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
      radius: Colors.radiusMedium
      color: NetworkService.wifiRadioEnabled ? Colors.withAlpha(Colors.primary, 0.18) : Colors.chipSurface
      border.color: NetworkService.wifiRadioEnabled ? Colors.primary : Colors.border
      border.width: 1
      Text {
        id: wifiStatusLabel
        anchors.centerIn: parent
        text: !NetworkService.wifiDeviceAvailable ? "No Wi-Fi" : (NetworkService.wifiRadioEnabled ? "Wi-Fi On" : "Wi-Fi Off")
        color: NetworkService.wifiRadioEnabled ? Colors.primary : Colors.textSecondary
        font.pixelSize: Colors.fontSizeSmall
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
      icon: NetworkService.isRefreshing ? "󰇚" : "󰑐"
      onClicked: NetworkService.refreshData()
    }
  ]

  SharedWidgets.ScrollableContent {
    Layout.fillWidth: true
    Layout.fillHeight: true
    columnSpacing: Colors.spacingM

        Rectangle {
          Layout.fillWidth: true
          radius: Colors.radiusMedium
          color: Colors.withAlpha(Colors.surface, 0.4)
          border.color: NetworkService.activePrimaryName === "Offline" ? Colors.border : Colors.primary
          border.width: 1
          implicitHeight: root.compactMode ? 126 : 96

          gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Colors.surfaceGradientStart }
            GradientStop { position: 1.0; color: Colors.surfaceGradientEnd }
          }

          // Inner highlight
          Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius - 1
            color: "transparent"
            border.color: Colors.borderLight
            border.width: 1
            opacity: 0.1
          }

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: Colors.spacingM
            spacing: Colors.paddingSmall

            RowLayout {
              visible: !root.compactMode
              Layout.fillWidth: true
              spacing: Colors.spacingM

              Text {
                text: NetworkService.networkIcon()
                color: NetworkService.activePrimaryName === "Offline" ? Colors.textDisabled : Colors.primary
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeHuge
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingXXS
                Text {
                  text: NetworkService.activePrimaryName
                  color: Colors.text
                  font.pixelSize: Colors.fontSizeLarge
                  font.weight: Font.DemiBold
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }
                Text {
                  text: NetworkService.networkSubtitle()
                  color: Colors.textSecondary
                  font.pixelSize: Colors.fontSizeSmall
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }
              }

              Rectangle {
                width: 90
                height: 30
                radius: height / 2
                color: NetworkService.activePrimaryName === "Offline"
                  ? Colors.withAlpha(Colors.primary, 0.16)
                  : Colors.withAlpha(Colors.error, 0.16)
                border.color: NetworkService.activePrimaryName === "Offline" ? Colors.primary : Colors.error
                border.width: 1
                Text {
                  anchors.centerIn: parent
                  text: NetworkService.activePrimaryName === "Offline" ? "Refresh" : "Disconnect"
                  color: NetworkService.activePrimaryName === "Offline" ? Colors.primary : Colors.error
                  font.pixelSize: Colors.fontSizeSmall
                  font.weight: Font.Medium
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (NetworkService.activePrimaryName === "Offline") NetworkService.refreshData();
                    else NetworkService.disconnectPrimary();
                  }
                }
              }
            }

            ColumnLayout {
              visible: root.compactMode
              Layout.fillWidth: true
              spacing: Colors.spacingS

              RowLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingM

                Text {
                  text: NetworkService.networkIcon()
                  color: NetworkService.activePrimaryName === "Offline" ? Colors.textDisabled : Colors.primary
                  font.family: Colors.fontMono
                  font.pixelSize: Colors.fontSizeHuge
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: Colors.spacingXXS
                  Text {
                    text: NetworkService.activePrimaryName
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeLarge
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                  }
                  Text {
                    text: NetworkService.networkSubtitle()
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeSmall
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                  }
                }
              }

              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 30
                radius: height / 2
                color: NetworkService.activePrimaryName === "Offline"
                  ? Colors.withAlpha(Colors.primary, 0.16)
                  : Colors.withAlpha(Colors.error, 0.16)
                border.color: NetworkService.activePrimaryName === "Offline" ? Colors.primary : Colors.error
                border.width: 1
                Text {
                  anchors.centerIn: parent
                  text: NetworkService.activePrimaryName === "Offline" ? "Refresh" : "Disconnect"
                  color: NetworkService.activePrimaryName === "Offline" ? Colors.primary : Colors.error
                  font.pixelSize: Colors.fontSizeSmall
                  font.weight: Font.Medium
                }
                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (NetworkService.activePrimaryName === "Offline") NetworkService.refreshData();
                    else NetworkService.disconnectPrimary();
                  }
                }
              }
            }

            Flow {
              Layout.fillWidth: true
              width: parent.width
              spacing: Colors.spacingS

              Rectangle {
                visible: NetworkService.primaryDevice !== ""
                radius: Colors.radiusPill
                color: Colors.chipSurface
                border.color: Colors.border
                border.width: 1
                implicitWidth: deviceLabel.implicitWidth + 18
                implicitHeight: 24
                Text { id: deviceLabel; anchors.centerIn: parent; text: NetworkService.primaryDevice; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Medium }
              }

              Rectangle {
                radius: Colors.radiusPill
                color: Colors.chipSurface
                border.color: Colors.border
                border.width: 1
                implicitWidth: reachabilityLabel.implicitWidth + 18
                implicitHeight: 24
                Text { id: reachabilityLabel; anchors.centerIn: parent; text: NetworkService.connectivityStatus; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Medium }
              }

              Rectangle {
                visible: NetworkService.primarySignal !== ""
                radius: Colors.radiusPill
                color: Colors.chipSurface
                border.color: Colors.border
                border.width: 1
                implicitWidth: signalLabel.implicitWidth + 18
                implicitHeight: 24
                Text { id: signalLabel; anchors.centerIn: parent; text: NetworkService.signalIcon(NetworkService.primarySignal) + " " + NetworkService.primarySignal + "%"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Medium; font.family: Colors.fontMono }
              }

            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Colors.spacingS
          SharedWidgets.SectionLabel { label: "Overview" }

          GridLayout {
            Layout.fillWidth: true
            columns: root.detailColumns
            columnSpacing: Colors.paddingSmall
            rowSpacing: Colors.paddingSmall

            Repeater {
              model: [
                { label: "IPv4", value: NetworkService.detailValue(NetworkService.primaryIpv4, "Unavailable") },
                { label: "Gateway", value: NetworkService.detailValue(NetworkService.primaryGateway, "Unavailable") },
                { label: "Default Route", value: NetworkService.detailValue(NetworkService.routeDevice, "Unavailable") + (NetworkService.routeSource !== "" ? " \u2022 " + NetworkService.routeSource : "") },
                { label: "DNS", value: NetworkService.dnsSummary() }
              ]
              delegate: Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                radius: Colors.radiusMedium
                color: Colors.withAlpha(Colors.surface, 0.3)
                border.color: Colors.border
                border.width: 1
                clip: true

                // Inner highlight
                Rectangle {
                  anchors.fill: parent
                  anchors.margins: 1
                  radius: parent.radius - 1
                  color: "transparent"
                  border.color: Colors.borderLight
                  border.width: 1
                  opacity: 0.1
                }

                Rectangle {
                  anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                  width: 3; color: Colors.withAlpha(Colors.primary, 0.25)
                }

                Column {
                  anchors.fill: parent
                  anchors.margins: Colors.spacingM
                  anchors.leftMargin: Colors.spacingM
                  spacing: Colors.spacingXS
                  SharedWidgets.SectionLabel { label: modelData.label }
                  Text {
                    text: modelData.value
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Font.Medium
                    width: parent.width
                    wrapMode: Text.WrapAnywhere
                    maximumLineCount: 2
                    elide: Text.ElideRight
                  }
                }

                SharedWidgets.StateLayer { anchors.fill: parent; radius: parent.radius; stateColor: Colors.primary; enableRipple: false; hovered: overviewCardHover.containsMouse }
                MouseArea { id: overviewCardHover; anchors.fill: parent; hoverEnabled: true }
              }
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Colors.spacingS

          SharedWidgets.SectionLabel { label: "Internet" }

          GridLayout {
            Layout.fillWidth: true
            columns: root.detailColumns
            columnSpacing: Colors.paddingSmall
            rowSpacing: Colors.paddingSmall

            Repeater {
              model: [
                { label: "Connectivity", value: NetworkService.detailValue(NetworkService.connectivityStatus, "Unknown") },
                { label: "Public IPv4", value: NetworkService.detailValue(NetworkService.publicIpv4, "Unavailable") },
                { label: "Downloaded", value: NetworkService.detailValue(NetworkService.totalReceived, "0 B") },
                { label: "Uploaded", value: NetworkService.detailValue(NetworkService.totalSent, "0 B") }
              ]
              delegate: Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                radius: Colors.radiusMedium
                color: Colors.withAlpha(Colors.surface, 0.3)
                border.color: Colors.border
                border.width: 1
                clip: true

                // Inner highlight
                Rectangle {
                  anchors.fill: parent
                  anchors.margins: 1
                  radius: parent.radius - 1
                  color: "transparent"
                  border.color: Colors.borderLight
                  border.width: 1
                  opacity: 0.1
                }

                Rectangle {
                  anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                  width: 3; color: Colors.withAlpha(Colors.primary, 0.25)
                }

                Column {
                  anchors.fill: parent
                  anchors.margins: Colors.spacingM
                  anchors.leftMargin: Colors.spacingM
                  spacing: Colors.spacingXS
                  SharedWidgets.SectionLabel { label: modelData.label }
                  Text {
                    text: modelData.value
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Font.Medium
                    width: parent.width
                    wrapMode: Text.WrapAnywhere
                    maximumLineCount: 2
                    elide: Text.ElideRight
                  }
                }

                SharedWidgets.StateLayer { anchors.fill: parent; radius: parent.radius; stateColor: Colors.primary; enableRipple: false; hovered: internetCardHover.containsMouse }
                MouseArea { id: internetCardHover; anchors.fill: parent; hoverEnabled: true }
              }
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Colors.spacingS

          SharedWidgets.SectionLabel { label: "Live Traffic" }
          NetworkGraphs { Layout.fillWidth: true }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Colors.spacingS
          visible: NetworkService.vpns.length > 0 || NetworkService.tailscaleStatus !== "Offline"

          SharedWidgets.SectionLabel { label: "VPN & Overlays" }

          Rectangle {
            Layout.fillWidth: true
            visible: NetworkService.tailscaleStatus !== "Offline"
            implicitHeight: 54
            radius: Colors.radiusMedium
            color: Colors.cardSurface
            border.color: Colors.border
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.margins: Colors.spacingM
              spacing: Colors.paddingSmall

              Text { text: "󰖂"; color: NetworkService.tailscaleStatus === "Connected" ? Colors.primary : Colors.textSecondary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text { text: "Tailscale"; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.DemiBold }
                Text {
                  text: NetworkService.tailscaleIp !== "" ? (NetworkService.tailscaleStatus + " \u2022 " + NetworkService.tailscaleIp) : NetworkService.tailscaleStatus
                  color: Colors.textSecondary
                  font.pixelSize: Colors.fontSizeXS
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }
              }

              Rectangle {
                width: 72
                height: 28
                radius: Colors.radiusMedium
                color: NetworkService.tailscaleStatus === "Connected"
                  ? Colors.withAlpha(Colors.error, 0.14)
                  : Colors.withAlpha(Colors.primary, 0.16)
                border.color: NetworkService.tailscaleStatus === "Connected" ? Colors.error : Colors.primary
                border.width: 1
                Text {
                  anchors.centerIn: parent
                  text: NetworkService.tailscaleStatus === "Connected" ? "Down" : "Up"
                  color: NetworkService.tailscaleStatus === "Connected" ? Colors.error : Colors.primary
                  font.pixelSize: Colors.fontSizeSmall
                  font.weight: Font.Medium
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (NetworkService.tailscaleStatus === "Connected") NetworkService.tailscaleDown();
                else NetworkService.tailscaleUp();
              }
            }
          }

          Repeater {
            model: NetworkService.vpns
            delegate: Rectangle {
              Layout.fillWidth: true
              implicitHeight: 54
              radius: Colors.radiusMedium
              color: Colors.cardSurface
              border.color: Colors.border
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.margins: Colors.spacingM
                spacing: Colors.paddingSmall
                Text { text: "󰖂"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeLarge }
                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 0
                  Text { text: modelData.name; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; Layout.fillWidth: true; elide: Text.ElideRight }
                  Text { text: modelData.type + (modelData.state ? " \u2022 " + modelData.state : ""); color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; Layout.fillWidth: true; elide: Text.ElideRight }
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: NetworkService.disconnectVpn(modelData.name)
              }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 40
          radius: Colors.radiusMedium
          color: Colors.cardSurface
          border.color: detailsMouse.containsMouse ? Colors.primary : Colors.border
          border.width: 1
          Behavior on border.color { ColorAnimation { duration: Colors.durationFast } }

          RowLayout {
            anchors.fill: parent
            anchors.margins: Colors.spacingM
            spacing: Colors.spacingS

            Text {
              text: root.showAdvanced ? "󰅂" : "󰅀"
              color: detailsMouse.containsMouse ? Colors.primary : Colors.textSecondary
              Behavior on color { ColorAnimation { duration: Colors.durationFast } }
              font.family: Colors.fontMono
              font.pixelSize: Colors.fontSizeLarge
            }

            Text {
              text: root.showAdvanced ? "Hide technical details" : "Show technical details"
              color: detailsMouse.containsMouse ? Colors.primary : Colors.text
              Behavior on color { ColorAnimation { duration: Colors.durationFast } }
              font.pixelSize: Colors.fontSizeSmall
              font.weight: Font.Medium
            }

            Item { Layout.fillWidth: true }

            Text {
              text: root.showAdvanced ? "Less" : "More"
              color: Colors.textSecondary
              font.pixelSize: Colors.fontSizeXS
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
          spacing: Colors.spacingS
          visible: root.showAdvanced

          SharedWidgets.SectionLabel { label: "Technical Details" }

          GridLayout {
            Layout.fillWidth: true
            columns: root.detailColumns
            columnSpacing: Colors.paddingSmall
            rowSpacing: Colors.paddingSmall

            Repeater {
              model: [
                { label: "IPv6", value: NetworkService.detailValue(NetworkService.primaryIpv6, "Unavailable") },
                { label: "MAC", value: NetworkService.detailValue(NetworkService.primaryMac, "Unavailable") },
                { label: "Link Speed", value: NetworkService.detailValue(NetworkService.primaryLinkSpeed, "Unavailable") },
                { label: "Security", value: NetworkService.detailValue(NetworkService.primarySecurity, NetworkService.activePrimaryType === "wifi" ? "Unknown" : "N/A") },
                { label: "Channel / Band", value: NetworkService.primaryChannel !== "" ? (NetworkService.primaryChannel + (NetworkService.primaryBand !== "" ? " \u2022 " + NetworkService.primaryBand : "")) : "N/A" },
                { label: "Interface", value: NetworkService.detailValue(NetworkService.primaryDevice, "Unavailable") }
              ]
              delegate: Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                radius: Colors.radiusMedium
                color: Colors.withAlpha(Colors.surface, 0.3)
                border.color: Colors.border
                border.width: 1
                clip: true

                // Inner highlight
                Rectangle {
                  anchors.fill: parent
                  anchors.margins: 1
                  radius: parent.radius - 1
                  color: "transparent"
                  border.color: Colors.borderLight
                  border.width: 1
                  opacity: 0.1
                }

                Rectangle {
                  anchors.left: parent.left; anchors.top: parent.top; anchors.bottom: parent.bottom
                  width: 3; color: Colors.withAlpha(Colors.primary, 0.25)
                }

                Column {
                  anchors.fill: parent
                  anchors.margins: Colors.spacingM
                  anchors.leftMargin: Colors.spacingM
                  spacing: Colors.spacingXS
                  SharedWidgets.SectionLabel { label: modelData.label }
                  Text {
                    text: modelData.value
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Font.Medium
                    width: parent.width
                    wrapMode: Text.WrapAnywhere
                    maximumLineCount: 2
                    elide: Text.ElideRight
                  }
                }

                SharedWidgets.StateLayer { anchors.fill: parent; radius: parent.radius; stateColor: Colors.primary; enableRipple: false; hovered: techCardHover.containsMouse }
                MouseArea { id: techCardHover; anchors.fill: parent; hoverEnabled: true }
              }
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Colors.spacingS
          visible: root.showAdvanced && NetworkService.activeConnections.length > 0

          SharedWidgets.SectionLabel { label: "Active Connections" }

          Repeater {
            model: NetworkService.activeConnections
            delegate: Rectangle {
              Layout.fillWidth: true
              implicitHeight: 42
              radius: Colors.radiusMedium
              color: Colors.cardSurface
              border.color: Colors.border
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.margins: Colors.spacingM
                spacing: Colors.paddingSmall
                Text {
                  text: modelData.type === "802-3-ethernet" || modelData.type === "ethernet" ? "󰈀" : (modelData.type === "wifi" || modelData.type === "802-11-wireless" ? "󰖩" : "󰖂")
                  color: Colors.primary
                  font.family: Colors.fontMono
                  font.pixelSize: Colors.fontSizeLarge
                }
                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 0
                  Text { text: modelData.name; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; Layout.fillWidth: true; elide: Text.ElideRight }
                  Text { text: (modelData.device || "") + (modelData.type ? " \u2022 " + modelData.type : ""); color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; Layout.fillWidth: true; elide: Text.ElideRight }
                }
              }
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Colors.spacingS

          SharedWidgets.SectionLabel { label: "Available Networks" }
          Text {
            text: NetworkService.wifiNetworks.length === 0 ? "No nearby networks right now" : "Select a network to connect or disconnect"
            color: Colors.textSecondary
            font.pixelSize: Colors.fontSizeXS
          }

          Repeater {
            model: NetworkService.wifiNetworks
            delegate: ColumnLayout {
              width: parent.width
              spacing: Colors.spacingS

              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 46
                radius: Colors.radiusMedium
                color: networkMouse.containsMouse
                  ? Colors.withAlpha(Colors.primary, 0.12)
                  : (modelData.active ? Colors.withAlpha(Colors.primary, 0.16) : Colors.withAlpha(Colors.surface, 0.3))
                border.color: modelData.active ? Colors.primary : Colors.border
                border.width: 1

                // Inner highlight
                Rectangle {
                  anchors.fill: parent
                  anchors.margins: 1
                  radius: parent.radius - 1
                  color: "transparent"
                  border.color: Colors.borderLight
                  border.width: 1
                  opacity: modelData.active ? 0.25 : 0.1
                }

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: Colors.spacingM
                  spacing: Colors.paddingSmall

                  Text {
                    text: modelData.active ? "󰄬" : NetworkService.signalIcon(modelData.signal)
                    color: modelData.active ? Colors.primary : Colors.textSecondary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeLarge
                  }

                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                      text: modelData.ssid
                      color: Colors.text
                      font.pixelSize: Colors.fontSizeMedium
                      font.weight: modelData.active ? Font.DemiBold : Font.Normal
                      Layout.fillWidth: true
                      elide: Text.ElideRight
                    }
                    Text {
                      text: (modelData.security || "open") + " \u2022 " + (modelData.signal || "0") + "%"
                      color: Colors.textSecondary
                      font.pixelSize: Colors.fontSizeXS
                      Layout.fillWidth: true
                      elide: Text.ElideRight
                    }
                  }

                  Text {
                    text: modelData.active ? "Connected" : "Connect"
                    color: modelData.active ? Colors.primary : Colors.textSecondary
                    font.pixelSize: Colors.fontSizeSmall
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
                      NetworkService.disconnectWifi(modelData.ssid);
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
                radius: Colors.radiusMedium
                color: Colors.cardSurface
                border.color: Colors.border
                border.width: 1

                TextInput {
                  id: passwordInput
                  anchors.fill: parent
                  anchors.margins: Colors.spacingM
                  verticalAlignment: Text.AlignVCenter
                  color: Colors.text
                  font.pixelSize: Colors.fontSizeMedium
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
                  anchors.leftMargin: Colors.spacingM
                  anchors.rightMargin: Colors.spacingM
                  verticalAlignment: Text.AlignVCenter
                  text: "Enter Wi-Fi password and press Enter"
                  color: Colors.textDisabled
                  font.pixelSize: Colors.fontSizeSmall
                  visible: passwordInput.text === "" && !passwordInput.activeFocus
                }
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            visible: NetworkService.wifiNetworks.length === 0
            radius: Colors.radiusMedium
            color: Colors.cardSurface
            border.color: Colors.border
            border.width: 1
            implicitHeight: 72

            Column {
              anchors.centerIn: parent
              spacing: Colors.spacingXS
              Text {
                text: NetworkService.wifiDeviceAvailable ? (NetworkService.wifiRadioEnabled ? "󰤮" : "󰖪") : "󰤭"
                color: Colors.textDisabled
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeXL
                anchors.horizontalCenter: parent.horizontalCenter
              }
              Text {
                text: !NetworkService.wifiDeviceAvailable ? "No Wi-Fi device detected" : (NetworkService.wifiRadioEnabled ? "No Wi-Fi networks detected" : "Wi-Fi radio is turned off")
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeSmall
                anchors.horizontalCenter: parent.horizontalCenter
              }
            }
          }
        }

  }
}
