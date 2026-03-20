import QtQuick
import Quickshell
import Quickshell.Io
import "../../services"
import "../../widgets" as SharedWidgets

Item {
    id: root
    property var widgetInstance: null
    required property var anchorWindow
    property bool inhibitorActive: _pidFile.text !== ""
    signal contextMenuRequested(var actions, rect triggerRect)

    implicitWidth: inhibitorPill.width
    implicitHeight: inhibitorPill.height

    FileView {
        id: _pidFile
        path: "/tmp/wayland_idle_inhibitor.pid"
        watchChanges: true
        printErrors: false
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
                }
            }
        ]
        onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)
        onClicked: {
            Quickshell.execDetached(DependencyService.resolveCommand("qs-inhibitor"));
        }

        Text {
            text: "󰒲"
            color: root.inhibitorActive ? Colors.primary : Colors.text
            font.pixelSize: Appearance.fontSizeXL
            font.family: Appearance.fontMono
        }

    }
}
