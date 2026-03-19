import { describe, it, expect } from "vitest";
import {
  formatKiB,
  fallbackText,
  detailStatusColor,
  actionStatusColor,
} from "../../src/features/system/sections/ProcessTableHelpers.js";

describe("formatKiB", () => {
  it("formats KiB", () => {
    expect(formatKiB(512)).toBe("512 KiB");
  });

  it("formats MiB", () => {
    expect(formatKiB(2048)).toBe("2.0 MiB");
  });

  it("formats GiB", () => {
    expect(formatKiB(2 * 1024 * 1024)).toBe("2.0 GiB");
  });

  it("returns 0 KiB for zero/negative", () => {
    expect(formatKiB(0)).toBe("0 KiB");
    expect(formatKiB(-100)).toBe("0 KiB");
  });
});

describe("fallbackText", () => {
  it('returns "Unavailable" for empty/null', () => {
    expect(fallbackText("")).toBe("Unavailable");
    expect(fallbackText(null)).toBe("Unavailable");
    expect(fallbackText("   ")).toBe("Unavailable");
  });

  it("returns stringified value otherwise", () => {
    expect(fallbackText("hello")).toBe("hello");
    expect(fallbackText(42)).toBe("42");
  });
});

const Colors = {
  success: "#9ece6a",
  warning: "#e0af68",
  error: "#f7768e",
  textDisabled: "#565f89",
};

describe("detailStatusColor", () => {
  it("maps status to correct color", () => {
    expect(detailStatusColor("ready", Colors)).toBe(Colors.success);
    expect(detailStatusColor("loading", Colors)).toBe(Colors.warning);
    expect(detailStatusColor("permission-limited", Colors)).toBe(Colors.warning);
    expect(detailStatusColor("terminated", Colors)).toBe(Colors.error);
    expect(detailStatusColor("error", Colors)).toBe(Colors.error);
    expect(detailStatusColor("unknown", Colors)).toBe(Colors.textDisabled);
  });
});

describe("actionStatusColor", () => {
  it("maps status to correct color", () => {
    expect(actionStatusColor("success", Colors)).toBe(Colors.success);
    expect(actionStatusColor("pending", Colors)).toBe(Colors.warning);
    expect(actionStatusColor("error", Colors)).toBe(Colors.error);
    expect(actionStatusColor("idle", Colors)).toBe(Colors.textDisabled);
  });
});
