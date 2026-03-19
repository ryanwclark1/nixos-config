import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const powerProfileServicePath = resolve(quickshellRoot, "src/services/PowerProfileService.qml");
const batteryMenuPath = resolve(quickshellRoot, "src/features/power/BatteryMenu.qml");

describe("PowerProfileService contract", () => {
  it("probes daemon availability before reading PowerProfiles state", () => {
    const source = readFileSync(powerProfileServicePath, "utf8");

    expect(source).toContain("import Quickshell.Io");
    expect(source).toContain('command: ["sh", "-c", "command -v powerprofilesctl >/dev/null 2>&1 && powerprofilesctl list >/dev/null 2>&1"]');
    expect(source).toContain("readonly property bool availabilityKnown: _probeComplete");
    expect(source).toContain("readonly property bool available: _probeComplete && _powerProfilesAvailable");
    expect(source).toContain('readonly property string currentProfile: available ? _profileToString(PowerProfiles.profile) : "balanced"');
    expect(source).toContain("readonly property bool hasPerformanceProfile: available ? PowerProfiles.hasPerformanceProfile : false");
    expect(source).toContain("if (!available)");
    expect(source).not.toContain("readonly property bool available: true");
  });

  it("hides the unavailable fallback copy until the availability probe completes", () => {
    const source = readFileSync(batteryMenuPath, "utf8");

    expect(source).toContain('PowerProfileService.availabilityKnown ? "POWER PROFILE UNAVAILABLE" : "POWER PROFILE"');
    expect(source).toContain("visible: PowerProfileService.availabilityKnown && !PowerProfileService.available");
  });
});
