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
  property color warning: "#f1c40f"
  
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

  // --- POPUP SURFACES (shared across all menus) ---
  readonly property color popupSurface: withAlpha(surface, 0.96)
  readonly property color cardSurface: withAlpha(surface, 0.82)
  readonly property color chipSurface: withAlpha(surface, 0.92)
  readonly property color surfaceContainerHigh: Qt.lighter(popupSurface, 1.12)

  // --- DIMENSIONS ---
  readonly property real radiusLarge: 20
  readonly property real radiusMedium: 14
  readonly property real radiusSmall: 10
  readonly property real radiusXS: 8
  readonly property real radiusPill: 999

  readonly property int paddingLarge: 24
  readonly property int paddingMedium: 15
  readonly property int paddingSmall: 10

  // --- SPACING TOKENS ---
  readonly property int spacingXS: 4
  readonly property int spacingS: 8
  readonly property int spacingM: 12
  readonly property int spacingL: 16
  readonly property int spacingXL: 24

  // --- ANIMATION DURATIONS ---
  readonly property int durationFast: 160
  readonly property int durationNormal: 250
  readonly property int durationSlow: 350

  // --- TYPOGRAPHY TOKENS ---
  readonly property int fontSizeXS: 10
  readonly property int fontSizeSmall: 12
  readonly property int fontSizeMedium: 14
  readonly property int fontSizeLarge: 16
  readonly property int fontSizeXL: 20
  readonly property int fontSizeHuge: 24
  readonly property int fontWeightNormal: Font.Normal
  readonly property int fontWeightMedium: Font.Medium
  readonly property int fontWeightBold: Font.Bold

  function withAlpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }
  function clamp01(value) { return Math.max(0, Math.min(1, value)); }

  function weatherIcon(desc) {
    var d = (desc || "").toLowerCase();
    if (d.includes("sun") || d.includes("clear")) return "󰖙";
    if (d.includes("partly")) return "󰖕";
    if (d.includes("rain") || d.includes("drizzle")) return "󰖗";
    if (d.includes("thunder")) return "󰖓";
    if (d.includes("snow") || d.includes("sleet") || d.includes("blizzard")) return "󰼶";
    if (d.includes("fog") || d.includes("mist") || d.includes("haze")) return "󰖑";
    if (d.includes("cloud") || d.includes("overcast")) return "󰖐";
    return "󰖐";
  }

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
      warning = data.colors.color3;

      text = data.special.foreground;
      textSecondary = data.colors.color7;
      textDisabled = data.colors.color8;
      
    } catch (e) {
      // It's fine if the file doesn't exist yet, we'll use defaults
    }
  }

  property FileView walWatcher: FileView {
    path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
    blockLoading: true
    printErrors: false
    watchChanges: true
    onTextChanged: colors.reloadColors()
    onLoaded: colors.reloadColors()
  }
}
