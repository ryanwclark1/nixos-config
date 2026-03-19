.pragma library
.import "LauncherFileParser.js" as FileParser

// ── Empty state text ─────────────────────────────

function emptyStateTitle(mode, clean, fileMinQueryLength) {
    if (mode === "files") {
        if (clean.length < fileMinQueryLength)
            return "Start typing to search Home";
        return "No files match '" + clean + "'";
    }
    if (mode === "ai")
        return "Describe what you want and press Enter";
    if (mode === "clip")
        return "Clipboard history is empty";
    if (mode === "window")
        return "No open windows found";
    if (mode === "ssh")
        return "No SSH hosts found";
    return "No results";
}

function emptyStateSubtitle(mode, clean, fileMinQueryLength) {
    if (mode === "files") {
        if (clean.length < fileMinQueryLength)
            return "Filename-first search across your home directory. Prefix with / to jump here from any mode.";
        return "Try a shorter filename fragment or browse Home directly.";
    }
    if (mode === "ai")
        return "The response will be copied to your clipboard";
    if (mode === "clip")
        return "Copy something to populate clipboard history";
    if (mode === "window")
        return "Open some applications to see them here";
    if (mode === "ssh")
        return "Add hosts in SSH widget settings or import from ~/.ssh/config";
    return "Try another query or switch modes";
}

function emptyPrimaryCta(mode, clean, webPrimaryName) {
    if (mode === "files")
        return "Open Home";
    if (mode === "web")
        return clean !== "" ? "Search " + webPrimaryName : "Open " + webPrimaryName;
    if (mode === "ai")
        return clean.length >= 3 ? "Ask AI" : "Switch to Apps";
    if (mode === "run")
        return clean !== "" ? "Run Command" : "Switch to Apps";
    if (mode === "window")
        return "Open Apps";
    if (mode === "bookmarks")
        return "Switch to Web";
    if (mode === "clip")
        return "Switch to Apps";
    if (mode === "ssh")
        return clean !== "" ? "Connect to " + clean : "Open SSH Settings";
    return "Switch to Apps";
}

function emptySecondaryCta(mode, clean, searchText, webSecondaryName) {
    if (mode === "files")
        return FileParser.fileQueryLooksLikePath(clean) ? "Open Folder" : (searchText !== "" ? "Clear Query" : "");
    if (mode === "web")
        return clean !== "" ? "Search " + webSecondaryName : "Open " + webSecondaryName;
    if (mode === "system")
        return "Open Controls";
    if (mode === "run")
        return clean !== "" ? "Run In Terminal" : "Open Terminal";
    if (mode === "ssh")
        return "Refresh Import";
    return searchText !== "" ? "Clear Query" : "";
}

function emptyPrimaryHint(mode, clean, webPrimaryName, webPrimaryHintName) {
    var hintName = webPrimaryHintName || webPrimaryName;
    if (mode === "files")
        return "Open your home directory in the default file manager.";
    if (mode === "web")
        return clean !== "" ? "Search " + hintName + " using the current query." : "Open " + hintName + " homepage.";
    if (mode === "ai")
        return clean.length >= 3 ? "Send prompt to AI helper and show copyable result." : "Switch back to app launcher mode.";
    if (mode === "run")
        return clean !== "" ? "Execute command directly in shell." : "Switch back to app launcher mode.";
    if (mode === "system")
        return "Switch back to app launcher mode.";
    if (mode === "bookmarks")
        return "Switch to web mode for broader search.";
    if (mode === "ssh")
        return clean !== "" ? "Connect to this host directly." : "Configure SSH hosts and import settings.";
    return "Switch to app launcher mode.";
}

function emptyPrimaryHintIcon(mode) {
    if (mode === "files")
        return "󰉋";
    if (mode === "web")
        return "󰖟";
    if (mode === "ai")
        return "󰚩";
    if (mode === "run")
        return "󰆍";
    if (mode === "bookmarks")
        return "󰃀";
    if (mode === "ssh")
        return "󰣀";
    return "󰀻";
}

function emptySecondaryHint(mode, clean, searchText, webSecondaryName) {
    if (mode === "files")
        return FileParser.fileQueryLooksLikePath(clean) ? "Open the folder implied by the current path-like query." : (searchText !== "" ? "Clear the current query text." : "");
    if (mode === "web")
        return clean !== "" ? "Search " + webSecondaryName + " using the current query." : "Open " + webSecondaryName + " homepage.";
    if (mode === "system")
        return "Open quickshell control center panel.";
    if (mode === "run")
        return clean !== "" ? "Run command inside terminal for interactive output." : "Open terminal app.";
    if (mode === "ssh")
        return "Re-read ~/.ssh/config and refresh the host list.";
    if (searchText !== "")
        return "Clear the current query text.";
    return "";
}

function emptySecondaryHintIcon(mode, searchText) {
    if (mode === "files")
        return "󰉋";
    if (mode === "web")
        return "󰇥";
    if (mode === "system")
        return "󰒓";
    if (mode === "run")
        return "󰆍";
    if (mode === "ssh")
        return "󰑐";
    if (searchText !== "")
        return "󰅖";
    return "";
}

// ── Category filter labels ───────────────────────

function categoryFilterLabel(options, filter) {
    for (var i = 0; i < options.length; ++i) {
        var option = options[i];
        if (String(option.key || "") === filter)
            return String(option.label || "All");
    }
    return "All";
}

function categoryFilterSummary(options, filter) {
    var opts = Array.isArray(options) ? options : [];
    var totalCount = opts.length > 0 ? Math.max(0, Math.round(Number((opts[0] || {}).count || 0))) : 0;
    var activeCount = totalCount;
    for (var i = 0; i < opts.length; ++i) {
        var option = opts[i] || ({});
        if (String(option.key || "") === filter) {
            activeCount = Math.max(0, Math.round(Number(option.count || 0)));
            break;
        }
    }
    if (filter === "")
        return activeCount + " apps ready";
    return activeCount + " of " + totalCount + " apps";
}

// ── Web alias hint ───────────────────────────────

function webAliasHint(aliases, providers, compact) {
    var parts = [];
    for (var i = 0; i < providers.length; ++i) {
        var providerKey = String(providers[i].key || "");
        if (providerKey === "")
            continue;
        var list = aliases[providerKey];
        if (!Array.isArray(list) || list.length === 0)
            continue;
        var first = String(list[0] || "").trim();
        if (first !== "")
            parts.push("?" + first);
    }
    if (parts.length > 0)
        return (compact ? "Aliases: " : "Alias: ") + parts.join(" ");
    return compact ? "Aliases: provider key" : "Alias: provider key";
}
