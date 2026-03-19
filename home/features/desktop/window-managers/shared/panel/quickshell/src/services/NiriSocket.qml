import QtQuick
import Quickshell.Io

// Resilient Unix socket wrapper with exponential-backoff reconnection.
// Wraps Quickshell.Io.Socket and auto-reconnects on disconnect when
// `connected` is true.  Emits `connectionStateChanged()` on transitions.
Item {
    id: root
    property bool _destroyed: false

    property alias path: socket.path
    property alias parser: socket.parser
    property bool connected: false

    property int reconnectBaseMs: 400
    property int reconnectMaxMs: 15000

    property int _reconnectAttempt: 0

    readonly property bool socketConnected: socket.connected

    signal connectionStateChanged()

    onConnectedChanged: {
        socket.connected = connected
    }

    Socket {
        id: socket

        onConnectionStateChanged: {
            root.connectionStateChanged()
            if (connected) {
                root._reconnectAttempt = 0
                return
            }
            if (root.connected) {
                root._scheduleReconnect()
            }
        }
    }

    Component.onDestruction: _destroyed = true

    Timer {
        id: reconnectTimer
        interval: 0
        repeat: false
        onTriggered: {
            socket.connected = false
            Qt.callLater(() => { if (root._destroyed) return; socket.connected = true; })
        }
    }

    function send(data) {
        const json = typeof data === "string" ? data : JSON.stringify(data)
        const message = json.endsWith("\n") ? json : json + "\n"
        socket.write(message)
        socket.flush()
    }

    function _scheduleReconnect() {
        const pow = Math.min(_reconnectAttempt, 10)
        const base = Math.min(reconnectBaseMs * Math.pow(2, pow), reconnectMaxMs)
        const jitter = Math.floor(Math.random() * Math.floor(base / 4))
        reconnectTimer.interval = base + jitter
        reconnectTimer.restart()
        _reconnectAttempt++
    }
}
