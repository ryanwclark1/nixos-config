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
    spacing: 15

    Text {
      text: Colors.weatherIcon(WeatherService.condition)
      color: Colors.accent
      font.family: Colors.fontMono
      font.pixelSize: 32
    }

    ColumnLayout {
      spacing: 2
      Text {
        text: WeatherService.temp
        color: Colors.fgMain
        font.pixelSize: 18
        font.weight: Font.Bold
      }
      Text {
        text: (WeatherService.condition || "Unknown") + " in " + (WeatherService.location || "Local")
        color: Colors.fgDim
        font.pixelSize: 11
        elide: Text.ElideRight
        Layout.fillWidth: true
      }
    }
  }
}
