import QtQuick
import "../services"

Item {
    id: root

    property var widgetInstance: null
    property var anchorWindow: null
    property bool isActive: false
    property var currentContextActions: []
    signal contextMenuRequested(var actions, var triggerRect)
    signal surfaceRequested(var triggerItem, var surfaceContext)
    readonly property bool hasVisibleState: sshData.mergedHosts.length > 0 || sshData.importBusy || sshData.importErrors.length > 0 || sshData.showWhenEmpty

    visible: hasVisibleState
    implicitWidth: visible ? sshPill.width : 0
    implicitHeight: visible ? sshPill.height : 0

    function refreshContextActions() {
        currentContextActions = sshData.contextActions(6);
    }

    function openActionsMenu() {
        var globalPos = sshPill.mapToItem(null, 0, 0);
        sshPill.contextMenuRequested(sshPill.contextActions, {
            x: globalPos.x,
            y: globalPos.y,
            width: sshPill.width,
            height: sshPill.height
        });
    }

    SshWidgetData {
        id: sshData
        widgetInstance: root.widgetInstance
    }

    Connections {
        target: sshData
        function onMergedHostsChanged() { root.refreshContextActions(); }
        function onImportBusyChanged() { root.refreshContextActions(); }
        function onEnableSshConfigImportChanged() { root.refreshContextActions(); }
    }

    Component.onCompleted: refreshContextActions()

    BarPill {
        id: sshPill
        anchorWindow: root.anchorWindow
        isActive: root.isActive
        enabled: root.hasVisibleState
        tooltipText: sshData.summaryTooltip()
        shimmerEnabled: true
        contextActions: root.currentContextActions
        onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)
        onClicked: {
            if (sshData.mergedHosts.length === 1) {
                sshData.executeDefault(sshData.mergedHosts[0]);
                return;
            }
            if (sshData.mergedHosts.length === 0 && sshData.showWhenEmpty) {
                if (sshData.handleEmptyClick() === "refresh")
                    return;
            }
            root.surfaceRequested(sshPill, {
                widgetInstance: root.widgetInstance ? JSON.parse(JSON.stringify(root.widgetInstance)) : null
            });
        }

        Row {
            spacing: Colors.spacingSM

            Text {
                text: "󰣀"
                color: sshData.importErrors.length > 0 ? Colors.warning : Colors.primary
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeMedium
            }

            Text {
                text: sshData.importBusy ? "Refreshing..." : sshData.summaryLabel()
                color: Colors.text
                font.pixelSize: Colors.fontSizeSmall
                font.weight: Font.Medium
            }
        }
    }
}
