.pragma library

// Maps matugen Material You JSON output to our Colors.qml properties.
// matugen outputs: { colors: { dark: { primary, on_primary, surface, ... }, light: {...} } }
// We map the dark scheme by default, light if _isLight is true.

function parseMatugenOutput(jsonText) {
    try {
        var data = JSON.parse(jsonText);
        if (!data || !data.colors) return null;
        return data.colors;
    } catch (e) {
        return null;
    }
}

function applyScheme(scheme, colors) {
    if (!scheme) return false;

    // Use dark scheme by default
    var s = scheme.dark || scheme.light;
    if (!s) return false;

    if (s.surface) colors.background = s.surface;
    if (s.surface_container) colors.surface = s.surface_container;
    if (s.primary) colors.primary = s.primary;
    if (s.secondary) colors.secondary = s.secondary;
    if (s.tertiary) colors.accent = s.tertiary;
    if (s.error) colors.error = s.error;
    if (s.on_surface) colors.text = s.on_surface;
    if (s.on_surface_variant) colors.textSecondary = s.on_surface_variant;
    if (s.outline) colors.textDisabled = s.outline;

    // Derive warning/success/info from the M3 palette if available
    if (s.tertiary_container) colors.warning = s.tertiary_container;

    return true;
}
