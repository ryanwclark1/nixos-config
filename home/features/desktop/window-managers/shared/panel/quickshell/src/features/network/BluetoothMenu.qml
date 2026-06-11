import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import "../../shared"
import "../../services"
import "../../services/IconHelpers.js" as IconHelpers
import "../../widgets" as SharedWidgets
import "../../services/ShellUtils.js" as ShellUtils

BasePopupMenu {
  id: root
  popupMinWidth: 340; popupMaxWidth: 380; compactThreshold: 360
  implicitHeight: compactMode ? 760 : 720
  title: "Bluetooth"

  readonly property bool hasAdapter: !!Bluetooth.defaultAdapter
  readonly property bool btEnabled: !!(Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled)

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
    if (!root.hasAdapter || !Bluetooth.defaultAdapter) return;
    var next = !root.effectiveBtEnabled;
    root._optimisticBtEnabled = next;
    root._optimisticLocked = true;
    optimisticTimer.restart();
    Bluetooth.defaultAdapter.enabled = next;
    if (!next) root.stopScan();
    else root.startScan();
  }

  readonly property bool isScanning: BluetoothCatalogService.isScanning
  readonly property int connectedCount: BluetoothCatalogService.connectedDevices.length
  readonly property int pairedCount: BluetoothCatalogService.pairedDevices.length
  readonly property int availableCount: BluetoothCatalogService.availableDevices.length

  Component {
    id: _btSvgIcon
    SharedWidgets.SvgIcon { source: parent.devIcon; color: parent.devColor; size: Appearance.fontSizeXL }
  }
  Component {
    id: _btNerdIcon
    Text { text: parent.devIcon; color: parent.devColor; font.family: Appearance.fontMono; font.pixelSize: Appearance.fontSizeXL }
  }

  function deviceIcon(dev) {
    return IconHelpers.bluetoothDeviceIcon(dev);
  }

  function pairDevice(address) {
    if (!address) return;

    root.stopScan();
    Quickshell.execDetached(["sh", "-c",
      "bluetoothctl pair \"$1\" && bluetoothctl trust \"$1\" && bluetoothctl connect \"$1\" || true",
      "sh", address
    ]);
  }

  function findLiveDevice(address) {
    return BluetoothCatalogService.findLiveDevice(address);
  }

  function connectDevice(address) {
    if (!address) return;
    root.stopScan();
    var device = findLiveDevice(address);
    if (device) device.connect();
    else Quickshell.execDetached(["bluetoothctl", "connect", address]);
  }

  function disconnectDevice(address) {
    if (!address) return;
    root.stopScan();
    var device = findLiveDevice(address);
    if (device) device.disconnect();
    else Quickshell.execDetached(["bluetoothctl", "disconnect", address]);
  }

  function startScan() {
    BluetoothCatalogService.startScan();
  }

  function stopScan() {
    BluetoothCatalogService.stopScan();
  }

  onVisibleChanged: {
    if (visible && effectiveBtEnabled) startScan();
    else if (!visible) stopScan();
  }

  component BtDeviceCard: Rectangle {
    id: _btCard
    required property var modelData
    property color iconColor: Colors.textDisabled
    property int nameWeight: Font.Normal
    property color bgColor: Colors.cardSurface
    property color borderColor: Colors.border
    property bool highlightAlways: false
    property string chipText: ""
    property color chipColor: Colors.textSecondary
    property bool chipInteractive: false
    property string actionIcon: ""
    property string actionTooltip: ""
    property bool showAction: actionIcon !== ""
    signal chipClicked()
    signal actionClicked()

    Layout.fillWidth: true
    implicitHeight: visible ? (root.compactMode ? 56 : 46) : 0
    radius: Appearance.radiusMedium
    color: _cardHover.containsMouse ? Colors.primaryFaint : bgColor
    border.color: borderColor
    border.width: 1

    SharedWidgets.InnerHighlight { hoveredOpacity: highlightAlways ? 0.25 : 0.2; hovered: highlightAlways || _cardHover.containsMouse }

    RowLayout {
      anchors.fill: parent
      anchors.margins: Appearance.paddingSmall
      spacing: Appearance.paddingSmall

      Loader {
        readonly property string devIcon: root.deviceIcon(_btCard.modelData)
        readonly property color devColor: _btCard.iconColor
        sourceComponent: devIcon.endsWith(".svg") ? _btSvgIcon : _btNerdIcon
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacingXXS
        Text {
          text: modelData.name || "Unknown Device"
          color: Colors.text
          font.pixelSize: Appearance.fontSizeMedium
          font.weight: nameWeight
          elide: Text.ElideRight
          Layout.fillWidth: true
        }
        Text {
          text: modelData.subtitle || modelData.address
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeXS
          visible: !!(modelData.subtitle || modelData.address)
        }
      }

      SharedWidgets.StatusChip {
        text: chipText
        chipColor: _btCard.chipColor
        interactive: _btCard.chipInteractive
        visible: !root.compactMode
        onClicked: _btCard.chipClicked()
      }

      SharedWidgets.IconButton {
        size: 28; radius: Appearance.radiusMedium
        icon: _btCard.actionIcon; stateColor: Colors.error
        tooltipText: _btCard.actionTooltip
        visible: _btCard.showAction
        onClicked: _btCard.actionClicked()
      }
    }

    SharedWidgets.StateLayer { hovered: _cardHover.containsMouse; pressed: _cardHover.pressed; stateColor: Colors.primary; enableRipple: false }

    MouseArea {
      id: _cardHover
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.NoButton
    }
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

      SharedWidgets.SvgIcon {
        id: scanIcon
        anchors.centerIn: parent
        source: "arrow-clockwise.svg"
        color: root.isScanning ? Colors.primary : Colors.textSecondary
        size: Appearance.fontSizeXL

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

      Tooltip {
        text: root.isScanning ? "Stop scan" : "Scan for devices"
        hoverPoint: Qt.point(scanBtnHover.mouseX, scanBtnHover.mouseY)
        shown: scanBtnHover.containsMouse
      }
    }
  ]

  // ── CONTENT ──────────────────────────
  SharedWidgets.ScrollableContent {
    Layout.fillWidth: true
    Layout.fillHeight: true
    columnSpacing: Appearance.paddingSmall

      // ── EMPTY STATES ──────────────────
      // No adapter
      SharedWidgets.EmptyState {
        Layout.fillWidth: true
        Layout.topMargin: 40
        visible: !root.hasAdapter
        icon: "bluetooth-disabled.svg"
        iconSize: Appearance.iconSizeLarge
        message: "No Bluetooth adapter found"
      }

      // BT off
      ColumnLayout {
        Layout.fillWidth: true
        visible: root.hasAdapter && !root.effectiveBtEnabled
        spacing: Appearance.spacingM
        Layout.topMargin: 40

        SharedWidgets.SvgIcon {
          Layout.alignment: Qt.AlignHCenter
          source: "bluetooth-disabled.svg"
          color: Colors.textDisabled
          size: Appearance.fontSizeHuge * 2
        }
        Text {
          Layout.alignment: Qt.AlignHCenter
          text: "Bluetooth is off"
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeMedium
        }
        Rectangle {
          Layout.alignment: Qt.AlignHCenter
          Layout.fillWidth: root.compactMode
          implicitWidth: turnOnLabel.implicitWidth + 24
          implicitHeight: 32
          radius: Appearance.radiusPill
          color: Colors.primaryStrong

          Text {
            id: turnOnLabel
            anchors.centerIn: parent
            text: "Turn On"
            color: Colors.primary
            font.pixelSize: Appearance.fontSizeMedium
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
        model: BluetoothCatalogService.connectedDevices
        delegate: BtDeviceCard {
          visible: true
          iconColor: Colors.primary
          nameWeight: Font.DemiBold
          bgColor: Colors.primarySubtle
          borderColor: Colors.primary
          highlightAlways: true
          chipText: "Connected"
          chipColor: Colors.primary
          actionIcon: "dismiss.svg"
          actionTooltip: "Disconnect"
          onChipClicked: {}
          onActionClicked: root.disconnectDevice(modelData.address)
        }
      }

      // ── PAIRED SECTION ──────────────
      SharedWidgets.SectionLabel { label: "PAIRED"; visible: root.pairedCount > 0 }

      Repeater {
        model: BluetoothCatalogService.pairedDevices
        delegate: BtDeviceCard {
          visible: true
          iconColor: Colors.textSecondary
          chipText: "Connect"
          chipInteractive: true
          actionIcon: "delete.svg"
          actionTooltip: "Remove"
          onChipClicked: root.connectDevice(modelData.address)
          onActionClicked: Quickshell.execDetached(["bluetoothctl", "remove", modelData.address])
        }
      }

      // ── AVAILABLE SECTION ──────────────
      SharedWidgets.SectionLabel { label: "AVAILABLE"; visible: root.availableCount > 0 || root.isScanning }

      // Scanning placeholder
      RowLayout {
        Layout.fillWidth: true
        visible: root.isScanning
        spacing: Appearance.spacingS
        Layout.leftMargin: Appearance.spacingXS

        SharedWidgets.LoadingSpinner { size: Appearance.fontSizeLarge; color: Colors.textDisabled }

        Text {
          text: "Scanning for devices..."
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeSmall
        }
      }

      Repeater {
        model: BluetoothCatalogService.availableDevices
        delegate: BtDeviceCard {
          visible: true
          iconColor: Colors.textDisabled
          chipText: "Pair"
          chipInteractive: true
          showAction: false
          onChipClicked: root.pairDevice(modelData.address)
        }
      }

      // No devices found (BT on, not scanning, nothing found)
      SharedWidgets.EmptyState {
        Layout.fillWidth: true
        Layout.topMargin: Appearance.spacingLG
        visible: root.effectiveBtEnabled && !root.isScanning && root.connectedCount === 0 && root.pairedCount === 0 && root.availableCount === 0
        icon: "bluetooth.svg"
        message: "No devices found"
      }
  }
}
