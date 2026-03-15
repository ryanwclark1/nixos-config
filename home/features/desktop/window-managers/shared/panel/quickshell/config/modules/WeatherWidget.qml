import QtQuick
import QtQuick.Layouts
import "../services"

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: 80
  color: Colors.withAlpha(Colors.surface, 0.4)
  radius: Colors.radiusMedium
  border.color: Colors.border
  clip: true

  gradient: Gradient {
    orientation: Gradient.Vertical
    GradientStop { position: 0.0; color: Colors.surfaceGradientStart }
    GradientStop { position: 1.0; color: Colors.surfaceGradientEnd }
  }

  // Inner highlight
  Rectangle {
    anchors.fill: parent
    anchors.margins: 1
    radius: parent.radius - 1
    color: "transparent"
    border.color: Colors.borderLight
    border.width: 1
    opacity: 0.1
  }

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
        color: Colors.textDisabled
        font.pixelSize: Colors.fontSizeSmall
        elide: Text.ElideRight
        Layout.fillWidth: true
      }
    }
  }
}
