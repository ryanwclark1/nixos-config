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
    spacing: Appearance.spacingM

    readonly property bool showCategoryFilters: root.showCategoryFiltersSection && root.launcher.showLauncherHome && root.launcher.drunCategoryFiltersEnabled && root.launcher.mode === "drun" && root.launcher.drunCategoryOptions.length > 1
    readonly property bool categorySummaryExpanded: root.launcher.drunCategorySectionExpanded || root.launcher.drunCategoryFilter !== ""
    readonly property bool showCategoryChips: root.showCategoryFilters && root.categorySummaryExpanded
    readonly property bool showRecentItems: root.showHomeSections && root.launcher.recentItems.length > 0
    readonly property bool showSuggestions: root.showHomeSections && root.launcher.mode === "drun" && root.launcher.suggestionItems.length > 0
    readonly property bool useSplitColumns: width >= 720 && root.showRecentItems && root.showSuggestions

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
            spacing: Appearance.spacingS

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingS

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    radius: Appearance.radiusPill
                    color: categorySummaryMouse.containsMouse ? Colors.primaryAccent : Colors.withAlpha(Colors.surface, 0.72)
                    border.color: root.launcher.drunCategoryFilter !== "" ? Colors.withAlpha(Colors.primary, 0.55) : Colors.border
                    border.width: 1
                    implicitHeight: 30
                    implicitWidth: categorySummaryRow.implicitWidth + 18

                    RowLayout {
                        id: categorySummaryRow
                        anchors.centerIn: parent
                        spacing: Appearance.spacingXS

                        Text {
                            text: root.launcher.drunCategoryFilter === "" ? "󰍉" : "󰌌"
                            color: root.launcher.drunCategoryFilter === "" ? Colors.textSecondary : Colors.primary
                            font.family: Appearance.fontMono
                            font.pixelSize: Appearance.fontSizeSmall
                        }

                        Text {
                            text: root.launcher.drunCategoryFilter === "" ? "All Apps" : root.launcher.drunCategoryFilterLabel
                            color: root.launcher.drunCategoryFilter === "" ? Colors.text : Colors.primary
                            font.pixelSize: Appearance.fontSizeSmall
                            font.weight: root.launcher.drunCategoryFilter === "" ? Font.Medium : Font.DemiBold
                        }

                        Text {
                            text: root.categorySummaryExpanded ? "󰅀" : "󰅂"
                            color: Colors.textDisabled
                            font.family: Appearance.fontMono
                            font.pixelSize: Appearance.fontSizeXS
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
                    font.pixelSize: Appearance.fontSizeXS
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

    GridLayout {
        Layout.fillWidth: true
        visible: root.showHomeSections
        columns: root.useSplitColumns ? 2 : 1
        rowSpacing: Appearance.spacingL
        columnSpacing: Appearance.spacingL

        // Recent Apps Grid
        SharedWidgets.ThemedContainer {
            variant: "card"
            radius: Appearance.radiusLarge
            showGradient: true
            customHighlightOpacity: 0.12
            Layout.fillWidth: true
            visible: root.showRecentItems
            clip: true
            implicitHeight: recentLayout.implicitHeight + (Appearance.paddingLarge * 2)

            ColumnLayout {
                id: recentLayout
                anchors.fill: parent
                anchors.margins: Appearance.paddingLarge
                spacing: Appearance.spacingM

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacingS
                    Text {
                        text: "RECENT"
                        color: Colors.textDisabled
                        font.pixelSize: Appearance.fontSizeXXS
                        font.weight: Font.Black
                        font.letterSpacing: Appearance.letterSpacingWide
                    }
                    Rectangle { Layout.fillWidth: true; height: 1; color: Colors.border; opacity: 0.4 }
                    Text {
                        text: root.launcher.recentItems.length
                        color: Colors.textDisabled
                        font.pixelSize: Appearance.fontSizeXXS
                        font.weight: Font.Bold
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: Appearance.spacingM
                    flow: Flow.LeftToRight

                    Repeater {
                        model: root.launcher.recentItems
                        delegate: Rectangle {
                            width: (recentLayout.width - (Appearance.spacingM * 3)) / 4
                            height: 94
                            radius: Appearance.radiusLarge
                            readonly property bool hovered: recentHover.containsMouse
                            readonly property bool selected: root.isSelected(modelData)
                            
                            color: selected ? Colors.highlight : (hovered ? Colors.withAlpha("#ffffff", 0.04) : Colors.withAlpha("#000000", 0.15))
                            border.color: selected ? Colors.withAlpha(Colors.primary, 0.4) : (hovered ? Colors.withAlpha(Colors.border, 0.5) : "transparent")
                            border.width: 1
                            scale: hovered ? 1.04 : 1.0
                            Behavior on scale { NumberAnimation { duration: Appearance.durationMedium; easing.type: Easing.OutCubic } }
                            Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: Appearance.spacingS
                                width: parent.width - 16

                                Rectangle {
                                    Layout.alignment: Qt.AlignHCenter
                                    width: 44
                                    height: 44
                                    radius: Appearance.radiusMedium
                                    color: Colors.surface
                                    border.color: Colors.withAlpha(Colors.primary, 0.15)
                                    border.width: 1

                                    SharedWidgets.AppIcon {
                                        anchors.centerIn: parent
                                        iconName: modelData ? String(modelData.icon || "") : ""
                                        desktopId: modelData ? String(modelData.desktopId || "") : ""
                                        iconSize: 30
                                        fallbackIcon: "󰀻"
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: root.primaryText(modelData)
                                    color: selected ? Colors.primary : Colors.text
                                    font.pixelSize: Appearance.fontSizeXS
                                    font.weight: selected ? Font.Bold : Font.Medium
                                    horizontalAlignment: Text.AlignHCenter
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
            }
        }

        // Suggested Apps List
        SharedWidgets.ThemedContainer {
            variant: "card"
            radius: Appearance.radiusLarge
            showGradient: true
            customHighlightOpacity: 0.12
            Layout.fillWidth: true
            visible: root.showSuggestions
            clip: true
            implicitHeight: suggestionColumn.implicitHeight + (Appearance.paddingLarge * 2)

            ColumnLayout {
                id: suggestionColumn
                anchors.fill: parent
                anchors.margins: Appearance.paddingLarge
                spacing: Appearance.spacingM

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacingS
                    Text {
                        text: "SUGGESTED"
                        color: Colors.textDisabled
                        font.pixelSize: Appearance.fontSizeXXS
                        font.weight: Font.Black
                        font.letterSpacing: Appearance.letterSpacingWide
                    }
                    Rectangle { Layout.fillWidth: true; height: 1; color: Colors.border; opacity: 0.4 }
                }

                Repeater {
                    model: root.launcher.suggestionItems
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 46
                        clip: true
                        radius: Appearance.radiusMedium
                        readonly property bool hovered: suggestionHover.containsMouse
                        readonly property bool selected: root.isSelected(modelData)
                        
                        color: selected ? Colors.highlight : (hovered ? Colors.withAlpha("#ffffff", 0.04) : "transparent")
                        border.color: selected ? Colors.withAlpha(Colors.primary, 0.4) : (hovered ? Colors.withAlpha(Colors.border, 0.5) : "transparent")
                        border.width: 1
                        scale: selected ? 1.01 : (hovered ? 1.005 : 1.0)

                        Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }
                        Behavior on scale { NumberAnimation { duration: Appearance.durationMedium; easing.type: Easing.OutCubic } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Appearance.spacingS
                            spacing: Appearance.paddingMedium

                            Rectangle {
                                implicitWidth: 32
                                implicitHeight: 32
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
                                    iconSize: 20
                                    fallbackIcon: "󰀻"
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 0

                                Text {
                                    text: root.primaryText(modelData)
                                    color: selected ? Colors.primary : Colors.text
                                    font.pixelSize: Appearance.fontSizeSmall
                                    font.weight: selected ? Font.Bold : Font.DemiBold
                                    elide: Text.ElideRight
                                    wrapMode: Text.NoWrap
                                    maximumLineCount: 1
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: root.secondaryText(modelData) || "Frequently used"
                                    color: selected ? Colors.withAlpha(Colors.primary, 0.8) : Colors.textSecondary
                                    font.pixelSize: Appearance.fontSizeXXS
                                    elide: Text.ElideRight
                                    wrapMode: Text.NoWrap
                                    maximumLineCount: 1
                                    Layout.fillWidth: true
                                }
                            }

                            Rectangle {
                                radius: Appearance.radiusPill
                                color: selected ? Colors.primarySubtle : Colors.highlight
                                border.color: selected ? Colors.primaryRing : Colors.border
                                border.width: 1
                                implicitWidth: suggestionBadge.implicitWidth + 14
                                implicitHeight: 20

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
