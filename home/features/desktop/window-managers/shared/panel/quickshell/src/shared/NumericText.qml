import QtQuick
import "../services"

// Text with tabular (fixed-width) digits to prevent layout jitter.
// All digits 0-9 render at the same width via OpenType tnum feature.
// Use for stats, clocks, timers, percentages, and any rapidly-changing numbers.
Text {
    color: Colors.text
    font.pixelSize: Appearance.fontSizeMedium
    font.weight: Font.DemiBold
    font.features: { "tnum": 1 }
}
