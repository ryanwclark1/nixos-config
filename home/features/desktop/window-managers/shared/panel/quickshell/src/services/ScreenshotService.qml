pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // ── Public state ─────────────────────────────
    property string lastScreenshotPath: ""
    property string lastRegionPath: ""
    property bool capturing: false
    property string _captureMode: ""
    property string _captureMonitor: ""
    property string _captureStdout: ""
    property string _captureStderr: ""

    // ── Signals ──────────────────────────────────
    signal captureCompleted(string path)
    signal regionCaptured(string path)
    signal captureFailed(string error)

    // ── Actions ──────────────────────────────────
    function captureRegion() { _capture("region", ""); }
    function captureScreen(monitorName) { _capture("screen", monitorName || ""); }
    function captureFullscreen() { _capture("fullscreen", ""); }

    function _capture(mode, monitor) {
        if (root.capturing) return;
        root.capturing = true;
        root._captureMode = mode;
        root._captureMonitor = monitor || "";
        root._captureStdout = "";
        root._captureStderr = "";

        _captureProc.command = DependencyService.resolveCommand("qs-screenshot",
            root._captureMonitor !== ""
                ? [root._captureMode, root._captureMonitor]
                : [root._captureMode]
        );
        _captureProc.running = true;
    }

    function _resetCaptureState() {
        root.capturing = false;
        root._captureMode = "";
        root._captureMonitor = "";
        root._captureStdout = "";
        root._captureStderr = "";
    }

    property Process _captureProc: Process {
        running: false
        onExited: (exitCode, exitStatus) => {
                var result = (root._captureStdout || "").trim();
                var parts = result.split("|");

                if (exitCode === 0 && parts[0] === "OK" && parts[1]) {
                    var path = parts[1];
                    root.lastScreenshotPath = path;
                    if (root._captureMode === "region") {
                        root.lastRegionPath = path;
                        root.regionCaptured(path);
                    }
                    root.captureCompleted(path);
                    // Notify
                    Quickshell.execDetached([
                        "notify-send", "-i", "camera-photo",
                        "Screenshot captured",
                        "Saved to " + parts[1] + " and copied to clipboard"
                    ]);
                } else if (parts[0] === "ERROR" && parts[1] === "cancelled") {
                    // User cancelled slurp — silent
                } else {
                    var msg = parts.length > 1 && parts[1] ? parts[1] : root._captureStderr;
                    if (!msg || msg.trim() === "")
                        msg = exitCode === 0 ? "Unknown error" : "qs-screenshot exited with code " + exitCode;
                    root.captureFailed(msg);
                    ToastService.showError("Screenshot failed", msg);
                }

                root._resetCaptureState();
        }
        stdout: StdioCollector {
            onStreamFinished: {
                root._captureStdout = this.text || "";
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                root._captureStderr = (this.text || "").trim();
            }
        }
    }

    function openScreenshotsFolder() {
        Quickshell.execDetached(["xdg-open", (Quickshell.env("HOME") || "/home") + "/Pictures/Screenshots"]);
    }
}
