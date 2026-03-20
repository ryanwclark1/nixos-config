.pragma library

var allKnownModes = ["drun", "window", "files", "ai", "system", "settings", "run", "ssh", "web", "clip", "emoji", "calc", "bookmarks", "media", "nixos", "wallpapers", "plugins", "devops", "orchestrator", "keybinds"];
var transientModes = ["dmenu"];
var defaultModeOrder = ["drun", "window", "files", "ai", "system", "settings", "run", "ssh", "web", "clip", "emoji", "calc", "bookmarks", "media", "nixos", "wallpapers", "plugins", "devops", "orchestrator", "keybinds"];
var defaultPrimaryModes = ["drun", "window", "files", "ai", "system"];
var modePrefixes = "!/@?>=,:;~";

var modeMeta = {
    "drun": { label: "Apps", shortLabel: "Apps", heroLabel: "Application Launch", heroIcon: "apps.svg", hint: "Launch applications", prefix: "", tone: "primary" },
    "window": { label: "Windows", shortLabel: "Windows", heroLabel: "Window Switch", heroIcon: "window-shield.svg", hint: "Jump to an open window with ~", prefix: "~", tone: "info" },
    "files": { label: "Files", shortLabel: "Files", heroLabel: "File Search", heroIcon: "folder.svg", hint: "Search home with /", prefix: "/", tone: "warning" },
    "ai": { label: "AI", shortLabel: "AI", heroLabel: "AI Prompt", heroIcon: "chat.svg", hint: "Ask with !", prefix: "!", tone: "accent" },
    "clip": { label: "Clipboard", shortLabel: "Clipboard", heroLabel: "Clipboard History", heroIcon: "copy.svg", hint: "Recent clipboard history", prefix: "", tone: "secondary" },
    "emoji": { label: "Characters", shortLabel: "Chars", heroLabel: "Character Search", heroIcon: "star.svg", hint: "Search characters with :", prefix: ":", tone: "warning" },
    "calc": { label: "Calculator", shortLabel: "Calc", heroLabel: "Inline Calculation", heroIcon: "calculator.svg", hint: "Evaluate with =", prefix: "=", tone: "warning" },
    "web": { label: "Web", shortLabel: "Web", heroLabel: "Web Search", heroIcon: "globe-search.svg", hint: "Search with ?", prefix: "?", tone: "info" },
    "plugins": { label: "Plugins", shortLabel: "Plugins", heroLabel: "Plugin Search", heroIcon: "apps.svg", hint: "Search plugin providers", prefix: "", tone: "secondary" },
    "run": { label: "Run", shortLabel: "Run", heroLabel: "Command Execution", heroIcon: "terminal.svg", hint: "Run commands with >", prefix: ">", tone: "accent" },
    "system": { label: "System", shortLabel: "System", heroLabel: "Shell Destinations", heroIcon: "settings.svg", hint: "Shell and session destinations", prefix: "", tone: "secondary" },
    "keybinds": { label: "Keybinds", shortLabel: "Keys", heroLabel: "Keybind Browser", heroIcon: "keyboard.svg", hint: "Inspect and trigger binds", prefix: "", tone: "secondary" },
    "media": { label: "Media", shortLabel: "Media", heroLabel: "Media Control", heroIcon: "music-note-2.svg", hint: "Control active players", prefix: "", tone: "success" },
    "nixos": { label: "NixOS", shortLabel: "NixOS", heroLabel: "NixOS Actions", heroIcon: "brands/nixos-symbolic.svg", hint: "Nix maintenance actions", prefix: "", tone: "success" },
    "wallpapers": { label: "Wallpapers", shortLabel: "Walls", heroLabel: "Wallpaper Picker", heroIcon: "image.svg", hint: "Pick and apply wallpapers", prefix: "", tone: "accent" },
    "bookmarks": { label: "Bookmarks", shortLabel: "Marks", heroLabel: "Bookmark Search", heroIcon: "bookmark.svg", hint: "Open bookmarked destinations", prefix: "@", tone: "primary" },
    "settings": { label: "Settings", shortLabel: "Settings", heroLabel: "Settings Jump", heroIcon: "settings.svg", hint: "Jump to a settings tab with ,", prefix: ",", tone: "secondary" },
    "devops": { label: "DevOps", shortLabel: "DevOps", heroLabel: "Ops Controls", heroIcon: "developer-board.svg", hint: "Control containers & services", prefix: "", tone: "warning" },
    "orchestrator": { label: "Orchestrator", shortLabel: "Ops", heroLabel: "System Orchestrator", heroIcon: "board.svg", hint: "Full system dashboard", prefix: "", tone: "success" },
    "ssh": { label: "SSH", shortLabel: "SSH", heroLabel: "Remote Connect", heroIcon: "server.svg", hint: "Connect with ;", prefix: ";", tone: "info" }
};

