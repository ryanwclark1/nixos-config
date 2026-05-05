pragma Singleton

import QtQuick
import "../../../services"
import "SettingsSearchIndex.js" as SearchIndex

QtObject {
    id: root

    readonly property string defaultTabId: "dashboard"

    readonly property var categories: [
        {
            id: "system-overview",
            label: "Overview",
            shortLabel: "Overview",
            description: "Status, shortcuts, and the quickest path into shell controls.",
            tone: "neutral",
            icon: "heart-pulse.svg",
            order: 0,
            expandedByDefault: true
        },
        {
            id: "shell-core",
            label: "Shell",
            shortLabel: "Shell",
            description: "Core shell behavior, popups, and the control center.",
            tone: "shell",
            icon: "settings.svg",
            order: 10,
            expandedByDefault: true
        },
        {
            id: "launcher",
            label: "Launcher",
            shortLabel: "Launcher",
            description: "Search, mode layout, providers, and runtime controls.",
            tone: "launcher",
            icon: "search-visual.svg",
            order: 20,
            expandedByDefault: true
        },
        {
            id: "visuals",
            label: "Visuals",
            shortLabel: "Visuals",
            description: "Themes, wallpaper, motion, density, and shell styling.",
            tone: "visual",
            icon: "color-palette.svg",
            order: 30,
            expandedByDefault: true
        },
        {
            id: "interaction",
            label: "Interaction",
            shortLabel: "Input",
            description: "Notifications, audio, overlays, and input-facing behavior.",
            tone: "interaction",
            icon: "cursor-click.svg",
            order: 40,
            expandedByDefault: true
        },
        {
            id: "surfaces",
            label: "Surfaces",
            shortLabel: "Surfaces",
            description: "Bars, docks, widgets, and other persistent shell surfaces.",
            tone: "surface",
            icon: "board.svg",
            order: 50,
            expandedByDefault: true
        },
        {
            id: "window-manager",
            label: "Window Manager",
            shortLabel: "WM",
            description: "Compositor layout, monitors, and workspace behavior.",
            tone: "window-manager",
            icon: "window-multiple.svg",
            order: 60,
            expandedByDefault: false
        },
        {
            id: "power-privacy",
            label: "Power & Privacy",
            shortLabel: "Power",
            description: "Battery policies, privacy indicators, and night-light behavior.",
            tone: "power",
            icon: "shield.svg",
            order: 70,
            expandedByDefault: false
        },
        {
            id: "extensibility",
            label: "Extensions",
            shortLabel: "Extensions",
            description: "Plugins, hooks, AI integrations, and model usage surfaces.",
            tone: "extensions",
            icon: "apps.svg",
            order: 80,
            expandedByDefault: false
        },
        {
            id: "meta",
            label: "Tools",
            shortLabel: "Tools",
            description: "Diagnostics, presets, and information about the current shell.",
            tone: "tools",
            icon: "info.svg",
            order: 90,
            expandedByDefault: false
        }
    ]

    readonly property var tabs: [
        {
            id: "dashboard",
            label: "Dashboard",
            shortLabel: "Dashboard",
            description: "Check shell status, media, and a few high-value quick actions.",
            pageStyle: "dashboard",
            icon: "heart-pulse.svg",
            categoryId: "system-overview",
            order: 0,
            component: "DashboardTab.qml",
            searchTerms: ["overview", "dashboard", "system", "status"],
            owner: {
                surface: "",
                service: "SystemStatus",
                configDomain: "overview"
            }
        },
        {
            id: "system",
            legacyIndex: 0,
            label: "Shell",
            shortLabel: "Shell",
            description: "Configure shell chrome, popup behavior, and shared surface settings.",
            pageStyle: "control",
            icon: "settings.svg",
            categoryId: "shell-core",
            order: 10,
            component: "SystemTab.qml",
            searchTerms: ["shell", "notification", "popup", "bar", "blur", "panels", "enable", "disable"],
            owner: {
                surface: "",
                service: "Config",
                configDomain: "shell"
            }
        },
        {
            id: "control-center",
            legacyIndex: 25,
            label: "Control Center",
            shortLabel: "Control Center",
            description: "Tune modules, quick toggles, and media controls in the control center.",
            pageStyle: "control",
            icon: "options.svg",
            categoryId: "shell-core",
            order: 20,
            component: "ControlCenterTab.qml",
            searchTerms: ["control center", "quick toggles", "quick links", "media widget"],
            owner: {
                surface: "controlCenter",
                service: "Config",
                configDomain: "controlCenter"
            }
        },
        {
            id: "launcher",
            legacyIndex: 24,
            label: "General",
            shortLabel: "General",
            description: "Tune the launcher shell, default entry mode, and home-stage behavior.",
            pageStyle: "launcher",
            icon: "search-visual.svg",
            categoryId: "launcher",
            order: 10,
            component: "LauncherTab.qml",
            searchTerms: ["launcher", "general", "default mode", "recents", "home"],
            owner: {
                surface: "launcher",
                service: "Config",
                configDomain: "launcher"
            }
        },
        {
            id: "launcher-search",
            label: "Search",
            shortLabel: "Search",
            description: "Adjust result breadth, file search timing, and launcher ranking signals.",
            pageStyle: "launcher",
            icon: "search-visual.svg",
            categoryId: "launcher",
            order: 20,
            component: "LauncherSearchTab.qml",
            searchTerms: ["launcher", "search", "results", "debounce", "ranking", "score", "recents"],
            owner: {
                surface: "launcher",
                service: "Config",
                configDomain: "launcher"
            }
        },
        {
            id: "launcher-web",
            label: "Web",
            shortLabel: "Web",
            description: "Manage providers, aliases, custom engines, and web-specific shortcuts.",
            pageStyle: "launcher",
            icon: "globe-search.svg",
            categoryId: "launcher",
            order: 30,
            component: "LauncherWebTab.qml",
            searchTerms: ["launcher", "web", "provider", "alias", "duckduckgo", "google", "youtube", "github"],
            owner: {
                surface: "launcher",
                service: "Config",
                configDomain: "launcher"
            }
        },
        {
            id: "launcher-modes",
            label: "Modes",
            shortLabel: "Modes",
            description: "Control which modes stay pinned, which stay advanced, and how presets apply.",
            pageStyle: "launcher",
            icon: "keyboard.svg",
            categoryId: "launcher",
            order: 40,
            component: "LauncherModesTab.qml",
            searchTerms: ["launcher", "modes", "apps", "files", "clipboard", "emoji", "preset", "order"],
            owner: {
                surface: "launcher",
                service: "Config",
                configDomain: "launcher"
            }
        },
        {
            id: "launcher-runtime",
            label: "Runtime",
            shortLabel: "Runtime",
            description: "Configure preload, diagnostics, metrics, and recovery actions for launcher runtime.",
            pageStyle: "launcher",
            icon: "timer.svg",
            categoryId: "launcher",
            order: 50,
            component: "LauncherRuntimeTab.qml",
            searchTerms: ["launcher", "runtime", "diagnostics", "preload", "metrics", "reset", "recovery"],
            owner: {
                surface: "launcher",
                service: "Config",
                configDomain: "launcher"
            }
        },
        {
            id: "theme",
            legacyIndex: 2,
            label: "Theme",
            shortLabel: "Theme",
            description: "Browse shell themes, schedules, and theme-source behavior.",
            pageStyle: "catalog",
            icon: "color-palette.svg",
            categoryId: "visuals",
            order: 10,
            component: "ThemeTab.qml",
            searchTerms: ["theme", "colors"],
            owner: {
                surface: "",
                service: "ThemeService",
                configDomain: "theme"
            }
        },
        {
            id: "wallpaper",
            legacyIndex: 3,
            label: "Wallpaper",
            shortLabel: "Wallpaper",
            description: "Choose wallpapers, folders, and dynamic theming inputs.",
            pageStyle: "catalog",
            icon: "image.svg",
            categoryId: "visuals",
            order: 20,
            component: "WallpaperTab.qml",
            searchTerms: ["wallpaper", "background", "pywal", "matugen", "dynamic", "theming"],
            owner: {
                surface: "",
                service: "WallpaperService",
                configDomain: "wallpaper"
            }
        },
        {
            id: "appearance",
            legacyIndex: 1,
            label: "Style & Motion",
            shortLabel: "Style",
            description: "Adjust glass, typography, density, radii, and animation behavior.",
            pageStyle: "catalog",
            icon: "color-palette.svg",
            categoryId: "visuals",
            order: 30,
            component: "AppearanceTab.qml",
            searchTerms: ["appearance", "glass", "blur", "density", "scale", "spacing", "speed", "animations", "eco", "power", "battery"],
            owner: {
                surface: "bar",
                service: "Config",
                configDomain: "appearance"
            }
        },
        {
            id: "osd",
            legacyIndex: 5,
            label: "OSD",
            shortLabel: "OSD",
            description: "Position and style on-screen display overlays across the shell.",
            pageStyle: "control",
            icon: "speaker-settings.svg",
            categoryId: "interaction",
            order: 10,
            component: "OsdTab.qml",
            searchTerms: ["osd", "overlay", "volume"],
            owner: {
                surface: "osd",
                service: "Config",
                configDomain: "osd"
            }
        },
        {
            id: "time-weather",
            legacyIndex: 16,
            label: "Time & Weather",
            shortLabel: "Time",
            description: "Configure clocks, weather, markets, and live location data.",
            pageStyle: "control",
            icon: "clock.svg",
            categoryId: "interaction",
            order: 20,
            component: "TimeWeatherTab.qml",
            searchTerms: ["time", "clock", "weather"],
            owner: {
                surface: "dateTimeMenu",
                service: "WeatherService",
                configDomain: "timeWeather"
            }
        },
        {
            id: "hotkeys",
            legacyIndex: 13,
            label: "Keybinds",
            shortLabel: "Keybinds",
            description: "Search, review, and reason about keyboard bindings across the shell.",
            pageStyle: "control",
            icon: "keyboard-settings.svg",
            categoryId: "interaction",
            order: 30,
            component: "HotkeysTab.qml",
            searchTerms: ["keys", "shortcuts", "bindings", "cheatsheet"],
            owner: {
                surface: "",
                service: "Config",
                configDomain: "hotkeys"
            }
        },
        {
            id: "notifications",
            legacyIndex: 17,
            label: "Notifications",
            shortLabel: "Notifications",
            description: "Tune popup layout, history, timeout behavior, and notification rules.",
            pageStyle: "control",
            icon: "alert.svg",
            categoryId: "interaction",
            order: 40,
            component: "NotificationsTab.qml",
            searchTerms: ["notifications", "popup", "urgency", "history", "rules"],
            owner: {
                surface: "notifCenter",
                service: "Config",
                configDomain: "notifications"
            }
        },
        {
            id: "audio",
            legacyIndex: 18,
            label: "Audio",
            shortLabel: "Audio",
            description: "Manage audio safeguards, device visibility, and pinned devices.",
            pageStyle: "control",
            icon: "speaker.svg",
            categoryId: "interaction",
            order: 50,
            component: "AudioTab.qml",
            searchTerms: ["audio", "volume", "device", "pin", "hide"],
            owner: {
                surface: "audioMenu",
                service: "AudioService",
                configDomain: "audio"
            }
        },
        {
            id: "screenshot",
            label: "Screenshot",
            shortLabel: "Screenshot",
            description: "Editor, capture delay, OCR language, and screenshot history.",
            pageStyle: "control",
            icon: "fullscreen.svg",
            categoryId: "interaction",
            order: 55,
            component: "ScreenshotTab.qml",
            searchTerms: ["screenshot", "capture", "swappy", "satty", "editor", "ocr", "delay"],
            owner: {
                surface: "",
                service: "ScreenshotService",
                configDomain: "screenshot"
            }
        },
        {
            id: "recording",
            label: "Recording",
            shortLabel: "Recording",
            description: "Configure screen recording capture, audio sources, and output storage.",
            pageStyle: "control",
            icon: "video.svg",
            categoryId: "interaction",
            order: 60,
            component: "RecordingTab.qml",
            searchTerms: ["recording", "screen recorder", "gpu-screen-recorder", "portal", "fps", "cursor"],
            owner: {
                surface: "recordingMenu",
                service: "RecordingService",
                configDomain: "recording"
            }
        },
        {
            id: "bars",
            legacyIndex: 6,
            label: "Bar Layout",
            shortLabel: "Bars",
            description: "Manage bar instances, monitor placement, and per-bar layout settings.",
            pageStyle: "surface",
            icon: "layout-row.svg",
            categoryId: "surfaces",
            order: 10,
            component: "BarTab.qml",
            searchTerms: ["bar", "bars", "multi bar", "display assignment"],
            owner: {
                surface: "bar",
                service: "Config",
                configDomain: "bars"
            }
        },
        {
            id: "bar-widgets",
            legacyIndex: 7,
            label: "Bar Widgets",
            shortLabel: "Widgets",
            description: "Arrange bar widget instances, sections, and placement rules.",
            pageStyle: "surface",
            icon: "grid.svg",
            categoryId: "surfaces",
            order: 20,
            component: "BarWidgetsTab.qml",
            searchTerms: ["bar widgets", "widgets", "sections"],
            owner: {
                surface: "bar",
                service: "BarWidgetRegistry",
                configDomain: "barWidgets"
            }
        },
        {
            id: "dock",
            legacyIndex: 8,
            label: "Dock",
            shortLabel: "Dock",
            description: "Configure dock behavior, layout, and pinned destinations.",
            pageStyle: "surface",
            icon: "dock.svg",
            categoryId: "surfaces",
            order: 30,
            component: "DockTab.qml",
            searchTerms: ["dock", "pinned", "apps"],
            owner: {
                surface: "dock",
                service: "Config",
                configDomain: "dock"
            }
        },
        {
            id: "widgets",
            legacyIndex: 9,
            label: "Desktop Widgets",
            shortLabel: "Desktop",
            description: "Manage desktop widget surfaces and their placement behavior.",
            pageStyle: "surface",
            icon: "widgets.svg",
            categoryId: "surfaces",
            order: 40,
            component: "WidgetsTab.qml",
            searchTerms: ["widgets", "desktop"],
            owner: {
                surface: "desktopWidgets",
                service: "DesktopWidgetRegistry",
                configDomain: "desktopWidgets"
            }
        },
        {
            id: "background",
            label: "Background",
            shortLabel: "Background",
            description: "Control background layers, visualizers, and personality overlays.",
            pageStyle: "surface",
            icon: "image.svg",
            categoryId: "surfaces",
            order: 45,
            component: "BackgroundTab.qml",
            searchTerms: ["background", "visualizer", "clock", "spectrum", "cava", "shader", "glsl", "personality", "cat", "gif"],
            owner: {
                surface: "background",
                service: "Config",
                configDomain: "background"
            }
        },
        {
            id: "lock-screen",
            legacyIndex: 10,
            label: "Lock Screen",
            shortLabel: "Lock",
            description: "Choose lock-screen features and authentication presentation.",
            pageStyle: "surface",
            icon: "lock-closed.svg",
            categoryId: "surfaces",
            order: 50,
            component: "LockScreenTab.qml",
            searchTerms: ["lock", "screen", "auth"],
            owner: {
                surface: "lockscreen",
                service: "Config",
                configDomain: "lockScreen"
            }
        },
        {
            id: "hyprland",
            legacyIndex: 4,
            label: "Hyprland",
            shortLabel: "Hyprland",
            description: "Control display layout, gaps, opacity, and compositor layout defaults.",
            pageStyle: "control",
            icon: "window-multiple.svg",
            categoryId: "window-manager",
            order: 10,
            component: "HyprlandTab.qml",
            compositor: "hyprland",
            searchTerms: ["hyprland", "gaps", "opacity", "layout"],
            owner: {
                surface: "",
                service: "SettingsHub",
                configDomain: "hyprland"
            }
        },
        {
            id: "workspaces",
            legacyIndex: 19,
            label: "Workspaces",
            shortLabel: "Workspaces",
            description: "Adjust workspace display, scroll behavior, and auxiliary features.",
            pageStyle: "control",
            icon: "window-multiple.svg",
            categoryId: "window-manager",
            order: 20,
            component: "WorkspaceTab.qml",
            searchTerms: ["workspaces", "workspace", "scroll", "pill"],
            owner: {
                surface: "",
                service: "Config",
                configDomain: "workspaces"
            }
        },
        {
            id: "privacy",
            legacyIndex: 11,
            label: "Privacy",
            shortLabel: "Privacy",
            description: "Manage privacy indicators and capture-related disclosure surfaces.",
            pageStyle: "control",
            icon: "shield.svg",
            categoryId: "power-privacy",
            order: 10,
            component: "PrivacyTab.qml",
            searchTerms: ["privacy", "camera", "mic"],
            owner: {
                surface: "privacyMenu",
                service: "PrivacyService",
                configDomain: "privacy"
            }
        },
        {
            id: "power",
            legacyIndex: 12,
            label: "Power",
            shortLabel: "Power",
            description: "Set power-menu behavior, display policies, and battery profiles.",
            pageStyle: "control",
            icon: "power.svg",
            categoryId: "power-privacy",
            order: 20,
            component: "PowerTab.qml",
            searchTerms: ["power", "battery"],
            owner: {
                surface: "powerMenu",
                service: "Config",
                configDomain: "power"
            }
        },
        {
            id: "night-light",
            legacyIndex: 20,
            label: "Night Light",
            shortLabel: "Night Light",
            description: "Control color temperature and automatic scheduling for eye comfort.",
            pageStyle: "control",
            icon: "weather-moon.svg",
            categoryId: "power-privacy",
            order: 30,
            component: "NightLightTab.qml",
            searchTerms: ["night", "light", "gamma", "blue", "temperature", "schedule"],
            owner: {
                surface: "",
                service: "NightLightService",
                configDomain: "nightLight"
            }
        },
        {
            id: "plugins",
            legacyIndex: 14,
            label: "Plugins",
            shortLabel: "Plugins",
            description: "Enable installed plugins and manage plugin installation sources.",
            pageStyle: "catalog",
            icon: "apps.svg",
            categoryId: "extensibility",
            order: 10,
            component: "PluginsTab.qml",
            searchTerms: ["plugins", "extensions"],
            owner: {
                surface: "",
                service: "PluginService",
                configDomain: "plugins"
            }
        },
        {
            id: "hooks",
            legacyIndex: 22,
            label: "Hooks",
            shortLabel: "Hooks",
            description: "Configure automation hooks and inspect installed event-driven scripts.",
            pageStyle: "catalog",
            icon: "code.svg",
            categoryId: "extensibility",
            order: 20,
            component: "HooksTab.qml",
            searchTerms: ["hooks", "scripts", "events", "automation"],
            owner: {
                surface: "",
                service: "HookService",
                configDomain: "hooks"
            }
        },
        {
            id: "ai",
            legacyIndex: 23,
            label: "AI Assistant",
            shortLabel: "AI",
            description: "Choose providers, keys, prompts, and generation defaults for AI features.",
            pageStyle: "catalog",
            icon: "chat.svg",
            categoryId: "extensibility",
            order: 30,
            component: "AiTab.qml",
            searchTerms: ["ai", "chat", "assistant", "ollama", "anthropic", "openai", "gemini", "llm"],
            owner: {
                surface: "aiChat",
                service: "AiService",
                configDomain: "ai"
            }
        },
        {
            id: "model-usage",
            label: "AI Model Usage",
            shortLabel: "Usage",
            description: "Enable provider tabs and control which AI usage popup surfaces are available.",
            pageStyle: "catalog",
            icon: "board.svg",
            categoryId: "extensibility",
            order: 40,
            component: "ModelUsageTab.qml",
            searchTerms: ["model", "usage", "claude", "codex", "gemini", "tokens", "prompts", "rate limit"],
            owner: {
                surface: "modelUsageMenu",
                service: "ModelUsageService",
                configDomain: "modelUsage"
            }
        },
        {
            id: "unifi",
            label: "UniFi",
            shortLabel: "UniFi",
            description: "Configure UniFi cloud API and Protect controller connections for network monitoring and camera feeds.",
            pageStyle: "catalog",
            icon: "brands/ubiquiti-symbolic.svg",
            categoryId: "extensibility",
            order: 50,
            component: "UnifiTab.qml",
            searchTerms: ["unifi", "ubiquiti", "network", "protect", "camera", "api", "devices"],
            owner: {
                surface: "unifiNetworkMenu",
                service: "UnifiNetworkService",
                configDomain: "unifi"
            }
        },
        {
            id: "forge",
            label: "Forge",
            shortLabel: "Forge",
            description: "Configure GitHub and GitLab notifications and todo monitoring.",
            pageStyle: "catalog",
            icon: "brands/github-symbolic.svg",
            categoryId: "extensibility",
            order: 60,
            component: "ForgeTab.qml",
            searchTerms: ["forge", "github", "gitlab", "notifications", "token"],
            owner: {
                surface: "",
                service: "ForgeService",
                configDomain: "forge"
            }
        },
        {
            id: "health",
            label: "Diagnostics",
            shortLabel: "Diagnostics",
            description: "Review shell incidents, vitals, and recovery actions.",
            pageStyle: "utility",
            icon: "heart-pulse.svg",
            categoryId: "meta",
            order: 10,
            component: "HealthTab.qml",
            searchTerms: ["health", "status", "incidents", "diagnostics", "vitals"],
            owner: {
                surface: "",
                service: "SystemStatus",
                configDomain: "health"
            }
        },
        {
            id: "about",
            legacyIndex: 15,
            label: "About",
            shortLabel: "About",
            description: "Inspect shell identity, host information, and runtime details.",
            pageStyle: "utility",
            icon: "info.svg",
            categoryId: "meta",
            order: 20,
            component: "AboutTab.qml",
            searchTerms: ["about", "version"],
            owner: {
                surface: "",
                service: "Config",
                configDomain: "about"
            }
        },
        {
            id: "presets",
            legacyIndex: 21,
            label: "Presets",
            shortLabel: "Presets",
            description: "Save, restore, and inspect reusable shell configuration snapshots.",
            pageStyle: "catalog",
            icon: "save.svg",
            categoryId: "meta",
            order: 30,
            component: "PresetsTab.qml",
            searchTerms: ["presets", "save", "load", "snapshot", "backup"],
            owner: {
                surface: "",
                service: "PresetService",
                configDomain: "presets"
            }
        }
    ]

    function isTabSupported(tab) {
        if (!tab)
            return false;
        var needs = tab.compositor || "any";
        return CompositorAdapter.matchesCompositorTag(needs);
    }

    function supportedTabs() {
        var out = [];
        for (var i = 0; i < tabs.length; i++) {
            if (isTabSupported(tabs[i]))
                out.push(tabs[i]);
        }
        return out;
    }

    function findDeclaredTab(tabId) {
        for (var i = 0; i < tabs.length; i++) {
            if (tabs[i].id === tabId)
                return tabs[i];
        }
        return null;
    }

    function sortedCategories() {
        return categories.slice().sort(function(a, b) {
            return (a.order || 0) - (b.order || 0);
        }).filter(function(category) {
            return tabsForCategory(category.id).length > 0;
        });
    }

    function findCategory(categoryId) {
        for (var i = 0; i < categories.length; i++) {
            if (categories[i].id === categoryId)
                return categories[i];
        }
        return null;
    }

    function tabsForCategory(categoryId) {
        return supportedTabs().filter(function(tab) {
            return tab.categoryId === categoryId;
        }).sort(function(a, b) {
            return (a.order || 0) - (b.order || 0);
        });
    }

    function findTab(tabId) {
        var supported = supportedTabs();
        for (var i = 0; i < supported.length; i++) {
            if (supported[i].id === tabId)
                return supported[i];
        }
        return null;
    }

    function categoryForTab(tabId) {
        var tab = findTab(tabId);
        return tab ? findCategory(tab.categoryId) : null;
    }

    function relatedTabsFor(tabId, limit) {
        var tab = findTab(tabId);
        if (!tab)
            return [];

        var out = [];
        var seen = {};
        var preferred = tab.relatedTabs || [];
        var maxItems = limit !== undefined ? Math.max(0, Number(limit) || 0) : 4;

        function pushTab(candidateId) {
            var candidate = findTab(candidateId);
            if (!candidate || candidate.id === tab.id || seen[candidate.id])
                return;
            seen[candidate.id] = true;
            out.push(candidate);
        }

        for (var i = 0; i < preferred.length; i++)
            pushTab(preferred[i]);

        var siblings = tabsForCategory(tab.categoryId);
        for (var j = 0; j < siblings.length; j++)
            pushTab(siblings[j].id);

        return maxItems > 0 ? out.slice(0, maxItems) : out;
    }

    function tabIdForIndex(index) {
        var supported = supportedTabs();
        for (var i = 0; i < supported.length; i++) {
            if (supported[i].legacyIndex === index)
                return supported[i].id;
        }
        return "";
    }

    function indexForTabId(tabId) {
        var supported = supportedTabs();
        for (var i = 0; i < supported.length; i++) {
            if (supported[i].id === tabId)
                return supported[i].legacyIndex !== undefined ? supported[i].legacyIndex : i;
        }
        return 0;
    }

    function searchTabs(query) {
        var q = String(query || "").trim().toLowerCase();
        if (!q)
            return [];

        var results = [];
        var supported = supportedTabs();
        for (var i = 0; i < supported.length; i++) {
            var tab = supported[i];
            var category = findCategory(tab.categoryId);
            var haystack = [
                tab.label,
                tab.shortLabel || "",
                tab.description || "",
                category ? category.label : "",
                category && category.description ? category.description : "",
                (tab.searchTerms || []).join(" ")
            ].join(" ").toLowerCase();
            if (haystack.indexOf(q) !== -1)
                results.push(tab);
        }
        return results;
    }

    function searchSettings(query) {
        return SearchIndex.searchSettings(query).filter(function(result) {
            return findTab(result.tabId) !== null;
        });
    }

    function validateRegistry() {
        var seenTabIds = {};
        var seenLegacy = {};
        var categoryIds = {};

        for (var i = 0; i < categories.length; i++) {
            var category = categories[i];
            if (!category.id)
                Logger.w("SettingsRegistry", "category missing id at index " + i);
            if (categoryIds[category.id])
                Logger.w("SettingsRegistry", "duplicate category id '" + category.id + "'");
            categoryIds[category.id] = true;
        }

        for (var j = 0; j < tabs.length; j++) {
            var tab = tabs[j];
            if (!tab.id)
                Logger.w("SettingsRegistry", "tab missing id at index " + j);
            if (seenTabIds[tab.id])
                Logger.w("SettingsRegistry", "duplicate tab id '" + tab.id + "'");
            seenTabIds[tab.id] = true;

            if (!tab.categoryId || !categoryIds[tab.categoryId])
                Logger.w("SettingsRegistry", "tab '" + tab.id + "' references unknown category '" + tab.categoryId + "'");

            if (!tab.component)
                Logger.w("SettingsRegistry", "tab '" + tab.id + "' missing component");

            if (tab.legacyIndex !== undefined) {
                if (seenLegacy[tab.legacyIndex] !== undefined)
                    Logger.w("SettingsRegistry", "duplicate legacyIndex " + tab.legacyIndex + " for tabs '" + seenLegacy[tab.legacyIndex] + "' and '" + tab.id + "'");
                seenLegacy[tab.legacyIndex] = tab.id;
            }
        }

        if (!findTab(defaultTabId))
            Logger.w("SettingsRegistry", "defaultTabId '" + defaultTabId + "' not found");

        SearchIndex.validateIndex(findDeclaredTab);
    }

    Component.onCompleted: validateRegistry()
}
