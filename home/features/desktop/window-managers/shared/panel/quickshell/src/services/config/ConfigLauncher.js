.pragma library

function toInt(value, fallback) {
    var n = parseInt(value, 10);
    return isNaN(n) ? fallback : n;
}

function toReal(value, fallback) {
    var n = Number(value);
    return isNaN(n) ? fallback : n;
}

function clampInt(value, min, max, fallback) {
    var n = toInt(value, fallback);
    if (n < min)
        return min;
    if (n > max)
        return max;
    return n;
}

function clampReal(value, min, max, fallback) {
    var n = toReal(value, fallback);
    if (n < min)
        return min;
    if (n > max)
        return max;
    return n;
}

function asBool(value, fallback) {
    if (value === true || value === false)
        return value;
    if (value === "true")
        return true;
    if (value === "false")
        return false;
    return fallback;
}

function normalizeModeList(list, fallbackList) {
    var allowed = {
        "drun": true,
        "window": true,
        "files": true,
        "ai": true,
        "clip": true,
        "emoji": true,
        "calc": true,
        "web": true,
        "plugins": true,
        "run": true,
        "system": true,
        "keybinds": true,
        "media": true,
        "nixos": true,
        "wallpapers": true,
        "bookmarks": true
    };
    var source = Array.isArray(list) ? list : fallbackList;
    var out = [];
    var seen = {};
    for (var i = 0; i < source.length; ++i) {
        var mode = String(source[i] || "");
        if (!allowed[mode] || seen[mode])
            continue;
        out.push(mode);
        seen[mode] = true;
    }
    if (out.length === 0)
        return fallbackList.slice();
    return out;
}

function normalizeWebProviderOrder(list, fallbackList) {
    var allowed = {
        "duckduckgo": true,
        "google": true,
        "youtube": true,
        "nixos": true,
        "github": true
    };
    var source = Array.isArray(list) ? list : fallbackList;
    var out = [];
    var seen = {};
    for (var i = 0; i < source.length; ++i) {
        var provider = String(source[i] || "");
        if (!allowed[provider] || seen[provider])
            continue;
        out.push(provider);
        seen[provider] = true;
    }
    if (out.length === 0)
        return fallbackList.slice();
    return out;
}

function normalizeWebAliases(map, fallbackMap) {
    var allowed = ["duckduckgo", "google", "youtube", "nixos", "github"];
    var source = (map && typeof map === "object") ? map : {};
    var out = ({});
    var globalSeen = ({});
    var i;

    function addToken(token, seen, bucket, providerKey) {
        var normalized = String(token || "").trim().toLowerCase();
        if (normalized === "")
            return;
        if (!/^[a-z0-9][a-z0-9_-]{0,15}$/.test(normalized))
            return;
        if (seen[normalized] || globalSeen[normalized])
            return;
        if (normalized === providerKey)
            return;
        seen[normalized] = true;
        globalSeen[normalized] = true;
        bucket.push(normalized);
    }

    for (i = 0; i < allowed.length; ++i) {
        var provider = allowed[i];
        var raw = source[provider];
        var defaults = Array.isArray(fallbackMap[provider]) ? fallbackMap[provider] : [];
        var tokens = [];
        var seen = ({});
        var j;

        if (Array.isArray(raw)) {
            for (j = 0; j < raw.length; ++j)
                addToken(raw[j], seen, tokens, provider);
        } else if (typeof raw === "string") {
            var parts = raw.split(/[\s,]+/);
            for (j = 0; j < parts.length; ++j)
                addToken(parts[j], seen, tokens, provider);
        }

        if (tokens.length === 0) {
            for (j = 0; j < defaults.length; ++j)
                addToken(defaults[j], seen, tokens, provider);
        }

        out[provider] = tokens;
    }

    return out;
}

