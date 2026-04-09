import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets

ColumnLayout {
    Layout.fillWidth: true
    spacing: Appearance.spacingSM

    Repeater {
        model: BrightnessService.monitors
        delegate: ColumnLayout {
            required property var modelData
            Layout.fillWidth: true
            spacing: Appearance.spacingSM
            RowLayout {
                Layout.fillWidth: true
                SharedWidgets.SvgIcon {
                    source: "weather-sunny.svg"
                    color: Colors.textDisabled
                    size: Appearance.fontSizeXS
                }
                Text {
                    text: BrightnessService.hasMultipleMonitors
                        ? modelData.name.toUpperCase() : "BRIGHTNESS"
                    color: Colors.textDisabled
                    font.pixelSize: Appearance.fontSizeXS
                    font.weight: Font.Bold
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: modelData.available
                        ? Math.round(modelData.brightness * 100) + "%" : "Unavailable"
                    color: modelData.available ? Colors.textSecondary : Colors.warning
                    font.pixelSize: Appearance.fontSizeXS
                }
            }
            SharedWidgets.SliderTrack {
                Layout.fillWidth: true
                value: modelData.brightness
                icon: "weather-sunny.svg"
                enabled: modelData.available
                opacity: enabled ? 1.0 : 0.4
                onSliderMoved: v => BrightnessService.setBrightness(
                    modelData.name, Math.max(0.01, v))
            }
        }
    }

    Text {
        visible: BrightnessService.monitors.length === 0
        text: "No brightness devices detected"
        color: Colors.textDisabled
        font.pixelSize: Appearance.fontSizeXS
        Layout.fillWidth: true
    }

    // Keyboard backlight slider
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacingSM
        visible: BrightnessService.kbdAvailable

        RowLayout {
            Layout.fillWidth: true
            SharedWidgets.SvgIcon {
                source: "keyboard.svg"
                color: Colors.textDisabled
                size: Appearance.fontSizeXS
            }
            Text {
                text: "KEYBOARD"
                color: Colors.textDisabled
                font.pixelSize: Appearance.fontSizeXS
                font.weight: Font.Bold
            }
            Item { Layout.fillWidth: true }
            Text {
                text: Math.round(BrightnessService.kbdDevice.brightness * 100) + "%"
                color: Colors.textSecondary
                font.pixelSize: Appearance.fontSizeXS
            }
        }
        SharedWidgets.SliderTrack {
            Layout.fillWidth: true
            value: BrightnessService.kbdDevice.brightness
            icon: "keyboard.svg"
            onSliderMoved: v => BrightnessService.setKbdBrightness(v)
        }
    }
}
