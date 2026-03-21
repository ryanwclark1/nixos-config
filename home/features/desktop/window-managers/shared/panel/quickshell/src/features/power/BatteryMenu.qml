import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import "../../shared"
import "../../services"
import "../system/sections"
import "../../widgets" as SharedWidgets
import "BatteryHelpers.js" as BatteryHelpers

BasePopupMenu {
  id: root
  popupMinWidth: 300; popupMaxWidth: 340; compactThreshold: 330
  readonly property int detailColumns: compactMode ? 1 : 2
  implicitHeight: compactMode ? 430 : 380
  title: "Battery"

  property var device: UPower.displayDevice
  property bool hasBattery: device != null && device.isPresent

  // UPower.displayDevice is an aggregate: energy fields map to changeRate / energyCapacity in Quickshell.
  // Health (Capacity) is often 0 on DisplayDevice; prefer the physical laptop battery from UPower.devices.
  readonly property int _upowerDeviceCount: (UPower.devices && UPower.devices.values) ? UPower.devices.values.length : 0
  readonly property var _healthSourceDevice: {
    var m = UPower.devices;
    if (m && m.values) {
      // Touch _upowerDeviceCount so we rebind when the model count changes (no countChanged on ObjectModel).
      for (var i = 0; i < m.values.length && root._upowerDeviceCount >= 0; i++) {
        var d = m.values[i];
        if (d && d.isLaptopBattery && d.healthSupported) return d;
      }
    }
    return (root.device && root.device.healthSupported) ? root.device : null;
  }

  readonly property real _healthPercentRaw: _healthSourceDevice ? _healthSourceDevice.healthPercentage : -1

  readonly property string batteryStateText: BatteryHelpers.stateText(device, UPower)

  readonly property string batteryIcon: BatteryHelpers.iconName(device, UPower)

  readonly property color batteryColor: {
    if (!device) return Colors.textDisabled;
    if (device.state === UPower.DeviceStateCharging
        || (device.timeToFull > 0 && !(device.timeToEmpty > 0))) return Colors.primary;
    if (device.percentage < 0.2) return Colors.error;
    if (device.percentage < 0.4) return Colors.accent;
    return Colors.primary;
  }

  readonly property string timeRemainingText: {
    if (!device) return "";
    var secs = device.timeToEmpty > 0 ? device.timeToEmpty : device.timeToFull;
    if (secs <= 0) return "";
    var hours = Math.floor(secs / 3600);
    var mins = Math.floor((secs % 3600) / 60);
    var label = device.timeToEmpty > 0 ? "remaining" : "to full";
    if (hours > 0) return hours + "h " + mins + "m " + label;
    return mins + "m " + label;
  }

  // No battery state
  Item {
    Layout.fillWidth: true
    Layout.fillHeight: true
    visible: !root.hasBattery

    SharedWidgets.EmptyState {
      anchors.centerIn: parent
      icon: "battery-full.svg"
      message: "No battery detected"
    }
  }

  // Battery content
  ColumnLayout {
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: Appearance.spacingM
    visible: root.hasBattery

    // Battery status card
    Rectangle {
      Layout.fillWidth: true
      implicitHeight: root.compactMode ? 102 : 90
      radius: Appearance.radiusMedium
      color: Colors.cardSurface
      border.color: Colors.border
      border.width: 1

      RowLayout {
        anchors.fill: parent
        anchors.margins: root.compactMode ? Appearance.spacingM : Appearance.spacingL
        spacing: root.compactMode ? Appearance.spacingM : Appearance.spacingL

        CircularGauge {
          value: root.device ? root.device.percentage : 0
          color: root.batteryColor
          icon: root.batteryIcon
          thickness: 4
          width: 56; height: 56
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Appearance.spacingXXS

          Text {
            text: root.device ? Math.round(root.device.percentage * 100) + "%" : "—"
            color: root.batteryColor
            font.pixelSize: Appearance.fontSizeIcon
            font.weight: Font.Bold
          }

          Text {
            text: root.batteryStateText
            color: Colors.textSecondary
            font.pixelSize: Appearance.fontSizeMedium
          }

          Text {
            text: root.timeRemainingText
            color: Colors.textDisabled
            font.pixelSize: Appearance.fontSizeSmall
            visible: root.timeRemainingText !== ""
          }
        }
      }
    }

    // Power details grid
    Rectangle {
      Layout.fillWidth: true
      implicitHeight: detailsGrid.implicitHeight + Appearance.paddingLarge
      radius: Appearance.radiusMedium
      color: Colors.cardSurface
      border.color: Colors.border
      border.width: 1

      GridLayout {
        id: detailsGrid
        anchors.fill: parent
        anchors.margins: Appearance.spacingM
        columns: root.detailColumns
        rowSpacing: Appearance.spacingS
        columnSpacing: Appearance.spacingM

        SharedWidgets.SectionLabel { label: "POWER"; Layout.columnSpan: root.detailColumns }

        Text { text: "Energy rate"; color: Colors.textSecondary; font.pixelSize: Appearance.fontSizeMedium }
        Text {
          text: (root.device && root.device.ready)
            ? Math.abs(root.device.changeRate).toFixed(1) + " W"
            : "—"
          color: Colors.text; font.pixelSize: Appearance.fontSizeMedium; font.weight: Font.Medium
          Layout.alignment: root.compactMode ? Qt.AlignLeft : Qt.AlignRight
        }

        Text { text: "Capacity"; color: Colors.textSecondary; font.pixelSize: Appearance.fontSizeMedium }
        Text {
          text: (root.device && root.device.ready && root.device.energyCapacity > 0)
            ? root.device.energyCapacity.toFixed(1) + " Wh"
            : "—"
          color: Colors.text; font.pixelSize: Appearance.fontSizeMedium; font.weight: Font.Medium
          Layout.alignment: root.compactMode ? Qt.AlignLeft : Qt.AlignRight
        }

        Text { text: "Health"; color: Colors.textSecondary; font.pixelSize: Appearance.fontSizeMedium }
        Text {
          text: root._healthPercentRaw >= 0
            ? (root._healthPercentRaw > 1 ? Math.round(root._healthPercentRaw) : Math.round(root._healthPercentRaw * 100)) + "%"
            : "—"
          color: {
            if (root._healthPercentRaw < 0) return Colors.text;
            var p = root._healthPercentRaw > 1 ? root._healthPercentRaw / 100 : root._healthPercentRaw;
            return p > 0.8 ? Colors.primary : (p > 0.5 ? Colors.accent : Colors.error);
          }
          font.pixelSize: Appearance.fontSizeMedium; font.weight: Font.Medium
          Layout.alignment: root.compactMode ? Qt.AlignLeft : Qt.AlignRight
        }
      }
    }

    // Power profiles
    SharedWidgets.SectionLabel {
      label: PowerProfileService.available
        ? "POWER PROFILE"
        : (PowerProfileService.availabilityKnown ? "POWER PROFILE UNAVAILABLE" : "POWER PROFILE")
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Appearance.spacingS
      visible: PowerProfileService.available

      Repeater {
        model: [
          { id: "power-saver", label: "Saver", icon: "leaf-two.svg" },
          { id: "balanced", label: "Balanced", icon: "scales.svg" },
          { id: "performance", label: "Perform", icon: "flash-on.svg" }
        ]
        delegate: SharedWidgets.FilterChip {
          Layout.fillWidth: true
          icon: modelData.icon
          label: modelData.label
          selected: PowerProfileService.currentProfile === modelData.id
          onClicked: PowerProfileService.setProfile(modelData.id)
        }
      }
    }

    Text {
      Layout.fillWidth: true
      visible: PowerProfileService.availabilityKnown && !PowerProfileService.available
      text: "powerprofilesctl is not available on this system."
      color: Colors.textDisabled
      font.pixelSize: Appearance.fontSizeSmall
      wrapMode: Text.WordWrap
    }

    Item { Layout.fillHeight: true }
  }
}
