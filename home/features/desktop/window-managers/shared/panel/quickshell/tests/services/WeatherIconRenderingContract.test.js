import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");

const weatherSurfacePaths = [
  "src/bar/components/WeatherBarWidget.qml",
  "src/features/time/DateTimeMenu.qml",
  "src/features/time/WeatherMenu.qml",
  "src/features/desktop/components/DesktopWeather.qml",
  "src/features/system/sections/WeatherWidget.qml",
  "src/features/lock/LockPanel.qml",
].map(path => resolve(quickshellRoot, path));

describe("weather icon rendering contracts", () => {
  it("renders weather icon asset names through SvgIcon instead of Text", () => {
    for (const filePath of weatherSurfacePaths) {
      const source = readFileSync(filePath, "utf8");

      expect(source).toContain("source: Appearance.weatherIcon(");
      expect(source).not.toContain("text: Appearance.weatherIcon(");
    }
  });
});
