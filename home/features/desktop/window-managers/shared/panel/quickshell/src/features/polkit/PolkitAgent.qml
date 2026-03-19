import QtQuick
import Quickshell
import Quickshell.Io
import "../../services"

Scope {
    id: root

    property bool _authActive: false
    property string _cookie: ""
    property string _actionId: ""
    property string _authMessage: ""
    property string _iconName: ""
    property var _identities: []
    property var _details: ({})
    property bool _daemonReady: false

    // Long-running Python polkit agent daemon
    Process {
        id: agentProc
        command: ["qs-polkit-agent"]
        running: true
        stdinEnabled: true

        stdout: SplitParser {
            onRead: line => {
                var msg;
                try {
                    msg = JSON.parse(line);
                } catch (e) {
                    return;
                }

                if (msg.type === "ready") {
                    root._daemonReady = true;
                } else if (msg.type === "begin") {
                    root._cookie = msg.cookie || "";
                    root._actionId = msg.action_id || "";
                    root._authMessage = msg.message || "";
                    root._iconName = msg.icon_name || "";
                    root._identities = msg.identities || [];
                    root._details = msg.details || {};
                    root._authActive = true;
                } else if (msg.type === "cancel") {
                    if (msg.cookie === root._cookie) {
                        root._authActive = false;
                    }
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            root._daemonReady = false;
            root._authActive = false;
            restartTimer.start();
        }
    }

    // Auto-restart daemon on crash
    Timer {
        id: restartTimer
        interval: 2000
        onTriggered: {
            if (!agentProc.running)
                agentProc.running = true;
        }
    }

    function _sendResponse(cookie, authenticated) {
        if (!agentProc.running) return;
        var msg = JSON.stringify({
            type: "response",
            cookie: cookie,
            authenticated: authenticated
        });
        agentProc.write(msg + "\n");
    }

    // Dialog displayed on cursor screen when auth is active
    Variants {
        model: root._authActive ? [Quickshell.cursorScreen || Config.primaryScreen()] : []

        PolkitAuthDialog {
            screen: modelData
            cookie: root._cookie
            actionId: root._actionId
            authMessage: root._authMessage
            iconName: root._iconName
            identities: root._identities
            details: root._details
            isVisible: root._authActive

            onAuthResult: (cookie, authenticated) => {
                root._sendResponse(cookie, authenticated);
                root._authActive = false;

                if (authenticated) {
                    ToastService.showSuccess("Authenticated", root._authMessage || root._actionId);
                } else {
                    ToastService.showError("Authentication cancelled", root._actionId);
                }
            }
        }
    }

    IpcHandler {
        target: "PolkitAgent"

        function status(): string {
            return JSON.stringify({
                daemonRunning: agentProc.running,
                daemonReady: root._daemonReady,
                authActive: root._authActive,
                cookie: root._cookie,
                actionId: root._actionId
            });
        }
    }
}
