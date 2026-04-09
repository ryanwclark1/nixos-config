import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const controlCenterPath = resolve(quickshellRoot, "src/features/control-center/ControlCenter.qml");
const registryPath = resolve(quickshellRoot, "src/features/control-center/registry/ControlCenterRegistry.qml");

describe("Control Center power actions contract", () => {
  it("renders the pinned Power Actions footer outside the main Flickable", () => {
    const source = readFileSync(controlCenterPath, "utf8");

    expect(source).toContain("id: ccFlick");
    expect(source).toContain("visible: Config.controlCenterShowPowerActions");
    expect(source).toContain("label: \"POWER ACTIONS\"");
    expect(source).toContain("PowerActionsRow {");

    const flickIndex = source.indexOf("id: ccFlick");
    const footerIndex = source.indexOf("visible: Config.controlCenterShowPowerActions");
    expect(footerIndex).toBeGreaterThan(flickIndex);
  });

  it("keeps powerActions out of the generic visible widget list", () => {
    const source = readFileSync(registryPath, "utf8");

    expect(source).toContain("function isPinnedFooterWidget(widgetId)");
    expect(source).toContain("return String(widgetId || \"\") === \"powerActions\";");
    expect(source).toContain("if (isPinnedFooterWidget(ordered.id))");
    expect(source).toContain("if (isPinnedFooterWidget(fallback.id))");
  });
});
