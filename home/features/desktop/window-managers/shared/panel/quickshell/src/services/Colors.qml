pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

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
    readonly property string fontMono: Config.monoFontFamily || "JetBrainsMono Nerd Font"
    readonly property real _fontScale: clampScale(Config.fontScale, 1.0)
    readonly property real _radiusScale: clampScale(Config.radiusScale, 1.0)
    readonly property real _spacingScale: clampScale(Config.spacingScale, 1.0)

    readonly property color border: withAlpha(text, 0.15)
    readonly property color highlight: withAlpha(primary, 0.25)
    readonly property color highlightLight: withAlpha(primary, 0.15)

    // --- TEXT COLOR ALIASES ---
    readonly property color textFaint: withAlpha(text, 0.06)         // Subtle code/card bg
    readonly property color textWash: withAlpha(text, 0.08)          // Hover bg / subtle fill
    readonly property color textThin: withAlpha(text, 0.1)           // Subtle border / light separator

    // --- PRIMARY COLOR ALIASES ---
    readonly property color primaryFaint: withAlpha(primary, 0.08)   // Light hover state
    readonly property color primaryGhost: withAlpha(primary, 0.1)    // Ghost hover / faint tint
    readonly property color primarySubtle: withAlpha(primary, 0.12)  // Hover/selected card bg
    readonly property color primaryAccent: withAlpha(primary, 0.14)  // Selected item bg
    readonly property color primaryStrong: withAlpha(primary, 0.16)  // Active/default item bg
    readonly property color primaryMid: withAlpha(primary, 0.18)     // Active chip/button bg
    readonly property color primaryTint: withAlpha(primary, 0.2)     // Soft active bg / badge
    readonly property color primaryMarked: withAlpha(primary, 0.22)  // Drag target / strong selection
    readonly property color primaryRing: withAlpha(primary, 0.3)     // Focus ring / emphasis border

    // --- AUTO-TRANSPARENCY (wallpaper-driven) ---
    property bool autoTransparencyEnabled: Config.autoTransparency !== undefined ? Config.autoTransparency : false

    property ColorQuantizer _wallpaperQuant: ColorQuantizer {
        source: {
            var keys = Object.keys(WallpaperService.wallpapers);
            var path = WallpaperService.wallpapers["__all__"]
                || (keys.length > 0 ? WallpaperService.wallpapers[keys[0]] : "");
            return path ? Qt.resolvedUrl("file://" + path) : "";
        }
        depth: 0
        rescaleSize: 10
    }

    readonly property real _wallpaperVibrancy: {
        var c = _wallpaperQuant.colors;
        if (!c || c.length === 0) return 0.5;
        return (c[0].hslSaturation + c[0].hslLightness) / 2;
    }

    readonly property real autoGlassOpacity: {
        var x = _wallpaperVibrancy;
        var y = 0.5768 * x * x - 0.759 * x + 0.2896;
        return Math.max(0, Math.min(0.22, y));
    }

    // --- GLASSMORPHISM ---
    readonly property real bgOpacity: autoTransparencyEnabled ? (1.0 - autoGlassOpacity) : Config.glassOpacity
    readonly property color bgGlass: withAlpha(background, bgOpacity)
    readonly property color bgWidget: _isLight ? Qt.rgba(0, 0, 0, 0.06) : Qt.rgba(1, 1, 1, 0.08)
    readonly property color bg: background

    // --- GRADIENTS & DEPTH ---
    readonly property color surfaceGradientStart: solid(surface)
    readonly property color surfaceGradientEnd: solid(surface)
    readonly property color borderLight: withAlpha(text, 0.12)
    readonly property color borderDark: withAlpha("#000000", 0.25)
    readonly property color borderMedium: withAlpha(text, 0.4)       // Subtle separator / divider
    readonly property color borderFocus: withAlpha(text, 0.6)        // Focused input / strong border

    // --- STATUS COLOR ALIASES ---
    readonly property color errorLight: withAlpha(error, 0.15)       // Error indicator bg
    readonly property color warningLight: withAlpha(warning, 0.16)   // Warning indicator bg

    // --- OVERLAYS ---
    readonly property color overlayScrim: Qt.rgba(0, 0, 0, 0.45)

    // --- POPUP SURFACES (shared across all menus) ---
    property real _popupOpacity: 0.96
    property real _cardOpacity: 0.96
    readonly property color popupSurface: withAlpha(surface, _popupOpacity)
    readonly property color cardSurface: withAlpha(surface, _cardOpacity)
    readonly property color chipSurface: withAlpha(surface, 0.92)
    readonly property color modalFieldSurface: chipSurface

    property Connections _configConn: Connections {
        target: Config
        function onPopupOpacityChanged() { colors._popupOpacity = Config.popupOpacity; }
        function onCardOpacityChanged() { colors._cardOpacity = Config.cardOpacity; }
    }

    Component.onCompleted: {
        if (Config) {
            colors._popupOpacity = Config.popupOpacity;
            colors._cardOpacity = Config.cardOpacity;
        }
        colors.reloadColors();
    }


    // --- DIMENSIONS ---
    readonly property int spacingXXS: 2
    readonly property int spacingXS: 4
    readonly property int spacingSM: 6
    readonly property int spacingS: 8
    readonly property int spacingM: 12
    readonly property int spacingL: 16
    readonly property int spacingLG: 20
    readonly property int spacingXL: 24

    readonly property int paddingSmall: scaledMetric(8, _spacingScale, 4)
    readonly property int paddingMedium: scaledMetric(12, _spacingScale, 8)
    readonly property int paddingLarge: scaledMetric(20, _spacingScale, 12)

    readonly property int radiusXXXS: scaledMetric(1, _radiusScale, 1)
    readonly property int radiusXXS: scaledMetric(2, _radiusScale, 1)
    readonly property int radiusMicro: radiusXXS
    readonly property int radiusXS: scaledMetric(4, _radiusScale, 2)
    readonly property int radiusSmall: scaledMetric(8, _radiusScale, 4)
    readonly property int radiusMedium: scaledMetric(12, _radiusScale, 6)
    readonly property int radiusLarge: scaledMetric(16, _radiusScale, 8)
    readonly property int radiusXL: scaledMetric(24, _radiusScale, 12)
    readonly property int radiusCard: radiusMedium
    readonly property int radiusPill: 999

    // --- ANIMATIONS ---
    readonly property int durationFlash: 80
    readonly property int durationSnap: 100
    readonly property int durationMedium: 220
    readonly property int durationFast: 160
    readonly property int durationNormal: 250
    readonly property int durationSlow: 350
    readonly property int durationEmphasis: 400
    readonly property int durationPulse: 600
    readonly property int durationShake: 50        // Lock screen auth shake micro-steps
    readonly property int durationPanelClose: 260  // Sidebar panel fade/scale out
    readonly property int durationPanelOpen: 320   // Sidebar panel scale in (OutBack)
    readonly property int durationLong: 800        // Extended pulse/countdown animations

    // --- ANIMATION EASING PRESETS ---
    // Named bezier-curve presets for consistent motion across the shell.
    // Based on Material Design 3 expressive motion.
    readonly property var animMove: ({
        duration: 320,
        type: Easing.BezierSpline,
        bezierCurve: [0.38, 1.21, 0.22, 1.00, 1, 1]
    })
    readonly property var animEnter: ({
        duration: 400,
        type: Easing.BezierSpline,
        bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1]
    })
    readonly property var animExit: ({
        duration: 200,
        type: Easing.BezierSpline,
        bezierCurve: [0.3, 0, 0.8, 0.15, 1, 1]
    })
    readonly property var animFastSpatial: ({
        duration: 350,
        type: Easing.BezierSpline,
        bezierCurve: [0.42, 1.67, 0.21, 0.90, 1, 1]
    })
    readonly property var animEffect: ({
        duration: 200,
        type: Easing.BezierSpline,
        bezierCurve: [0.34, 0.80, 0.34, 1.00, 1, 1]
    })

    // --- LETTER-SPACING TOKENS ---
    readonly property real letterSpacingTight: -0.5
    readonly property real letterSpacingWide: 1.0
    readonly property real letterSpacingExtraWide: 1.2

    // --- TYPOGRAPHY TOKENS ---
    readonly property int fontSizeXXS: scaledMetric(8, _fontScale, 7)
    readonly property int fontSizeXS: scaledMetric(12, _fontScale, 10)
    readonly property int fontSizeSmall: scaledMetric(13, _fontScale, 11)
    readonly property int fontSizeMedium: scaledMetric(14, _fontScale, 11)
    readonly property int fontSizeLarge: scaledMetric(16, _fontScale, 12)
    readonly property int fontSizeXL: scaledMetric(20, _fontScale, 14)
    readonly property int fontSizeIcon: fontSizeXL
    readonly property int fontSizeXXL: scaledMetric(26, _fontScale, 18)
    readonly property int fontSizeHuge: scaledMetric(32, _fontScale, 20)
    readonly property int fontSizeDisplay: scaledMetric(28, _fontScale, 20)

    function withAlpha(c, a) {
        if (c === undefined || c === null || c === "")
            return "transparent";
        return Qt.rgba(c.r, c.g, c.b, a);
    }
    function solid(c) {
        if (c === undefined || c === null || c === "")
            return "transparent";
        return Qt.rgba(c.r, c.g, c.b, 1);
    }
    function clamp01(value) {
        return Math.max(0, Math.min(1, value));
    }
    function scaledMetric(base, scale, min) {
        return Math.max(min, Math.round(base * scale));
    }
    function clampScale(scale, min) {
        return Math.max(min, Math.min(2.5, scale));
    }

    function weatherIcon(condition) {
        if (!condition) return "󰖐";
        var c = condition.toLowerCase();
        if (c.includes("clear") || c.includes("sunny")) return "󰖙";
        if (c.includes("cloud")) return "󰖐";
        if (c.includes("rain") || c.includes("drizzle")) return "󰖖";
        if (c.includes("snow") || c.includes("sleet")) return "󰖘";
        if (c.includes("thunder") || c.includes("storm")) return "󰖓";
        if (c.includes("fog") || c.includes("mist")) return "󰖑";
        return "󰖐";
    }

    property bool _themeActive: false

    function applyBase24(palette, variant) {
        if (!palette) return;
        _themeActive = true;
        _isLight = (variant === "light");
        background = palette.base00 || background;
        surface = palette.base01 || surface;
        primary = palette.base0D || primary;
        secondary = palette.base0E || secondary;
        accent = palette.base0A || accent;
        error = palette.base08 || error;
        warning = palette.base09 || warning;
        success = palette.base0B || success;
        text = palette.base05 || text;
        textSecondary = palette.base04 || textSecondary;
        textDisabled = palette.base03 || textDisabled;
    }

    function reloadColors() {
        if (_themeActive) return;
        var raw = walColorsFile.text();
        if (!raw) return;
        try {
            var data = JSON.parse(raw);
            if (data.special) {
                background = data.special.background || background;
                surface = data.colors.color8 || surface;
                primary = data.colors.color1 || primary;
                secondary = data.colors.color2 || secondary;
                accent = data.colors.color4 || accent;
                text = data.special.foreground || text;
            }
        } catch (e) {
            console.error("Colors: failed to reload wal colors: " + e);
        }
    }

    property FileView walColorsFile: FileView {
        path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
        blockLoading: true
        printErrors: false
        watchChanges: true
        onTextChanged: colors.reloadColors()
        onLoaded: colors.reloadColors()
    }
}
