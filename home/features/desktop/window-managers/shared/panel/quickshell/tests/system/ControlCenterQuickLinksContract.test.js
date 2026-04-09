import { describe, it, expect } from "vitest";
import { existsSync, readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const registryPath = resolve(quickshellRoot, "src/features/control-center/registry/ControlCenterRegistry.qml");
const iconsRoot = resolve(quickshellRoot, "src/assets/icons");

describe("Control Center quick links contract", () => {
  it("references icon assets that exist for built-in quick links", () => {
    const source = readFileSync(registryPath, "utf8");
    const builtInSection = source.split("]).concat([")[1]?.split("    ])")[0] || "";
    const iconMatches = [...builtInSection.matchAll(/icon:\s*"([^"]+)"/g)];
    const missingIcons = iconMatches
      .map((match) => match[1])
      .filter((iconName) => !existsSync(resolve(iconsRoot, "fluent", iconName)) && !existsSync(resolve(iconsRoot, iconName)));

    expect(missingIcons).toEqual([]);
    expect(source).toContain('id: "displayControls"');
    expect(source).toContain('icon: "desktop.svg"');
  });
});
