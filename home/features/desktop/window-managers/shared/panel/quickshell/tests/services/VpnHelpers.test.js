import { describe, it, expect } from "vitest";
import { statusColor } from "../../src/features/network/VpnHelpers.js";

const colors = {
  success: "#00ff00",
  warning: "#ffaa00",
  textSecondary: "#888888",
  textDisabled: "#444444",
};

describe("statusColor", () => {
  it("returns success for 'connected'", () => {
    expect(statusColor("connected", colors)).toBe("#00ff00");
  });

  it("returns warning for 'stopped'", () => {
    expect(statusColor("stopped", colors)).toBe("#ffaa00");
  });

  it("returns textSecondary for 'disconnected'", () => {
    expect(statusColor("disconnected", colors)).toBe("#888888");
  });

  it("returns textDisabled for unknown status", () => {
    expect(statusColor("unknown", colors)).toBe("#444444");
  });

  it("returns textDisabled for empty string", () => {
    expect(statusColor("", colors)).toBe("#444444");
  });

  it("returns textDisabled for undefined status", () => {
    expect(statusColor(undefined, colors)).toBe("#444444");
  });
});
