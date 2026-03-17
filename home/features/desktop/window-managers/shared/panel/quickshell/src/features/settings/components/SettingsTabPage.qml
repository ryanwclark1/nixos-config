pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../widgets" as SharedWidgets
import "../../../services"
import "."

SharedWidgets.ScrollableContent {
    id: root

    property string title: ""
    property string subtitle: ""
    property string iconName: ""
    property string tabId: ""
    property bool compactMode: false
    property bool tightSpacing: false
    readonly property var tabMeta: SettingsRegistry.findTab(tabId)
    readonly property var ownerMeta: tabMeta ? tabMeta.owner : null
    default property alias pageContent: contentColumn.data

    anchors.fill: parent
    columnSpacing: Colors.spacingXL

    ColumnLayout {
        id: contentColumn
        Layout.fillWidth: true
        Layout.leftMargin: root.tightSpacing ? 20 : (root.compactMode ? 24 : 32)
        Layout.rightMargin: root.tightSpacing ? 20 : (root.compactMode ? 24 : 32)
        Layout.topMargin: root.tightSpacing ? 20 : (root.compactMode ? 24 : 32)
        Layout.bottomMargin: root.tightSpacing ? 20 : (root.compactMode ? 24 : 32)
        spacing: Colors.spacingXL

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingXS

            Flow {
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width
                spacing: Colors.spacingS

                Text {
                    visible: !!root.iconName
                    text: root.iconName
                    color: Colors.primary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeXL
                }

                Text {
                    Layout.fillWidth: true
                    Layout.preferredWidth: root.iconName ? Math.max(0, parent.width - Colors.fontSizeXL - Colors.spacingS) : parent.width
                    text: root.title
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeHuge
                    font.weight: Font.Bold
                    font.letterSpacing: Colors.letterSpacingTight
                    wrapMode: Text.WordWrap
                }
            }

            Text {
                visible: !!root.subtitle
                text: root.subtitle
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeSmall
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Flow {
                id: ownerBadgeRow
                Layout.fillWidth: true
                spacing: Colors.spacingS
                visible: !!root.ownerMeta
                Layout.preferredWidth: parent.width

                function ownerField(name, fallback) {
                    if (!root.ownerMeta || root.ownerMeta[name] === undefined || root.ownerMeta[name] === null || root.ownerMeta[name] === "")
                        return fallback;
                    return String(root.ownerMeta[name]);
                }

                function ownerChip(label, value) {
                    return label + ": " + value;
                }

                Repeater {
                    model: [
                        {
                            key: "service",
                            label: "Service",
                            fallback: "-"
                        },
                        {
                            key: "configDomain",
                            label: "Domain",
                            fallback: "-"
                        },
                        {
                            key: "surface",
                            label: "Surface",
                            fallback: "none"
                        }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        implicitHeight: 24
                        implicitWidth: badgeText.implicitWidth + 16
                        radius: Colors.radiusPill
                        color: Colors.modalFieldSurface
                        border.color: Colors.border
                        border.width: 1

                        Text {
                            id: badgeText
                            anchors.centerIn: parent
                            text: ownerBadgeRow.ownerChip(modelData.label, ownerBadgeRow.ownerField(modelData.key, modelData.fallback))
                            color: Colors.textSecondary
                            font.pixelSize: Colors.fontSizeXS
                        }
                    }
                }
            }
        }
    }
}
