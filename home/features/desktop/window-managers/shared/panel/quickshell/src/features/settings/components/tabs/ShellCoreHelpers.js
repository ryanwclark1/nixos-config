.pragma library

// ---------------------------------------------------------------------------
// Web alias helpers
// ---------------------------------------------------------------------------

function defaultWebAliasesCopy(webAliasDefaults) {
    return JSON.parse(JSON.stringify(webAliasDefaults));
}

function webProviderMeta(webProviders, providerKey) {
    for (var i = 0; i < webProviders.length; ++i) {
        if (webProviders[i].key === providerKey)
            return webProviders[i];
    }
    return {
        key: providerKey,
        label: providerKey,
        icon: "󰖟"
    };
}

function parseAliasTokens(text, providerKey) {
    var value = String(text || "").toLowerCase();
    var raw = value.split(/[\s,]+/);
    var out = [];
    var seen = {};
    for (var i = 0; i < raw.length; ++i) {
        var token = String(raw[i] || "").trim();
        if (token === "" || token === providerKey || seen[token])
            continue;
        if (!/^[a-z0-9][a-z0-9_-]{0,15}$/.test(token))
            continue;
        out.push(token);
        seen[token] = true;
    }
    return out;
}

function webAliasString(Config, providerKey) {
    var aliases = (Config.launcherWebAliases && typeof Config.launcherWebAliases === "object") ? Config.launcherWebAliases : ({});
    var list = aliases[providerKey];
    if (!Array.isArray(list))
        list = [];
    return list.join(", ");
}

function setWebAliasString(Config, providerKey, textValue) {
    var next = Object.assign({}, (Config.launcherWebAliases && typeof Config.launcherWebAliases === "object") ? Config.launcherWebAliases : ({}));
    next[providerKey] = parseAliasTokens(textValue, providerKey);
    Config.launcherWebAliases = next;
}

// ---------------------------------------------------------------------------
// Launcher mode helpers
// ---------------------------------------------------------------------------

function isLauncherModeSupported(CompositorAdapter, modeKey) {
    if (modeKey === "window" && !CompositorAdapter.supportsWindowListing)
        return false;
    if (modeKey === "keybinds" && !CompositorAdapter.supportsHotkeysListing)
        return false;
    return true;
}

function supportedLauncherModes(launcherModes, CompositorAdapter) {
    var out = [];
    for (var i = 0; i < launcherModes.length; i++) {
        var modeMeta = launcherModes[i];
        if (isLauncherModeSupported(CompositorAdapter, modeMeta.key))
            out.push(modeMeta);
    }
    return out;
}

function supportedLauncherModeKeys(launcherModes, CompositorAdapter) {
    return supportedLauncherModes(launcherModes, CompositorAdapter).map(function (modeMeta) {
        return modeMeta.key;
    });
}

function defaultModeOptions(launcherModes, CompositorAdapter) {
    return supportedLauncherModes(launcherModes, CompositorAdapter).map(function (modeMeta) {
        return {
            value: modeMeta.key,
            label: modeMeta.label
        };
    });
}

function setEnabledModes(Config, CompositorAdapter, launcherModes, nextModes) {
    var allowed = {};
    var i;
    var availableModes = supportedLauncherModeKeys(launcherModes, CompositorAdapter);
    for (i = 0; i < availableModes.length; i++)
        allowed[availableModes[i]] = true;

    var next = [];
    var seen = {};
    for (i = 0; i < nextModes.length; i++) {
        var key = String(nextModes[i] || "");
        if (!allowed[key] || seen[key])
            continue;
        next.push(key);
        seen[key] = true;
    }

    if (next.length === 0)
        next = ["drun"];

    Config.launcherEnabledModes = next;

    var currentOrder = Array.isArray(Config.launcherModeOrder) ? Config.launcherModeOrder : [];
    var newOrder = [];
    var included = {};
    for (i = 0; i < currentOrder.length; i++) {
        var orderedKey = String(currentOrder[i] || "");
        if (next.indexOf(orderedKey) !== -1 && !included[orderedKey]) {
            newOrder.push(orderedKey);
            included[orderedKey] = true;
        }
    }
    for (i = 0; i < next.length; i++) {
        var extra = next[i];
        if (!included[extra]) {
            newOrder.push(extra);
            included[extra] = true;
        }
    }
    Config.launcherModeOrder = newOrder;

    if (next.indexOf(Config.launcherDefaultMode) === -1)
        Config.launcherDefaultMode = next[0];
}

