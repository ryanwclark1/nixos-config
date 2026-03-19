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
