import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const nightLightServicePath = resolve(quickshellRoot, "src/services/NightLightService.qml");

describe("NightLightService contract", () => {
  it("keeps wake recovery wired through the shared suspend manager connection pattern", () => {
    const source = readFileSync(nightLightServicePath, "utf8");

    expect(source).toContain("property Connections _suspendConn: Connections {");
    expect(source).toContain("target: SuspendManager");
    expect(source).not.toContain("property Connections suspendConn: Connections {");
    expect(source).not.toContain("id: suspendConn");
  });
});