function toggleLauncherMode(Config, CompositorAdapter, launcherModes, modeKey) {
    var current = Array.isArray(Config.launcherEnabledModes) ? Config.launcherEnabledModes.slice() : [];
    var idx = current.indexOf(modeKey);
    if (idx >= 0)
        current.splice(idx, 1);
    else
        current.push(modeKey);
    setEnabledModes(Config, CompositorAdapter, launcherModes, current);
}

function applyModePreset(Config, CompositorAdapter, launcherModes, preset) {
    var presetModes = [];
    if (preset === "minimal")
        presetModes = ["drun", "window", "files", "run", "system", "media"];
    else if (preset === "full")
        presetModes = supportedLauncherModeKeys(launcherModes, CompositorAdapter);
    else
        presetModes = ["drun", "window", "files", "ai", "clip", "system", "media"];

    setEnabledModes(Config, CompositorAdapter, launcherModes, presetModes);
    Config.launcherModeOrder = Array.isArray(Config.launcherEnabledModes) ? Config.launcherEnabledModes.slice() : ["drun"];
}

function launcherModeMeta(launcherModes, modeKey) {
    for (var i = 0; i < launcherModes.length; i++) {
        if (launcherModes[i].key === modeKey)
            return launcherModes[i];
    }
    return {
        key: modeKey,
        label: modeKey,
        icon: "•"
    };
}

function orderedEnabledModes(Config, CompositorAdapter, launcherModes) {
    var enabled = Array.isArray(Config.launcherEnabledModes) ? Config.launcherEnabledModes : [];
    var order = Array.isArray(Config.launcherModeOrder) ? Config.launcherModeOrder : [];
    var out = [];
    var seen = {};
    var i;
    for (i = 0; i < order.length; i++) {
        var modeKey = String(order[i] || "");
        if (!isLauncherModeSupported(CompositorAdapter, modeKey))
            continue;
        if (enabled.indexOf(modeKey) !== -1 && !seen[modeKey]) {
            out.push(modeKey);
            seen[modeKey] = true;
        }
    }
    for (i = 0; i < enabled.length; i++) {
        var extra = String(enabled[i] || "");
        if (!isLauncherModeSupported(CompositorAdapter, extra))
            continue;
        if (!seen[extra]) {
            out.push(extra);
            seen[extra] = true;
        }
    }
    return out;
}

function moveMode(Config, CompositorAdapter, launcherModes, modeKey, delta) {
    var current = orderedEnabledModes(Config, CompositorAdapter, launcherModes);
    var from = current.indexOf(modeKey);
    if (from < 0)
        return;
    var to = Math.max(0, Math.min(current.length - 1, from + delta));
    if (to === from)
        return;
    var moved = current[from];
    current.splice(from, 1);
    current.splice(to, 0, moved);
    Config.launcherModeOrder = current.slice();
}

// root must expose: dragModeKey, dragModeTargetIndex
function clearModeDragState(root) {
    root.dragModeKey = "";
    root.dragModeTargetIndex = -1;
}

// targetIndexFromMappedY is inlined to avoid cross-JS-file imports
function _targetIndexFromMappedY(mappedY, itemExtent, spacing, count) {
    var extent = Math.max(1, Math.round(Number(itemExtent) || 0) + Math.round(Number(spacing) || 0));
    var upperBound = Math.max(0, Number(count) || 0);
    var value = Math.round((Number(mappedY) || 0) / extent);
    if (value < 0)
        return 0;
    if (value > upperBound)
        return upperBound;
    return value;
}

function currentModeDropIndex(cardItem, rowIndex, listItem, Config, CompositorAdapter, launcherModes) {
    if (!cardItem || !listItem)
        return rowIndex;
    var modes = orderedEnabledModes(Config, CompositorAdapter, launcherModes);
    return _targetIndexFromMappedY(cardItem.mapToItem(listItem, 0, cardItem.y).y, cardItem.height, listItem.spacing, modes.length);
}

