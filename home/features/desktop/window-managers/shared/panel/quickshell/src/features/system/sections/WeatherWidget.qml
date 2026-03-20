import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: weatherContent.implicitHeight + Appearance.paddingMedium * 2
  color: Colors.cardSurface
  radius: Appearance.radiusLarge
  border.color: Colors.border
  clip: true

  SharedWidgets.Ref { service: WeatherService }

  gradient: SharedWidgets.SurfaceGradient {}

  // Inner highlight
  SharedWidgets.InnerHighlight { }

  RowLayout {
    id: weatherContent
    anchors.fill: parent
    anchors.margins: Appearance.paddingMedium
    spacing: Appearance.paddingMedium

    Text {
      text: Colors.weatherIcon(WeatherService.condition)
      color: Colors.accent
      font.family: Appearance.fontMono
      font.pixelSize: Appearance.fontSizeIcon
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Appearance.spacingXXS
      Text {
        text: WeatherService.temp
        color: Colors.text
        font.pixelSize: Appearance.fontSizeXL
        font.weight: Font.Bold
      }
      Text {
        text: (WeatherService.condition || "Unknown") + " in " + (WeatherService.location || "Local")
        color: Colors.textDisabled
        font.pixelSize: Appearance.fontSizeSmall
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        maximumLineCount: 2
      }
    }
  }
}
