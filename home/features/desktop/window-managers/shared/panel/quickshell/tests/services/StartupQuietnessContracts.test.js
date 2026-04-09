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
const wallpaperServicePath = resolve(quickshellRoot, "src/services/WallpaperService.qml");
const audioServicePath = resolve(quickshellRoot, "src/services/AudioService.qml");
const wallpaperLayerPath = resolve(quickshellRoot, "src/features/background/WallpaperLayer.qml");
const wallpaperTabPath = resolve(quickshellRoot, "src/features/settings/components/tabs/WallpaperTab.qml");

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

  it("defers wallpaper discovery off startup and exposes an env-gated scan isolation hook", () => {
    const source = readFileSync(wallpaperServicePath, "utf8");

    expect(source).toContain('QS_ENABLE_WALLPAPER_STARTUP_SCAN');
    expect(source).toContain('QS_DEBUG_DISABLE_WALLPAPER_SCAN');
    expect(source).toContain("property Timer startupScanTimer: Timer");
    expect(source).toContain('Logger.i("WallpaperService", "startup wallpaper scan deferred until first use"');
    expect(source).toContain('scheduleStartupScan("Component.onCompleted")');
    expect(source).not.toContain("    scanWallpapers();");
  });

  it("supports env-gated audio and video startup isolation for warning triage", () => {
    const audioSource = readFileSync(audioServicePath, "utf8");
    const wallpaperLayerSource = readFileSync(wallpaperLayerPath, "utf8");

    expect(audioSource).toContain('QS_DEBUG_DISABLE_AUDIO_SERVICE');
    expect(audioSource).toContain('Logger.i("AudioService", "audio service disabled via QS_DEBUG_DISABLE_AUDIO_SERVICE")');
    expect(wallpaperLayerSource).toContain('QS_DEBUG_DISABLE_VIDEO_WALLPAPER');
    expect(wallpaperLayerSource).toContain('Logger.i("WallpaperLayer", "video wallpaper disabled via QS_DEBUG_DISABLE_VIDEO_WALLPAPER")');
  });

  it("loads wallpaper inventory on demand when the wallpaper settings tab becomes visible", () => {
    const source = readFileSync(wallpaperTabPath, "utf8");

    expect(source).toContain("function ensureWallpaperInventory()");
    expect(source).toContain("onVisibleChanged:");
    expect(source).toContain("ensureWallpaperInventory();");
    expect(source).not.toContain("Component.onCompleted: {\n        if (!wallpaperMonProc.running)\n            wallpaperMonProc.running = true;\n        if (WallpaperService.availableWallpapers.length === 0)");
  });
});
