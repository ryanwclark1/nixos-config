.pragma library

var allKnownModes = ["drun", "window", "files", "ai", "clip", "emoji", "calc", "web", "plugins", "run", "system", "keybinds", "media", "nixos", "wallpapers", "bookmarks", "settings", "devops"];
var transientModes = ["dmenu"];
var defaultModeOrder = ["drun", "window", "files", "ai", "clip", "emoji", "calc", "web", "plugins", "run", "system", "keybinds", "media", "nixos", "wallpapers", "bookmarks", "settings", "devops"];
var defaultPrimaryModes = ["drun", "window", "files", "ai", "clip", "system", "media", "settings", "devops"];
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
    "devops": { label: "DevOps", hint: "Control containers & services", prefix: "" }
};

var modeIcons = {
    "drun": "󰀻", "window": "󱗼", "files": "󰈔", "ai": "󰚩",
    "clip": "󰅍", "emoji": "󰞅", "calc": "󰪚", "web": "󰖟",
    "plugins": "󰏗", "run": "󰆍", "system": "󰒓", "keybinds": "󰌌",
    "media": "󰝚", "nixos": "", "wallpapers": "󰸉", "bookmarks": "󰃭",
    "settings": "󰒓", "devops": "󰒍"
};

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
