import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  implicitWidth: 380
  implicitHeight: 520
  title: "Bluetooth"
  toggleMethod: "toggleBluetoothMenu"

  readonly property bool hasAdapter: !!Bluetooth.defaultAdapter
  readonly property bool btEnabled: hasAdapter && Bluetooth.defaultAdapter.enabled

  // Optimistic UI: reflect the toggle immediately, lock out polling for 4s
  property bool _optimisticBtEnabled: false
  property bool _optimisticLocked: false
  readonly property bool effectiveBtEnabled: _optimisticLocked ? _optimisticBtEnabled : btEnabled

  Timer {
    id: optimisticTimer
    interval: 4000
    onTriggered: root._optimisticLocked = false
  }

  function toggleBluetooth() {
    if (!root.hasAdapter) return;
    var next = !root.effectiveBtEnabled;
    root._optimisticBtEnabled = next;
    root._optimisticLocked = true;
    optimisticTimer.restart();
    Bluetooth.defaultAdapter.enabled = next;
    if (!next) root.stopScan();
    else root.startScan();
  }

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
    if (!hasAdapter || !effectiveBtEnabled) return;
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
    if (visible && effectiveBtEnabled) startScan();
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

  headerExtras: [
    SharedWidgets.FilterChip {
      label: root.effectiveBtEnabled ? "On" : "Off"
      selected: root.effectiveBtEnabled
      onClicked: root.toggleBluetooth()
    },
    Rectangle {
      width: 30; height: 30; radius: height / 2
      color: "transparent"

      Text {
        id: scanIcon
        anchors.centerIn: parent
        text: "󰑐"
        color: root.isScanning ? Colors.primary : Colors.textSecondary
        font.family: Colors.fontMono
        font.pixelSize: Colors.fontSizeXL

        RotationAnimator on rotation {
          from: 0; to: 360
          duration: 1200
          running: root.isScanning
          loops: Animation.Infinite
        }
      }

      SharedWidgets.StateLayer { id: scanBtnStateLayer; hovered: scanBtnHover.containsMouse; pressed: scanBtnHover.pressed }

      MouseArea {
        id: scanBtnHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => { scanBtnStateLayer.burst(mouse.x, mouse.y); root.isScanning ? root.stopScan() : root.startScan(); }
      }
    }
  ]

  // ── CONTENT ──────────────────────────
  SharedWidgets.ScrollableContent {
    Layout.fillWidth: true
    Layout.fillHeight: true
    columnSpacing: Colors.paddingSmall

      // ── EMPTY STATES ──────────────────
      // No adapter
      SharedWidgets.EmptyState {
        Layout.fillWidth: true
        Layout.topMargin: 40
        visible: !root.hasAdapter
        icon: "󰂲"
        iconSize: 48
        message: "No Bluetooth adapter found"
      }

      // BT off
      ColumnLayout {
        Layout.fillWidth: true
        visible: root.hasAdapter && !root.effectiveBtEnabled
        spacing: Colors.spacingM
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
          font.pixelSize: Colors.fontSizeMedium
        }
        Rectangle {
          Layout.alignment: Qt.AlignHCenter
          implicitWidth: turnOnLabel.implicitWidth + 24
          implicitHeight: 32
          radius: 16
          color: Colors.withAlpha(Colors.primary, 0.16)

          Text {
            id: turnOnLabel
            anchors.centerIn: parent
            text: "Turn On"
            color: Colors.primary
            font.pixelSize: Colors.fontSizeMedium
            font.weight: Font.DemiBold
          }

          SharedWidgets.StateLayer { id: turnOnStateLayer; hovered: turnOnHover.containsMouse; pressed: turnOnHover.pressed; stateColor: Colors.primary }

          MouseArea {
            id: turnOnHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => { turnOnStateLayer.burst(mouse.x, mouse.y); root.toggleBluetooth(); }
          }
        }
      }

      // ── CONNECTED SECTION ──────────────
      SharedWidgets.SectionLabel { label: "CONNECTED"; visible: root.connectedCount > 0 }

      Repeater {
        model: Bluetooth.devices
        delegate: Rectangle {
          id: connCard
          Layout.fillWidth: true
          implicitHeight: visible ? 46 : 0
          visible: modelData.connected
          radius: Colors.radiusMedium
          color: Colors.cardSurface
          border.color: Colors.primary
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.margins: Colors.paddingSmall
            spacing: Colors.paddingSmall

            Text {
              text: root.deviceIcon(modelData)
              color: Colors.primary
              font.family: Colors.fontMono
              font.pixelSize: Colors.fontSizeXL
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 1
              Text {
                text: modelData.name || "Unknown Device"
                color: Colors.text
                font.pixelSize: Colors.fontSizeMedium
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
              Text {
                text: modelData.address
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeXS
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
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.Medium
              }
            }

            Rectangle {
              width: 28; height: 28; radius: Colors.radiusMedium
              color: "transparent"
              Text {
                anchors.centerIn: parent
                text: "󰅖"
                color: Colors.textSecondary
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeLarge
              }
              SharedWidgets.StateLayer { id: disconnStateLayer; hovered: disconnHover.containsMouse; pressed: disconnHover.pressed; stateColor: Colors.error }
              MouseArea {
                id: disconnHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => { disconnStateLayer.burst(mouse.x, mouse.y); modelData.disconnect(); }
              }
            }
          }

          SharedWidgets.StateLayer { id: connStateLayer; hovered: connHover.containsMouse; pressed: connHover.pressed; stateColor: Colors.primary; enableRipple: false }

          MouseArea {
            id: connHover
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
          }
        }
      }

      // ── PAIRED SECTION ──────────────
      SharedWidgets.SectionLabel { label: "PAIRED"; visible: root.pairedCount > 0 }

      Repeater {
        model: Bluetooth.devices
        delegate: Rectangle {
          id: pairedCard
          Layout.fillWidth: true
          implicitHeight: visible ? 46 : 0
          visible: modelData.paired && !modelData.connected
          radius: Colors.radiusMedium
          color: Colors.cardSurface
          border.color: Colors.border
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.margins: Colors.paddingSmall
            spacing: Colors.paddingSmall

            Text {
              text: root.deviceIcon(modelData)
              color: Colors.textSecondary
              font.family: Colors.fontMono
              font.pixelSize: Colors.fontSizeXL
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 1
              Text {
                text: modelData.name || "Unknown Device"
                color: Colors.text
                font.pixelSize: Colors.fontSizeMedium
                font.weight: Font.Normal
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
              Text {
                text: modelData.address
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeXS
                visible: !!modelData.address
              }
            }

            Rectangle {
              radius: 12
              color: Colors.highlightLight
              implicitWidth: pairedChipLabel.implicitWidth + 16
              implicitHeight: 24

              Text {
                id: pairedChipLabel
                anchors.centerIn: parent
                text: "Connect"
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.Medium
              }

              SharedWidgets.StateLayer { id: pairedConnStateLayer; hovered: pairedConnHover.containsMouse; pressed: pairedConnHover.pressed; stateColor: Colors.primary }

              MouseArea {
                id: pairedConnHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => { pairedConnStateLayer.burst(mouse.x, mouse.y); modelData.connect(); }
              }
            }

            Rectangle {
              width: 28; height: 28; radius: Colors.radiusMedium
              color: "transparent"
              Text {
                anchors.centerIn: parent
                text: "󰆴"
                color: Colors.textSecondary
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeLarge
              }
              SharedWidgets.StateLayer { id: removeStateLayer; hovered: removeHover.containsMouse; pressed: removeHover.pressed; stateColor: Colors.error }
              MouseArea {
                id: removeHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => { removeStateLayer.burst(mouse.x, mouse.y); Quickshell.execDetached(["bluetoothctl", "remove", modelData.address]); }
              }
            }
          }

          SharedWidgets.StateLayer { id: pairedStateLayer; hovered: pairedHover.containsMouse; pressed: pairedHover.pressed; stateColor: Colors.primary; enableRipple: false }

          MouseArea {
            id: pairedHover
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
          }
        }
      }

      // ── AVAILABLE SECTION ──────────────
      SharedWidgets.SectionLabel { label: "AVAILABLE"; visible: root.availableCount > 0 || root.isScanning }

      // Scanning placeholder
      RowLayout {
        Layout.fillWidth: true
        visible: root.isScanning
        spacing: Colors.spacingS
        Layout.leftMargin: 4

        Text {
          text: "󰑐"
          color: Colors.textDisabled
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeLarge

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
          font.pixelSize: Colors.fontSizeSmall
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
          color: Colors.cardSurface
          border.color: Colors.border
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.margins: Colors.paddingSmall
            spacing: Colors.paddingSmall

            Text {
              text: root.deviceIcon(modelData)
              color: Colors.textDisabled
              font.family: Colors.fontMono
              font.pixelSize: Colors.fontSizeXL
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 1
              Text {
                text: modelData.name || "Unknown Device"
                color: Colors.text
                font.pixelSize: Colors.fontSizeMedium
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
              Text {
                text: modelData.address
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeXS
                visible: !!modelData.address
              }
            }

            Rectangle {
              radius: 12
              color: Colors.highlightLight
              implicitWidth: pairChipLabel.implicitWidth + 16
              implicitHeight: 24

              Text {
                id: pairChipLabel
                anchors.centerIn: parent
                text: "Pair"
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.Medium
              }

              SharedWidgets.StateLayer { id: pairStateLayer; hovered: pairHover.containsMouse; pressed: pairHover.pressed; stateColor: Colors.primary }

              MouseArea {
                id: pairHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                  pairStateLayer.burst(mouse.x, mouse.y);
                  Quickshell.execDetached(["sh", "-c",
                    "bluetoothctl trust " + modelData.address + " && bluetoothctl pair " + modelData.address
                  ]);
                }
              }
            }
          }

          SharedWidgets.StateLayer { id: availStateLayer; hovered: availHover.containsMouse; pressed: availHover.pressed; stateColor: Colors.primary; enableRipple: false }

          MouseArea {
            id: availHover
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
          }
        }
      }

      // No devices found (BT on, not scanning, nothing found)
      SharedWidgets.EmptyState {
        Layout.fillWidth: true
        Layout.topMargin: 20
        visible: root.effectiveBtEnabled && !root.isScanning && root.connectedCount === 0 && root.pairedCount === 0 && root.availableCount === 0
        icon: "󰂯"
        message: "No devices found"
      }
  }
}
