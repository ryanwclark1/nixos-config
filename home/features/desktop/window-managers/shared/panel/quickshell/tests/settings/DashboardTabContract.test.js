import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const dashboardTabPath = resolve(quickshellRoot, "src/features/settings/components/tabs/DashboardTab.qml");

describe("DashboardTab contract", () => {
  it("coerces media visibility to a real boolean before MediaService initializes", () => {
    const source = readFileSync(dashboardTabPath, "utf8");

    expect(source).toContain("visible: !!MediaService.playing || !!MediaService.hasPlayer");
    expect(source).not.toContain("visible: MediaService.playing || MediaService.hasPlayer");
  });
});
