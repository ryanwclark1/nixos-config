import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets
import "../models/ModuleUtils.js" as MU

Rectangle {
    id: root

    required property var selectedUnit
    required property var detailData
    required property int clockTick

    // Color resolver functions passed from parent
    required property var detailStatusColorFn
    required property var actionStatusColorFn
    required property var fallbackTextFn

    Layout.fillWidth: true
    radius: Colors.radiusSmall
    color: Colors.cardSurface
    border.color: Colors.withAlpha(root.detailStatusColorFn(ServiceUnitService.detailStatus), 0.4)
    border.width: 1
    implicitHeight: liveDetailColumn.implicitHeight + Colors.spacingM * 2

    ColumnLayout {
        id: liveDetailColumn
        anchors.fill: parent
        anchors.margins: Colors.spacingM
        spacing: Colors.spacingS

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "LIVE UNIT DETAIL"
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.Bold
                font.letterSpacing: Colors.letterSpacingWide
            }

            Item {
                Layout.fillWidth: true
            }

            SharedWidgets.Chip {
                icon: ServiceUnitService.detailBusy ? "󰑐" : "󰄬"
                iconColor: root.detailStatusColorFn(ServiceUnitService.detailStatus)
                text: ServiceUnitService.detailStatus.toUpperCase()
                textColor: root.detailStatusColorFn(ServiceUnitService.detailStatus)
            }

            SharedWidgets.Chip {
                icon: ServiceUnitService.detailDegraded ? "󰀦" : "󰥔"
                iconColor: ServiceUnitService.detailDegraded ? Colors.warning : Colors.textSecondary
                text: "Updated " + MU.formatAge(ServiceUnitService.detailLastUpdatedMs, root.clockTick)
                textColor: ServiceUnitService.detailDegraded ? Colors.warning : Colors.textSecondary
            }
        }

        Text {
            Layout.fillWidth: true
            visible: ServiceUnitService.detailMessage !== ""
            text: ServiceUnitService.detailMessage
            color: Colors.textSecondary
            font.pixelSize: Colors.fontSizeXS
            wrapMode: Text.WordWrap
        }

        Text {
            Layout.fillWidth: true
            visible: root.selectedUnit
                && ServiceUnitService.lastActionScope === root.selectedUnit.scope
                && ServiceUnitService.lastActionUnitName === root.selectedUnit.name
                && ServiceUnitService.lastActionMessage !== ""
            text: ServiceUnitService.lastActionMessage + "  •  " + MU.formatAge(ServiceUnitService.lastActionAt, root.clockTick)
            color: root.actionStatusColorFn(ServiceUnitService.lastActionState)
            font.pixelSize: Colors.fontSizeXS
            wrapMode: Text.WordWrap
        }

        Flow {
            Layout.fillWidth: true
            width: parent.width
            spacing: Colors.spacingS

            SharedWidgets.Chip {
                icon: "󰈐"
                iconColor: Colors.primary
                text: "PID " + (root.detailData.mainPid !== undefined && root.detailData.mainPid !== null ? String(root.detailData.mainPid) : "Unavailable")
                textColor: Colors.primary
            }

            SharedWidgets.Chip {
                icon: "󰜎"
                iconColor: Colors.secondary
                text: "EXIT " + (root.detailData.execMainStatus !== undefined && root.detailData.execMainStatus !== null ? String(root.detailData.execMainStatus) : "Unavailable")
                textColor: Colors.secondary
            }

            SharedWidgets.Chip {
                icon: "󰍛"
                iconColor: Colors.accent
                text: "MEM " + MU.formatBytes(root.detailData.memoryCurrent)
                textColor: Colors.accent
            }

            SharedWidgets.Chip {
                icon: "󰓅"
                iconColor: Colors.warning
                text: "TASKS " + (root.detailData.tasksCurrent !== undefined && root.detailData.tasksCurrent !== null ? String(root.detailData.tasksCurrent) : "Unavailable")
                textColor: Colors.warning
            }

            SharedWidgets.Chip {
                icon: ServiceUnitService.detailPermissionLimited ? "󰌾" : "󰄬"
                iconColor: ServiceUnitService.detailPermissionLimited ? Colors.warning : Colors.success
                text: ServiceUnitService.detailPermissionLimited ? "Permission limited" : "Live unit healthy"
                textColor: ServiceUnitService.detailPermissionLimited ? Colors.warning : Colors.success
            }
        }

        Rectangle {
            Layout.fillWidth: true
            color: Colors.cardSurface
            radius: Colors.radiusSmall
            border.color: Colors.borderFocus
            border.width: 1
            implicitHeight: fragmentBlock.implicitHeight + Colors.spacingS * 2

            ColumnLayout {
                id: fragmentBlock
                anchors.fill: parent
                anchors.margins: Colors.spacingS
                spacing: Colors.spacingXXS

                Text {
                    text: "FRAGMENT PATH"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXS
                    font.weight: Font.Bold
                }

                Text {
                    Layout.fillWidth: true
                    text: root.fallbackTextFn(root.detailData.fragmentPath)
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeXS
                    font.family: Colors.fontMono
                    wrapMode: Text.WrapAnywhere
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            color: Colors.cardSurface
            radius: Colors.radiusSmall
            border.color: Colors.borderFocus
            border.width: 1
            implicitHeight: logsBlock.implicitHeight + Colors.spacingS * 2

            ColumnLayout {
                id: logsBlock
                anchors.fill: parent
                anchors.margins: Colors.spacingS
                spacing: Colors.spacingXXS

                Text {
                    text: "RECENT LOGS"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXS
                    font.weight: Font.Bold
                }

                Text {
                    Layout.fillWidth: true
                    visible: !root.detailData.recentLogs || root.detailData.recentLogs.length === 0
                    text: "Unavailable"
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeXS
                    font.family: Colors.fontMono
                }

                Repeater {
                    model: root.detailData.recentLogs || []

                    delegate: Text {
                        required property var modelData
                        Layout.fillWidth: true
                        text: String(modelData || "")
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeXS
                        font.family: Colors.fontMono
                        wrapMode: Text.WrapAnywhere
                    }
                }
            }
        }
    }
}
