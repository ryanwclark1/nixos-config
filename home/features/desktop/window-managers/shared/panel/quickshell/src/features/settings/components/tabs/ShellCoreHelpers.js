.pragma library
.import "../SettingsReorderHelpers.js" as SettingsReorderHelpers

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
        icon: "globe-search.svg"
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

var _launcherPrimaryDefaults = ["drun", "window", "files", "ai", "system"];

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
            label: modeMeta.label,
            icon: modeMeta.icon || ""
        };
    });
}

function defaultPrimaryModes(launcherModes, CompositorAdapter) {
    var supported = supportedLauncherModeKeys(launcherModes, CompositorAdapter);
    var out = [];
    for (var i = 0; i < _launcherPrimaryDefaults.length; ++i) {
        if (supported.indexOf(_launcherPrimaryDefaults[i]) !== -1)
            out.push(_launcherPrimaryDefaults[i]);
    }
    if (out.length === 0)
        out = supported.length > 0 ? [supported[0]] : ["drun"];
    return out;
}

function normalizePrimaryModes(Config, CompositorAdapter, launcherModes, nextModes) {
    var enabled = Array.isArray(Config.launcherEnabledModes) ? Config.launcherEnabledModes.slice() : [];
    var source = Array.isArray(nextModes) ? nextModes : defaultPrimaryModes(launcherModes, CompositorAdapter);
    var out = [];
    var seen = {};
    for (var i = 0; i < source.length; ++i) {
        var key = String(source[i] || "");
        if (enabled.indexOf(key) === -1 || !isLauncherModeSupported(CompositorAdapter, key) || seen[key])
            continue;
        out.push(key);
        seen[key] = true;
    }
    if (out.length === 0 && enabled.length > 0)
        out.push(enabled[0]);
    return out;
}

