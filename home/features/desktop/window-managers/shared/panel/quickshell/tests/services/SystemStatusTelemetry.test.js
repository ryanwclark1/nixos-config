import { describe, it, expect } from "vitest";
import {
  parseTaggedStats,
  formatPercent,
  formatUsedTotal,
} from "../../src/services/SystemStatusTelemetry.js";

describe("SystemStatusTelemetry.parseTaggedStats", () => {
  it("parses tagged detailed telemetry without relying on placeholder lines", () => {
    const raw = [
      "cpu_raw\tcpu  1 2 3 4 5 6 7 8 0 0",
      "ram_used_text\t29.9GB",
      "ram_total_text\t123.5GB",
      "ram_frac\t0.24196347",
      "swap_used_text\t36.0GB",
      "swap_total_text\t68.0GB",
      "disk_pct\t74%",
      "net_rx\t123456",
      "net_tx\t654321",
      "",
    ].join("\n");

    expect(parseTaggedStats(raw)).toEqual({
      cpuRaw: "cpu  1 2 3 4 5 6 7 8 0 0",
      ramUsedText: "29.9GB",
      ramTotalText: "123.5GB",
      ramFrac: "0.24196347",
      swapUsedText: "36.0GB",
      swapTotalText: "68.0GB",
      diskPct: "74%",
      netRx: "123456",
      netTx: "654321",
    });
  });

  it("ignores leading whitespace, blank lines, and unknown tags", () => {
    const raw = "\n\nunknown\tignored\nram_frac\t0.50\nnet_rx\t42\n";

    expect(parseTaggedStats(raw)).toMatchObject({
      ramFrac: "0.50",
      netRx: "42",
    });
    expect(parseTaggedStats(raw).cpuRaw).toBe("");
  });
});

describe("SystemStatusTelemetry formatters", () => {
  it("formats percentages with clamping", () => {
    expect(formatPercent(0.24196347)).toBe("24%");
    expect(formatPercent(1.2)).toBe("100%");
    expect(formatPercent(-1)).toBe("--");
  });

  it("formats used/total strings with sensible fallbacks", () => {
    expect(formatUsedTotal("29.9GB", "123.5GB", "--")).toBe("29.9GB / 123.5GB");
    expect(formatUsedTotal("29.9GB", "", "--")).toBe("29.9GB");
    expect(formatUsedTotal("", "", "--")).toBe("--");
  });
});
