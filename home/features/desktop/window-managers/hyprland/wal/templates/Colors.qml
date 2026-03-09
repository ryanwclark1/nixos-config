import QtQuick

pragma Singleton

QtObject {
  // --- COLORS ---
  readonly property color background: "{{background}}"
  readonly property color surface: "{{color0}}"
  readonly property color primary: "{{color4}}"
  readonly property color secondary: "{{color2}}"
  readonly property color accent: "{{color5}}"
  readonly property color error: "{{color1}}"
  
  readonly property color text: "{{foreground}}"
  readonly property color textSecondary: "{{color7}}"
  readonly property color textDisabled: "{{color8}}"
  
  readonly property color border: "{{color8}}4d"
  readonly property color highlight: "{{color4}}4d"
  readonly property color highlightLight: "{{color4}}1a"
  
  // --- GLASSMORPHISM ---
  readonly property real bgOpacity: 0.65
  readonly property color bgGlass: Qt.rgba(background.r, background.g, background.b, bgOpacity)
  
  // --- DIMENSIONS ---
  readonly property real radiusLarge: 16
  readonly property real radiusMedium: 12
  readonly property real radiusSmall: 8
  
  readonly property int paddingLarge: 24
  readonly property int paddingMedium: 15
  readonly property int paddingSmall: 10
}
