import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");

const managerPath = resolve(quickshellRoot, "src/features/notifications/NotificationManager.qml");
const delegatePath = resolve(quickshellRoot, "src/features/notifications/NotificationDelegate.qml");

describe("Notification timestamp contract", () => {
  // The Quickshell C++ Notification type does NOT have a .time property.
  // Timestamps must be injected via _receivedAt in onNotification handler.
  // See: https://quickshell.org/docs/v0.2.1/types/Quickshell.Services.Notifications/Notification

  it("NotificationManager injects _receivedAt on incoming notifications", () => {
    const source = readFileSync(managerPath, "utf8");
    expect(source).toContain("notif._receivedAt = new Date()");
  });

  it("NotificationDelegate uses _receivedAt, not .time", () => {
    const source = readFileSync(delegatePath, "utf8");
    expect(source).toContain("notification._receivedAt");
    expect(source).not.toContain("notification.time");
  });
});
