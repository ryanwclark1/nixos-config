import QtQuick
import QtQuick.Layouts
import "../services"

Item {
  id: root
  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight

  Ref { service: SystemStatus }

  Rectangle {
    id: bg
    anchors.fill: parent
    anchors.margins: -Colors.spacingM
    radius: Colors.radiusLarge
    color: Colors.cardSurface
    border.color: Colors.withAlpha(Colors.border, 0.4)
    border.width: 1

    gradient: SurfaceGradient {}

    // Inner highlight
    InnerHighlight { }
  }

  RowLayout {
    id: row
    spacing: 36

    ColumnLayout {
      spacing: Colors.spacingXS
      Text { text: "CPU"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold; font.letterSpacing: Colors.letterSpacingWide }
      RowLayout {
        spacing: Colors.spacingSM
        Text { text: ""; color: Colors.primary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL }
        Text { text: SystemStatus.cpuUsage; color: Colors.text; font.pixelSize: Colors.fontSizeLarge; font.weight: Font.Bold }
      }
    }

    ColumnLayout {
      spacing: Colors.spacingXS
      Text { text: "RAM"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold; font.letterSpacing: Colors.letterSpacingWide }
      RowLayout {
        spacing: Colors.spacingSM
        Text { text: ""; color: Colors.secondary; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL }
        Text { text: SystemStatus.ramUsage; color: Colors.text; font.pixelSize: Colors.fontSizeLarge; font.weight: Font.Bold }
      }
    }

    ColumnLayout {
      spacing: Colors.spacingXS
      Text { text: "TEMP"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold; font.letterSpacing: Colors.letterSpacingWide }
      RowLayout {
        spacing: Colors.spacingSM
        Text { text: "󰔏"; color: Colors.warning; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeXL }
        Text { text: SystemStatus.cpuTemp || "--"; color: Colors.text; font.pixelSize: Colors.fontSizeLarge; font.weight: Font.Bold }
      }
    }
  }
}
