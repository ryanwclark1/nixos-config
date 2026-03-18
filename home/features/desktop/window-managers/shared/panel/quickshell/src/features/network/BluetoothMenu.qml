import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import "../../menu"
import "../../services"
import "../../widgets" as SharedWidgets
import "../../services/ShellUtils.js" as ShellUtils

BasePopupMenu {
  id: root
  popupMinWidth: 340; popupMaxWidth: 380; compactThreshold: 360
  implicitHeight: compactMode ? 560 : 520
  title: "Bluetooth"

  readonly property bool hasAdapter: !!Bluetooth.defaultAdapter
  readonly property bool btEnabled: hasAdapter && Bluetooth.defaultAdapter.enabled

  // Optimistic UI: reflect the toggle immediately, lock out polling for 4s
  property bool _optimisticBtEnabled: false
  property bool _optimisticLocked: false
  readonly property bool effectiveBtEnabled: _optimisticLocked ? _optimisticBtEnabled : btEnabled

  readonly property int _optimisticLockMs: 4000

  Timer {
    id: optimisticTimer
    interval: root._optimisticLockMs
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

  function pairDevice(address) {
    if (!address) return;

    root.stopScan();
    var quotedAddress = ShellUtils.shellQuote(address);
    Quickshell.execDetached(["sh", "-c",
      "bluetoothctl pair " + quotedAddress
      + " && bluetoothctl trust " + quotedAddress
      + " && bluetoothctl connect " + quotedAddress + " || true"
    ]);
  }

  function connectDevice(device) {
    if (!device) return;
    root.stopScan();
    device.connect();
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

  readonly property int _scanTickMs: 2000
  readonly property int _scanTimeoutSec: 30

  Timer {
    id: scanTimer
    interval: root._scanTickMs
    repeat: true
    onTriggered: {
      scanElapsed += root._scanTickMs / 1000;
      if (scanElapsed >= root._scanTimeoutSec) stopScan();
    }
  }

  // Reactive device count watcher (ObjectModel doesn't expose countChanged signal)
  property int _btDeviceCount: (Bluetooth.devices && Bluetooth.devices.values) ? Bluetooth.devices.values.length : 0
  on_BtDeviceCountChanged: root.updateCounts()

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
          font.pixelSize: Colors.fontSizeHuge * 2
        }
        Text {
          Layout.alignment: Qt.AlignHCenter
          text: "Bluetooth is off"
          color: Colors.textDisabled
          font.pixelSize: Colors.fontSizeMedium
        }
        Rectangle {
          Layout.alignment: Qt.AlignHCenter
          Layout.fillWidth: root.compactMode
          implicitWidth: turnOnLabel.implicitWidth + 24
          implicitHeight: 32
          radius: Colors.radiusPill
          color: Colors.primaryStrong

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
          implicitHeight: visible ? (root.compactMode ? 56 : 46) : 0
          visible: modelData.connected
          radius: Colors.radiusMedium
          color: modelData.connected ? Colors.primarySubtle : (connHover.containsMouse ? Colors.primaryFaint : Colors.cardSurface)
          border.color: modelData.connected ? Colors.primary : Colors.border
          border.width: 1

          SharedWidgets.InnerHighlight { hoveredOpacity: 0.25; hovered: modelData.connected }

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

            SharedWidgets.StatusChip {
              text: "Connected"
              chipColor: Colors.primary
              visible: !root.compactMode
            }

            SharedWidgets.IconButton {
              size: 28; radius: Colors.radiusMedium
              icon: "󰅖"; stateColor: Colors.error
              onClicked: modelData.disconnect()
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
          implicitHeight: visible ? (root.compactMode ? 56 : 46) : 0
          visible: modelData.paired && !modelData.connected
          radius: Colors.radiusMedium
          color: pairedHover.containsMouse ? Colors.primaryFaint : Colors.cardSurface
          border.color: Colors.border
          border.width: 1

          // Inner highlight
          SharedWidgets.InnerHighlight { }

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

            SharedWidgets.StatusChip {
              text: "Connect"
              chipColor: Colors.textSecondary
              interactive: true
              visible: !root.compactMode
              onClicked: root.connectDevice(modelData)
            }

            SharedWidgets.IconButton {
              size: 28; radius: Colors.radiusMedium
              icon: "󰆴"; stateColor: Colors.error
              onClicked: Quickshell.execDetached(["bluetoothctl", "remove", modelData.address])
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
        Layout.leftMargin: Colors.spacingXS

        SharedWidgets.LoadingSpinner { size: Colors.fontSizeLarge; color: Colors.textDisabled }

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
          implicitHeight: visible ? (root.compactMode ? 56 : 46) : 0
          visible: !modelData.paired && !modelData.connected
          radius: Colors.radiusMedium
          color: availHover.containsMouse ? Colors.primaryFaint : Colors.cardSurface
          border.color: Colors.border
          border.width: 1

          SharedWidgets.InnerHighlight { hoveredOpacity: 0.2; hovered: availHover.containsMouse }

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

            SharedWidgets.StatusChip {
              text: "Pair"
              chipColor: Colors.textSecondary
              interactive: true
              visible: !root.compactMode
              onClicked: root.pairDevice(modelData.address)
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
        Layout.topMargin: Colors.spacingLG
        visible: root.effectiveBtEnabled && !root.isScanning && root.connectedCount === 0 && root.pairedCount === 0 && root.availableCount === 0
        icon: "󰂯"
        message: "No devices found"
      }
  }
}
