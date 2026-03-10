import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
import Quickshell.Wayland
import Quickshell.Widgets
import "."
import "../modules"
import "../services"

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
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  WlrLayershell.namespace: "quickshell"
  
  property var manager: null
  property bool showContent: false
  visible: showContent || sidebarContent.x < 350
  property real outputVolume: {
    var v = Pipewire.defaultAudioSink?.audio?.volume;
    return (v !== undefined && !isNaN(v)) ? Colors.clamp01(v) : 0;
  }
  property real inputVolume: {
    var v = Pipewire.defaultAudioSource?.audio?.volume;
    return (v !== undefined && !isNaN(v)) ? Colors.clamp01(v) : 0;
  }
  property bool outputMuted: Pipewire.defaultAudioSink?.audio?.muted ?? false
  property bool inputMuted: Pipewire.defaultAudioSource?.audio?.muted ?? false

  PwObjectTracker {
    objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
  }

  function setAudioVolume(target, value) {
    var clamped = Colors.clamp01(value);
    if (clamped > 0) {
      Quickshell.execDetached(["wpctl", "set-mute", target, "0"]);
    }
    Quickshell.execDetached(["wpctl", "set-volume", target, Math.round(clamped * 100) + "%"]);
    if (target === "@DEFAULT_AUDIO_SINK@") {
      root.outputVolume = clamped;
      root.outputMuted = false;
      Quickshell.execDetached(["quickshell", "ipc", "call", "Osd", "showVolume", Math.round(clamped * 100).toString(), "false"]);
    } else if (target === "@DEFAULT_AUDIO_SOURCE@") {
      root.inputVolume = clamped;
      root.inputMuted = false;
      Quickshell.execDetached(["quickshell", "ipc", "call", "Osd", "showMic", Math.round(clamped * 100).toString(), "false"]);
    }
  }

  function toggleMute(target, muted) {
    Quickshell.execDetached(["wpctl", "set-mute", target, muted ? "0" : "1"]);
    if (target === "@DEFAULT_AUDIO_SINK@") {
      root.outputMuted = !muted;
      Quickshell.execDetached(["quickshell", "ipc", "call", "Osd", "showVolume", Math.round(root.outputVolume * 100).toString(), (!muted).toString()]);
    } else if (target === "@DEFAULT_AUDIO_SOURCE@") {
      root.inputMuted = !muted;
      Quickshell.execDetached(["quickshell", "ipc", "call", "Osd", "showMic", Math.round(root.inputVolume * 100).toString(), (!muted).toString()]);
    }
  }

  Rectangle {
    id: sidebarContent
    width: 350; height: parent.height; color: Colors.bgGlass; border.color: Colors.border; border.width: 1; radius: Colors.radiusLarge
    x: root.showContent ? 0 : 360; opacity: root.showContent ? 1.0 : 0.0
    Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 250 } }

    Keys.onEscapePressed: root.showContent = false

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
            onClicked: { root.showContent = false; Quickshell.execDetached(["quickshell", "ipc", "call", "SettingsHub", "toggle"]); }
          }
        }
        Rectangle {
          width: 32; height: 32; radius: 16; color: closeHover.containsMouse ? Colors.surface : "transparent"
          Text { anchors.centerIn: parent; text: "󰅖"; color: Colors.textSecondary; font.family: Colors.fontMono; font.pixelSize: 18 }
          MouseArea { id: closeHover; anchors.fill: parent; hoverEnabled: true; onClicked: root.showContent = false }
        }
      }

      Flickable {
        Layout.fillWidth: true; Layout.fillHeight: true; contentHeight: mainCol.height; clip: true
        boundsBehavior: Flickable.StopAtBounds; flickableDirection: Flickable.VerticalFlick
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        ColumnLayout {
          id: mainCol; width: parent.width; spacing: 20

          RowLayout {
            Layout.fillWidth: true
            spacing: 10
            visible: Config.controlCenterShowQuickLinks

            Rectangle {
              Layout.fillWidth: true
              implicitHeight: 78
              radius: Colors.radiusMedium
              color: Colors.bgWidget
              border.color: Colors.border
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12
                Text { text: "󰕾"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: 18 }
                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 2
                  Text { text: "Audio Controls"; color: Colors.fgMain; font.pixelSize: 13; font.weight: Font.DemiBold }
                  Text { text: "Switch devices, volume, mute"; color: Colors.textSecondary; font.pixelSize: 11 }
                }
                Text { text: "󰄮"; color: Colors.textSecondary; font.family: Colors.fontMono; font.pixelSize: 14 }
              }

              MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "toggleAudioMenu"]) }
            }

            Rectangle {
              Layout.fillWidth: true
              implicitHeight: 78
              radius: Colors.radiusMedium
              color: Colors.bgWidget
              border.color: Colors.border
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12
                Text { text: "󰖩"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: 18 }
                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 2
                  Text { text: "Network Controls"; color: Colors.fgMain; font.pixelSize: 13; font.weight: Font.DemiBold }
                  Text { text: "Connections, VPNs, Tailscale"; color: Colors.textSecondary; font.pixelSize: 11 }
                }
                Text { text: "󰄮"; color: Colors.textSecondary; font.family: Colors.fontMono; font.pixelSize: 14 }
              }

              MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "toggleNetworkMenu"]) }
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
              onClicked: { Quickshell.execDetached(["os-toggle-nightlight"]); active = !active; }
              Process {
                id: checkNightLight; command: ["sh", "-c", "hyprctl hyprsunset temperature 2>/dev/null | grep -v '6000' >/dev/null && echo 'on' || echo 'off'"]
                running: root.showContent; stdout: StdioCollector { onStreamFinished: nightLightToggle.active = (this.text.trim() === "on") }
              }
            }
          }

          MediaWidget {
            visible: Config.controlCenterShowMediaWidget
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
              Rectangle {
                id: brightnessTrack
                Layout.fillWidth: true; height: 28; color: Colors.bgWidget; radius: 14; border.color: Colors.border; border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Rectangle {
                  height: parent.height; width: Math.max(28, parent.width * SystemStatus.brightness); radius: 14
                  color: brightnessHover.containsMouse ? Qt.darker(Colors.primary, 1.08) : Colors.primary
                  Behavior on color { ColorAnimation { duration: 150 } }
                  Text { anchors.centerIn: parent; text: "󰃠"; color: Colors.background; font.family: Colors.fontMono; font.pixelSize: 12; visible: SystemStatus.brightness > 0.1 }
                }
                MouseArea {
                  id: brightnessHover
                  anchors.fill: parent; 
                  hoverEnabled: true
                  onEntered: { brightnessTrack.color = Colors.surface; brightnessTrack.border.color = Colors.primary; }
                  onExited: { brightnessTrack.color = Colors.bgWidget; brightnessTrack.border.color = Colors.border; }
                  onPressed: (mouse) => { SystemStatus.setBrightness(Math.max(0.01, Math.min(1.0, mouse.x / width))); }
                  onPositionChanged: (mouse) => { if (pressed) SystemStatus.setBrightness(Math.max(0.01, Math.min(1.0, mouse.x / width))); }
                }
              }
            }

            ColumnLayout {
              Layout.fillWidth: true; spacing: 6
              RowLayout {
                Layout.fillWidth: true
                Text { text: "󰕾  OUTPUT"; color: Colors.textDisabled; font.pixelSize: 8; font.weight: Font.Bold }
                Item { Layout.fillWidth: true }
                Text { text: root.outputMuted ? "Muted" : Math.round(root.outputVolume * 100) + "%"; color: Colors.textSecondary; font.pixelSize: 10 }
              }
              RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Rectangle {
                  width: 32; height: 32; radius: 16
                  color: outputMuteHover.containsMouse ? Colors.highlightLight : Colors.bgWidget
                  border.color: Colors.border
                  border.width: 1
                  Text {
                    anchors.centerIn: parent
                    text: root.outputMuted ? "󰝟" : "󰕾"
                    color: root.outputMuted ? Colors.error : Colors.text
                    font.family: Colors.fontMono
                    font.pixelSize: 15
                  }
                  MouseArea {
                    id: outputMuteHover
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.toggleMute("@DEFAULT_AUDIO_SINK@", root.outputMuted)
                  }
                }
                Slider {
                  id: outputSlider
                  Layout.fillWidth: true
                  from: 0
                  to: 1
                  value: root.outputMuted ? 0 : root.outputVolume
                  onMoved: root.setAudioVolume("@DEFAULT_AUDIO_SINK@", value)
                }
              }
            }

            ColumnLayout {
              Layout.fillWidth: true; spacing: 6
              RowLayout {
                Layout.fillWidth: true
                Text { text: "󰍬  INPUT"; color: Colors.textDisabled; font.pixelSize: 8; font.weight: Font.Bold }
                Item { Layout.fillWidth: true }
                Text { text: root.inputMuted ? "Muted" : Math.round(root.inputVolume * 100) + "%"; color: Colors.textSecondary; font.pixelSize: 10 }
              }
              RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Rectangle {
                  width: 32; height: 32; radius: 16
                  color: inputMuteHover.containsMouse ? Colors.highlightLight : Colors.bgWidget
                  border.color: Colors.border
                  border.width: 1
                  Text {
                    anchors.centerIn: parent
                    text: root.inputMuted ? "󰍭" : "󰍬"
                    color: root.inputMuted ? Colors.error : Colors.text
                    font.family: Colors.fontMono
                    font.pixelSize: 15
                  }
                  MouseArea {
                    id: inputMuteHover
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.toggleMute("@DEFAULT_AUDIO_SOURCE@", root.inputMuted)
                  }
                }
                Slider {
                  id: inputSlider
                  Layout.fillWidth: true
                  from: 0
                  to: 1
                  value: root.inputMuted ? 0 : root.inputVolume
                  onMoved: root.setAudioVolume("@DEFAULT_AUDIO_SOURCE@", value)
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
            Layout.fillWidth: true; height: 40; color: Colors.surface; radius: 8
            Text { anchors.centerIn: parent; text: modelData.icon; color: Colors.text; font.family: Colors.fontMono; font.pixelSize: 18 }
            MouseArea {
              anchors.fill: parent; hoverEnabled: true
              onEntered: parent.color = Colors.highlightLight
              onExited: parent.color = Colors.surface
              onClicked: Quickshell.execDetached(modelData.cmd)
            }
          }
        }
      }
    }
  }
}
