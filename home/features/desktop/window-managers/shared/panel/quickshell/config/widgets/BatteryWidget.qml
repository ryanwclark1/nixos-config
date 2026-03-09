import QtQuick
import Quickshell.Services.UPower

Row {
  spacing: 6
  anchors.verticalCenter: parent.verticalCenter

  property var device: UPower.displayDevice
  property bool hasBattery: device != null && device.isPresent
  property bool showBattery: hasBattery && device.isLaptopBattery

  visible: showBattery

  Text {
    text: showBattery ? (device.state == 1 ? "󰂄" : "󰁹") : "󰂑"
    color: showBattery && device.state == 1 ? "#4caf50" : (showBattery && device.percentage < 0.2 ? "#f44336" : "#e6e6e6")
    font.pixelSize: 16
    font.family: "JetBrainsMono Nerd Font"
    anchors.verticalCenter: parent.verticalCenter
  }

  Text {
    text: showBattery ? Math.round(device.percentage * 100) + "%" : "100%"
    color: "#e6e6e6"
    font.pixelSize: 12
    anchors.verticalCenter: parent.verticalCenter
  }
}
