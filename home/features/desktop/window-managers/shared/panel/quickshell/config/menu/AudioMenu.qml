import Quickshell
import QtQuick
import QtQuick.Layouts

import Quickshell.Io
import "../services"

PopupWindow {
  id: root
  implicitWidth: 350
  implicitHeight: 510
  readonly property color panelSurface: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.96)
  readonly property color cardSurface: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.82)
  readonly property color chipSurface: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.92)

  property var sinks: []
  property var sources: []
  property int defaultSinkId: -1
  property int defaultSourceId: -1
  property real outputVolume: 0
  property real inputVolume: 0
  property bool outputMuted: false
  property bool inputMuted: false
  property string outputLabel: "No output device"
  property string inputLabel: "No input device"

  function percentText(value, muted) {
    return muted ? "Muted" : Math.round(value * 100) + "%";
  }

  function refreshDevices() {
    audioStatus.running = true;
  }

  function setVolume(target, value) {
    var clamped = Colors.clamp01(value);
    var percent = Math.round(clamped * 100).toString() + "%";
    if (clamped > 0) Quickshell.execDetached(["wpctl", "set-mute", target, "0"]);
    Quickshell.execDetached(["wpctl", "set-volume", target, percent]);
    refreshDevices();
  }

  function toggleMute(target, muted) {
    Quickshell.execDetached(["wpctl", "set-mute", target, muted ? "0" : "1"]);
    refreshDevices();
  }

  function setDefaultDevice(id) {
    if (id < 0) return;
    Quickshell.execDetached(["wpctl", "set-default", id.toString()]);
    refreshDevices();
  }

  Process {
    id: audioStatus
    command: ["sh", "-c", "wpctl status"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = (this.text || "").split("\n");
        var section = "";
        var parsedSinks = [];
        var parsedSources = [];

        root.defaultSinkId = -1;
        root.defaultSourceId = -1;
        root.outputVolume = 0;
        root.inputVolume = 0;
        root.outputMuted = false;
        root.inputMuted = false;
        root.outputLabel = "No output device";
        root.inputLabel = "No input device";

        for (var i = 0; i < lines.length; i++) {
          var line = lines[i];
          if (line.indexOf("├─ Sinks:") !== -1) {
            section = "sinks";
            continue;
          }
          if (line.indexOf("├─ Sources:") !== -1) {
            section = "sources";
            continue;
          }
          if (line.indexOf("├─ Filters:") !== -1 || line.indexOf("└─ Streams:") !== -1 || line.indexOf("Video") === 0 || line.indexOf("Settings") === 0) {
            section = "";
          }
          if (section !== "sinks" && section !== "sources") continue;

          var trimmed = line.trim();
          if (!trimmed) continue;
          var isDefault = trimmed.indexOf("*") === 0;
          if (isDefault) trimmed = trimmed.substring(1).trim();

          var match = trimmed.match(/^(\d+)\.\s+(.*?)\s+\[vol:\s+([0-9.]+)\](\s+\[MUTED\])?$/);
          if (!match) continue;

          var item = {
            id: parseInt(match[1]),
            name: match[2],
            volume: parseFloat(match[3]),
            muted: !!match[4],
            isDefault: isDefault
          };

          if (section === "sinks") {
            parsedSinks.push(item);
            if (item.isDefault) {
              root.defaultSinkId = item.id;
              root.outputVolume = item.volume;
              root.outputMuted = item.muted;
              root.outputLabel = item.name;
            }
          } else {
            parsedSources.push(item);
            if (item.isDefault) {
              root.defaultSourceId = item.id;
              root.inputVolume = item.volume;
              root.inputMuted = item.muted;
              root.inputLabel = item.name;
            }
          }
        }

        root.sinks = parsedSinks;
        root.sources = parsedSources;
      }
    }
  }

  Timer {
    interval: 5000
    running: root.visible
    repeat: true
    onTriggered: root.refreshDevices()
  }

  onVisibleChanged: if (visible) refreshDevices()

  Rectangle {
    anchors.fill: parent
    color: root.panelSurface
    border.color: Colors.border
    border.width: 1
    radius: Colors.radiusMedium
    clip: true

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Colors.paddingLarge
      spacing: 14

      RowLayout {
        Layout.fillWidth: true
        Text {
          text: "Audio"
          color: Colors.fgMain
          font.pixelSize: 18
          font.weight: Font.DemiBold
        }
        Item { Layout.fillWidth: true }
        Rectangle {
          width: 30
          height: 30
          radius: 15
          color: audioSettingsHover.containsMouse ? Colors.highlightLight : "transparent"

          Text {
            anchors.centerIn: parent
            text: "󰒓"
            color: Colors.textSecondary
            font.family: Colors.fontMono
            font.pixelSize: 16
          }

          MouseArea {
            id: audioSettingsHover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: Quickshell.execDetached(["pavucontrol"])
          }
        }
        Rectangle {
          width: 30
          height: 30
          radius: 15
          color: audioCloseHover.containsMouse ? Colors.highlightLight : "transparent"

          Text {
            anchors.centerIn: parent
            text: "󰅖"
            color: Colors.textSecondary
            font.family: Colors.fontMono
            font.pixelSize: 16
          }

          MouseArea {
            id: audioCloseHover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "toggleAudioMenu"])
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Colors.border
      }

      Flickable {
        Layout.fillWidth: true
        Layout.fillHeight: true
        contentHeight: contentColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
          id: contentColumn
          width: parent.width
          spacing: 14

          // ── OUTPUT section ──────────────────────────
          Text {
            text: "OUTPUT"
            color: Colors.textDisabled
            font.pixelSize: 10
            font.weight: Font.Bold
            font.letterSpacing: 0.5
          }

          Rectangle {
            Layout.fillWidth: true
            radius: Colors.radiusMedium
            color: root.cardSurface
            border.color: Colors.border
            border.width: 1
            implicitHeight: 64

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 12
              spacing: 6

              RowLayout {
                Layout.fillWidth: true
                Text { text: "󰕾"; color: root.outputMuted ? Colors.error : Colors.primary; font.family: Colors.fontMono; font.pixelSize: 16 }
                Text { text: "Output"; color: Colors.fgMain; font.pixelSize: 13; font.weight: Font.Medium }
                Item { Layout.fillWidth: true }
                Rectangle {
                  radius: 12
                  color: root.outputMuted ? Colors.withAlpha(Colors.error, 0.16) : Colors.highlightLight
                  implicitWidth: outputPercentLabel.implicitWidth + 16
                  implicitHeight: 24
                  Text {
                    id: outputPercentLabel
                    anchors.centerIn: parent
                    text: root.percentText(root.outputVolume, root.outputMuted)
                    color: root.outputMuted ? Colors.error : Colors.textSecondary
                    font.pixelSize: 10
                    font.weight: Font.Medium
                  }
                }
                Rectangle {
                  width: 28
                  height: 28
                  radius: 14
                  color: outputMuteHover.containsMouse ? Colors.highlightLight : "transparent"
                  Text { anchors.centerIn: parent; text: root.outputMuted ? "󰝟" : "󰕾"; color: root.outputMuted ? Colors.error : Colors.textSecondary; font.family: Colors.fontMono; font.pixelSize: 14 }
                  MouseArea { id: outputMuteHover; anchors.fill: parent; hoverEnabled: true; onClicked: root.toggleMute("@DEFAULT_AUDIO_SINK@", root.outputMuted) }
                }
              }

              Rectangle {
                id: audioOutputTrack
                Layout.fillWidth: true; height: 28; color: Colors.bgWidget; radius: 14; border.color: Colors.border; border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Rectangle {
                  height: parent.height; width: Math.max(28, parent.width * (root.outputMuted ? 0 : root.outputVolume)); radius: 14
                  color: root.outputMuted ? Colors.error : (audioOutputHover.containsMouse ? Qt.darker(Colors.primary, 1.08) : Colors.primary)
                  Behavior on color { ColorAnimation { duration: 150 } }
                  Text { anchors.centerIn: parent; text: root.outputMuted ? "󰝟" : "󰕾"; color: Colors.background; font.family: Colors.fontMono; font.pixelSize: 12; visible: (root.outputMuted || root.outputVolume > 0.1) }
                }
                MouseArea {
                  id: audioOutputHover
                  anchors.fill: parent
                  hoverEnabled: true
                  onEntered: { audioOutputTrack.color = Colors.surface; audioOutputTrack.border.color = root.outputMuted ? Colors.error : Colors.primary; }
                  onExited: { audioOutputTrack.color = Colors.bgWidget; audioOutputTrack.border.color = Colors.border; }
                  onPressed: (mouse) => { root.setVolume("@DEFAULT_AUDIO_SINK@", Math.max(0, Math.min(1.0, mouse.x / width))); }
                  onPositionChanged: (mouse) => { if (pressed) root.setVolume("@DEFAULT_AUDIO_SINK@", Math.max(0, Math.min(1.0, mouse.x / width))); }
                }
              }
            }
          }

          Repeater {
            model: root.sinks
            delegate: Rectangle {
              id: sinkCard
              Layout.fillWidth: true
              implicitHeight: 46
              radius: Colors.radiusMedium
              property bool isDefault: modelData.id === root.defaultSinkId
              property bool isHovered: sinkHover.containsMouse
              color: isDefault ? Colors.withAlpha(Colors.primary, 0.16) : (isHovered ? Colors.withAlpha(Colors.primary, 0.12) : root.cardSurface)
              border.color: isDefault ? Colors.primary : Colors.border
              border.width: 1
              Behavior on color { ColorAnimation { duration: 150 } }

              RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10
                Text { text: sinkCard.isDefault ? "󰄬" : "󰕾"; color: sinkCard.isDefault ? Colors.primary : Colors.textSecondary; font.family: Colors.fontMono; font.pixelSize: 14 }
                Text { text: modelData.name; color: Colors.fgMain; font.pixelSize: 12; font.weight: sinkCard.isDefault ? Font.DemiBold : Font.Normal; elide: Text.ElideRight; Layout.fillWidth: true }
                Text { text: Math.round(modelData.volume * 100) + "%"; color: Colors.textSecondary; font.pixelSize: 10 }
                Text { text: sinkCard.isDefault ? "Default" : "Select"; color: sinkCard.isDefault ? Colors.primary : Colors.textSecondary; font.pixelSize: 10; font.weight: Font.Medium }
              }

              MouseArea { id: sinkHover; anchors.fill: parent; hoverEnabled: true; onClicked: root.setDefaultDevice(modelData.id) }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            visible: root.sinks.length === 0
            implicitHeight: 36
            radius: Colors.radiusMedium
            color: root.cardSurface
            border.color: Colors.border
            border.width: 1
            Text { anchors.centerIn: parent; text: "No output devices detected"; color: Colors.textDisabled; font.pixelSize: 11 }
          }

          // ── INPUT section ──────────────────────────
          Text {
            text: "INPUT"
            color: Colors.textDisabled
            font.pixelSize: 10
            font.weight: Font.Bold
            font.letterSpacing: 0.5
          }

          Rectangle {
            Layout.fillWidth: true
            radius: Colors.radiusMedium
            color: root.cardSurface
            border.color: Colors.border
            border.width: 1
            implicitHeight: 64

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 12
              spacing: 6

              RowLayout {
                Layout.fillWidth: true
                Text { text: "󰍬"; color: root.inputMuted ? Colors.error : Colors.primary; font.family: Colors.fontMono; font.pixelSize: 16 }
                Text { text: "Input"; color: Colors.fgMain; font.pixelSize: 13; font.weight: Font.Medium }
                Item { Layout.fillWidth: true }
                Rectangle {
                  radius: 12
                  color: root.inputMuted ? Colors.withAlpha(Colors.error, 0.16) : Colors.highlightLight
                  implicitWidth: inputPercentLabel.implicitWidth + 16
                  implicitHeight: 24
                  Text {
                    id: inputPercentLabel
                    anchors.centerIn: parent
                    text: root.percentText(root.inputVolume, root.inputMuted)
                    color: root.inputMuted ? Colors.error : Colors.textSecondary
                    font.pixelSize: 10
                    font.weight: Font.Medium
                  }
                }
                Rectangle {
                  width: 28
                  height: 28
                  radius: 14
                  color: inputMuteHover.containsMouse ? Colors.highlightLight : "transparent"
                  Text { anchors.centerIn: parent; text: root.inputMuted ? "󰍭" : "󰍬"; color: root.inputMuted ? Colors.error : Colors.textSecondary; font.family: Colors.fontMono; font.pixelSize: 14 }
                  MouseArea { id: inputMuteHover; anchors.fill: parent; hoverEnabled: true; onClicked: root.toggleMute("@DEFAULT_AUDIO_SOURCE@", root.inputMuted) }
                }
              }

              Rectangle {
                id: audioInputTrack
                Layout.fillWidth: true; height: 28; color: Colors.bgWidget; radius: 14; border.color: Colors.border; border.width: 1
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Rectangle {
                  height: parent.height; width: Math.max(28, parent.width * (root.inputMuted ? 0 : root.inputVolume)); radius: 14
                  color: root.inputMuted ? Colors.error : (audioInputHover.containsMouse ? Qt.darker(Colors.primary, 1.08) : Colors.primary)
                  Behavior on color { ColorAnimation { duration: 150 } }
                  Text { anchors.centerIn: parent; text: root.inputMuted ? "󰍭" : "󰍬"; color: Colors.background; font.family: Colors.fontMono; font.pixelSize: 12; visible: (root.inputMuted || root.inputVolume > 0.1) }
                }
                MouseArea {
                  id: audioInputHover
                  anchors.fill: parent
                  hoverEnabled: true
                  onEntered: { audioInputTrack.color = Colors.surface; audioInputTrack.border.color = root.inputMuted ? Colors.error : Colors.primary; }
                  onExited: { audioInputTrack.color = Colors.bgWidget; audioInputTrack.border.color = Colors.border; }
                  onPressed: (mouse) => { root.setVolume("@DEFAULT_AUDIO_SOURCE@", Math.max(0, Math.min(1.0, mouse.x / width))); }
                  onPositionChanged: (mouse) => { if (pressed) root.setVolume("@DEFAULT_AUDIO_SOURCE@", Math.max(0, Math.min(1.0, mouse.x / width))); }
                }
              }
            }
          }

          Repeater {
            model: root.sources
            delegate: Rectangle {
              id: sourceCard
              Layout.fillWidth: true
              implicitHeight: 46
              radius: Colors.radiusMedium
              property bool isDefault: modelData.id === root.defaultSourceId
              property bool isHovered: sourceHover.containsMouse
              color: isDefault ? Colors.withAlpha(Colors.primary, 0.16) : (isHovered ? Colors.withAlpha(Colors.primary, 0.12) : root.cardSurface)
              border.color: isDefault ? Colors.primary : Colors.border
              border.width: 1
              Behavior on color { ColorAnimation { duration: 150 } }

              RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10
                Text { text: sourceCard.isDefault ? "󰄬" : "󰍬"; color: sourceCard.isDefault ? Colors.primary : Colors.textSecondary; font.family: Colors.fontMono; font.pixelSize: 14 }
                Text { text: modelData.name; color: Colors.fgMain; font.pixelSize: 12; font.weight: sourceCard.isDefault ? Font.DemiBold : Font.Normal; elide: Text.ElideRight; Layout.fillWidth: true }
                Text { text: Math.round(modelData.volume * 100) + "%"; color: Colors.textSecondary; font.pixelSize: 10 }
                Text { text: sourceCard.isDefault ? "Default" : "Select"; color: sourceCard.isDefault ? Colors.primary : Colors.textSecondary; font.pixelSize: 10; font.weight: Font.Medium }
              }

              MouseArea { id: sourceHover; anchors.fill: parent; hoverEnabled: true; onClicked: root.setDefaultDevice(modelData.id) }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            visible: root.sources.length === 0
            implicitHeight: 36
            radius: Colors.radiusMedium
            color: root.cardSurface
            border.color: Colors.border
            border.width: 1
            Text { anchors.centerIn: parent; text: "No input devices detected"; color: Colors.textDisabled; font.pixelSize: 11 }
          }
        }
      }
    }
  }
}
