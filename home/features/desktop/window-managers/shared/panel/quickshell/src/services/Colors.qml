pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "color/MaterialColorAdapter.js" as MatugenAdapter

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
    readonly property int _colorTransitionMs: Math.round(400 * Appearance._animScale)

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
        return Math.max(0, Math.min(0.40, y));
    }

    // Effective opacity tiers — auto-transparency adjusts all tiers proportionally
    property real _effectiveOpacityBase: autoTransparencyEnabled
        ? Math.min(opacityBase, 1.0 - autoGlassOpacity) : opacityBase
    property real _effectiveOpacitySurface: autoTransparencyEnabled
        ? Math.min(opacitySurface, _effectiveOpacityBase + 0.06) : opacitySurface
    property real _effectiveOpacityOverlay: autoTransparencyEnabled
        ? Math.min(opacityOverlay, _effectiveOpacitySurface + 0.04) : opacityOverlay
    Behavior on _effectiveOpacityBase { enabled: !colors.skipTransition; NumberAnimation { duration: colors._colorTransitionMs; easing.type: Easing.OutCubic } }
    Behavior on _effectiveOpacitySurface { enabled: !colors.skipTransition; NumberAnimation { duration: colors._colorTransitionMs; easing.type: Easing.OutCubic } }
    Behavior on _effectiveOpacityOverlay { enabled: !colors.skipTransition; NumberAnimation { duration: colors._colorTransitionMs; easing.type: Easing.OutCubic } }

    // --- OLED MODE ---
    // Forces background to pure black for power savings on OLED displays
    readonly property color _effectiveBackground: Config.oledMode ? "#000000" : background

    // --- GLASSMORPHISM ---
    readonly property real bgOpacity: _effectiveOpacityBase
    readonly property color bgGlass: withAlpha(_effectiveBackground, bgOpacity)
    readonly property color bgWidget: _isLight ? Qt.rgba(0, 0, 0, 0.06) : Qt.rgba(1, 1, 1, 0.08)
    readonly property color bg: _effectiveBackground

    // --- GRADIENTS & DEPTH ---
    readonly property color surfaceGradientStart: withAlpha(surface, _effectiveOpacitySurface)
    readonly property color surfaceGradientEnd: withAlpha(surface, _effectiveOpacitySurface * 0.95)
    readonly property color borderLight: withAlpha(text, 0.12)
    readonly property color borderDark: withAlpha("#000000", 0.25)
    readonly property color borderMedium: withAlpha(text, 0.4)       // Subtle separator / divider
    readonly property color borderFocus: withAlpha(text, 0.6)        // Focused input / strong border

    // --- STATUS COLOR ALIASES ---
    readonly property color errorLight: withAlpha(error, 0.15)       // Error indicator bg
    readonly property color warningLight: withAlpha(warning, 0.16)   // Warning indicator bg

    // --- OVERLAYS ---
    readonly property color overlayScrim: Qt.rgba(0, 0, 0, 0.45)

    // --- SURFACE ELEVATION HIERARCHY (MD3-inspired) ---
    readonly property color surfaceContainerLowest: withAlpha(_effectiveBackground, _effectiveOpacityBase)
    readonly property color surfaceContainerLow: withAlpha(surface, _effectiveOpacityBase * 0.97)
    readonly property color surfaceContainer: withAlpha(surface, _effectiveOpacityBase)
    readonly property color surfaceContainerHigh: withAlpha(surface, _effectiveOpacitySurface)
    readonly property color surfaceContainerHighest: withAlpha(surface, _effectiveOpacityOverlay)

    // --- POPUP SURFACES (shared across all menus) ---
    readonly property color popupSurface: surfaceContainer
    readonly property color cardSurface: surfaceContainerHigh
    readonly property color chipSurface: surfaceContainerHighest
    readonly property color modalFieldSurface: chipSurface

    property Connections _configConn: Connections {
        target: Config
        function onUseDynamicThemingChanged() { colors._applyColorBackend(); }
        function onColorBackendChanged() { colors._applyColorBackend(); }
    }

    property Timer _transitionTimer: Timer {
        interval: colors._colorTransitionMs + 50
        onTriggered: colors.isTransitioning = false
    }

    property Connections _wallpaperConn: Connections {
        target: WallpaperService
        function onWallpapersChanged() {
            if (Config.useDynamicTheming || Config.colorBackend === "matugen")
                colors._applyColorBackend();
        }
    }

    property FileView _matugenColorsFile: FileView {
        path: Quickshell.env("HOME") + "/.cache/matugen/colors.json"
        blockLoading: true
        printErrors: false
        watchChanges: true
        onTextChanged: { if (Config.colorBackend === "matugen") colors._loadMatugenColors(); }
        onLoaded: { if (Config.colorBackend === "matugen") colors._loadMatugenColors(); }
    }

    property Process _matugenProc: Process {
        running: false
        stdout: SplitParser { onRead: line => {} }
        onExited: (code, status) => {
            if (code === 0) colors._matugenColorsFile.reload();
            else Logger.w("Colors", "matugen exited with code", code);
        }
    }

    function _generateMatugenColors() {
        var keys = Object.keys(WallpaperService.wallpapers);
        var wallpaper = WallpaperService.wallpapers["__all__"]
            || (keys.length > 0 ? WallpaperService.wallpapers[keys[0]] : "");
        if (!wallpaper) return;
        var outPath = (Quickshell.env("HOME") || "/home") + "/.cache/matugen/colors.json";
        _matugenProc.command = ["sh", "-c",
            'mkdir -p "$(dirname "$2")" && matugen image "$1" --json hex --dry-run > "$2"',
            "sh", wallpaper, outPath];
        _matugenProc.running = true;
    }

    function _loadMatugenColors() {
        var raw = _matugenColorsFile.text();
        if (!raw) return;
        var scheme = MatugenAdapter.parseMatugenOutput(raw);
        if (!scheme) { Logger.w("Colors", "Failed to parse matugen colors"); return; }
        isTransitioning = true;
        _transitionTimer.restart();
        MatugenAdapter.applyScheme(scheme, colors);
    }

    function _applyColorBackend() {
        if (_themeActive) return;
        var backend = Config.colorBackend || "pywal";
        if (backend === "matugen") _generateMatugenColors();
        else if (backend === "dynamic" || Config.useDynamicTheming) applyDynamicPalette();
        else reloadColors();
    }

    property bool colorsReady: false

    Component.onCompleted: {
        colors._applyColorBackend();
        colorsReady = true;
        Qt.callLater(function() { colors.skipTransition = false; });
    }

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