function setPrimaryModes(Config, CompositorAdapter, launcherModes, nextModes) {
    Config.launcherPrimaryModes = normalizePrimaryModes(Config, CompositorAdapter, launcherModes, nextModes);
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
    Config.launcherPrimaryModes = normalizePrimaryModes(Config, CompositorAdapter, launcherModes, Config.launcherPrimaryModes);

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
    if (preset === "all" || preset === "full")
        presetModes = supportedLauncherModeKeys(launcherModes, CompositorAdapter);
    else if (preset === "extended" || preset === "core")
        presetModes = ["drun", "window", "files", "ai", "system", "settings", "run", "ssh", "web"];
    else
        presetModes = ["drun", "window", "files", "ai", "system"];

    setEnabledModes(Config, CompositorAdapter, launcherModes, presetModes);
    Config.launcherModeOrder = Array.isArray(Config.launcherEnabledModes) ? Config.launcherEnabledModes.slice() : ["drun"];
    Config.launcherPrimaryModes = normalizePrimaryModes(Config, CompositorAdapter, launcherModes, defaultPrimaryModes(launcherModes, CompositorAdapter));
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

function orderedPrimaryModes(Config, CompositorAdapter, launcherModes) {
    var enabledOrder = orderedEnabledModes(Config, CompositorAdapter, launcherModes);
    var primary = Array.isArray(Config.launcherPrimaryModes) ? Config.launcherPrimaryModes : [];
    var out = [];
    for (var i = 0; i < primary.length; ++i) {
        var key = String(primary[i] || "");
        if (enabledOrder.indexOf(key) !== -1 && out.indexOf(key) === -1)
            out.push(key);
    }
    if (out.length === 0 && enabledOrder.length > 0)
        out.push(enabledOrder[0]);
    return out;
}

function orderedAdvancedModes(Config, CompositorAdapter, launcherModes) {
    var enabledOrder = orderedEnabledModes(Config, CompositorAdapter, launcherModes);
    var primary = orderedPrimaryModes(Config, CompositorAdapter, launcherModes);
    return enabledOrder.filter(function(modeKey) {
        return primary.indexOf(modeKey) === -1;
    });
}

function disabledLauncherModes(Config, CompositorAdapter, launcherModes) {
    var enabled = orderedEnabledModes(Config, CompositorAdapter, launcherModes);
    return supportedLauncherModes(launcherModes, CompositorAdapter).filter(function(modeMeta) {
        return enabled.indexOf(modeMeta.key) === -1;
    }).map(function(modeMeta) {
        return modeMeta.key;
    });
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

function movePrimaryMode(Config, CompositorAdapter, launcherModes, modeKey, delta) {
    var current = orderedPrimaryModes(Config, CompositorAdapter, launcherModes);
    var from = current.indexOf(modeKey);
    if (from < 0)
        return;
    var to = Math.max(0, Math.min(current.length - 1, from + delta));
    if (to === from)
        return;
    var moved = current[from];
    current.splice(from, 1);
    current.splice(to, 0, moved);
    setPrimaryModes(Config, CompositorAdapter, launcherModes, current);
    Config.launcherModeOrder = orderedPrimaryModes(Config, CompositorAdapter, launcherModes).concat(
        orderedAdvancedModes(Config, CompositorAdapter, launcherModes)
    );
}

function moveDraggedPrimaryMode(Config, CompositorAdapter, launcherModes, state, targetIndex) {
    var current = orderedPrimaryModes(Config, CompositorAdapter, launcherModes);
    var result = SettingsReorderHelpers.moveValueToTarget(current, String(state && state.sourceItemId || ""), targetIndex);
    clearModeDragState(state);
    if (!result.changed)
        return false;
    setPrimaryModes(Config, CompositorAdapter, launcherModes, result.items);
    Config.launcherModeOrder = orderedPrimaryModes(Config, CompositorAdapter, launcherModes).concat(
        orderedAdvancedModes(Config, CompositorAdapter, launcherModes)
    );
    return true;
}

function moveAdvancedMode(Config, CompositorAdapter, launcherModes, modeKey, delta) {
    var advanced = orderedAdvancedModes(Config, CompositorAdapter, launcherModes);
    var from = advanced.indexOf(modeKey);
    if (from < 0)
        return;
    var to = Math.max(0, Math.min(advanced.length - 1, from + delta));
    if (to === from)
        return;
    var moved = advanced[from];
    advanced.splice(from, 1);
    advanced.splice(to, 0, moved);
    Config.launcherModeOrder = orderedPrimaryModes(Config, CompositorAdapter, launcherModes).concat(advanced);
}

function moveDraggedAdvancedMode(Config, CompositorAdapter, launcherModes, state, targetIndex) {
    var advanced = orderedAdvancedModes(Config, CompositorAdapter, launcherModes);
    var result = SettingsReorderHelpers.moveValueToTarget(advanced, String(state && state.sourceItemId || ""), targetIndex);
    clearModeDragState(state);
    if (!result.changed)
        return false;
    Config.launcherModeOrder = orderedPrimaryModes(Config, CompositorAdapter, launcherModes).concat(result.items);
    return true;
}

function promoteLauncherMode(Config, CompositorAdapter, launcherModes, modeKey) {
    var enabled = orderedEnabledModes(Config, CompositorAdapter, launcherModes);
    if (enabled.indexOf(modeKey) === -1)
        enabled.push(modeKey);
    setEnabledModes(Config, CompositorAdapter, launcherModes, enabled);
    var primary = orderedPrimaryModes(Config, CompositorAdapter, launcherModes);
    if (primary.indexOf(modeKey) === -1)
        primary.push(modeKey);
    setPrimaryModes(Config, CompositorAdapter, launcherModes, primary);
    Config.launcherModeOrder = orderedPrimaryModes(Config, CompositorAdapter, launcherModes).concat(
        orderedAdvancedModes(Config, CompositorAdapter, launcherModes)
    );
}

function enableLauncherMode(Config, CompositorAdapter, launcherModes, modeKey, asPrimary) {
    var enabled = orderedEnabledModes(Config, CompositorAdapter, launcherModes);
    if (enabled.indexOf(modeKey) === -1)
        enabled.push(modeKey);
    setEnabledModes(Config, CompositorAdapter, launcherModes, enabled);
    if (asPrimary)
        promoteLauncherMode(Config, CompositorAdapter, launcherModes, modeKey);
}

function demoteLauncherMode(Config, CompositorAdapter, launcherModes, modeKey) {
    var primary = orderedPrimaryModes(Config, CompositorAdapter, launcherModes).filter(function(key) {
        return key !== modeKey;
    });
    setPrimaryModes(Config, CompositorAdapter, launcherModes, primary);
    Config.launcherModeOrder = orderedPrimaryModes(Config, CompositorAdapter, launcherModes).concat(
        orderedAdvancedModes(Config, CompositorAdapter, launcherModes)
    );
}

function disableLauncherMode(Config, CompositorAdapter, launcherModes, modeKey) {
    var enabled = orderedEnabledModes(Config, CompositorAdapter, launcherModes).filter(function(key) {
        return key !== modeKey;
    });
    setEnabledModes(Config, CompositorAdapter, launcherModes, enabled);
}

function clearModeDragState(state) {
    SettingsReorderHelpers.clearState(state);
}

function _targetIndexFromMappedY(mappedY, itemExtent, spacing, count) {
    return SettingsReorderHelpers.targetIndexFromMappedY(mappedY, itemExtent, spacing, count);
}

function currentModeDropIndex(cardItem, rowIndex, listItem, count, dragOffsetY) {
    return SettingsReorderHelpers.currentListDropIndex(cardItem, rowIndex, listItem, count, dragOffsetY);
}

function moveDraggedMode(Config, CompositorAdapter, launcherModes, state, targetIndex) {
    var current = orderedEnabledModes(Config, CompositorAdapter, launcherModes);
    var result = SettingsReorderHelpers.moveValueToTarget(current, String(state && state.sourceItemId || ""), targetIndex);
    clearModeDragState(state);
    if (!result.changed)
        return false;
    Config.launcherModeOrder = result.items.slice();
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

function clearWebProviderDragState(state) {
    SettingsReorderHelpers.clearState(state);
}

function currentWebProviderDropIndex(cardItem, rowIndex, listItem, Config, webProviders, webProviderDefaultOrder, dragOffsetY) {
    if (!cardItem || !listItem)
        return rowIndex;
    var providers = orderedWebProviders(Config, webProviders, webProviderDefaultOrder);
    return SettingsReorderHelpers.currentListDropIndex(cardItem, rowIndex, listItem, providers.length, dragOffsetY);
}

function moveDraggedWebProvider(Config, webProviders, webProviderDefaultOrder, state, targetIndex) {
    var current = orderedWebProviders(Config, webProviders, webProviderDefaultOrder);
    var result = SettingsReorderHelpers.moveValueToTarget(current, String(state && state.sourceItemId || ""), targetIndex);
    clearWebProviderDragState(state);
    if (!result.changed)
        return false;
    setWebProviderOrder(Config, webProviders, webProviderDefaultOrder, result.items);
    return true;
}

// ---------------------------------------------------------------------------
// Control Center helpers
// ---------------------------------------------------------------------------

function orderedControlCenterToggles(ControlCenterRegistry, Config) {
    var order = Config && Array.isArray(Config.controlCenterToggleOrder) ? Config.controlCenterToggleOrder : [];
    return SettingsReorderHelpers.orderCatalogItems(ControlCenterRegistry ? ControlCenterRegistry.quickToggleItems : [], order, function(item) {
        return String(item && item.id || "");
    });
}

function orderedControlCenterPlugins(PluginService, Config) {
    var order = Config && Array.isArray(Config.controlCenterPluginOrder) ? Config.controlCenterPluginOrder : [];
    return SettingsReorderHelpers.orderCatalogItems(PluginService ? PluginService.controlCenterPlugins : [], order, function(item) {
        return String(item && item.id || "");
    });
}

function moveOrderedValue(Config, ControlCenterRegistry, PluginService, configKey, value, delta) {
    var current = [];
    if (configKey === "controlCenterToggleOrder")
        current = orderedControlCenterToggles(ControlCenterRegistry, Config).map(function (item) {
            return item.id;
        });
    else if (configKey === "controlCenterPluginOrder")
        current = orderedControlCenterPlugins(PluginService, Config).map(function (item) {
            return item.id;
        });

    var result = SettingsReorderHelpers.moveValueByDelta(current, value, delta);
    if (!result.changed)
        return;
    Config[configKey] = result.items.slice();
}

function moveDraggedOrderedValue(Config, ControlCenterRegistry, PluginService, configKey, state, targetIndex) {
    var current = [];
    if (configKey === "controlCenterToggleOrder")
        current = orderedControlCenterToggles(ControlCenterRegistry, Config).map(function(item) {
            return item.id;
        });
    else if (configKey === "controlCenterPluginOrder")
        current = orderedControlCenterPlugins(PluginService, Config).map(function(item) {
            return item.id;
        });

    var result = SettingsReorderHelpers.moveValueToTarget(current, String(state && state.sourceItemId || ""), targetIndex);
    SettingsReorderHelpers.clearState(state);
    if (!result.changed)
        return false;
    Config[configKey] = result.items.slice();
    return true;
}

function currentOrderedDropIndex(cardItem, rowIndex, listItem, count, dragOffsetY) {
    return SettingsReorderHelpers.currentListDropIndex(cardItem, rowIndex, listItem, count, dragOffsetY);
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
    Config.launcherCharacterTrigger = ":";
    Config.launcherCharacterPasteOnSelect = false;
    Config.launcherEnablePreload = true;
    Config.launcherKeepSearchOnModeSwitch = true;
    Config.launcherEnableDebugTimings = false;
    Config.launcherShowRuntimeMetrics = false;
    Config.launcherPreloadFailureThreshold = 3;
    Config.launcherPreloadFailureBackoffSec = 120;
    Config.launcherMaxResults = 80;
    Config.launcherFileMinQueryLength = 1;
    Config.launcherFileMaxResults = 100;
    Config.launcherFileSearchRoot = "~";
    Config.launcherFileShowHidden = false;
    Config.launcherFileOpener = "xdg-open";
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
    Config.launcherWebCustomEngines = [];
    Config.launcherWebBangsEnabled = false;
    Config.launcherWebBangsLastSync = "";
    var supportedDefaults = launcherDefaultModes.filter(function (modeKey) {
        return isLauncherModeSupported(CompositorAdapter, modeKey);
    });
    if (supportedDefaults.length === 0)
        supportedDefaults = ["drun"];
    Config.launcherEnabledModes = supportedDefaults.slice();
    Config.launcherModeOrder = supportedDefaults.slice();
    Config.launcherPrimaryModes = defaultPrimaryModes(launcherModes, CompositorAdapter);
    Config.launcherScoreNameWeight = 1.0;
    Config.launcherScoreTitleWeight = 0.92;
    Config.launcherScoreExecWeight = 0.88;
    Config.launcherScoreBodyWeight = 0.75;
    Config.launcherScoreCategoryWeight = 0.7;
}
