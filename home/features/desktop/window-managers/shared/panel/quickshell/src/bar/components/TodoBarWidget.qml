import QtQuick
import "../../services"
import "../../widgets" as SharedWidgets

SharedWidgets.BarPill {
    id: root
    property var widgetInstance: null
    property bool vertical: false

    visible: TodoService.totalCount > 0
    tooltipText: TodoService.pendingCount > 0
        ? TodoService.pendingCount + " pending task" + (TodoService.pendingCount === 1 ? "" : "s")
        : "All tasks done"

    contextActions: [
        {
            label: "Clear Done",
            icon: "archive.svg",
            action: () => TodoService.clearDone()
        }
    ]

    Row {
        spacing: Colors.spacingXS

        Text {
            color: TodoService.pendingCount > 0 ? Colors.primary : Colors.success
            font.pixelSize: Colors.fontSizeLarge
            font.family: Colors.fontMono
            text: TodoService.pendingCount > 0 ? "󰄱" : "󰄵"
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: TodoService.pendingCount > 0 && !root.vertical
            color: Colors.text
            font.pixelSize: Colors.fontSizeSmall
            font.weight: Font.DemiBold
            text: String(TodoService.pendingCount)
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
