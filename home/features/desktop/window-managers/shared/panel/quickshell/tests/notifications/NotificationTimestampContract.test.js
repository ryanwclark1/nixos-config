import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");

const managerPath = resolve(quickshellRoot, "src/features/notifications/NotificationManager.qml");
const delegatePath = resolve(quickshellRoot, "src/features/notifications/NotificationDelegate.qml");
const centerPath = resolve(quickshellRoot, "src/features/notifications/NotificationCenter.qml");

// The Quickshell v0.2.1 Notification/NotificationAction C++ API:
//   Notification: appName, summary, body, appIcon, urgency, actions, image,
//                 dismiss(), expire(), sendInlineReply(), closed signal
//   NotificationAction: identifier, text, invoke()
// See: https://quickshell.org/docs/v0.2.1/types/Quickshell.Services.Notifications/

describe("Notification API contract", () => {
  it("NotificationManager injects _receivedAt on incoming notifications", () => {
    const source = readFileSync(managerPath, "utf8");
    expect(source).toContain("notif._receivedAt = new Date()");
  });

  it("NotificationDelegate uses _receivedAt, not nonexistent .time", () => {
    const source = readFileSync(delegatePath, "utf8");
    expect(source).toContain("notification._receivedAt");
    expect(source).not.toContain("notification.time");
  });

  it("NotificationCenter uses sendInlineReply, not nonexistent invoke", () => {
    const source = readFileSync(centerPath, "utf8");
    expect(source).toContain("notification.sendInlineReply(text)");
    expect(source).not.toContain("notification.invoke(text)");
  });

  it("NotificationDelegate uses NotificationAction.text, not .label", () => {
    const source = readFileSync(delegatePath, "utf8");
    // NotificationAction has .text property, not .label
    expect(source).not.toMatch(/modelData\.label/);
    expect(source).toContain("modelData.text");
  });
});
