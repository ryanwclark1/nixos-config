import { describe, it, expect } from "vitest";
import { readFileSync, readdirSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";
import { _MAPS } from "../../src/services/config/ConfigPersistence.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const tabsDir = resolve(quickshellRoot, "src/features/settings/components/tabs");
const configPath = resolve(quickshellRoot, "src/services/Config.qml");
const autoSavePath = resolve(quickshellRoot, "src/services/ConfigAutoSave.qml");

function persistedConfigProperties() {
  const properties = new Set();

  for (const entries of Object.values(_MAPS)) {
    for (const entry of entries)
      properties.add(entry[1]);
  }

  [
    "barConfigs",
    "selectedBarId",
    "controlCenterWidth",
    "disabledPlugins",
    "pluginLauncherTriggers",
    "pluginLauncherNoTrigger",
    "pluginSettings",
    "pluginHotReload",
  ].forEach((property) => properties.add(property));

  return properties;
}

function configProperties() {
  const source = readFileSync(configPath, "utf8");
  return new Set(
    [...source.matchAll(/^\s*property\s+\w+\s+([A-Za-z0-9_]+)\s*:/gm)].map((match) => match[1]),
  );
}

function settingsWrittenProperties() {
  const usage = new Map();

  for (const fileName of readdirSync(tabsDir)) {
    if (!fileName.endsWith(".qml"))
      continue;

    const source = readFileSync(resolve(tabsDir, fileName), "utf8");

    for (const match of source.matchAll(/Config\.([A-Za-z0-9_]+)\s*=/g)) {
      const property = match[1];
      if (!usage.has(property))
        usage.set(property, new Set());
      usage.get(property).add(fileName);
    }

    for (const match of source.matchAll(/configKey:\s*["']([A-Za-z0-9_]+)["']/g)) {
      const property = match[1];
      if (!usage.has(property))
        usage.set(property, new Set());
      usage.get(property).add(fileName);
    }
  }

  return usage;
}

function autoSaveHandlers() {
  const source = readFileSync(autoSavePath, "utf8");
  return new Set(
    [...source.matchAll(/function\s+on([A-Za-z0-9_]+)Changed\s*\(/g)].map((match) => {
      const handlerName = match[1];
      return handlerName[0].toLowerCase() + handlerName.slice(1);
    }),
  );
}

describe("ConfigAutoSave contract", () => {
  it("covers persisted Config properties written from settings tabs", () => {
    const persistedProps = persistedConfigProperties();
    const configProps = configProperties();
    const writtenProps = settingsWrittenProperties();
    const handlers = autoSaveHandlers();

    const unknownConfigProps = [];
    const missingPersistence = [];
    const missingHandlers = [];

    for (const [property, files] of writtenProps.entries()) {
      if (!configProps.has(property))
        unknownConfigProps.push(`${property} (${[...files].sort().join(", ")})`);
      const isPersisted = persistedProps.has(property);
      if (!isPersisted)
        missingPersistence.push(`${property} (${[...files].sort().join(", ")})`);
      if (isPersisted && !handlers.has(property))
        missingHandlers.push(`${property} (${[...files].sort().join(", ")})`);
    }

    expect(unknownConfigProps).toEqual([]);
    expect(missingPersistence).toEqual([]);
    expect(missingHandlers).toEqual([]);
  });
});
