import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../sections"
import "../../../services"
import "../../../services/IconHelpers.js" as IconHelpers
import "../../../shared"
import "../../../widgets" as SharedWidgets

PanelWindow {
    id: root
    property bool _destroyed: false

    readonly property var edgeMargins: Config.reservedEdgesForScreen(screen, "")

    anchors {
        top: true
        right: true
        bottom: true
    }
    margins.top: edgeMargins.top
    margins.right: Math.max(edgeMargins.right, Appearance.spacingS)
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
    readonly property int telemetryColumnMinWidth: 360
    readonly property int detailColumnMinWidth: 760
    property int panelWidth: _persist.panelWidth
    readonly property int panelMinWidth: telemetryColumnMinWidth + detailColumnMinWidth + Appearance.spacingM + (Appearance.paddingLarge * 2)
    readonly property int panelMaxWidth: 1760

    PersistentProperties {
        id: _persist
        reloadableId: "systemMonitorPanelState"
        property int panelWidth: 1360
    }
    property real _dragStartX: 0
    property real _dragStartWidth: 0
    property int keyboardSectionIndex: 0

    signal closeRequested()

    visible: showContent || slidePanel.x < panelWidth

    Component.onDestruction: _destroyed = true

    onShowContentChanged: {
        if (showContent) {
            slidePanel.forceActiveFocus();
            Qt.callLater(function() {
                if (_destroyed) return;
                root.focusKeyboardSection(0);
            });
        } else {
            if (processTable && processTable.clearTableFocus)
                processTable.clearTableFocus();
            if (serviceTable && serviceTable.clearTableFocus)
                serviceTable.clearTableFocus();
            if (slidePanel.activeFocus)
                slidePanel.focus = false;
        }
    }

    function refreshAll() {
        SystemStatus.refreshStats();
        ProcessService.refresh();
        ServiceUnitService.refresh();
        NetworkService.refreshData();
        SystemIoTelemetryService.refreshMetadata();
    }

    function focusKeyboardSection(index) {
        keyboardSectionIndex = index;
        if (keyboardSectionIndex === 0) {
            if (processTable && processTable.focusTable)
                processTable.focusTable();
            scrollDetailSectionIntoView(processTable);
            return;
        }
        if (serviceTable && serviceTable.focusTable) {
            serviceTable.focusTable();
            scrollDetailSectionIntoView(serviceTable);
        }
    }

    function jumpToSection(index) {
        focusKeyboardSection(index);
        if (index === 0) {
            if (processTable && processTable.pulseJumpHighlight)
                processTable.pulseJumpHighlight();
            return;
        }
        if (serviceTable && serviceTable.pulseJumpHighlight)
            serviceTable.pulseJumpHighlight();
    }

    function cycleKeyboardSection(delta) {
        var nextIndex = keyboardSectionIndex + delta;
        if (nextIndex < 0)
            nextIndex = 1;
        if (nextIndex > 1)
            nextIndex = 0;
        focusKeyboardSection(nextIndex);
    }

    function scrollDetailSectionIntoView(item) {
        if (!item || !detailFlick)
            return;
        var top = item.y;
        var bottom = item.y + item.height;
        var viewportTop = detailFlick.contentY;
        var viewportBottom = viewportTop + detailFlick.height;
        var nextContentY = viewportTop;

        if (top < viewportTop)
            nextContentY = top;
        else if (bottom > viewportBottom)
            nextContentY = bottom - detailFlick.height;

        var maxContentY = Math.max(0, detailFlick.contentHeight - detailFlick.height);
        detailFlick.contentY = Math.max(0, Math.min(maxContentY, nextContentY));
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
        color: Colors.popupSurface
        border.color: Colors.border
        border.width: 1
        radius: Appearance.radiusLarge
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
                duration: Appearance.durationPanelOpen
                easing.type: Easing.OutBack
                easing.overshoot: 0.6
            }
        }
        Behavior on opacity {
            NumberAnimation {
                id: fadeAnim
                duration: Appearance.durationPanelClose
            }
        }
        layer.enabled: slideAnim.running || fadeAnim.running

        Keys.onEscapePressed: root.closeRequested()
        Keys.onTabPressed: event => {
            root.cycleKeyboardSection(1);
            event.accepted = true;
        }
        Keys.onBacktabPressed: event => {
            root.cycleKeyboardSection(-1);
            event.accepted = true;
        }

        Rectangle {
            id: dragHandle
            width: 6
            height: parent.height * 0.18
            radius: Appearance.radiusXS
            color: dragArea.containsMouse ? Colors.primary : Colors.border
            anchors.left: parent.left
            anchors.leftMargin: -3
            anchors.verticalCenter: parent.verticalCenter
            opacity: dragArea.containsMouse || dragArea.pressed ? 1.0 : 0.4

            Behavior on opacity {
                NumberAnimation {
                    duration: Appearance.durationFast
                }
            }
            Behavior on color {
                enabled: !Colors.isTransitioning
                CAnim {}
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
                    _persist.panelWidth = Math.round(nextWidth);
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.paddingLarge
            spacing: Appearance.spacingM

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingM

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: "System Monitor"
                        color: Colors.text
                        font.pixelSize: Appearance.fontSizeHuge
                        font.weight: Font.DemiBold
                        font.letterSpacing: Appearance.letterSpacingTight
                    }

                    Text {
                        text: "Native telemetry, processes, and services in a standalone panel"
                        color: Colors.textSecondary
                        font.pixelSize: Appearance.fontSizeSmall
                    }
                }

                SharedWidgets.Chip {
                    icon: IconHelpers.healthStatusIcon(SystemStatus.isCritical)
                    iconColor: SystemStatus.isCritical ? Colors.error : Colors.success
                    text: SystemStatus.isCritical ? "Hot / busy" : "Stable"
                    textColor: SystemStatus.isCritical ? Colors.error : Colors.success
                }

                RowLayout {
                    spacing: Appearance.spacingS

                    Text {
                        text: "STATUS"
                        color: Colors.textDisabled
                        font.pixelSize: Appearance.fontSizeXS
                        font.weight: Font.Bold
                        font.letterSpacing: Appearance.letterSpacingWide
                    }

                    SharedWidgets.Chip {
                        icon: IconHelpers.degradedStatusIcon(ProcessService.detailDegraded, "window-multiple.svg")
                        iconColor: ProcessService.detailStatus === "error" || ProcessService.detailStatus === "terminated"
                            ? Colors.error
                            : (ProcessService.detailDegraded ? Colors.warning : Colors.textSecondary)
                        text: "PROC " + String(ProcessService.detailStatus || "idle").toUpperCase()
                        textColor: ProcessService.detailStatus === "error" || ProcessService.detailStatus === "terminated"
                            ? Colors.error
                            : (ProcessService.detailDegraded ? Colors.warning : Colors.textSecondary)
                    }

                    SharedWidgets.Chip {
                        icon: IconHelpers.degradedStatusIcon(ServiceUnitService.detailDegraded, "settings.svg")
                        iconColor: ServiceUnitService.detailStatus === "error" || ServiceUnitService.detailStatus === "missing"
                            ? Colors.error
                            : (ServiceUnitService.detailDegraded ? Colors.warning : Colors.textSecondary)
                        text: "UNIT " + String(ServiceUnitService.detailStatus || "idle").toUpperCase()
                        textColor: ServiceUnitService.detailStatus === "error" || ServiceUnitService.detailStatus === "missing"
                            ? Colors.error
                            : (ServiceUnitService.detailDegraded ? Colors.warning : Colors.textSecondary)
                    }

                    SharedWidgets.Chip {
                        icon: IconHelpers.degradedStatusIcon(SystemIoTelemetryService.telemetryStatus === "degraded", "hard-drive.svg")
                        iconColor: SystemIoTelemetryService.telemetryStatus === "degraded"
                            ? Colors.warning
                            : (SystemIoTelemetryService.telemetryStatus === "missing" ? Colors.error : Colors.textSecondary)
                        text: "I/O " + String(SystemIoTelemetryService.telemetryStatus || "loading").toUpperCase()
                        textColor: SystemIoTelemetryService.telemetryStatus === "degraded"
                            ? Colors.warning
                            : (SystemIoTelemetryService.telemetryStatus === "missing" ? Colors.error : Colors.textSecondary)
                    }
                }

                RowLayout {
                    spacing: Appearance.spacingS

                    Text {
                        text: "JUMP TO"
                        color: Colors.textDisabled
                        font.pixelSize: Appearance.fontSizeXS
                        font.weight: Font.Bold
                        font.letterSpacing: Appearance.letterSpacingWide
                    }

                    SharedWidgets.FilterChip {
                        label: "Processes"
                        icon: "terminal.svg"
                        selected: root.keyboardSectionIndex === 0
                        onClicked: root.jumpToSection(0)
                    }

                    SharedWidgets.FilterChip {
                        label: "Services"
                        icon: "settings.svg"
                        selected: root.keyboardSectionIndex === 1
                        onClicked: root.jumpToSection(1)
                    }
                }

                SharedWidgets.IconButton {
                    icon: "arrow-clockwise.svg"
                    size: 34
                    iconSize: Appearance.fontSizeLarge
                    tooltipText: "Refresh"
                    onClicked: root.refreshAll()
                }

                SharedWidgets.IconButton {
                    icon: "dismiss.svg"
                    size: 34
                    iconSize: Appearance.fontSizeLarge
                    tooltipText: "Close"
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
                spacing: Appearance.spacingM

                Item {
                    Layout.minimumWidth: root.telemetryColumnMinWidth
                    Layout.preferredWidth: Math.max(root.telemetryColumnMinWidth, Math.round(root.panelWidth * 0.32))
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
                            spacing: Appearance.spacingM

                            CpuWidget {}
                            SystemCpuCores {}
                            RamWidget {}
                            GPUWidget {}
                            DiskWidget {}
                            NetworkGraphs {}
                            SystemIoHistory {}
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
                    Layout.minimumWidth: root.detailColumnMinWidth
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
                            spacing: Appearance.spacingM

                            ProcessWidget {
                                id: processTable
                                maxRows: 26
                                viewportFlickable: detailFlick
                            }

                            SystemServiceTable {
                                id: serviceTable
                                maxRows: 18
                                viewportFlickable: detailFlick
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
                text: root.keyboardSectionIndex === 0
                    ? "Tab switches sections. Process keys: arrows/j/k move, selection persists across refresh, left/right or h/l collapse tree, r refresh, x term, Delete kill, Space suspend, +/- renice, d details, c/y copy, Enter inspect. Status chips show degraded or stale detail."
                    : "Tab switches sections. Service keys: arrows/j/k move, selection persists across refresh, r restart, s start/stop, Enter or l opens logs. Status chips show degraded or stale unit detail."
                color: Colors.textDisabled
                font.pixelSize: Appearance.fontSizeXS
                wrapMode: Text.WordWrap
            }
        }
    }
}
