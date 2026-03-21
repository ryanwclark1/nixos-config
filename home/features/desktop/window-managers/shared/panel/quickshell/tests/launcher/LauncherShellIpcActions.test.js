import { describe, it, expect, vi } from "vitest";
import { shellDestinationAndPaletteHandlers } from "../../src/launcher/LauncherShellIpcActions.js";

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
    ]);
  });
});