function moveDraggedMode(Config, CompositorAdapter, launcherModes, root, targetIndex) {
    var current = orderedEnabledModes(Config, CompositorAdapter, launcherModes);
    var from = current.indexOf(root.dragModeKey);
    if (from < 0)
        return false;

    var boundedTarget = Math.max(0, Math.min(current.length, targetIndex));
    if (from < boundedTarget)
        boundedTarget -= 1;
    if (boundedTarget === from) {
        clearModeDragState(root);
        return false;
    }

    var moved = current[from];
    current.splice(from, 1);
    current.splice(boundedTarget, 0, moved);
    Config.launcherModeOrder = current.slice();
    clearModeDragState(root);
    return true;
}

// ---------------------------------------------------------------------------
// Web provider order helpers
// ---------------------------------------------------------------------------

function setWebProviderOrder(Config, webProviders, webProviderDefaultOrder, nextOrder) {
    var allowed = {};
    var i;
    for (i = 0; i < webProviders.length; i++)
        allowed[webProviders[i].key] = true;

    var out = [];
    var seen = {};
    for (i = 0; i < nextOrder.length; i++) {
        var key = String(nextOrder[i] || "");
        if (!allowed[key] || seen[key])
            continue;
        out.push(key);
        seen[key] = true;
    }
    if (out.length === 0)
        out = webProviderDefaultOrder.slice();
    Config.launcherWebProviderOrder = out;
}

function orderedWebProviders(Config, webProviders, webProviderDefaultOrder) {
    var order = Array.isArray(Config.launcherWebProviderOrder) ? Config.launcherWebProviderOrder : [];
    var out = [];
    var seen = {};
    var i;
    for (i = 0; i < order.length; i++) {
        var key = String(order[i] || "");
        if (seen[key])
            continue;
        for (var j = 0; j < webProviders.length; j++) {
            if (webProviders[j].key === key) {
                out.push(key);
                seen[key] = true;
                break;
            }
        }
    }
    for (i = 0; i < webProviderDefaultOrder.length; i++) {
        var fallbackKey = webProviderDefaultOrder[i];
        if (!seen[fallbackKey]) {
            out.push(fallbackKey);
            seen[fallbackKey] = true;
        }
    }
    return out;
}

function toggleWebProvider(Config, webProviders, webProviderDefaultOrder, providerKey) {
    var current = orderedWebProviders(Config, webProviders, webProviderDefaultOrder);
    var idx = current.indexOf(providerKey);
    if (idx >= 0) {
        if (current.length <= 1)
            return;
        current.splice(idx, 1);
    } else {
        current.push(providerKey);
    }
    setWebProviderOrder(Config, webProviders, webProviderDefaultOrder, current);
}

function moveWebProvider(Config, webProviders, webProviderDefaultOrder, providerKey, delta) {
    var current = orderedWebProviders(Config, webProviders, webProviderDefaultOrder);
    var from = current.indexOf(providerKey);
    if (from < 0)
        return;
    var to = Math.max(0, Math.min(current.length - 1, from + delta));
    if (to === from)
        return;
    var moved = current[from];
    current.splice(from, 1);
    current.splice(to, 0, moved);
    setWebProviderOrder(Config, webProviders, webProviderDefaultOrder, current);
}

// root must expose: dragWebProviderKey, dragWebProviderTargetIndex
function clearWebProviderDragState(root) {
    root.dragWebProviderKey = "";
    root.dragWebProviderTargetIndex = -1;
}

function currentWebProviderDropIndex(cardItem, rowIndex, listItem, Config, webProviders, webProviderDefaultOrder) {
    if (!cardItem || !listItem)
        return rowIndex;
    var providers = orderedWebProviders(Config, webProviders, webProviderDefaultOrder);
    return _targetIndexFromMappedY(cardItem.mapToItem(listItem, 0, cardItem.y).y, cardItem.height, listItem.spacing, providers.length);
}

