pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "."

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

    readonly property string fontMain: Config.fontFamily || "Inter"
    readonly property string fontMono: Config.monoFontFamily || "JetBrainsMono Nerd Font"
    readonly property real _fontScale: clampScale(Config.fontScale, 1.0)
    readonly property real _radiusScale: clampScale(Config.radiusScale, 1.0)
    readonly property real _spacingScale: clampScale(Config.spacingScale, 1.0)

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
    readonly property real radiusLarge: scaledMetric(20, _radiusScale, 8)
    readonly property real radiusCard: scaledMetric(12, _radiusScale, 4)
    readonly property real radiusMedium: scaledMetric(14, _radiusScale, 6)
    readonly property real radiusSmall: scaledMetric(10, _radiusScale, 4)
    readonly property real radiusXS: scaledMetric(8, _radiusScale, 4)
    readonly property real radiusXXS: scaledMetric(6, _radiusScale, 2)
    readonly property real radiusMicro: scaledMetric(2, _radiusScale, 1)
    readonly property real radiusPill: 999

    readonly property int paddingLarge: scaledMetric(24, _spacingScale, 12)
    readonly property int paddingMedium: scaledMetric(15, _spacingScale, 8)
    readonly property int paddingSmall: scaledMetric(10, _spacingScale, 6)

    // --- SPACING TOKENS ---
    readonly property int spacingXXS: scaledMetric(2, _spacingScale, 1)
    readonly property int spacingXS: scaledMetric(4, _spacingScale, 2)
    readonly property int spacingSM: scaledMetric(6, _spacingScale, 3)
    readonly property int spacingS: scaledMetric(8, _spacingScale, 4)
    readonly property int spacingM: scaledMetric(12, _spacingScale, 6)
    readonly property int spacingL: scaledMetric(16, _spacingScale, 8)
    readonly property int spacingLG: scaledMetric(20, _spacingScale, 10)
    readonly property int spacingXL: scaledMetric(24, _spacingScale, 12)

    // --- ANIMATION DURATIONS ---
    readonly property int durationFlash: 60
    readonly property int durationSnap: 100
    readonly property int durationMedium: 220
    readonly property int durationFast: 160
    readonly property int durationNormal: 250
    readonly property int durationSlow: 350
    readonly property int durationEmphasis: 400
    readonly property int durationPulse: 600

    // --- LETTER-SPACING TOKENS ---
    readonly property real letterSpacingTight: -0.5
    readonly property real letterSpacingWide: 1.0
    readonly property real letterSpacingExtraWide: 1.2

    // --- TYPOGRAPHY TOKENS ---
    readonly property int fontSizeXXS: scaledMetric(8, _fontScale, 7)
    readonly property int fontSizeXS: scaledMetric(10, _fontScale, 9)
    readonly property int fontSizeSmall: scaledMetric(12, _fontScale, 10)
    readonly property int fontSizeMedium: scaledMetric(14, _fontScale, 11)
    readonly property int fontSizeLarge: scaledMetric(16, _fontScale, 12)
    readonly property int fontSizeXL: scaledMetric(20, _fontScale, 14)
    readonly property int fontSizeHuge: scaledMetric(24, _fontScale, 16)
    readonly property int fontSizeDisplay: scaledMetric(28, _fontScale, 20)
    readonly property int fontSizeIcon: scaledMetric(32, _fontScale, 22)
    readonly property int fontWeightNormal: Font.Normal
    readonly property int fontWeightMedium: Font.Medium
    readonly property int fontWeightBold: Font.Bold

    function withAlpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }
    function solid(c) {
        return Qt.rgba(c.r, c.g, c.b, 1);
    }
    function clamp01(value) {
        return Math.max(0, Math.min(1, value));
    }
    function clampScale(value, fallback) {
        var n = Number(value);
        if (isNaN(n))
            return fallback;
        return Math.max(0.75, Math.min(1.5, n));
    }
    function scaledMetric(base, factor, minimum) {
        return Math.max(minimum || 1, Math.round(Number(base || 0) * factor));
    }

    // ── WCAG contrast utilities ───────────────────
    // Relative luminance per WCAG 2.1 §1.4.3
    function _srgbChannel(c) {
        return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
    }
    function luminance(c) {
        return 0.2126 * _srgbChannel(c.r) + 0.7152 * _srgbChannel(c.g) + 0.0722 * _srgbChannel(c.b);
    }
    function contrastRatio(fg, bg) {
        var l1 = luminance(fg);
        var l2 = luminance(bg);
        var lighter = Math.max(l1, l2);
        var darker = Math.min(l1, l2);
        return (lighter + 0.05) / (darker + 0.05);
    }
    // Returns true if the pair meets WCAG AA for normal text (4.5:1).
    function meetsContrastAA(fg, bg) {
        return contrastRatio(fg, bg) >= 4.5;
    }
    // Adjusts `fg` toward white or black until it meets minRatio against `bg`.
    // Returns the adjusted color, or the original if already passing.
    function ensureReadable(fg, bg, minRatio) {
        if (minRatio === undefined) minRatio = 4.5;
        if (contrastRatio(fg, bg) >= minRatio) return fg;

        var bgLum = luminance(bg);
        // Try lightening if bg is dark, darkening if bg is light
        var target = bgLum > 0.5 ? Qt.darker(fg, 1.0) : Qt.lighter(fg, 1.0);
        for (var i = 0; i < 20; i++) {
            var step = 1.0 + (i + 1) * 0.1;
            target = bgLum > 0.5 ? Qt.darker(fg, step) : Qt.lighter(fg, step);
            if (contrastRatio(target, bg) >= minRatio) return target;
        }
        // Last resort: pure white or black
        return bgLum > 0.5 ? Qt.color("#000000") : Qt.color("#ffffff");
    }

    function weatherIcon(desc) {
        var d = (desc || "").toLowerCase();
        if (d.includes("sun") || d.includes("clear"))
            return "󰖙";
        if (d.includes("partly"))
            return "󰖕";
        if (d.includes("rain") || d.includes("drizzle"))
            return "󰖗";
        if (d.includes("thunder"))
            return "󰖓";
        if (d.includes("snow") || d.includes("sleet") || d.includes("blizzard"))
            return "󰼶";
        if (d.includes("fog") || d.includes("mist") || d.includes("haze"))
            return "󰖑";
        if (d.includes("cloud") || d.includes("overcast"))
            return "󰖐";
        return "󰖐";
    }

    function applyBase24(palette, variant) {
        if (!palette)
            return;
        _isLight = (variant === "light");

        background = palette.base00 || background;
        // Derive surface close to background — base01 is "lighter bg" in base16,
        // but some themes set it far from base00.  Nudge base00 slightly instead.
        var bg = Qt.color(palette.base00 || background);
        surface = _isLight ? Qt.darker(bg, 1.06) : Qt.lighter(bg, 1.15);

        textDisabled = palette.base03 || textDisabled;
        textSecondary = palette.base04 || textSecondary;
        text = palette.base05 || text;
        error = palette.base08 || error;
        warning = palette.base09 || warning;
        success = palette.base0B || success;
        info = palette.base0C || info;
        primary = palette.base0D || primary;
        secondary = palette.base0E || secondary;
        accent = palette.base0F || accent;
    }

    function reloadColors() {
        // Skip fallback wallpaper colors if a named theme is active.
        if (Config.themeName)
            return;

        try {
            let content = walWatcher.text();
            if (!content)
                return;
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
