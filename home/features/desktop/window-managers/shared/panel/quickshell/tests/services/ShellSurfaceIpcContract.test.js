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

describe("Shell surface IPC contract", () => {
  it("routes affected QML and launcher callers through shellSurfaceCall", () => {
    const files = [
      "src/features/clipboard/ClipboardMenu.qml",
      "src/features/settings/components/tabs/HyprlandTab.qml",
      "src/features/time/DateTimeMenu.qml",
      "src/features/system/surfaces/SystemStatsMenu.qml",
      "src/launcher/LauncherShellIpcActions.js",
    ];

    for (const path of files) {
      const text = source(path);
      expect(text).toContain("shellSurfaceCall(");
      expect(text).not.toMatch(/ipcCall\("Shell", "(openSurface|toggleSurface)", "[^"]+"\)/);
    }
  });

  it("keeps QA helpers and docs on the fixed-arity Shell IPC form", () => {
    const manualQa = source("scripts/manual-qa.sh");
    const checklist = source("MANUAL_QA_CHECKLIST.md");

    expect(manualQa).toContain('quickshell ipc call Shell openSurface controlCenter ""');
    expect(manualQa).toContain('quickshell ipc call Shell openSurface networkMenu ""');
    expect(checklist).toContain('quickshell ipc call Shell openSurface controlCenter ""');
    expect(checklist).toContain('quickshell ipc call Shell openSurface notifCenter ""');
  });

  it("defaults qs open/toggle to an empty screen name", () => {
    const cli = source("scripts/qs-cli.sh");

    expect(cli).toContain('screen_name="${2:-}"');
    expect(cli).toContain('exec quickshell ipc call Shell toggleSurface "${surface_id}" "${screen_name}"');
    expect(cli).toContain('exec quickshell ipc call Shell openSurface "${surface_id}" "${screen_name}"');
  });
});
