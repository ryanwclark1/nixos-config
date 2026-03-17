pragma Singleton
import QtQuick
import Quickshell
import "."

QtObject {
    id: root

    readonly property var _actions: ({
            shutdown: {
                id: "shutdown",
                category: "Power",
                name: "Shutdown",
                title: "Shutdown system?",
                label: "Shutdown",
                icon: "󰐥",
                subtitle: "Power off the system",
                danger: true,
                requiresConfirmation: true,
                cmd: ["systemctl", "poweroff"]
            },
            reboot: {
                id: "reboot",
                category: "Power",
                name: "Reboot",
                title: "Reboot system?",
                label: "Reboot",
                icon: "󰑐",
                subtitle: "Restart the system",
                danger: true,
                requiresConfirmation: true,
                cmd: ["systemctl", "reboot"]
            },
            lock: {
                id: "lock",
                category: "Power",
                name: "Lock Screen",
                title: "",
                label: "Lock",
                icon: "󰌾",
                subtitle: "Lock the current session",
                danger: false,
                requiresConfirmation: false,
                cmd: CompositorAdapter.lockCommand()
            },
            logout: {
                id: "logout",
                category: "Power",
                name: "Log Out",
                title: "Log out of session?",
                label: "Logout",
                icon: "󰍃",
                subtitle: "End the current session",
                danger: false,
                requiresConfirmation: true
            },
            audioControls: {
                id: "audioControls",
                category: "Controls",
                name: "Open Audio Controls",
                title: "Open the audio popup",
                label: "Audio Controls",
                icon: "󰕾",
                subtitle: "Devices, volume, and mute",
                danger: false,
                requiresConfirmation: false,
                ipcTarget: "Shell",
                ipcAction: "toggleSurface",
                clickCommand: ["quickshell", "ipc", "call", "Shell", "toggleSurface", "audioMenu"]
            },
            networkControls: {
                id: "networkControls",
                category: "Controls",
                name: "Open Network Controls",
                title: "Open the network popup",
                label: "Network Controls",
                icon: "󰖩",
                subtitle: "Wi-Fi and connectivity",
                danger: false,
                requiresConfirmation: false,
                ipcTarget: "Shell",
                ipcAction: "toggleSurface",
                clickCommand: ["quickshell", "ipc", "call", "Shell", "toggleSurface", "networkMenu"]
            },
            vpnControls: {
                id: "vpnControls",
                category: "Controls",
                name: "Open VPN Hub",
                title: "Open the VPN popup",
                label: "VPN Hub",
                icon: "󰖂",
                subtitle: "Tailscale and active VPN sessions",
                danger: false,
                requiresConfirmation: false,
                ipcTarget: "Shell",
                ipcAction: "toggleSurface",
                clickCommand: ["quickshell", "ipc", "call", "Shell", "toggleSurface", "vpnMenu"]
            },
            commandCenter: {
                id: "commandCenter",
                category: "Controls",
                name: "Open Command Center",
                title: "Open the system hub",
                label: "Command Center",
                icon: "󰒓",
                subtitle: "Quick system controls",
                danger: false,
                requiresConfirmation: false,
                ipcTarget: "Shell",
                ipcAction: "toggleSurface",
                clickCommand: ["quickshell", "ipc", "call", "Shell", "toggleSurface", "controlCenter"]
            }
        })

    readonly property var sessionActionIds: ["shutdown", "reboot", "lock", "logout"]
    readonly property var shellEntryActionIds: ["audioControls", "networkControls", "vpnControls", "commandCenter"]

    readonly property var sessionActions: actionsByIds(sessionActionIds)
    readonly property var shellEntryActions: actionsByIds(shellEntryActionIds)

    function actionById(actionId) {
        var action = root._actions[String(actionId || "")];
        return action || null;
    }

    function actionsByIds(actionIds) {
        var result = [];
        var ids = actionIds || [];
        for (var i = 0; i < ids.length; i++) {
            var action = root.actionById(ids[i]);
            if (action)
                result.push(action);
        }
        return result;
    }

    function execute(actionId) {
        var action = root.actionById(actionId);
        if (!action)
            return false;

        if (String(action.id || "") === "logout")
            return CompositorAdapter.logout();

        if (action.clickCommand && action.clickCommand.length > 0) {
            Quickshell.execDetached(action.clickCommand);
            return true;
        }

        if (action.cmd && action.cmd.length > 0) {
            Quickshell.execDetached(action.cmd);
            return true;
        }

        return false;
    }
}
