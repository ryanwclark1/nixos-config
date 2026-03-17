.pragma library

var allKnownModes = ["drun", "window", "files", "ai", "clip", "emoji", "calc", "web", "plugins", "run", "system", "keybinds", "media", "nixos", "wallpapers", "bookmarks", "settings", "devops", "orchestrator"];
var transientModes = ["dmenu"];
var defaultModeOrder = ["drun", "window", "files", "ai", "clip", "emoji", "calc", "web", "plugins", "run", "system", "keybinds", "media", "nixos", "wallpapers", "bookmarks", "settings", "devops", "orchestrator"];
var defaultPrimaryModes = ["drun", "window", "files", "ai", "clip", "system", "media", "settings", "devops", "orchestrator"];
var modePrefixes = "!/@?>=:";

var modeMeta = {
    "drun": { label: "Apps", hint: "Launch applications", prefix: "" },
    "window": { label: "Windows", hint: "Jump to an open window", prefix: "" },
    "files": { label: "Files", hint: "Search home with /", prefix: "/" },
    "ai": { label: "AI", hint: "Ask with !", prefix: "!" },
    "clip": { label: "Clipboard", hint: "Recent clipboard history", prefix: "" },
    "emoji": { label: "Emoji", hint: "Search with :", prefix: ":" },
    "calc": { label: "Calculator", hint: "Evaluate with =", prefix: "=" },
    "web": { label: "Web", hint: "Search with ?", prefix: "?" },
    "plugins": { label: "Plugins", hint: "Search plugin providers", prefix: "" },
    "run": { label: "Run", hint: "Run commands with >", prefix: ">" },
    "system": { label: "System", hint: "Session and utility actions", prefix: "" },
    "keybinds": { label: "Keybinds", hint: "Inspect and trigger binds", prefix: "" },
    "media": { label: "Media", hint: "Control active players", prefix: "" },
    "nixos": { label: "NixOS", hint: "Nix maintenance actions", prefix: "" },
    "wallpapers": { label: "Wallpapers", hint: "Pick and apply wallpapers", prefix: "" },
    "bookmarks": { label: "Bookmarks", hint: "Open bookmarked destinations", prefix: "@" },
    "settings": { label: "Settings", hint: "Jump to a settings tab with ,", prefix: "," },
    "devops": { label: "DevOps", hint: "Control containers & services", prefix: "" },
    "orchestrator": { label: "Orchestrator", hint: "Full system dashboard", prefix: "" }
};

var modeIcons = {
    "drun": "󰀻", "window": "󰖯", "files": "󰈔", "ai": "󰚩",
    "clip": "󰅍", "emoji": "󰞅", "calc": "󰪚", "web": "󰖟",
    "plugins": "󰏗", "run": "󰆍", "system": "󰒓", "keybinds": "󰌌",
    "media": "󰝚", "nixos": "", "wallpapers": "󰸉", "bookmarks": "󰃭",
    "settings": "󰒓", "devops": "󰒍", "orchestrator": "󰓅"
};

function modeInfo(key) {
    return modeMeta[key] || { label: key.toUpperCase(), hint: "", prefix: "" };
}

function sanitizeModeList(source, fallback, allowedList) {
    var out = [];
    var seen = {};
    var allowed = {};
    var i;
    for (i = 0; i < allowedList.length; ++i)
        allowed[allowedList[i]] = true;
    var list = Array.isArray(source) && source.length > 0 ? source : fallback;
    for (i = 0; i < list.length; ++i) {
        var modeKey = String(list[i] || "");
        if (!allowed[modeKey] || seen[modeKey])
            continue;
        out.push(modeKey);
        seen[modeKey] = true;
    }
    if (out.length === 0)
        return fallback.slice();
    return out;
}

