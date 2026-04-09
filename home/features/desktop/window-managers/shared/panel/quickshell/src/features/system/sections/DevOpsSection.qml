import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../services"
import "../../../services/ShellUtils.js" as SU
import "../../ssh"
import "DevOpsSectionHelpers.js" as DevOpsHelpers
import "../../../widgets" as SharedWidgets

ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: Appearance.spacingM

    signal menuRequested(string surfaceId, var surfaceContext)

    property bool showContent: false
    property int baseIndex: 15
    property int staggerDelay: 35
    property string expandedSection: ""
    property bool autoExpanded: false

    readonly property var sshWidgetFallback: DevOpsHelpers.defaultSshWidgetInstance()
    readonly property var sshWidgetInstance: DevOpsHelpers.findFirstWidgetInstance(
        Config.barConfigs,
        function(barConfig, section) {
            return Config.barSectionWidgets(barConfig, section);
        },
        "ssh",
        sshWidgetFallback
    )
    readonly property var sshSessionSummary: DevOpsHelpers.summarizeSshSessions(ServiceUnitService.sshSessions)
    readonly property bool dockerExpanded: expandedSection === "docker"
    readonly property bool sshExpanded: expandedSection === "ssh"
    readonly property bool hasDockerContainers: ServiceUnitService.dockerContainers.length > 0
    readonly property bool hasSshHosts: sshData.mergedHosts.length > 0
    readonly property bool hasLiveSshSessions: sshSessionSummary.total > 0

    function toggleSection(sectionId) {
        expandedSection = DevOpsHelpers.toggleAccordionSection(expandedSection, sectionId);
        autoExpanded = true;
    }

    function openMenu(surfaceId, extraContext) {
        var context = extraContext || ({});
        menuRequested(surfaceId, context);
    }

    onHasDockerContainersChanged: {
        if (!autoExpanded && hasDockerContainers)
            expandedSection = "docker";
    }

    opacity: showContent ? 1.0 : 0.0
    scale: showContent ? 1.0 : 0.96
    transform: Translate {
        y: showContent ? 0 : 8
    }
    visible: opacity > 0

    Behavior on opacity {
        SequentialAnimation {
            id: devopsFadeAnim
            PauseAnimation {
                duration: showContent ? (root.baseIndex * root.staggerDelay) : 0
            }
            NumberAnimation {
                duration: Appearance.durationNormal + (root.baseIndex * 20)
                easing.type: Easing.OutCubic
            }
        }
    }
    Behavior on scale {
        SequentialAnimation {
            id: devopsScaleAnim
            PauseAnimation {
                duration: showContent ? (root.baseIndex * root.staggerDelay) : 0
            }
            NumberAnimation {
                duration: Appearance.durationNormal + (root.baseIndex * 20)
                easing.type: Easing.OutBack
            }
        }
    }
    Behavior on transform {
        SequentialAnimation {
            PauseAnimation {
                duration: showContent ? (root.baseIndex * root.staggerDelay) : 0
            }
            NumberAnimation {
                duration: Appearance.durationNormal + (root.baseIndex * 20)
                easing.type: Easing.OutCubic
            }
        }
    }
    layer.enabled: devopsFadeAnim.running || devopsScaleAnim.running

    SshWidgetData {
        id: sshData
        widgetInstance: root.sshWidgetInstance
    }

    Text {
        text: "DEVOPS & SERVICES"
        color: Colors.textDisabled
        font.pixelSize: Appearance.fontSizeXS
        font.weight: Font.Bold
        font.letterSpacing: Appearance.letterSpacingWide
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacingM

        Rectangle {
            id: dockerSummaryRect
            Layout.fillWidth: true
            implicitHeight: 62
            radius: Appearance.radiusMedium
            color: dockerSummaryHover.containsMouse || root.dockerExpanded ? Colors.primaryFaint : Colors.cardSurface
            border.color: root.dockerExpanded ? Colors.primary : (ServiceUnitService.dockerStatus === "ready" ? Colors.border : Colors.warning)
            border.width: 1

            MouseArea {
                id: dockerSummaryHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleSection("docker")
            }

            SharedWidgets.InnerHighlight { hoveredOpacity: 0.2; hovered: dockerSummaryHover.containsMouse || root.dockerExpanded }

            RowLayout {
                anchors.fill: parent
                anchors.margins: Appearance.paddingSmall
                spacing: Appearance.spacingS

                SharedWidgets.SvgIcon {
                    source: "server.svg"
                    color: ServiceUnitService.dockerContainers.length > 0 ? Colors.primary : Colors.textDisabled
                    size: Appearance.fontSizeXL
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: ServiceUnitService.dockerContainers.length + " Docker"
                        color: Colors.text
                        font.pixelSize: Appearance.fontSizeSmall
                        font.weight: Font.Bold
                    }

                    Text {
                        text: ServiceUnitService.dockerStatus === "ready"
                            ? DevOpsHelpers.formatDockerActivitySummary(ServiceUnitService.dockerContainers)
                            : (ServiceUnitService.dockerMessage || (ServiceUnitService.dockerStatus === "missing" ? "Missing" : "Error"))
                        color: ServiceUnitService.dockerStatus === "ready" ? Colors.textSecondary : Colors.warning
                        font.pixelSize: Appearance.fontSizeCaption
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                SharedWidgets.SvgIcon {
                    source: root.dockerExpanded ? "chevron-up.svg" : "chevron-down.svg"
                    color: Colors.textSecondary
                    size: Appearance.fontSizeLarge
                }

                SharedWidgets.IconButton {
                    icon: "open.svg"
                    size: 30
                    iconSize: 15
                    tooltipText: "Open Docker popup"
                    onClicked: root.openMenu("dockerMenu")
                }
            }
        }

        Rectangle {
            id: sshSummaryRect
            Layout.fillWidth: true
            implicitHeight: 62
            radius: Appearance.radiusMedium
            color: sshSummaryHover.containsMouse || root.sshExpanded ? Colors.primaryFaint : Colors.cardSurface
            border.color: root.sshExpanded ? Colors.primary : Colors.border
            border.width: 1

            MouseArea {
                id: sshSummaryHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleSection("ssh")
            }

            SharedWidgets.InnerHighlight { hoveredOpacity: 0.2; hovered: sshSummaryHover.containsMouse || root.sshExpanded }

            RowLayout {
                anchors.fill: parent
                anchors.margins: Appearance.paddingSmall
                spacing: Appearance.spacingS

                SharedWidgets.SvgIcon {
                    source: "terminal.svg"
                    color: root.hasSshHosts ? Colors.accent : Colors.textDisabled
                    size: Appearance.fontSizeXL
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: DevOpsHelpers.formatSshHostSummary(sshData.mergedHosts.length)
                        color: Colors.text
                        font.pixelSize: Appearance.fontSizeSmall
                        font.weight: Font.Bold
                    }

                    Text {
                        text: sshData.importBusy
                            ? "Refreshing aliases..."
                            : DevOpsHelpers.formatSshActivitySummary(ServiceUnitService.sshSessions)
                        color: Colors.textSecondary
                        font.pixelSize: Appearance.fontSizeCaption
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                SharedWidgets.SvgIcon {
                    source: root.sshExpanded ? "chevron-up.svg" : "chevron-down.svg"
                    color: Colors.textSecondary
                    size: Appearance.fontSizeLarge
                }

                SharedWidgets.IconButton {
                    icon: "open.svg"
                    size: 30
                    iconSize: 15
                    tooltipText: "Open SSH popup"
                    onClicked: root.openMenu("sshMenu", {
                        widgetInstance: JSON.parse(JSON.stringify(root.sshWidgetInstance || root.sshWidgetFallback))
                    })
                }
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacingXS
        visible: root.dockerExpanded

        Repeater {
            model: ServiceUnitService.dockerContainers.slice(0, 3)

            delegate: Rectangle {
                id: dockerRow
                required property var modelData

                Layout.fillWidth: true
                implicitHeight: 48
                radius: Appearance.radiusSmall
                color: dockerHover.containsMouse ? Colors.primaryFaint : Colors.cardSurface
                border.color: dockerHover.containsMouse ? Colors.primary : Colors.border
                border.width: 1

                MouseArea {
                    id: dockerHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        logOverlay.title = "Docker: " + modelData.name;
                        logOverlay.command = ServiceUnitService.getLogStreamCommand("docker", modelData.id);
                        logOverlay.visible = true;
                    }
                }

                SharedWidgets.InnerHighlight { hoveredOpacity: 0.2; hovered: dockerHover.containsMouse }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Appearance.spacingS

                    SharedWidgets.SvgIcon {
                        source: "server.svg"
                        color: Colors.primary
                        size: Appearance.fontSizeLarge
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: modelData.name
                            color: Colors.text
                            font.pixelSize: Appearance.fontSizeXS
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            visible: String(modelData.image || "") !== ""
                            text: String(modelData.image || "")
                            color: Colors.textSecondary
                            font.pixelSize: Appearance.fontSizeXXS
                            font.family: Appearance.fontMono
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }
                    }

                    Row {
                        spacing: Appearance.spacingXXS

                        SharedWidgets.IconButton {
                            icon: "terminal.svg"
                            size: 28
                            iconSize: 14
                            iconColor: dockerHover.containsMouse ? Colors.primary : Colors.textDisabled
                            tooltipText: "Open shell"
                            onClicked: {
                                var cmd = "runtime=$(command -v docker || command -v podman); if [ -n \"$runtime\" ]; then \"$runtime\" exec -it " + SU.shellQuote(modelData.id) + " /bin/sh; else exit 1; fi";
                                Quickshell.execDetached(SU.terminalCommand(cmd));
                            }
                        }

                        SharedWidgets.IconButton {
                            icon: "arrow-counterclockwise.svg"
                            size: 28
                            iconSize: 14
                            iconColor: dockerHover.containsMouse ? Colors.primary : Colors.textDisabled
                            tooltipText: "View logs"
                            onClicked: {
                                logOverlay.title = "Docker: " + modelData.name;
                                logOverlay.command = ServiceUnitService.getLogStreamCommand("docker", modelData.id);
                                logOverlay.visible = true;
                            }
                        }
                    }
                }
            }
        }

        Text {
            visible: !root.hasDockerContainers
            text: ServiceUnitService.dockerStatus === "ready"
                ? "No Docker containers found"
                : (ServiceUnitService.dockerMessage || "Docker runtime unavailable")
            color: ServiceUnitService.dockerStatus === "ready" ? Colors.textDisabled : Colors.warning
            font.pixelSize: Appearance.fontSizeXS
            Layout.alignment: Qt.AlignHCenter
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacingXS
        visible: root.sshExpanded

        Repeater {
            model: sshData.mergedHosts.slice(0, 4)

            delegate: Rectangle {
                id: hostRow
                required property var modelData

                Layout.fillWidth: true
                implicitHeight: 48
                radius: Appearance.radiusSmall
                color: sshHostHover.containsMouse ? Colors.primaryFaint : Colors.cardSurface
                border.color: sshHostHover.containsMouse ? Colors.primary : Colors.border
                border.width: 1

                readonly property string hostMetaText: {
                    var details = sshData.hostUserHostText(modelData);
                    if (details !== "")
                        return details;
                    return sshData.hostSourceLabel(modelData);
                }

                MouseArea {
                    id: sshHostHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton
                    onClicked: sshData.executeDefault(modelData)
                }

                SharedWidgets.InnerHighlight { hoveredOpacity: 0.2; hovered: sshHostHover.containsMouse }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Appearance.spacingS
                    spacing: Appearance.spacingS

                    SharedWidgets.SvgIcon {
                        source: modelData.source === "imported" ? "download.svg" : "server-2.svg"
                        color: modelData.source === "imported" ? Colors.accent : Colors.primary
                        size: Appearance.fontSizeLarge
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: String(modelData.label || modelData.alias || modelData.host || "SSH")
                            color: Colors.text
                            font.pixelSize: Appearance.fontSizeXS
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            visible: hostRow.hostMetaText !== ""
                            text: hostRow.hostMetaText
                            color: Colors.textSecondary
                            font.pixelSize: Appearance.fontSizeXXS
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Row {
                        spacing: Appearance.spacingXXS

                        SharedWidgets.IconButton {
                            icon: "terminal.svg"
                            size: 28
                            iconSize: 14
                            iconColor: sshHostHover.containsMouse ? Colors.primary : Colors.textDisabled
                            tooltipText: "Connect"
                            onClicked: sshData.connectHost(modelData)
                        }

                        SharedWidgets.IconButton {
                            icon: "copy.svg"
                            size: 28
                            iconSize: 14
                            iconColor: sshHostHover.containsMouse ? Colors.primary : Colors.textDisabled
                            tooltipText: "Copy command"
                            onClicked: sshData.copyHostCommand(modelData)
                        }
                    }
                }
            }
        }

        Text {
            visible: !root.hasSshHosts
            text: sshData.importBusy ? "Refreshing SSH hosts..." : "No SSH hosts configured"
            color: Colors.textDisabled
            font.pixelSize: Appearance.fontSizeXS
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            visible: root.hasLiveSshSessions
            text: "Active sessions"
            color: Colors.textDisabled
            font.pixelSize: Appearance.fontSizeXXS
            font.weight: Font.Bold
            font.letterSpacing: Appearance.letterSpacingWide
            Layout.topMargin: Appearance.spacingXS
        }

        Repeater {
            model: ServiceUnitService.sshSessions.slice(0, 4)

            delegate: Rectangle {
                id: sshRow
                required property var modelData

                Layout.fillWidth: true
                implicitHeight: 42
                radius: Appearance.radiusSmall
                color: sshHover.containsMouse ? Colors.primaryFaint : Colors.cardSurface
                border.color: sshHover.containsMouse ? Colors.primary : Colors.border
                border.width: 1

                readonly property string sessionType: modelData.type || "ssh"
                readonly property string sessionLabel: modelData.label || ""
                readonly property int sessionCount: modelData.count || 1
                readonly property string typeIcon: {
                    switch (sessionType) {
                    case "scp":   return "copy.svg";
                    case "sftp":  return "document.svg";
                    case "rsync": return "arrow-sync.svg";
                    case "sshfs": return "hard-drive.svg";
                    default:      return "terminal.svg";
                    }
                }

                MouseArea {
                    id: sshHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: sshRow.sessionType === "ssh" ? Qt.PointingHandCursor : Qt.ArrowCursor
                    acceptedButtons: Qt.LeftButton
                    onClicked: {
                        if (sshRow.sessionType === "ssh") {
                            var host = sshRow.sessionLabel.split("@")[1] || sshRow.sessionLabel;
                            Quickshell.execDetached(SU.terminalCommand("exec ssh \"$1\"", host));
                        }
                    }
                }

                SharedWidgets.InnerHighlight { hoveredOpacity: 0.2; hovered: sshHover.containsMouse }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Appearance.spacingS

                    SharedWidgets.SvgIcon {
                        source: sshRow.typeIcon
                        color: Colors.accent
                        size: Appearance.fontSizeLarge
                    }

                    Text {
                        text: sshRow.sessionLabel + (sshRow.sessionCount > 1 ? " ×" + sshRow.sessionCount : "")
                        color: Colors.text
                        font.pixelSize: Appearance.fontSizeXS
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        visible: sshRow.sessionType !== "ssh"
                        text: sshRow.sessionType.toUpperCase()
                        color: Colors.textSecondary
                        font.pixelSize: Appearance.fontSizeXXS
                        font.weight: Font.Medium
                    }

                    SharedWidgets.IconButton {
                        visible: sshRow.sessionType === "ssh"
                        icon: "terminal.svg"
                        size: 28
                        iconSize: 14
                        iconColor: sshHover.containsMouse ? Colors.primary : Colors.textDisabled
                        tooltipText: "Open shell"
                        onClicked: {
                            var host = sshRow.sessionLabel.split("@")[1] || sshRow.sessionLabel;
                            Quickshell.execDetached(SU.terminalCommand("exec ssh \"$1\"", host));
                        }
                    }
                }
            }
        }
    }

    SharedWidgets.LiveLogOverlay {
        id: logOverlay
        Layout.fillWidth: true
        Layout.preferredHeight: 300
        visible: false
        onCloseRequested: {
            visible = false;
            command = [];
        }
    }

    Text {
        visible: !root.hasDockerContainers && !root.hasSshHosts && !root.hasLiveSshSessions
        text: "No containers, SSH hosts, or active sessions"
        color: Colors.textDisabled
        font.pixelSize: Appearance.fontSizeXS
        Layout.alignment: Qt.AlignHCenter
    }
}
