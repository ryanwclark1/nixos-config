.pragma library

// Per-setting search index for SettingsHub.
// Each entry maps a single setting to its tab + card for scroll-to navigation.
// Maintained manually — update when adding/removing Settings*Row components.
//
// Fields:
//   tabId      — SettingsRegistry tab id
//   cardTitle  — SettingsCard title (used for tree-walk scroll target)
//   label      — Setting label text (displayed in results, used for highlight)
//   keywords   — Extra search terms (space-separated)
//   type       — "toggle" | "slider" | "mode" | "select" | "text" | "color"

var entries = [
    // ── Appearance ───────────────────────────────────
    { tabId: "appearance", cardTitle: "Glass Surface", label: "Base Opacity", keywords: "glass transparency", type: "slider" },
    { tabId: "appearance", cardTitle: "Glass Surface", label: "Surface Opacity", keywords: "glass surface", type: "slider" },
    { tabId: "appearance", cardTitle: "Glass Surface", label: "Overlay Opacity", keywords: "glass overlay", type: "slider" },
    { tabId: "appearance", cardTitle: "Glass Surface", label: "Blur", keywords: "blur effects gaussian", type: "mode" },
    { tabId: "appearance", cardTitle: "Glass Surface", label: "Auto Transparency", keywords: "transparency automatic", type: "toggle" },
    { tabId: "appearance", cardTitle: "Theme Mode", label: "Color Backend", keywords: "pywal matugen material you dynamic color", type: "mode" },
    { tabId: "appearance", cardTitle: "Theme Mode", label: "Dynamic Wallpaper Theming", keywords: "pywal theme wallpaper", type: "toggle" },
    { tabId: "appearance", cardTitle: "Theme Mode", label: "OLED Mode", keywords: "oled amoled black display power", type: "toggle" },
    { tabId: "appearance", cardTitle: "Screen Decorations", label: "Screen Corners", keywords: "rounded corners screen decoration", type: "toggle" },
    { tabId: "appearance", cardTitle: "Screen Decorations", label: "Corner Radius", keywords: "rounded corners radius size", type: "slider" },
    { tabId: "appearance", cardTitle: "Screen Decorations", label: "Screen Borders", keywords: "screen border frame decoration", type: "toggle" },
    { tabId: "appearance", cardTitle: "Performance", label: "Automatic Eco Mode", keywords: "eco power battery", type: "toggle" },
    { tabId: "appearance", cardTitle: "Performance", label: "Blur", keywords: "blur effects gaussian performance", type: "mode" },
    { tabId: "appearance", cardTitle: "Performance", label: "Weather Overlay Shaders", keywords: "weather rain snow fog shader gpu", type: "toggle" },
    { tabId: "appearance", cardTitle: "Performance", label: "Background Visualizer", keywords: "visualizer audio cava performance", type: "toggle" },
    { tabId: "appearance", cardTitle: "Typography", label: "Primary Font Family", keywords: "font family text", type: "text" },
    { tabId: "appearance", cardTitle: "Typography", label: "Monospace Font Family", keywords: "font monospace code", type: "text" },
    { tabId: "appearance", cardTitle: "Typography", label: "Font Scale", keywords: "font size scale", type: "slider" },
    { tabId: "appearance", cardTitle: "Shape & Density", label: "Corner Radius Scale", keywords: "radius rounded corners", type: "slider" },
    { tabId: "appearance", cardTitle: "Shape & Density", label: "UI Density Scale", keywords: "density spacing compact", type: "slider" },
    { tabId: "appearance", cardTitle: "Shape & Density", label: "Animation Speed Scale", keywords: "animation speed duration", type: "slider" },

    // ── Shell ────────────────────────────────────────
    { tabId: "system", cardTitle: "Shell", label: "Floating Bar", keywords: "bar floating dock", type: "toggle" },
    { tabId: "system", cardTitle: "Shell", label: "Blur Effects", keywords: "blur glass", type: "toggle" },
    { tabId: "system", cardTitle: "Shell", label: "Debug Logging", keywords: "debug log verbose", type: "toggle" },
    { tabId: "system", cardTitle: "Shell", label: "Notification Center Width", keywords: "notification popup width", type: "slider" },
    { tabId: "system", cardTitle: "Shell", label: "Popup Duration", keywords: "notification popup timeout duration", type: "slider" },
    { tabId: "system", cardTitle: "Panel Enablement", label: "Notification Center", keywords: "panel enable disable memory", type: "toggle" },
    { tabId: "system", cardTitle: "Panel Enablement", label: "Control Center", keywords: "panel enable disable memory", type: "toggle" },
    { tabId: "system", cardTitle: "Panel Enablement", label: "Notepad", keywords: "panel enable disable memory", type: "toggle" },
    { tabId: "system", cardTitle: "Panel Enablement", label: "AI Chat", keywords: "panel enable disable memory", type: "toggle" },
    { tabId: "system", cardTitle: "Panel Enablement", label: "Command Palette", keywords: "panel enable disable memory", type: "toggle" },
    { tabId: "system", cardTitle: "Panel Enablement", label: "Power Menu", keywords: "panel enable disable memory", type: "toggle" },
    { tabId: "system", cardTitle: "Panel Enablement", label: "Color Picker", keywords: "panel enable disable memory", type: "toggle" },
    { tabId: "system", cardTitle: "Panel Enablement", label: "Display Config", keywords: "panel enable disable memory", type: "toggle" },
    { tabId: "system", cardTitle: "Panel Enablement", label: "File Browser", keywords: "panel enable disable memory", type: "toggle" },
    { tabId: "system", cardTitle: "Panel Enablement", label: "System Monitor", keywords: "panel enable disable memory", type: "toggle" },

    // ── Control Center ───────────────────────────────
    { tabId: "control-center", cardTitle: "Control Center", label: "Quick Links", keywords: "links shortcuts", type: "toggle" },
    { tabId: "control-center", cardTitle: "Control Center", label: "Media Widget", keywords: "media player music", type: "toggle" },
    { tabId: "control-center", cardTitle: "Control Center", label: "Control Center Width", keywords: "width size", type: "slider" },

    // ── OSD ──────────────────────────────────────────
    { tabId: "osd", cardTitle: "Position", label: "Screen Position", keywords: "osd position corner", type: "mode" },
    { tabId: "osd", cardTitle: "Style", label: "Display Style", keywords: "osd style circular pill", type: "mode" },
    { tabId: "osd", cardTitle: "Style", label: "Volume Overdrive", keywords: "volume overdrive boost", type: "toggle" },
    { tabId: "osd", cardTitle: "Timing & Size", label: "OSD Duration", keywords: "timeout duration display time", type: "slider" },
    { tabId: "osd", cardTitle: "Timing & Size", label: "OSD Size", keywords: "size scale", type: "slider" },

    // ── Audio ────────────────────────────────────────
    { tabId: "audio", cardTitle: "Volume Protection", label: "Volume Protection", keywords: "volume limit safety", type: "toggle" },
    { tabId: "audio", cardTitle: "Volume Protection", label: "Max Jump", keywords: "volume jump step", type: "slider" },

    // ── Notifications ────────────────────────────────
    { tabId: "notifications", cardTitle: "Popup Position", label: "Screen Corner", keywords: "notification position corner", type: "mode" },
    { tabId: "notifications", cardTitle: "Popup Appearance", label: "Popup Width", keywords: "notification width size", type: "slider" },
    { tabId: "notifications", cardTitle: "Popup Appearance", label: "Compact Style", keywords: "notification compact small", type: "toggle" },
    { tabId: "notifications", cardTitle: "Popup Appearance", label: "Privacy Mode", keywords: "notification privacy hide content", type: "toggle" },
    { tabId: "notifications", cardTitle: "Timeouts", label: "Low Urgency", keywords: "notification timeout low", type: "slider" },
    { tabId: "notifications", cardTitle: "Timeouts", label: "Normal Urgency", keywords: "notification timeout normal", type: "slider" },
    { tabId: "notifications", cardTitle: "Timeouts", label: "Critical Urgency", keywords: "notification timeout critical", type: "slider" },
    { tabId: "notifications", cardTitle: "History", label: "Notification History", keywords: "history persist store", type: "toggle" },
    { tabId: "notifications", cardTitle: "History", label: "Max Stored Count", keywords: "history max count limit", type: "slider" },
    { tabId: "notifications", cardTitle: "History", label: "Max Age", keywords: "history max age expire", type: "slider" },

    // ── Dock ─────────────────────────────────────────
    { tabId: "dock", cardTitle: "Behavior", label: "Dock Enabled", keywords: "dock show hide", type: "toggle" },
    { tabId: "dock", cardTitle: "Behavior", label: "Auto Hide", keywords: "dock auto hide", type: "toggle" },
    { tabId: "dock", cardTitle: "Behavior", label: "Group Windows", keywords: "dock group windows", type: "toggle" },
    { tabId: "dock", cardTitle: "Layout", label: "Dock Position", keywords: "dock position edge", type: "mode" },
    { tabId: "dock", cardTitle: "Layout", label: "Icon Size", keywords: "dock icon size", type: "slider" },

    // ── Privacy ──────────────────────────────────────
    { tabId: "privacy", cardTitle: "Indicators", label: "Privacy Indicators", keywords: "privacy indicator bar", type: "toggle" },
    { tabId: "privacy", cardTitle: "Indicators", label: "Camera Monitoring", keywords: "camera webcam monitor", type: "toggle" },

    // ── Power ────────────────────────────────────────
    { tabId: "power", cardTitle: "Power Menu", label: "Powermenu Countdown", keywords: "powermenu countdown timer", type: "slider" },
    { tabId: "power", cardTitle: "Display", label: "Screen Borders", keywords: "screen border decoration", type: "toggle" },
    { tabId: "power", cardTitle: "Display", label: "Hot Corners", keywords: "hot corners trigger", type: "toggle" },
    { tabId: "power", cardTitle: "Display", label: "Idle Inhibitor", keywords: "idle inhibitor caffeine", type: "toggle" },
    { tabId: "power", cardTitle: "Display", label: "Prevent Idle When Playing", keywords: "idle media playing video", type: "toggle" },
    { tabId: "power", cardTitle: "Battery Alerts", label: "Battery Alerts", keywords: "battery notification alert", type: "toggle" },
    { tabId: "power", cardTitle: "Battery Alerts", label: "Warning Threshold", keywords: "battery warning percent", type: "slider" },
    { tabId: "power", cardTitle: "Battery Alerts", label: "Critical Threshold", keywords: "battery critical percent", type: "slider" },
    { tabId: "power", cardTitle: "AC Power Profile", label: "Monitor Off", keywords: "ac monitor timeout screen off", type: "slider" },
    { tabId: "power", cardTitle: "AC Power Profile", label: "Lock Screen", keywords: "ac lock timeout", type: "slider" },
    { tabId: "power", cardTitle: "AC Power Profile", label: "Suspend", keywords: "ac suspend timeout", type: "slider" },
    { tabId: "power", cardTitle: "AC Power Profile", label: "Suspend Action", keywords: "ac suspend hibernate", type: "mode" },
    { tabId: "power", cardTitle: "Battery Power Profile", label: "Monitor Off", keywords: "battery monitor timeout screen off", type: "slider" },
    { tabId: "power", cardTitle: "Battery Power Profile", label: "Lock Screen", keywords: "battery lock timeout", type: "slider" },
    { tabId: "power", cardTitle: "Battery Power Profile", label: "Suspend", keywords: "battery suspend timeout", type: "slider" },
    { tabId: "power", cardTitle: "Battery Power Profile", label: "Suspend Action", keywords: "battery suspend hibernate", type: "mode" },

    // ── Night Light ──────────────────────────────────
    { tabId: "night-light", cardTitle: "Night Light", label: "Enable Night Light", keywords: "night light blue filter", type: "toggle" },
    { tabId: "night-light", cardTitle: "Night Light", label: "Color Temperature", keywords: "temperature warm cool kelvin", type: "slider" },
    { tabId: "night-light", cardTitle: "Auto Schedule", label: "Auto Schedule", keywords: "night light schedule auto", type: "toggle" },
    { tabId: "night-light", cardTitle: "Auto Schedule", label: "Schedule Mode", keywords: "schedule fixed sunrise sunset", type: "mode" },
    { tabId: "night-light", cardTitle: "Fixed Time Schedule", label: "Start Hour", keywords: "night light start time", type: "slider" },
    { tabId: "night-light", cardTitle: "Fixed Time Schedule", label: "Start Minute", keywords: "night light start", type: "slider" },
    { tabId: "night-light", cardTitle: "Fixed Time Schedule", label: "End Hour", keywords: "night light end time", type: "slider" },
    { tabId: "night-light", cardTitle: "Fixed Time Schedule", label: "End Minute", keywords: "night light end", type: "slider" },
    { tabId: "night-light", cardTitle: "Location", label: "Latitude", keywords: "location latitude", type: "text" },
    { tabId: "night-light", cardTitle: "Location", label: "Longitude", keywords: "location longitude", type: "text" },

    // ── Lock Screen ──────────────────────────────────
    { tabId: "lock-screen", cardTitle: "Features", label: "Compact Mode", keywords: "lock screen compact minimal", type: "toggle" },
    { tabId: "lock-screen", cardTitle: "Features", label: "Media Controls", keywords: "lock screen media player", type: "toggle" },
    { tabId: "lock-screen", cardTitle: "Features", label: "Weather", keywords: "lock screen weather", type: "toggle" },
    { tabId: "lock-screen", cardTitle: "Features", label: "Session Buttons", keywords: "lock screen session power", type: "toggle" },
    { tabId: "lock-screen", cardTitle: "Features", label: "Fingerprint Unlock", keywords: "lock screen fingerprint biometric", type: "toggle" },
    { tabId: "lock-screen", cardTitle: "Features", label: "Lock Countdown", keywords: "lock timeout countdown", type: "slider" },

    // ── Recording ────────────────────────────────────
    { tabId: "recording", cardTitle: "Capture", label: "Capture Source", keywords: "recording source portal screen", type: "mode" },
    { tabId: "recording", cardTitle: "Capture", label: "Frame Rate", keywords: "recording fps framerate", type: "mode" },
    { tabId: "recording", cardTitle: "Capture", label: "Quality", keywords: "recording quality bitrate", type: "mode" },
    { tabId: "recording", cardTitle: "Capture", label: "Record Cursor", keywords: "recording cursor mouse", type: "toggle" },
    { tabId: "recording", cardTitle: "Audio", label: "Desktop Audio", keywords: "recording audio desktop", type: "toggle" },
    { tabId: "recording", cardTitle: "Audio", label: "Microphone", keywords: "recording microphone mic", type: "toggle" },
    { tabId: "recording", cardTitle: "Storage", label: "Output Directory", keywords: "recording output directory path", type: "text" },

    // ── Workspaces ───────────────────────────────────
    { tabId: "workspaces", cardTitle: "Workspace Display", label: "Show Empty Workspaces", keywords: "workspace empty visible", type: "toggle" },
    { tabId: "workspaces", cardTitle: "Workspace Display", label: "Show Workspace Names", keywords: "workspace name label", type: "toggle" },
    { tabId: "workspaces", cardTitle: "Workspace Display", label: "Pill Size", keywords: "workspace pill size compact", type: "mode" },
    { tabId: "workspaces", cardTitle: "App Icons", label: "Show App Icons", keywords: "workspace app icon window", type: "toggle" },
    { tabId: "workspaces", cardTitle: "App Icons", label: "Max Icons Per Pill", keywords: "workspace icon max limit", type: "slider" },
    { tabId: "workspaces", cardTitle: "Scroll Behavior", label: "Scroll to Switch", keywords: "workspace scroll switch", type: "toggle" },
    { tabId: "workspaces", cardTitle: "Scroll Behavior", label: "Reverse Scroll Direction", keywords: "workspace scroll reverse invert", type: "toggle" },
    { tabId: "workspaces", cardTitle: "Notepad", label: "Auto-Switch Tabs by Workspace", keywords: "notepad workspace tabs sync", type: "toggle" },
    { tabId: "workspaces", cardTitle: "Colors", label: "Active Color", keywords: "workspace active color", type: "color" },
    { tabId: "workspaces", cardTitle: "Colors", label: "Urgent Color", keywords: "workspace urgent color", type: "color" },

    // ── Hyprland ─────────────────────────────────────
    { tabId: "hyprland", cardTitle: "Window Layout", label: "Master Layout", keywords: "hyprland layout master dwindle", type: "toggle" },
    { tabId: "hyprland", cardTitle: "Window Layout", label: "Outer Gaps", keywords: "hyprland gaps outer margin", type: "slider" },
    { tabId: "hyprland", cardTitle: "Window Layout", label: "Inner Gaps", keywords: "hyprland gaps inner spacing", type: "slider" },
    { tabId: "hyprland", cardTitle: "Window Layout", label: "Active Opacity", keywords: "hyprland opacity window transparency", type: "slider" },
    { tabId: "hyprland", cardTitle: "Display Profiles", label: "Auto-Apply Profiles", keywords: "display profile monitor auto", type: "toggle" },

    // ── AI ────────────────────────────────────────────
    { tabId: "ai", cardTitle: "Provider", label: "Provider", keywords: "ai provider ollama anthropic openai gemini", type: "select" },
    { tabId: "ai", cardTitle: "Provider", label: "Model", keywords: "ai model llm", type: "text" },
    { tabId: "ai", cardTitle: "Provider", label: "Detected Models", keywords: "ai ollama models available", type: "select" },
    { tabId: "ai", cardTitle: "Provider", label: "Model Override", keywords: "ai ollama model override custom", type: "text" },
    { tabId: "ai", cardTitle: "Provider", label: "Custom Endpoint", keywords: "ai custom endpoint url api", type: "text" },
    { tabId: "ai", cardTitle: "API Keys", label: "Anthropic API Key", keywords: "ai anthropic claude key", type: "text" },
    { tabId: "ai", cardTitle: "API Keys", label: "OpenAI API Key", keywords: "ai openai gpt key", type: "text" },
    { tabId: "ai", cardTitle: "API Keys", label: "Gemini API Key", keywords: "ai gemini google key", type: "text" },
    { tabId: "ai", cardTitle: "Endpoint Override", label: "Base URL", keywords: "ai endpoint base url override proxy", type: "text" },
    { tabId: "ai", cardTitle: "Generation", label: "Temperature", keywords: "ai temperature creativity", type: "slider" },
    { tabId: "ai", cardTitle: "Generation", label: "Max Tokens", keywords: "ai tokens limit output", type: "slider" },
    { tabId: "ai", cardTitle: "Generation", label: "Timeout (seconds)", keywords: "ai timeout request", type: "slider" },
    { tabId: "ai", cardTitle: "System Prompt", label: "Include System Context", keywords: "ai system prompt context", type: "toggle" },
    { tabId: "ai", cardTitle: "System Prompt", label: "Tool Call Auto-Reply", keywords: "ai tool calling command execution auto reply", type: "toggle" },
    { tabId: "ai", cardTitle: "System Prompt", label: "Custom System Prompt", keywords: "ai system prompt custom", type: "text" },
    { tabId: "ai", cardTitle: "Limits", label: "Max Conversations", keywords: "ai conversations limit history", type: "slider" },
    { tabId: "ai", cardTitle: "Limits", label: "Max Messages per Conversation", keywords: "ai messages limit", type: "slider" },

    // ── Bars ─────────────────────────────────────────
    { tabId: "bars", cardTitle: "Modular Layout", label: "Use Modular Entries", keywords: "bar modular layout sections", type: "toggle" },
    { tabId: "bars", cardTitle: "Selected Bar", label: "Bar Name", keywords: "bar name label rename", type: "text" },
    { tabId: "bars", cardTitle: "Selected Bar", label: "Position", keywords: "bar position top bottom", type: "mode" },
    { tabId: "bars", cardTitle: "Selected Bar", label: "Enabled", keywords: "bar enabled disabled active", type: "mode" },
    { tabId: "bars", cardTitle: "Selected Bar", label: "Display Mode", keywords: "bar display monitor screen", type: "mode" },
    { tabId: "bars", cardTitle: "Selected Bar", label: "Thickness", keywords: "bar thickness height size", type: "slider" },
    { tabId: "bars", cardTitle: "Selected Bar", label: "Margin", keywords: "bar margin gap edge", type: "slider" },
    { tabId: "bars", cardTitle: "Selected Bar", label: "Opacity", keywords: "bar opacity transparency alpha", type: "slider" },
    { tabId: "bars", cardTitle: "Selected Bar", label: "Window Mode", keywords: "bar window layer overlay", type: "mode" },
    { tabId: "bars", cardTitle: "Selected Bar", label: "Auto-Hide", keywords: "bar autohide hide show", type: "toggle" },
    { tabId: "bars", cardTitle: "Selected Bar", label: "Auto-Hide Delay", keywords: "bar autohide delay timeout", type: "slider" },
    { tabId: "bars", cardTitle: "Selected Bar", label: "No Background", keywords: "bar background transparent", type: "toggle" },
    { tabId: "bars", cardTitle: "Selected Bar", label: "Hide on Fullscreen", keywords: "bar fullscreen hide", type: "toggle" },
    { tabId: "bars", cardTitle: "Selected Bar", label: "Scroll Behavior", keywords: "bar scroll workspace switch", type: "mode" },
    { tabId: "bars", cardTitle: "Selected Bar", label: "Shadow", keywords: "bar shadow drop elevation", type: "toggle" },
    { tabId: "bars", cardTitle: "Selected Bar", label: "Shadow Opacity", keywords: "bar shadow opacity intensity", type: "slider" },
    { tabId: "bars", cardTitle: "Selected Bar", label: "Font Scale", keywords: "bar font size scale text", type: "slider" },
    { tabId: "bars", cardTitle: "Selected Bar", label: "Icon Scale", keywords: "bar icon size scale", type: "slider" },

    // ── Time & Weather ───────────────────────────────
    { tabId: "time-weather", cardTitle: "Time Format", label: "24-Hour Clock", keywords: "clock 24 hour format", type: "toggle" },
    { tabId: "time-weather", cardTitle: "Time Format", label: "Show Seconds", keywords: "clock seconds display", type: "toggle" },
    { tabId: "time-weather", cardTitle: "Time Format", label: "Show Date In Bar", keywords: "bar date display", type: "toggle" },
    { tabId: "time-weather", cardTitle: "Time Format", label: "Bar Date Style", keywords: "bar date format weekday month", type: "mode" },
    { tabId: "time-weather", cardTitle: "Weather & Location", label: "Units", keywords: "weather units metric imperial celsius fahrenheit", type: "mode" },
    { tabId: "time-weather", cardTitle: "Weather & Location", label: "Animated weather in bar and menus", keywords: "weather animation animated bar menu icon rain snow fog thunder", type: "toggle" },
    { tabId: "time-weather", cardTitle: "Weather & Location", label: "Location Priority", keywords: "weather location priority auto city", type: "mode" },
    { tabId: "time-weather", cardTitle: "Weather & Location", label: "Auto Location", keywords: "weather auto location gps", type: "toggle" },
    { tabId: "time-weather", cardTitle: "Weather & Location", label: "City", keywords: "weather city name", type: "text" },
    { tabId: "time-weather", cardTitle: "Weather & Location", label: "Latitude", keywords: "weather latitude location", type: "text" },
    { tabId: "time-weather", cardTitle: "Weather & Location", label: "Longitude", keywords: "weather longitude location", type: "text" },
    { tabId: "time-weather", cardTitle: "Markets", label: "Tickers", keywords: "stock market ticker symbols", type: "text" },

    // ── Background ───────────────────────────────────
    { tabId: "background", cardTitle: "Desktop Background", label: "Spectrum Visualizer", keywords: "visualizer cava spectrum audio", type: "toggle" },
    { tabId: "background", cardTitle: "Desktop Background", label: "Shader Visualizer", keywords: "visualizer shader gpu", type: "toggle" },
    { tabId: "background", cardTitle: "Desktop Background", label: "Desktop Clock", keywords: "clock desktop time overlay", type: "toggle" },
    { tabId: "background", cardTitle: "Desktop Background", label: "Auto-Hide on Fullscreen", keywords: "fullscreen hide background", type: "toggle" },
    { tabId: "background", cardTitle: "Desktop Background", label: "Clock Position", keywords: "clock position center corner", type: "mode" },
    { tabId: "background", cardTitle: "Personality GIF", label: "Enable GIF", keywords: "gif animated background", type: "toggle" },
    { tabId: "background", cardTitle: "Personality GIF", label: "GIF Path", keywords: "gif file path", type: "text" },
    { tabId: "background", cardTitle: "Personality GIF", label: "Reaction Mode", keywords: "gif reaction media cpu beat", type: "mode" },

    // ── Hooks ────────────────────────────────────────
    { tabId: "hooks", cardTitle: "Hook System", label: "Enable Hooks", keywords: "hooks scripts automation", type: "toggle" },

    // ── Theme ────────────────────────────────────────
    { tabId: "theme", cardTitle: "Auto Schedule", label: "Enable Auto Schedule", keywords: "theme schedule auto dark light", type: "toggle" },
    { tabId: "theme", cardTitle: "Auto Schedule", label: "Schedule Mode", keywords: "theme schedule fixed sunrise sunset", type: "mode" },
    { tabId: "theme", cardTitle: "Auto Schedule", label: "Dark Theme", keywords: "theme dark name", type: "text" },
    { tabId: "theme", cardTitle: "Auto Schedule", label: "Light Theme", keywords: "theme light name", type: "text" },
    { tabId: "theme", cardTitle: "Schedule Times", label: "Dark Mode Hour", keywords: "theme dark time hour", type: "slider" },
    { tabId: "theme", cardTitle: "Schedule Times", label: "Dark Mode Minute", keywords: "theme dark time minute", type: "slider" },
    { tabId: "theme", cardTitle: "Schedule Times", label: "Light Mode Hour", keywords: "theme light time hour", type: "slider" },
    { tabId: "theme", cardTitle: "Schedule Times", label: "Light Mode Minute", keywords: "theme light time minute", type: "slider" },
    { tabId: "theme", cardTitle: "Location", label: "Latitude", keywords: "theme location latitude", type: "text" },
    { tabId: "theme", cardTitle: "Location", label: "Longitude", keywords: "theme location longitude", type: "text" },

    // ── Wallpaper ────────────────────────────────────
    { tabId: "wallpaper", cardTitle: "", label: "Default wallpaper folder", keywords: "wallpaper folder directory path", type: "text" },
    { tabId: "wallpaper", cardTitle: "", label: "Solid color", keywords: "wallpaper solid color hex", type: "text" },
    { tabId: "wallpaper", cardTitle: "", label: "Use solid color on startup", keywords: "wallpaper solid startup", type: "toggle" },
    { tabId: "wallpaper", cardTitle: "", label: "Run pywal on change", keywords: "wallpaper pywal theme colors", type: "toggle" },
    { tabId: "wallpaper", cardTitle: "", label: "Shell-rendered wallpaper", keywords: "wallpaper shell renderer quickshell", type: "toggle" },
    { tabId: "wallpaper", cardTitle: "", label: "Video wallpaper", keywords: "video wallpaper mp4 webm animated", type: "toggle" },
    { tabId: "wallpaper", cardTitle: "", label: "Browse Wallhaven", keywords: "wallhaven browse download online", type: "toggle" },
    { tabId: "wallpaper", cardTitle: "", label: "Transition effect", keywords: "wallpaper transition fade pixelate wipe", type: "select" },
    { tabId: "wallpaper", cardTitle: "", label: "Transition duration", keywords: "wallpaper transition duration speed", type: "slider" },

    // ── Desktop Widgets ──────────────────────────────
    { tabId: "widgets", cardTitle: "Widgets", label: "Desktop Widgets", keywords: "desktop widgets enable", type: "toggle" },
    { tabId: "widgets", cardTitle: "Widgets", label: "Grid Snap", keywords: "widgets grid snap alignment", type: "toggle" },

    // ── Launcher (General) ───────────────────────────
    { tabId: "launcher", cardTitle: "Launcher Behavior", label: "Default Mode", keywords: "launcher default mode start", type: "mode" },
    { tabId: "launcher", cardTitle: "Launcher Behavior", label: "Show Mode Hints", keywords: "launcher hints tips", type: "toggle" },
    { tabId: "launcher", cardTitle: "Launcher Behavior", label: "Keep Query on Mode Switch", keywords: "launcher query persist mode", type: "toggle" },
    { tabId: "launcher", cardTitle: "Launcher Behavior", label: "Paste Characters on Select", keywords: "launcher paste character emoji", type: "toggle" },
    { tabId: "launcher", cardTitle: "Launcher Behavior", label: "Tab Behavior", keywords: "launcher tab contextual results mode", type: "mode" },
    { tabId: "launcher", cardTitle: "Launcher Behavior", label: "Character Trigger", keywords: "launcher character emoji trigger", type: "text" },
    { tabId: "launcher", cardTitle: "Home Layout", label: "Show Home Sections", keywords: "launcher home sections show", type: "toggle" },
    { tabId: "launcher", cardTitle: "Home Layout", label: "App Category Filters", keywords: "launcher category filter apps", type: "toggle" },
    { tabId: "launcher", cardTitle: "Home Layout", label: "Recents History Limit", keywords: "launcher recents history count", type: "slider" },
    { tabId: "launcher", cardTitle: "Home Layout", label: "Recent Apps on Home", keywords: "launcher recent apps home", type: "slider" },
    { tabId: "launcher", cardTitle: "Home Layout", label: "Suggestions on Home", keywords: "launcher suggestions home", type: "slider" },

    // ── Launcher (Search) ────────────────────────────
    { tabId: "launcher-search", cardTitle: "Search Limits", label: "Max Results", keywords: "search results limit", type: "slider" },
    { tabId: "launcher-search", cardTitle: "Search Limits", label: "File Query Min Length", keywords: "file search minimum length", type: "slider" },
    { tabId: "launcher-search", cardTitle: "Search Limits", label: "File Search Max Results", keywords: "file search results limit", type: "slider" },
    { tabId: "launcher-search", cardTitle: "Search Limits", label: "Default Search Directory", keywords: "file search root directory default search directory", type: "text" },
    { tabId: "launcher-search", cardTitle: "Search Limits", label: "Show Hidden Files", keywords: "file search hidden dotfiles", type: "toggle" },
    { tabId: "launcher-search", cardTitle: "Search Limits", label: "File Opener", keywords: "file opener application", type: "text" },
    { tabId: "launcher-search", cardTitle: "Search Limits", label: "File Preview", keywords: "file preview pane toggle", type: "toggle" },
    { tabId: "launcher-search", cardTitle: "Search Limits", label: "Cache TTL", keywords: "search cache ttl expire", type: "slider" },
    { tabId: "launcher-search", cardTitle: "Search Limits", label: "Search Debounce", keywords: "search debounce delay", type: "slider" },
    { tabId: "launcher-search", cardTitle: "Search Limits", label: "File Search Debounce", keywords: "file search debounce delay", type: "slider" },
    { tabId: "launcher-search", cardTitle: "Result Scoring", label: "Name Weight", keywords: "search score name weight", type: "slider" },
    { tabId: "launcher-search", cardTitle: "Result Scoring", label: "Title Weight", keywords: "search score title weight", type: "slider" },
    { tabId: "launcher-search", cardTitle: "Result Scoring", label: "Exec/Class Weight", keywords: "search score exec class weight", type: "slider" },
    { tabId: "launcher-search", cardTitle: "Result Scoring", label: "Body Weight", keywords: "search score body weight", type: "slider" },
    { tabId: "launcher-search", cardTitle: "Result Scoring", label: "Category/Keywords Weight", keywords: "search score category keywords weight", type: "slider" },

    // ── Launcher (Web) ───────────────────────────────
    { tabId: "launcher-web", cardTitle: "Web Search Behavior", label: "Web Enter Uses Primary", keywords: "web search enter primary provider", type: "toggle" },
    { tabId: "launcher-web", cardTitle: "Web Search Behavior", label: "Web Number Hotkeys", keywords: "web number hotkeys provider", type: "toggle" },
    { tabId: "launcher-web", cardTitle: "Web Search Behavior", label: "Remember Web Provider", keywords: "web provider remember persist", type: "toggle" },
    { tabId: "launcher-web", cardTitle: "DuckDuckGo Bangs", label: "Enable !Bangs", keywords: "duckduckgo bangs shortcuts", type: "toggle" },

    // ── Launcher (Runtime) ───────────────────────────
    { tabId: "launcher-runtime", cardTitle: "Runtime Behavior", label: "Background Preload", keywords: "launcher preload cache background", type: "toggle" },
    { tabId: "launcher-runtime", cardTitle: "Runtime Behavior", label: "Debug Launcher Timings", keywords: "launcher debug timing perf", type: "toggle" },
    { tabId: "launcher-runtime", cardTitle: "Runtime Behavior", label: "Show Runtime Metrics", keywords: "launcher runtime metrics stats", type: "toggle" },
    { tabId: "launcher-runtime", cardTitle: "Runtime Behavior", label: "Preload Failure Threshold", keywords: "launcher preload failure threshold", type: "slider" },
    { tabId: "launcher-runtime", cardTitle: "Runtime Behavior", label: "Preload Backoff", keywords: "launcher preload backoff retry", type: "slider" },
];


