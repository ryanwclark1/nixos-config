import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");

describe("Hypridle sync wiring", () => {
  it("registers the sync service and starts it from ShellRoot", () => {
    const qmldir = readFileSync(resolve(quickshellRoot, "src/services/qmldir"), "utf8");
    const shellRoot = readFileSync(resolve(quickshellRoot, "src/app/ShellRoot.qml"), "utf8");

    expect(qmldir).toContain("singleton HypridleSyncService 1.0 HypridleSyncService.qml");
    expect(shellRoot).toContain("void HypridleSyncService;");
  });
});
