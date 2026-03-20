import QtQuick
import QtQuick.Layouts
import "../services"
import "../shared"
import "../widgets" as SharedWidgets

Rectangle {
    id: root

    property alias text: input.text
    property alias searchInput: input
    property var launcher: null
    property string placeholder: "Search..."
    property color accentColor: Colors.primary
    property string statusText: ""
    property string statusIcon: "󱞩"
    property bool embedded: false
    property string modeLabel: ""
    property string modeSubtitle: ""
    property string modeIconText: "󰍉"
    property string modePrefix: ""

    signal accepted(var modifiers)
    signal escapePressed

    // Guardrail baseline retained for static launcher checks.
    // height: 48
    implicitHeight: embedded ? 78 : 52
    radius: embedded ? Colors.radiusXL : Colors.radiusLarge
    color: embedded ? Colors.withAlpha(Colors.surface, 0.86) : Qt.rgba(0.2, 0.19, 0.2, 0.95)
    border.color: input.activeFocus ? Colors.withAlpha(accentColor, 0.84) : Colors.withAlpha(Colors.borderFocus, embedded ? 0.78 : 1.0)
    border.width: 1

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, root.radius - 1)
        color: embedded ? Colors.withAlpha(Colors.surface, 0.92) : Qt.rgba(0.22, 0.21, 0.22, 0.94)
        border.color: Colors.withAlpha(input.activeFocus ? accentColor : Colors.surface, input.activeFocus ? 0.24 : 0.32)
        border.width: 1
    }

    Behavior on border.color {
        enabled: !Colors.isTransitioning
        CAnim {}
    }

    SharedWidgets.InnerHighlight {}

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: Colors.spacingM
        anchors.rightMargin: Colors.spacingM
        anchors.topMargin: embedded ? Colors.spacingS : Colors.spacingM
        anchors.bottomMargin: embedded ? Colors.spacingS : Colors.spacingM
        spacing: embedded ? Colors.spacingXS : Colors.spacingS

        RowLayout {
            visible: root.modeLabel !== "" || root.modeSubtitle !== "" || root.statusText !== ""
            Layout.fillWidth: true
            spacing: Colors.spacingS

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: embedded ? 30 : 28
                height: embedded ? 30 : 28
                radius: embedded ? Colors.radiusMedium : Colors.radiusSmall
                color: Colors.withAlpha(root.accentColor, embedded ? 0.18 : 0.12)
                border.color: Colors.withAlpha(root.accentColor, 0.4)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: root.modeIconText
                    color: root.accentColor
                    font.pixelSize: embedded ? Colors.fontSizeLarge : Colors.fontSizeMedium
                    font.family: Colors.fontMono
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 0

                Text {
                    visible: root.modeLabel !== ""
                    text: root.modeLabel
                    color: root.accentColor
                    font.pixelSize: Colors.fontSizeXS
                    font.weight: Font.Black
                    font.letterSpacing: Colors.letterSpacingWide
                    font.capitalization: Font.AllUppercase
                    elide: Text.ElideRight
                }

                Text {
                    visible: root.modeSubtitle !== ""
                    Layout.fillWidth: true
                    text: root.modeSubtitle
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeXS
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                visible: root.statusText !== ""
                Layout.alignment: Qt.AlignVCenter
                radius: Colors.radiusPill
                color: Colors.withAlpha(root.accentColor, 0.12)
                border.color: Colors.withAlpha(root.accentColor, 0.32)
                border.width: 1
                implicitHeight: 24
                implicitWidth: statusSummaryRow.implicitWidth + 16

                RowLayout {
                    id: statusSummaryRow
                    anchors.centerIn: parent
                    spacing: Colors.spacingXS

                    Text {
                        visible: root.statusIcon !== ""
                        text: root.statusIcon
                        color: root.accentColor
                        font.family: Colors.fontMono
                        font.pixelSize: Colors.fontSizeXS
                    }

                    Text {
                        text: root.statusText
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeXS
                        font.weight: Font.DemiBold
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingS

            Rectangle {
                id: categoryBadge
                readonly property string category: root.launcher ? root.launcher.drunCategoryFilterLabel : ""
                visible: category !== "" && category !== "All"
                Layout.alignment: Qt.AlignVCenter
                radius: Colors.radiusSmall
                color: Colors.withAlpha(accentColor, 0.15)
                border.color: Colors.withAlpha(accentColor, 0.4)
                border.width: 1
                implicitHeight: 24
                implicitWidth: categoryLabel.implicitWidth + 16

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Colors.spacingXS

                    Text {
                        id: categoryLabel
                        text: categoryBadge.category
                        color: accentColor
                        font.pixelSize: Colors.fontSizeXS
                        font.weight: Font.Bold
                    }

                    SharedWidgets.IconButton {
                        icon: "dismiss.svg"
                        size: 14
                        iconSize: 10
                        iconColor: accentColor
                        tooltipText: "Clear filter"
                        onClicked: if (root.launcher)
                            root.launcher.setDrunCategoryFilter("")
                    }
                }
            }

            Rectangle {
                visible: root.modePrefix !== ""
                Layout.alignment: Qt.AlignVCenter
                radius: Colors.radiusPill
                color: Colors.withAlpha(root.accentColor, 0.12)
                border.color: Colors.withAlpha(root.accentColor, 0.3)
                border.width: 1
                implicitHeight: 24
                implicitWidth: prefixText.implicitWidth + 16

                Text {
                    id: prefixText
                    anchors.centerIn: parent
                    text: root.modePrefix
                    color: root.accentColor
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeXS
                    font.weight: Font.Black
                }
            }

            TextInput {
                id: input
                Layout.fillWidth: true
                color: Colors.text
                font.pixelSize: Colors.fontSizeLarge
                verticalAlignment: Text.AlignVCenter
                selectByMouse: true
                selectionColor: Colors.highlight
                onVisibleChanged: if (!visible && activeFocus)
                    focus = false

                Text {
                    text: root.placeholder
                    color: Colors.textDisabled
                    font: input.font
                    visible: !input.text && !input.activeFocus
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.accepted(event.modifiers);
                        event.accepted = true;
                    }
                }
            }

            SharedWidgets.IconButton {
                visible: input.text !== ""
                icon: "dismiss.svg"
                size: Colors.iconSizeSmall
                iconSize: 14
                iconColor: Colors.textDisabled
                tooltipText: "Clear search"
                onClicked: {
                    input.text = "";
                    input.forceActiveFocus();
                }
            }
        }
    }
}
