import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../modules"
import "../services"
import "../widgets" as SharedWidgets

PanelWindow {
    id: root

    readonly property var edgeMargins: Config.reservedEdgesForScreen(screen, "")

    anchors {
        top: true
        right: true
        bottom: true
    }
    margins.top: edgeMargins.top
    margins.right: edgeMargins.right
    margins.bottom: edgeMargins.bottom

    implicitWidth: panelWidth
    color: "transparent"
    mask: Region {
        item: slidePanel
    }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell"

    property bool showContent: false
    property int panelWidth: 980
    readonly property int panelMinWidth: 760
    readonly property int panelMaxWidth: 1320
    property real _dragStartX: 0
    property real _dragStartWidth: 0

    signal closeRequested()

    visible: showContent || slidePanel.x < panelWidth

    onShowContentChanged: {
        if (showContent) {
            slidePanel.forceActiveFocus();
            Qt.callLater(function() {
                if (processTable && processTable.focusTable)
                    processTable.focusTable();
            });
        }
        else if (slidePanel.activeFocus)
            slidePanel.focus = false;
    }

    function refreshAll() {
        if (!SystemStatus.statsProc.running)
            SystemStatus.statsProc.running = true;
        ProcessService.refresh();
        ServiceUnitService.refresh();
        NetworkService.refreshData();
    }

    Loader {
        active: root.showContent
        sourceComponent: SharedWidgets.Ref {
            service: SystemStatus
        }
    }
    Loader {
        active: root.showContent
        sourceComponent: SharedWidgets.Ref {
            service: ProcessService
        }
    }
    Loader {
        active: root.showContent
        sourceComponent: SharedWidgets.Ref {
            service: ServiceUnitService
        }
    }
    Loader {
        active: root.showContent
        sourceComponent: SharedWidgets.Ref {
            service: NetworkService
        }
    }

    Rectangle {
        id: slidePanel
        width: root.panelWidth
        height: parent.height
        color: Colors.withAlpha(Colors.surface, 0.96)
        border.color: Colors.border
        border.width: 1
        radius: Colors.radiusLarge
        focus: true

        gradient: SharedWidgets.SurfaceGradient {}

        SharedWidgets.InnerHighlight {
            highlightOpacity: 0.15
        }

        x: root.showContent ? 0 : root.panelWidth + 10
        opacity: root.showContent ? 1.0 : 0.0

        Behavior on x {
            NumberAnimation {
                id: slideAnim
                duration: 320
                easing.type: Easing.OutBack
                easing.overshoot: 0.6
            }
        }
        Behavior on opacity {
            NumberAnimation {
                id: fadeAnim
                duration: 260
            }
        }
        layer.enabled: slideAnim.running || fadeAnim.running

        Keys.onEscapePressed: root.closeRequested()

        Rectangle {
            id: dragHandle
            width: 6
            height: parent.height * 0.18
            radius: 3
            color: dragArea.containsMouse ? Colors.primary : Colors.border
            anchors.left: parent.left
            anchors.leftMargin: -3
            anchors.verticalCenter: parent.verticalCenter
            opacity: dragArea.containsMouse || dragArea.pressed ? 1.0 : 0.4

            Behavior on opacity {
                NumberAnimation {
                    duration: Colors.durationFast
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: Colors.durationFast
                }
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.SizeHorCursor
                onPressed: mouse => {
                    root._dragStartX = mapToGlobal(mouse.x, mouse.y).x;
                    root._dragStartWidth = root.panelWidth;
                }
                onPositionChanged: mouse => {
                    if (!pressed)
                        return;
                    var globalX = mapToGlobal(mouse.x, mouse.y).x;
                    var delta = root._dragStartX - globalX;
                    var nextWidth = Math.max(root.panelMinWidth, Math.min(root.panelMaxWidth, root._dragStartWidth + delta));
                    root.panelWidth = Math.round(nextWidth);
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Colors.paddingLarge
            spacing: Colors.spacingM

            RowLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingM

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: "System Monitor"
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeHuge
                        font.weight: Font.DemiBold
                        font.letterSpacing: Colors.letterSpacingTight
                    }

                    Text {
                        text: "Native telemetry, processes, and services in a standalone panel"
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeSmall
                    }
                }

                SharedWidgets.Chip {
                    icon: SystemStatus.isCritical ? "󰀦" : "󰄬"
                    iconColor: SystemStatus.isCritical ? Colors.error : Colors.success
                    text: SystemStatus.isCritical ? "Hot / busy" : "Stable"
                    textColor: SystemStatus.isCritical ? Colors.error : Colors.success
                }

                SharedWidgets.IconButton {
                    icon: "󰑐"
                    size: 34
                    iconSize: Colors.fontSizeLarge
                    onClicked: root.refreshAll()
                }

                SharedWidgets.IconButton {
                    icon: "󰅖"
                    size: 34
                    iconSize: Colors.fontSizeLarge
                    onClicked: root.closeRequested()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.border
                opacity: 0.6
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Colors.spacingM

                Item {
                    Layout.preferredWidth: Math.max(340, Math.round(root.panelWidth * 0.4))
                    Layout.fillHeight: true

                    Flickable {
                        id: telemetryFlick
                        anchors.fill: parent
                        contentHeight: telemetryColumn.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.DragOverBounds
                        flickableDirection: Flickable.VerticalFlick

                        ColumnLayout {
                            id: telemetryColumn
                            width: telemetryFlick.width
                            spacing: Colors.spacingM

                            SystemMonitorSummary {}
                            SystemCpuCores {}
                            SystemGraphs {}
                            GPUWidget {}
                            DiskWidget {}
                            NetworkGraphs {}
                        }
                    }

                    SharedWidgets.Scrollbar {
                        flickable: telemetryFlick
                    }

                    SharedWidgets.OverscrollGlow {
                        flickable: telemetryFlick
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Flickable {
                        id: detailFlick
                        anchors.fill: parent
                        contentHeight: detailColumn.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.DragOverBounds
                        flickableDirection: Flickable.VerticalFlick

                        ColumnLayout {
                            id: detailColumn
                            width: detailFlick.width
                            spacing: Colors.spacingM

                            SystemProcessTable {
                                id: processTable
                                maxRows: 26
                            }

                            SystemServiceTable {
                                maxRows: 18
                            }
                        }
                    }

                    SharedWidgets.Scrollbar {
                        flickable: detailFlick
                    }

                    SharedWidgets.OverscrollGlow {
                        flickable: detailFlick
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Esc closes the panel. Drag the left edge to resize."
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeXS
            }
        }
    }
}