function modeDependencies(modeKey) {
    if (modeKey === "drun") return ["qs-apps"];
    if (modeKey === "run") return ["qs-run"];
    if (modeKey === "emoji") return ["qs-emoji"];
    if (modeKey === "clip") return ["qs-clip", "cliphist", "wl-copy"];
    if (modeKey === "keybinds") return ["qs-keybinds"];
    if (modeKey === "bookmarks") return ["qs-bookmarks"];
    if (modeKey === "wallpapers") return ["qs-wallpapers"];
    if (modeKey === "ai") return ["qs-ai", "wl-copy"];
    if (modeKey === "files") return [];
    if (modeKey === "plugins") return [];
    return [];
}

function missingDependencyMessage(modeKey, cmd) {
    if (modeKey === "files")
        return "Required command missing: " + cmd;
    return "Install '" + cmd + "' to use " + modeInfo(modeKey).label + " mode.";
}

function shellQuote(text) {
    return "'" + String(text || "").replace(/'/g, "'\\''") + "'";
}

function stripModePrefix(text) {
    if (text.length > 0 && modePrefixes.indexOf(text[0]) !== -1)
        return text.substring(1).trim();
    return text;
}

function configuredWebProviders(orderArray) {
    var fallback = ["duckduckgo", "google", "youtube", "nixos", "github"];
    var order = Array.isArray(orderArray) && orderArray.length > 0 ? orderArray : fallback;
    var out = [];
    var seen = {};
    for (var i = 0; i < order.length; ++i) {
        var key = String(order[i] || "");
        var provider = webProviderCatalog[key];
        if (!provider || seen[key])
            continue;
        out.push(provider);
        seen[key] = true;
    }
    if (out.length === 0) {
        for (var j = 0; j < fallback.length; ++j) {
            var fallbackProvider = webProviderCatalog[fallback[j]];
            if (fallbackProvider)
                out.push(fallbackProvider);
        }
    }
    return out;
}

function webAliasToProviderKey(token, providers, aliases) {
    var key = String(token || "").toLowerCase();
    if (key === "")
        return "";
    if (webProviderCatalog[key])
        return key;
    for (var i = 0; i < providers.length; ++i) {
        var providerKey = String(providers[i].key || "");
        if (providerKey === "")
            continue;
        var list = aliases[providerKey];
        if (!Array.isArray(list))
            continue;
        for (var j = 0; j < list.length; ++j) {
            if (String(list[j] || "").toLowerCase() === key)
                return providerKey;
        }
    }
    return "";
}

function parseWebQuery(text, providers, aliases) {
    var clean = stripModePrefix(text || "").trim();
    var result = { query: clean, providerKey: "" };
    if (clean === "")
        return result;
    var parts = clean.split(/\s+/);
    if (!parts || parts.length === 0)
        return result;
    var mapped = webAliasToProviderKey(parts[0], providers, aliases);
    if (mapped === "")
        return result;
    result.providerKey = mapped;
    result.query = parts.length > 1 ? clean.substring(parts[0].length).trim() : "";
    return result;
}

var webProviderCatalog = {
    "google": {
        key: "google", name: "Google",
        exec: "https://www.google.com/search?q=",
        home: "https://www.google.com/",
        icon: "󰊯", isWeb: true
    },
    "duckduckgo": {
        key: "duckduckgo", name: "DuckDuckGo",
        exec: "https://duckduckgo.com/?q=",
        home: "https://duckduckgo.com/",
        icon: "󰇥", isWeb: true
    },
    "youtube": {
        key: "youtube", name: "YouTube",
        exec: "https://www.youtube.com/results?search_query=",
        home: "https://www.youtube.com/",
        icon: "󰗃", isWeb: true
    },
    "nixos": {
        key: "nixos", name: "NixOS Packages",
        exec: "https://search.nixos.org/packages?query=",
        home: "https://search.nixos.org/packages",
        icon: "", isWeb: true
    },
    "github": {
        key: "github", name: "GitHub",
        exec: "https://github.com/search?q=",
        home: "https://github.com/",
        icon: "󰊤", isWeb: true
    }
};
