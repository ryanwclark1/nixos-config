.pragma library

function filesBackendStatusObject(props) {
    var metrics = props.launcherMetrics || ({});
    var modeStats = props.modeMetricFn ? props.modeMetricFn("files") : ({});
    var resolveRuns = metrics.filesResolveRuns || 0;
    var resolveAvgMs = metrics.filesResolveAvgMs || 0;
    var resolveLastMs = metrics.filesResolveLastMs || 0;
    var filesFdLoads = metrics.filesFdLoads || 0;
    var filesFindLoads = metrics.filesFindLoads || 0;
    var filesFdAvgMs = metrics.filesFdAvgMs || 0;
    var filesFdLastMs = metrics.filesFdLastMs || 0;
    var filesFindAvgMs = metrics.filesFindAvgMs || 0;
    var filesFindLastMs = metrics.filesFindLastMs || 0;
    var fileCacheHits = modeStats.cacheHits || 0;
    var fileCacheMisses = modeStats.cacheMisses || 0;
    return ({
            backend: props.filesBackendLabel,
            backendRaw: String(props.fileSearchBackend || ""),
            resolvedAt: props.fileSearchBackendResolvedAt,
            indexReady: props.fileIndexReady,
            indexBuilding: props.fileIndexBuilding,
            indexSize: props.fileIndexItemsLength,
            metrics: ({
                    filesResolveRuns: resolveRuns,
                    filesResolveAvgMs: resolveAvgMs,
                    filesResolveLastMs: resolveLastMs,
                    filesFdLoads: filesFdLoads,
                    filesFindLoads: filesFindLoads,
                    filesFdAvgMs: filesFdAvgMs,
                    filesFdLastMs: filesFdLastMs,
                    filesFindAvgMs: filesFindAvgMs,
                    filesFindLastMs: filesFindLastMs
                }),
            cache: ({
                    hits: fileCacheHits,
                    misses: fileCacheMisses,
                    hitRateLabel: props.filesCacheStatsLabel
                }),
            // Backward-compatible flat fields for existing consumers.
            resolveRuns: resolveRuns,
            resolveAvgMs: resolveAvgMs,
            resolveLastMs: resolveLastMs,
            filesFdLoads: filesFdLoads,
            filesFindLoads: filesFindLoads,
            filesFdAvgMs: filesFdAvgMs,
            filesFdLastMs: filesFdLastMs,
            filesFindAvgMs: filesFindAvgMs,
            filesFindLastMs: filesFindLastMs,
            fileCacheHits: fileCacheHits,
            fileCacheMisses: fileCacheMisses,
            fileCacheHitRateLabel: props.filesCacheStatsLabel,
            fileIndexReady: props.fileIndexReady,
            fileIndexBuilding: props.fileIndexBuilding,
            fileIndexSize: props.fileIndexItemsLength
        });
}

function drunCategoryStateObject(props) {
    var options = Array.isArray(props.drunCategoryOptions) ? props.drunCategoryOptions : [];
    var normalized = [];
    var active = null;
    for (var i = 0; i < options.length; ++i) {
        var raw = options[i] || ({});
        var key = String(raw.key || "");
        var label = String(raw.label || props.formatLabelFn(key));
        var count = Math.max(0, Math.round(Number(raw.count || 0)));
        var hotkey = String(raw.hotkey || "");
        var selected = key === props.drunCategoryFilter;
        var item = ({
                key: key,
                label: label,
                count: count,
                hotkey: hotkey,
                selected: selected
            });
        if (selected && !active)
            active = item;
        normalized.push(item);
    }

    if (!active && normalized.length > 0) {
        var fallback = normalized[0];
        active = Object.assign({}, fallback, {
            selected: true
        });
        normalized[0] = active;
    }

    var totalCount = normalized.length > 0 ? Math.max(0, Math.round(Number(normalized[0].count || 0))) : 0;
    var activeCount = active ? Math.max(0, Math.round(Number(active.count || 0))) : totalCount;

    return ({
            enabled: props.drunCategoryFiltersEnabled === true,
            mode: String(props.mode || ""),
            showLauncherHome: props.showLauncherHome === true,
            visible: props.showLauncherHome && props.drunCategoryFiltersEnabled && props.mode === "drun" && options.length > 1,
            activeKey: active ? String(active.key || "") : "",
            activeLabel: active ? String(active.label || "All") : "All",
            activeCount: activeCount,
            totalCount: totalCount,
            options: normalized
        });
}

function escapeActionStateObject(props) {
    var action = "close";
    if (props.showingConfirm)
        action = "cancelConfirm";
    else if (props.searchText !== "")
        action = "resetQuery";
    else if (props.drunCategoryFiltersEnabled && props.mode === "drun" && props.drunCategoryFilter !== "")
        action = "resetCategory";
    else if (props.drunCategoryFiltersEnabled && props.mode === "drun" && props.drunCategorySectionExpanded)
        action = "collapseCategorySummary";

    return ({
            action: action,
            mode: String(props.mode || ""),
            showingConfirm: props.showingConfirm === true,
            hasQuery: props.searchText !== "",
            searchText: String(props.searchText || ""),
            hasCategoryFilter: props.drunCategoryFiltersEnabled && props.mode === "drun" && props.drunCategoryFilter !== "",
            drunCategoryFilter: String(props.drunCategoryFilter || "")
        });
}

function launcherStateObject(props) {
    return ({
            visible: props.launcherOpacity > 0,
            mode: String(props.mode || ""),
            searchText: String(props.searchText || ""),
            showLauncherHome: props.showLauncherHome === true,
            drunCategoryFilter: String(props.drunCategoryFilter || ""),
            drunCategorySectionExpanded: props.drunCategorySectionExpanded === true,
            hasResults: props.filteredItemsLength > 0,
            loadState: String(props.modeLoadState || "idle"),
            loadMessage: String(props.modeLoadMessage || ""),
            allItemCount: props.allItemsLength,
            filteredItemCount: props.filteredItemsLength,
            recentCount: props.recentItemsLength,
            suggestionCount: props.suggestionItemsLength,
            fileIndexReady: props.fileIndexReady === true,
            fileIndexBuilding: props.fileIndexBuilding === true,
            fileIndexSize: props.fileIndexItemsLength,
            selectedIndex: props.selectedIndex,
            resultCount: props.filteredItemsLength,
            windowWidth: props.width,
            windowHeight: props.height,
            screenWidth: props.screenWidth,
            screenHeight: props.screenHeight,
            actualViewportWidth: props.actualViewportWidth,
            actualViewportHeight: props.actualViewportHeight,
            viewportWidth: props.viewportWidth,
            viewportHeight: props.viewportHeight,
            usableWidth: props.usableWidth,
            usableHeight: props.usableHeight,
            actualUsableWidth: props.actualUsableWidth,
            actualUsableHeight: props.actualUsableHeight,
            diagnosticViewportOffsetX: props.diagnosticViewportOffsetX,
            diagnosticViewportOffsetY: props.diagnosticViewportOffsetY,
            hudX: props.hudX,
            hudY: props.hudY,
            hudWidth: props.hudWidth,
            hudHeight: props.hudHeight,
            hudScale: props.hudScale
        });
}
