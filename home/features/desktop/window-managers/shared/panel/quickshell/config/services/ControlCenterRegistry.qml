pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth

QtObject {
    id: root

    readonly property var quickLinkItems: SystemActionRegistry.actionsByIds([
        "audioControls",
        "networkControls"
    ]).concat([
        {
            id: "screenshotControls",
            icon: "󰩭",
            title: "Screenshot",
            subtitle: "Capture region, screen, or fullscreen",
            clickCommand: ["quickshell", "ipc", "call", "Shell", "toggleScreenshotMenu"]
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
        var hidden = Array.isArray(Config.controlCenterHiddenToggles) ? Config.controlCenterHiddenToggles : [];
        var order = Array.isArray(Config.controlCenterToggleOrder) ? Config.controlCenterToggleOrder : [];
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
            return NightLightService.active;
        case "caffeine":
            return CaffeineService.inhibiting;
        case "recording":
            return RecordingService.isRecording;
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
            NightLightService.toggle();
            return;
        case "caffeine":
            CaffeineService.toggle();
            return;
        case "recording":
            if (RecordingService.isRecording)
                RecordingService.stopRecording();
            else
                RecordingService.startRecording("fullscreen");
            return;
        }
    }
}
