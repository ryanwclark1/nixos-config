import QtQuick
import Quickshell
import Quickshell.Io
import "../../services"

Scope {
    id: root

    property bool _isOpen: false

    // ── Action to perform after selection ───────
    // "screenshot" = capture region, "ocr" = OCR the region
    property string _pendingAction: "screenshot"

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
            // Future: OCR support
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
    }

    // ── Global shortcut ─────────────────────────
    GlobalShortcut {
        name: "regionScreenshot"
        description: "Select a screen region to capture"
        onPressed: root.open("screenshot")
    }

    // ── Wire up ScreenshotService signal ────────
    Connections {
        target: ScreenshotService
        function onRegionSelectionRequested() {
            root.open("screenshot");
        }
    }
}
