import { describe, it, expect } from "vitest";
import { stateText, iconName } from "../../src/features/power/BatteryHelpers.js";

// Mock UPower enum values matching Quickshell's UPower.DeviceState* constants
const UPowerEnums = {
  DeviceStateCharging: 1,
  DeviceStateFullyCharged: 4,
  DeviceStatePendingCharge: 5,
  DeviceStatePendingDischarge: 6,
};

describe("stateText", () => {
  it("returns 'Unknown' for null device", () => {
    expect(stateText(null, UPowerEnums)).toBe("Unknown");
  });

  it("returns 'Unknown' for undefined device", () => {
    expect(stateText(undefined, UPowerEnums)).toBe("Unknown");
  });

  it("returns 'Charging' for charging state", () => {
    expect(stateText({ state: 1 }, UPowerEnums)).toBe("Charging");
  });

  it("returns 'Fully charged' for fully charged state", () => {
    expect(stateText({ state: 4 }, UPowerEnums)).toBe("Fully charged");
  });

  it("returns 'Pending charge' for pending charge state", () => {
    expect(stateText({ state: 5 }, UPowerEnums)).toBe("Pending charge");
  });

  it("returns 'Pending discharge' for pending discharge state", () => {
    expect(stateText({ state: 6 }, UPowerEnums)).toBe("Pending discharge");
  });

  it("returns 'Discharging' for unrecognized state (fallthrough)", () => {
    expect(stateText({ state: 2 }, UPowerEnums)).toBe("Discharging");
  });

  it("returns 'Discharging' for device with no state property", () => {
    expect(stateText({}, UPowerEnums)).toBe("Discharging");
  });
});

describe("iconName", () => {
  it("maps charging devices to the shared charging svg", () => {
    expect(iconName({ state: 1, percentage: 0.4 }, UPowerEnums)).toBe("battery-charge.svg");
  });

  it("maps low battery devices to warning svg", () => {
    expect(iconName({ state: 2, percentage: 0.05 }, UPowerEnums)).toBe("battery-warning.svg");
  });

  it("maps healthy battery levels to stepped battery svgs", () => {
    expect(iconName({ state: 2, percentage: 0.72 }, UPowerEnums)).toBe("battery-7.svg");
  });
});
