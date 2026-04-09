import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const clipboardHistoryServicePath = resolve(quickshellRoot, "src/services/ClipboardHistoryService.qml");

describe("ClipboardHistoryService contracts", () => {
  it("only surfaces decoded clipboard previews after mime validation", () => {
    const source = readFileSync(clipboardHistoryServicePath, "utf8");

    expect(source).toContain('import "ClipboardDisplayHelpers.js" as ClipboardDisplay');
    expect(source).toContain("ClipboardDisplay.imagePreviewExtension");
    expect(source).toContain('mt=$(file -Lb --mime-type');
    expect(source).toContain("image/png|image/jpeg|image/webp|image/gif|image/bmp");
    expect(source).toContain("property var _parsedMap: ({})");
    expect(source).toContain("root._decodedImages = Object.assign({}, _parsedMap);");
  });
});
