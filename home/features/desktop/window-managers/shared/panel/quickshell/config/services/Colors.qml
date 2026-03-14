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
  property color success: "#a6d189"
  property color info: "#81c8be"

  property bool _isLight: false

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
  readonly property color bgWidget: _isLight ? Qt.rgba(0, 0, 0, 0.06) : Qt.rgba(1, 1, 1, 0.08)

  // --- POPUP SURFACES (shared across all menus) ---
  readonly property color popupSurface: withAlpha(surface, 0.96)
  readonly property color cardSurface: withAlpha(surface, 0.82)
  readonly property color chipSurface: withAlpha(surface, 0.92)
  readonly property color surfaceContainerHigh: Qt.lighter(popupSurface, 1.12)
  readonly property color modalSurface: solid(surface)
  readonly property color modalSidebarSurface: _isLight ? Qt.darker(modalSurface, 1.06) : Qt.darker(modalSurface, 1.18)
  readonly property color modalCardSurface: _isLight ? Qt.darker(modalSurface, 1.03) : Qt.lighter(modalSurface, 1.12)
  readonly property color modalFieldSurface: _isLight ? Qt.darker(modalSurface, 1.02) : Qt.lighter(modalSurface, 1.08)

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
  function solid(c) { return Qt.rgba(c.r, c.g, c.b, 1); }
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

  function applyBase24(palette, variant) {
    if (!palette) return;
    _isLight = (variant === "light");

    background    = palette.base00 || background;
    // Derive surface close to background — base01 is "lighter bg" in base16,
    // but some themes set it far from base00.  Nudge base00 slightly instead.
    var bg = Qt.color(palette.base00 || background);
    surface = _isLight ? Qt.darker(bg, 1.06) : Qt.lighter(bg, 1.15);

    textDisabled  = palette.base03 || textDisabled;
    textSecondary = palette.base04 || textSecondary;
    text          = palette.base05 || text;
    error         = palette.base08 || error;
    warning       = palette.base09 || warning;
    success       = palette.base0B || success;
    info          = palette.base0C || info;
    primary       = palette.base0D || primary;
    secondary     = palette.base0E || secondary;
    accent        = palette.base0F || accent;
  }

  function reloadColors() {
    // Skip pywal if a base24 theme is active
    if (Config.themeName) return;

    try {
      let content = walWatcher.text();
      if (!content) return;
      let data = JSON.parse(content);

      _isLight = false;
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
      console.debug("Colors: pywal colors not loaded, using defaults");
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
