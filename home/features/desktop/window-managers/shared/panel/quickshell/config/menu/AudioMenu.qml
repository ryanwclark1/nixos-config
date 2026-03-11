import Quickshell
import QtQuick
import QtQuick.Layouts

import "../services"
import "../widgets" as SharedWidgets

PopupWindow {
  id: root
  implicitWidth: 350
  implicitHeight: 510

  function percentText(value, muted) {
    return muted ? "Muted" : Math.round(value * 100) + "%";
  }

  onVisibleChanged: if (visible) AudioService.refreshDevices()

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
        SharedWidgets.MenuCloseButton { toggleMethod: "toggleAudioMenu" }
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
            color: Colors.cardSurface
            border.color: Colors.border
            border.width: 1
            implicitHeight: 64

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 12
              spacing: 6

              RowLayout {
                Layout.fillWidth: true
                Text { text: "󰕾"; color: AudioService.outputMuted ? Colors.error : Colors.primary; font.family: Colors.fontMono; font.pixelSize: 16 }
                Text { text: "Output"; color: Colors.fgMain; font.pixelSize: 13; font.weight: Font.Medium }
                Item { Layout.fillWidth: true }
                Rectangle {
                  radius: 12
                  color: AudioService.outputMuted ? Colors.withAlpha(Colors.error, 0.16) : Colors.highlightLight
                  implicitWidth: outputPercentLabel.implicitWidth + 16
                  implicitHeight: 24
                  Text {
                    id: outputPercentLabel
                    anchors.centerIn: parent
                    text: root.percentText(AudioService.outputVolume, AudioService.outputMuted)
                    color: AudioService.outputMuted ? Colors.error : Colors.textSecondary
                    font.pixelSize: 10
                    font.weight: Font.Medium
                  }
                }
                SharedWidgets.MuteButton {
                  target: "@DEFAULT_AUDIO_SINK@"
                  muted: AudioService.outputMuted
                  icon: "󰕾"; mutedIcon: "󰝟"
                }
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

          Repeater {
            model: AudioService.sinks
            delegate: Rectangle {
              id: sinkCard
              Layout.fillWidth: true
              implicitHeight: 46
              radius: Colors.radiusMedium
              property bool isDefault: modelData.id === AudioService.defaultSinkId
              property bool isHovered: sinkHover.containsMouse
              color: isDefault ? Colors.withAlpha(Colors.primary, 0.16) : (isHovered ? Colors.withAlpha(Colors.primary, 0.12) : Colors.cardSurface)
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

              MouseArea { id: sinkHover; anchors.fill: parent; hoverEnabled: true; onClicked: AudioService.setDefaultDevice(modelData.id) }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            visible: AudioService.sinks.length === 0
            implicitHeight: 36
            radius: Colors.radiusMedium
            color: Colors.cardSurface
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
            color: Colors.cardSurface
            border.color: Colors.border
            border.width: 1
            implicitHeight: 64

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 12
              spacing: 6

              RowLayout {
                Layout.fillWidth: true
                Text { text: "󰍬"; color: AudioService.inputMuted ? Colors.error : Colors.primary; font.family: Colors.fontMono; font.pixelSize: 16 }
                Text { text: "Input"; color: Colors.fgMain; font.pixelSize: 13; font.weight: Font.Medium }
                Item { Layout.fillWidth: true }
                Rectangle {
                  radius: 12
                  color: AudioService.inputMuted ? Colors.withAlpha(Colors.error, 0.16) : Colors.highlightLight
                  implicitWidth: inputPercentLabel.implicitWidth + 16
                  implicitHeight: 24
                  Text {
                    id: inputPercentLabel
                    anchors.centerIn: parent
                    text: root.percentText(AudioService.inputVolume, AudioService.inputMuted)
                    color: AudioService.inputMuted ? Colors.error : Colors.textSecondary
                    font.pixelSize: 10
                    font.weight: Font.Medium
                  }
                }
                SharedWidgets.MuteButton {
                  target: "@DEFAULT_AUDIO_SOURCE@"
                  muted: AudioService.inputMuted
                  icon: "󰍬"; mutedIcon: "󰍭"
                }
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

          Repeater {
            model: AudioService.sources
            delegate: Rectangle {
              id: sourceCard
              Layout.fillWidth: true
              implicitHeight: 46
              radius: Colors.radiusMedium
              property bool isDefault: modelData.id === AudioService.defaultSourceId
              property bool isHovered: sourceHover.containsMouse
              color: isDefault ? Colors.withAlpha(Colors.primary, 0.16) : (isHovered ? Colors.withAlpha(Colors.primary, 0.12) : Colors.cardSurface)
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

              MouseArea { id: sourceHover; anchors.fill: parent; hoverEnabled: true; onClicked: AudioService.setDefaultDevice(modelData.id) }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            visible: AudioService.sources.length === 0
            implicitHeight: 36
            radius: Colors.radiusMedium
            color: Colors.cardSurface
            border.color: Colors.border
            border.width: 1
            Text { anchors.centerIn: parent; text: "No input devices detected"; color: Colors.textDisabled; font.pixelSize: 11 }
          }
        }
      }
    }
  }
}
