pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "."

// Parses ~/.config/niri/config.kdl for hotkey cheatsheet display.
// Falls back to built-in defaults if parsing fails.
// Watches the config file for live reload on save.
QtObject {
    id: root

    property var binds: ({ children: defaultBinds })
    property bool loaded: false
    property string configPath: ""
    property string errorMessage: ""

    readonly property string parserScript: {
        const envPath = Quickshell.env("QS_NIRI_PARSER");
        if (envPath) return envPath;
        return Qt.resolvedUrl("../../scripts/parse-niri-binds.py").toString().replace("file://", "");
    }

    function reload() {
        bindParser.running = true
    }

    property Process bindParser: Process {
        command: ["python3", root.parserScript]

        stdout: StdioCollector {
            id: stdoutCollector
            onStreamFinished: {
                const output = (stdoutCollector.text || "").trim()
                if (bindParser.exitCode !== 0 || output.length === 0) {
                    Logger.d("NiriBinds", "Parser unavailable, using defaults")
                    root.errorMessage = "Parser script failed"
                    return
                }
                try {
                    const result = JSON.parse(output)
                    if (!result) return
                    if (result.error) {
                        Logger.w("NiriBinds", "Parser error:", result.error)
                        root.errorMessage = result.error
                    } else if (result.children && result.children.length > 0) {
                        root.binds = result
                        root.configPath = result.configPath || ""
                        root.loaded = true
                    }
                } catch (e) {
                    Logger.w("NiriBinds", "JSON parse error:", e)
                    root.errorMessage = "Failed to parse output"
                }
            }
        }
    }

    property FileView _configWatcher: FileView {
        path: Quickshell.env("HOME") + "/.config/niri/config.kdl"
        watchChanges: true
        onFileChanged: reloadDebounce.restart()
    }

    property Timer reloadDebounce: Timer {
        interval: 300
        repeat: false
        onTriggered: root.reload()
    }

    Component.onCompleted: {
        if (CompositorAdapter.isNiri) reload()
    }

    readonly property var defaultBinds: [
        {
            name: "System",
            children: [{ keybinds: [
                { mods: ["Super"], key: "Tab", comment: "Niri Overview" },
                { mods: ["Super", "Shift"], key: "E", comment: "Quit Niri" },
                { mods: ["Super"], key: "Escape", comment: "Toggle shortcuts inhibit" }
            ]}]
        },
        {
            name: "Applications",
            children: [{ keybinds: [
                { mods: ["Super"], key: "T", comment: "Terminal" },
                { mods: ["Super"], key: "Return", comment: "Terminal" },
                { mods: ["Super"], key: "E", comment: "File manager" }
            ]}]
        },
        {
            name: "Window Management",
            children: [{ keybinds: [
                { mods: ["Super"], key: "Q", comment: "Close window" },
                { mods: ["Super"], key: "D", comment: "Maximize column" },
                { mods: ["Super"], key: "F", comment: "Fullscreen" },
                { mods: ["Super"], key: "A", comment: "Toggle floating" }
            ]}]
        },
        {
            name: "Focus",
            children: [{ keybinds: [
                { mods: ["Super"], key: "\u2190/\u2192/\u2191/\u2193", comment: "Focus direction" },
                { mods: ["Super"], key: "H/J/K/L", comment: "Focus (vim)" }
            ]}]
        },
        {
            name: "Move Windows",
            children: [{ keybinds: [
                { mods: ["Super", "Shift"], key: "\u2190/\u2192/\u2191/\u2193", comment: "Move direction" },
                { mods: ["Super", "Shift"], key: "H/J/K/L", comment: "Move (vim)" }
            ]}]
        },
        {
            name: "Workspaces",
            children: [{ keybinds: [
                { mods: ["Super"], key: "1-9", comment: "Focus workspace" },
                { mods: ["Super", "Shift"], key: "1-5", comment: "Move to workspace" }
            ]}]
        },
        {
            name: "Screenshots",
            children: [{ keybinds: [
                { mods: [], key: "Print", comment: "Screenshot (select)" },
                { mods: ["Ctrl"], key: "Print", comment: "Screenshot screen" },
                { mods: ["Alt"], key: "Print", comment: "Screenshot window" }
            ]}]
        },
        {
            name: "Media",
            children: [{ keybinds: [
                { mods: [], key: "Vol+", comment: "Volume up" },
                { mods: [], key: "Vol-", comment: "Volume down" },
                { mods: [], key: "Mute", comment: "Mute audio" }
            ]}]
        }
    ]
}
