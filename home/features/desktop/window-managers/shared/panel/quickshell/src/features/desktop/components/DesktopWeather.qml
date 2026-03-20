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
    anchors.margins: -Appearance.spacingM
    radius: Appearance.radiusLarge
    color: Colors.cardSurface
    border.color: Colors.borderMedium
    border.width: 1

    gradient: SurfaceGradient {}

    // Inner highlight
    InnerHighlight { }
  }

  RowLayout {
    id: row
    spacing: Appearance.spacingL

    AnimatedWeatherIcon {
      condition: WeatherService.condition
      color: Colors.primary
      size: Appearance.fontSizeIcon
    }

    ColumnLayout {
      spacing: Appearance.spacingXXS

      Text {
        text: WeatherService.temp || "--"
        color: Colors.text
        font.pixelSize: Appearance.fontSizeHuge
        font.weight: Font.Bold
      }

      Text {
        text: WeatherService.condition || "Unknown"
        color: Colors.textSecondary
        font.pixelSize: Appearance.fontSizeSmall
      }

      Text {
        text: WeatherService.location || ""
        color: Colors.textDisabled
        font.pixelSize: Appearance.fontSizeXS
        visible: text !== ""
      }
    }
  }
}
