import QtQuick
import Quickshell
import Quickshell.Io

pragma Singleton

QtObject {
  id: colors
  
  // --- COLORS (Dynamic) ---
  property color background: "#0a0a0c"
  property color surface: "#1e1e24"
  property color primary: "#7289da"
  property color secondary: "#99aab5"
  property color accent: "#f39c12"
  property color error: "#f04747"
  
  property color text: "#ffffff"
  property color textSecondary: "#b9bbbe"
  property color textDisabled: "#72767d"
  
  // --- DERIVED PROPERTIES (Auto-updating) ---
  readonly property color fgMain: text
  readonly property color fgSecondary: textSecondary
  readonly property color fgDim: textDisabled

  readonly property string fontMain: "Inter"
  readonly property string fontMono: "JetBrainsMono Nerd Font"

  readonly property color border: Qt.rgba(text.r, text.g, text.b, 0.15)
  readonly property color highlight: Qt.rgba(primary.r, primary.g, primary.b, 0.25)
  readonly property color highlightLight: Qt.rgba(primary.r, primary.g, primary.b, 0.15)
  
  // --- GLASSMORPHISM ---
  readonly property real bgOpacity: 0.70
  readonly property color bgGlass: Qt.rgba(background.r, background.g, background.b, bgOpacity)
  readonly property color bgWidget: Qt.rgba(255, 255, 255, 0.08)
  
  // --- DIMENSIONS ---
  readonly property real radiusLarge: 20
  readonly property real radiusMedium: 14
  readonly property real radiusSmall: 10
  
  readonly property int paddingLarge: 24
  readonly property int paddingMedium: 15
  readonly property int paddingSmall: 10

  function reloadColors() {
    let home = Quickshell.env("HOME");
    let colorsPath = home + "/.cache/wal/colors.json";
    
    try {
      let file = Quickshell.openFile(colorsPath, File.ReadOnly);
      if (!file) return;
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
      
      file.close();
      // console.log("Quickshell colors reloaded from", colorsPath);
    } catch (e) {
      // It's fine if the file doesn't exist yet, we'll use defaults
      // console.log("Dynamic colors not yet available at", colorsPath);
    }
  }

  property FileView walWatcher: FileView {
    path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
    watchChanges: true
    onTextChanged: colors.reloadColors()
  }

  Component.onCompleted: {
    reloadColors();
  }

}
