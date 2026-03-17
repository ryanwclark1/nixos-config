import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: weatherContent.implicitHeight + Colors.paddingMedium * 2
  color: Colors.cardSurface
  radius: Colors.radiusMedium
  border.color: Colors.border
  clip: true

  SharedWidgets.Ref { service: WeatherService }

  gradient: SharedWidgets.SurfaceGradient {}

  // Inner highlight
  SharedWidgets.InnerHighlight { }

  RowLayout {
    id: weatherContent
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
      Layout.fillWidth: true
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
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        maximumLineCount: 2
      }
    }
  }
}
