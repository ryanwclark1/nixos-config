.pragma library
.import "LauncherSearch.js" as Search

// Build category option array from app list.
// formatLabel(key) → display string, e.g. "Utility" → "Utility"
// Returns array of { key, label, count, hotkey } with "All" entry at index 0.
function buildCategoryOptions(apps, formatLabel) {
    var source = Array.isArray(apps) ? apps : [];
    var counts = ({});
    var labels = ({});
    for (var i = 0; i < source.length; ++i) {
        var app = source[i];
        Search.ensureItemRankCache(app);
        var key = String(app._primaryCategoryKey || "");
        if (key === "")
            continue;
        counts[key] = (counts[key] || 0) + 1;
        if (!labels[key])
            labels[key] = formatLabel(key);
    }
    var keys = Object.keys(counts);
    keys.sort(function (a, b) {
        if ((counts[b] || 0) !== (counts[a] || 0))
            return (counts[b] || 0) - (counts[a] || 0);
        return String(labels[a] || a).localeCompare(String(labels[b] || b));
    });

    var result = [
        {
            key: "",
            label: "All",
            count: source.length,
            hotkey: "0"
        }
    ];
    var limit = Math.min(9, keys.length);
    for (var j = 0; j < limit; ++j) {
        var categoryKey = keys[j];
        result.push({
            key: categoryKey,
            label: String(labels[categoryKey] || categoryKey),
            count: counts[categoryKey] || 0,
            hotkey: String(j + 1)
        });
    }
    return result;
}

// Returns "" if currentFilter is not present among options, else returns currentFilter.
function validateCategoryFilter(currentFilter, options) {
    for (var i = 0; i < options.length; ++i) {
        if (String(options[i].key || "") === currentFilter)
            return currentFilter;
    }
    return "";
}
