pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // ── Public state ─────────────────────────────
    property string lastScreenshotPath: ""
    property bool capturing: false

    // ── Signals ──────────────────────────────────
    signal captureStarted()
    signal captureCompleted(string path)
    signal captureFailed(string error)

    // ── Actions ──────────────────────────────────
    function captureRegion() { _capture("region", ""); }
    function captureScreen(monitorName) { _capture("screen", monitorName || ""); }
    function captureFullscreen() { _capture("fullscreen", ""); }

    function _capture(mode, monitor) {
        if (root.capturing) return;
        root.capturing = true;
        root.captureStarted();

        _captureProc.command = monitor
            ? ["qs-screenshot", mode, monitor]
            : ["qs-screenshot", mode];
        _captureProc.running = true;
    }

    property Process _captureProc: Process {
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.capturing = false;
                var result = (this.text || "").trim();
                var parts = result.split("|");

                if (parts[0] === "OK" && parts[1]) {
                    root.lastScreenshotPath = parts[1];
                    root.captureCompleted(parts[1]);
                    // Notify
                    Quickshell.execDetached([
                        "notify-send", "-i", "camera-photo",
                        "Screenshot captured",
                        "Saved to " + parts[1] + " and copied to clipboard"
                    ]);
                } else if (parts[0] === "ERROR" && parts[1] === "cancelled") {
                    // User cancelled slurp — silent
                } else {
                    var msg = parts.length > 1 ? parts[1] : "Unknown error";
                    root.captureFailed(msg);
                }
            }
        }
    }

    function openScreenshotsFolder() {
        Quickshell.execDetached(["xdg-open", (Quickshell.env("HOME") || "/home") + "/Pictures/Screenshots"]);
    }
}
