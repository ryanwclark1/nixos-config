import { describe, it, expect } from "vitest";
import { stateText, iconName, isAcPowered } from "../../src/features/power/BatteryHelpers.js";

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

  it("infers Charging when time-to-full is set but state is discharging (UPower quirk)", () => {
    expect(stateText({ state: 2, timeToFull: 960, timeToEmpty: 0 }, UPowerEnums)).toBe("Charging");
  });
});

describe("isAcPowered", () => {
  it("returns false for null device", () => {
    expect(isAcPowered(null, UPowerEnums)).toBe(false);
  });

  it("returns true when charging, fully charged, or pending charge", () => {
    expect(isAcPowered({ state: 1 }, UPowerEnums)).toBe(true);
    expect(isAcPowered({ state: 4 }, UPowerEnums)).toBe(true);
    expect(isAcPowered({ state: 5 }, UPowerEnums)).toBe(true);
  });

  it("returns false for plain discharging and pending discharge", () => {
    expect(isAcPowered({ state: 2, percentage: 0.5 }, UPowerEnums)).toBe(false);
    expect(isAcPowered({ state: 6 }, UPowerEnums)).toBe(false);
  });

  it("returns true when time-to-full implies charging despite discharging state", () => {
    expect(isAcPowered({ state: 2, timeToFull: 600, timeToEmpty: 0 }, UPowerEnums)).toBe(true);
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

  it("maps discharging state with time-to-full to charging icon", () => {
    expect(iconName({ state: 2, percentage: 0.98, timeToFull: 600, timeToEmpty: 0 }, UPowerEnums)).toBe(
      "battery-charge.svg",
    );
  });
});
