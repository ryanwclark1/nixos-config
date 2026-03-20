import QtQuick
import "../services"
import "LauncherModeData.js" as ModeData
import "LauncherSearch.js" as Search
import "LauncherMetrics.js" as Metrics
import "LauncherCategoryHelpers.js" as CategoryHelpers
import "LauncherTextHelpers.js" as TextHelpers
import "LauncherWebProviders.js" as WebProviders

QtObject {
    id: controller

    // ── Core state ─────────────────────────────
    property string searchText: ""
    property var allItems: []
    property var filteredItems: []
    property int selectedIndex: 0
    property string mode: "drun"

    property string confirmTitle: ""
    property var confirmCallback: null
    readonly property bool showingConfirm: confirmTitle !== ""

    property var recentItems: []
    property var suggestionItems: []
    property string drunCategoryFilter: ""
    property bool drunCategorySectionExpanded: false
    property var drunCategoryOptions: [{ key: "", label: "All", count: 0, hotkey: "0" }]
    property string _sessionWebProviderKey: ""

    // ── Mode load state ────────────────────────
    property string modeLoadState: "idle"
    property string modeLoadMessage: ""
    property string modeLoadTarget: ""
    readonly property bool isModeLoading: modeLoadState === "loading"

    function setModeLoadState(nextState, targetMode, message) {
        modeLoadState = String(nextState || "idle");
        modeLoadTarget = String(targetMode || mode || "");
        modeLoadMessage = String(message || "");
    }

    function beginModeLoad(targetMode, message) {
        setModeLoadState("loading", targetMode, message);
    }

    function completeModeLoad(targetMode, success, message) {
        var target = String(targetMode || "");
        if (target !== "" && target !== mode)
            return;
        setModeLoadState(success ? "ready" : "error", targetMode, message);
    }

    // ── Mode metadata ──────────────────────────
    readonly property var allKnownModes: ModeData.allKnownModes
    readonly property var transientModes: ModeData.transientModes
    readonly property var defaultModeOrder: ModeData.defaultModeOrder
    readonly property var defaultPrimaryModes: ModeData.defaultPrimaryModes
    readonly property var modeIcons: ModeData.modeIcons

    property var modeOrder: computeModeOrder()
    property var primaryModes: ModeData.sanitizeModeList(
        Config.launcherPrimaryModes, defaultPrimaryModes, allKnownModes
    ).filter(function(modeKey) { return controller.modeOrder.indexOf(modeKey) !== -1; })

    readonly property var overflowModes: modeOrder.filter(function(modeKey) {
        return primaryModes.indexOf(modeKey) === -1;
    })

    readonly property var cyclableModes: {
        var ordered = [];
        var seen = ({});
        var source = primaryModes.concat(overflowModes);
        for (var i = 0; i < source.length; ++i) {
            var key = String(source[i] || "");
            if (key === "" || seen[key]) continue;
            ordered.push(key);
            seen[key] = true;
        }
        return ordered.length > 0 ? ordered : modeOrder;
    }

    readonly property var prefixQuickModes: ["settings", "run", "ssh", "web"].filter(function(modeKey) {
        return controller.supportsMode(modeKey);
    })

    readonly property var currentModeMeta: modeMeta(mode)
    readonly property string modeToneKey: String(currentModeMeta.tone || "primary")
    readonly property string modeHeroLabel: String(currentModeMeta.heroLabel || currentModeMeta.label || "Launcher")
    readonly property string modeShortLabel: String(currentModeMeta.shortLabel || currentModeMeta.label || "Launcher")
    readonly property string modeHeroIcon: String(currentModeMeta.heroIcon || modeIcons[mode] || "󰍉")
    readonly property string modePrefixText: String(currentModeMeta.prefix || "")

    function computeModeOrder() {
        var order = ModeData.sanitizeModeList(Config.launcherModeOrder, defaultModeOrder, allKnownModes);
        var enabled = ModeData.sanitizeModeList(Config.launcherEnabledModes, defaultModeOrder, allKnownModes);
        var enabledSet = ({});
        for (var i = 0; i < enabled.length; ++i)
            enabledSet[enabled[i]] = true;
        var filtered = [];
        for (i = 0; i < order.length; ++i) {
            var modeKey = order[i];
            if (enabledSet[modeKey] && isModeAllowedByCompositor(modeKey))
                filtered.push(modeKey);
        }
        return filtered.length === 0 ? ["drun"] : filtered;
    }

    function modeMeta(modeKey) {
        return ModeData.modeInfo(modeKey);
    }

    function toneColor(toneKey) {
        var key = String(toneKey || "primary");
        if (key === "accent") return Colors.accent;
        if (key === "info") return Colors.info;
        if (key === "success") return Colors.success;
        if (key === "warning") return Colors.warning;
        if (key === "secondary") return Colors.secondary;
        return Colors.primary;
    }

    readonly property color modeAccentColor: toneColor(modeToneKey)

    function isModeAllowedByCompositor(modeKey) {
        if (modeKey === "window" && !CompositorAdapter.supportsWindowListing) return false;
        if (modeKey === "keybinds" && !CompositorAdapter.supportsHotkeysListing) return false;
        return true;
    }

    function supportsMode(modeKey) {
        return modeOrder.indexOf(modeKey) !== -1 || transientModes.indexOf(modeKey) !== -1;
    }

    function effectiveDefaultMode() {
        var preferred = String(Config.launcherDefaultMode || "drun");
        if (supportsMode(preferred)) return preferred;
        return modeOrder.length > 0 ? modeOrder[0] : "drun";
    }

    // ── Mode hint ──────────────────────────────
    property string modeHintTitle: ""
    property string modeHintSubtitle: ""
    property string modeHintIcon: ""

    function setModeHint(title, subtitle, iconName) {
        modeHintTitle = title || "";
        modeHintSubtitle = subtitle || "";
        modeHintIcon = iconName || "";
    }

    // ── Caching ────────────────────────────────
    property var modeCache: ({})
    property var modeCacheTime: ({})
    property var fileQueryCache: ({})
    property var fileQueryCacheTime: ({})

    function getCached(modeKey) {
        var items = modeCache[modeKey];
        if (!items) return null;
        var ttlMs = Math.max(1, Config.launcherCacheTtlSec) * 1000;
        var last = modeCacheTime[modeKey] || 0;
        if (Date.now() - last > ttlMs) {
            var nextCache = Object.assign({}, modeCache);
            var nextTimes = Object.assign({}, modeCacheTime);
            delete nextCache[modeKey];
            delete nextTimes[modeKey];
            modeCache = nextCache;
            modeCacheTime = nextTimes;
            return null;
        }
        return items;
    }

    function setCached(modeKey, items) {
        var nextCache = Object.assign({}, modeCache);
        var nextTimes = Object.assign({}, modeCacheTime);
        nextCache[modeKey] = items;
        nextTimes[modeKey] = Date.now();
        modeCache = nextCache;
        modeCacheTime = nextTimes;
    }

    function clearCaches() {
        modeCache = ({});
        modeCacheTime = ({});
        fileQueryCache = ({});
        fileQueryCacheTime = ({});
    }

    function getFileQueryCached(queryKey) {
        var key = String(queryKey || "");
        var cached = fileQueryCache[key];
        if (!cached) return null;
        var stamp = fileQueryCacheTime[key] || 0;
        var age = Date.now() - stamp;
        if (age > 60000) {
            var c = Object.assign({}, fileQueryCache);
            delete c[key];
            fileQueryCache = c;
            return null;
        }
        return cached;
    }

    function setFileQueryCached(queryKey, items) {
        var key = String(queryKey || "");
        var c = Object.assign({}, fileQueryCache);
        c[key] = items;
        fileQueryCache = c;
        var t = Object.assign({}, fileQueryCacheTime);
        t[key] = Date.now();
        fileQueryCacheTime = t;
    }

    // ── Metrics ────────────────────────────────
    property var launcherMetrics: Metrics.freshMetrics()

    function modeMetric(modeKey) { return Metrics.modeMetric(launcherMetrics, modeKey); }
    function clearLauncherMetrics() { launcherMetrics = Metrics.freshMetrics(); }
    function recordFilterMetric(durationMs) { launcherMetrics = Metrics.recordFilterMetric(launcherMetrics, durationMs); }
    function recordLoadMetric(modeKey, durationMs, cacheHit, success) { launcherMetrics = Metrics.recordLoadMetric(launcherMetrics, modeKey, durationMs, cacheHit, success); }
    function recordFilesBackendLoad(backend, durationMs) { launcherMetrics = Metrics.recordFilesBackendLoad(launcherMetrics, backend, durationMs); }
    function recordFilesBackendResolveMetric(durationMs) { launcherMetrics = Metrics.recordFilesBackendResolveMetric(launcherMetrics, durationMs); }

    // ── Filter cache ───────────────────────────
    property string _lastFilterMode: ""
    property string _lastFilterQuery: ""
    property string _lastFilterCategory: ""
    property var _lastFilterCandidates: []

    function resetFilterCache() {
        _lastFilterMode = "";
        _lastFilterQuery = "";
        _lastFilterCategory = "";
        _lastFilterCandidates = [];
    }

    // ── Telemetry ──────────────────────────────
    function telemetryStart() {
        return Date.now();
    }

    function telemetryEnd(label, startedAt) {
        if (!Config.launcherEnableDebugTimings) return;
        var took = Math.max(0, Date.now() - startedAt);
        Logger.d("Launcher", "timing:", label, took + "ms");
    }

    // ── Request tracking ───────────────────────
    property int _requestToken: 0
    property var _activeRequests: ({})

    function beginRequest(modeKey) {
        _requestToken++;
        var key = String(modeKey || "");
        var updated = Object.assign({}, _activeRequests);
        updated[key] = _requestToken;
        _activeRequests = updated;
        return _requestToken;
    }

    function isRequestCurrent(modeKey, token) {
        return _activeRequests[String(modeKey || "")] === token;
    }

    // ── Web provider helpers ───────────────────
    function configuredWebProviders() { return WebProviders.configuredWebProviders(); }
    function primaryWebProvider() { return WebProviders.primaryWebProvider(); }
    function configuredWebProviderByKey(providerKey) { return WebProviders.configuredWebProviderByKey(providerKey); }
    function webAliasToProviderKey(token) { return WebProviders.webAliasToProviderKey(token); }
    function parseWebQuery(text) { return WebProviders.parseWebQuery(text); }
    function secondaryWebProvider() { return WebProviders.secondaryWebProvider(); }
    function preferredWebProviderKey() { return WebProviders.preferredWebProviderKey(_sessionWebProviderKey); }

    // ── Selection helpers ──────────────────────
    readonly property bool hasResults: filteredItems.length > 0
    readonly property var selectedItem: hasResults && selectedIndex >= 0 && selectedIndex < filteredItems.length
        ? filteredItems[selectedIndex] : null

    function cycleSelection(step) {
        if (filteredItems.length === 0) return;
        selectedIndex = ((selectedIndex + step) % filteredItems.length + filteredItems.length) % filteredItems.length;
    }

    function moveSelectionRelative(step) {
        if (filteredItems.length === 0) return;
        var next = selectedIndex + step;
        selectedIndex = Math.max(0, Math.min(filteredItems.length - 1, next));
    }

    function jumpSelectionBoundary(toEnd) {
        if (filteredItems.length === 0) return;
        selectedIndex = toEnd ? filteredItems.length - 1 : 0;
    }

    function pageSelection(step) {
        if (filteredItems.length === 0) return;
        var pageSize = 10;
        var next = selectedIndex + step * pageSize;
        selectedIndex = Math.max(0, Math.min(filteredItems.length - 1, next));
    }

    // ── Confirm dialog ─────────────────────────
    function showConfirm(title, callback) {
        confirmTitle = title;
        confirmCallback = callback;
    }

    function doConfirm() {
        var cb = confirmCallback;
        confirmTitle = "";
        confirmCallback = null;
        if (typeof cb === "function") cb();
    }

    function cancelConfirm() {
        confirmTitle = "";
        confirmCallback = null;
    }

    // ── Drun usage tracking ────────────────────
    property var appFrequency: ({})

    function updateDrunUsageCache(item) {
        if (!item) return;
        var execKey = String(item.exec || "");
        var rawFreq = (appFrequency[execKey] || 0) * 0.3;
        var usageScore = UsageTrackerService.getUsageScore(execKey);
        item._rawFrequencyScore = rawFreq;
        item._usageScore = usageScore;
        item._drunUsageBoost = Math.max(rawFreq, usageScore * 1.5);
    }

    function refreshDrunUsageCaches(items) {
        var source = Array.isArray(items) ? items : [];
        for (var i = 0; i < source.length; ++i)
            updateDrunUsageCache(source[i]);
    }

    function prepareDrunItems(items) {
        var source = Array.isArray(items) ? items : [];
        for (var i = 0; i < source.length; ++i) {
            Search.ensureItemRankCache(source[i]);
            updateDrunUsageCache(source[i]);
        }
        return source;
    }

    // ── Text helpers (delegated) ───────────────
    function cleanSearchTextForMode(modeKey, text) {
        return Search.stripSearchPrefix(modeKey, text);
    }

    readonly property string _cleanSearch: cleanSearchTextForMode(mode, searchText).trim()
    readonly property var _webPrimaryProvider: primaryWebProvider()
    readonly property var _webSecondaryProvider: secondaryWebProvider()
    readonly property string _webPrimaryName: _webPrimaryProvider ? _webPrimaryProvider.name : "Web"
    readonly property string _webSecondaryName: _webSecondaryProvider ? _webSecondaryProvider.name : "Google"
}
