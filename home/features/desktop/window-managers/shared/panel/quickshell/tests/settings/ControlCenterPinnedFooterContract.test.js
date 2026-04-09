import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const sectionPath = resolve(quickshellRoot, "src/features/settings/components/tabs/ShellControlCenterSection.qml");
const helpersPath = resolve(quickshellRoot, "src/features/settings/components/tabs/ShellCoreHelpers.js");

describe("Control Center pinned footer settings contract", () => {
  it("documents Power Actions as a pinned footer control in settings", () => {
    const source = readFileSync(sectionPath, "utf8");

    expect(source).toContain("title: \"Pinned Footer\"");
    expect(source).toContain("configKey: \"controlCenterShowPowerActions\"");
    expect(source).toContain("Always pinned to the bottom of the Command Center when enabled.");
  });

  it("filters powerActions out of the reorder helper catalog", () => {
    const source = readFileSync(helpersPath, "utf8");

    expect(source).toContain("ControlCenterRegistry.isPinnedFooterWidget");
    expect(source).toContain("catalog = catalog.filter(function(item)");
    expect(source).toContain("order = order.filter(function(itemId)");
  });
});
