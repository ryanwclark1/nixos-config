import { describe, expect, it } from "vitest";
import {
  ENTRY_TTL_MS,
  buildAppearanceLookup,
  buildCompanyLookup,
  buildServiceLookup,
  enrichEntry,
  markMissingEntries,
  mergeEntry,
  sectionedEntries,
  subtitleForEntry,
} from "../../src/services/BluetoothCatalog.js";

describe("BluetoothCatalog helpers", () => {
  it("retains recently seen available devices after a scan stops, then expires them", () => {
    const now = 1_000_000;
    let entries = {};

    entries["AA:BB:CC:DD:EE:FF"] = mergeEntry(entries["AA:BB:CC:DD:EE:FF"], {
      address: "aa:bb:cc:dd:ee:ff",
      name: "Hue lamp",
      paired: false,
      connected: false,
    }, now, "quickshell");

    entries = markMissingEntries(entries, {}, now + 30_000, ENTRY_TTL_MS);
    let sections = sectionedEntries(entries, now + 30_000, ENTRY_TTL_MS);
    expect(sections.available).toHaveLength(1);
    expect(sections.available[0].isLive).toBe(false);

    entries = markMissingEntries(entries, {}, now + ENTRY_TTL_MS + 1, ENTRY_TTL_MS);
    sections = sectionedEntries(entries, now + ENTRY_TTL_MS + 1, ENTRY_TTL_MS);
    expect(sections.available).toHaveLength(0);
  });

  it("groups devices by connected, paired, then available state", () => {
    const now = 2_000_000;
    let entries = {};
    entries["01"] = mergeEntry(entries["01"], { address: "01", name: "Mouse", connected: true, paired: true }, now, "bluez");
    entries["02"] = mergeEntry(entries["02"], { address: "02", name: "Keyboard", connected: false, paired: true }, now, "bluez");
    entries["03"] = mergeEntry(entries["03"], { address: "03", name: "Lamp", connected: false, paired: false }, now, "bluez");

    const sections = sectionedEntries(entries, now, ENTRY_TTL_MS);
    expect(sections.connected.map((item) => item.address)).toEqual(["01"]);
    expect(sections.paired.map((item) => item.address)).toEqual(["02"]);
    expect(sections.available.map((item) => item.address)).toEqual(["03"]);
    expect(sections.all.map((item) => item.address)).toEqual(["01", "02", "03"]);
  });

  it("resolves vendor, appearance, service names, and subtitle text from lookups", () => {
    const lookups = {
      companyLookup: buildCompanyLookup([{ code: 76, name: "Apple, Inc." }]),
      serviceLookup: buildServiceLookup([{ uuid: "1812", name: "Human Interface Device" }]),
      appearanceLookup: buildAppearanceLookup([{ category: 15, name: "HID", subcategory: [{ value: 2, name: "Mouse" }] }]),
    };

    const enriched = enrichEntry({
      address: "AA:BB:CC:DD:EE:FF",
      displayName: "Magic Mouse",
      manufacturerIds: [76],
      serviceUuids: ["1812"],
      appearance: (15 << 6) + 2,
      lastSeenMs: 1000,
      isLive: false,
    }, lookups, 121_000);

    expect(enriched.vendorName).toBe("Apple, Inc.");
    expect(enriched.appearanceName).toBe("Mouse");
    expect(enriched.serviceNames).toEqual(["Human Interface Device"]);
    expect(enriched.seenLabel).toBe("Seen 2m ago");
    expect(subtitleForEntry(enriched)).toBe("Apple, Inc. • AA:BB:CC:DD:EE:FF • Seen 2m ago");
  });
});
