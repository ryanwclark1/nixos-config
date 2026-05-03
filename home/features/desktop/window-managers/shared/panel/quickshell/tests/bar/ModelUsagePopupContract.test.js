import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");
const widgetPath = resolve(quickshellRoot, "src/bar/components/ModelUsageBarWidget.qml");
const menuPath = resolve(quickshellRoot, "src/features/model-usage/ModelUsageMenu.qml");
const servicePath = resolve(quickshellRoot, "src/services/ModelUsageService.qml");
const surfaceServicePath = resolve(quickshellRoot, "src/services/SurfaceService.qml");

describe("AI Model Usage popup contract", () => {
  it("keeps the bar widget focused on a single generic launch icon", () => {
    const source = readFileSync(widgetPath, "utf8");

    expect(source).toContain("tooltipText: ModelUsageService.displayTooltip");
    expect(source).toContain('source: root.iconOnly ? ModelUsageService.providerIcon : "board.svg"');
    expect(source).toContain("color: ModelUsageService.providerColor");
  });

  it("keeps the popup title and provider tabs centered on AI Model Usage", () => {
    const source = readFileSync(menuPath, "utf8");

    expect(source).toContain('title: "AI Model Usage"');
    expect(source).toContain("popupMinWidth: 500; popupMaxWidth: 720; compactThreshold: 600");
    expect(source).toContain("implicitHeight: Math.min(1000, scrollContent.implicitHeight + 120)");
    expect(source).toContain('tooltipText: "Refresh"');
    expect(source).toContain('tooltipText: "Settings"');
    expect(source).toContain('text: "Providers"');
    expect(source).toContain('text: "Overview"');
    expect(source).toContain('label: "Claude Code"');
    expect(source).toContain('label: "Codex CLI"');
    expect(source).toContain('label: "Gemini CLI"');
    expect(source).toContain('selected: ModelUsageService.effectiveActiveProvider === modelData.key');
    expect(source).toContain('message: root.providerEmptyMessage()');
  });

  it("falls back to the first enabled provider when the saved provider is unavailable", () => {
    const source = readFileSync(servicePath, "utf8");

    expect(source).toContain("readonly property var enabledProviders:");
    expect(source).toContain("readonly property string effectiveActiveProvider:");
    expect(source).toContain("if (root.enabledProviders.indexOf(root.activeProvider) >= 0)");
    expect(source).toContain("return root.enabledProviders[0];");
    expect(source).toContain('readonly property string displayTooltip: root.hasEnabledProviders');
  });

  it("exposes Codex session limits and Gemini 24-hour usage in the popup service contract", () => {
    const menuSource = readFileSync(menuPath, "utf8");
    const serviceSource = readFileSync(servicePath, "utf8");

    expect(menuSource).toContain('text: "Last 24 Hours"');
    expect(menuSource).toContain('title: "Latest Session Breakdown"');
    expect(menuSource).toContain('title: "Current Session Usage"');
    expect(menuSource).toContain('title: "Usage Limits"');
    expect(menuSource).toContain('title: "Claude Token Breakdown"');
    expect(menuSource).toContain('title: "Gemini Token Details"');
    expect(serviceSource).toContain("property var codexTotalUsage: ({})");
    expect(serviceSource).toContain("property var codexRateLimits: ({})");
    expect(serviceSource).toContain("property int geminiLast24hPrompts: 0");
    expect(serviceSource).toContain("property int geminiLast24hSessions: 0");
    expect(serviceSource).toContain("property var geminiLast24hTokensByModel: ({})");
    expect(serviceSource).toContain("function formatUnixResetTime(epochSeconds)");
    expect(serviceSource).toContain("function usageWindowLabel(windowMinutes)");
  });

  it("registers the model usage popup in the shared surface registry", () => {
    const source = readFileSync(surfaceServicePath, "utf8");

    expect(source).toContain("modelUsageMenu: {");
    expect(source).toContain('legacyFlags: ["modelUsageMenuVisible"]');
    expect(source).toContain('focusPolicy: "preserve-app-focus"');
  });
});
