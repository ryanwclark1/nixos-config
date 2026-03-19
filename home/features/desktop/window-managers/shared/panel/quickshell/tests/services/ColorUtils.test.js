import { describe, it, expect } from "vitest";
import {
  hsvToRgb,
  rgbToHsv,
  hex2,
  mix,
  solveOverlayColor,
} from "../../src/services/ColorUtils.js";

// ---------------------------------------------------------------------------
// hsvToRgb
// ---------------------------------------------------------------------------

describe("hsvToRgb", () => {
  it("converts pure red (0, 1, 1)", () => {
    expect(hsvToRgb(0, 1, 1)).toEqual({ r: 255, g: 0, b: 0 });
  });

  it("converts pure green (120, 1, 1)", () => {
    expect(hsvToRgb(120, 1, 1)).toEqual({ r: 0, g: 255, b: 0 });
  });

  it("converts pure blue (240, 1, 1)", () => {
    expect(hsvToRgb(240, 1, 1)).toEqual({ r: 0, g: 0, b: 255 });
  });

  it("converts white (0, 0, 1)", () => {
    expect(hsvToRgb(0, 0, 1)).toEqual({ r: 255, g: 255, b: 255 });
  });

  it("converts black (0, 0, 0)", () => {
    expect(hsvToRgb(0, 0, 0)).toEqual({ r: 0, g: 0, b: 0 });
  });

  it("handles negative hue (wraps around)", () => {
    // -60 should equal 300 degrees (magenta)
    const result = hsvToRgb(-60, 1, 1);
    expect(result).toEqual(hsvToRgb(300, 1, 1));
  });

  it("clamps saturation and value", () => {
    const result = hsvToRgb(0, 2, 2);
    expect(result).toEqual({ r: 255, g: 0, b: 0 });
  });
});

// ---------------------------------------------------------------------------
// rgbToHsv
// ---------------------------------------------------------------------------

describe("rgbToHsv", () => {
  it("converts pure red", () => {
    const hsv = rgbToHsv(255, 0, 0);
    expect(hsv.h).toBeCloseTo(0);
    expect(hsv.s).toBeCloseTo(1);
    expect(hsv.v).toBeCloseTo(1);
  });

  it("converts pure green", () => {
    const hsv = rgbToHsv(0, 255, 0);
    expect(hsv.h).toBeCloseTo(120);
    expect(hsv.s).toBeCloseTo(1);
  });

  it("converts gray (no saturation)", () => {
    const hsv = rgbToHsv(128, 128, 128);
    expect(hsv.s).toBeCloseTo(0);
  });

  it("round-trips correctly", () => {
    const rgb = hsvToRgb(210, 0.8, 0.9);
    const hsv = rgbToHsv(rgb.r, rgb.g, rgb.b);
    expect(hsv.h).toBeCloseTo(210, 0);
    expect(hsv.s).toBeCloseTo(0.8, 1);
    expect(hsv.v).toBeCloseTo(0.9, 1);
  });
});

// ---------------------------------------------------------------------------
// hex2
// ---------------------------------------------------------------------------

describe("hex2", () => {
  it("pads single-digit hex", () => {
    expect(hex2(0)).toBe("00");
    expect(hex2(15)).toBe("0f");
  });

  it("formats double-digit hex", () => {
    expect(hex2(255)).toBe("ff");
    expect(hex2(128)).toBe("80");
  });

  it("clamps out-of-range values", () => {
    expect(hex2(-10)).toBe("00");
    expect(hex2(300)).toBe("ff");
  });
});

// ---------------------------------------------------------------------------
// mix (uses Qt.rgba mock from setup.js)
// ---------------------------------------------------------------------------

describe("mix", () => {
  const red = { r: 1, g: 0, b: 0, a: 1 };
  const blue = { r: 0, g: 0, b: 1, a: 1 };

  it("returns c1 at t=0", () => {
    const result = mix(red, blue, 0);
    expect(result.r).toBeCloseTo(1);
    expect(result.b).toBeCloseTo(0);
  });

  it("returns c2 at t=1", () => {
    const result = mix(red, blue, 1);
    expect(result.r).toBeCloseTo(0);
    expect(result.b).toBeCloseTo(1);
  });

  it("returns midpoint at t=0.5", () => {
    const result = mix(red, blue, 0.5);
    expect(result.r).toBeCloseTo(0.5);
    expect(result.b).toBeCloseTo(0.5);
  });

  it("clamps t outside 0-1", () => {
    const below = mix(red, blue, -1);
    expect(below.r).toBeCloseTo(1); // clamped to 0 → c1

    const above = mix(red, blue, 5);
    expect(above.b).toBeCloseTo(1); // clamped to 1 → c2
  });
});

// ---------------------------------------------------------------------------
// solveOverlayColor
// ---------------------------------------------------------------------------

describe("solveOverlayColor", () => {
  it("returns target when opacity is 0", () => {
    const target = { r: 0.5, g: 0.5, b: 0.5, a: 1 };
    const result = solveOverlayColor({ r: 0, g: 0, b: 0, a: 1 }, target, 0);
    expect(result.r).toBeCloseTo(0.5);
  });

  it("solves overlay = target when base is black and opacity is 1", () => {
    const base = { r: 0, g: 0, b: 0, a: 1 };
    const target = { r: 0.7, g: 0.3, b: 0.5, a: 1 };
    const result = solveOverlayColor(base, target, 1);
    expect(result.r).toBeCloseTo(0.7);
    expect(result.g).toBeCloseTo(0.3);
    expect(result.b).toBeCloseTo(0.5);
  });

  it("clamps result channels to 0-1", () => {
    // Target brighter than base can produce → values > 1 which should be clamped
    const base = { r: 0.5, g: 0.5, b: 0.5, a: 1 };
    const target = { r: 0.9, g: 0.9, b: 0.9, a: 1 };
    const result = solveOverlayColor(base, target, 0.1);
    expect(result.r).toBeLessThanOrEqual(1);
    expect(result.g).toBeLessThanOrEqual(1);
    expect(result.b).toBeLessThanOrEqual(1);
  });
});
