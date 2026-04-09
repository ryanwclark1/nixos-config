import { describe, it, expect } from "vitest";
import fs from "node:fs";
import path from "node:path";

const source = fs.readFileSync(
  path.resolve(import.meta.dirname, "../../src/shared/CardBase.qml"),
  "utf8"
);

describe("CardBase contract", () => {
  it("exposes an implicit height for loader-based layouts", () => {
    expect(source).toContain("implicitHeight: container.implicitHeight + root.pad * 2");
  });

  it("exposes an implicit width for loader-based layouts", () => {
    expect(source).toContain("implicitWidth: container.implicitWidth + root.pad * 2");
  });
});
