import QtQuick
import QtQuick.Layouts
import "../services"

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
    color: Colors.withAlpha(Colors.surface, 0.2)
    border.color: Colors.withAlpha(Colors.border, 0.4)
    border.width: 1

    gradient: Gradient {
    orientation: Gradient.Vertical
    GradientStop { position: 0.0; color: Colors.surfaceGradientStart }
    GradientStop { position: 1.0; color: Colors.surfaceGradientEnd }
}

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
