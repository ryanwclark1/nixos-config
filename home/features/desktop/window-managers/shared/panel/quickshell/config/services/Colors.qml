import QtQuick
import Quickshell
import Quickshell.Io
import "."

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

  readonly property color border: withAlpha(text, 0.15)
  readonly property color highlight: withAlpha(primary, 0.25)
  readonly property color highlightLight: withAlpha(primary, 0.15)
  
  // --- GLASSMORPHISM ---
  readonly property real bgOpacity: Config.glassOpacity
  readonly property color bgGlass: withAlpha(background, bgOpacity)
  readonly property color bgWidget: Qt.rgba(1, 1, 1, 0.08)
  
  // --- DIMENSIONS ---
  readonly property real radiusLarge: 20
  readonly property real radiusMedium: 14
  readonly property real radiusSmall: 10
  
  readonly property int paddingLarge: 24
  readonly property int paddingMedium: 15
  readonly property int paddingSmall: 10

  function withAlpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }
  function clamp01(value) { return Math.max(0, Math.min(1, value)); }

  function reloadColors() {
    try {
      let content = walWatcher.text();
      if (!content) return;
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
      
    } catch (e) {
      // It's fine if the file doesn't exist yet, we'll use defaults
    }
  }

  property FileView walWatcher: FileView {
    path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
    watchChanges: true
    onTextChanged: colors.reloadColors()
    onLoaded: colors.reloadColors()
  }
}
