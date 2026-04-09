import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../shared"
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
      icon: "settings.svg"
      iconSize: Appearance.fontSizeXL
      tooltipText: "Open mixer"
      onClicked: Quickshell.execDetached(["pavucontrol"])
    }
  ]

  SharedWidgets.ScrollableContent {
    Layout.fillWidth: true
    Layout.fillHeight: true
    columnSpacing: Appearance.spacingM

    SharedWidgets.AudioDeviceSection {
      Layout.fillWidth: true
      sectionLabel: "OUTPUT"
      icon: "speaker.svg"; mutedIcon: "speaker-mute.svg"
      volume: AudioService.outputVolume
      muted: AudioService.outputMuted
      target: "@DEFAULT_AUDIO_SINK@"
      deviceModel: AudioService.filteredSinks
      defaultDeviceId: AudioService.defaultSinkId
      emptyIcon: "speaker-off.svg"
      emptyMessage: "No output devices detected"
      compactMode: root.compactMode
      useCompactDevicePicker: root.compactMode
      onSliderMoved: (v) => AudioService.setVolume("@DEFAULT_AUDIO_SINK@", v)
    }

    SharedWidgets.AudioDeviceSection {
      Layout.fillWidth: true
      sectionLabel: "INPUT"
      icon: "mic.svg"; mutedIcon: "mic-off.svg"
      volume: AudioService.inputVolume
      muted: AudioService.inputMuted
      target: "@DEFAULT_AUDIO_SOURCE@"
      deviceModel: AudioService.filteredSources
      defaultDeviceId: AudioService.defaultSourceId
      emptyIcon: "mic-off.svg"
      emptyMessage: "No input devices detected"
      compactMode: root.compactMode
      useCompactDevicePicker: root.compactMode
      onSliderMoved: (v) => AudioService.setVolume("@DEFAULT_AUDIO_SOURCE@", v)
    }

    // ── Per-app volume ──────────────────────────
    ColumnLayout {
      Layout.fillWidth: true
      spacing: Appearance.spacingS
      visible: AudioService.outputAppNodes.length > 0

      SharedWidgets.SectionLabel { label: "APP VOLUME" }

      SharedWidgets.ThemedContainer {
        variant: "card"
        Layout.fillWidth: true
        implicitHeight: appCol.implicitHeight + 2 * Appearance.spacingM

        ColumnLayout {
          id: appCol
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: Appearance.spacingM
          spacing: Appearance.spacingS

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
