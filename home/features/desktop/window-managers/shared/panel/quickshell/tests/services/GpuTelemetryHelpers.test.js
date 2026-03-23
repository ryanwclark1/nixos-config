import { describe, it, expect } from "vitest";
import {
  amdgpuFdinfoUsage,
  findMatchingAmdgpuTopDevice,
  normalizeGpuCandidate,
  selectPreferredAmdgpuTopDevice,
  selectPreferredGpuCandidate,
} from "../../src/services/GpuTelemetryHelpers.js";

describe("GpuTelemetryHelpers", () => {
  it("keeps the only GPU candidate", () => {
    const selected = selectPreferredGpuCandidate([
      { cardName: "/sys/class/drm/card0", pciAddress: "0000:0f:00.0", busyPercent: 12, vramTotalBytes: 2 * 1024 * 1024 },
    ]);

    expect(selected.cardName).toBe("card0");
    expect(selected.pciAddress).toBe("0000:0f:00.0");
  });

  it("prefers the larger-VRAM device when sysfs candidates do not expose GPU type", () => {
    const selected = selectPreferredGpuCandidate([
      { cardName: "card0", pciAddress: "0000:0f:00.0", busyPercent: 0, vramTotalBytes: 2147483648 },
      { cardName: "card1", pciAddress: "0000:03:00.0", busyPercent: 18, vramTotalBytes: 17163091968 },
    ]);

    expect(selected.cardName).toBe("card1");
    expect(selected.busyPercent).toBe(18);
  });

  it("uses card index as the stable final tie-breaker", () => {
    const selected = selectPreferredGpuCandidate([
      { cardName: "card2", pciAddress: "0000:04:00.0", busyPercent: 5, vramTotalBytes: 4294967296 },
      { cardName: "card1", pciAddress: "0000:03:00.0", busyPercent: 5, vramTotalBytes: 4294967296 },
    ]);

    expect(selected.cardName).toBe("card1");
  });

  it("prefers an explicit dGPU from amdgpu_top data", () => {
    const devices = [
      {
        Info: {
          "GPU Type": "APU",
          DevicePath: { card: "/dev/dri/card0", pci: "0000:0f:00.0" },
        },
        VRAM: { "Total VRAM": { value: 2048 } },
        gpu_activity: { GFX: { value: 0 } },
      },
      {
        Info: {
          "GPU Type": "dGPU",
          DevicePath: { card: "/dev/dri/card1", pci: "0000:03:00.0" },
        },
        VRAM: { "Total VRAM": { value: 16368 } },
        gpu_activity: { GFX: { value: 17 } },
      },
    ];

    expect(selectPreferredAmdgpuTopDevice(devices)).toBe(devices[1]);
  });

  it("matches amdgpu_top devices by card or PCI identity", () => {
    const devices = [
      {
        Info: {
          "GPU Type": "APU",
          DevicePath: { card: "/dev/dri/card0", pci: "0000:0f:00.0" },
        },
      },
      {
        Info: {
          "GPU Type": "dGPU",
          DevicePath: { card: "/dev/dri/card1", pci: "0000:03:00.0" },
        },
      },
    ];

    expect(findMatchingAmdgpuTopDevice(devices, { cardName: "card1" })).toBe(devices[1]);
    expect(findMatchingAmdgpuTopDevice(devices, { pciAddress: "0000:0f:00.0" })).toBe(devices[0]);
  });

  it("unwraps the nested amdgpu_top fdinfo usage shape", () => {
    const usage = amdgpuFdinfoUsage({
      usage: {
        name: "quickshell",
        usage: {
          GFX: { value: 12 },
          VRAM: { value: 256 },
        },
      },
    });

    expect(usage.GFX.value).toBe(12);
    expect(usage.VRAM.value).toBe(256);
  });

  it("normalizes card names from sysfs and /dev/dri paths", () => {
    expect(normalizeGpuCandidate({ cardName: "/sys/class/drm/card1" }).cardName).toBe("card1");
    expect(normalizeGpuCandidate({ cardName: "/dev/dri/card0" }).cardName).toBe("card0");
  });
});
