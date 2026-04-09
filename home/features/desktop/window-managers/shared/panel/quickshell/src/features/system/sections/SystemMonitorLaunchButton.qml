import QtQuick
import Quickshell
import "../../../services"
import "../../../services/ShellUtils.js" as SU
import "../../../widgets" as SharedWidgets

SharedWidgets.IconButton {
    id: root

    icon: "info.svg"
    size: Appearance.iconSizeSmall
    iconSize: Appearance.fontSizeSmall
    iconColor: Colors.primary
    tooltipText: "Open system monitor"

    onClicked: Quickshell.execDetached(SU.ipcCall("Shell", "openSurface", "systemMonitor"))
}
