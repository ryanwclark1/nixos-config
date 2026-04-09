import { describe, it, expect, vi } from "vitest";
import { shellDestinationAndPaletteHandlers } from "../../src/launcher/LauncherShellIpcActions.js";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");

describe("shellDestinationAndPaletteHandlers", () => {
  it("routes openSettings through execDetached with ipc argv", () => {
    const execDetached = vi.fn();
    const h = shellDestinationAndPaletteHandlers(execDetached);
    h.openSettings();
    expect(execDetached).toHaveBeenCalledTimes(1);
    expect(execDetached.mock.calls[0][0]).toEqual([
      "quickshell",
      "ipc",
      "call",
      "SettingsHub",
      "open",
    ]);
  });

  it("includes surface id for openAiChat", () => {
    const execDetached = vi.fn();
    const h = shellDestinationAndPaletteHandlers(execDetached);
    h.openAiChat();
    expect(execDetached.mock.calls[0][0]).toEqual([
      "quickshell",
      "ipc",
      "call",
      "Shell",
      "openSurface",
      "aiChat",
      "",
    ]);
  });

  it("pads Shell surface opens for launcher destinations", () => {
    const execDetached = vi.fn();
    const h = shellDestinationAndPaletteHandlers(execDetached);
    h.openNotifications();
    h.openControlCenter();

    expect(execDetached.mock.calls[0][0]).toEqual([
      "quickshell",
      "ipc",
      "call",
      "Shell",
      "openSurface",
      "notifCenter",
      "",
    ]);
    expect(execDetached.mock.calls[1][0]).toEqual([
      "quickshell",
      "ipc",
      "call",
      "Shell",
      "openSurface",
      "controlCenter",
      "",
    ]);
  });

  it("keeps SSH settings routed through the SettingsHub target", () => {
    const launcherSource = readFileSync(
      resolve(quickshellRoot, "src/launcher/Launcher.qml"),
      "utf8"
    );

    expect(launcherSource).toContain('openSshSettings: function() {');
    expect(launcherSource).toContain('SU.ipcCall("SettingsHub", "open")');
    expect(launcherSource).not.toContain('SU.ipcCall("Shell", "openSurface", "settingsHub")');
  });
});
