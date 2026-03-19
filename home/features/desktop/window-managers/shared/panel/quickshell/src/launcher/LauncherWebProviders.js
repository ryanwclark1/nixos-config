.pragma library

// Pure provider lookup functions extracted from Launcher.qml.
// All take the provider list as a parameter to avoid QML coupling.

function primaryProvider(providers) {
    return providers.length > 0 ? providers[0] : null;
}

function secondaryProvider(providers) {
    return providers.length > 1 ? providers[1] : null;
}

function providerByKey(providers, providerKey) {
    var key = String(providerKey || "");
    if (key === "")
        return null;
    for (var i = 0; i < providers.length; ++i) {
        if (String(providers[i].key || "") === key)
            return providers[i];
    }
    return null;
}

function preferredProviderKey(rememberEnabled, persistedKey, sessionKey) {
    if (rememberEnabled) {
        var persisted = String(persistedKey || "");
        if (persisted !== "")
            return persisted;
    }
    return String(sessionKey || "");
}

// Build a web target URL from a provider and query string.
// Supports two URL patterns:
//   1. Append-query: exec URL ends with a query param, query is appended
//   2. Placeholder: exec URL contains %s, replaced with encoded query
function buildWebTarget(provider, query) {
    if (!provider)
        return "";
    var exec = String(provider.exec || "");
    if (query !== "" && exec) {
        if (exec.indexOf("%s") !== -1)
            return exec.replace(/%s/g, encodeURIComponent(query));
        return exec + encodeURIComponent(query);
    }
    return String(provider.home || exec || "");
}

// Build a recent entry for a web provider action.
function buildWebRecent(provider, target) {
    return {
        name: provider.name || "Web",
        title: target,
        icon: provider.icon || "󰖟",
        exec: String(provider.exec || "")
    };
}

// Derive a homepage URL from a provider item.
function deriveHomepage(item) {
    var home = String(item.home || "");
    if (home === "") {
        var exec = String(item.exec || "");
        var qIndex = exec.indexOf("?");
        home = qIndex >= 0 ? exec.substring(0, qIndex) : exec;
        if (home !== "" && home.charAt(home.length - 1) !== "/")
            home += "/";
    }
    return home;
}