var modeIcons = {
    "drun": "apps.svg", "window": "window-shield.svg", "files": "folder.svg", "ai": "chat.svg",
    "clip": "copy.svg", "emoji": "star.svg", "calc": "calculator.svg", "web": "globe-search.svg",
    "plugins": "apps.svg", "run": "terminal.svg", "system": "settings.svg", "keybinds": "keyboard.svg",
    "media": "music-note-2.svg", "nixos": "brands/nixos-symbolic.svg", "wallpapers": "image.svg", "bookmarks": "bookmark.svg",
    "settings": "settings.svg", "devops": "developer-board.svg", "orchestrator": "board.svg",
    "ssh": "server.svg"
};

var modeDeps = {
    "run": ["qs-run"],
    "clip": ["cliphist", "wl-copy", "wl-paste"],
    "emoji": ["wl-copy"],
    "keybinds": ["qs-keybinds"],
    "bookmarks": ["qs-bookmarks"],
    "wallpapers": ["qs-wallpapers"],
    "ai": ["qs-ai", "wl-copy"]
};

function modeDependencies(key) {
    return modeDeps[key] || [];
}

function missingDependencyMessage(key, cmd) {
    if (key === "files")
        return "Required command missing: " + cmd;
    return "Install '" + cmd + "' to use " + modeInfo(key).label + " mode.";
}

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

