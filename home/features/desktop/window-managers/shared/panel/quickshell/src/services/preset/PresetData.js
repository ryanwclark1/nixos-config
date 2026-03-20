.pragma library

var EXCLUDED_TOP_LEVEL_KEYS = {
    "_version": true,
    "description": true
};

var EXCLUDED_PATHS = [
    ["ai", "anthropicKey"],
    ["ai", "openaiKey"],
    ["ai", "geminiKey"],
    ["state", "activeSurfaceId"]
];

function deepClone(value) {
    if (value === undefined)
        return undefined;
    return JSON.parse(JSON.stringify(value));
}

function _deletePath(target, pathParts) {
    var cursor = target;
    for (var i = 0; i < pathParts.length - 1; ++i) {
        var key = pathParts[i];
        if (!cursor || typeof cursor !== "object" || Array.isArray(cursor))
            return;
        cursor = cursor[key];
    }
    if (!cursor || typeof cursor !== "object" || Array.isArray(cursor))
        return;
    delete cursor[pathParts[pathParts.length - 1]];
}

function _sanitizeInPlace(target) {
    if (!target || typeof target !== "object" || Array.isArray(target))
        return target;

    for (var key in EXCLUDED_TOP_LEVEL_KEYS) {
        if (EXCLUDED_TOP_LEVEL_KEYS[key])
            delete target[key];
    }

    for (var i = 0; i < EXCLUDED_PATHS.length; ++i)
        _deletePath(target, EXCLUDED_PATHS[i]);

    return target;
}

function sanitizePresetData(data) {
    return _sanitizeInPlace(deepClone(data || {}));
}

function _mergeObjects(baseValue, overrideValue) {
    if (overrideValue === undefined)
        return baseValue;
    if (overrideValue === null)
        return null;
    if (Array.isArray(overrideValue))
        return deepClone(overrideValue);
    if (typeof overrideValue !== "object")
        return overrideValue;
    if (!baseValue || typeof baseValue !== "object" || Array.isArray(baseValue))
        return deepClone(overrideValue);

    var merged = deepClone(baseValue);
    for (var key in overrideValue)
        merged[key] = _mergeObjects(merged[key], overrideValue[key]);
    return merged;
}

function mergePresetData(currentData, presetData) {
    var base = deepClone(currentData || {});
    var preset = sanitizePresetData(presetData || {});
    return _mergeObjects(base, preset);
}

// ── Built-in presets ─────────────────────────────────────────────
// Each adjusts radiusScale, spacingScale, uiDensityScale, animationSpeedScale,
// and glassOpacity to create distinct shell personalities.

var BUILTIN_PRESETS = [
    {
        id: "compact",
        name: "Compact",
        description: "Tight spacing, small radii — maximizes screen real estate.",
        icon: "minimize.svg",
        data: {
            appearance: {
                radiusScale: 0.6,
                spacingScale: 0.8,
                uiDensityScale: 0.85,
                animationSpeedScale: 0.85
            },
            glass: { opacityBase: 0.9, opacitySurface: 0.95 }
        }
    },
    {
        id: "rounded",
        name: "Rounded",
        description: "Large radii, relaxed spacing — soft and approachable.",
        icon: "circle.svg",
        data: {
            appearance: {
                radiusScale: 1.6,
                spacingScale: 1.15,
                uiDensityScale: 1.1,
                animationSpeedScale: 1.0
            },
            glass: { opacityBase: 0.82, opacitySurface: 0.92 }
        }
    },
    {
        id: "minimal",
        name: "Minimal",
        description: "Flat, fast, no-nonsense — focus on content.",
        icon: "subtract.svg",
        data: {
            appearance: {
                radiusScale: 0.3,
                spacingScale: 0.9,
                uiDensityScale: 0.95,
                animationSpeedScale: 0.5
            },
            glass: { opacityBase: 0.95, opacitySurface: 0.98 }
        }
    },
    {
        id: "vibrant",
        name: "Vibrant",
        description: "Saturated, bouncy animations — expressive and lively.",
        icon: "color-palette.svg",
        data: {
            appearance: {
                radiusScale: 1.2,
                spacingScale: 1.05,
                uiDensityScale: 1.0,
                animationSpeedScale: 1.4
            },
            glass: { opacityBase: 0.75, opacitySurface: 0.88 }
        }
    },
    {
        id: "calm",
        name: "Calm",
        description: "Slow animations, gentle opacity — easy on the eyes.",
        icon: "weather-moon.svg",
        data: {
            appearance: {
                radiusScale: 1.1,
                spacingScale: 1.1,
                uiDensityScale: 1.05,
                animationSpeedScale: 0.7
            },
            glass: { opacityBase: 0.88, opacitySurface: 0.95 }
        }
    }
];

function builtinPresets() {
    return BUILTIN_PRESETS;
}

function findBuiltinPreset(id) {
    for (var i = 0; i < BUILTIN_PRESETS.length; i++) {
        if (BUILTIN_PRESETS[i].id === id)
            return BUILTIN_PRESETS[i];
    }
    return null;
}
