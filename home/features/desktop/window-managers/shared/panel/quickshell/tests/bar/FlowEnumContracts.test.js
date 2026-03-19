import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const taskbarPath = resolve(quickshellRoot, "src/bar/widgets/Taskbar.qml");
const trayWidgetPath = resolve(quickshellRoot, "src/features/bar/components/TrayWidget.qml");

describe("Flow enum contracts", () => {
  it("keeps bar layout direction wiring on a runtime-safe code path", () => {
    const taskbarSource = readFileSync(taskbarPath, "utf8");
    const trayWidgetSource = readFileSync(trayWidgetPath, "utf8");

    expect(taskbarSource).toContain("sourceComponent: root.vertical ? verticalLayoutComponent : horizontalLayoutComponent");
    expect(taskbarSource).toContain("Row {");
    expect(taskbarSource).toContain("Column {");
    expect(taskbarSource).not.toContain("flow: vertical ? TopToBottom : LeftToRight");
    expect(trayWidgetSource).toContain("flow: vertical ? Flow.TopToBottom : Flow.LeftToRight");
    expect(trayWidgetSource).not.toContain("flow: vertical ? TopToBottom : LeftToRight");
  });
});
