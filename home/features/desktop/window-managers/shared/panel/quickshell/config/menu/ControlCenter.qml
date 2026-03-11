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
  signal closeRequested()
  visible: showContent || sidebarContent.x < Config.controlCenterWidth
  property real displayOutputVolume: 0
  property real displayInputVolume: 0
  property bool displayOutputMuted: false
  property bool displayInputMuted: false

  function refreshAudioState() {
    outputVolumeProc.running = true;
    inputVolumeProc.running = true;
  }

  Process {
    id: outputVolumeProc
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var text = (this.text || "").trim();
        var match = text.match(/Volume:\s+([0-9.]+)(?:\s+\[MUTED\])?/);
        if (!match) {
          root.displayOutputVolume = 0;
          root.displayOutputMuted = false;
          return;
        }

        var parsed = parseFloat(match[1]);
        root.displayOutputVolume = isNaN(parsed) ? 0 : Colors.clamp01(parsed);
        root.displayOutputMuted = text.indexOf("[MUTED]") !== -1;
      }
    }
  }

  Process {
    id: inputVolumeProc
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var text = (this.text || "").trim();
        var match = text.match(/Volume:\s+([0-9.]+)(?:\s+\[MUTED\])?/);
        if (!match) {
          root.displayInputVolume = 0;
          root.displayInputMuted = false;
          return;
        }

        var parsed = parseFloat(match[1]);
        root.displayInputVolume = isNaN(parsed) ? 0 : Colors.clamp01(parsed);
        root.displayInputMuted = text.indexOf("[MUTED]") !== -1;
      }
    }
  }

  Timer {
    interval: 3000
    running: root.showContent
    repeat: true
    onTriggered: root.refreshAudioState()
  }

  onVisibleChanged: if (visible) root.refreshAudioState()

  function setAudioVolume(target, value) {
    var clamped = Colors.clamp01(value);
    if (clamped > 0) {
      Quickshell.execDetached(["wpctl", "set-mute", target, "0"]);
    }
    Quickshell.execDetached(["wpctl", "set-volume", target, Math.round(clamped * 100) + "%"]);
    if (target === "@DEFAULT_AUDIO_SINK@") {
      root.displayOutputVolume = clamped;
      root.displayOutputMuted = false;
      Quickshell.execDetached(["quickshell", "ipc", "call", "Osd", "showVolume", Math.round(clamped * 100).toString(), "false"]);
    } else if (target === "@DEFAULT_AUDIO_SOURCE@") {
      root.displayInputVolume = clamped;
      root.displayInputMuted = false;
      Quickshell.execDetached(["quickshell", "ipc", "call", "Osd", "showMic", Math.round(clamped * 100).toString(), "false"]);
    }
    Qt.callLater(root.refreshAudioState);
  }

  function toggleMute(target, muted) {
    Quickshell.execDetached(["wpctl", "set-mute", target, muted ? "0" : "1"]);
    if (target === "@DEFAULT_AUDIO_SINK@") {
      root.displayOutputMuted = !muted;
      Quickshell.execDetached(["quickshell", "ipc", "call", "Osd", "showVolume", Math.round(root.displayOutputVolume * 100).toString(), (!muted).toString()]);
    } else if (target === "@DEFAULT_AUDIO_SOURCE@") {
      root.displayInputMuted = !muted;
      Quickshell.execDetached(["quickshell", "ipc", "call", "Osd", "showMic", Math.round(root.displayInputVolume * 100).toString(), (!muted).toString()]);
    }
    Qt.callLater(root.refreshAudioState);
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
                color: Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.12)

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
              Process {
                id: checkNightLight; command: ["sh", "-c", "hyprctl hyprsunset temperature 2>/dev/null | grep -v '6000' >/dev/null && echo 'on' || echo 'off'"]
                running: root.showContent; stdout: StdioCollector { onStreamFinished: nightLightToggle.active = (this.text.trim() === "on") }
              }
              Timer {
                id: nightLightVerify; interval: 500; repeat: false
                onTriggered: checkNightLight.running = true
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
                Text { text: root.displayOutputMuted ? "Muted" : Math.round(root.displayOutputVolume * 100) + "%"; color: Colors.textSecondary; font.pixelSize: 10 }
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
                    text: root.displayOutputMuted ? "󰝟" : "󰕾"
                    color: root.displayOutputMuted ? Colors.error : Colors.text
                    font.family: Colors.fontMono
                    font.pixelSize: 15
                  }
                  MouseArea {
                    id: outputMuteHover
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.toggleMute("@DEFAULT_AUDIO_SINK@", root.displayOutputMuted)
                  }
                }
                Rectangle {
                  id: outputTrack
                  Layout.fillWidth: true; height: 28; color: Colors.bgWidget; radius: 14; border.color: Colors.border; border.width: 1
                  Behavior on color { ColorAnimation { duration: 150 } }
                  Behavior on border.color { ColorAnimation { duration: 150 } }
                  Rectangle {
                    height: parent.height; width: Math.max(28, parent.width * (root.displayOutputMuted ? 0 : root.displayOutputVolume)); radius: 14
                    color: root.displayOutputMuted ? Colors.error : (outputSliderHover.containsMouse ? Qt.darker(Colors.primary, 1.08) : Colors.primary)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { anchors.centerIn: parent; text: root.displayOutputMuted ? "󰝟" : "󰕾"; color: Colors.background; font.family: Colors.fontMono; font.pixelSize: 12; visible: (root.displayOutputMuted || root.displayOutputVolume > 0.1) }
                  }
                  MouseArea {
                    id: outputSliderHover
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: { outputTrack.color = Colors.surface; outputTrack.border.color = root.displayOutputMuted ? Colors.error : Colors.primary; }
                    onExited: { outputTrack.color = Colors.bgWidget; outputTrack.border.color = Colors.border; }
                    onPressed: (mouse) => { root.setAudioVolume("@DEFAULT_AUDIO_SINK@", Math.max(0, Math.min(1.0, mouse.x / width))); }
                    onPositionChanged: (mouse) => { if (pressed) root.setAudioVolume("@DEFAULT_AUDIO_SINK@", Math.max(0, Math.min(1.0, mouse.x / width))); }
                  }
                }
              }
            }

            ColumnLayout {
              Layout.fillWidth: true; spacing: 6
              RowLayout {
                Layout.fillWidth: true
                Text { text: "󰍬  INPUT"; color: Colors.textDisabled; font.pixelSize: 8; font.weight: Font.Bold }
                Item { Layout.fillWidth: true }
                Text { text: root.displayInputMuted ? "Muted" : Math.round(root.displayInputVolume * 100) + "%"; color: Colors.textSecondary; font.pixelSize: 10 }
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
                    text: root.displayInputMuted ? "󰍭" : "󰍬"
                    color: root.displayInputMuted ? Colors.error : Colors.text
                    font.family: Colors.fontMono
                    font.pixelSize: 15
                  }
                  MouseArea {
                    id: inputMuteHover
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.toggleMute("@DEFAULT_AUDIO_SOURCE@", root.displayInputMuted)
                  }
                }
                Rectangle {
                  id: inputTrack
                  Layout.fillWidth: true; height: 28; color: Colors.bgWidget; radius: 14; border.color: Colors.border; border.width: 1
                  Behavior on color { ColorAnimation { duration: 150 } }
                  Behavior on border.color { ColorAnimation { duration: 150 } }
                  Rectangle {
                    height: parent.height; width: Math.max(28, parent.width * (root.displayInputMuted ? 0 : root.displayInputVolume)); radius: 14
                    color: root.displayInputMuted ? Colors.error : (inputSliderHover.containsMouse ? Qt.darker(Colors.primary, 1.08) : Colors.primary)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { anchors.centerIn: parent; text: root.displayInputMuted ? "󰍭" : "󰍬"; color: Colors.background; font.family: Colors.fontMono; font.pixelSize: 12; visible: (root.displayInputMuted || root.displayInputVolume > 0.1) }
                  }
                  MouseArea {
                    id: inputSliderHover
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: { inputTrack.color = Colors.surface; inputTrack.border.color = root.displayInputMuted ? Colors.error : Colors.primary; }
                    onExited: { inputTrack.color = Colors.bgWidget; inputTrack.border.color = Colors.border; }
                    onPressed: (mouse) => { root.setAudioVolume("@DEFAULT_AUDIO_SOURCE@", Math.max(0, Math.min(1.0, mouse.x / width))); }
                    onPositionChanged: (mouse) => { if (pressed) root.setAudioVolume("@DEFAULT_AUDIO_SOURCE@", Math.max(0, Math.min(1.0, mouse.x / width))); }
                  }
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
            Behavior on color { ColorAnimation { duration: 160 } }
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
