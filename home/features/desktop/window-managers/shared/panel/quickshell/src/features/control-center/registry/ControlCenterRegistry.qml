pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../../../services" as Services
import "../../../services/ShellUtils.js" as SU

QtObject {
    id: root

    // --- Quick Link Catalog (all available links, including new ones) ---
    readonly property var quickLinkCatalog: Services.SystemActionRegistry.actionsByIds([
        "audioControls",
        "networkControls",
        "vpnControls"
    ]).concat([
        {
            id: "screenshotControls",
            icon: "crop.svg",
            title: "Screenshot",
            subtitle: "Capture region, screen, or fullscreen",
            clickCommand: SU.ipcCall("Shell", "toggleSurface", "screenshotMenu", "")
        },
        {
            id: "bluetoothControls",
            icon: "bluetooth.svg",
            title: "Bluetooth",
            subtitle: "Paired devices and connections",
            ipcTarget: "Shell",
            ipcAction: "toggleSurface",
            clickCommand: SU.ipcCall("Shell", "toggleSurface", "bluetoothMenu", "")
        },
        {
            id: "displayControls",
            icon: "desktop.svg",
            title: "Display",
            subtitle: "Monitor layout and brightness",
            ipcTarget: "Shell",
            ipcAction: "toggleSurface",
            clickCommand: SU.ipcCall("Shell", "toggleSurface", "displayConfig", "")
        },
        {
            id: "powerControls",
            icon: "battery-full.svg",
            title: "Power",
            subtitle: "Battery and power profile",
            ipcTarget: "Shell",
            ipcAction: "toggleSurface",
            clickCommand: SU.ipcCall("Shell", "toggleSurface", "batteryMenu", "")
        },
        {
            id: "printerControls",
            icon: "print.svg",
            title: "Printer",
            subtitle: "Print queue and devices",
            ipcTarget: "Shell",
            ipcAction: "toggleSurface",
            clickCommand: SU.ipcCall("Shell", "toggleSurface", "printerMenu", "")
        },
        {
            id: "systemMonitorControls",
            icon: "developer-board.svg",
            title: "System Monitor",
            subtitle: "Resources and processes",
            ipcTarget: "Shell",
            ipcAction: "toggleSurface",
            clickCommand: SU.ipcCall("Shell", "toggleSurface", "systemMonitor", "")
        }
    ])

    // Backward-compatible alias (original 4 links)
    readonly property var quickLinkItems: quickLinkCatalog

    readonly property var visibleQuickLinkItems: (function() {
        void Services.Config.controlCenterQuickLinkOrder;
        void Services.Config.controlCenterHiddenQuickLinks;
        return orderedQuickLinkItems();
    })()

    function quickLinkMeta(linkId) {
        var id = String(linkId || "");
        for (var i = 0; i < quickLinkCatalog.length; i++) {
            if (quickLinkCatalog[i].id === id)
                return quickLinkCatalog[i];
        }
        return null;
    }

    function orderedQuickLinkItems() {
        var hidden = Array.isArray(Services.Config.controlCenterHiddenQuickLinks) ? Services.Config.controlCenterHiddenQuickLinks : [];
        var order = Array.isArray(Services.Config.controlCenterQuickLinkOrder) ? Services.Config.controlCenterQuickLinkOrder : [];
        var seen = ({});
        var items = [];
        var i;

        for (i = 0; i < order.length; i++) {
            var ordered = quickLinkMeta(order[i]);
            if (!ordered || seen[ordered.id] || hidden.indexOf(ordered.id) !== -1)
                continue;
            seen[ordered.id] = true;
            items.push(ordered);
        }

        for (i = 0; i < quickLinkCatalog.length; i++) {
            var fallback = quickLinkCatalog[i];
            if (seen[fallback.id] || hidden.indexOf(fallback.id) !== -1)
                continue;
            seen[fallback.id] = true;
            items.push(fallback);
        }

        return items;
    }

    // --- Quick Toggle Catalog ---
    readonly property var quickToggleItems: [
        {
            id: "bluetooth",
            icon: "bluetooth.svg",
            label: "Bluetooth"
        },
        {
            id: "dnd",
            icon: "alert-off.svg",
            label: "DND"
        },
        {
            id: "nightLight",
            icon: "weather-moon.svg",
            label: "Night Light"
        },
        {
            id: "caffeine",
            icon: "drink-coffee.svg",
            label: "Caffeine"
        },
        {
            id: "recording",
            icon: "record.svg",
            label: "Recording"
        },
        {
            id: "gameMode",
            icon: "games.svg",
            label: "Game Mode"
        }
    ]
    readonly property var visibleQuickToggleItems: (function() {
        void Services.Config.controlCenterToggleOrder;
        void Services.Config.controlCenterHiddenToggles;
        return orderedQuickToggleItems();
    })()

    function toggleMeta(toggleId) {
        var id = String(toggleId || "");
        for (var i = 0; i < quickToggleItems.length; i++) {
            if (quickToggleItems[i].id === id)
                return quickToggleItems[i];
        }
        return null;
    }

    function orderedQuickToggleItems() {
        var hidden = Array.isArray(Services.Config.controlCenterHiddenToggles) ? Services.Config.controlCenterHiddenToggles : [];
        var order = Array.isArray(Services.Config.controlCenterToggleOrder) ? Services.Config.controlCenterToggleOrder : [];
        var seen = ({});
        var items = [];
        var i;

        for (i = 0; i < order.length; i++) {
            var ordered = toggleMeta(order[i]);
            if (!ordered || seen[ordered.id] || hidden.indexOf(ordered.id) !== -1)
                continue;
            seen[ordered.id] = true;
            items.push(ordered);
        }

        for (i = 0; i < quickToggleItems.length; i++) {
            var fallback = quickToggleItems[i];
            if (seen[fallback.id] || hidden.indexOf(fallback.id) !== -1)
                continue;
            seen[fallback.id] = true;
            items.push(fallback);
        }

        return items;
    }

    function quickToggleActive(toggleId, manager) {
        switch (String(toggleId || "")) {
        case "bluetooth":
            return !!(Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled);
        case "dnd":
            return !!(manager && manager.dndEnabled);
        case "nightLight":
            return Services.NightLightService.active;
        case "caffeine":
            return Services.IdleService.inhibiting;
        case "recording":
            return Services.RecordingService.isRecording;
        case "gameMode":
            return Services.GameModeService.active;
        default:
            return false;
        }
    }

    function toggleQuickToggle(toggleId, manager) {
        switch (String(toggleId || "")) {
        case "bluetooth":
            if (Bluetooth.defaultAdapter)
                Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
            return;
        case "dnd":
            if (manager)
                manager.dndEnabled = !manager.dndEnabled;
            return;
        case "nightLight":
            Services.NightLightService.toggle();
            return;
        case "caffeine":
            Services.IdleService.toggle();
            return;
        case "recording":
            if (Services.RecordingService.isRecording)
                Services.RecordingService.stopRecording();
            else
                Services.RecordingService.startRecording();
            return;
        case "gameMode":
            Services.GameModeService.toggle();
            return;
        }
    }

    // --- Widget Catalog (Command Center Widgets) ---
    readonly property var widgetCatalog: [
        { id: "mediaWidget",    icon: "music-note-2.svg",     label: "Media Widget",    configKey: "controlCenterShowMediaWidget" },
        { id: "pomodoro",       icon: "timer.svg",            label: "Pomodoro Timer",  configKey: "controlCenterShowPomodoro" },
        { id: "todo",           icon: "checkbox-checked.svg", label: "Todo List",       configKey: "controlCenterShowTodo" },
        { id: "devOps",         icon: "terminal-filled.svg",  label: "DevOps Section",  configKey: "controlCenterShowDevOps" },
        { id: "brightness",     icon: "weather-sunny.svg",    label: "Brightness",      configKey: "controlCenterShowBrightness" },
        { id: "audioOutput",    icon: "speaker.svg",          label: "Audio Output",    configKey: "controlCenterShowAudioOutput" },
        { id: "audioInput",     icon: "mic.svg",              label: "Audio Input",     configKey: "controlCenterShowAudioInput" },
        { id: "cpuGpuTemp",     icon: "temperature.svg",      label: "CPU / GPU Temp",  configKey: "controlCenterShowCpuGpuTemp" },
        { id: "cpuWidget",      icon: "developer-board.svg",  label: "CPU Widget",      configKey: "controlCenterShowCpuWidget" },
        { id: "systemGraphs",   icon: "developer-board.svg",  label: "System Graphs",   configKey: "controlCenterShowSystemGraphs" },
        { id: "processWidget",  icon: "arrow-sync.svg",       label: "Process Widget",  configKey: "controlCenterShowProcessWidget" },
        { id: "networkGraphs",  icon: "ethernet.svg",         label: "Network Graphs",  configKey: "controlCenterShowNetworkGraphs" },
        { id: "ramWidget",      icon: "board.svg",            label: "RAM Widget",      configKey: "controlCenterShowRamWidget" },
        { id: "diskWidget",     icon: "hard-drive.svg",       label: "Disk Widget",     configKey: "controlCenterShowDiskWidget" },
        { id: "gpuWidget",      icon: "developer-board.svg",  label: "GPU Widget",      configKey: "controlCenterShowGpuWidget" },
        { id: "updateWidget",   icon: "arrow-sync.svg",       label: "Update Widget",   configKey: "controlCenterShowUpdateWidget" },
        { id: "scratchpad",     icon: "edit.svg",             label: "Scratchpad",      configKey: "controlCenterShowScratchpad" },
        { id: "powerActions",   icon: "power.svg",            label: "Power Actions",   configKey: "controlCenterShowPowerActions" }
    ]

    // Explicit dependency on all widget visibility bools + ordering for reactive updates
    readonly property var visibleWidgetItems: (function() {
        void Services.Config.controlCenterWidgetOrder;
        void Services.Config.controlCenterShowMediaWidget;
        void Services.Config.controlCenterShowPomodoro;
        void Services.Config.controlCenterShowTodo;
        void Services.Config.controlCenterShowDevOps;
        void Services.Config.controlCenterShowBrightness;
        void Services.Config.controlCenterShowAudioOutput;
        void Services.Config.controlCenterShowAudioInput;
        void Services.Config.controlCenterShowCpuGpuTemp;
        void Services.Config.controlCenterShowCpuWidget;
        void Services.Config.controlCenterShowSystemGraphs;
        void Services.Config.controlCenterShowProcessWidget;
        void Services.Config.controlCenterShowNetworkGraphs;
        void Services.Config.controlCenterShowRamWidget;
        void Services.Config.controlCenterShowDiskWidget;
        void Services.Config.controlCenterShowGpuWidget;
        void Services.Config.controlCenterShowUpdateWidget;
        void Services.Config.controlCenterShowScratchpad;
        void Services.Config.controlCenterShowPowerActions;
        return orderedWidgetItems();
    })()

    function widgetMeta(widgetId) {
        var id = String(widgetId || "");
        for (var i = 0; i < widgetCatalog.length; i++) {
            if (widgetCatalog[i].id === id)
                return widgetCatalog[i];
        }
        return null;
    }

    function isPinnedFooterWidget(widgetId) {
        return String(widgetId || "") === "powerActions";
    }

    function orderedWidgetItems() {
        var order = Array.isArray(Services.Config.controlCenterWidgetOrder) ? Services.Config.controlCenterWidgetOrder : [];
        var seen = ({});
        var items = [];
        var i;

        for (i = 0; i < order.length; i++) {
            var ordered = widgetMeta(order[i]);
            if (!ordered || seen[ordered.id])
                continue;
            if (isPinnedFooterWidget(ordered.id))
                continue;
            // Check visibility via the per-widget config bool
            if (ordered.configKey && Services.Config[ordered.configKey] === false)
                continue;
            seen[ordered.id] = true;
            items.push(ordered);
        }

        for (i = 0; i < widgetCatalog.length; i++) {
            var fallback = widgetCatalog[i];
            if (seen[fallback.id])
                continue;
            if (isPinnedFooterWidget(fallback.id))
                continue;
            if (fallback.configKey && Services.Config[fallback.configKey] === false)
                continue;
            seen[fallback.id] = true;
            items.push(fallback);
        }

        return items;
    }

    // All widgets in order (including hidden) — for settings UI
    function allOrderedWidgetItems() {
        var order = Array.isArray(Services.Config.controlCenterWidgetOrder) ? Services.Config.controlCenterWidgetOrder : [];
        var seen = ({});
        var items = [];
        var i;

        for (i = 0; i < order.length; i++) {
            var ordered = widgetMeta(order[i]);
            if (!ordered || seen[ordered.id])
                continue;
            if (isPinnedFooterWidget(ordered.id))
                continue;
            seen[ordered.id] = true;
            items.push(ordered);
        }

        for (i = 0; i < widgetCatalog.length; i++) {
            var fallback = widgetCatalog[i];
            if (seen[fallback.id])
                continue;
            if (isPinnedFooterWidget(fallback.id))
                continue;
            seen[fallback.id] = true;
            items.push(fallback);
        }

        return items;
    }

    // All quick links in order (including hidden) — for settings UI
    function allOrderedQuickLinkItems() {
        var order = Array.isArray(Services.Config.controlCenterQuickLinkOrder) ? Services.Config.controlCenterQuickLinkOrder : [];
        var seen = ({});
        var items = [];
        var i;

        for (i = 0; i < order.length; i++) {
            var ordered = quickLinkMeta(order[i]);
            if (!ordered || seen[ordered.id])
                continue;
            seen[ordered.id] = true;
            items.push(ordered);
        }

        for (i = 0; i < quickLinkCatalog.length; i++) {
            var fallback = quickLinkCatalog[i];
            if (seen[fallback.id])
                continue;
            seen[fallback.id] = true;
            items.push(fallback);
        }

        return items;
    }
}
