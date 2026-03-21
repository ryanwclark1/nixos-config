.pragma library

.import "../services/ShellUtils.js" as ShellUtils

/**
 * Shared SettingsHub / Shell IPC shortcuts for system destinations and command palette.
 * Pass execDetached(cmdArray) — typically (cmd) => Quickshell.execDetached(cmd).
 */
function shellDestinationAndPaletteHandlers(execDetached) {
    var x = execDetached;
    return {
        openDashboard: function() { x(ShellUtils.ipcCall("SettingsHub", "openTab", "dashboard")); },
        openSettings: function() { x(ShellUtils.ipcCall("SettingsHub", "open")); },
        openNotifications: function() { x(ShellUtils.ipcCall("Shell", "openSurface", "notifCenter")); },
        openControlCenter: function() { x(ShellUtils.ipcCall("Shell", "openSurface", "controlCenter")); },
        openNetworkControls: function() { x(ShellUtils.ipcCall("Shell", "openSurface", "networkMenu")); },
        openAudioControls: function() { x(ShellUtils.ipcCall("Shell", "openSurface", "audioMenu")); },
        openVpnControls: function() { x(ShellUtils.ipcCall("Shell", "openSurface", "vpnMenu")); },
        openPowerMenu: function() { x(ShellUtils.ipcCall("Shell", "openSurface", "powerMenu")); },
        openScreenshotMenu: function() { x(ShellUtils.ipcCall("Shell", "openSurface", "screenshotMenu")); },
        openAiChat: function() { x(ShellUtils.ipcCall("Shell", "openSurface", "aiChat")); },
        reloadShell: function() { x(ShellUtils.ipcCall("Shell", "reloadConfig")); }
    };
}
