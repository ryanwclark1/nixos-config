import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../shared"
import "../../services"
import "../../services/IconHelpers.js" as IconHelpers
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
        hovered: marketMouse.containsMouse

        RowLayout {
          anchors.fill: parent
          anchors.margins: Appearance.spacingM
          spacing: Appearance.spacingM

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingXXS
            Text {
              text: modelData.symbol || ""
              color: Colors.text
              font.pixelSize: Appearance.fontSizeLarge
              font.weight: Font.Bold
            }
            Text {
              text: "Last update: " + (modelData.time || "N/A")
              color: Colors.textDisabled
              font.pixelSize: Appearance.fontSizeXS
            }
          }

          ColumnLayout {
            Layout.alignment: Qt.AlignRight
            spacing: Appearance.spacingXXS
            Text {
              text: modelData.close || "0.00"
              color: Colors.text
              font.pixelSize: Appearance.fontSizeLarge
              font.weight: Font.Bold
              Layout.alignment: Qt.AlignRight
            }
            RowLayout {
              Layout.alignment: Qt.AlignRight
              spacing: 4
              property real change: (modelData.close || 0) - (modelData.open || 0)
              property bool up: change >= 0
              SharedWidgets.SvgIcon {
                source: IconHelpers.trendIndicatorIcon(parent.up)
                color: parent.up ? Colors.success : Colors.error
                size: Appearance.fontSizeSmall
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

        MouseArea {
          id: marketMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            var url = "https://stooq.com/q/?s=" + encodeURIComponent(modelData.symbol || "");
            Quickshell.execDetached(["xdg-open", url]);
          }
        }

        SharedWidgets.BarTooltip {
          text: "Click to view " + (modelData.symbol || "market") + " chart"
          hovered: marketMouse.containsMouse
          anchorItem: parent
          anchorWindow: root.anchorWindow
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
