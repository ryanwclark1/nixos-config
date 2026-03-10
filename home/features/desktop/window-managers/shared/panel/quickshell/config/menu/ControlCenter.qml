import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Bluetooth
import Quickshell.Io
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
  
  implicitWidth: 350
  color: "transparent"
  mask: Region {
    item: sidebarContent
  }
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  WlrLayershell.namespace: "quickshell"
  
  property var manager: null
  property bool showContent: false
  visible: showContent || sidebarContent.x < 350

  onShowContentChanged: { if (showContent) sidebarContent.forceActiveFocus(); }

  // State
  property var wifiNetworks: []
  property var vpns: []
  property string tailscaleStatus: "Offline"
  property string selectedSSID: ""

  Process {
    id: getWifi
    command: ["sh", "-c", "command -v nmcli >/dev/null 2>&1 && nmcli -t -f SSID,SIGNAL,BARS dev wifi || true"]
    running: root.showContent
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = (this.text || "").trim().split("\n");
        var nets = [];
        for (var i = 0; i < Math.min(lines.length, 10); i++) {
          if (lines[i]) {
            var parts = lines[i].split(":");
            if (parts[0]) nets.push({ssid: parts[0], signal: parts[1], bars: parts[2]});
          }
        }
        root.wifiNetworks = nets;
      }
    }
  }

  Process {
    id: getVPNs
    command: ["sh", "-c", "command -v nmcli >/dev/null 2>&1 && nmcli -t -f NAME,TYPE,STATE connection show --active | grep -E 'vpn|wireguard|tun' || true"]
    running: root.showContent
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = (this.text || "").trim().split("\n");
        var activeVpns = [];
        for (var i = 0; i < lines.length; i++) {
          if (lines[i]) {
            var parts = lines[i].split(":");
            activeVpns.push({name: parts[0], type: parts[1], state: parts[2]});
          }
        }
        root.vpns = activeVpns;
      }
    }
  }

  Process {
    id: getTailscale
    command: ["sh", "-c", "command -v tailscale >/dev/null 2>&1 && tailscale status --active || echo 'Offline'"]
    running: root.showContent
    stdout: StdioCollector {
      onStreamFinished: {
        var output = (this.text || "").trim();
        if (output.includes("Tailscale is stopped")) root.tailscaleStatus = "Stopped";
        else if (output === "" || output === "Offline") root.tailscaleStatus = "Disconnected";
        else root.tailscaleStatus = "Connected";
      }
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
        Text { text: "Control Center"; color: Colors.text; font.pixelSize: 22; font.weight: Font.DemiBold; font.letterSpacing: -0.5 }
        Item { Layout.fillWidth: true }
        Rectangle {
          width: 32; height: 32; radius: 16; color: settingsHover.containsMouse ? Colors.surface : "transparent"
          Text { anchors.centerIn: parent; text: "󰒓"; color: Colors.textSecondary; font.family: Colors.fontMono; font.pixelSize: 18 }
          MouseArea { id: settingsHover; anchors.fill: parent; hoverEnabled: true; onClicked: { root.showContent = false; Quickshell.execDetached(["quickshell", "ipc", "call", "SettingsHub", "toggle"]); } }
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
              icon: "󰖩"; label: "Wi-Fi"; active: root.wifiNetworks.length > 0
              onClicked: Quickshell.execDetached(["nmcli", "radio", "wifi", active ? "off" : "on"])
            }
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
                Layout.fillWidth: true; height: 28; color: Colors.bgWidget; radius: 14; border.color: Colors.border; border.width: 1
                Rectangle {
                  height: parent.height; width: Math.max(28, parent.width * SystemStatus.brightness); radius: 14
                  color: Colors.primary
                  Text { anchors.centerIn: parent; text: "󰃠"; color: Colors.background; font.family: Colors.fontMono; font.pixelSize: 12; visible: SystemStatus.brightness > 0.1 }
                }
                MouseArea {
                  anchors.fill: parent; 
                  onPressed: (mouse) => { SystemStatus.setBrightness(Math.max(0.01, Math.min(1.0, mouse.x / width))); }
                  onPositionChanged: (mouse) => { if (pressed) SystemStatus.setBrightness(Math.max(0.01, Math.min(1.0, mouse.x / width))); }
                }
              }
            }

            ColumnLayout {
              Layout.fillWidth: true; spacing: 6
              RowLayout {
                Layout.fillWidth: true
                Text { text: "󰓃  OUTPUT VOLUME"; color: Colors.textDisabled; font.pixelSize: 8; font.weight: Font.Bold }
                Item { Layout.fillWidth: true }
                Text { 
                  text: (Pipewire.defaultAudioSink && !isNaN(Pipewire.defaultAudioSink.audio.volume)) ? Math.round(Pipewire.defaultAudioSink.audio.volume * 100) + "%" : "0%"
                  color: Colors.textSecondary; font.pixelSize: 10 
                }
              }
              Rectangle {
                Layout.fillWidth: true; height: 28; color: Colors.bgWidget; radius: 14; border.color: Colors.border; border.width: 1
                Rectangle {
                  height: parent.height; width: (Pipewire.defaultAudioSink && !isNaN(Pipewire.defaultAudioSink.audio.volume)) ? Math.max(28, parent.width * Pipewire.defaultAudioSink.audio.volume) : 0; radius: 14
                  color: Colors.primary
                  Text { anchors.centerIn: parent; text: "󰓃"; color: Colors.background; font.family: Colors.fontMono; font.pixelSize: 12; visible: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio.volume > 0.1 }
                }
                MouseArea {
                  anchors.fill: parent; 
                  onPressed: (mouse) => { if (Pipewire.defaultAudioSink) Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(1, mouse.x / width)); }
                  onPositionChanged: (mouse) => { if (pressed && Pipewire.defaultAudioSink) Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(1, mouse.x / width)); }
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

          ColumnLayout {
            width: parent.width; spacing: 15
            
            ColumnLayout {
              width: parent.width; spacing: 8; visible: root.wifiNetworks.length > 0
              Text { text: "WI-FI NETWORKS"; color: Colors.textDisabled; font.pixelSize: 8; font.weight: Font.Bold; font.capitalization: Font.AllUppercase }
              Repeater {
                model: root.wifiNetworks
                delegate: ColumnLayout {
                  width: parent.width; spacing: 4
                  Rectangle {
                    Layout.fillWidth: true; height: 35; color: Colors.highlightLight; radius: 6
                    RowLayout {
                      anchors.fill: parent; anchors.margins: Colors.paddingSmall
                      Text { text: "󰖩"; color: Colors.textSecondary; font.family: Colors.fontMono }
                      Text { text: modelData.ssid; color: Colors.text; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                      Text { text: modelData.bars; color: Colors.textDisabled; font.family: Colors.fontMono }
                    }
                    MouseArea { anchors.fill: parent; onClicked: { if (root.selectedSSID === modelData.ssid) root.selectedSSID = ""; else root.selectedSSID = modelData.ssid; } }
                  }
                  Rectangle {
                    Layout.fillWidth: true; height: 40; color: Colors.highlightLight; radius: 6; visible: root.selectedSSID === modelData.ssid
                    TextInput {
                      id: pwInput; anchors.fill: parent; anchors.margins: Colors.paddingSmall; verticalAlignment: Text.AlignVCenter; color: Colors.text; font.pixelSize: 12; echoMode: TextInput.Password; focus: parent.visible
                      Keys.onReturnPressed: { Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", modelData.ssid, "password", text]); root.selectedSSID = ""; }
                    }
                  }
                }
              }
            }

            ColumnLayout {
              width: parent.width; spacing: 8; visible: root.vpns.length > 0 || root.tailscaleStatus !== "Stopped"
              Text { text: "VPN & OVERLAYS"; color: Colors.textDisabled; font.pixelSize: 8; font.weight: Font.Bold }
              Rectangle {
                Layout.fillWidth: true; height: 40; color: Colors.highlightLight; radius: 8; visible: root.tailscaleStatus !== "Stopped"
                RowLayout {
                  anchors.fill: parent; anchors.margins: 12
                  Text { text: "󰖂"; color: root.tailscaleStatus === "Connected" ? Colors.primary : Colors.textSecondary; font.family: Colors.fontMono; font.pixelSize: 16 }
                  Text { text: "Tailscale"; color: Colors.text; font.pixelSize: 12; font.weight: Font.Medium; Layout.fillWidth: true }
                  Rectangle { width: 8; height: 8; radius: 4; color: root.tailscaleStatus === "Connected" ? Colors.primary : Colors.textDisabled }
                }
                MouseArea { anchors.fill: parent; hoverEnabled: true; onClicked: { if (root.tailscaleStatus === "Connected") Quickshell.execDetached(["tailscale", "down"]); else Quickshell.execDetached(["tailscale", "up"]); } }
              }
              Repeater {
                model: root.vpns
                delegate: Rectangle {
                  Layout.fillWidth: true; height: 40; color: Colors.highlightLight; radius: 8
                  RowLayout {
                    anchors.fill: parent; anchors.margins: 12
                    Text { text: "󰖂"; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: 16 }
                    Text { text: modelData.name; color: Colors.text; font.pixelSize: 12; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                    Text { text: modelData.type; color: Colors.textDisabled; font.pixelSize: 10; font.capitalization: Font.AllUppercase }
                  }
                  MouseArea { anchors.fill: parent; hoverEnabled: true; onClicked: Quickshell.execDetached(["nmcli", "connection", "down", modelData.name]) }
                }
              }
            }
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true; spacing: 10
        Repeater {
          model: [{ icon: "󰐥", cmd: ["systemctl", "poweroff"] }, { icon: "󰑐", cmd: ["systemctl", "reboot"] }, { icon: "󰌾", cmd: ["hyprlock"] }]
          delegate: Rectangle {
            Layout.fillWidth: true; height: 40; color: Colors.surface; radius: 8
            Text { anchors.centerIn: parent; text: modelData.icon; color: Colors.text; font.family: Colors.fontMono; font.pixelSize: 18 }
            MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: parent.color = Colors.highlightLight; onExited: parent.color = Colors.surface; onClicked: Quickshell.execDetached(modelData.cmd) }
          }
        }
      }
    }
  }
}
