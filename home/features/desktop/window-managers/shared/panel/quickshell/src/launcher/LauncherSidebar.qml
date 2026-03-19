import QtQuick
import QtQuick.Layouts
import "../services"
import "../shared"
import "../widgets" as SharedWidgets

Rectangle {
    id: root

    required property var launcher
    readonly property var _primaryModes: Array.isArray(root.launcher && root.launcher.primaryModes) ? root.launcher.primaryModes : []
    readonly property var _overflowModes: Array.isArray(root.launcher && root.launcher.overflowModes) ? root.launcher.overflowModes : []
    readonly property color accentColor: root.launcher && root.launcher.modeAccentColor ? root.launcher.modeAccentColor : Colors.primary

    radius: Colors.radiusXL
    color: Colors.withAlpha(Colors.surface, 0.74)
    border.color: Colors.withAlpha(root.accentColor, 0.18)
    border.width: 1

    SharedWidgets.InnerHighlight {
        highlightOpacity: 0.14
    }

    component ModeButton: Rectangle {
        required property string modeKey
        required property string label
        required property string iconText
        required property bool compact
        property string prefix: ""
        property bool active: false
        property bool hovered: hoverArea.containsMouse
        signal clicked

        Layout.fillWidth: true
        implicitHeight: compact ? 48 : 52
        radius: Colors.radiusLarge
        color: active ? Colors.withAlpha(root.accentColor, 0.16) : (hovered ? Colors.withAlpha("#ffffff", 0.04) : "transparent")
        border.color: active ? Colors.withAlpha(root.accentColor, 0.36) : (hovered ? Colors.withAlpha(Colors.border, 0.4) : "transparent")
        border.width: 1

        Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }

        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: compact ? 6 : 8
            anchors.verticalCenter: parent.verticalCenter
            width: active ? 4 : 0
            height: active ? parent.height * 0.52 : 0
            radius: Colors.radiusPill
            color: root.accentColor
            opacity: active ? 1 : 0
            Behavior on width { NumberAnimation { duration: Colors.durationFast } }
            Behavior on height { NumberAnimation { duration: Colors.durationFast } }
            Behavior on opacity { NumberAnimation { duration: Colors.durationFast } }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: compact ? Colors.spacingXS : Colors.spacingS
            spacing: compact ? Colors.spacingXS : Colors.paddingMedium

            Rectangle {
                Layout.preferredWidth: compact ? 34 : 32
                Layout.preferredHeight: compact ? 34 : 32
                radius: compact ? Colors.radiusMedium : Colors.radiusSmall
                color: active ? Colors.withAlpha(root.accentColor, 0.12) : Colors.withAlpha(Colors.surface, 0.78)
                border.color: active ? Colors.withAlpha(root.accentColor, 0.3) : "transparent"
                border.width: 1
                visible: !compact

                Text {
                    anchors.centerIn: parent
                    text: iconText || "•"
                    color: active ? root.accentColor : Colors.textSecondary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeLarge
                }
            }

            Text {
                visible: compact
                Layout.alignment: Qt.AlignHCenter
                text: iconText || "•"
                color: active ? root.accentColor : Colors.textSecondary
                font.family: Colors.fontMono
                font.pixelSize: Colors.fontSizeXL
            }

            ColumnLayout {
                visible: !compact
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: label
                    color: active ? Colors.text : Colors.textSecondary
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: active ? Font.Black : Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    visible: prefix !== ""
                    Layout.fillWidth: true
                    text: prefix + " prefix"
                    color: active ? root.accentColor : Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXXS
                    font.family: Colors.fontMono
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.launcher.sidebarCompact ? Colors.spacingS : Colors.spacingM
        spacing: root.launcher.sidebarCompact ? Colors.spacingXS : Colors.spacingM

        Rectangle {
            visible: !root.launcher.sidebarCompact
            Layout.fillWidth: true
            radius: Colors.radiusLarge
            color: Colors.withAlpha(root.accentColor, 0.1)
            border.color: Colors.withAlpha(root.accentColor, 0.22)
            border.width: 1
            implicitHeight: railIntro.implicitHeight + (Colors.spacingM * 2)

            ColumnLayout {
                id: railIntro
                anchors.fill: parent
                anchors.margins: Colors.spacingM
                spacing: Colors.spacingXS

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Colors.spacingS

                    Rectangle {
                        width: 34
                        height: 34
                        radius: Colors.radiusMedium
                        color: Colors.withAlpha(root.accentColor, 0.18)
                        border.color: Colors.withAlpha(root.accentColor, 0.34)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: root.launcher.modeHeroIcon
                            color: root.accentColor
                            font.family: Colors.fontMono
                            font.pixelSize: Colors.fontSizeXL
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: "NAV RAIL"
                            color: Colors.withAlpha(root.accentColor, 0.92)
                            font.pixelSize: Colors.fontSizeXXS
                            font.weight: Font.Black
                            font.letterSpacing: Colors.letterSpacingExtraWide
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.launcher.modeHeroLabel
                            color: Colors.text
                            font.pixelSize: Colors.fontSizeSmall
                            font.weight: Font.Black
                            elide: Text.ElideRight
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.launcher.sidebarOverflowExpanded ? "Advanced modes are open below the primary rail." : "Pinned modes stay visible here while advanced modes live behind More."
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeXS
                    wrapMode: Text.WordWrap
                }
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            contentHeight: modeColumn.implicitHeight

            ColumnLayout {
                id: modeColumn
                width: parent.width
                spacing: Colors.spacingS

                Text {
                    visible: !root.launcher.sidebarCompact
                    text: "PRIMARY"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXXS
                    font.weight: Font.Black
                    font.letterSpacing: Colors.letterSpacingExtraWide
                }

                Repeater {
                    model: root._primaryModes

                    delegate: ModeButton {
                        required property string modelData
                        modeKey: modelData
                        label: root.launcher.modeMeta(modelData).label
                        iconText: root.launcher.modeIcons[modelData] || "•"
                        prefix: root.launcher.modeMeta(modelData).prefix || ""
                        compact: root.launcher.sidebarCompact
                        active: root.launcher.mode === modelData
                        onClicked: root.launcher.open(modelData, true)
                    }
                }

                ModeButton {
                    visible: root._overflowModes.length > 0
                    modeKey: "__more__"
                    label: root.launcher.sidebarOverflowExpanded ? "Hide Advanced" : "Advanced"
                    iconText: root.launcher.sidebarOverflowExpanded ? "󰅀" : "󰅂"
                    compact: root.launcher.sidebarCompact
                    active: root.launcher.sidebarOverflowExpanded || root._overflowModes.indexOf(root.launcher.mode) !== -1
                    onClicked: root.launcher.sidebarOverflowExpanded = !root.launcher.sidebarOverflowExpanded
                }

                ColumnLayout {
                    visible: root.launcher.sidebarOverflowExpanded && root._overflowModes.length > 0
                    Layout.fillWidth: true
                    spacing: Colors.spacingS

                    Text {
                        visible: !root.launcher.sidebarCompact
                        text: "ADVANCED MODES"
                        color: Colors.textDisabled
                        font.pixelSize: Colors.fontSizeXXS
                        font.weight: Font.Black
                        font.letterSpacing: Colors.letterSpacingExtraWide
                    }

                    Repeater {
                        model: root._overflowModes

                        delegate: ModeButton {
                            required property string modelData
                            modeKey: modelData
                            label: root.launcher.modeMeta(modelData).label
                            iconText: root.launcher.modeIcons[modelData] || "•"
                            prefix: root.launcher.modeMeta(modelData).prefix || ""
                            compact: root.launcher.sidebarCompact
                            active: root.launcher.mode === modelData
                            onClicked: root.launcher.open(modelData, true)
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: Colors.spacingS
            implicitHeight: controlsLayout.implicitHeight + (Colors.paddingMedium * 2)
            radius: Colors.radiusLarge
            color: Colors.withAlpha(Colors.surface, 0.72)
            border.color: Colors.withAlpha(root.accentColor, 0.16)
            border.width: 1
            visible: Config.launcherShowModeHints && !root.launcher.sidebarCompact

            ColumnLayout {
                id: controlsLayout
                anchors.fill: parent
                anchors.margins: Colors.paddingMedium
                spacing: Colors.spacingXXS

                Text {
                    text: "CONTROL NOTES"
                    color: Colors.withAlpha(root.accentColor, 0.92)
                    font.pixelSize: Colors.fontSizeXXS
                    font.weight: Font.Black
                    font.letterSpacing: Colors.letterSpacingExtraWide
                }

                Text {
                    Layout.fillWidth: true
                    text: String(root.launcher.modeSummaryText || "")
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeXXS
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                }

                Text {
                    Layout.fillWidth: true
                    text: String(root.launcher.overflowHintText || "")
                    color: Colors.textDisabled
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