function shellQuote(text) {
    return "'" + String(text || "").replace(/'/g, "'\\''") + "'";
}

function stripModePrefix(text) {
    if (text.length > 0 && modePrefixes.indexOf(text[0]) !== -1)
        return text.substring(1).trim();
    return text;
}

function configuredWebProviders(orderArray, customEngines) {
    var catalog = customEngines ? mergedProviderCatalog(customEngines) : webProviderCatalog;
    var fallback = ["duckduckgo", "google", "youtube", "nixos", "github"];
    var order = Array.isArray(orderArray) && orderArray.length > 0 ? orderArray : fallback;
    var out = [];
    var seen = {};
    for (var i = 0; i < order.length; ++i) {
        var key = String(order[i] || "");
        var provider = catalog[key];
        if (!provider || seen[key])
            continue;
        out.push(provider);
        seen[key] = true;
    }
    if (out.length === 0) {
        for (var j = 0; j < fallback.length; ++j) {
            var fallbackProvider = catalog[fallback[j]];
            if (fallbackProvider)
                out.push(fallbackProvider);
        }
    }
    return out;
}

function webAliasToProviderKey(token, providers, aliases, customEngines) {
    var key = String(token || "").toLowerCase();
    if (key === "")
        return "";
    var catalog = customEngines ? mergedProviderCatalog(customEngines) : webProviderCatalog;
    if (catalog[key])
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

function parseWebQuery(text, providers, aliases, customEngines) {
    var clean = stripModePrefix(text || "").trim();
    var result = { query: clean, providerKey: "" };
    if (clean === "")
        return result;
    var parts = clean.split(/\s+/);
    if (!parts || parts.length === 0)
        return result;
    var mapped = webAliasToProviderKey(parts[0], providers, aliases, customEngines);
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
        icon: "globe-search.svg", isWeb: true
    },
    "duckduckgo": {
        key: "duckduckgo", name: "DuckDuckGo",
        exec: "https://duckduckgo.com/?q=",
        home: "https://duckduckgo.com/",
        icon: "globe-search.svg", isWeb: true
    },
    "youtube": {
        key: "youtube", name: "YouTube",
        exec: "https://www.youtube.com/results?search_query=",
        home: "https://www.youtube.com/",
        icon: "play.svg", isWeb: true
    },
    "nixos": {
        key: "nixos", name: "NixOS Packages",
        exec: "https://search.nixos.org/packages?query=",
        home: "https://search.nixos.org/packages",
        icon: "brands/nixos-symbolic.svg", isWeb: true
    },
    "github": {
        key: "github", name: "GitHub",
        exec: "https://github.com/search?q=",
        home: "https://github.com/",
        icon: "brands/github-symbolic.svg", isWeb: true
    },
    "brave": {
        key: "brave", name: "Brave Search",
        exec: "https://search.brave.com/search?q=",
        home: "https://search.brave.com/",
        icon: "globe-search.svg", isWeb: true
    },
    "bing": {
        key: "bing", name: "Bing",
        exec: "https://www.bing.com/search?q=",
        home: "https://www.bing.com/",
        icon: "globe-search.svg", isWeb: true
    },
    "kagi": {
        key: "kagi", name: "Kagi",
        exec: "https://kagi.com/search?q=",
        home: "https://kagi.com/",
        icon: "globe-search.svg", isWeb: true
    },
    "stackoverflow": {
        key: "stackoverflow", name: "Stack Overflow",
        exec: "https://stackoverflow.com/search?q=",
        home: "https://stackoverflow.com/",
        icon: "globe-search.svg", isWeb: true
    },
    "npm": {
        key: "npm", name: "npm",
        exec: "https://www.npmjs.com/search?q=",
        home: "https://www.npmjs.com/",
        icon: "apps.svg", isWeb: true
    },
    "pypi": {
        key: "pypi", name: "PyPI",
        exec: "https://pypi.org/search/?q=",
        home: "https://pypi.org/",
        icon: "apps.svg", isWeb: true
    },
    "crates": {
        key: "crates", name: "crates.io",
        exec: "https://crates.io/search?q=",
        home: "https://crates.io/",
        icon: "apps.svg", isWeb: true
    },
    "mdn": {
        key: "mdn", name: "MDN Web Docs",
        exec: "https://developer.mozilla.org/en-US/search?q=",
        home: "https://developer.mozilla.org/",
        icon: "globe-search.svg", isWeb: true
    },
    "archwiki": {
        key: "archwiki", name: "Arch Wiki",
        exec: "https://wiki.archlinux.org/index.php?search=",
        home: "https://wiki.archlinux.org/",
        icon: "brands/arch-symbolic.svg", isWeb: true
    },
    "aur": {
        key: "aur", name: "AUR",
        exec: "https://aur.archlinux.org/packages?K=",
        home: "https://aur.archlinux.org/",
        icon: "brands/arch-symbolic.svg", isWeb: true
    },
    "nixopts": {
        key: "nixopts", name: "NixOS Options",
        exec: "https://search.nixos.org/options?channel=unstable&query=",
        home: "https://search.nixos.org/options",
        icon: "brands/nixos-symbolic.svg", isWeb: true
    },
    "reddit": {
        key: "reddit", name: "Reddit",
        exec: "https://www.reddit.com/search?q=",
        home: "https://www.reddit.com/",
        icon: "chat.svg", isWeb: true
    },
    "twitter": {
        key: "twitter", name: "Twitter/X",
        exec: "https://twitter.com/search?q=",
        home: "https://twitter.com/",
        icon: "chat.svg", isWeb: true
    },
    "linkedin": {
        key: "linkedin", name: "LinkedIn",
        exec: "https://www.linkedin.com/search/results/all/?keywords=",
        home: "https://www.linkedin.com/",
        icon: "people.svg", isWeb: true
    },
    "wikipedia": {
        key: "wikipedia", name: "Wikipedia",
        exec: "https://en.wikipedia.org/wiki/Special:Search?search=",
        home: "https://en.wikipedia.org/",
        icon: "library.svg", isWeb: true
    },
    "translate": {
        key: "translate", name: "Google Translate",
        exec: "https://translate.google.com/?text=",
        home: "https://translate.google.com/",
        icon: "rename.svg", isWeb: true
    },
    "imdb": {
        key: "imdb", name: "IMDb",
        exec: "https://www.imdb.com/find?q=",
        home: "https://www.imdb.com/",
        icon: "play.svg", isWeb: true
    },
    "amazon": {
        key: "amazon", name: "Amazon",
        exec: "https://www.amazon.com/s?k=",
        home: "https://www.amazon.com/",
        icon: "apps.svg", isWeb: true
    },
    "ebay": {
        key: "ebay", name: "eBay",
        exec: "https://www.ebay.com/sch/i.html?_nkw=",
        home: "https://www.ebay.com/",
        icon: "apps.svg", isWeb: true
    },
    "maps": {
        key: "maps", name: "Google Maps",
        exec: "https://www.google.com/maps/search/",
        home: "https://www.google.com/maps",
        icon: "compass.svg", isWeb: true
    },
    "images": {
        key: "images", name: "Google Images",
        exec: "https://www.google.com/search?tbm=isch&q=",
        home: "https://www.google.com/imghp",
        icon: "image.svg", isWeb: true
    }
};

// Returns an array of all built-in catalog keys.
function webProviderKeys() {
    return Object.keys(webProviderCatalog);
}

// Merge custom user-defined engines into the built-in catalog.
// Custom engines with the same key as a built-in engine override it.
function mergedProviderCatalog(customEngines) {
    var merged = {};
    var key;
    for (key in webProviderCatalog)
        merged[key] = webProviderCatalog[key];
    if (!Array.isArray(customEngines))
        return merged;
    for (var i = 0; i < customEngines.length; ++i) {
        var engine = customEngines[i];
        if (!engine || !engine.key || !engine.name || !engine.exec)
            continue;
        merged[engine.key] = {
            key: engine.key,
            name: engine.name,
            exec: engine.exec,
            home: engine.home || "",
            icon: engine.icon || "󰖟",
            isWeb: true,
            isCustom: true
        };
    }
    return merged;
}
