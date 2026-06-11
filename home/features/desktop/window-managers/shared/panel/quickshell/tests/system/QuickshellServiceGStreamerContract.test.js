import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";

const moduleText = readFileSync(resolve(__dirname, "../../default.nix"), "utf8");
const wallpaperLayerText = readFileSync(resolve(__dirname, "../../src/features/background/WallpaperLayer.qml"), "utf8");
const liveStreamOverlayText = readFileSync(resolve(__dirname, "../../src/features/unifi_protect/components/LiveStreamOverlay.qml"), "utf8");

describe("quickshell systemd GStreamer environment", () => {
  it("exposes GStreamer plugins needed by Qt Multimedia in the user service", () => {
    expect(moduleText).toContain('gstPluginPath = lib.makeSearchPath "lib/gstreamer-1.0"');
    expect(moduleText).toContain("GST_PLUGIN_SYSTEM_PATH_1_0=");
    expect(moduleText).toContain("pkgs.gst_all_1.gstreamer.out");
    expect(moduleText).toContain("pkgs.gst_all_1.gst-plugins-base");
    expect(moduleText).toContain("pkgs.gst_all_1.gst-plugins-good");
    expect(moduleText).toContain("pkgs.gst_all_1.gst-plugins-bad");
    expect(moduleText).toContain("pkgs.gst_all_1.gst-plugins-ugly");
    expect(moduleText).toContain("pkgs.gst_all_1.gst-libav");
  });
});

describe("video playback startup safety", () => {
  it("does not instantiate Qt Multimedia AudioOutput for muted video surfaces", () => {
    expect(wallpaperLayerText).not.toContain("AudioOutput");
    expect(liveStreamOverlayText).not.toContain("AudioOutput");
  });
});