function applyLauncherConfig(config, data) {
    var launcher = data && data.launcher ? data.launcher : {};
    var fallbackModes = ["drun", "window", "files", "ai", "clip", "emoji", "calc", "web", "plugins", "run", "system", "keybinds", "media", "nixos", "wallpapers", "bookmarks"];
    var fallbackWebProviders = ["duckduckgo", "google", "youtube", "nixos", "github"];

    config.launcherModeOrder = normalizeModeList(launcher.modeOrder, fallbackModes);
    config.launcherEnabledModes = normalizeModeList(launcher.enabledModes, fallbackModes);
    config.launcherDefaultMode = config.launcherEnabledModes.indexOf(String(launcher.defaultMode || "")) !== -1 ? launcher.defaultMode : "drun";
    if (config.launcherEnabledModes.indexOf(config.launcherDefaultMode) === -1)
        config.launcherDefaultMode = config.launcherEnabledModes[0] || "drun";

    config.launcherShowModeHints = asBool(launcher.showModeHints, true);
    config.launcherShowHomeSections = asBool(launcher.showHomeSections, false);
    config.launcherDrunCategoryFiltersEnabled = asBool(launcher.drunCategoryFiltersEnabled, false);
    config.launcherEnablePreload = asBool(launcher.enablePreload, true);
    config.launcherKeepSearchOnModeSwitch = asBool(launcher.keepSearchOnModeSwitch, true);
    config.launcherEnableDebugTimings = asBool(launcher.enableDebugTimings, false);
    config.launcherShowRuntimeMetrics = asBool(launcher.showRuntimeMetrics, false);
    config.launcherPreloadFailureThreshold = clampInt(launcher.preloadFailureThreshold, 1, 10, 3);
    config.launcherPreloadFailureBackoffSec = clampInt(launcher.preloadFailureBackoffSec, 10, 900, 120);

    config.launcherMaxResults = clampInt(launcher.maxResults, 20, 400, 80);
    config.launcherFileMinQueryLength = clampInt(launcher.fileMinQueryLength, 1, 8, 2);
    config.launcherFileMaxResults = clampInt(launcher.fileMaxResults, 20, 500, 100);
    config.launcherRecentsLimit = clampInt(launcher.recentsLimit, 1, 40, 12);
    config.launcherRecentAppsLimit = clampInt(launcher.recentAppsLimit, 1, 20, 6);
    config.launcherSuggestionsLimit = clampInt(launcher.suggestionsLimit, 1, 20, 4);
    config.launcherCacheTtlSec = clampInt(launcher.cacheTtlSec, 10, 3600, 300);
    config.launcherSearchDebounceMs = clampInt(launcher.searchDebounceMs, 0, 250, 35);
    config.launcherFileSearchDebounceMs = clampInt(launcher.fileSearchDebounceMs, 50, 1200, 140);
    var tabBehavior = String(launcher.tabBehavior || "contextual");
    config.launcherTabBehavior = ["contextual", "results", "mode"].indexOf(tabBehavior) !== -1 ? tabBehavior : "contextual";
    config.launcherWebEnterUsesPrimary = asBool(launcher.webEnterUsesPrimary, true);
    config.launcherWebNumberHotkeysEnabled = asBool(launcher.webNumberHotkeysEnabled, true);
    config.launcherWebAliases = normalizeWebAliases(launcher.webAliases, {
        "duckduckgo": ["d", "ddg"],
        "google": ["g"],
        "youtube": ["yt"],
        "nixos": ["nix", "np"],
        "github": ["gh"]
    });
    config.launcherWebProviderOrder = normalizeWebProviderOrder(launcher.webProviderOrder, fallbackWebProviders);
    config.launcherRememberWebProvider = asBool(launcher.rememberWebProvider, true);
    config.launcherWebLastProviderKey = String(launcher.webLastProviderKey || "duckduckgo");
    if (config.launcherWebProviderOrder.indexOf(config.launcherWebLastProviderKey) === -1)
        config.launcherWebLastProviderKey = config.launcherWebProviderOrder[0] || "duckduckgo";

    config.launcherScoreNameWeight = clampReal(launcher.scoreNameWeight, 0.1, 4.0, 1.0);
    config.launcherScoreTitleWeight = clampReal(launcher.scoreTitleWeight, 0.1, 4.0, 0.92);
    config.launcherScoreExecWeight = clampReal(launcher.scoreExecWeight, 0.1, 4.0, 0.88);
    config.launcherScoreBodyWeight = clampReal(launcher.scoreBodyWeight, 0.1, 4.0, 0.75);
    config.launcherScoreCategoryWeight = clampReal(launcher.scoreCategoryWeight, 0.1, 4.0, 0.7);
}
