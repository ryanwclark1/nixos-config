import QtQuick
import "../services"

// SectionLabel — uppercase section header used across popup menus.
//
// Usage:
//   SectionLabel { label: "OUTPUT" }

Text {
  property string label: ""
  text: label
  color: Colors.textSecondary
  font.pixelSize: Appearance.fontSizeXS
  font.weight: Font.Bold
  font.letterSpacing: 0.5
}
