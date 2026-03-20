import QtQuick
import QtQuick.Layouts
import "../../shared"
import "../../services"
import "../../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  popupMinWidth: 340; popupMaxWidth: 500; compactThreshold: 460
  implicitHeight: Math.min(600, 120 + (MarketService.marketData.length * 80))
  title: "Markets"
  subtitle: "Real-time quotes via Stooq"

  SharedWidgets.Ref { service: MarketService }

  SharedWidgets.ScrollableContent {
    Layout.fillWidth: true
    Layout.fillHeight: true
    columnSpacing: Appearance.spacingM

    Repeater {
      model: MarketService.marketData || []
      delegate: SharedWidgets.ThemedContainer {
        variant: "card"
        Layout.fillWidth: true
        implicitHeight: 70

        RowLayout {
          anchors.fill: parent
          anchors.margins: Appearance.spacingM
          spacing: Appearance.spacingM

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingXXS
            Text {
              text: modelData.symbol
              color: Colors.text
              font.pixelSize: Appearance.fontSizeLarge
              font.weight: Font.Bold
            }
            Text {
              text: "Last update: " + modelData.time
              color: Colors.textDisabled
              font.pixelSize: Appearance.fontSizeXS
            }
          }

          ColumnLayout {
            Layout.alignment: Qt.AlignRight
            spacing: Appearance.spacingXXS
            Text {
              text: modelData.close
              color: Colors.text
              font.pixelSize: Appearance.fontSizeLarge
              font.weight: Font.Bold
              Layout.alignment: Qt.AlignRight
            }
            RowLayout {
              Layout.alignment: Qt.AlignRight
              spacing: 4
              property real change: modelData.close - modelData.open
              property bool up: change >= 0
              Text {
                text: parent.up ? "▲" : "▼"
                color: parent.up ? Colors.success : Colors.error
                font.pixelSize: Appearance.fontSizeSmall
              }
              Text {
                text: Math.abs(parent.change).toFixed(2)
                color: parent.up ? Colors.success : Colors.error
                font.pixelSize: Appearance.fontSizeSmall
                font.weight: Font.DemiBold
              }
            }
          }
        }
      }
    }

    Text {
        visible: !MarketService.marketData || MarketService.marketData.length === 0
        text: "No market data available. Check your tickers in Settings."
        color: Colors.textDisabled
        font.pixelSize: Appearance.fontSizeMedium
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
        Layout.margins: Appearance.spacingL
    }
  }
}
