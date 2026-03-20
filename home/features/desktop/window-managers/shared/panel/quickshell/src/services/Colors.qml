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

    // ── Color transition control ───────────────
    property bool skipTransition: true
    property bool isTransitioning: false
    readonly property int _colorTransitionMs: Math.round(400 * _animScale)

    // ── Color transition behaviors ─────────────
    Behavior on background { enabled: !colors.skipTransition; ColorAnimation { duration: colors._colorTransitionMs; easing.type: Easing.OutCubic } }
    Behavior on surface { enabled: !colors.skipTransition; ColorAnimation { duration: colors._colorTransitionMs; easing.type: Easing.OutCubic } }
    Behavior on primary { enabled: !colors.skipTransition; ColorAnimation { duration: colors._colorTransitionMs; easing.type: Easing.OutCubic } }
    Behavior on secondary { enabled: !colors.skipTransition; ColorAnimation { duration: colors._colorTransitionMs; easing.type: Easing.OutCubic } }
    Behavior on accent { enabled: !colors.skipTransition; ColorAnimation { duration: colors._colorTransitionMs; easing.type: Easing.OutCubic } }
    Behavior on error { enabled: !colors.skipTransition; ColorAnimation { duration: colors._colorTransitionMs; easing.type: Easing.OutCubic } }
    Behavior on warning { enabled: !colors.skipTransition; ColorAnimation { duration: colors._colorTransitionMs; easing.type: Easing.OutCubic } }
    Behavior on success { enabled: !colors.skipTransition; ColorAnimation { duration: colors._colorTransitionMs; easing.type: Easing.OutCubic } }
    Behavior on info { enabled: !colors.skipTransition; ColorAnimation { duration: colors._colorTransitionMs; easing.type: Easing.OutCubic } }
    Behavior on text { enabled: !colors.skipTransition; ColorAnimation { duration: colors._colorTransitionMs; easing.type: Easing.OutCubic } }
    Behavior on textSecondary { enabled: !colors.skipTransition; ColorAnimation { duration: colors._colorTransitionMs; easing.type: Easing.OutCubic } }
    Behavior on textDisabled { enabled: !colors.skipTransition; ColorAnimation { duration: colors._colorTransitionMs; easing.type: Easing.OutCubic } }

    // --- DERIVED PROPERTIES (Auto-updating) ---
    readonly property string fontMono: Config.monoFontFamily || "JetBrainsMono Nerd Font"
    readonly property real _fontScale: clampScale(Config.fontScale, 1.0)
    readonly property real _radiusScale: clampScale(Config.radiusScale, 1.0)
    readonly property real _spacingScale: clampScale(Config.spacingScale * Config.uiDensityScale, 1.0)
    
    // Eco Mode: Auto-downscale animations on battery
    readonly property bool _isEcoMode: Config.autoEcoMode && SystemStatus.isBatteryPowered
    readonly property bool _isGameMode: GameModeService.active
    readonly property real _powerAnimScale: _isGameMode ? 0.3 : (_isEcoMode ? 0.6 : 1.0)
    readonly property real _animScale: Config.animationSpeedScale * _powerAnimScale

    readonly property color border: withAlpha(text, 0.15)
    readonly property color highlight: withAlpha(primary, 0.25)
    readonly property color highlightLight: withAlpha(primary, 0.15)

    // --- TRANSPARENCY TIERS ---
    readonly property real opacityBase: Config.glassOpacityBase
    readonly property real opacitySurface: Config.glassOpacitySurface
    readonly property real opacityOverlay: Config.glassOpacityOverlay

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
        onColorsChanged: colors.applyDynamicPalette()
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
    readonly property real bgOpacity: autoTransparencyEnabled ? (1.0 - autoGlassOpacity) : opacityBase
    readonly property color bgGlass: withAlpha(background, bgOpacity)
    readonly property color bgWidget: _isLight ? Qt.rgba(0, 0, 0, 0.06) : Qt.rgba(1, 1, 1, 0.08)
    readonly property color bg: background

    // --- GRADIENTS & DEPTH ---
    readonly property color surfaceGradientStart: withAlpha(surface, opacitySurface)
    readonly property color surfaceGradientEnd: withAlpha(surface, opacitySurface * 0.95)
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
    readonly property color popupSurface: withAlpha(surface, opacityBase)
    readonly property color cardSurface: withAlpha(surface, opacitySurface)
    readonly property color chipSurface: withAlpha(surface, opacityOverlay)
    readonly property color modalFieldSurface: chipSurface

    property Connections _configConn: Connections {
        target: Config
        function onUseDynamicThemingChanged() {
            if (Config.useDynamicTheming)
                colors.applyDynamicPalette();
            else
                colors.reloadColors();
        }
    }

    property Timer _transitionTimer: Timer {
        interval: colors._colorTransitionMs + 50
        onTriggered: colors.isTransitioning = false
    }

    property Connections _wallpaperConn: Connections {
        target: WallpaperService
        function onWallpapersChanged() {
            if (Config.useDynamicTheming)
                colors.applyDynamicPalette();
        }
    }

    Component.onCompleted: {
        if (Config.useDynamicTheming)
            colors.applyDynamicPalette();
        else
            colors.reloadColors();
        Qt.callLater(function() { colors.skipTransition = false; });
    }


    // --- DIMENSIONS ---
    readonly property int spacingXXS: scaledMetric(2, _spacingScale, 1)
    readonly property int spacingXS: scaledMetric(4, _spacingScale, 2)
    readonly property int spacingSM: scaledMetric(6, _spacingScale, 3)
    readonly property int spacingS: scaledMetric(8, _spacingScale, 4)
    readonly property int spacingM: scaledMetric(12, _spacingScale, 8)
    readonly property int spacingL: scaledMetric(16, _spacingScale, 10)
    readonly property int spacingLG: scaledMetric(20, _spacingScale, 12)
    readonly property int spacingXL: scaledMetric(24, _spacingScale, 16)

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
    readonly property int durationFlash: Math.round(80 * _animScale)
    readonly property int durationSnap: Math.round(100 * _animScale)
    readonly property int durationMedium: Math.round(220 * _animScale)
    readonly property int durationFast: Math.round(160 * _animScale)
    readonly property int durationNormal: Math.round(250 * _animScale)
    readonly property int durationSlow: Math.round(350 * _animScale)
    readonly property int durationEmphasis: Math.round(400 * _animScale)
    readonly property int durationPulse: Math.round(600 * _animScale)
    readonly property int durationShake: Math.round(50 * _animScale)
    readonly property int durationPanelClose: Math.round(260 * _animScale)
    readonly property int durationPanelOpen: Math.round(320 * _animScale)
    readonly property int durationLong: Math.round(800 * _animScale)

    // --- ANIMATION EASING PRESETS ---
    // Named bezier-curve presets for consistent motion across the shell.
    // Based on Material Design 3 expressive motion.
    readonly property var animMove: ({
        duration: Math.round(320 * _animScale),
        type: Easing.BezierSpline,
        bezierCurve: [0.38, 1.21, 0.22, 1.00, 1, 1]
    })
    readonly property var animEnter: ({
        duration: Math.round(400 * _animScale),
        type: Easing.BezierSpline,
        bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1]
    })
    readonly property var animExit: ({
        duration: Math.round(200 * _animScale),
        type: Easing.BezierSpline,
        bezierCurve: [0.3, 0, 0.8, 0.15, 1, 1]
    })
    readonly property var animFastSpatial: ({
        duration: Math.round(350 * _animScale),
        type: Easing.BezierSpline,
        bezierCurve: [0.42, 1.67, 0.21, 0.90, 1, 1]
    })
    readonly property var animEffect: ({
        duration: Math.round(200 * _animScale),
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

    // ── Container variant definitions ─────────────
    // Returns a fresh object with current color values for the given variant.
    // Used by ThemedContainer to auto-apply visual treatment.
    function containerVariant(name) {
        switch (name) {
        case "popup":
            return {
                color: popupSurface,
                borderColor: border,
                borderWidth: 1,
                radius: radiusLarge,
                gradient: true,
                highlightOpacity: 0.15
            };
        case "card":
            return {
                color: cardSurface,
                borderColor: border,
                borderWidth: 1,
                radius: radiusMedium,
                gradient: false,
                highlightOpacity: 0.1
            };
        case "elevated":
            return {
                color: chipSurface,
                borderColor: border,
                borderWidth: 1,
                radius: radiusCard,
                gradient: false,
                highlightOpacity: 0.08
            };
        case "surface":
            return {
                color: Qt.alpha(surface, opacitySurface),
                borderColor: "transparent",
                borderWidth: 0,
                radius: radiusSmall,
                gradient: true,
                highlightOpacity: 0
            };
        case "pill":
            return {
                color: Qt.alpha(surface, opacityOverlay),
                borderColor: border,
                borderWidth: 1,
                radius: radiusPill,
                gradient: true,
                highlightOpacity: 0.08
            };
        default:
            return {
                color: cardSurface,
                borderColor: border,
                borderWidth: 1,
                radius: radiusMedium,
                gradient: false,
                highlightOpacity: 0.1
            };
        }
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

    function aqiColor(value, isUS) {
        var v = parseInt(value);
        if (isNaN(v)) return Colors.textDisabled;
        if (isUS) {
            if (v <= 50) return "#4caf50";
            if (v <= 100) return "#ffeb3b";
            if (v <= 150) return "#ff9800";
            if (v <= 200) return "#f44336";
            if (v <= 300) return "#9c27b0";
            return "#7e0023";
        }
        if (v <= 20) return "#4caf50";
        if (v <= 40) return "#8bc34a";
        if (v <= 60) return "#ffeb3b";
        if (v <= 80) return "#ff9800";
        if (v <= 100) return "#f44336";
        return "#7e0023";
    }

    property bool _themeActive: false

    function applyBase24(palette, variant) {
        if (!palette) return;
        isTransitioning = true;
        _transitionTimer.restart();
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
        var done = Logger.perf("Colors", "reloadColors");
        isTransitioning = true;
        _transitionTimer.restart();
        var raw = walColorsFile.text();
        if (!raw) {
            done();
            return;
        }
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
            Logger.e("Colors", "failed to reload wal colors:", e);
        }
        done();
    }

    property FileView walColorsFile: FileView {
        path: Quickshell.env("HOME") + "/.cache/wal/colors.json"
        blockLoading: true
        printErrors: false
        watchChanges: true
        onTextChanged: colors.reloadColors()
        onLoaded: colors.reloadColors()
    }

    function getLuminance(c) {
        var r = c.r, g = c.g, b = c.b;
        var R = (r <= 0.03928) ? r / 12.92 : Math.pow((r + 0.055) / 1.055, 2.4);
        var G = (g <= 0.03928) ? g / 12.92 : Math.pow((g + 0.055) / 1.055, 2.4);
        var B = (b <= 0.03928) ? b / 12.92 : Math.pow((b + 0.055) / 1.055, 2.4);
        return 0.2126 * R + 0.7152 * G + 0.0722 * B;
    }

    function getContrastRatio(c1, c2) {
        var l1 = getLuminance(c1);
        var l2 = getLuminance(c2);
        return (Math.max(l1, l2) + 0.05) / (Math.min(l1, l2) + 0.05);
    }

    function applyDynamicPalette() {
        if (!Config.useDynamicTheming) return;
        var c = _wallpaperQuant.colors;
        if (!c || c.length === 0) return;

        // Extract vibrant and muted tones
        var p = c[0].color; // dominant
        var s = c.length > 1 ? c[1].color : p;
        var a = c.length > 2 ? c[2].color : s;

        background = withAlpha(p, 1.0);
        surface = withAlpha(p, 0.95);
        primary = withAlpha(s, 1.0);
        accent = withAlpha(a, 1.0);

        // Smart Contrast: Pick best text color
        var whiteContrast = getContrastRatio(background, Qt.rgba(1,1,1,1));
        var blackContrast = getContrastRatio(background, Qt.rgba(0,0,0,1));

        var textColor = (whiteContrast > blackContrast) ? "#ffffff" : "#000000";
        _isLight = (whiteContrast <= blackContrast);

        text = textColor;
        textSecondary = withAlpha(textColor, 0.7);
        textDisabled = withAlpha(textColor, 0.4);
    }
}
