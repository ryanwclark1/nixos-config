import QtQuick
import Quickshell.Services.UPower
import "../../system/sections"
import "../../../services"
import "../BatteryHelpers.js" as BatteryHelpers

Row {
  id: root
  spacing: Appearance.spacingSM * iconScale
  property bool iconOnly: false
  property real iconScale: 1.0
  property real fontScale: 1.0

  property var device: UPower.displayDevice
  property bool hasBattery: device != null && device.isPresent
  readonly property bool showBattery: hasBattery
  readonly property string batteryStateText: BatteryHelpers.stateText(device, UPower)
  readonly property bool onAcPower: BatteryHelpers.isAcPowered(device, UPower)
  readonly property color gaugeColor: {
    if (!device) return Colors.text;
    if (onAcPower) return Colors.primary;
    return device.percentage < 0.2 ? Colors.error : Colors.text;
  }
  readonly property string tooltipText: {
    if (!showBattery || !device) return "No battery detected";
    return Math.round(device.percentage * 100) + "% • " + batteryStateText;
  }

  visible: showBattery

  CircularGauge {
    value: device ? device.percentage : 0
    color: root.gaugeColor
    icon: BatteryHelpers.iconName(device, UPower)
    thickness: root.onAcPower ? 4 : 3
    width: 20 * root.iconScale; height: 20 * root.iconScale
    iconScale: root.iconScale
  }

  Text {
    visible: !root.iconOnly
    text: showBattery && device ? Math.round(device.percentage * 100) + "%" : ""
    color: root.gaugeColor
    font.pixelSize: Appearance.fontSizeSmall * root.fontScale
    font.weight: Font.DemiBold
    anchors.verticalCenter: parent.verticalCenter
  }
}
