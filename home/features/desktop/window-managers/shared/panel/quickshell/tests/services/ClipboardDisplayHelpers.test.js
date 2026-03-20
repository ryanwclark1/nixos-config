import { describe, it, expect } from "vitest";
import {
  isBinaryData,
  isImageContent,
  binarySummary,
  displayText,
  launcherItem,
} from "../../src/services/ClipboardDisplayHelpers.js";

describe("ClipboardDisplayHelpers", () => {
  it("detects image clipboard placeholders by mime hint", () => {
    expect(isBinaryData("[[ binary data 640x480 png ]]")).toBe(true);
    expect(isImageContent("[[ binary data 640x480 png ]]")).toBe(true);
    expect(isImageContent("[[ binary data application/pdf ]]")).toBe(false);
  });

  it("extracts readable summary text from binary clipboard markers", () => {
    expect(binarySummary("[[ binary data 640x480 png ]]")).toBe("640x480 png");
    expect(displayText("[[ binary data 640x480 png ]]")).toBe("640x480 png");
    expect(displayText("plain clipboard text")).toBe("plain clipboard text");
  });

  it("builds launcher clipboard items with image metadata", () => {
    expect(
      launcherItem({ id: "101", content: "[[ binary data 640x480 png ]]" })
    ).toMatchObject({
      id: "101",
      name: "640x480 png",
      description: "Clipboard image",
      icon: "image.svg",
      clipIsImage: true,
    });
  });

  it("keeps plain text clipboard entries as text rows", () => {
    expect(
      launcherItem({ id: "102", content: "npm test -- --runInBand" })
    ).toMatchObject({
      id: "102",
      name: "npm test -- --runInBand",
      description: "",
      icon: "copy.svg",
      clipIsImage: false,
    });
  });
});
