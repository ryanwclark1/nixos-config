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
            source: "mic.svg"
            color: Colors.textDisabled
            size: Appearance.fontSizeXS
        }
        Text {
            text: "INPUT"
            color: Colors.textDisabled
            font.pixelSize: Appearance.fontSizeXS
            font.weight: Font.Bold
        }
        Item {
            Layout.fillWidth: true
        }
        SharedWidgets.NumericText {
            text: AudioService.inputMuted ? "Muted" : Math.round(AudioService.inputVolume * 100) + "%"
            color: Colors.textSecondary
            font.pixelSize: Appearance.fontSizeXS
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.paddingSmall
        SharedWidgets.MuteButton {
            target: "@DEFAULT_AUDIO_SOURCE@"
            muted: AudioService.inputMuted
            icon: "mic.svg"
            mutedIcon: "mic-off.svg"
            size: Appearance.iconSizeMedium
            showBorder: true
        }
        SharedWidgets.SliderTrack {
            Layout.fillWidth: true
            value: AudioService.inputVolume
            muted: AudioService.inputMuted
            icon: "mic.svg"
            mutedIcon: "mic-off.svg"
            onSliderMoved: v => AudioService.setVolume("@DEFAULT_AUDIO_SOURCE@", v)
        }
    }
}
