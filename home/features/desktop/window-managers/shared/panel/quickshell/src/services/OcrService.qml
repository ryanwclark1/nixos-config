pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // ── Public state ─────────────────────────────
    property string lastOcrText: ""
    property bool ocrBusy: false
    property bool isAvailable: false

    // ── Signals ──────────────────────────────────
    signal ocrCompleted(string text)
    signal ocrFailed(string error)
    signal ocrSelectionRequested()

    // ── Actions ──────────────────────────────────
    function ocrRegion() {
        root.ocrSelectionRequested();
    }

    function ocrArea(x, y, w, h) {
        if (root.ocrBusy) return;
        root._waitingForCapture = true;
        ScreenshotService.captureArea(x, y, w, h);
    }

    function ocrFromPath(imagePath) {
        if (root.ocrBusy) return;
        root.ocrBusy = true;
        root._ocrStdout = "";
        root._ocrStderrText = "";
        root._ocrExitCode = -1;
        root._ocrExitObserved = false;
        root._ocrStdoutFinished = false;
        root._ocrStderrFinished = false;

        _ocrProc.command = DependencyService.resolveCommand("qs-ocr", [imagePath]);
        _ocrProc.running = true;
    }

    // ── Internal ─────────────────────────────────
    property bool _waitingForCapture: false
    property string _ocrStdout: ""
    property string _ocrStderrText: ""
    property int _ocrExitCode: -1
    property bool _ocrExitObserved: false
    property bool _ocrStdoutFinished: false
    property bool _ocrStderrFinished: false

    // Check tesseract availability on startup
    property Process _checkProc: Process {
        command: ["sh", "-c", "command -v tesseract"]
        onExited: (exitCode, exitStatus) => {
            root.isAvailable = (exitCode === 0);
        }
        Component.onCompleted: running = true
    }

    // Listen for region captures to OCR
    property Connections _captureConn: Connections {
        target: ScreenshotService
        function onRegionCaptured(path) {
            if (root._waitingForCapture) {
                root._waitingForCapture = false;
                root.ocrFromPath(path);
            }
        }
    }

    function _resetOcrState() {
        root.ocrBusy = false;
        root._ocrStdout = "";
        root._ocrStderrText = "";
        root._ocrExitCode = -1;
        root._ocrExitObserved = false;
        root._ocrStdoutFinished = false;
        root._ocrStderrFinished = false;
    }

    function _finalizeOcr() {
        var result = (root._ocrStdout || "").trim();
        var parts = result.split("|");
        var status = parts[0] || "";
        var payload = parts.slice(1).join("|");

        if (status === "OK" && payload) {
            root.lastOcrText = payload;
            root.ocrCompleted(payload);
            var preview = payload.length > 80 ? payload.substring(0, 80) + "..." : payload;
            ToastService.showSuccess("Text Copied", preview);
        } else if (status === "ERROR" && payload === "no text detected") {
            ToastService.showInfo("OCR", "No text detected");
            root.ocrFailed("no text detected");
        } else if (status === "ERROR" && payload) {
            ToastService.showError("OCR Failed", payload);
            root.ocrFailed(payload);
        } else {
            var msg = root._ocrStderrText || "Unknown error";
            ToastService.showError("OCR Failed", msg);
            root.ocrFailed(msg);
        }

        root._resetOcrState();
    }

    function _maybeFinalizeOcr() {
        if (!root._ocrExitObserved || !root._ocrStdoutFinished || !root._ocrStderrFinished)
            return;
        root._finalizeOcr();
    }

    property Process _ocrProc: Process {
        running: false
        onExited: (exitCode, exitStatus) => {
            root._ocrExitCode = exitCode;
            root._ocrExitObserved = true;
            root._maybeFinalizeOcr();
        }
        stdout: StdioCollector {
            onStreamFinished: {
                root._ocrStdout = this.text || "";
                root._ocrStdoutFinished = true;
                root._maybeFinalizeOcr();
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                root._ocrStderrText = (this.text || "").trim();
                root._ocrStderrFinished = true;
                root._maybeFinalizeOcr();
            }
        }
    }
}
