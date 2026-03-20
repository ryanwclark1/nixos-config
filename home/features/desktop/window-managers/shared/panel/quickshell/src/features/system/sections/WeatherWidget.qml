import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../shared" as Shared
import "../../../widgets" as SharedWidgets

Shared.ThemedContainer {
  id: root
  variant: "card"
  showGradient: true
  Layout.fillWidth: true
  Layout.preferredHeight: weatherContent.implicitHeight + Appearance.paddingMedium * 2
  clip: true

  SharedWidgets.Ref { service: WeatherService }

  RowLayout {
    id: weatherContent
    anchors.fill: parent
    anchors.margins: Appearance.paddingMedium
    spacing: Appearance.paddingMedium

    Text {
      text: Appearance.weatherIcon(WeatherService.condition)
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
