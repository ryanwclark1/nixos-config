pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import "../../../services" as Services

QtObject {
    id: root

    readonly property var quickLinkItems: Services.SystemActionRegistry.actionsByIds([
        "audioControls",
        "networkControls",
        "vpnControls"
    ]).concat([
        {
            id: "screenshotControls",
            icon: "󰩭",
            title: "Screenshot",
            subtitle: "Capture region, screen, or fullscreen",
            clickCommand: ["quickshell", "ipc", "call", "Shell", "toggleSurface", "screenshotMenu"]
        }
    ])

    readonly property var quickToggleItems: [
        {
            id: "bluetooth",
            icon: "󰂯",
            label: "Bluetooth"
        },
        {
            id: "dnd",
            icon: "󰒲",
            label: "DND"
        },
        {
            id: "nightLight",
            icon: "󰖔",
            label: "Night Light"
        },
        {
            id: "caffeine",
            icon: "󰾪",
            label: "Caffeine"
        },
        {
            id: "recording",
            icon: "󰑊",
            label: "Recording"
        },
        {
            id: "gameMode",
            icon: "󰊗",
            label: "Game Mode"
        }
    ]
    readonly property var visibleQuickToggleItems: orderedQuickToggleItems()

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
            return Services.CaffeineService.inhibiting;
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
            Services.CaffeineService.toggle();
            return;
        case "recording":
            if (Services.RecordingService.isRecording)
                Services.RecordingService.stopRecording();
            else
                Services.RecordingService.startRecording("fullscreen");
            return;
        case "gameMode":
            Services.GameModeService.toggle();
            return;
        }
    }
}
