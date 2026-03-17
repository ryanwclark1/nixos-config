import QtQuick
import Quickshell
import "../../services"
import "../../widgets" as SharedWidgets

Item {
    id: root
    property var widgetInstance: null
    required property var anchorWindow
    property bool inhibitorActive: false
    signal contextMenuRequested(var actions, rect triggerRect)

    implicitWidth: inhibitorPill.width
    implicitHeight: inhibitorPill.height

    CommandPoll {
        id: inhibitorPoll
        interval: 5000
        running: root.visible
        command: ["sh", "-c", "[ -f /tmp/wayland_idle_inhibitor.pid ] && echo true || echo false"]
        parse: function (out) {
            return String(out || "").trim() === "true";
        }
        onUpdated: root.inhibitorActive = inhibitorPoll.value
    }

    SharedWidgets.BarPill {
        id: inhibitorPill
        anchors.centerIn: parent
        anchorWindow: root.anchorWindow
        normalColor: root.inhibitorActive ? Colors.withAlpha(Colors.primary, 0.2) : Colors.bgWidget
        hoverColor: root.inhibitorActive ? Colors.withAlpha(Colors.primary, 0.35) : Colors.highlightLight
        tooltipText: root.inhibitorActive ? "Idle inhibitor enabled" : "Idle inhibitor"
        contextActions: [
            {
                label: root.inhibitorActive ? "Disable Inhibitor" : "Enable Inhibitor",
                icon: "󰒲",
                action: () => {
                    Quickshell.execDetached(["qs-inhibitor"]);
                    inhibitorCheckTimer.restart();
                }
            }
        ]
        onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)
        onClicked: {
            Quickshell.execDetached(["qs-inhibitor"]);
            inhibitorCheckTimer.restart();
        }

        Text {
            text: "󰒲"
            color: root.inhibitorActive ? Colors.primary : Colors.text
            font.pixelSize: Colors.fontSizeXL
            font.family: Colors.fontMono
        }

        Timer {
            id: inhibitorCheckTimer
            interval: 500
            running: false
            repeat: false
            onTriggered: inhibitorPoll.triggerPoll()
        }
    }
}
