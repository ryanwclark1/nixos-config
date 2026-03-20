import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const registryPath = resolve(quickshellRoot, "src/features/settings/components/SettingsRegistry.qml");

describe("SettingsRegistry contract", () => {
  it("points defaultTabId at a declared tab entry", () => {
    const source = readFileSync(registryPath, "utf8");
    const defaultTabId = (source.match(/readonly property string defaultTabId:\s*"([^"]+)"/) || [])[1];
    const tabIds = new Set([...source.matchAll(/\bid:\s*"([^"]+)"/g)].map((match) => match[1]));

    expect(defaultTabId).toBeTruthy();
    expect(tabIds.has(defaultTabId)).toBe(true);
  });

  it("defines icons for every top-level settings category", () => {
    const source = readFileSync(registryPath, "utf8");
    const categoriesBlock = source.split("readonly property var categories: [")[1].split("readonly property var tabs: [")[0];
    const categoryEntries = [...categoriesBlock.matchAll(/\{\s*id:\s*"([^"]+)"[\s\S]*?label:\s*"([^"]+)"[\s\S]*?\}/g)];
    const missingIcons = [];

    for (const entry of categoryEntries) {
      const chunk = entry[0];
      const categoryId = entry[1];
      if (!/\bicon:\s*"[^"]+"/.test(chunk))
        missingIcons.push(categoryId);
    }

    expect(missingIcons).toEqual([]);
  });

  it("validates search entries against declared tabs while filtering runtime results to supported tabs", () => {
    const source = readFileSync(registryPath, "utf8");

    expect(source).toContain("function findDeclaredTab(tabId)");
    expect(source).toContain("SearchIndex.validateIndex(findDeclaredTab);");
    expect(source).toContain("return SearchIndex.searchSettings(query).filter(function(result) {");
    expect(source).toContain("return findTab(result.tabId) !== null;");
  });
});
