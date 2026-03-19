import { describe, it, expect } from "vitest";
import {
  clampIndex,
  targetIndexFromMappedY,
  normalizedTargetIndex,
  moveArrayItem,
  moveValueToTarget,
  moveValueByDelta,
  orderCatalogItems,
} from "../../src/features/settings/components/SettingsReorderHelpers.js";

describe("SettingsReorderHelpers", () => {
  it("clamps indices into the valid range", () => {
    expect(clampIndex(-2, 4)).toBe(0);
    expect(clampIndex(2, 4)).toBe(2);
    expect(clampIndex(99, 4)).toBe(4);
  });

  it("computes drop targets from list coordinates", () => {
    expect(targetIndexFromMappedY(0, 40, 4, 5)).toBe(0);
    expect(targetIndexFromMappedY(44, 40, 4, 5)).toBe(1);
    expect(targetIndexFromMappedY(220, 40, 4, 5)).toBe(5);
  });

  it("normalizes insertion targets after removing the source item", () => {
    expect(normalizedTargetIndex(1, 4, 4)).toBe(3);
    expect(normalizedTargetIndex(3, 0, 4)).toBe(0);
  });

  it("moves array items to a new target index", () => {
    const result = moveArrayItem(["a", "b", "c", "d"], 1, 4);
    expect(result.changed).toBe(true);
    expect(result.targetIndex).toBe(3);
    expect(result.items).toEqual(["a", "c", "d", "b"]);
  });

  it("returns unchanged results for no-op array moves", () => {
    const result = moveArrayItem(["a", "b", "c"], 1, 2);
    expect(result.changed).toBe(false);
    expect(result.items).toEqual(["a", "b", "c"]);
  });

  it("moves a value by target slot", () => {
    const result = moveValueToTarget(["drun", "files", "ssh"], "ssh", 0);
    expect(result.changed).toBe(true);
    expect(result.items).toEqual(["ssh", "drun", "files"]);
  });

  it("moves a value by delta", () => {
    const result = moveValueByDelta(["bluetooth", "dnd", "recording"], "dnd", 1);
    expect(result.changed).toBe(true);
    expect(result.items).toEqual(["bluetooth", "recording", "dnd"]);
  });

  it("orders catalog items by explicit order and appends the rest", () => {
    const catalog = [
      { id: "bluetooth", label: "Bluetooth" },
      { id: "dnd", label: "DND" },
      { id: "recording", label: "Recording" },
    ];

    const ordered = orderCatalogItems(catalog, ["recording", "missing"], item => item.id);
    expect(ordered.map(item => item.id)).toEqual(["recording", "bluetooth", "dnd"]);
  });
});