/**
 * Search settings entries by query.
 * Returns matches sorted by relevance (label match > keyword match).
 */
function searchSettings(query) {
    var q = String(query || "").trim().toLowerCase();
    if (q.length < 2) return [];

    var results = [];
    for (var i = 0; i < entries.length; i++) {
        var e = entries[i];
        var labelLower = e.label.toLowerCase();
        var score = 0;

        // Exact label match is strongest
        if (labelLower === q) {
            score = 100;
        } else if (labelLower.indexOf(q) === 0) {
            score = 80;
        } else if (labelLower.indexOf(q) !== -1) {
            score = 60;
        } else if (e.cardTitle && e.cardTitle.toLowerCase().indexOf(q) !== -1) {
            score = 40;
        } else {
            // Check keywords
            var kw = (e.keywords || "").toLowerCase();
            if (kw.indexOf(q) !== -1) {
                score = 20;
            }
        }

        if (score > 0) {
            results.push({
                tabId: e.tabId,
                cardTitle: e.cardTitle,
                label: e.label,
                type: e.type,
                score: score
            });
        }
    }

    results.sort(function(a, b) { return b.score - a.score; });
    return results.slice(0, 15);
}


/**
 * Validate that all tabIds in the index exist in the registry.
 * Call from SettingsRegistry.validateRegistry().
 */
function validateIndex(findTabFn) {
    var warned = {};
    for (var i = 0; i < entries.length; i++) {
        var tabId = entries[i].tabId;
        if (warned[tabId]) continue;
        if (!findTabFn(tabId)) {
            console.warn("[W][SettingsSearchIndex] entry references unknown tab '" + tabId + "' (label: '" + entries[i].label + "')");
            warned[tabId] = true;
        }
    }
}
