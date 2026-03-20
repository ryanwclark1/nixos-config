import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets
import "../models/ModuleUtils.js" as MU
import "ProcessTableHelpers.js" as PTH

Rectangle {
    id: root

    required property var selectedProcess
    required property var detailData
    required property int selectedPid
    required property string pendingAction
    required property int clockTick

    Layout.fillWidth: true
    radius: Appearance.radiusSmall
    color: Colors.bgWidget
    border.color: Colors.border
    border.width: 1
    implicitHeight: detailColumn.implicitHeight + Appearance.spacingM * 2

    ColumnLayout {
        id: detailColumn
        anchors.fill: parent
        anchors.margins: Appearance.spacingM
        spacing: Appearance.spacingS

        RowLayout {
            Layout.fillWidth: true
            visible: !!root.selectedProcess

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingXXS

                Text {
                    text: root.selectedProcess ? String(root.selectedProcess.name || "process") : ""
                    color: Colors.text
                    font.pixelSize: Appearance.fontSizeSmall
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    text: root.selectedProcess
                        ? ("PID " + String(root.selectedProcess.pid || 0)
                           + "  •  "
                           + String(root.selectedProcess.user || "user")
                           + "  •  "
                           + String(root.selectedProcess.tty || "?"))
                        : ""
                    color: Colors.textDisabled
                    font.pixelSize: Appearance.fontSizeXS
                    font.family: Appearance.fontMono
                }
            }

            Text {
                text: root.pendingAction !== "" ? ("PENDING  " + root.pendingAction.toUpperCase()) : "READY"
                color: root.pendingAction !== "" ? Colors.warning : Colors.textDisabled
                font.pixelSize: Appearance.fontSizeXS
                font.weight: Font.Bold
            }
        }

        SharedWidgets.EmptyState {
            Layout.fillWidth: true
            visible: !root.selectedProcess
            icon: "search-visual.svg"
            message: "Select a process to inspect live detail."
        }

        // ── Quick stat chips ────────────────────────────────────────────────
        Flow {
            Layout.fillWidth: true
            visible: !!root.selectedProcess
            width: parent.width
            spacing: Appearance.spacingS

            SharedWidgets.Chip {
                icon: ""
                iconColor: Colors.primary
                text: "CPU " + Number(root.selectedProcess ? root.selectedProcess.cpu : 0).toFixed(1) + "%"
                textColor: Colors.primary
            }

            SharedWidgets.Chip {
                icon: "board.svg"
                iconColor: Colors.accent
                text: "RAM " + Number(root.selectedProcess ? root.selectedProcess.mem : 0).toFixed(1) + "%"
                textColor: Colors.accent
            }

            SharedWidgets.Chip {
                icon: "board.svg"
                iconColor: Colors.accent
                text: root.selectedProcess ? ("RSS " + PTH.formatKiB(root.selectedProcess.rssKb || 0)) : "RSS 0 KiB"
                textColor: Colors.accent
            }

            SharedWidgets.Chip {
                icon: "clock.svg"
                iconColor: Colors.secondary
                text: root.selectedProcess ? String(root.selectedProcess.elapsed || "--:--") : ""
                textColor: Colors.secondary
            }

            SharedWidgets.Chip {
                icon: "link.svg"
                iconColor: Colors.textSecondary
                text: "PPID " + String(root.selectedProcess ? root.selectedProcess.parentPid || 0 : 0)
                textColor: Colors.textSecondary
            }

            SharedWidgets.Chip {
                icon: "more-horizontal.svg"
                iconColor: Colors.secondary
                text: "THR " + String(root.selectedProcess ? root.selectedProcess.threadCount || 0 : 0)
                textColor: Colors.secondary
            }

            SharedWidgets.Chip {
                icon: Number(root.selectedProcess ? root.selectedProcess.nice : 0) < 0 ? "chevron-up.svg" : "chevron-down.svg"
                iconColor: Number(root.selectedProcess ? root.selectedProcess.nice : 0) < 0 ? Colors.primary : Colors.textSecondary
                text: "NICE " + String(root.selectedProcess ? root.selectedProcess.nice || 0 : 0)
                textColor: Number(root.selectedProcess ? root.selectedProcess.nice : 0) < 0 ? Colors.primary : Colors.textSecondary
            }

            SharedWidgets.Chip {
                icon: "document.svg"
                iconColor: Colors.textSecondary
                text: root.selectedProcess ? ("TTY " + String(root.selectedProcess.tty || "?")) : "TTY ?"
                textColor: Colors.textSecondary
            }

            SharedWidgets.Chip {
                icon: "desktop.svg"
                iconColor: root.selectedProcess && String(root.selectedProcess.state || "").indexOf("T") !== -1 ? Colors.warning : Colors.textSecondary
                text: root.selectedProcess ? ("STATE " + String(root.selectedProcess.state || "?")) : ""
                textColor: root.selectedProcess && String(root.selectedProcess.state || "").indexOf("T") !== -1 ? Colors.warning : Colors.textSecondary
            }
        }

        // ── Action chips ────────────────────────────────────────────────────
        Flow {
            Layout.fillWidth: true
            visible: !!root.selectedProcess
            width: parent.width
            spacing: Appearance.spacingS

            SharedWidgets.FilterChip {
                label: "TERM"
                icon: "dismiss.svg"
                enabled: !ProcessService.isPidPending(root.selectedPid)
                selected: false
                onClicked: ProcessService.terminateProcess(root.selectedPid)
            }

            SharedWidgets.FilterChip {
                label: "KILL"
                icon: "dismiss.svg"
                enabled: !ProcessService.isPidPending(root.selectedPid)
                selected: false
                onClicked: ProcessService.killProcess(root.selectedPid)
            }

            SharedWidgets.FilterChip {
                label: root.selectedProcess && String(root.selectedProcess.state || "").indexOf("T") !== -1 ? "Resume" : "Suspend"
                icon: root.selectedProcess && String(root.selectedProcess.state || "").indexOf("T") !== -1 ? "play.svg" : "pause.svg"
                enabled: !ProcessService.isPidPending(root.selectedPid)
                selected: false
                onClicked: ProcessService.togglePause(root.selectedPid)
            }

            SharedWidgets.FilterChip {
                label: "Inspect"
                icon: "terminal.svg"
                enabled: !ProcessService.isPidPending(root.selectedPid)
                selected: false
                onClicked: ProcessService.openProcessInTerminal(root.selectedPid)
            }

            SharedWidgets.FilterChip {
                label: "Details"
                icon: "info.svg"
                enabled: !ProcessService.isPidPending(root.selectedPid)
                selected: false
                onClicked: ProcessService.openProcessDetailsInTerminal(root.selectedPid)
            }

            SharedWidgets.FilterChip {
                label: "Nice -1"
                icon: "chevron-up.svg"
                enabled: !ProcessService.isPidPending(root.selectedPid)
                selected: false
                onClicked: ProcessService.reniceProcess(root.selectedPid, Number(root.selectedProcess ? root.selectedProcess.nice : 0) - 1)
            }

            SharedWidgets.FilterChip {
                label: "Nice +1"
                icon: "chevron-down.svg"
                enabled: !ProcessService.isPidPending(root.selectedPid)
                selected: false
                onClicked: ProcessService.reniceProcess(root.selectedPid, Number(root.selectedProcess ? root.selectedProcess.nice : 0) + 1)
            }

            SharedWidgets.FilterChip {
                label: "Copy PID"
                icon: "copy.svg"
                enabled: !ProcessService.isPidPending(root.selectedPid)
                selected: false
                onClicked: ProcessService.copyPid(root.selectedPid)
            }

            SharedWidgets.FilterChip {
                label: "Copy Cmd"
                icon: "copy.svg"
                enabled: !ProcessService.isPidPending(root.selectedPid)
                selected: false
                onClicked: ProcessService.copyCommand(root.selectedPid)
            }

            SharedWidgets.FilterChip {
                label: "Copy CWD"
                icon: "folder.svg"
                enabled: !ProcessService.isPidPending(root.selectedPid) && root.detailData.cwd !== undefined
                selected: false
                onClicked: ProcessService.copyCwd(root.selectedPid)
            }

            SharedWidgets.FilterChip {
                label: "Copy EXE"
                icon: "terminal.svg"
                enabled: !ProcessService.isPidPending(root.selectedPid) && root.detailData.exe !== undefined
                selected: false
                onClicked: ProcessService.copyExe(root.selectedPid)
            }
        }

        // ── Live detail card ────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            visible: !!root.selectedProcess
            radius: Appearance.radiusSmall
            color: Colors.cardSurface
            border.color: Colors.withAlpha(PTH.detailStatusColor(ProcessService.detailStatus, Colors), 0.4)
            border.width: 1
            implicitHeight: liveDetailColumn.implicitHeight + Appearance.spacingM * 2

            ColumnLayout {
                id: liveDetailColumn
                anchors.fill: parent
                anchors.margins: Appearance.spacingM
                spacing: Appearance.spacingS

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "LIVE DETAIL"
                        color: Colors.textDisabled
                        font.pixelSize: Appearance.fontSizeXS
                        font.weight: Font.Bold
                        font.letterSpacing: Appearance.letterSpacingWide
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    SharedWidgets.Chip {
                        icon: ProcessService.detailBusy ? "󰑐" : "󰄬"
                        iconColor: PTH.detailStatusColor(ProcessService.detailStatus, Colors)
                        text: ProcessService.detailStatus.toUpperCase()
                        textColor: PTH.detailStatusColor(ProcessService.detailStatus, Colors)
                    }

                    SharedWidgets.Chip {
                        icon: ProcessService.detailDegraded ? "󰀦" : "󰥔"
                        iconColor: ProcessService.detailDegraded ? Colors.warning : Colors.textSecondary
                        text: "Updated " + MU.formatAge(ProcessService.detailLastUpdatedMs, root.clockTick)
                        textColor: ProcessService.detailDegraded ? Colors.warning : Colors.textSecondary
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: ProcessService.detailMessage !== ""
                    text: ProcessService.detailMessage
                    color: Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeXS
                    wrapMode: Text.WordWrap
                }

                Text {
                    Layout.fillWidth: true
                    visible: ProcessService.lastActionPid === root.selectedPid && ProcessService.lastActionMessage !== ""
                    text: ProcessService.lastActionMessage + "  •  " + MU.formatAge(ProcessService.lastActionAt, root.clockTick)
                    color: PTH.actionStatusColor(ProcessService.lastActionState, Colors)
                    font.pixelSize: Appearance.fontSizeXS
                    wrapMode: Text.WordWrap
                }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Appearance.spacingS

                    SharedWidgets.Chip {
                        icon: "󰞷"
                        iconColor: Colors.secondary
                        text: "FD " + (root.detailData.fdCount === undefined || root.detailData.fdCount === null ? "Unavailable" : String(root.detailData.fdCount))
                        textColor: Colors.secondary
                    }

                    SharedWidgets.Chip {
                        icon: "download.svg"
                        iconColor: Colors.primary
                        text: "READ " + MU.formatBytes(root.detailData.readBytes)
                        textColor: Colors.primary
                    }

                    SharedWidgets.Chip {
                        icon: "upload.svg"
                        iconColor: Colors.accent
                        text: "WRITE " + MU.formatBytes(root.detailData.writeBytes)
                        textColor: Colors.accent
                    }

                    SharedWidgets.Chip {
                        icon: "󰛐"
                        iconColor: Colors.warning
                        text: "CANCEL " + MU.formatBytes(root.detailData.cancelledWriteBytes)
                        textColor: Colors.warning
                    }

                    SharedWidgets.Chip {
                        icon: ProcessService.detailPermissionLimited ? "󰌾" : "󰄬"
                        iconColor: ProcessService.detailPermissionLimited ? Colors.warning : Colors.success
                        text: ProcessService.detailPermissionLimited ? "Permission limited" : "Live detail healthy"
                        textColor: ProcessService.detailPermissionLimited ? Colors.warning : Colors.success
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: Appearance.spacingS

                    SharedWidgets.Chip {
                        icon: "󰓅"
                        iconColor: Colors.secondary
                        text: "THR " + (root.detailData.statusFields && root.detailData.statusFields.threads !== null && root.detailData.statusFields.threads !== undefined ? String(root.detailData.statusFields.threads) : "Unavailable")
                        textColor: Colors.secondary
                    }

                    SharedWidgets.Chip {
                        icon: "󰾆"
                        iconColor: Colors.accent
                        text: "VMRSS " + (root.detailData.statusFields && root.detailData.statusFields.vmRssKb !== null && root.detailData.statusFields.vmRssKb !== undefined ? PTH.formatKiB(root.detailData.statusFields.vmRssKb) : "Unavailable")
                        textColor: Colors.accent
                    }

                    SharedWidgets.Chip {
                        icon: "󰚰"
                        iconColor: Colors.primary
                        text: "VCTX " + (root.detailData.statusFields && root.detailData.statusFields.voluntaryCtxtSwitches !== null && root.detailData.statusFields.voluntaryCtxtSwitches !== undefined ? String(root.detailData.statusFields.voluntaryCtxtSwitches) : "Unavailable")
                        textColor: Colors.primary
                    }

                    SharedWidgets.Chip {
                        icon: "󰚌"
                        iconColor: Colors.warning
                        text: "NVCTX " + (root.detailData.statusFields && root.detailData.statusFields.nonvoluntaryCtxtSwitches !== null && root.detailData.statusFields.nonvoluntaryCtxtSwitches !== undefined ? String(root.detailData.statusFields.nonvoluntaryCtxtSwitches) : "Unavailable")
                        textColor: Colors.warning
                    }
                }

                // ── Info blocks ─────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    color: Colors.cardSurface
                    radius: Appearance.radiusSmall
                    border.color: Colors.borderFocus
                    border.width: 1
                    implicitHeight: cwdBlock.implicitHeight + Appearance.spacingS * 2

                    ColumnLayout {
                        id: cwdBlock
                        anchors.fill: parent
                        anchors.margins: Appearance.spacingS
                        spacing: Appearance.spacingXXS

                        Text {
                            text: "CWD"
                            color: Colors.textDisabled
                            font.pixelSize: Appearance.fontSizeXS
                            font.weight: Font.Bold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: PTH.fallbackText(root.detailData.cwd)
                            color: Colors.textSecondary
                            font.pixelSize: Appearance.fontSizeXS
                            font.family: Appearance.fontMono
                            wrapMode: Text.WrapAnywhere
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    color: Colors.cardSurface
                    radius: Appearance.radiusSmall
                    border.color: Colors.borderFocus
                    border.width: 1
                    implicitHeight: exeBlock.implicitHeight + Appearance.spacingS * 2

                    ColumnLayout {
                        id: exeBlock
                        anchors.fill: parent
                        anchors.margins: Appearance.spacingS
                        spacing: Appearance.spacingXXS

                        Text {
                            text: "EXECUTABLE"
                            color: Colors.textDisabled
                            font.pixelSize: Appearance.fontSizeXS
                            font.weight: Font.Bold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: PTH.fallbackText(root.detailData.exe)
                            color: Colors.textSecondary
                            font.pixelSize: Appearance.fontSizeXS
                            font.family: Appearance.fontMono
                            wrapMode: Text.WrapAnywhere
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    visible: !!root.detailData.openFilePreview && root.detailData.openFilePreview.length > 0
                    color: Colors.cardSurface
                    radius: Appearance.radiusSmall
                    border.color: Colors.borderFocus
                    border.width: 1
                    implicitHeight: openFilesBlock.implicitHeight + Appearance.spacingS * 2

                    ColumnLayout {
                        id: openFilesBlock
                        anchors.fill: parent
                        anchors.margins: Appearance.spacingS
                        spacing: Appearance.spacingXXS

                        Text {
                            text: "OPEN FILES"
                            color: Colors.textDisabled
                            font.pixelSize: Appearance.fontSizeXS
                            font.weight: Font.Bold
                        }

                        Repeater {
                            model: root.detailData.openFilePreview || []

                            delegate: Text {
                                required property var modelData
                                Layout.fillWidth: true
                                text: String(modelData.fd || 0) + "  " + PTH.fallbackText(modelData.target)
                                color: Colors.textSecondary
                                font.pixelSize: Appearance.fontSizeXS
                                font.family: Appearance.fontMono
                                wrapMode: Text.WrapAnywhere
                            }
                        }
                    }
                }
            }
        }

        // ── Command display ─────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            visible: !!root.selectedProcess
            color: Colors.cardSurface
            radius: Appearance.radiusSmall
            border.color: Colors.withAlpha(Colors.border, 0.65)
            border.width: 1
            implicitHeight: commandText.implicitHeight + Appearance.spacingS * 2

            Text {
                id: commandText
                anchors.fill: parent
                anchors.margins: Appearance.spacingS
                text: root.selectedProcess ? String(root.detailData.command || root.selectedProcess.command || root.selectedProcess.name || "") : ""
                color: Colors.textSecondary
                font.pixelSize: Appearance.fontSizeXS
                font.family: Appearance.fontMono
                wrapMode: Text.WrapAnywhere
            }
        }
    }
}
