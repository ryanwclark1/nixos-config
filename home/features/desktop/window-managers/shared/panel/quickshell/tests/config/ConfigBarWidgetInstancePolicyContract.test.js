import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const configBarManagerPath = resolve(
  quickshellRoot,
  "src/services/ConfigBarManager.qml"
);

describe("Config bar widget instance policy contract", () => {
  it("guards singleton widget adds in the config layer", () => {
    const source = readFileSync(configBarManagerPath, "utf8");

    expect(source).toContain('import "BarWidgetInstancePolicy.js" as BarWidgetInstancePolicy');
    expect(source).toContain("if (!BarWidgetInstancePolicy.canAddToBar(barConfig.sectionWidgets, widgetType))");
  });
});
