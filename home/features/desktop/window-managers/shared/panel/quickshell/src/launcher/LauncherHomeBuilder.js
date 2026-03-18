.pragma library
.import "LauncherSearch.js" as Search

// Build the drun home view (recent apps + suggestions) from app cache and history.
// Returns { recentItems: [], suggestionItems: [] }
function buildDrunHome(apps, launchHistory, categoryFilter, usageTracker, config) {
    var recent = [];
    var seen = ({});
    var appsByExec = ({});
    var usageRanked = [];

    for (var i = 0; i < apps.length; ++i) {
        var app = apps[i];
        var execKey = String(app.exec || "");
        if (execKey !== "" && !appsByExec[execKey])
            appsByExec[execKey] = app;
        var usageScore = usageTracker.getUsageScore(execKey);
        if (usageScore > 0) {
            var rankedByUsage = Object.assign({}, app);
            rankedByUsage._usage = usageScore;
            usageRanked.push(rankedByUsage);
        }
    }

    for (var j = 0; j < launchHistory.length; ++j) {
        var launch = launchHistory[j];
        var launchExec = String(launch.exec || "");
        var matchedApp = launchExec === "" ? null : appsByExec[launchExec];
        if (matchedApp && !seen[launchExec]) {
            var matched = Object.assign({}, matchedApp);
            matched._recent = launch.timestamp || 0;
            recent.push(matched);
            seen[launchExec] = true;
        }
    }

    usageRanked.sort(function (a, b) {
        if ((b._usage || 0) !== (a._usage || 0))
            return (b._usage || 0) - (a._usage || 0);
        return Search.compareLauncherItemsAlpha(a, b);
    });
    recent.sort(function (a, b) {
        if ((b._recent || 0) !== (a._recent || 0))
            return (b._recent || 0) - (a._recent || 0);
        return Search.compareLauncherItemsAlpha(a, b);
    });

    if (categoryFilter !== "") {
        recent = recent.filter(function (item) {
            return config.itemMatchesDrunCategory(item, categoryFilter);
        });
    }

    if (recent.length < config.recentAppsLimit) {
        for (var k = 0; k < usageRanked.length; ++k) {
            var fallback = usageRanked[k];
            var fallbackExec = String(fallback.exec || "");
            if (fallbackExec === "" || seen[fallbackExec] || !config.itemMatchesDrunCategory(fallback, categoryFilter))
                continue;
            var promoted = Object.assign({}, fallback);
            promoted._recent = fallback._usage || 0;
            recent.push(promoted);
            seen[fallbackExec] = true;
            if (recent.length >= config.recentAppsLimit)
                break;
        }
    }

    var recentItems = recent.slice(0, config.recentAppsLimit);

    var suggestions = [];
    for (var m = 0; m < usageRanked.length; ++m) {
        var candidate = usageRanked[m];
        var candidateExec = String(candidate.exec || "");
        if (candidateExec === "" || seen[candidateExec] || !config.itemMatchesDrunCategory(candidate, categoryFilter))
            continue;
        suggestions.push(candidate);
    }
    var suggestionItems = suggestions.slice(0, config.suggestionsLimit);

    return { recentItems: recentItems, suggestionItems: suggestionItems };
}
