import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

PopupWindow {
  id: root
  implicitWidth: 380
  implicitHeight: 520

  readonly property bool hasAdapter: !!Bluetooth.defaultAdapter
  readonly property bool btEnabled: hasAdapter && Bluetooth.defaultAdapter.enabled
  property bool isScanning: false
  property int scanElapsed: 0
  property int connectedCount: 0
  property int pairedCount: 0
  property int availableCount: 0

  function updateCounts() {
    var cc = 0, pc = 0, ac = 0;
    for (var i = 0; i < Bluetooth.devices.values.length; i++) {
      var d = Bluetooth.devices.values[i];
      if (d.connected) cc++;
      else if (d.paired) pc++;
      else ac++;
    }
    connectedCount = cc;
    pairedCount = pc;
    availableCount = ac;
  }

  function deviceIcon(dev) {
    var n = (dev.name || "").toLowerCase();
    if (n.indexOf("headphone") !== -1 || n.indexOf("airpod") !== -1 || n.indexOf("buds") !== -1 || n.indexOf("earphone") !== -1) return "󰋋";
    if (n.indexOf("keyboard") !== -1) return "󰌌";
    if (n.indexOf("mouse") !== -1 || n.indexOf("trackpad") !== -1) return "󰍽";
    if (n.indexOf("phone") !== -1 || n.indexOf("iphone") !== -1 || n.indexOf("pixel") !== -1 || n.indexOf("galaxy") !== -1) return "󰄜";
    if (n.indexOf("speaker") !== -1 || n.indexOf("soundbar") !== -1) return "󰓃";
    if (n.indexOf("watch") !== -1) return "󰂰";
    if (n.indexOf("gamepad") !== -1 || n.indexOf("controller") !== -1 || n.indexOf("xbox") !== -1 || n.indexOf("dualsense") !== -1) return "󰖳";
    return "󰂯";
  }

  function startScan() {
    if (!hasAdapter || !btEnabled) return;
    Bluetooth.defaultAdapter.discovering = true;
    isScanning = true;
    scanElapsed = 0;
    scanTimer.start();
  }

  function stopScan() {
    if (hasAdapter) Bluetooth.defaultAdapter.discovering = false;
    isScanning = false;
    scanTimer.stop();
    scanElapsed = 0;
  }

  onVisibleChanged: {
    if (visible && btEnabled) startScan();
    else if (!visible) stopScan();
    if (visible) updateCounts();
  }

  Timer {
    id: scanTimer
    interval: 1000
    repeat: true
    onTriggered: {
      scanElapsed++;
      updateCounts();
      if (scanElapsed >= 30) stopScan();
    }
  }

  Connections {
    target: Bluetooth.devices
    function onCountChanged() { root.updateCounts(); }
  }

  Rectangle {
    anchors.fill: parent
    color: Colors.popupSurface
    border.color: Colors.border
    border.width: 1
    radius: Colors.radiusMedium
    clip: true

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Colors.paddingLarge
      spacing: 14

      // ── HEADER ──────────────────────────
      RowLayout {
        Layout.fillWidth: true

        Text {
          text: "Bluetooth"
          color: Colors.fgMain
          font.pixelSize: 18
          font.weight: Font.DemiBold
        }

        Item { Layout.fillWidth: true }

        // On/Off chip
        Rectangle {
          implicitWidth: btChipLabel.implicitWidth + 20
          implicitHeight: 26
          radius: 13
          color: root.btEnabled ? Colors.withAlpha(Colors.primary, 0.16) : Colors.highlightLight
          Behavior on color { ColorAnimation { duration: 150 } }

          Text {
            id: btChipLabel
            anchors.centerIn: parent
            text: root.btEnabled ? "On" : "Off"
            color: root.btEnabled ? Colors.primary : Colors.textSecondary
            font.pixelSize: 11
            font.weight: Font.Medium
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (root.hasAdapter) {
                Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
                if (!Bluetooth.defaultAdapter.enabled) root.stopScan();
                else root.startScan();
              }
            }
          }
        }

        // Scan button
        Rectangle {
          width: 30; height: 30; radius: 15
          color: scanBtnHover.containsMouse ? Colors.highlightLight : "transparent"

          Text {
            id: scanIcon
            anchors.centerIn: parent
            text: "󰑐"
            color: root.isScanning ? Colors.primary : Colors.textSecondary
            font.family: Colors.fontMono
            font.pixelSize: 16

            RotationAnimator on rotation {
              from: 0; to: 360
              duration: 1200
              running: root.isScanning
              loops: Animation.Infinite
            }
          }

          MouseArea {
            id: scanBtnHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.isScanning ? root.stopScan() : root.startScan()
          }
        }

        SharedWidgets.MenuCloseButton { toggleMethod: "toggleBluetoothMenu" }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Colors.border
      }

      // ── CONTENT ──────────────────────────
      Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentHeight: contentColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
          id: contentColumn
          width: parent.width
          spacing: 10

          // ── EMPTY STATES ──────────────────
          // No adapter
          ColumnLayout {
            Layout.fillWidth: true
            visible: !root.hasAdapter
            spacing: 8
            Layout.topMargin: 40

            Text {
              Layout.alignment: Qt.AlignHCenter
              text: "󰂲"
              color: Colors.textDisabled
              font.family: Colors.fontMono
              font.pixelSize: 48
            }
            Text {
              Layout.alignment: Qt.AlignHCenter
              text: "No Bluetooth adapter found"
              color: Colors.textDisabled
              font.pixelSize: 13
            }
          }

          // BT off
          ColumnLayout {
            Layout.fillWidth: true
            visible: root.hasAdapter && !root.btEnabled
            spacing: 12
            Layout.topMargin: 40

            Text {
              Layout.alignment: Qt.AlignHCenter
              text: "󰂲"
              color: Colors.textDisabled
              font.family: Colors.fontMono
              font.pixelSize: 48
            }
            Text {
              Layout.alignment: Qt.AlignHCenter
              text: "Bluetooth is off"
              color: Colors.textDisabled
              font.pixelSize: 13
            }
            Rectangle {
              Layout.alignment: Qt.AlignHCenter
              implicitWidth: turnOnLabel.implicitWidth + 24
              implicitHeight: 32
              radius: 16
              color: turnOnHover.containsMouse ? Colors.withAlpha(Colors.primary, 0.24) : Colors.withAlpha(Colors.primary, 0.16)
              Behavior on color { ColorAnimation { duration: 150 } }

              Text {
                id: turnOnLabel
                anchors.centerIn: parent
                text: "Turn On"
                color: Colors.primary
                font.pixelSize: 12
                font.weight: Font.DemiBold
              }

              MouseArea {
                id: turnOnHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  if (root.hasAdapter) {
                    Bluetooth.defaultAdapter.enabled = true;
                    root.startScan();
                  }
                }
              }
            }
          }

          // ── CONNECTED SECTION ──────────────
          Text {
            text: "CONNECTED"
            color: Colors.textDisabled
            font.pixelSize: 10
            font.weight: Font.Bold
            font.letterSpacing: 0.5
            visible: root.connectedCount > 0
          }

          Repeater {
            model: Bluetooth.devices
            delegate: Rectangle {
              id: connCard
              Layout.fillWidth: true
              implicitHeight: visible ? 46 : 0
              visible: modelData.connected
              radius: Colors.radiusMedium
              property bool isHovered: connHover.containsMouse
              color: isHovered ? Colors.withAlpha(Colors.primary, 0.12) : Colors.cardSurface
              border.color: Colors.primary
              border.width: 1
              Behavior on color { ColorAnimation { duration: 150 } }

              RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Text {
                  text: root.deviceIcon(modelData)
                  color: Colors.primary
                  font.family: Colors.fontMono
                  font.pixelSize: 16
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 1
                  Text {
                    text: modelData.name || "Unknown Device"
                    color: Colors.fgMain
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                  }
                  Text {
                    text: modelData.address
                    color: Colors.textDisabled
                    font.pixelSize: 9
                    visible: !!modelData.address
                  }
                }

                Rectangle {
                  radius: 12
                  color: Colors.withAlpha(Colors.primary, 0.16)
                  implicitWidth: connChipLabel.implicitWidth + 16
                  implicitHeight: 24
                  Text {
                    id: connChipLabel
                    anchors.centerIn: parent
                    text: "Connected"
                    color: Colors.primary
                    font.pixelSize: 10
                    font.weight: Font.Medium
                  }
                }

                Rectangle {
                  width: 28; height: 28; radius: 14
                  color: disconnHover.containsMouse ? Colors.withAlpha(Colors.error, 0.16) : "transparent"
                  Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    color: Colors.textSecondary
                    font.family: Colors.fontMono
                    font.pixelSize: 14
                  }
                  MouseArea {
                    id: disconnHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.disconnect()
                  }
                }
              }

              MouseArea {
                id: connHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
              }
            }
          }

          // ── PAIRED SECTION ──────────────
          Text {
            text: "PAIRED"
            color: Colors.textDisabled
            font.pixelSize: 10
            font.weight: Font.Bold
            font.letterSpacing: 0.5
            visible: root.pairedCount > 0
          }

          Repeater {
            model: Bluetooth.devices
            delegate: Rectangle {
              id: pairedCard
              Layout.fillWidth: true
              implicitHeight: visible ? 46 : 0
              visible: modelData.paired && !modelData.connected
              radius: Colors.radiusMedium
              property bool isHovered: pairedHover.containsMouse
              color: isHovered ? Colors.withAlpha(Colors.primary, 0.12) : Colors.cardSurface
              border.color: Colors.border
              border.width: 1
              Behavior on color { ColorAnimation { duration: 150 } }

              RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Text {
                  text: root.deviceIcon(modelData)
                  color: Colors.textSecondary
                  font.family: Colors.fontMono
                  font.pixelSize: 16
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 1
                  Text {
                    text: modelData.name || "Unknown Device"
                    color: Colors.fgMain
                    font.pixelSize: 12
                    font.weight: Font.Normal
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                  }
                  Text {
                    text: modelData.address
                    color: Colors.textDisabled
                    font.pixelSize: 9
                    visible: !!modelData.address
                  }
                }

                Rectangle {
                  radius: 12
                  color: pairedConnHover.containsMouse ? Colors.withAlpha(Colors.primary, 0.24) : Colors.highlightLight
                  implicitWidth: pairedChipLabel.implicitWidth + 16
                  implicitHeight: 24
                  Behavior on color { ColorAnimation { duration: 150 } }

                  Text {
                    id: pairedChipLabel
                    anchors.centerIn: parent
                    text: "Connect"
                    color: Colors.textSecondary
                    font.pixelSize: 10
                    font.weight: Font.Medium
                  }

                  MouseArea {
                    id: pairedConnHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.connect()
                  }
                }

                Rectangle {
                  width: 28; height: 28; radius: 14
                  color: removeHover.containsMouse ? Colors.withAlpha(Colors.error, 0.16) : "transparent"
                  Text {
                    anchors.centerIn: parent
                    text: "󰆴"
                    color: Colors.textSecondary
                    font.family: Colors.fontMono
                    font.pixelSize: 14
                  }
                  MouseArea {
                    id: removeHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Quickshell.execDetached(["bluetoothctl", "remove", modelData.address])
                  }
                }
              }

              MouseArea {
                id: pairedHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
              }
            }
          }

          // ── AVAILABLE SECTION ──────────────
          Text {
            text: "AVAILABLE"
            color: Colors.textDisabled
            font.pixelSize: 10
            font.weight: Font.Bold
            font.letterSpacing: 0.5
            visible: root.availableCount > 0 || root.isScanning
          }

          // Scanning placeholder
          RowLayout {
            Layout.fillWidth: true
            visible: root.isScanning
            spacing: 8
            Layout.leftMargin: 4

            Text {
              text: "󰑐"
              color: Colors.textDisabled
              font.family: Colors.fontMono
              font.pixelSize: 14

              RotationAnimator on rotation {
                from: 0; to: 360
                duration: 1200
                running: root.isScanning
                loops: Animation.Infinite
              }
            }

            Text {
              text: "Scanning for devices..."
              color: Colors.textDisabled
              font.pixelSize: 11
            }
          }

          Repeater {
            model: Bluetooth.devices
            delegate: Rectangle {
              id: availCard
              Layout.fillWidth: true
              implicitHeight: visible ? 46 : 0
              visible: !modelData.paired && !modelData.connected
              radius: Colors.radiusMedium
              property bool isHovered: availHover.containsMouse
              color: isHovered ? Colors.withAlpha(Colors.primary, 0.12) : Colors.cardSurface
              border.color: Colors.border
              border.width: 1
              Behavior on color { ColorAnimation { duration: 150 } }

              RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Text {
                  text: root.deviceIcon(modelData)
                  color: Colors.textDisabled
                  font.family: Colors.fontMono
                  font.pixelSize: 16
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 1
                  Text {
                    text: modelData.name || "Unknown Device"
                    color: Colors.fgMain
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                  }
                  Text {
                    text: modelData.address
                    color: Colors.textDisabled
                    font.pixelSize: 9
                    visible: !!modelData.address
                  }
                }

                Rectangle {
                  radius: 12
                  color: pairHover.containsMouse ? Colors.withAlpha(Colors.primary, 0.24) : Colors.highlightLight
                  implicitWidth: pairChipLabel.implicitWidth + 16
                  implicitHeight: 24
                  Behavior on color { ColorAnimation { duration: 150 } }

                  Text {
                    id: pairChipLabel
                    anchors.centerIn: parent
                    text: "Pair"
                    color: Colors.textSecondary
                    font.pixelSize: 10
                    font.weight: Font.Medium
                  }

                  MouseArea {
                    id: pairHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      Quickshell.execDetached(["sh", "-c",
                        "bluetoothctl trust " + modelData.address + " && bluetoothctl pair " + modelData.address
                      ]);
                    }
                  }
                }
              }

              MouseArea {
                id: availHover
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
              }
            }
          }

          // No devices found (BT on, not scanning, nothing found)
          Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 20
            text: "No devices found"
            color: Colors.textDisabled
            font.pixelSize: 12
            visible: root.btEnabled && !root.isScanning && root.connectedCount === 0 && root.pairedCount === 0 && root.availableCount === 0
          }
        }
      }
    }
  }
}
