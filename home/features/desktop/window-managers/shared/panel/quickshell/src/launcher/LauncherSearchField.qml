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
    property string statusIcon: "info.svg"
    property bool embedded: false
    property string modeLabel: ""
    property string modeSubtitle: ""
    property string modeIconText: "search-visual.svg"
    property string modePrefix: ""

    readonly property bool modeHeaderVisible: root.modeLabel !== "" || root.modeSubtitle !== "" || root.statusText !== ""
    readonly property real modeHeaderLeadWidth: (embedded ? 24 : 28) + Appearance.spacingXS

    signal accepted(var modifiers)
    signal escapePressed

    implicitHeight: embedded ? 58 : 52
    radius: embedded ? Appearance.radiusXL : Appearance.radiusLarge
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
        anchors.leftMargin: Appearance.spacingM
        anchors.rightMargin: Appearance.spacingM
        anchors.topMargin: embedded ? Appearance.spacingXS : Appearance.spacingM
        anchors.bottomMargin: embedded ? Appearance.spacingXS : Appearance.spacingM
        spacing: embedded ? Appearance.spacingXS : Appearance.spacingS

        RowLayout {
            visible: root.modeHeaderVisible
            Layout.fillWidth: true
            spacing: Appearance.spacingXS

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: embedded ? 24 : 28
                height: embedded ? 24 : 28
                radius: embedded ? Appearance.radiusSmall : Appearance.radiusSmall
                color: Colors.withAlpha(root.accentColor, embedded ? 0.18 : 0.12)
                border.color: Colors.withAlpha(root.accentColor, 0.4)
                border.width: 1

                Loader {
                    anchors.centerIn: parent
                    sourceComponent: String(root.modeIconText || "").endsWith(".svg") ? _sfSvg : _sfNerd
                }
                Component { id: _sfSvg; SharedWidgets.SvgIcon { source: root.modeIconText; color: root.accentColor; size: embedded ? Appearance.fontSizeMedium : Appearance.fontSizeMedium } }
                Component { id: _sfNerd; Text { text: root.modeIconText; color: root.accentColor; font.pixelSize: embedded ? Appearance.fontSizeMedium : Appearance.fontSizeMedium; font.family: Appearance.fontMono } }
            }

            Text {
                visible: root.modeLabel !== ""
                text: root.modeLabel
                color: root.accentColor
                font.pixelSize: Appearance.fontSizeXS
                font.weight: Font.Black
                font.letterSpacing: Appearance.letterSpacingWide
                font.capitalization: Font.AllUppercase
                elide: Text.ElideRight
            }

            Text {
                visible: root.modeSubtitle !== ""
                Layout.fillWidth: true
                text: root.modeSubtitle
                color: Colors.textSecondary
                font.pixelSize: Appearance.fontSizeXS
                elide: Text.ElideRight
            }

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                visible: root.statusText !== ""
                Layout.alignment: Qt.AlignVCenter
                radius: Appearance.radiusPill
                color: Colors.withAlpha(root.accentColor, 0.12)
                border.color: Colors.withAlpha(root.accentColor, 0.32)
                border.width: 1
                implicitHeight: 22
                implicitWidth: statusSummaryRow.implicitWidth + 14

                RowLayout {
                    id: statusSummaryRow
                    anchors.centerIn: parent
                    spacing: Appearance.spacingXS

                    Loader {
                        visible: root.statusIcon !== ""
                        property string _si: root.statusIcon
                        sourceComponent: String(_si).endsWith(".svg") ? _siSvg : _siNerd
                    }
                    Component { id: _siSvg; SharedWidgets.SvgIcon { source: root.statusIcon; color: root.accentColor; size: Appearance.fontSizeXS } }
                    Component { id: _siNerd; Text { text: root.statusIcon; color: root.accentColor; font.family: Appearance.fontMono; font.pixelSize: Appearance.fontSizeXS } }

                    Text {
                        text: root.statusText
                        color: Colors.textSecondary
                        font.pixelSize: Appearance.fontSizeXS
                        font.weight: Font.DemiBold
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            Item {
                visible: root.modeHeaderVisible
                Layout.preferredWidth: root.modeHeaderLeadWidth
                Layout.fillHeight: true
            }

            Rectangle {
                id: categoryBadge
                readonly property string category: root.launcher ? root.launcher.drunCategoryFilterLabel : ""
                visible: category !== "" && category !== "All"
                Layout.alignment: Qt.AlignVCenter
                radius: Appearance.radiusSmall
                color: Colors.withAlpha(accentColor, 0.15)
                border.color: Colors.withAlpha(accentColor, 0.4)
                border.width: 1
                implicitHeight: 22
                implicitWidth: categoryLabel.implicitWidth + 14

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Appearance.spacingXS

                    Text {
                        id: categoryLabel
                        text: categoryBadge.category
                        color: accentColor
                        font.pixelSize: Appearance.fontSizeXS
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
                radius: Appearance.radiusPill
                color: Colors.withAlpha(root.accentColor, 0.12)
                border.color: Colors.withAlpha(root.accentColor, 0.3)
                border.width: 1
                implicitHeight: 22
                implicitWidth: prefixText.implicitWidth + 14

                Text {
                    id: prefixText
                    anchors.centerIn: parent
                    text: root.modePrefix
                    color: root.accentColor
                    font.family: Appearance.fontMono
                    font.pixelSize: Appearance.fontSizeXS
                    font.weight: Font.Black
                }
            }

            TextInput {
                id: input
                Layout.fillWidth: true
                color: Colors.text
                font.pixelSize: embedded ? Appearance.fontSizeMedium : Appearance.fontSizeLarge
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
                size: Appearance.iconSizeSmall
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