function moveDraggedWebProvider(Config, webProviders, webProviderDefaultOrder, root, targetIndex) {
    var current = orderedWebProviders(Config, webProviders, webProviderDefaultOrder);
    var from = current.indexOf(root.dragWebProviderKey);
    if (from < 0)
        return false;

    var boundedTarget = Math.max(0, Math.min(current.length, targetIndex));
    if (from < boundedTarget)
        boundedTarget -= 1;
    if (boundedTarget === from) {
        clearWebProviderDragState(root);
        return false;
    }

    var moved = current[from];
    current.splice(from, 1);
    current.splice(boundedTarget, 0, moved);
    setWebProviderOrder(Config, webProviders, webProviderDefaultOrder, current);
    clearWebProviderDragState(root);
    return true;
}

// ---------------------------------------------------------------------------
// Control Center helpers
// ---------------------------------------------------------------------------

function orderedControlCenterToggles(ControlCenterRegistry) {
    return ControlCenterRegistry.orderedQuickToggleItems();
}

function orderedControlCenterPlugins(PluginService) {
    return PluginService.visibleControlCenterPlugins.slice();
}

function moveOrderedValue(Config, ControlCenterRegistry, PluginService, configKey, value, delta) {
    var current = [];
    if (configKey === "controlCenterToggleOrder")
        current = orderedControlCenterToggles(ControlCenterRegistry).map(function (item) {
            return item.id;
        });
    else if (configKey === "controlCenterPluginOrder")
        current = orderedControlCenterPlugins(PluginService).map(function (item) {
            return item.id;
        });

    var from = current.indexOf(value);
    if (from < 0)
        return;
    var to = Math.max(0, Math.min(current.length - 1, from + delta));
    if (to === from)
        return;

    current.splice(from, 1);
    current.splice(to, 0, value);
    Config[configKey] = current.slice();
}

function toggleHiddenListValue(Config, configKey, value) {
    var next = Array.isArray(Config[configKey]) ? Config[configKey].slice() : [];
    var idx = next.indexOf(value);
    if (idx >= 0)
        next.splice(idx, 1);
    else
        next.push(value);
    Config[configKey] = next;
}

// ---------------------------------------------------------------------------
// Full launcher defaults reset
// ---------------------------------------------------------------------------

function resetLauncherDefaults(Config, webAliasDefaults, webProviderDefaultOrder, launcherDefaultModes, CompositorAdapter, launcherModes) {
    Config.launcherDefaultMode = "drun";
    Config.launcherShowModeHints = true;
    Config.launcherShowHomeSections = false;
    Config.launcherDrunCategoryFiltersEnabled = false;
    Config.launcherEnablePreload = true;
    Config.launcherKeepSearchOnModeSwitch = true;
    Config.launcherEnableDebugTimings = false;
    Config.launcherShowRuntimeMetrics = false;
    Config.launcherPreloadFailureThreshold = 3;
    Config.launcherPreloadFailureBackoffSec = 120;
    Config.launcherMaxResults = 80;
    Config.launcherFileMinQueryLength = 2;
    Config.launcherFileMaxResults = 100;
    Config.launcherRecentsLimit = 12;
    Config.launcherRecentAppsLimit = 6;
    Config.launcherSuggestionsLimit = 4;
    Config.launcherCacheTtlSec = 300;
    Config.launcherSearchDebounceMs = 35;
    Config.launcherFileSearchDebounceMs = 140;
    Config.launcherTabBehavior = "contextual";
    Config.launcherWebEnterUsesPrimary = true;
    Config.launcherWebNumberHotkeysEnabled = true;
    Config.launcherWebAliases = defaultWebAliasesCopy(webAliasDefaults);
    Config.launcherRememberWebProvider = true;
    Config.launcherWebLastProviderKey = "duckduckgo";
    Config.launcherWebProviderOrder = webProviderDefaultOrder.slice();
    var supportedDefaults = launcherDefaultModes.filter(function (modeKey) {
        return isLauncherModeSupported(CompositorAdapter, modeKey);
    });
    if (supportedDefaults.length === 0)
        supportedDefaults = ["drun"];
    Config.launcherEnabledModes = supportedDefaults.slice();
    Config.launcherModeOrder = supportedDefaults.slice();
    Config.launcherScoreNameWeight = 1.0;
    Config.launcherScoreTitleWeight = 0.92;
    Config.launcherScoreExecWeight = 0.88;
    Config.launcherScoreBodyWeight = 0.75;
    Config.launcherScoreCategoryWeight = 0.7;
}
