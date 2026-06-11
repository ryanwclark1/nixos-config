pragma Singleton
import QtQuick
import "WeatherVisuals.js" as WeatherVisuals

QtObject {
    id: appearance

    // ── Scale factors ──────────────────────────
    readonly property real _fontScale: clampScale(Config.fontScale, 0.8)
    readonly property real _radiusScale: clampScale(Config.radiusScale, 0.1)
    readonly property real _spacingScale: clampScale(Config.spacingScale * Config.uiDensityScale, 0.2)

    // Eco Mode: Auto-downscale animations on battery
    readonly property bool _isEcoMode: Config.autoEcoMode && SystemStatus.isBatteryPowered
    readonly property bool _isGameMode: GameModeService.active
    readonly property real _powerAnimScale: _isGameMode ? 0.3 : (_isEcoMode ? 0.6 : 1.0)
    readonly property real _animScale: Config.animationSpeedScale * _powerAnimScale

    // ── Font ───────────────────────────────────
    readonly property string fontMono: Config.monoFontFamily || "JetBrainsMono Nerd Font"

    // ── Spacing tokens ─────────────────────────
    readonly property int spacingXXS: scaledMetric(2, _spacingScale, 1)
    readonly property int spacingXS: scaledMetric(4, _spacingScale, 2)
    readonly property int spacingSM: scaledMetric(6, _spacingScale, 3)
    readonly property int spacingS: scaledMetric(8, _spacingScale, 4)
    readonly property int spacingM: scaledMetric(12, _spacingScale, 8)
    readonly property int spacingML: scaledMetric(14, _spacingScale, 10)
    readonly property int spacingL: scaledMetric(16, _spacingScale, 10)
    readonly property int spacingLG: scaledMetric(20, _spacingScale, 12)
    readonly property int spacingXL: scaledMetric(24, _spacingScale, 16)

    readonly property int controlRowHeight: scaledMetric(38, _spacingScale, 28)

    // ── Padding tokens ─────────────────────────
    readonly property int paddingSmall: scaledMetric(8, _spacingScale, 4)
    readonly property int paddingMedium: scaledMetric(12, _spacingScale, 8)
    readonly property int paddingLarge: scaledMetric(20, _spacingScale, 12)

    // ── Icon sizes (scale with spacing) ────────
    readonly property int iconSizeSmall: scaledMetric(24, _spacingScale, 18)
    readonly property int iconSizeMedium: scaledMetric(32, _spacingScale, 24)
    readonly property int iconSizeLarge: scaledMetric(48, _spacingScale, 36)

    // ── Radius tokens ──────────────────────────
    readonly property int radiusXXXS: scaledMetric(1, _radiusScale, 1)
    readonly property int radiusXXS: scaledMetric(2, _radiusScale, 1)
    readonly property int radiusMicro: radiusXXS
    readonly property int radiusXS3: scaledMetric(3, _radiusScale, 2)
    readonly property int radiusXS: scaledMetric(4, _radiusScale, 2)
    readonly property int radiusSmall: scaledMetric(8, _radiusScale, 4)
    readonly property int radiusMedium: scaledMetric(12, _radiusScale, 6)
    readonly property int radiusLarge: scaledMetric(16, _radiusScale, 8)
    readonly property int radiusXL: scaledMetric(24, _radiusScale, 12)
    readonly property int radiusCard: radiusMedium
    readonly property int radiusPill: 999

    // ── Duration tokens ────────────────────────
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
    readonly property int durationRipple: Math.round(450 * _animScale)
    readonly property int durationMediumSlow: Math.round(500 * _animScale)
    readonly property int durationAmbientShort: Math.round(1000 * _animScale)
    readonly property int durationAmbient: Math.round(2000 * _animScale)
    readonly property int durationMarquee: Math.round(5000 * _animScale)
    readonly property int durationWallpaper: Math.round(1500 * _animScale)
    readonly property int durationToast: 3000

    // ── Animation easing presets ───────────────
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

    // ── Letter-spacing tokens ──────────────────
    readonly property real letterSpacingTight: -0.5
    readonly property real letterSpacingWide: 1.0
    readonly property real letterSpacingExtraWide: 1.2

    // ── Typography tokens ──────────────────────
    readonly property int fontSizeCaption: scaledMetric(10, _fontScale, 9)
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
    readonly property int fontSizeGigantic: scaledMetric(48, _fontScale, 32)
    readonly property int fontSizeColossal: scaledMetric(64, _fontScale, 40)
    readonly property int fontSizeMassive: scaledMetric(96, _fontScale, 56)

    // ── Utility functions ──────────────────────
    function weatherIcon(condition) {
        return WeatherVisuals.visualForCondition(condition).icon;
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

    function scaledMetric(base, scale, min) {
        return Math.max(min, Math.round(base * scale));
    }
    function clampScale(scale, min) {
        return Math.max(min, Math.min(2.5, scale));
    }
}
