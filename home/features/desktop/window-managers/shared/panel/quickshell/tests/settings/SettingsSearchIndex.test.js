import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";
import { entries } from "../../src/features/settings/components/SettingsSearchIndex.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const componentsDir = resolve(quickshellRoot, "src/features/settings/components");
const tabsDir = resolve(componentsDir, "tabs");
const registryPath = resolve(componentsDir, "SettingsRegistry.qml");

const SHELL_SECTION_FILE_BY_MODE = {
  system: "ShellSystemSection.qml",
  "control-center": "ShellControlCenterSection.qml",
  launcher: "ShellLauncherSection.qml",
  "launcher-general": "ShellLauncherSection.qml",
  "launcher-search": "ShellLauncherSection.qml",
  "launcher-web": "ShellLauncherSection.qml",
  "launcher-modes": "ShellLauncherSection.qml",
  "launcher-runtime": "ShellLauncherSection.qml",
};

function tabComponentMap() {
  const source = readFileSync(registryPath, "utf8");
  const tabsMarker = "readonly property var tabs: [";
  const arrayStart = source.indexOf(tabsMarker);

  if (arrayStart === -1)
    throw new Error("Could not locate SettingsRegistry.tabs");

  const objects = [];
  let bracketDepth = 0;
  let braceDepth = 0;
  let stringQuote = "";
  let escaped = false;
  let objectStart = -1;

  for (let index = source.indexOf("[", arrayStart); index < source.length; index++) {
    const char = source[index];

    if (stringQuote) {
      if (escaped) {
        escaped = false;
        continue;
      }
      if (char === "\\") {
        escaped = true;
        continue;
      }
      if (char === stringQuote)
        stringQuote = "";
      continue;
    }

    if (char === '"' || char === "'") {
      stringQuote = char;
      continue;
    }

    if (char === "[") {
      bracketDepth += 1;
      continue;
    }

    if (char === "]") {
      bracketDepth -= 1;
      if (bracketDepth === 0)
        break;
      continue;
    }

    if (char === "{") {
      if (bracketDepth === 1 && braceDepth === 0)
        objectStart = index;
      braceDepth += 1;
      continue;
    }

    if (char === "}") {
      braceDepth -= 1;
      if (bracketDepth === 1 && braceDepth === 0 && objectStart !== -1) {
        objects.push(source.slice(objectStart, index + 1));
        objectStart = -1;
      }
    }
  }

  const map = new Map();
  for (const objectSource of objects) {
    const idMatch = objectSource.match(/\bid:\s*"([^"]+)"/);
    const componentMatch = objectSource.match(/\bcomponent:\s*"([^"]+)"/);
    if (idMatch && componentMatch)
      map.set(idMatch[1], componentMatch[1]);
  }

  return map;
}

function sourceForTab(tabId, componentsByTab) {
  const component = componentsByTab.get(tabId);
  if (!component)
    return null;

  const componentPath = resolve(tabsDir, component);
  const wrapperSource = readFileSync(componentPath, "utf8");
  const sectionModeMatch = wrapperSource.match(/sectionMode:\s*"([^"]+)"/);

  if (!sectionModeMatch)
    return { file: component, source: wrapperSource };

  const sectionFile = SHELL_SECTION_FILE_BY_MODE[sectionModeMatch[1]];
  if (!sectionFile)
    return { file: component, source: wrapperSource };

  return {
    file: sectionFile,
    source: readFileSync(resolve(tabsDir, sectionFile), "utf8"),
  };
}

describe("SettingsSearchIndex", () => {
  it("references supported entry types without duplicates", () => {
    const allowedTypes = new Set(["toggle", "slider", "mode", "select", "text", "color"]);
    const unsupportedTypes = [...new Set(entries.map((entry) => entry.type).filter((type) => !allowedTypes.has(type)))];
    const duplicates = [];
    const seen = new Set();

    for (const entry of entries) {
      const key = `${entry.tabId}|${entry.cardTitle}|${entry.label}`;
      if (seen.has(key))
        duplicates.push(key);
      seen.add(key);
    }

    expect(unsupportedTypes).toEqual([]);
    expect(duplicates).toEqual([]);
  });

  it("points to known tabs, cards, and labels in the settings source", () => {
    const componentsByTab = tabComponentMap();
    const failures = [];

    for (const entry of entries) {
      const source = sourceForTab(entry.tabId, componentsByTab);
      if (!source) {
        failures.push(`unknown tabId "${entry.tabId}"`);
        continue;
      }

      if (!source.source.includes(entry.cardTitle))
        failures.push(`${entry.tabId}: missing card "${entry.cardTitle}" in ${source.file}`);

      if (!source.source.includes(entry.label))
        failures.push(`${entry.tabId}: missing label "${entry.label}" in ${source.file}`);
    }

    expect(failures).toEqual([]);
  });
});
