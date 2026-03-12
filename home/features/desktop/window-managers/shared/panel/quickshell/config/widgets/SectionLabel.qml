import QtQuick
import "../services"

// SectionLabel — uppercase section header used across popup menus.
//
// Usage:
//   SectionLabel { label: "OUTPUT" }

Text {
  property string label: ""
  text: label
  color: Colors.textDisabled
  font.pixelSize: Colors.fontSizeXS
  font.weight: Font.Bold
  font.letterSpacing: 0.5
}
