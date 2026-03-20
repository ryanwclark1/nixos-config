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
  it("renders primary weather conditions through the animated weather icon component", () => {
    for (const filePath of weatherSurfacePaths) {
      const source = readFileSync(filePath, "utf8");

      expect(source).toContain("AnimatedWeatherIcon");
    }
  });

  it("keeps forecast rows on static SvgIcon assets", () => {
    const source = readFileSync(resolve(quickshellRoot, "src/features/time/WeatherMenu.qml"), "utf8");

    expect(source).toContain("source: Appearance.weatherIcon(modelData.condition)");
  });
});
