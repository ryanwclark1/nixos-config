import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets"

Item {
  id: root
  Ref { service: WeatherService }
  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight

  Rectangle {
    id: bg
    anchors.fill: parent
    anchors.margins: -Colors.spacingM
    radius: Colors.radiusLarge
    color: Colors.cardSurface
    border.color: Colors.borderMedium
    border.width: 1

    gradient: SurfaceGradient {}

    // Inner highlight
    InnerHighlight { }
  }

  RowLayout {
    id: row
    spacing: Colors.spacingL

    Text {
      text: Colors.weatherIcon(WeatherService.condition)
      color: Colors.primary
      font.family: Colors.fontMono
      font.pixelSize: Colors.fontSizeIcon
    }

    ColumnLayout {
      spacing: Colors.spacingXXS

      Text {
        text: WeatherService.temp || "--"
        color: Colors.text
        font.pixelSize: Colors.fontSizeHuge
        font.weight: Font.Bold
      }

      Text {
        text: WeatherService.condition || "Unknown"
        color: Colors.textSecondary
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
