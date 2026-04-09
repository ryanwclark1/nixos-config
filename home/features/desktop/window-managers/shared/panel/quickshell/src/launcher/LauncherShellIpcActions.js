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
        openNotifications: function() { x(ShellUtils.shellSurfaceCall("openSurface", "notifCenter")); },
        openControlCenter: function() { x(ShellUtils.shellSurfaceCall("openSurface", "controlCenter")); },
        openNetworkControls: function() { x(ShellUtils.shellSurfaceCall("openSurface", "networkMenu")); },
        openAudioControls: function() { x(ShellUtils.shellSurfaceCall("openSurface", "audioMenu")); },
        openVpnControls: function() { x(ShellUtils.shellSurfaceCall("openSurface", "vpnMenu")); },
        openPowerMenu: function() { x(ShellUtils.shellSurfaceCall("openSurface", "powerMenu")); },
        openScreenshotMenu: function() { x(ShellUtils.shellSurfaceCall("openSurface", "screenshotMenu")); },
        openAiChat: function() { x(ShellUtils.shellSurfaceCall("openSurface", "aiChat")); },
        reloadShell: function() { x(ShellUtils.ipcCall("Shell", "reloadConfig")); }
    };
}
