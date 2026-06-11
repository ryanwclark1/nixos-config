import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");

function source(relativePath) {
  return readFileSync(resolve(quickshellRoot, relativePath), "utf8");
}

describe("ClipboardMenu contract", () => {
  it("provides an option to open clipboard images in a viewer", () => {
    const menu = source("src/features/clipboard/ClipboardMenu.qml");

    // Function exists
    expect(menu).toContain("function openClipboardImage(path)");
    expect(menu).toContain('Quickshell.execDetached(["xdg-open", path])');

    // Button exists in the delegate
    expect(menu).toContain("id: openBtn");
    expect(menu).toContain('icon: "open.svg"');
    expect(menu).toContain('visible: clipCard.isImage && clipCard.imageSrc !== ""');
    expect(menu).toContain('tooltipText: "Open in viewer"');
    expect(menu).toContain("onClicked: root.openClipboardImage(clipCard.imageSrc)");

    // MouseArea click protection
    expect(menu).toContain("if (deleteBtn.containsMouse || (openBtn && openBtn.containsMouse))");
  });
});
