import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import "../services"
import "../system/sections"
import "../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  popupMinWidth: 300; popupMaxWidth: 340; compactThreshold: 330
  readonly property int detailColumns: compactMode ? 1 : 2
  implicitHeight: compactMode ? 430 : 380
  title: "Battery"
  toggleMethod: "toggleBatteryMenu"

  property var device: UPower.displayDevice
  property bool hasBattery: device != null && device.isPresent && (device.kind === UPower.DeviceKindDisplayDevice || device.kind === UPower.DeviceKindBattery)

  SharedWidgets.Ref { service: PowerProfileService }

  onVisibleChanged: if (visible) PowerProfileService.refresh()

  readonly property string batteryStateText: {
    if (!device) return "Unknown";
    if (device.state === UPower.DeviceStateCharging) return "Charging";
    if (device.state === UPower.DeviceStateFullyCharged) return "Fully charged";
    if (device.state === UPower.DeviceStatePendingCharge) return "Pending charge";
    if (device.state === UPower.DeviceStatePendingDischarge) return "Pending discharge";
    return "Discharging";
  }

  readonly property string batteryIcon: {
    if (!device) return "󰂑";
    if (device.state === UPower.DeviceStateCharging) return "󰂄";
    if (device.percentage > 0.9) return "󰁹";
    if (device.percentage > 0.7) return "󰂀";
    if (device.percentage > 0.5) return "󰁿";
    if (device.percentage > 0.3) return "󰁾";
    if (device.percentage > 0.2) return "󰁽";
    return "󰂃";
  }

  readonly property color batteryColor: {
    if (!device) return Colors.textDisabled;
    if (device.state === UPower.DeviceStateCharging) return Colors.primary;
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
      icon: "󰂑"
      message: "No battery detected"
    }
  }

  // Battery content
  ColumnLayout {
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: Colors.spacingM
    visible: root.hasBattery

    // Battery status card
    Rectangle {
      Layout.fillWidth: true
      implicitHeight: root.compactMode ? 102 : 90
      radius: Colors.radiusMedium
      color: Colors.cardSurface
      border.color: Colors.border
      border.width: 1

      RowLayout {
        anchors.fill: parent
        anchors.margins: root.compactMode ? Colors.spacingM : Colors.spacingL
        spacing: root.compactMode ? Colors.spacingM : Colors.spacingL

        CircularGauge {
          value: root.device ? root.device.percentage : 0
          color: root.batteryColor
          icon: root.batteryIcon
          thickness: 4
          width: 56; height: 56
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Colors.spacingXXS

          Text {
            text: root.device ? Math.round(root.device.percentage * 100) + "%" : "—"
            color: root.batteryColor
            font.pixelSize: Colors.fontSizeIcon
            font.weight: Font.Bold
          }

          Text {
            text: root.batteryStateText
            color: Colors.textSecondary
            font.pixelSize: Colors.fontSizeMedium
          }

          Text {
            text: root.timeRemainingText
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeSmall
            visible: root.timeRemainingText !== ""
          }
        }
      }
    }

    // Power details grid
    Rectangle {
      Layout.fillWidth: true
      implicitHeight: detailsGrid.implicitHeight + 24
      radius: Colors.radiusMedium
      color: Colors.cardSurface
      border.color: Colors.border
      border.width: 1

      GridLayout {
        id: detailsGrid
        anchors.fill: parent
        anchors.margins: Colors.spacingM
        columns: root.detailColumns
        rowSpacing: Colors.spacingS
        columnSpacing: Colors.spacingM

        SharedWidgets.SectionLabel { label: "POWER"; Layout.columnSpan: root.detailColumns }

        Text { text: "Energy rate"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeMedium }
        Text {
          text: root.device && root.device.energyRate ? root.device.energyRate.toFixed(1) + " W" : "—"
          color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.Medium
          Layout.alignment: root.compactMode ? Qt.AlignLeft : Qt.AlignRight
        }

        Text { text: "Capacity"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeMedium }
        Text {
          text: root.device && root.device.energyFull ? root.device.energyFull.toFixed(1) + " Wh" : "—"
          color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.Medium
          Layout.alignment: root.compactMode ? Qt.AlignLeft : Qt.AlignRight
        }

        Text { text: "Health"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeMedium }
        Text {
          text: root.device && root.device.energyFullDesign > 0
            ? Math.round((root.device.energyFull / root.device.energyFullDesign) * 100) + "%"
            : "—"
          color: {
            if (!root.device || root.device.energyFullDesign <= 0) return Colors.text;
            var health = root.device.energyFull / root.device.energyFullDesign;
            return health > 0.8 ? Colors.primary : (health > 0.5 ? Colors.accent : Colors.error);
          }
          font.pixelSize: Colors.fontSizeMedium; font.weight: Font.Medium
          Layout.alignment: root.compactMode ? Qt.AlignLeft : Qt.AlignRight
        }
      }
    }

    // Power profiles
    SharedWidgets.SectionLabel {
      label: PowerProfileService.available ? "POWER PROFILE" : "POWER PROFILE UNAVAILABLE"
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Colors.spacingS
      visible: PowerProfileService.available

      Repeater {
        model: [
          { id: "power-saver", label: "Saver", icon: "󰌪" },
          { id: "balanced", label: "Balanced", icon: "󰛲" },
          { id: "performance", label: "Perform", icon: "󱐋" }
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
      visible: !PowerProfileService.available
      text: "powerprofilesctl is not available on this system."
      color: Colors.textDisabled
      font.pixelSize: Colors.fontSizeSmall
      wrapMode: Text.WordWrap
    }

    Item { Layout.fillHeight: true }
  }
}
