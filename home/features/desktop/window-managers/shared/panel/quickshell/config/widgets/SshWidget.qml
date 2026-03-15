import QtQuick
import "../services"

Item {
    id: root

    property var widgetInstance: null
    property var anchorWindow: null
    signal contextMenuRequested(var actions, var triggerRect)

    implicitWidth: sshPill.width
    implicitHeight: sshPill.height

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

    BarPill {
        id: sshPill
        anchorWindow: root.anchorWindow
        enabled: sshData.mergedHosts.length > 0 || sshData.importBusy || sshData.importErrors.length > 0 || sshData.enableSshConfigImport
        tooltipText: sshData.summaryTooltip()
        shimmerEnabled: true
        contextActions: sshData.contextActions(6)
        onContextMenuRequested: (actions, rect) => root.contextMenuRequested(actions, rect)
        onClicked: {
            if (sshData.mergedHosts.length === 1) {
                sshData.executeDefault(sshData.mergedHosts[0]);
                return;
            }
            root.openActionsMenu();
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
