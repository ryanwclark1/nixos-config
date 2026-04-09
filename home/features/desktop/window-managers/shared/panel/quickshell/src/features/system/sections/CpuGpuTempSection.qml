import QtQuick
import QtQuick.Layouts
import "../../../services"

RowLayout {
    Layout.fillWidth: true
    spacing: Appearance.spacingM

    Rectangle {
        Layout.fillWidth: true
        height: 60
        color: Colors.bgWidget
        radius: Appearance.radiusSmall
        border.color: Colors.border
        border.width: 1
        Column {
            anchors.centerIn: parent
            spacing: Appearance.spacingXXS
            Text {
                text: "CPU TEMP"
                color: Colors.textDisabled
                font.pixelSize: Appearance.fontSizeXS
                font.weight: Font.Bold
            }
            Text {
                text: SystemStatus.cpuTemp
                color: Colors.primary
                font.pixelSize: Appearance.fontSizeLarge
                font.weight: Font.Bold
            }
        }
    }
    Rectangle {
        Layout.fillWidth: true
        height: 60
        color: Colors.bgWidget
        radius: Appearance.radiusSmall
        border.color: Colors.border
        border.width: 1
        Column {
            anchors.centerIn: parent
            spacing: Appearance.spacingXXS
            Text {
                text: "GPU TEMP"
                color: Colors.textDisabled
                font.pixelSize: Appearance.fontSizeXS
                font.weight: Font.Bold
            }
            Text {
                text: SystemStatus.gpuTemp
                color: Colors.accent
                font.pixelSize: Appearance.fontSizeLarge
                font.weight: Font.Bold
            }
        }
    }
}
