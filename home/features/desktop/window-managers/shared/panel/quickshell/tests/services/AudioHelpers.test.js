import { describe, it, expect } from "vitest";
import { normalizeVolume, parseWpctlVolume } from "../../src/services/AudioHelpers.js";

describe("normalizeVolume", () => {
  it("returns zero for invalid pipewire values", () => {
    expect(normalizeVolume(undefined, 1.0)).toBe(0);
    expect(normalizeVolume(null, 1.0)).toBe(0);
    expect(normalizeVolume(NaN, 1.0)).toBe(0);
    expect(normalizeVolume(Infinity, 1.0)).toBe(0);
    expect(normalizeVolume("not-a-number", 1.0)).toBe(0);
  });

  it("clamps negative and oversized values into range", () => {
    expect(normalizeVolume(-0.2, 1.0)).toBe(0);
    expect(normalizeVolume(0.4, 1.0)).toBe(0.4);
    expect(normalizeVolume(1.6, 1.0)).toBe(1.0);
  });

  it("falls back to a sane default limit when the max is invalid", () => {
    expect(normalizeVolume(0.5, undefined)).toBe(0.5);
    expect(normalizeVolume(2.0, NaN)).toBe(1.0);
    expect(normalizeVolume(2.0, -1)).toBe(1.0);
  });
});

describe("parseWpctlVolume", () => {
  it("parses volume and mute state from wpctl output", () => {
    expect(parseWpctlVolume("Volume: 0.45", 1.0)).toEqual({
      volume: 0.45,
      muted: false,
    });

    expect(parseWpctlVolume("Volume: 0.12 [MUTED]", 1.0)).toEqual({
      volume: 0.12,
      muted: true,
    });
  });

  it("returns null when wpctl output does not include a volume value", () => {
    expect(parseWpctlVolume("", 1.0)).toBeNull();
    expect(parseWpctlVolume("not volume output", 1.0)).toBeNull();
  });
});
