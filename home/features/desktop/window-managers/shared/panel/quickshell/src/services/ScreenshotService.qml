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
    property int _captureExitCode: -1
    property bool _captureExitObserved: false
    property bool _captureStdoutFinished: false
    property bool _captureStderrFinished: false

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
        root._captureExitCode = -1;
        root._captureExitObserved = false;
        root._captureStdoutFinished = false;
        root._captureStderrFinished = false;

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
        root._captureExitCode = -1;
        root._captureExitObserved = false;
        root._captureStdoutFinished = false;
        root._captureStderrFinished = false;
    }

    function _finalizeCapture() {
        var result = (root._captureStdout || "").trim();
        var parts = result.split("|");

        if (root._captureExitCode === 0 && parts[0] === "OK" && parts[1]) {
            var path = parts[1];
            root.lastScreenshotPath = path;
            if (root._captureMode === "region") {
                root.lastRegionPath = path;
                root.regionCaptured(path);
            }
            root.captureCompleted(path);
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
                msg = root._captureExitCode === 0 ? "Unknown error" : "qs-screenshot exited with code " + root._captureExitCode;
            root.captureFailed(msg);
            ToastService.showError("Screenshot failed", msg);
        }

        root._resetCaptureState();
    }

    function _maybeFinalizeCapture() {
        if (!root._captureExitObserved || !root._captureStdoutFinished || !root._captureStderrFinished)
            return;
        root._finalizeCapture();
    }

    property Process _captureProc: Process {
        running: false
        onExited: (exitCode, exitStatus) => {
                root._captureExitCode = exitCode;
                root._captureExitObserved = true;
                root._maybeFinalizeCapture();
        }
        stdout: StdioCollector {
            onStreamFinished: {
                root._captureStdout = this.text || "";
                root._captureStdoutFinished = true;
                root._maybeFinalizeCapture();
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                root._captureStderr = (this.text || "").trim();
                root._captureStderrFinished = true;
                root._maybeFinalizeCapture();
            }
        }
    }

    function openScreenshotsFolder() {
        Quickshell.execDetached(["xdg-open", (Quickshell.env("HOME") || "/home") + "/Pictures/Screenshots"]);
    }
}
