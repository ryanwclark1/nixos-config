import { describe, it, expect } from "vitest";
import {
  audioOutputIcon,
  batteryIcon,
  bluetoothDeviceIcon,
  doNotDisturbIcon,
  gpuProcessToggleIcon,
  hookCategoryIcon,
  pluginTypeIcon,
  processFocusIcon,
  speechToggleIcon,
  sshCollectionIcon,
  sshSessionIcon,
  transportToggleIcon,
} from "../../src/services/IconHelpers.js";

const UPowerEnums = {
  DeviceStateCharging: 1,
  DeviceStateFullyCharged: 4,
  DeviceStatePendingCharge: 5,
};

describe("IconHelpers", () => {
  it("maps audio state to svg icons", () => {
    expect(audioOutputIcon(0.7, false, "")).toBe("speaker-2-filled.svg");
    expect(audioOutputIcon(0.2, true, "")).toBe("speaker-mute.svg");
  });

  it("maps battery and bluetooth state to svg icons", () => {
    expect(batteryIcon({ state: UPowerEnums.DeviceStateCharging, percentage: 0.4 }, UPowerEnums)).toBe("battery-charge.svg");
    expect(bluetoothDeviceIcon("MX Master Mouse")).toBe("cursor-click.svg");
  });

  it("maps transport and notification controls to svg icons", () => {
    expect(transportToggleIcon(true)).toBe("pause.svg");
    expect(speechToggleIcon(false)).toBe("mic-off.svg");
    expect(doNotDisturbIcon(true)).toBe("alert-off.svg");
  });

  it("maps ssh and plugin metadata to svg icons", () => {
    expect(sshCollectionIcon(true)).toBe("cloud.svg");
    expect(sshSessionIcon("rsync")).toBe("arrow-sync.svg");
    expect(pluginTypeIcon("launcher-provider")).toBe("globe-search.svg");
    expect(hookCategoryIcon("Compositor")).toBe("window-shield.svg");
  });

  it("maps focus and visibility affordances to svg icons", () => {
    expect(processFocusIcon(true, "settings.svg")).toBe("keyboard-dock.svg");
    expect(processFocusIcon(false, "settings.svg")).toBe("settings.svg");
    expect(gpuProcessToggleIcon(false)).toBe("grid.svg");
  });
});
