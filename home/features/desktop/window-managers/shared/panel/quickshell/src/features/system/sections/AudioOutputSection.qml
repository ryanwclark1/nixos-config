import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets

ColumnLayout {
    Layout.fillWidth: true
    spacing: Appearance.spacingSM

    RowLayout {
        Layout.fillWidth: true
        SharedWidgets.SvgIcon {
            source: "speaker.svg"
            color: Colors.textDisabled
            size: Appearance.fontSizeXS
        }
        Text {
            text: "OUTPUT"
            color: Colors.textDisabled
            font.pixelSize: Appearance.fontSizeXS
            font.weight: Font.Bold
        }
        Item {
            Layout.fillWidth: true
        }
        SharedWidgets.NumericText {
            text: AudioService.outputMuted ? "Muted" : Math.round(AudioService.outputVolume * 100) + "%"
            color: Colors.textSecondary
            font.pixelSize: Appearance.fontSizeXS
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.paddingSmall
        SharedWidgets.MuteButton {
            target: "@DEFAULT_AUDIO_SINK@"
            muted: AudioService.outputMuted
            icon: "speaker.svg"
            mutedIcon: "speaker-mute.svg"
            size: Appearance.iconSizeMedium
            showBorder: true
        }
        SharedWidgets.SliderTrack {
            Layout.fillWidth: true
            value: AudioService.outputVolume
            muted: AudioService.outputMuted
            icon: "speaker.svg"
            mutedIcon: "speaker-mute.svg"
            onSliderMoved: v => AudioService.setVolume("@DEFAULT_AUDIO_SINK@", v)
        }
    }
}
