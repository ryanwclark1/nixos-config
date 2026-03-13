import Quickshell
import QtQuick
import QtQuick.Layouts

import "../services"
import "../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  readonly property int availablePopupWidth: screen ? Math.max(340, screen.width - 40) : 380
  readonly property bool compactMode: availablePopupWidth < 360
  implicitWidth: Math.min(380, availablePopupWidth)
  implicitHeight: compactMode ? 620 : 560
  title: "Audio"
  toggleMethod: "toggleAudioMenu"

  function percentText(value, muted) {
    return muted ? "Muted" : Math.round(value * 100) + "%";
  }

  onVisibleChanged: if (visible) AudioService.refreshDevices()

  headerExtras: [
    Rectangle {
      width: 30
      height: 30
      radius: height / 2
      color: "transparent"

      Text {
        anchors.centerIn: parent
        text: "󰒓"
        color: Colors.textSecondary
        font.family: Colors.fontMono
        font.pixelSize: Colors.fontSizeXL
      }

      SharedWidgets.StateLayer {
        id: stateLayer
        hovered: audioSettingsHover.containsMouse
        pressed: audioSettingsHover.pressed
      }

      MouseArea {
        id: audioSettingsHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => { stateLayer.burst(mouse.x, mouse.y); Quickshell.execDetached(["pavucontrol"]); }
      }
    }
  ]

  SharedWidgets.ScrollableContent {
    Layout.fillWidth: true
    Layout.fillHeight: true
    columnSpacing: Colors.spacingM

      // ── OUTPUT section ──────────────────────────
      SharedWidgets.SectionLabel { label: "OUTPUT" }

      Rectangle {
        Layout.fillWidth: true
        radius: Colors.radiusMedium
        color: Colors.cardSurface
        border.color: Colors.border
        border.width: 1
        implicitHeight: outputCol.implicitHeight + 2 * Colors.spacingM

        ColumnLayout {
          id: outputCol
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: Colors.spacingM
          spacing: Colors.spacingS

          RowLayout {
            visible: !root.compactMode
            Layout.fillWidth: true
            Text { text: "󰕾"; color: AudioService.outputMuted ? Colors.error : Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL }
            Text { text: "Output"; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.Medium }
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
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.Medium
              }
            }
            SharedWidgets.MuteButton {
              target: "@DEFAULT_AUDIO_SINK@"
              muted: AudioService.outputMuted
              icon: "󰕾"; mutedIcon: "󰝟"
            }
          }

          ColumnLayout {
            visible: root.compactMode
            Layout.fillWidth: true
            spacing: Colors.spacingXS

            RowLayout {
              Layout.fillWidth: true
              Text { text: "󰕾"; color: AudioService.outputMuted ? Colors.error : Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL }
              Text { text: "Output"; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.Medium }
              Item { Layout.fillWidth: true }
              SharedWidgets.MuteButton {
                target: "@DEFAULT_AUDIO_SINK@"
                muted: AudioService.outputMuted
                icon: "󰕾"; mutedIcon: "󰝟"
              }
            }

            Rectangle {
              radius: 12
              color: AudioService.outputMuted ? Colors.withAlpha(Colors.error, 0.16) : Colors.highlightLight
              implicitWidth: outputPercentLabelCompact.implicitWidth + 16
              implicitHeight: 24
              Text {
                id: outputPercentLabelCompact
                anchors.centerIn: parent
                text: root.percentText(AudioService.outputVolume, AudioService.outputMuted)
                color: AudioService.outputMuted ? Colors.error : Colors.textSecondary
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.Medium
              }
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
          implicitHeight: root.compactMode ? 56 : 46
          radius: Colors.radiusMedium
          property bool isDefault: modelData.id === AudioService.defaultSinkId
          property bool isHovered: sinkHover.containsMouse
          color: isDefault ? Colors.withAlpha(Colors.primary, 0.16) : (isHovered ? Colors.withAlpha(Colors.primary, 0.12) : Colors.cardSurface)
          border.color: isDefault ? Colors.primary : Colors.border
          border.width: 1
          Behavior on color { ColorAnimation { duration: 160 } }

          RowLayout {
            anchors.fill: parent
            anchors.margins: Colors.paddingSmall
            spacing: Colors.paddingSmall
            Text { text: sinkCard.isDefault ? "󰄬" : "󰕾"; color: sinkCard.isDefault ? Colors.primary : Colors.textSecondary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeLarge }
            Text { text: modelData.name; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: sinkCard.isDefault ? Font.DemiBold : Font.Normal; elide: Text.ElideRight; Layout.fillWidth: true }
            Text { text: Math.min(Math.round(modelData.volume * 100), 100) + "%"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS }
            Text { visible: !root.compactMode; text: sinkCard.isDefault ? "Default" : "Select"; color: sinkCard.isDefault ? Colors.primary : Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Medium }
          }

          MouseArea { id: sinkHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: AudioService.setDefaultDevice(modelData.id) }
        }
      }

      SharedWidgets.EmptyState {
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        visible: AudioService.sinks.length === 0
        icon: "󰕿"
        message: "No output devices detected"
      }

      // ── INPUT section ──────────────────────────
      SharedWidgets.SectionLabel { label: "INPUT" }

      Rectangle {
        Layout.fillWidth: true
        radius: Colors.radiusMedium
        color: Colors.cardSurface
        border.color: Colors.border
        border.width: 1
        implicitHeight: inputCol.implicitHeight + 2 * Colors.spacingM

        ColumnLayout {
          id: inputCol
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: Colors.spacingM
          spacing: Colors.spacingS

          RowLayout {
            visible: !root.compactMode
            Layout.fillWidth: true
            Text { text: "󰍬"; color: AudioService.inputMuted ? Colors.error : Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL }
            Text { text: "Input"; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.Medium }
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
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.Medium
              }
            }
            SharedWidgets.MuteButton {
              target: "@DEFAULT_AUDIO_SOURCE@"
              muted: AudioService.inputMuted
              icon: "󰍬"; mutedIcon: "󰍭"
            }
          }

          ColumnLayout {
            visible: root.compactMode
            Layout.fillWidth: true
            spacing: Colors.spacingXS

            RowLayout {
              Layout.fillWidth: true
              Text { text: "󰍬"; color: AudioService.inputMuted ? Colors.error : Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL }
              Text { text: "Input"; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.Medium }
              Item { Layout.fillWidth: true }
              SharedWidgets.MuteButton {
                target: "@DEFAULT_AUDIO_SOURCE@"
                muted: AudioService.inputMuted
                icon: "󰍬"; mutedIcon: "󰍭"
              }
            }

            Rectangle {
              radius: 12
              color: AudioService.inputMuted ? Colors.withAlpha(Colors.error, 0.16) : Colors.highlightLight
              implicitWidth: inputPercentLabelCompact.implicitWidth + 16
              implicitHeight: 24
              Text {
                id: inputPercentLabelCompact
                anchors.centerIn: parent
                text: root.percentText(AudioService.inputVolume, AudioService.inputMuted)
                color: AudioService.inputMuted ? Colors.error : Colors.textSecondary
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.Medium
              }
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
          implicitHeight: root.compactMode ? 56 : 46
          radius: Colors.radiusMedium
          property bool isDefault: modelData.id === AudioService.defaultSourceId
          property bool isHovered: sourceHover.containsMouse
          color: isDefault ? Colors.withAlpha(Colors.primary, 0.16) : (isHovered ? Colors.withAlpha(Colors.primary, 0.12) : Colors.cardSurface)
          border.color: isDefault ? Colors.primary : Colors.border
          border.width: 1
          Behavior on color { ColorAnimation { duration: 160 } }

          RowLayout {
            anchors.fill: parent
            anchors.margins: Colors.paddingSmall
            spacing: Colors.paddingSmall
            Text { text: sourceCard.isDefault ? "󰄬" : "󰍬"; color: sourceCard.isDefault ? Colors.primary : Colors.textSecondary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeLarge }
            Text { text: modelData.name; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: sourceCard.isDefault ? Font.DemiBold : Font.Normal; elide: Text.ElideRight; Layout.fillWidth: true }
            Text { text: Math.min(Math.round(modelData.volume * 100), 100) + "%"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeXS }
            Text { visible: !root.compactMode; text: sourceCard.isDefault ? "Default" : "Select"; color: sourceCard.isDefault ? Colors.primary : Colors.textSecondary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Medium }
          }

          MouseArea { id: sourceHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: AudioService.setDefaultDevice(modelData.id) }
        }
      }

      SharedWidgets.EmptyState {
        Layout.fillWidth: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        visible: AudioService.sources.length === 0
        icon: "󰍭"
        message: "No input devices detected"
      }
  }
}
