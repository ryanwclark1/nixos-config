import QtQuick

pragma Singleton

QtObject {
  // --- COLORS ---
  readonly property color bgTranslucent: "#a6101014"
  readonly property color bgWidget: "#1affffff"
  readonly property color bgHover: "#33ffffff"
  readonly property color accent: "#4caf50"
  readonly property color warning: "#ff9800"
  readonly property color critical: "#f44336"
  readonly property color fgMain: "#ffffff"
  readonly property color fgSecondary: "#aaaaaa"
  readonly property color fgDim: "#66ffffff"
  readonly property color border: "#33ffffff"

  // --- DIMENSIONS ---
  readonly property int radiusLarge: 16
  readonly property int radiusMedium: 10
  readonly property int radiusSmall: 6
  readonly property int paddingLarge: 24
  readonly property int paddingMedium: 15
  readonly property int paddingSmall: 10

  // --- FONTS ---
  readonly property string fontMono: "JetBrainsMono Nerd Font"
  readonly property string fontSans: "Inter" // Fallback to system sans
}
