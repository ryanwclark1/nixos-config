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

describe("notification center width contract", () => {
  it("uses a dedicated notification-center width instead of control-center width", () => {
    const shellRoot = source("src/app/ShellRoot.qml");
    const center = source("src/features/notifications/NotificationCenter.qml");

    expect(shellRoot).toContain("Config.notifCenterWidth");
    expect(shellRoot).toContain('NotificationCenter {\n            id: center\n            readonly property var layoutState: root.surfacePanelLayout(root.activeSurfaceContext, Config.notifCenterWidth)');
    expect(center).toContain("property int panelWidth: Config.notifCenterWidth");
    expect(center).toContain("readonly property bool compactLayout: panelWidth < 420");
  });
});

describe("notification history contract", () => {
  it("archives notifications from close events and prunes history by config", () => {
    const manager = source("src/features/notifications/NotificationManager.qml");
    const popups = source("src/features/notifications/Notifications.qml");

    expect(manager).toContain("function _attachCloseHandler(notification)");
    expect(manager).toContain("notification.closed.connect(function(reason)");
    expect(manager).toContain("NotificationCloseReason.Dismissed");
    expect(manager).toContain("NotificationCloseReason.Expired");
    expect(manager).toContain("NotificationCloseReason.CloseRequested");
    expect(manager).toContain("if (!n || !Config.notifHistoryEnabled || n.transient || n._archivedByShell)");
    expect(manager).toContain("function _normalizeArchive(entries)");
    expect(popups).toContain("notification.expire();");
  });
});
