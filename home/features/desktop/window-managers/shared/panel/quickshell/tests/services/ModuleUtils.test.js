import { describe, it, expect } from "vitest";
import {
  formatRate,
  formatBytes,
  arrayMax,
  formatAge,
} from "../../src/features/system/models/ModuleUtils.js";

describe("formatRate", () => {
  it("formats bytes/s", () => {
    expect(formatRate(500)).toBe("500 B/s");
  });

  it("formats KB/s", () => {
    expect(formatRate(2048)).toBe("2.0 KB/s");
  });

  it("formats MB/s", () => {
    expect(formatRate(5 * 1048576)).toBe("5.0 MB/s");
  });

  it("formats GB/s", () => {
    expect(formatRate(2 * 1073741824)).toBe("2.00 GB/s");
  });

  it("handles zero", () => {
    expect(formatRate(0)).toBe("0 B/s");
  });
});

describe("formatBytes", () => {
  it("formats bytes", () => {
    expect(formatBytes(512)).toBe("512 B");
  });

  it("formats KiB", () => {
    expect(formatBytes(2048)).toBe("2.0 KiB");
  });

  it("formats MiB", () => {
    expect(formatBytes(10 * 1024 * 1024)).toBe("10.0 MiB");
  });

  it("formats GiB", () => {
    expect(formatBytes(4 * 1024 * 1024 * 1024)).toBe("4.0 GiB");
  });

  it('returns "Unavailable" for negative/NaN', () => {
    expect(formatBytes(-1)).toBe("Unavailable");
    expect(formatBytes(NaN)).toBe("Unavailable");
  });
});

describe("arrayMax", () => {
  it("finds maximum value", () => {
    expect(arrayMax([1, 5, 3, 2])).toBe(5);
  });

  it("returns 0 for empty array", () => {
    expect(arrayMax([])).toBe(0);
  });

  it("handles null/undefined entries", () => {
    expect(arrayMax([null, 10, undefined, 5])).toBe(10);
  });
});

describe("formatAge", () => {
  it('returns "waiting" for zero/negative timestamps', () => {
    expect(formatAge(0)).toBe("waiting");
    expect(formatAge(-100)).toBe("waiting");
  });

  it('returns "now" for very recent timestamps', () => {
    expect(formatAge(Date.now())).toBe("now");
  });

  it("formats seconds ago", () => {
    const result = formatAge(Date.now() - 30000);
    expect(result).toMatch(/^\d+s ago$/);
  });

  it("formats minutes and seconds", () => {
    const result = formatAge(Date.now() - 90000);
    expect(result).toMatch(/^\d+m \d+s ago$/);
  });
});
