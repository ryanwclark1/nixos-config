import QtQuick
import Quickshell
import Quickshell.Io

pragma Singleton

QtObject {
  id: colors
  
  // --- COLORS (Dynamic) ---
  property color background: "#101014"
  property color surface: "#2a2b2e"
  property color primary: "#4caf50"
  property color secondary: "#81c784"
  property color accent: "#ffb74d"
  property color error: "#e57373"
  
  property color text: "#ffffff"
  property color textSecondary: "#aaaaaa"
  property color textDisabled: "#666666"
  
  // --- DERIVED PROPERTIES (Auto-updating) ---
  readonly property color fgMain: text
  readonly property color fgSecondary: textSecondary
  readonly property color fgDim: textDisabled

  readonly property color border: Qt.rgba(textDisabled.r, textDisabled.g, textDisabled.b, 0.2)
  readonly property color highlight: Qt.rgba(primary.r, primary.g, primary.b, 0.2)
  readonly property color highlightLight: Qt.rgba(primary.r, primary.g, primary.b, 0.1)
  
  // --- GLASSMORPHISM ---
  readonly property real bgOpacity: 0.65
  readonly property color bgGlass: Qt.rgba(background.r, background.g, background.b, bgOpacity)
  readonly property color bgWidget: Qt.rgba(255, 255, 255, 0.05)
  
  // --- DIMENSIONS ---
  readonly property real radiusLarge: 16
  readonly property real radiusMedium: 12
  readonly property real radiusSmall: 8
  
  readonly property int paddingLarge: 24
  readonly property int paddingMedium: 15
  readonly property int paddingSmall: 10

  function reloadColors() {
    let home = Quickshell.env("HOME");
    let colorsPath = home + "/.cache/wal/colors.json";
    
    try {
      let file = File.open("file://" + colorsPath);
      let content = file.readAll();
      let data = JSON.parse(content);
      
      background = data.special.background;
      surface = data.colors.color0;
      primary = data.colors.color4;
      secondary = data.colors.color2;
      accent = data.colors.color5;
      error = data.colors.color1;
      
      text = data.special.foreground;
      textSecondary = data.colors.color7;
      textDisabled = data.colors.color8;
      
      // console.log("Quickshell colors reloaded from", colorsPath);
    } catch (e) {
      // It's fine if the file doesn't exist yet, we'll use defaults
      // console.log("Dynamic colors not yet available at", colorsPath);
    }
  }

  Component.onCompleted: {
    reloadColors();
  }

}
