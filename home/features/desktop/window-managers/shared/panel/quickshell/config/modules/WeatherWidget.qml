import QtQuick
import QtQuick.Layouts
import "../services"

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: 80
  color: Colors.bgWidget
  radius: Colors.radiusMedium
  border.color: Colors.border
  clip: true

  RowLayout {
    anchors.fill: parent
    anchors.margins: Colors.paddingMedium
    spacing: Colors.paddingMedium

    Text {
      text: Colors.weatherIcon(WeatherService.condition)
      color: Colors.accent
      font.family: Colors.fontMono
      font.pixelSize: Colors.fontSizeIcon
    }

    ColumnLayout {
      spacing: Colors.spacingXXS
      Text {
        text: WeatherService.temp
        color: Colors.text
        font.pixelSize: Colors.fontSizeXL
        font.weight: Font.Bold
      }
      Text {
        text: (WeatherService.condition || "Unknown") + " in " + (WeatherService.location || "Local")
        color: Colors.fgDim
        font.pixelSize: Colors.fontSizeSmall
        elide: Text.ElideRight
        Layout.fillWidth: true
      }
    }
  }
}
