import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.UPower
import "../services"
import "../modules"
import "../widgets" as SharedWidgets

PopupWindow {
  id: root
  implicitWidth: 340
  implicitHeight: 380

  property var device: UPower.displayDevice
  property bool hasBattery: device != null && device.isPresent && (device.kind === UPower.DeviceKindDisplayDevice || device.kind === UPower.DeviceKindBattery)
  property string currentProfile: "balanced"

  function refreshProfile() {
    profilePoll.poll();
  }

  function setProfile(profile) {
    Quickshell.execDetached(["powerprofilesctl", "set", profile]);
    root.currentProfile = profile;
  }

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

  SharedWidgets.CommandPoll {
    id: profilePoll
    interval: 5000
    running: root.visible
    command: ["powerprofilesctl", "get"]
    onUpdated: { if (profilePoll.value) root.currentProfile = profilePoll.value; }
  }

  onVisibleChanged: if (visible) refreshProfile()

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

      // Header
      RowLayout {
        Layout.fillWidth: true
        Text {
          text: "Battery"
          color: Colors.fgMain
          font.pixelSize: 18
          font.weight: Font.DemiBold
        }
        Item { Layout.fillWidth: true }
        SharedWidgets.MenuCloseButton { toggleMethod: "toggleBatteryMenu" }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Colors.border
      }

      // No battery state
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        visible: !root.hasBattery

        Text {
          anchors.centerIn: parent
          text: "No battery detected"
          color: Colors.textDisabled
          font.pixelSize: 14
        }
      }

      // Battery content
      ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 14
        visible: root.hasBattery

        // Battery status card
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 90
          radius: Colors.radiusMedium
          color: Colors.cardSurface
          border.color: Colors.border
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            CircularGauge {
              value: root.device ? root.device.percentage : 0
              color: root.batteryColor
              icon: root.batteryIcon
              thickness: 4
              width: 56; height: 56
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 2

              Text {
                text: root.device ? Math.round(root.device.percentage * 100) + "%" : "—"
                color: root.batteryColor
                font.pixelSize: 32
                font.weight: Font.Bold
              }

              Text {
                text: root.batteryStateText
                color: Colors.fgSecondary
                font.pixelSize: 12
              }

              Text {
                text: root.timeRemainingText
                color: Colors.textDisabled
                font.pixelSize: 11
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
            anchors.margins: 12
            columns: 2
            rowSpacing: 8
            columnSpacing: 12

            Text { text: "POWER"; color: Colors.textDisabled; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 0.5; Layout.columnSpan: 2 }

            Text { text: "Energy rate"; color: Colors.fgSecondary; font.pixelSize: 12 }
            Text {
              text: root.device && root.device.energyRate ? root.device.energyRate.toFixed(1) + " W" : "—"
              color: Colors.fgMain; font.pixelSize: 12; font.weight: Font.Medium
              Layout.alignment: Qt.AlignRight
            }

            Text { text: "Capacity"; color: Colors.fgSecondary; font.pixelSize: 12 }
            Text {
              text: root.device && root.device.energyFull ? root.device.energyFull.toFixed(1) + " Wh" : "—"
              color: Colors.fgMain; font.pixelSize: 12; font.weight: Font.Medium
              Layout.alignment: Qt.AlignRight
            }

            Text { text: "Health"; color: Colors.fgSecondary; font.pixelSize: 12 }
            Text {
              text: root.device && root.device.energyFullDesign > 0
                ? Math.round((root.device.energyFull / root.device.energyFullDesign) * 100) + "%"
                : "—"
              color: {
                if (!root.device || root.device.energyFullDesign <= 0) return Colors.fgMain;
                var health = root.device.energyFull / root.device.energyFullDesign;
                return health > 0.8 ? Colors.primary : (health > 0.5 ? Colors.accent : Colors.error);
              }
              font.pixelSize: 12; font.weight: Font.Medium
              Layout.alignment: Qt.AlignRight
            }
          }
        }

        // Power profiles
        Text {
          text: "POWER PROFILE"
          color: Colors.textDisabled
          font.pixelSize: 10
          font.weight: Font.Bold
          font.letterSpacing: 0.5
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: 8

          Repeater {
            model: [
              { id: "power-saver", label: "Saver", icon: "󰌪" },
              { id: "balanced", label: "Balanced", icon: "󰛲" },
              { id: "performance", label: "Perform", icon: "󱐋" }
            ]
            delegate: Rectangle {
              Layout.fillWidth: true
              implicitHeight: 50
              radius: Colors.radiusMedium
              property bool isActive: root.currentProfile === modelData.id
              property bool isHovered: profileMouse.containsMouse
              color: isActive ? Colors.withAlpha(Colors.primary, 0.2) : (isHovered ? Colors.highlightLight : Colors.cardSurface)
              border.color: isActive ? Colors.primary : Colors.border
              border.width: 1
              Behavior on color { ColorAnimation { duration: 150 } }

              ColumnLayout {
                anchors.centerIn: parent
                spacing: 2
                Text {
                  text: modelData.icon
                  color: isActive ? Colors.primary : Colors.textSecondary
                  font.family: Colors.fontMono
                  font.pixelSize: 18
                  Layout.alignment: Qt.AlignHCenter
                }
                Text {
                  text: modelData.label
                  color: isActive ? Colors.primary : Colors.fgMain
                  font.pixelSize: 10
                  font.weight: isActive ? Font.Bold : Font.Normal
                  Layout.alignment: Qt.AlignHCenter
                }
              }

              MouseArea {
                id: profileMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.setProfile(modelData.id)
              }
            }
          }
        }

        Item { Layout.fillHeight: true }
      }
    }
  }
}
