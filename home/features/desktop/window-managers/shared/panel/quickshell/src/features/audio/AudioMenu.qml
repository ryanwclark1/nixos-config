import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../menu"
import "../../services"
import "../../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  popupMinWidth: 340; popupMaxWidth: 380; compactThreshold: 360
  implicitHeight: compactMode ? 620 : 560
  title: "Audio"

  SharedWidgets.Ref { service: AudioService }

  headerExtras: [
    SharedWidgets.IconButton {
      icon: "󰒓"
      iconSize: Colors.fontSizeXL
      onClicked: Quickshell.execDetached(["pavucontrol"])
    }
  ]

  SharedWidgets.ScrollableContent {
    Layout.fillWidth: true
    Layout.fillHeight: true
    columnSpacing: Colors.spacingM

    SharedWidgets.AudioDeviceSection {
      Layout.fillWidth: true
      sectionLabel: "OUTPUT"
      icon: "󰕾"; mutedIcon: "󰝟"
      volume: AudioService.outputVolume
      muted: AudioService.outputMuted
      target: "@DEFAULT_AUDIO_SINK@"
      deviceModel: AudioService.filteredSinks
      defaultDeviceId: AudioService.defaultSinkId
      emptyIcon: "󰕿"
      emptyMessage: "No output devices detected"
      compactMode: root.compactMode
      onSliderMoved: (v) => AudioService.setVolume("@DEFAULT_AUDIO_SINK@", v)
    }

    SharedWidgets.AudioDeviceSection {
      Layout.fillWidth: true
      sectionLabel: "INPUT"
      icon: "󰍬"; mutedIcon: "󰍭"
      volume: AudioService.inputVolume
      muted: AudioService.inputMuted
      target: "@DEFAULT_AUDIO_SOURCE@"
      deviceModel: AudioService.filteredSources
      defaultDeviceId: AudioService.defaultSourceId
      emptyIcon: "󰍭"
      emptyMessage: "No input devices detected"
      compactMode: root.compactMode
      onSliderMoved: (v) => AudioService.setVolume("@DEFAULT_AUDIO_SOURCE@", v)
    }

    // ── Per-app volume ──────────────────────────
    ColumnLayout {
      Layout.fillWidth: true
      spacing: Colors.spacingS
      visible: AudioService.outputAppNodes.length > 0

      SharedWidgets.SectionLabel { label: "APP VOLUME" }

      Rectangle {
        Layout.fillWidth: true
        radius: Colors.radiusMedium
        color: Colors.cardSurface
        border.color: Colors.border
        border.width: 1
        implicitHeight: appCol.implicitHeight + 2 * Colors.spacingM


        // Inner highlight
        SharedWidgets.InnerHighlight { }

        ColumnLayout {
          id: appCol
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: Colors.spacingM
          spacing: Colors.spacingS

          Repeater {
            model: AudioService.outputAppNodes
            delegate: SharedWidgets.AppVolumeEntry {
              Layout.fillWidth: true
              appNode: modelData
            }
          }
        }
      }
    }
  }
}
