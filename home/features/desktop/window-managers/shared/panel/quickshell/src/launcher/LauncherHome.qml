import QtQuick
import QtQuick.Layouts
import "../services"
import "../shared"
import "../widgets" as SharedWidgets

ColumnLayout {
    id: root

    required property var launcher
    property bool showCategoryFiltersSection: true
    property bool showHomeSections: true
    spacing: root.launcher.compactMode ? Appearance.spacingXS : Appearance.spacingS

    readonly property bool showCategoryFilters: root.showCategoryFiltersSection && root.launcher.showLauncherHome && root.launcher.drunCategoryFiltersEnabled && root.launcher.mode === "drun" && root.launcher.drunCategoryOptions.length > 1
    readonly property bool categorySummaryExpanded: root.launcher.drunCategorySectionExpanded || root.launcher.drunCategoryFilter !== ""
    readonly property bool showCategoryChips: root.showCategoryFilters && root.categorySummaryExpanded
    readonly property bool showRecentItems: root.showHomeSections && root.launcher.recentItems.length > 0
    readonly property bool showSuggestions: root.showHomeSections && root.launcher.mode === "drun" && root.launcher.suggestionItems.length > 0
    readonly property bool showBrowseShelf: root.showRecentItems || root.showSuggestions
    readonly property real recentCardWidth: root.launcher.compactMode ? 118 : 136
    readonly property real suggestionCardWidth: root.launcher.compactMode ? 184 : 208

    function primaryText(item) {
        if (!item)
            return "";
        return String(item.name || item.label || item.title || "");
    }

    function secondaryText(item) {
        if (!item)
            return "";

        var title = String(item.title || "");
        var description = String(item.description || "");
        var fullPath = String(item.fullPath || "");
        var exec = String(item.exec || "");
        var primary = primaryText(item);

        if (title !== "" && title !== primary)
            return title;
        if (description !== "" && description !== primary)
            return description;
        if (fullPath !== "" && fullPath !== primary)
            return fullPath;
        if (exec !== "" && exec !== primary)
            return exec;
        return "";
    }

    function itemKey(item) {
        return root.launcher.homeItemKey(item);
    }

    function isSelected(item) {
        var key = itemKey(item);
        return key !== "" && key === root.launcher.selectedHomeItemKey;
    }

    Rectangle {
        Layout.fillWidth: true
        visible: root.showCategoryFilters
        color: "transparent"
        implicitHeight: categoryColumn.implicitHeight

        ColumnLayout {
            id: categoryColumn
            anchors.fill: parent
            spacing: Appearance.spacingXS

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingS

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    radius: Appearance.radiusPill
                    color: categorySummaryMouse.containsMouse ? Colors.primaryAccent : Colors.withAlpha(Colors.surface, 0.72)
                    border.color: root.launcher.drunCategoryFilter !== "" ? Colors.withAlpha(Colors.primary, 0.55) : Colors.border
                    border.width: 1
                    implicitHeight: 26
                    implicitWidth: categorySummaryRow.implicitWidth + 16

                    RowLayout {
                        id: categorySummaryRow
                        anchors.centerIn: parent
                        spacing: Appearance.spacingXS

                        Text {
                            text: root.launcher.drunCategoryFilter === "" ? "󰍉" : "󰌌"
                            color: root.launcher.drunCategoryFilter === "" ? Colors.textSecondary : Colors.primary
                            font.family: Appearance.fontMono
                            font.pixelSize: Appearance.fontSizeXS
                        }

                        Text {
                            text: root.launcher.drunCategoryFilter === "" ? "All Apps" : root.launcher.drunCategoryFilterLabel
                            color: root.launcher.drunCategoryFilter === "" ? Colors.text : Colors.primary
                            font.pixelSize: Appearance.fontSizeXS
                            font.weight: root.launcher.drunCategoryFilter === "" ? Font.Medium : Font.DemiBold
                        }

                        Text {
                            text: root.categorySummaryExpanded ? "󰅀" : "󰅂"
                            color: Colors.textDisabled
                            font.family: Appearance.fontMono
                            font.pixelSize: Appearance.fontSizeXXS
                        }
                    }

                    MouseArea {
                        id: categorySummaryMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.launcher.drunCategorySectionExpanded = !root.launcher.drunCategorySectionExpanded
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: root.launcher.drunCategoryFilterSummary
                    color: Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeXXS
                    elide: Text.ElideRight
                }
            }

            Flow {
                Layout.fillWidth: true
                visible: root.showCategoryChips
                spacing: Appearance.spacingXS

                Repeater {
                    model: root.launcher.drunCategoryOptions
                    delegate: SharedWidgets.FilterChip {
                        required property var modelData

                        label: String(modelData.label || "All")
                        selected: String(modelData.key || "") === root.launcher.drunCategoryFilter

                        onClicked: root.launcher.setDrunCategoryFilter(String(modelData.key || ""))
                    }
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        visible: root.showBrowseShelf
        radius: Appearance.radiusLarge
        color: Colors.withAlpha(Colors.surface, 0.52)
        border.color: Colors.withAlpha(Colors.primary, 0.14)
        border.width: 1
        implicitHeight: shelfColumn.implicitHeight + (root.launcher.compactMode ? Appearance.spacingS * 2 : Appearance.spacingM * 2)

        ColumnLayout {
            id: shelfColumn
            anchors.fill: parent
            anchors.margins: root.launcher.compactMode ? Appearance.spacingS : Appearance.spacingM
            spacing: Appearance.spacingXS

            Text {
                visible: root.showRecentItems
                text: "RECENT"
                color: Colors.textDisabled
                font.pixelSize: Appearance.fontSizeXXS
                font.weight: Font.Black
                font.letterSpacing: Appearance.letterSpacingWide
            }

            Flow {
                id: recentFlow
                Layout.fillWidth: true
                visible: root.showRecentItems
                width: parent.width
                spacing: Appearance.spacingXS

                Repeater {
                    model: root.launcher.recentItems

                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool hovered: recentHover.containsMouse
                        readonly property bool selected: root.isSelected(modelData)

                        width: root.recentCardWidth
                        height: 40
                        radius: Appearance.radiusMedium
                        color: selected ? Colors.highlight : (hovered ? Colors.withAlpha("#ffffff", 0.04) : Colors.withAlpha(Colors.surface, 0.48))
                        border.color: selected ? Colors.withAlpha(Colors.primary, 0.4) : (hovered ? Colors.withAlpha(Colors.border, 0.5) : Colors.border)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Appearance.spacingXS
                            spacing: Appearance.spacingXS

                            Rectangle {
                                width: 24
                                height: 24
                                radius: Appearance.radiusSmall
                                color: Colors.surface
                                border.color: Colors.withAlpha(Colors.primary, 0.15)
                                border.width: 1

                                SharedWidgets.AppIcon {
                                    anchors.centerIn: parent
                                    iconName: modelData ? String(modelData.icon || "") : ""
                                    desktopId: modelData ? String(modelData.desktopId || "") : ""
                                    appId: modelData ? String(modelData.appId || "") : ""
                                    execName: modelData ? String(modelData.exec || "") : ""
                                    appName: root.primaryText(modelData)
                                    iconSize: 16
                                    fallbackIcon: "info.svg"
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.primaryText(modelData)
                                color: selected ? Colors.primary : Colors.text
                                font.pixelSize: Appearance.fontSizeXS
                                font.weight: selected ? Font.Bold : Font.Medium
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }

                        MouseArea {
                            id: recentHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.launcher.activateHomeItem(modelData)
                        }
                    }
                }
            }

            Text {
                visible: root.showSuggestions
                text: "SUGGESTED"
                color: Colors.textDisabled
                font.pixelSize: Appearance.fontSizeXXS
                font.weight: Font.Black
                font.letterSpacing: Appearance.letterSpacingWide
            }

            Flow {
                id: suggestionFlow
                Layout.fillWidth: true
                visible: root.showSuggestions
                width: parent.width
                spacing: Appearance.spacingXS

                Repeater {
                    model: root.launcher.suggestionItems

                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool hovered: suggestionHover.containsMouse
                        readonly property bool selected: root.isSelected(modelData)

                        width: Math.min(root.suggestionCardWidth, suggestionFlow.width)
                        height: 36
                        radius: Appearance.radiusMedium
                        color: selected ? Colors.highlight : (hovered ? Colors.withAlpha("#ffffff", 0.04) : Colors.withAlpha(Colors.surface, 0.42))
                        border.color: selected ? Colors.withAlpha(Colors.primary, 0.4) : (hovered ? Colors.withAlpha(Colors.border, 0.5) : Colors.border)
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Appearance.spacingXS
                            spacing: Appearance.spacingXS

                            Rectangle {
                                width: 22
                                height: 22
                                radius: Appearance.radiusSmall
                                color: Colors.surface
                                border.color: Colors.primaryGhost
                                border.width: 1
                                Layout.alignment: Qt.AlignVCenter

                                SharedWidgets.AppIcon {
                                    anchors.centerIn: parent
                                    iconName: modelData ? String(modelData.icon || "") : ""
                                    desktopId: modelData ? String(modelData.desktopId || "") : ""
                                    appId: modelData ? String(modelData.appId || "") : ""
                                    execName: modelData ? String(modelData.exec || "") : ""
                                    appName: root.primaryText(modelData)
                                    iconSize: 14
                                    fallbackIcon: "info.svg"
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.primaryText(modelData)
                                color: selected ? Colors.primary : Colors.text
                                font.pixelSize: Appearance.fontSizeXS
                                font.weight: selected ? Font.Bold : Font.DemiBold
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Rectangle {
                                radius: Appearance.radiusPill
                                color: selected ? Colors.primarySubtle : Colors.highlight
                                border.color: selected ? Colors.primaryRing : Colors.border
                                border.width: 1
                                implicitWidth: suggestionBadge.implicitWidth + 12
                                implicitHeight: 18

                                Text {
                                    id: suggestionBadge
                                    anchors.centerIn: parent
                                    text: (modelData._usage || 0) + "x"
                                    color: selected ? Colors.primary : Colors.textDisabled
                                    font.pixelSize: Appearance.fontSizeXXS
                                    font.weight: Font.Black
                                }
                            }
                        }

                        MouseArea {
                            id: suggestionHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.launcher.activateHomeItem(modelData)
                        }
                    }
                }
            }
        }
    }
}
