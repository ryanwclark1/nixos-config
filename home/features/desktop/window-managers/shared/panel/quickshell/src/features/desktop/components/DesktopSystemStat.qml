import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets"

Item {
  id: root
  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight

  Ref { service: SystemStatus }

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
    spacing: 36

    ColumnLayout {
      spacing: Appearance.spacingXS
      Text { text: "CPU"; color: Colors.textDisabled; font.pixelSize: Appearance.fontSizeXS; font.weight: Font.Bold; font.letterSpacing: Appearance.letterSpacingWide }
      RowLayout {
        spacing: Appearance.spacingSM
        SvgIcon { source: "developer-board.svg"; color: Colors.primary; size: Appearance.fontSizeXL }
        Text { text: SystemStatus.cpuUsage; color: Colors.text; font.pixelSize: Appearance.fontSizeLarge; font.weight: Font.Bold }
      }
    }

    ColumnLayout {
      spacing: Appearance.spacingXS
      Text { text: "RAM"; color: Colors.textDisabled; font.pixelSize: Appearance.fontSizeXS; font.weight: Font.Bold; font.letterSpacing: Appearance.letterSpacingWide }
      RowLayout {
        spacing: Appearance.spacingSM
        SvgIcon { source: "memory.svg"; color: Colors.secondary; size: Appearance.fontSizeXL }
        Text { text: SystemStatus.ramUsage; color: Colors.text; font.pixelSize: Appearance.fontSizeLarge; font.weight: Font.Bold }
      }
    }

    ColumnLayout {
      spacing: Appearance.spacingXS
      Text { text: "TEMP"; color: Colors.textDisabled; font.pixelSize: Appearance.fontSizeXS; font.weight: Font.Bold; font.letterSpacing: Appearance.letterSpacingWide }
      RowLayout {
        spacing: Appearance.spacingSM
        SvgIcon { source: "temperature.svg"; color: Colors.warning; size: Appearance.fontSizeXL }
        Text { text: SystemStatus.cpuTemp || "--"; color: Colors.text; font.pixelSize: Appearance.fontSizeLarge; font.weight: Font.Bold }
      }
    }
  }
}
