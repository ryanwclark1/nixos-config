import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Wayland
import Quickshell.Widgets
import "."
import "../modules"
import "../services"
import "../widgets" as SharedWidgets

PanelWindow {
  id: root

  anchors {
    top: true
    right: true
    bottom: true
  }
  margins.top: Config.barHeight + Config.barMargin + 8
  margins.right: Config.barMargin
  margins.bottom: 60

  implicitWidth: Config.controlCenterWidth
  color: "transparent"
  mask: Region {
    item: sidebarContent
  }
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  WlrLayershell.namespace: "quickshell"

  property var manager: null
  property bool showContent: false
  signal closeRequested()
  visible: showContent || sidebarContent.x < Config.controlCenterWidth

  Component.onCompleted: AudioService.subscribe()
  Component.onDestruction: AudioService.unsubscribe()

  onShowContentChanged: {
    if (showContent) SystemStatus.subscribe();
    else SystemStatus.unsubscribe();
  }

  Rectangle {
    id: sidebarContent
    width: Config.controlCenterWidth; height: parent.height; color: Colors.bgGlass; border.color: Colors.border; border.width: 1; radius: Colors.radiusLarge
    x: root.showContent ? 0 : Config.controlCenterWidth + 10; opacity: root.showContent ? 1.0 : 0.0
    Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 250 } }

    Keys.onEscapePressed: root.closeRequested()

    ColumnLayout {
      anchors.fill: parent; anchors.margins: Colors.paddingLarge; spacing: 20
      RowLayout {
        Layout.fillWidth: true
        Text { text: "Command Center"; color: Colors.text; font.pixelSize: 22; font.weight: Font.DemiBold; font.letterSpacing: -0.5 }
        Item { Layout.fillWidth: true }
        Rectangle {
          width: 32; height: 32; radius: 16; color: settingsHover.containsMouse ? Colors.surface : "transparent"
          Text { anchors.centerIn: parent; text: "󰒓"; color: Colors.textSecondary; font.family: Colors.fontMono; font.pixelSize: 18 }
          MouseArea {
            id: settingsHover; anchors.fill: parent; hoverEnabled: true
            onClicked: { root.closeRequested(); Quickshell.execDetached(["quickshell", "ipc", "call", "SettingsHub", "toggle"]); }
          }
        }
        Rectangle {
          width: 32; height: 32; radius: 16; color: closeHover.containsMouse ? Colors.surface : "transparent"
          Text { anchors.centerIn: parent; text: "󰅖"; color: Colors.textSecondary; font.family: Colors.fontMono; font.pixelSize: 18 }
          MouseArea { id: closeHover; anchors.fill: parent; hoverEnabled: true; onClicked: root.closeRequested() }
        }
      }

      Flickable {
        Layout.fillWidth: true; Layout.fillHeight: true; contentHeight: mainCol.height; clip: true
        boundsBehavior: Flickable.StopAtBounds; flickableDirection: Flickable.VerticalFlick
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
          id: mainCol; width: parent.width; spacing: 20

          component QuickLinkCard: Rectangle {
            property string icon
            property string title
            property string subtitle
            property var clickCommand: []

            Layout.fillWidth: true
            implicitHeight: 68
            radius: Colors.radiusMedium
            color: quickLinkHover.containsMouse ? Colors.highlightLight : Colors.bgWidget
            border.color: Colors.border
            border.width: 1

            RowLayout {
              anchors.fill: parent
              anchors.margins: 14
              spacing: 12

              Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 18
                color: Colors.withAlpha(Colors.primary, 0.12)

                Text {
                  anchors.centerIn: parent
                  text: icon
                  color: Colors.primary
                  font.family: Colors.fontMono
                  font.pixelSize: 16
                }
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                  text: title
                  color: Colors.fgMain
                  font.pixelSize: 12
                  font.weight: Font.DemiBold
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }

                Text {
                  text: subtitle
                  color: Colors.textSecondary
                  font.pixelSize: 10
                  Layout.fillWidth: true
                  elide: Text.ElideRight
                }
              }

              Text {
                text: "󰄮"
                color: Colors.textSecondary
                font.family: Colors.fontMono
                font.pixelSize: 13
              }
            }

            MouseArea {
              id: quickLinkHover
              anchors.fill: parent
              hoverEnabled: true
              onClicked: Quickshell.execDetached(clickCommand)
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: Config.controlCenterShowQuickLinks

            QuickLinkCard {
              icon: "󰕾"
              title: "Audio Controls"
              subtitle: "Devices, volume, and mute"
              clickCommand: ["quickshell", "ipc", "call", "Shell", "toggleAudioMenu"]
            }

            QuickLinkCard {
              icon: "󰖩"
              title: "Network Controls"
              subtitle: "Wi-Fi, VPN, and Tailscale"
              clickCommand: ["quickshell", "ipc", "call", "Shell", "toggleNetworkMenu"]
            }
          }

          UserWidget {
            opacity: root.showContent ? 1 : 0
            scale: root.showContent ? 1 : 0.95
            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }
          }

          // Quick Toggles Grid
          GridLayout {
            columns: 2; Layout.fillWidth: true; rowSpacing: 10; columnSpacing: 10
            opacity: root.showContent ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }

            QuickToggle {
              icon: "󰂯"; label: "Bluetooth"; active: !!(Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled)
              onClicked: { if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled; }
            }
            QuickToggle {
              icon: "󰒲"; label: "DND"; active: !!(root.manager && root.manager.dndEnabled)
              onClicked: { if (root.manager) root.manager.dndEnabled = !root.manager.dndEnabled; }
            }
            QuickToggle {
              id: nightLightToggle; icon: "󰖔"; label: "Night Light"; active: false
              onClicked: { Quickshell.execDetached(["os-toggle-nightlight"]); active = !active; nightLightVerify.restart(); }
              SharedWidgets.CommandPoll {
                id: nightLightPoll
                interval: 5000
                running: root.showContent
                command: ["sh", "-c", "hyprctl hyprsunset temperature 2>/dev/null | grep -v '6000' >/dev/null && echo 'on' || echo 'off'"]
                parse: function(out) { return String(out || "").trim(); }
                onUpdated: nightLightToggle.active = (nightLightPoll.value === "on")
              }
              Timer {
                id: nightLightVerify; interval: 500; repeat: false
                onTriggered: nightLightPoll.poll()
              }
            }
          }

          MediaWidget {
            opacity: root.showContent ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
          }

          // Sliders
          ColumnLayout {
            Layout.fillWidth: true; spacing: 15
            opacity: root.showContent ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 550; easing.type: Easing.OutCubic } }

            ColumnLayout {
              Layout.fillWidth: true; spacing: 6
              RowLayout {
                Layout.fillWidth: true
                Text { text: "󰃠  BRIGHTNESS"; color: Colors.textDisabled; font.pixelSize: 8; font.weight: Font.Bold }
                Item { Layout.fillWidth: true }
                Text { text: Math.round(SystemStatus.brightness * 100) + "%"; color: Colors.textSecondary; font.pixelSize: 10 }
              }
              SharedWidgets.SliderTrack {
                Layout.fillWidth: true
                value: SystemStatus.brightness
                icon: "󰃠"
                onSliderMoved: (v) => SystemStatus.setBrightness(Math.max(0.01, v))
              }
            }

            ColumnLayout {
              Layout.fillWidth: true; spacing: 6
              RowLayout {
                Layout.fillWidth: true
                Text { text: "󰕾  OUTPUT"; color: Colors.textDisabled; font.pixelSize: 8; font.weight: Font.Bold }
                Item { Layout.fillWidth: true }
                Text { text: AudioService.outputMuted ? "Muted" : Math.round(AudioService.outputVolume * 100) + "%"; color: Colors.textSecondary; font.pixelSize: 10 }
              }
              RowLayout {
                Layout.fillWidth: true
                spacing: 10
                SharedWidgets.MuteButton {
                  target: "@DEFAULT_AUDIO_SINK@"
                  muted: AudioService.outputMuted
                  icon: "󰕾"; mutedIcon: "󰝟"
                  size: 32; showBorder: true
                }
                SharedWidgets.SliderTrack {
                  Layout.fillWidth: true
                  value: AudioService.outputVolume
                  muted: AudioService.outputMuted
                  icon: "󰕾"
                  mutedIcon: "󰝟"
                  onSliderMoved: (v) => AudioService.setVolume("@DEFAULT_AUDIO_SINK@", v)
                }
              }
            }

            ColumnLayout {
              Layout.fillWidth: true; spacing: 6
              RowLayout {
                Layout.fillWidth: true
                Text { text: "󰍬  INPUT"; color: Colors.textDisabled; font.pixelSize: 8; font.weight: Font.Bold }
                Item { Layout.fillWidth: true }
                Text { text: AudioService.inputMuted ? "Muted" : Math.round(AudioService.inputVolume * 100) + "%"; color: Colors.textSecondary; font.pixelSize: 10 }
              }
              RowLayout {
                Layout.fillWidth: true
                spacing: 10
                SharedWidgets.MuteButton {
                  target: "@DEFAULT_AUDIO_SOURCE@"
                  muted: AudioService.inputMuted
                  icon: "󰍬"; mutedIcon: "󰍭"
                  size: 32; showBorder: true
                }
                SharedWidgets.SliderTrack {
                  Layout.fillWidth: true
                  value: AudioService.inputVolume
                  muted: AudioService.inputMuted
                  icon: "󰍬"
                  mutedIcon: "󰍭"
                  onSliderMoved: (v) => AudioService.setVolume("@DEFAULT_AUDIO_SOURCE@", v)
                }
              }
            }

          }

          RowLayout {
            Layout.fillWidth: true; spacing: 12
            opacity: root.showContent ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
            Rectangle {
              Layout.fillWidth: true; height: 60; color: Colors.bgWidget; radius: 10; border.color: Colors.border; border.width: 1
              Column { anchors.centerIn: parent; spacing: 2
                Text { text: "CPU TEMP"; color: Colors.textDisabled; font.pixelSize: 8; font.weight: Font.Bold }
                Text { text: SystemStatus.cpuTemp; color: Colors.primary; font.pixelSize: 14; font.weight: Font.Bold }
              }
            }
            Rectangle {
              Layout.fillWidth: true; height: 60; color: Colors.bgWidget; radius: 10; border.color: Colors.border; border.width: 1
              Column { anchors.centerIn: parent; spacing: 2
                Text { text: "GPU TEMP"; color: Colors.textDisabled; font.pixelSize: 8; font.weight: Font.Bold }
                Text { text: SystemStatus.gpuTemp; color: Colors.accent; font.pixelSize: 14; font.weight: Font.Bold }
              }
            }
          }

          SystemGraphs { opacity: root.showContent ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 650; easing.type: Easing.OutCubic } } }
          ProcessWidget { opacity: root.showContent ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } } }
          NetworkGraphs {}
          DiskWidget {}
          GPUWidget {}
          UpdateWidget { opacity: root.showContent ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 750; easing.type: Easing.OutCubic } } }
          ScratchpadWidget {}

        }
      }

      RowLayout {
        Layout.fillWidth: true; spacing: 10
        Repeater {
          model: [{ icon: "󰐥", cmd: ["systemctl", "poweroff"] }, { icon: "󰑐", cmd: ["systemctl", "reboot"] }, { icon: "󰌾", cmd: ["hyprlock"] }]
          delegate: Rectangle {
            Layout.fillWidth: true; height: 40
            color: powerHover.containsMouse ? Colors.highlightLight : Colors.surface
            radius: 8
            Behavior on color { ColorAnimation { duration: 160 } }
            Text { anchors.centerIn: parent; text: modelData.icon; color: Colors.text; font.family: Colors.fontMono; font.pixelSize: 18 }
            MouseArea {
              id: powerHover
              anchors.fill: parent; hoverEnabled: true
              onClicked: Quickshell.execDetached(modelData.cmd)
            }
          }
        }
      }
    }
  }
}
