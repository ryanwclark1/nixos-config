import Quickshell
import QtQuick
import QtQuick.Layouts

import Quickshell.Io
import "../services"

PopupWindow {
  id: root
  implicitWidth: 340
  implicitHeight: 470
  readonly property color panelSurface: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.96)
  readonly property color cardSurface: Qt.rgba(Colors.surface.r, Colors.surface.g, Colors.surface.b, 0.82)

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

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 12

        Rectangle {
          Layout.fillWidth: true
          radius: Colors.radiusMedium
          color: root.cardSurface
          border.color: root.outputMuted && root.inputMuted ? Colors.border : Colors.primary
          border.width: 1
          implicitHeight: 78

          RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Text {
              text: root.outputMuted ? "󰝟" : "󰕾"
              color: root.outputMuted ? Colors.textDisabled : Colors.primary
              font.family: Colors.fontMono
              font.pixelSize: 22
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 2

              Text {
                text: root.outputLabel
                color: Colors.fgMain
                font.pixelSize: 13
                font.weight: Font.DemiBold
                Layout.fillWidth: true
                elide: Text.ElideRight
              }

              Text {
                text: "Output " + root.percentText(root.outputVolume, root.outputMuted) + " • Input " + root.percentText(root.inputVolume, root.inputMuted)
                color: Colors.textSecondary
                font.pixelSize: 11
                Layout.fillWidth: true
                elide: Text.ElideRight
              }
            }

            Rectangle {
              width: 64
              height: 30
              radius: 15
              color: summaryRefreshHover.containsMouse ? Colors.highlight : Colors.highlightLight

              Text {
                anchors.centerIn: parent
                text: "Refresh"
                color: Colors.fgMain
                font.pixelSize: 10
                font.weight: Font.Medium
              }

              MouseArea {
                id: summaryRefreshHover
                anchors.fill: parent
                hoverEnabled: true
                onClicked: root.refreshDevices()
              }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          radius: Colors.radiusMedium
          color: root.cardSurface
          border.color: Colors.border
          border.width: 1
          implicitHeight: 96

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
              Layout.fillWidth: true
              Text { text: "󰕾  Output"; color: Colors.fgMain; font.pixelSize: 13; font.weight: Font.Medium }
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

            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              Repeater {
                model: [
                  { label: "25%", value: 0.25 },
                  { label: "50%", value: 0.50 },
                  { label: "75%", value: 0.75 }
                ]
                delegate: Rectangle {
                  radius: 11
                  color: quickOutputHover.containsMouse ? Colors.highlight : Colors.surface
                  border.color: Colors.border
                  border.width: 1
                  implicitWidth: quickOutputLabel.implicitWidth + 18
                  implicitHeight: 24

                  Text {
                    id: quickOutputLabel
                    anchors.centerIn: parent
                    text: modelData.label
                    color: Colors.textSecondary
                    font.pixelSize: 10
                    font.weight: Font.Medium
                  }

                  MouseArea {
                    id: quickOutputHover
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.setVolume("@DEFAULT_AUDIO_SINK@", modelData.value)
                  }
                }
              }

              Item { Layout.fillWidth: true }
            }

            Text {
              text: root.outputLabel
              color: Colors.textSecondary
              font.pixelSize: 11
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          radius: Colors.radiusMedium
          color: root.cardSurface
          border.color: Colors.border
          border.width: 1
          implicitHeight: 96

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
              Layout.fillWidth: true
              Text { text: "󰍬  Input"; color: Colors.fgMain; font.pixelSize: 13; font.weight: Font.Medium }
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

            RowLayout {
              Layout.fillWidth: true
              spacing: 8

              Repeater {
                model: [
                  { label: "25%", value: 0.25 },
                  { label: "50%", value: 0.50 },
                  { label: "75%", value: 0.75 }
                ]
                delegate: Rectangle {
                  radius: 11
                  color: quickInputHover.containsMouse ? Colors.highlight : Colors.surface
                  border.color: Colors.border
                  border.width: 1
                  implicitWidth: quickInputLabel.implicitWidth + 18
                  implicitHeight: 24

                  Text {
                    id: quickInputLabel
                    anchors.centerIn: parent
                    text: modelData.label
                    color: Colors.textSecondary
                    font.pixelSize: 10
                    font.weight: Font.Medium
                  }

                  MouseArea {
                    id: quickInputHover
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.setVolume("@DEFAULT_AUDIO_SOURCE@", modelData.value)
                  }
                }
              }

              Item { Layout.fillWidth: true }
            }

            Text {
              text: root.inputLabel
              color: Colors.textSecondary
              font.pixelSize: 11
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 8

          Text { text: "Output Devices"; color: Colors.textDisabled; font.pixelSize: 10; font.weight: Font.Bold }
          Text { text: root.sinks.length === 0 ? "No output devices detected" : "Click a device to make it default"; color: Colors.textSecondary; font.pixelSize: 10 }
          Repeater {
            model: root.sinks
            delegate: Rectangle {
              Layout.fillWidth: true
              implicitHeight: 46
              radius: Colors.radiusMedium
              color: modelData.id === root.defaultSinkId ? Colors.highlight : root.cardSurface
              border.color: modelData.id === root.defaultSinkId ? Colors.primary : Colors.border
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10
                Text { text: modelData.id === root.defaultSinkId ? "󰄬" : "󰕾"; color: modelData.id === root.defaultSinkId ? Colors.primary : Colors.textSecondary; font.family: Colors.fontMono; font.pixelSize: 14 }
                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 0
                  Text { text: modelData.name; color: Colors.fgMain; font.pixelSize: 12; font.weight: modelData.id === root.defaultSinkId ? Font.DemiBold : Font.Normal; elide: Text.ElideRight; Layout.fillWidth: true }
                  Text { text: (modelData.muted ? "Muted" : "Ready") + " • " + Math.round(modelData.volume * 100) + "%"; color: Colors.textSecondary; font.pixelSize: 10; elide: Text.ElideRight; Layout.fillWidth: true }
                }
                Text { text: modelData.id === root.defaultSinkId ? "Default" : "Select"; color: modelData.id === root.defaultSinkId ? Colors.primary : Colors.textSecondary; font.pixelSize: 10; font.weight: Font.Medium }
              }

              MouseArea { anchors.fill: parent; onClicked: root.setDefaultDevice(modelData.id) }
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 8

          Text { text: "Input Devices"; color: Colors.textDisabled; font.pixelSize: 10; font.weight: Font.Bold }
          Text { text: root.sources.length === 0 ? "No input devices detected" : "Click a device to make it default"; color: Colors.textSecondary; font.pixelSize: 10 }
          Repeater {
            model: root.sources
            delegate: Rectangle {
              Layout.fillWidth: true
              implicitHeight: 46
              radius: Colors.radiusMedium
              color: modelData.id === root.defaultSourceId ? Colors.highlight : root.cardSurface
              border.color: modelData.id === root.defaultSourceId ? Colors.primary : Colors.border
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10
                Text { text: modelData.id === root.defaultSourceId ? "󰄬" : "󰍬"; color: modelData.id === root.defaultSourceId ? Colors.primary : Colors.textSecondary; font.family: Colors.fontMono; font.pixelSize: 14 }
                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 0
                  Text { text: modelData.name; color: Colors.fgMain; font.pixelSize: 12; font.weight: modelData.id === root.defaultSourceId ? Font.DemiBold : Font.Normal; elide: Text.ElideRight; Layout.fillWidth: true }
                  Text { text: (modelData.muted ? "Muted" : "Ready") + " • " + Math.round(modelData.volume * 100) + "%"; color: Colors.textSecondary; font.pixelSize: 10; elide: Text.ElideRight; Layout.fillWidth: true }
                }
                Text { text: modelData.id === root.defaultSourceId ? "Default" : "Select"; color: modelData.id === root.defaultSourceId ? Colors.primary : Colors.textSecondary; font.pixelSize: 10; font.weight: Font.Medium }
              }

              MouseArea { anchors.fill: parent; onClicked: root.setDefaultDevice(modelData.id) }
            }
          }
        }
      }
    }
  }
}
