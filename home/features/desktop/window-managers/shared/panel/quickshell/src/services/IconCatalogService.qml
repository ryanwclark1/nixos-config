pragma Singleton

import QtQuick
import Quickshell.Io
import "."

QtObject {
    id: root

    property var iconMap: ({})
    property bool loading: false
    property string lastError: ""

    function refresh() {
        if (_resolver.running)
            return;
        var command = DependencyService.resolveCommand("qs-icon-resolver");
        if (!command || command.length === 0) {
            lastError = "qs-icon-resolver unavailable";
            return;
        }
        lastError = "";
        loading = true;
        _resolver.command = command;
        _resolver.running = true;
    }

    Component.onCompleted: refresh()

    property Process _resolver: Process {
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.iconMap = JSON.parse(this.text || "{}");
                } catch (e) {
                    root.lastError = "icon map parse error";
                    Logger.w("IconCatalogService", "icon map parse error:", e);
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                var err = String(this.text || "").trim();
                if (err !== "")
                    root.lastError = err;
            }
        }
        onExited: exitCode => {
            root.loading = false;
            if (exitCode !== 0 && root.lastError === "") {
                root.lastError = "qs-icon-resolver exited " + exitCode;
                Logger.w("IconCatalogService", root.lastError);
            }
        }
    }
}
