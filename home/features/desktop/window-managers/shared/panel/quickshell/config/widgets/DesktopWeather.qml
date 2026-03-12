import QtQuick
import QtQuick.Layouts
import "../services"

Item {
  id: root
  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight

  RowLayout {
    id: row
    spacing: Colors.spacingM

    Text {
      text: Colors.weatherIcon(WeatherService.condition)
      color: Colors.primary
      font.family: Colors.fontMono
      font.pixelSize: 32
    }

    ColumnLayout {
      spacing: 2

      Text {
        text: WeatherService.temp || "--"
        color: Colors.text
        font.pixelSize: Colors.fontSizeHuge
        font.weight: Font.Bold
      }

      Text {
        text: WeatherService.condition || "Unknown"
        color: Colors.fgSecondary
        font.pixelSize: Colors.fontSizeSmall
      }

      Text {
        text: WeatherService.location || ""
        color: Colors.textDisabled
        font.pixelSize: Colors.fontSizeXS
        visible: text !== ""
      }
    }
  }
}
