import { describe, it, expect, vi } from "vitest";
import {
  buildSystemDestinationItems,
  buildCommandPaletteActions,
} from "../../src/launcher/LauncherEntryRegistry.js";

describe("buildSystemDestinationItems", () => {
  it("builds destination-style system entries with actions", () => {
    const openSettings = vi.fn();
    const items = buildSystemDestinationItems({
      openDashboard: vi.fn(),
      openSettings,
      openNotifications: vi.fn(),
      openControlCenter: vi.fn(),
      openScreenshotMenu: vi.fn(),
      openPowerMenu: vi.fn(),
    });

    expect(items.map((item) => item.name)).toEqual(
      expect.arrayContaining(["Dashboard", "Settings", "Notifications", "Control Center"])
    );
    expect(items.every((item) => item.entryKind === "destination")).toBe(true);

    const settingsItem = items.find((item) => item.name === "Settings");
    settingsItem.action();
    expect(openSettings).toHaveBeenCalledTimes(1);
  });
});

describe("buildCommandPaletteActions", () => {
  it("returns action-first command palette entries", () => {
    const toggleEcoMode = vi.fn();
    const items = buildCommandPaletteActions({
      openDashboard: vi.fn(),
      openSettings: vi.fn(),
      openNotifications: vi.fn(),
      openControlCenter: vi.fn(),
      openNetworkControls: vi.fn(),
      openAudioControls: vi.fn(),
      openVpnControls: vi.fn(),
      openPowerMenu: vi.fn(),
      openScreenshotMenu: vi.fn(),
      openAiChat: vi.fn(),
      toggleEcoMode,
      toggleDesktopEditMode: vi.fn(),
      toggleDynamicTheme: vi.fn(),
      reloadShell: vi.fn(),
    });

    expect(items.map((item) => item.label)).toContain("Toggle Eco Mode");
    expect(items.map((item) => item.label)).toContain("Open Control Center");

    const ecoItem = items.find((item) => item.label === "Toggle Eco Mode");
    ecoItem.action();
    expect(toggleEcoMode).toHaveBeenCalledTimes(1);
  });
});
