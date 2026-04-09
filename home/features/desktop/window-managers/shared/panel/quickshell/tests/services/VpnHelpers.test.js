import { describe, it, expect } from "vitest";
import {
  advertiseExitNodeEnabled,
  backendStateLabel,
  backendStateStatusKey,
  exitNodeLabel,
  firstIpv4,
  healthSummary,
  statefulFilteringEnabled,
  statusColor,
} from "../../src/features/network/VpnHelpers.js";

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

  it("returns warning for 'attention'", () => {
    expect(statusColor("attention", colors)).toBe("#ffaa00");
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

describe("backendStateStatusKey", () => {
  it("maps Running to connected", () => {
    expect(backendStateStatusKey("Running")).toBe("connected");
  });

  it("maps NeedsLogin to attention", () => {
    expect(backendStateStatusKey("NeedsLogin")).toBe("attention");
  });

  it("maps Stopped to stopped", () => {
    expect(backendStateStatusKey("Stopped")).toBe("stopped");
  });

  it("maps unknown values to disconnected", () => {
    expect(backendStateStatusKey("Starting")).toBe("disconnected");
  });
});

describe("backendStateLabel", () => {
  it("formats machine approval state", () => {
    expect(backendStateLabel("NeedsMachineAuth")).toBe("Needs Approval");
  });
});

describe("healthSummary", () => {
  it("returns the first non-empty health message", () => {
    expect(healthSummary(["", "Tailscale is stopped."])).toBe("Tailscale is stopped.");
  });
});

describe("firstIpv4", () => {
  it("prefers IPv4 addresses", () => {
    expect(firstIpv4(["fd7a::1", "100.64.0.1"])).toBe("100.64.0.1");
  });

  it("falls back to the first address", () => {
    expect(firstIpv4(["fd7a::1"])).toBe("fd7a::1");
  });
});

describe("prefs helpers", () => {
  it("detects exit-node advertisement from default routes", () => {
    expect(advertiseExitNodeEnabled({ AdvertiseRoutes: ["10.0.0.0/24", "0.0.0.0/0"] })).toBe(true);
  });

  it("inverts NoStatefulFiltering", () => {
    expect(statefulFilteringEnabled({ NoStatefulFiltering: true })).toBe(false);
  });
});

describe("exitNodeLabel", () => {
  it("prefers a friendly exit-node name", () => {
    expect(exitNodeLabel({ name: "woody", dnsName: "woody.ts.net", ip: "100.64.0.1" })).toBe("woody");
  });
});
