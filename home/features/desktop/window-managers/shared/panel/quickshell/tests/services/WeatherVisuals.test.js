import { describe, it, expect } from "vitest";
import { visualForCondition } from "../../src/services/WeatherVisuals.js";

describe("visualForCondition", () => {
  it("maps clear conditions to the sunny scene without an overlay", () => {
    expect(visualForCondition("Clear sky")).toMatchObject({
      scene: "clear",
      icon: "weather-sunny.svg",
      overlayScene: "none",
      flash: false,
    });
  });

  it("maps precipitation and storm conditions to rich animated scenes", () => {
    expect(visualForCondition("Light drizzle")).toMatchObject({
      scene: "rain",
      overlayScene: "rain",
      level: "light",
      flash: false,
    });

    expect(visualForCondition("Heavy thunderstorm")).toMatchObject({
      scene: "thunder",
      icon: "weather-thunderstorm.svg",
      overlayScene: "rain",
      level: "heavy",
      flash: true,
    });
  });

  it("maps snow and fog families to their dedicated scenes", () => {
    expect(visualForCondition("Moderate snow fall")).toMatchObject({
      scene: "snow",
      overlayScene: "snow",
    });

    expect(visualForCondition("Fog")).toMatchObject({
      scene: "fog",
      overlayScene: "fog",
    });
  });

  it("falls back to clouds for unknown conditions", () => {
    expect(visualForCondition("Volcanic ash")).toMatchObject({
      scene: "cloud",
      icon: "cloud.svg",
      overlayScene: "none",
      flash: false,
    });
  });
});
