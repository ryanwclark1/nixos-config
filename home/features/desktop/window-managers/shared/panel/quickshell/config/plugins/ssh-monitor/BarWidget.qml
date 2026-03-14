import QtQuick
import "../../services"
import "../../widgets" as SharedWidgets

Item {
    id: root

    property var pluginApi: null
    property var pluginManifest: null
    property var pluginService: null

    implicitWidth: sshPill.width
    implicitHeight: sshPill.height

    SshPluginData {
        id: pluginData
        pluginApi: root.pluginApi
        pluginManifest: root.pluginManifest
        pluginService: root.pluginService
    }

    SharedWidgets.BarPill {
        id: sshPill
        tooltipText: pluginData.summaryTooltip()
        shimmerEnabled: true
        onClicked: pluginData.openLauncher()

        Row {
            spacing: 6

            Text {
                text: "󰣀"
                color: Colors.primary
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeMedium
            }

            Text {
                text: pluginData.summaryLabel()
                color: Colors.text
                font.pixelSize: Colors.fontSizeSmall
                font.weight: Font.Medium
            }
        }
    }

    Connections {
        target: root.pluginService ? root.pluginService : null
        function onPluginRuntimeUpdated() {
            pluginData.refresh();
        }
    }
}
