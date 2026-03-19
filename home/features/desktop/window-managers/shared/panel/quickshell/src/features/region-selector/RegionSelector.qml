import QtQuick
import Quickshell
import Quickshell.Io
import "../../services"

Scope {
    id: root

    property bool _isOpen: false

    // ── Action to perform after selection ───────
    // "screenshot" = capture region, "ocr" = OCR the region, "analyze" = AI visual search
    property string _pendingAction: "screenshot"

    // ── Analyze flow state ──────────────────────
    property bool _waitingForAnalyze: false
    signal analyzeRegionCaptured(string path)

    function open(action) {
        if (root._isOpen) return;
        root._pendingAction = action || "screenshot";
        root._isOpen = true;
    }

    function dismiss() {
        root._isOpen = false;
    }

    function _handleRegionSelected(x, y, w, h) {
        root._isOpen = false;
        if (root._pendingAction === "screenshot") {
            ScreenshotService.captureArea(x, y, w, h);
        } else if (root._pendingAction === "ocr") {
            OcrService.ocrArea(x, y, w, h);
        } else if (root._pendingAction === "analyze") {
            root._waitingForAnalyze = true;
            ScreenshotService.captureArea(x, y, w, h);
        }
    }

    // ── Per-screen overlays ─────────────────────
    Variants {
        model: Quickshell.screens

        delegate: Loader {
            id: overlayLoader
            required property var modelData
            active: root._isOpen

            sourceComponent: RegionOverlay {
                screen: overlayLoader.modelData
                onDismissRequested: root.dismiss()
                onRegionSelected: (x, y, w, h) => root._handleRegionSelected(x, y, w, h)
            }
        }
    }

    // ── IPC ─────────────────────────────────────
    IpcHandler {
        target: "region"

        function screenshot() {
            root.open("screenshot");
        }
        function ocr() {
            root.open("ocr");
        }
        function analyze() {
            root.open("analyze");
        }
    }

    // Region screenshot accessible via IPC: quickshell ipc call region screenshot

    // ── Wire up ScreenshotService signals ───────
    Connections {
        target: ScreenshotService
        function onRegionSelectionRequested() {
            root.open("screenshot");
        }
        function onAnalyzeSelectionRequested() {
            root.open("analyze");
        }
        function onRegionCaptured(path) {
            if (root._waitingForAnalyze) {
                root._waitingForAnalyze = false;
                root.analyzeRegionCaptured(path);
            }
        }
    }

    // ── Wire up OcrService signal ───────────────
    Connections {
        target: OcrService
        function onOcrSelectionRequested() {
            root.open("ocr");
        }
    }
}
