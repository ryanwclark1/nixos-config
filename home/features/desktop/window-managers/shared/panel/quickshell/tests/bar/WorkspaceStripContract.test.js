import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const workspaceStripPath = resolve(quickshellRoot, "src/bar/widgets/WorkspaceStrip.qml");

describe("WorkspaceStrip contract", () => {
  it("does not attach QtQuick Layout sizing metadata to the strip root", () => {
    const source = readFileSync(workspaceStripPath, "utf8");

    expect(source).not.toContain("Layout.preferredWidth:");
    expect(source).not.toContain("import QtQuick.Layouts");
    expect(source).toContain("property bool showAddButton:");
    expect(source).not.toContain("readonly property bool showAddButton:");
    expect(source).toContain("property bool showMiniMap:");
    expect(source).not.toContain("readonly property bool showMiniMap:");
  });
});
