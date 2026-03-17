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

    readonly property int _inhibitorPollMs: 5000
    readonly property int _inhibitorRecheckMs: 500

    CommandPoll {
        id: inhibitorPoll
        interval: root._inhibitorPollMs
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
        normalColor: root.inhibitorActive ? Colors.primaryTint : Colors.bgWidget
        hoverColor: root.inhibitorActive ? Colors.withAlpha(Colors.primary, 0.35) : Colors.highlightLight
        tooltipText: root.inhibitorActive ? "Idle inhibitor enabled" : "Idle inhibitor"
        contextActions: [
            {
                label: root.inhibitorActive ? "Disable Inhibitor" : "Enable Inhibitor",
                icon: "󰒲",
                action: () => {
                    Quickshell.execDetached(DependencyService.resolveCommand("qs-inhibitor"));
                    inhibitorCheckTimer.restart();
                }
            }
        ]
        onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)
        onClicked: {
            Quickshell.execDetached(DependencyService.resolveCommand("qs-inhibitor"));
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
            interval: root._inhibitorRecheckMs
            running: false
            repeat: false
            onTriggered: inhibitorPoll.triggerPoll()
        }
    }
}
