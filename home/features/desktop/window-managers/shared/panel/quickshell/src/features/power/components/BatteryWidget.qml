import QtQuick
import Quickshell.Services.UPower
import "../../../system/sections"
import "../../../services"

Row {
  id: root
  spacing: Colors.spacingSM
  property bool iconOnly: false

  property var device: UPower.displayDevice
  property bool hasBattery: device != null && device.isPresent
  property bool showBattery: hasBattery && (device.kind === UPower.DeviceKindDisplayDevice || device.kind === UPower.DeviceKindBattery)
  readonly property string batteryStateText: {
    if (!device) return "Unknown";
    if (device.state === UPower.DeviceStateCharging) return "Charging";
    if (device.state === UPower.DeviceStateFullyCharged) return "Fully charged";
    if (device.state === UPower.DeviceStatePendingCharge) return "Pending charge";
    if (device.state === UPower.DeviceStatePendingDischarge) return "Pending discharge";
    return "Discharging";
  }
  readonly property string tooltipText: {
    if (!showBattery || !device) return "No battery detected";
    return Math.round(device.percentage * 100) + "% • " + batteryStateText;
  }

  visible: showBattery

  CircularGauge {
    value: device ? device.percentage : 0
    color: device && device.state === UPower.DeviceStateCharging ? Colors.primary : (device && device.percentage < 0.2 ? Colors.error : Colors.text)
    icon: device ? (device.state === UPower.DeviceStateCharging ? "󰂄" : (device.percentage > 0.9 ? "󰁹" : (device.percentage > 0.5 ? "󰁿" : (device.percentage > 0.2 ? "󰁽" : "󰂃")))) : "󰂑"
    thickness: 3
    width: 20; height: 20
  }

  Text {
    visible: !root.iconOnly
    text: showBattery && device ? Math.round(device.percentage * 100) + "%" : ""
    color: Colors.text
    font.pixelSize: Colors.fontSizeSmall
    font.weight: Font.DemiBold
    anchors.verticalCenter: parent.verticalCenter
  }
}
