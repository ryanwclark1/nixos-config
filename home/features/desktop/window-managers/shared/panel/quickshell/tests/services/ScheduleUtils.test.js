import { describe, it, expect } from "vitest";
import {
  computeSunTimes,
  currentMinutes,
  isInWindow,
  isDarkAtLocation,
} from "../../src/services/ScheduleUtils.js";

// ---------------------------------------------------------------------------
// currentMinutes
// ---------------------------------------------------------------------------

describe("currentMinutes", () => {
  it("returns 0 at midnight", () => {
    expect(currentMinutes(new Date(2025, 0, 1, 0, 0))).toBe(0);
  });

  it("returns 720 at noon", () => {
    expect(currentMinutes(new Date(2025, 0, 1, 12, 0))).toBe(720);
  });

  it("returns 1439 at 23:59", () => {
    expect(currentMinutes(new Date(2025, 0, 1, 23, 59))).toBe(1439);
  });

  it("returns hours * 60 + minutes for arbitrary time", () => {
    expect(currentMinutes(new Date(2025, 5, 15, 14, 37))).toBe(14 * 60 + 37);
  });
});

// ---------------------------------------------------------------------------
// isInWindow
// ---------------------------------------------------------------------------

describe("isInWindow", () => {
  it("returns true when current is inside a non-wrapping window", () => {
    // Window: 360 (06:00) to 1080 (18:00)
    expect(isInWindow(720, 360, 1080)).toBe(true);
  });

  it("returns false when current is outside a non-wrapping window", () => {
    expect(isInWindow(300, 360, 1080)).toBe(false);
  });

  it("returns true at exact start boundary", () => {
    expect(isInWindow(360, 360, 1080)).toBe(true);
  });

  it("returns false at exact end boundary (exclusive)", () => {
    expect(isInWindow(1080, 360, 1080)).toBe(false);
  });

  it("handles wrap-around window (e.g. 22:00 to 06:00)", () => {
    const start = 22 * 60; // 1320
    const end = 6 * 60; // 360

    // 23:00 should be inside
    expect(isInWindow(23 * 60, start, end)).toBe(true);
    // 02:00 should be inside
    expect(isInWindow(2 * 60, start, end)).toBe(true);
    // 12:00 should be outside
    expect(isInWindow(12 * 60, start, end)).toBe(false);
  });

  it("returns true at start of wrap-around window", () => {
    expect(isInWindow(1320, 1320, 360)).toBe(true);
  });

  it("returns false at end of wrap-around window (exclusive)", () => {
    expect(isInWindow(360, 1320, 360)).toBe(false);
  });

  it("handles same start and end (zero-width window)", () => {
    // When start === end, non-wrapping path: current >= start && current < end
    // This is always false, which is correct (empty window)
    expect(isInWindow(500, 500, 500)).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// computeSunTimes
// ---------------------------------------------------------------------------

describe("computeSunTimes", () => {
  // We can't test exact minute values since they depend on timezone,
  // but we can verify structural invariants.

  it("returns an object with sunrise and sunset properties", () => {
    const result = computeSunTimes(new Date(2025, 5, 21), 51.5, -0.1); // London
    expect(result).toHaveProperty("sunrise");
    expect(result).toHaveProperty("sunset");
    expect(typeof result.sunrise).toBe("number");
    expect(typeof result.sunset).toBe("number");
  });

  it("sunrise and sunset are within valid minute range [0, 1440)", () => {
    const result = computeSunTimes(new Date(2025, 5, 21), 40.7, -74.0); // NYC
    expect(result.sunrise).toBeGreaterThanOrEqual(0);
    expect(result.sunrise).toBeLessThan(1440);
    expect(result.sunset).toBeGreaterThanOrEqual(0);
    expect(result.sunset).toBeLessThan(1440);
  });

  it("summer days are longer than winter days at mid-latitudes", () => {
    const lat = 48.9; // Paris
    const lon = 2.35;
    const summer = computeSunTimes(new Date(2025, 5, 21), lat, lon);
    const winter = computeSunTimes(new Date(2025, 11, 21), lat, lon);

    const summerDayLength =
      summer.sunset > summer.sunrise
        ? summer.sunset - summer.sunrise
        : 1440 - summer.sunrise + summer.sunset;
    const winterDayLength =
      winter.sunset > winter.sunrise
        ? winter.sunset - winter.sunrise
        : 1440 - winter.sunrise + winter.sunset;

    expect(summerDayLength).toBeGreaterThan(winterDayLength);
  });

  it("equatorial locations have roughly equal day/night", () => {
    // Equator on equinox — day length should be close to 720 minutes (12h)
    const result = computeSunTimes(new Date(2025, 2, 20), 0, 0);
    const dayLength =
      result.sunset > result.sunrise
        ? result.sunset - result.sunrise
        : 1440 - result.sunrise + result.sunset;

    // Allow 60-minute tolerance for the simplified formula
    expect(dayLength).toBeGreaterThan(660);
    expect(dayLength).toBeLessThan(780);
  });

  it("handles extreme latitude without NaN", () => {
    // Near Arctic circle — cosHA gets clamped
    const result = computeSunTimes(new Date(2025, 5, 21), 68, 15);
    expect(Number.isNaN(result.sunrise)).toBe(false);
    expect(Number.isNaN(result.sunset)).toBe(false);
  });
});

// ---------------------------------------------------------------------------
// isDarkAtLocation
// ---------------------------------------------------------------------------

describe("isDarkAtLocation", () => {
  it("returns false for NaN latitude", () => {
    expect(isDarkAtLocation(new Date(), NaN, 0)).toBe(false);
  });

  it("returns false for NaN longitude", () => {
    expect(isDarkAtLocation(new Date(), 0, NaN)).toBe(false);
  });

  it("noon at equator is not dark", () => {
    // Create a date at local noon (12:00) — equator, prime meridian
    const noon = new Date(2025, 2, 20, 12, 0);
    expect(isDarkAtLocation(noon, 0, 0)).toBe(false);
  });
});
