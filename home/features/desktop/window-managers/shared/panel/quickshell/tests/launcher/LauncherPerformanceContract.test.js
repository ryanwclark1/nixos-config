import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const quickshellRoot = resolve(__dirname, "..", "..");

const shellRootPath = resolve(quickshellRoot, "src/app/ShellRoot.qml");
const launcherHostPath = resolve(quickshellRoot, "src/app/LauncherHost.qml");
const launcherPath = resolve(quickshellRoot, "src/launcher/Launcher.qml");
const taskbarPath = resolve(quickshellRoot, "src/bar/widgets/Taskbar.qml");
const systemStatusPath = resolve(quickshellRoot, "src/services/SystemStatus.qml");
const wallpaperTabPath = resolve(quickshellRoot, "src/features/settings/components/tabs/WallpaperTab.qml");
const wallpaperThumbImagePath = resolve(quickshellRoot, "src/widgets/WallpaperThumbImage.qml");

describe("launcher performance contract", () => {
  it("moves the public launcher IPC target into the lazy launcher host", () => {
    const shellRoot = readFileSync(shellRootPath, "utf8");
    const launcherHost = readFileSync(launcherHostPath, "utf8");
    const launcher = readFileSync(launcherPath, "utf8");

    expect(shellRoot).toContain("LauncherHost {");
    expect(launcherHost).toContain('target: "Launcher"');
    expect(launcher).not.toContain("LauncherIpcHandler {");
  });

  it("removes eager launcher and icon resolver startup work from the heavy launcher tree", () => {
    const launcher = readFileSync(launcherPath, "utf8");
    const taskbar = readFileSync(taskbarPath, "utf8");

    expect(launcher).not.toContain("initialAppsPreloadTimer.restart()");
    expect(launcher).not.toContain('command: ["qs-icon-resolver"]');
    expect(taskbar).not.toContain('command: ["qs-icon-resolver"]');
    expect(launcher).toContain("EmojiCatalogService.characterEntries");
  });

  it("keeps wallpaper browsing virtualized and system status summary-aware", () => {
    const wallpaperTab = readFileSync(wallpaperTabPath, "utf8");
    const wallpaperThumbImage = readFileSync(wallpaperThumbImagePath, "utf8");
    const systemStatus = readFileSync(systemStatusPath, "utf8");

    expect(wallpaperTab).toContain("GridView {");
    expect(wallpaperThumbImage).toContain("cache: false");
    expect(systemStatus).toContain("summarySubscriberCount");
    expect(systemStatus).toContain("addSummarySubscriber()");
  });
});
