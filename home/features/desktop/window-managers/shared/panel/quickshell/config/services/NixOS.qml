pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property var generations: []
    property bool busy: false

    function refresh() {
        if (busy) return;
        busy = true;
        genProc.running = true;
    }

    Process {
        id: genProc
        command: ["sh", "-c", "nixos-rebuild list-generations"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n");
                var result = [];
                // Skip header
                for (var i = 1; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line === "") continue;
                    var parts = line.split(/\s+/);
                    if (parts.length >= 4) {
                        result.push({
                            id: parts[0],
                            date: parts[1] + " " + parts[2],
                            version: parts[3],
                            kernel: parts[4],
                            current: line.includes("current") || line.includes("True")
                        });
                    }
                }
                root.generations = result;
                root.busy = false;
            }
        }
    }

    function rollbackTo(id) {
        // Safe rollback via sudo -n (will fail if needs pass, but better than hanging)
        var cmd = ["sudo", "-n", "nix-env", "--profile", "/nix/var/nix/profiles/system", "--switch-generation", id];
        Quickshell.execDetached(cmd);
    }

    Component.onCompleted: refresh()
}
