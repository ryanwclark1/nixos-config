import { describe, it, expect } from "vitest";
import {
  uniqueResolutions,
  ratesForResolution,
  cloneMonitor,
  arrangeMirror,
  arrangeExtend,
  arrangePrimaryOnly,
  computeScaleFactor,
} from "../../src/features/display/DisplayConfigHelpers.js";

const mkMonitor = (overrides = {}) => ({
  id: "m1", name: "DP-1", description: "Test",
  width: 2560, height: 1440, refreshRate: 165,
  x: 0, y: 0, scale: 1,
  availableModes: [],
  dragX: 0, dragY: 0,
  ...overrides,
});

describe("uniqueResolutions", () => {
  it("extracts unique resolutions from mode strings", () => {
    const modes = [
      "2560x1440@165.00Hz",
      "2560x1440@60.00Hz",
      "1920x1080@144.00Hz",
      "1920x1080@60.00Hz",
    ];
    expect(uniqueResolutions(modes)).toEqual(["2560x1440", "1920x1080"]);
  });

  it("returns empty for empty input", () => {
    expect(uniqueResolutions([])).toEqual([]);
  });
});

describe("ratesForResolution", () => {
  it("returns matching refresh rates", () => {
    const modes = [
      "2560x1440@165.00Hz",
      "2560x1440@60.00Hz",
      "1920x1080@144.00Hz",
    ];
    expect(ratesForResolution(modes, "2560x1440")).toEqual(["165.00", "60.00"]);
  });

  it("returns empty for non-matching resolution", () => {
    expect(ratesForResolution(["1920x1080@60.00Hz"], "3840x2160")).toEqual([]);
  });
});

describe("cloneMonitor", () => {
  it("creates a deep copy of monitor properties", () => {
    const orig = mkMonitor({ x: 100, y: 200 });
    const clone = cloneMonitor(orig);
    expect(clone).toEqual(orig);
    clone.x = 999;
    expect(orig.x).toBe(100);
  });
});

describe("arrangeMirror", () => {
  it("places all monitors at (0,0)", () => {
    const monitors = [mkMonitor({ x: 100 }), mkMonitor({ id: "m2", x: 200 })];
    const result = arrangeMirror(monitors);
    expect(result).toHaveLength(2);
    expect(result[0].x).toBe(0);
    expect(result[0].y).toBe(0);
    expect(result[1].x).toBe(0);
  });
});

describe("arrangeExtend", () => {
  it("tiles monitors left-to-right", () => {
    const monitors = [
      mkMonitor({ width: 2560, height: 1440, scale: 1 }),
      mkMonitor({ id: "m2", width: 1920, height: 1080, scale: 1 }),
    ];
    const result = arrangeExtend(monitors);
    expect(result[0].x).toBe(0);
    expect(result[1].x).toBe(2560);
  });

  it("vertically centers shorter monitors", () => {
    const monitors = [
      mkMonitor({ width: 2560, height: 1440, scale: 1 }),
      mkMonitor({ id: "m2", width: 1920, height: 1080, scale: 1 }),
    ];
    const result = arrangeExtend(monitors);
    // Second monitor is 360px shorter → centered at y=180
    expect(result[1].y).toBe(180);
  });

  it("returns empty for empty input", () => {
    expect(arrangeExtend([])).toEqual([]);
  });
});

describe("arrangePrimaryOnly", () => {
  it("keeps first at (0,0) and moves others off-screen", () => {
    const monitors = [mkMonitor(), mkMonitor({ id: "m2" })];
    const result = arrangePrimaryOnly(monitors);
    expect(result[0].x).toBe(0);
    expect(result[1].x).toBe(-99999);
  });
});

describe("computeScaleFactor", () => {
  it("computes fit-to-canvas scale", () => {
    const monitors = [mkMonitor({ x: 0, y: 0, width: 2560, height: 1440 })];
    const result = computeScaleFactor(monitors, 600, 400);
    expect(result.scale).toBeGreaterThan(0);
    expect(result.scale).toBeLessThanOrEqual(0.35);
  });

  it("returns default for empty monitors", () => {
    expect(computeScaleFactor([], 600, 400)).toEqual({
      scale: 1.0,
      offsetX: 0,
      offsetY: 0,
    });
  });

  it("enforces minimum scale of 0.05", () => {
    // Huge monitor in tiny canvas
    const monitors = [mkMonitor({ x: 0, y: 0, width: 100000, height: 100000 })];
    const result = computeScaleFactor(monitors, 100, 100);
    expect(result.scale).toBeGreaterThanOrEqual(0.05);
  });
});
