import QtQuick
import Quickshell
import Quickshell.Io
import "../../services"
import "../../widgets" as SharedWidgets

Item {
    id: root
    property var widgetInstance: null
    property var anchorWindow
    property bool inhibitorActive: _pidFile.text() !== ""
    property real iconScale: 1.0
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
        iconScale: root.iconScale
        contextActions: [
            {
                label: root.inhibitorActive ? "Disable Inhibitor" : "Enable Inhibitor",
                icon: "drink-coffee.svg",
                action: () => {
                    Quickshell.execDetached(DependencyService.resolveCommand("qs-inhibitor"));
                }
            }
        ]
        onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)
        onClicked: {
            Quickshell.execDetached(DependencyService.resolveCommand("qs-inhibitor"));
        }

        SharedWidgets.SvgIcon {
            source: "power-sleep.svg"
            color: root.inhibitorActive ? Colors.primary : Colors.text
            size: Appearance.fontSizeXL * root.iconScale
        }

    }
}
