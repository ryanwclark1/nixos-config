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
        icon: provider.icon || "globe-search.svg",
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

// ── Web execution helpers ────────────────────────────────────────────────────
// All functions take a `ctx` dependency object with:
//   ctx.filteredItems      — array of current filtered items
//   ctx.selectedIndex      — number (readable/writable)
//   ctx.mode               — string
//   ctx.searchText         — string
//   ctx.parseWebQuery(t)   — fn → {providerKey, query}
//   ctx.configuredWebProviders() — fn → provider array
//   ctx.configuredWebProviderByKey(k) — fn → provider|null
//   ctx.primaryWebProvider()      — fn → provider|null
//   ctx.rememberRecent(item)      — fn
//   ctx.close()                   — fn
//   ctx.execDetached(args)        — fn

// Select a web provider in filteredItems by its key string.
function selectWebProviderByKey(providerKey, ctx) {
    if (ctx.mode !== "web" || providerKey === "")
        return;
    for (var i = 0; i < ctx.filteredItems.length; ++i) {
        if (String(ctx.filteredItems[i].key || "") === providerKey) {
            ctx.selectedIndex = i;
            return;
        }
    }
}

// Convert a Qt key code to a 1-based provider slot (1–9), or 0 if not a digit.
function webProviderSlotFromKey(key) {
    var slot = key - 48; // Qt.Key_0 === 48
    return (slot >= 1 && slot <= 9) ? slot : 0;
}

// Select the provider at the given 1-based slot.
function selectWebProviderBySlot(slot, ctx) {
    if (ctx.mode !== "web" || slot < 1)
        return false;
    var providers = ctx.configuredWebProviders();
    if (slot > providers.length)
        return false;
    var key = String((providers[slot - 1] || {}).key || "");
    if (key === "")
        return false;
    selectWebProviderByKey(key, ctx);
    return true;
}

// Execute a web search using the provider at the given 1-based slot.
function executeWebProviderBySlot(slot, ctx) {
    if (ctx.mode !== "web" || slot < 1)
        return false;
    var providers = ctx.configuredWebProviders();
    if (slot > providers.length)
        return false;
    var provider = providers[slot - 1];
    if (!provider)
        return false;
    var query = String(ctx.parseWebQuery(ctx.searchText).query || "");
    var target = buildWebTarget(provider, query);
    if (target === "")
        return false;
    ctx.rememberRecent(buildWebRecent(provider, target));
    ctx.execDetached(["xdg-open", target]);
    ctx.close();
    return true;
}

// Open the homepage of the currently-selected web provider.
function openSelectedWebHomepage(ctx) {
    if (ctx.mode !== "web" || ctx.filteredItems.length <= 0 || ctx.selectedIndex < 0 || ctx.selectedIndex >= ctx.filteredItems.length)
        return;
    var home = deriveHomepage(ctx.filteredItems[ctx.selectedIndex]);
    if (home !== "") {
        ctx.execDetached(["xdg-open", home]);
        ctx.close();
    }
}

// Execute the primary web search (or a bang result if one is selected).
// bangSearchTerm is the resolved bang query term from the caller.
function executePrimaryWebSearch(bangSearchTerm, ctx) {
    if (ctx.mode !== "web")
        return;
    if (ctx.selectedIndex >= 0 && ctx.selectedIndex < ctx.filteredItems.length) {
        var selectedItem = ctx.filteredItems[ctx.selectedIndex];
        if (selectedItem.isBang && selectedItem.bangUrl) {
            executeBangSearch(selectedItem.bangUrl, bangSearchTerm, ctx);
            return;
        }
    }
    var webCtx = ctx.parseWebQuery(ctx.searchText);
    var provider = ctx.configuredWebProviderByKey(webCtx.providerKey) || ctx.primaryWebProvider();
    if (!provider)
        return;
    var target = buildWebTarget(provider, webCtx.query);
    if (target === "")
        return;
    ctx.rememberRecent(buildWebRecent(provider, target));
    ctx.execDetached(["xdg-open", target]);
    ctx.close();
}

// Expand a bang URL template with the given query and open it.
function executeBangSearch(bangUrlTemplate, query, ctx) {
    var url = bangUrlTemplate;
    if (url.indexOf("{{{s}}}") !== -1)
        url = url.replace("{{{s}}}", encodeURIComponent(query));
    else if (url.indexOf("%s") !== -1)
        url = url.replace(/%s/g, encodeURIComponent(query));
    else
        url = url + encodeURIComponent(query);
    ctx.execDetached(["xdg-open", url]);
    ctx.close();
}
