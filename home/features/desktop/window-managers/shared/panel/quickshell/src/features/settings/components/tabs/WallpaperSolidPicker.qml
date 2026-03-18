import QtQuick
import QtQuick.Layouts
import "../../../../services"
import "../../../../services/ColorUtils.js" as ColorUtils
import ".."

Rectangle {
    id: root
    required property bool compactMode
    required property bool tightSpacing
    required property real pickerHue
    required property real pickerSaturation
    required property real pickerValue
    required property real pickerAlpha

    signal pickerHueEdited(real v)
    signal pickerSaturationEdited(real v)
    signal pickerValueEdited(real v)
    signal pickerAlphaEdited(real v)
    signal applyRequested()
    signal cancelRequested()

    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.45)
    z: 2000

    readonly property string currentHex: {
        var rgb = ColorUtils.hsvToRgb(pickerHue, pickerSaturation / 100, pickerValue / 100);
        var a = Math.round(Math.max(0, Math.min(100, pickerAlpha)) * 2.55);
        return ColorUtils.hex2(rgb.r) + ColorUtils.hex2(rgb.g) + ColorUtils.hex2(rgb.b) + ColorUtils.hex2(a);
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.cancelRequested()
    }

    Rectangle {
        width: Math.min(parent.width - (root.tightSpacing ? 32 : 60), 560)
        color: Colors.bgGlass
        border.color: Colors.border
        border.width: 1
        radius: Colors.radiusLarge
        anchors.centerIn: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Colors.spacingL
            spacing: Colors.spacingM

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Colors.spacingS

                Text {
                    width: root.compactMode ? parent.width : Math.max(0, parent.width - solidPickerCloseButton.implicitWidth - Colors.spacingS)
                    text: "Solid Color Picker"
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeLarge
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                }

                SettingsActionButton {
                    id: solidPickerCloseButton
                    label: "Close"
                    compact: true
                    onClicked: root.cancelRequested()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 52
                radius: Colors.radiusMedium
                color: "#" + root.currentHex.slice(0, 6)
                border.color: Colors.border
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "#" + root.currentHex.toUpperCase()
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeMedium
                    font.family: Colors.fontMono
                    font.weight: Font.Medium
                }
            }

            SettingsSliderRow {
                label: "Hue"
                min: 0
                max: 360
                step: 1
                unit: ""
                value: root.pickerHue
                onMoved: v => root.pickerHueEdited(v)
            }

            SettingsSliderRow {
                label: "Saturation"
                min: 0
                max: 100
                step: 1
                unit: "%"
                value: root.pickerSaturation
                onMoved: v => root.pickerSaturationEdited(v)
            }

            SettingsSliderRow {
                label: "Brightness"
                min: 0
                max: 100
                step: 1
                unit: "%"
                value: root.pickerValue
                onMoved: v => root.pickerValueEdited(v)
            }

            SettingsSliderRow {
                label: "Alpha"
                min: 0
                max: 100
                step: 1
                unit: "%"
                value: root.pickerAlpha
                onMoved: v => root.pickerAlphaEdited(v)
            }

            Flow {
                Layout.fillWidth: true
                width: parent.width
                spacing: Colors.spacingS

                SettingsActionButton {
                    label: "Cancel"
                    compact: true
                    onClicked: root.cancelRequested()
                }

                SettingsActionButton {
                    label: "Apply Color"
                    compact: true
                    emphasized: true
                    onClicked: root.applyRequested()
                }
            }
        }
    }
}
