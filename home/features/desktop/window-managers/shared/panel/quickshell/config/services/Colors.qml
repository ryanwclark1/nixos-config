import QtQuick

pragma Singleton

QtObject {
  // --- COLORS ---
  readonly property color background: "#101014"
  readonly property color surface: "#2a2b2e"
  readonly property color primary: "#4caf50"
  readonly property color secondary: "#81c784"
  readonly property color accent: "#ffb74d"
  readonly property color error: "#e57373"
  
  readonly property color text: "#ffffff"
  readonly property color textSecondary: "#aaaaaa"
  readonly property color textDisabled: "#666666"
  
  readonly property color border: "#33ffffff"
  readonly property color highlight: "#33ffffff"
  readonly property color highlightLight: "#1affffff"
  
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
