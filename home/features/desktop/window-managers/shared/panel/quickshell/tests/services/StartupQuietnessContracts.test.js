import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");

const usageTrackerPath = resolve(quickshellRoot, "src/services/UsageTrackerService.qml");
const modelUsagePath = resolve(quickshellRoot, "src/services/ModelUsageService.qml");
const sshWidgetSettingsPath = resolve(quickshellRoot, "src/features/ssh/settings/SshWidgetSettings.qml");

describe("startup quietness contracts", () => {
  it("keeps UsageTrackerService file reads silent when the usage file is missing", () => {
    const source = readFileSync(usageTrackerPath, "utf8");

    expect(source).toContain('Quickshell.statePath("usage.json")');
    expect(source).toContain("blockLoading: true");
    expect(source).toContain("printErrors: false");
    expect(source).toContain("atomicWrites: true");
  });

  it("treats model-usage no-data responses as empty state instead of parse warnings", () => {
    const source = readFileSync(modelUsagePath, "utf8");

    expect(source).toContain("function _resetClaudeUsage()");
    expect(source).toContain("function _resetCodexUsage()");
    expect(source).toContain("function _resetGeminiUsage()");
    expect(source).toContain('if (data.error === "no data") {');
    expect(source).toContain("root._resetClaudeUsage();");
    expect(source).toContain("root._resetCodexUsage();");
    expect(source).toContain("root._resetGeminiUsage();");
  });

  it("resolves SSH settings helper components through the shared widget module", () => {
    const source = readFileSync(sshWidgetSettingsPath, "utf8");

    expect(source).toContain('import "../../../widgets/ssh-settings" as SshSettings');
    expect(source).toContain("SshSettings.SshHostList");
    expect(source).toContain("SshSettings.SshHostEditor");
    expect(source).toContain("SshSettings.SshImportDiagnostics");
    expect(source).toContain("SshSettings.SshSettingsOverview");
  });
});
