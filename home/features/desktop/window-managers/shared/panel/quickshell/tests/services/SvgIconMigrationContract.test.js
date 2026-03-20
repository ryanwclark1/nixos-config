import { describe, it, expect } from "vitest";
import { readdirSync, readFileSync, statSync } from "fs";
import { dirname, relative, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const srcDir = resolve(quickshellRoot, "src");

const iconLikePattern = /(?:return|icon\s*:|iconName\s*:|text\s*:|label\s*:).*(?:[\u2190-\u21FF\u2460-\u24FF\u25A0-\u27BF\u{1F300}-\u{1FAFF}]|[\uE000-\uF8FF])/u;

const allowlist = [
  {
    file: "bar/PanelWidgetHelpers.js",
    pattern: /SystemStatus\.net(?:Down|Up)/,
  },
  {
    file: "launcher/Launcher.qml",
    pattern: /Alt\+←\/→\/PgUp\/PgDn\/Home\/End\/0\/Backspace/,
  },
];

function walkFiles(dirPath) {
  const files = [];
  for (const entry of readdirSync(dirPath)) {
    const nextPath = resolve(dirPath, entry);
    const stats = statSync(nextPath);
    if (stats.isDirectory()) {
      files.push(...walkFiles(nextPath));
      continue;
    }
    if (/\.(qml|js)$/.test(entry))
      files.push(nextPath);
  }
  return files;
}

describe("SVG icon migration contract", () => {
  it("prevents new built-in glyph and symbol icons from reappearing", () => {
    const failures = [];

    for (const filePath of walkFiles(srcDir)) {
      const relPath = relative(srcDir, filePath).replace(/\\/g, "/");
      const lines = readFileSync(filePath, "utf8").split(/\r?\n/);

      lines.forEach((line, index) => {
        if (!iconLikePattern.test(line))
          return;

        const allowed = allowlist.some((entry) => entry.file === relPath && entry.pattern.test(line));
        if (!allowed)
          failures.push(`${relPath}:${index + 1}: ${line.trim()}`);
      });
    }

    expect(failures).toEqual([]);
  });
});
