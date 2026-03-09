import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Wayland
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
  mask: Region {}
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  WlrLayershell.namespace: "quickshell"
  WlrLayershell.blur: Config.blurEnabled
  
  property bool showContent: false
  visible: showContent || sidebarContent.x < 350

  onShowContentChanged: { if (showContent) sidebarContent.forceActiveFocus(); }

  Keys.onEscapePressed: root.showContent = false

  // State
  property real brightnessValue: 0.7
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

    ColumnLayout {
      anchors.fill: parent; anchors.margins: 24; spacing: 20      
      RowLayout {
        Layout.fillWidth: true
        Text { text: "Control Center"; color: Colors.text; font.pixelSize: 22; font.weight: Font.DemiBold; font.letterSpacing: -0.5 }
        Item { Layout.fillWidth: true }
        Rectangle {
          width: 32; height: 32; radius: 16; color: settingsHover.containsMouse ? Colors.surface : "transparent"
          Text { anchors.centerIn: parent; text: "󰒓"; color: Colors.textSecondary; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18 }
          MouseArea { id: settingsHover; anchors.fill: parent; hoverEnabled: true; onClicked: { root.showContent = false; Quickshell.execDetached(["quickshell", "ipc", "call", "SettingsHub", "toggle"]); } }
        }
      }

      UserWidget {}
      UpdateWidget {}
      MediaWidget {}

      // Quick Toggles (Night Light, DND)
      RowLayout {
        Layout.fillWidth: true; spacing: 12
        Rectangle {
          Layout.fillWidth: true; height: 50; color: root.nightLightActive ? Colors.primary : Colors.highlightLight; radius: 10
          property bool nightLightActive: false // We'll update this with a Process later
          RowLayout {
            anchors.centerIn: parent; spacing: 8
            Text { text: "󰖔"; color: parent.parent.nightLightActive ? Colors.background : Colors.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16 }
            Text { text: "Night Light"; color: parent.parent.nightLightActive ? Colors.background : Colors.text; font.pixelSize: 12; font.weight: Font.Medium }
          }
          MouseArea { anchors.fill: parent; onClicked: { Quickshell.execDetached(["os-toggle-nightlight"]); parent.nightLightActive = !parent.nightLightActive; } }
          
          Process {
            id: checkNightLight
            command: ["sh", "-c", "hyprctl hyprsunset temperature 2>/dev/null | grep -v '6000' >/dev/null && echo 'on' || echo 'off'"]
            running: root.showContent
            stdout: StdioCollector {
              onStreamFinished: {
                if (this.text.trim() === "on") parent.nightLightActive = true;
                else parent.nightLightActive = false;
              }
            }
          }
        }
        Rectangle {
          Layout.fillWidth: true; height: 50; color: root.manager && root.manager.dndEnabled ? Colors.primary : Colors.highlightLight; radius: 10
          RowLayout {
            anchors.centerIn: parent; spacing: 8
            Text { text: "󰂛"; color: root.manager && root.manager.dndEnabled ? Colors.background : Colors.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16 }
            Text { text: "DND"; color: root.manager && root.manager.dndEnabled ? Colors.background : Colors.text; font.pixelSize: 12; font.weight: Font.Medium }
          }
          MouseArea { anchors.fill: parent; onClicked: { if (root.manager) root.manager.dndEnabled = !root.manager.dndEnabled; } }
        }
      }

      // Brightness & Volume Sliders
      ColumnLayout {
        Layout.fillWidth: true; spacing: 15
        
        // Brightness Slider
        ColumnLayout {
          Layout.fillWidth: true; spacing: 6
          RowLayout {
            Layout.fillWidth: true
            Text { text: "󰃠  BRIGHTNESS"; color: Colors.textDisabled; font.pixelSize: 8; font.weight: Font.Bold }
            Item { Layout.fillWidth: true }
            Text { text: Math.round(SystemStatus.brightness * 100) + "%"; color: Colors.textSecondary; font.pixelSize: 10 }
          }
          Rectangle {
            Layout.fillWidth: true; height: 24; color: Colors.highlightLight; radius: 12
            Rectangle {
              height: parent.height; width: Math.max(24, parent.width * SystemStatus.brightness); radius: 12
              color: Colors.primary
              Text { anchors.centerIn: parent; text: "󰃠"; color: Colors.background; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; visible: SystemStatus.brightness > 0.1 }
            }
            MouseArea {
              anchors.fill: parent; 
              onPressed: (mouse) => { SystemStatus.setBrightness(Math.max(0.01, Math.min(1.0, mouse.x / width))); }
              onPositionChanged: (mouse) => { if (pressed) SystemStatus.setBrightness(Math.max(0.01, Math.min(1.0, mouse.x / width))); }
            }
          }
        }

        // Output Volume Slider
        ColumnLayout {
          Layout.fillWidth: true; spacing: 6
          RowLayout {
            Layout.fillWidth: true
            Text { text: "󰓃  OUTPUT VOLUME"; color: Colors.textDisabled; font.pixelSize: 8; font.weight: Font.Bold }
            Item { Layout.fillWidth: true }
            Text { text: Pipewire.defaultAudioSink ? Math.round(Pipewire.defaultAudioSink.audio.volume * 100) + "%" : "0%"; color: Colors.textSecondary; font.pixelSize: 10 }
          }
          Rectangle {
            Layout.fillWidth: true; height: 24; color: Colors.highlightLight; radius: 12
            Rectangle {
              height: parent.height; width: Pipewire.defaultAudioSink ? Math.max(24, parent.width * Pipewire.defaultAudioSink.audio.volume) : 0; radius: 12
              color: Colors.primary
              Text { anchors.centerIn: parent; text: "󰓃"; color: Colors.background; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; visible: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio.volume > 0.1 }
            }
            MouseArea {
              anchors.fill: parent; 
              onPressed: (mouse) => { if (Pipewire.defaultAudioSink) Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(1, mouse.x / width)); }
              onPositionChanged: (mouse) => { if (pressed && Pipewire.defaultAudioSink) Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(1, mouse.x / width)); }
            }
          }
        }

        // Input Volume Slider (Microphone)
        ColumnLayout {
          Layout.fillWidth: true; spacing: 6; visible: Pipewire.defaultAudioSource !== null
          RowLayout {
            Layout.fillWidth: true
            Text { text: "󰍬  INPUT VOLUME"; color: Colors.textDisabled; font.pixelSize: 8; font.weight: Font.Bold }
            Item { Layout.fillWidth: true }
            Text { text: Pipewire.defaultAudioSource ? Math.round(Pipewire.defaultAudioSource.audio.volume * 100) + "%" : "0%"; color: Colors.textSecondary; font.pixelSize: 10 }
          }
          Rectangle {
            Layout.fillWidth: true; height: 24; color: Colors.highlightLight; radius: 12
            Rectangle {
              height: parent.height; width: Pipewire.defaultAudioSource ? Math.max(24, parent.width * Pipewire.defaultAudioSource.audio.volume) : 0; radius: 12
              color: Colors.accent || Colors.primary
              Text { anchors.centerIn: parent; text: "󰍬"; color: Colors.background; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; visible: Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio.volume > 0.1 }
            }
            MouseArea {
              anchors.fill: parent; 
              onPressed: (mouse) => { if (Pipewire.defaultAudioSource) Pipewire.defaultAudioSource.audio.volume = Math.max(0, Math.min(1, mouse.x / width)); }
              onPositionChanged: (mouse) => { if (pressed && Pipewire.defaultAudioSource) Pipewire.defaultAudioSource.audio.volume = Math.max(0, Math.min(1, mouse.x / width)); }
            }
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true; spacing: 12
        Rectangle {
          Layout.fillWidth: true; height: 60; color: Colors.highlightLight; radius: 10
          Column { anchors.centerIn: parent; spacing: 2
            Text { text: "CPU TEMP"; color: Colors.textDisabled; font.pixelSize: 8; font.weight: Font.Bold; anchors.horizontalCenter: parent }
            Text { text: SystemStatus.cpuTemp; color: Colors.text; font.pixelSize: 14; font.weight: Font.Bold; anchors.horizontalCenter: parent }
          }
        }
        Rectangle {
          Layout.fillWidth: true; height: 60; color: Colors.highlightLight; radius: 10
          Column { anchors.centerIn: parent; spacing: 2
            Text { text: "GPU TEMP"; color: Colors.textDisabled; font.pixelSize: 8; font.weight: Font.Bold; anchors.horizontalCenter: parent }
            Text { text: SystemStatus.gpuTemp; color: Colors.text; font.pixelSize: 14; font.weight: Font.Bold; anchors.horizontalCenter: parent }
          }
        }
      }

      SystemGraphs {}
      NetworkGraphs {}
      DiskWidget {}
      GPUWidget {}
      ScratchpadWidget {}

      Flickable {
        Layout.fillWidth: true; Layout.fillHeight: true; contentHeight: scrollCol.height; clip: true
        Column {
          id: scrollCol; width: parent.width; spacing: 15; focus: true
          
          Column {
            width: parent.width; spacing: 8
            Text { 
              text: "WI-FI NETWORKS"
              color: Colors.textDisabled
              font.pixelSize: 8
              font.weight: Font.Bold
              font.capitalization: Font.AllUppercase
            }
            Repeater {
              model: root.wifiNetworks
              delegate: Column {
                width: parent.width; spacing: 4
                Rectangle {
                  width: parent.width; height: 35; color: Colors.highlightLight; radius: 6
                  RowLayout {
                    anchors.fill: parent; anchors.margins: 10
                    Text { text: "󰖩"; color: Colors.textSecondary; font.family: "JetBrainsMono Nerd Font" }
                    Text { text: modelData.ssid; color: Colors.text; font.pixelSize: 12; Layout.fillWidth: true; elide: Text.ElideRight }
                    Text { text: modelData.bars; color: Colors.textDisabled; font.family: "JetBrainsMono Nerd Font" }
                  }
                  MouseArea { anchors.fill: parent; onClicked: { if (root.selectedSSID === modelData.ssid) root.selectedSSID = ""; else root.selectedSSID = modelData.ssid; } }
                }
                Rectangle {
                  width: parent.width; height: 40; color: "#1affffff"; radius: 6; visible: root.selectedSSID === modelData.ssid
                  TextInput {
                    id: pwInput; anchors.fill: parent; anchors.margins: 10; verticalAlignment: Text.AlignVCenter; color: Colors.text; font.pixelSize: 12; echoMode: TextInput.Password; focus: parent.visible
                    Keys.onReturnPressed: { Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", modelData.ssid, "password", text]); root.selectedSSID = ""; }
                  }
                }
              }
            }
          }

          Column {
            width: parent.width; spacing: 8
            visible: root.vpns.length > 0 || root.tailscaleStatus !== "Stopped"
            Text { 
              text: "VPN & OVERLAYS"
              color: Colors.textDisabled
              font.pixelSize: 8
              font.weight: Font.Bold
              font.capitalization: Font.AllUppercase
            }
            Rectangle {
              width: parent.width; height: 40; color: Colors.highlightLight; radius: 8; visible: root.tailscaleStatus !== "Stopped"
              RowLayout {
                anchors.fill: parent; anchors.margins: 12
                Text { text: "󰖂"; color: root.tailscaleStatus === "Connected" ? Colors.primary : Colors.textSecondary; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16 }
                Text { text: "Tailscale"; color: Colors.text; font.pixelSize: 12; font.weight: Font.Medium; Layout.fillWidth: true }
                Rectangle { width: 8; height: 8; radius: 4; color: root.tailscaleStatus === "Connected" ? Colors.primary : Colors.textDisabled }
              }
              MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: parent.color = Colors.surface; onExited: parent.color = Colors.highlightLight; onClicked: { if (root.tailscaleStatus === "Connected") Quickshell.execDetached(["tailscale", "down"]); else Quickshell.execDetached(["tailscale", "up"]); } }
            }
            Repeater {
              model: root.vpns
              delegate: Rectangle {
                width: parent.width; height: 40; color: Colors.highlightLight; radius: 8
                RowLayout {
                  anchors.fill: parent; anchors.margins: 12
                  Text { text: "󰖂"; color: Colors.primary; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16 }
                  Text { text: modelData.name; color: Colors.text; font.pixelSize: 12; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                  Text { text: modelData.type; color: Colors.textDisabled; font.pixelSize: 10; font.capitalization: Font.AllUppercase }
                }
                MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: parent.color = Colors.surface; onExited: parent.color = Colors.highlightLight; onClicked: Quickshell.execDetached(["nmcli", "connection", "down", modelData.name]) }
              }
            }
          }

          Column {
            width: parent.width; spacing: 8
            visible: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
            Text { 
              text: "BLUETOOTH DEVICES"
              color: Colors.textDisabled
              font.pixelSize: 8
              font.weight: Font.Bold
              font.capitalization: Font.AllUppercase
            }
            Repeater {
              model: Bluetooth.defaultAdapter ? Bluetooth.defaultAdapter.devices : null
              delegate: Rectangle {
                width: parent.width; height: 40; color: Colors.highlightLight; radius: 8; visible: modelData.paired
                RowLayout {
                  anchors.fill: parent; anchors.margins: 12
                  Text { text: modelData.connected ? "󰂱" : "󰂯"; color: modelData.connected ? Colors.primary : Colors.textSecondary; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16 }
                  Text { text: modelData.name || "Unknown"; color: Colors.text; font.pixelSize: 12; font.weight: Font.Medium; Layout.fillWidth: true; elide: Text.ElideRight }
                  Rectangle { width: 8; height: 8; radius: 4; color: modelData.connected ? Colors.primary : "transparent" }
                }
                MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: parent.color = Colors.surface; onExited: parent.color = Colors.highlightLight; onClicked: { if (modelData.connected) modelData.disconnect(); else modelData.connect(); } }
              }
            }
          }

          Column {
            width: parent.width; spacing: 8
            Text { 
              text: "AUDIO OUTPUTS"
              color: Colors.textDisabled
              font.pixelSize: 8
              font.weight: Font.Bold
              font.capitalization: Font.AllUppercase
            }
            Repeater {
              model: Pipewire.objects
              delegate: Rectangle {
                width: parent.width; height: 40; color: isDefault ? Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.2) : Colors.highlightLight; radius: 8
                visible: modelData.type === PwObject.Node && modelData.audio !== null && !modelData.isSource && (modelData.props["node.name"] && modelData.props["node.name"].includes("alsa_output"))
                property bool isDefault: Pipewire.defaultAudioSink === modelData
                border.color: isDefault ? Colors.primary : "transparent"; border.width: 1
                RowLayout {
                  anchors.fill: parent; anchors.margins: 12
                  Text { text: isDefault ? "󰓃" : "󰓄"; color: isDefault ? Colors.primary : Colors.textSecondary; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16 }
                  Text { text: modelData.name || "Unknown Device"; color: Colors.text; font.pixelSize: 12; font.weight: isDefault ? Font.Bold : Font.Normal; Layout.fillWidth: true; elide: Text.ElideRight }
                }
                MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: if(!isDefault) parent.color = Colors.surface; onExited: if(!isDefault) parent.color = Colors.highlightLight; onClicked: Pipewire.defaultAudioSink = modelData }
              }
            }
          }

          Column {
            width: parent.width; spacing: 8
            Text { 
              text: "APPLICATION VOLUME"
              color: Colors.textDisabled
              font.pixelSize: 8
              font.weight: Font.Bold
              font.capitalization: Font.AllUppercase
            }
            Repeater {
              model: Pipewire.objects
              delegate: Rectangle {
                width: parent.width; height: 50; color: Colors.highlightLight; radius: 8
                visible: modelData.type === PwObject.Node && modelData.audio !== null && !modelData.isSource && !(modelData.props["node.name"] && modelData.props["node.name"].includes("alsa_output"))
                ColumnLayout {
                  anchors.fill: parent; anchors.margins: 10; spacing: 4
                  RowLayout {
                    Layout.fillWidth: true
                    Text { text: modelData.name || "App"; color: Colors.text; font.pixelSize: 11; font.weight: Font.Medium; elide: Text.ElideRight; Layout.fillWidth: true }
                    Text { text: Math.round(modelData.audio.volume * 100) + "%"; color: Colors.textSecondary; font.pixelSize: 10 }
                  }
                  Rectangle {
                    Layout.fillWidth: true; height: 4; color: "#33ffffff"; radius: 2
                    Rectangle { width: parent.width * modelData.audio.volume; height: parent.height; color: Colors.primary; radius: 2 }
                    MouseArea { anchors.fill: parent; onPressed: (mouse) => { modelData.audio.volume = Math.max(0, Math.min(1, mouse.x / width)); } }
                  }
                }
              }
            }
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true; spacing: 10
        Repeater {
          model: [
            { icon: "󰐥", cmd: "systemctl poweroff" },
            { icon: "󰑐", cmd: "systemctl reboot" },
            { icon: "󰌾", cmd: "hyprlock" }
          ]
          delegate: Rectangle {
            Layout.fillWidth: true; height: 40; color: Colors.surface; radius: 8
            Text { anchors.centerIn: parent; text: modelData.icon; color: Colors.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18 }
            MouseArea { anchors.fill: parent; hoverEnabled: true; onEntered: parent.color = Colors.highlightLight; onExited: parent.color = Colors.surface; onClicked: Quickshell.execDetached(modelData.cmd.split(" ")) }
          }
        }
      }
    }
  }
}
