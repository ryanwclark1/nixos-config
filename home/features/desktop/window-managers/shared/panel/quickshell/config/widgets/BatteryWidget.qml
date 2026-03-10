import QtQuick
import Quickshell.Services.UPower
import "../modules"
import "../services"

Row {
  spacing: 6

  property var device: UPower.displayDevice
  property bool hasBattery: device != null && device.isPresent
  property bool showBattery: hasBattery && (device.kind === UPower.DeviceKindDisplayDevice || device.kind === UPower.DeviceKindBattery)

  visible: showBattery

  CircularGauge {
    value: device ? device.percentage : 0
    color: device && device.state === UPower.DeviceStateCharging ? Colors.primary : (device && device.percentage < 0.2 ? Colors.error : Colors.fgMain)
    icon: device ? (device.state === UPower.DeviceStateCharging ? "󰂄" : (device.percentage > 0.9 ? "󰁹" : (device.percentage > 0.5 ? "󰁿" : (device.percentage > 0.2 ? "󰁽" : "󰂃")))) : "󰂑"
    thickness: 3
    width: 20; height: 20
  }

  Text {
    text: showBattery ? Math.round(device.percentage * 100) + "%" : "100%"
    color: Colors.fgMain
    font.pixelSize: 11
    font.weight: Font.DemiBold
    anchors.verticalCenter: parent.verticalCenter
  }
}
