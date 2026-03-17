import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

ColumnLayout {
    id: root

    required property var launcher
    property bool showCategoryFiltersSection: true
    property bool showHomeSections: true
    spacing: Colors.spacingM

    readonly property bool showCategoryFilters: root.showCategoryFiltersSection && root.launcher.showLauncherHome && root.launcher.drunCategoryFiltersEnabled && root.launcher.mode === "drun" && root.launcher.drunCategoryOptions.length > 1
    readonly property bool categorySummaryExpanded: root.launcher.drunCategorySectionExpanded || root.launcher.drunCategoryFilter !== ""
    readonly property bool showCategoryChips: root.showCategoryFilters && root.categorySummaryExpanded
    readonly property bool showRecentItems: root.launcher.showLauncherHome && root.launcher.recentItems.length > 0
    readonly property bool showSuggestions: root.launcher.showLauncherHome && root.launcher.mode === "drun" && root.launcher.suggestionItems.length > 0
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
            spacing: Colors.spacingS

            RowLayout {
                Layout.fillWidth: true
                spacing: Colors.spacingS

                Rectangle {
                    Layout.alignment: Qt.AlignVCenter
                    radius: Colors.radiusPill
                    color: categorySummaryMouse.containsMouse ? Colors.withAlpha(Colors.primary, 0.14) : Colors.withAlpha(Colors.surface, 0.72)
                    border.color: root.launcher.drunCategoryFilter !== "" ? Colors.withAlpha(Colors.primary, 0.55) : Colors.border
                    border.width: 1
                    implicitHeight: 30
                    implicitWidth: categorySummaryRow.implicitWidth + 18

                    RowLayout {
                        id: categorySummaryRow
                        anchors.centerIn: parent
                        spacing: Colors.spacingXS

                        Text {
                            text: root.launcher.drunCategoryFilter === "" ? "󰍉" : "󰌌"
                            color: root.launcher.drunCategoryFilter === "" ? Colors.textSecondary : Colors.primary
                            font.family: Colors.fontMono
                            font.pixelSize: Colors.fontSizeSmall
                        }

                        Text {
                            text: root.launcher.drunCategoryFilter === "" ? "All Apps" : root.launcher.drunCategoryFilterLabel
                            color: root.launcher.drunCategoryFilter === "" ? Colors.text : Colors.primary
                            font.pixelSize: Colors.fontSizeSmall
                            font.weight: root.launcher.drunCategoryFilter === "" ? Font.Medium : Font.DemiBold
                        }

                        Text {
                            text: root.categorySummaryExpanded ? "󰅀" : "󰅂"
                            color: Colors.textDisabled
                            font.family: Colors.fontMono
                            font.pixelSize: Colors.fontSizeXS
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
                    font.pixelSize: Colors.fontSizeXS
                    elide: Text.ElideRight
                }
            }

            Flow {
                Layout.fillWidth: true
                visible: root.showCategoryChips
                spacing: Colors.spacingXS

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
        rowSpacing: Colors.spacingM
        columnSpacing: Colors.spacingM

        Rectangle {
            Layout.fillWidth: true
            visible: root.showRecentItems
            clip: true
            color: Colors.bgWidget
            radius: Colors.radiusMedium
            border.color: Colors.border
            border.width: 1
            implicitHeight: recentColumn.implicitHeight + 24

            ColumnLayout {
                id: recentColumn
                anchors.fill: parent
                anchors.margins: Colors.spacingM
                spacing: Colors.spacingS

                SharedWidgets.SectionLabel {
                    label: "RECENT"
                }

                Repeater {
                    model: root.launcher.recentItems
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 42
                        clip: true
                        radius: Colors.radiusSmall
                        readonly property bool hovered: recentHover.containsMouse
                        readonly property bool selected: root.isSelected(modelData)
                        color: selected ? Colors.withAlpha(Colors.primary, 0.14) : (hovered ? Colors.withAlpha(Colors.primary, 0.08) : "transparent")
                        border.color: selected ? Colors.withAlpha(Colors.primary, 0.52) : (hovered ? Colors.withAlpha(Colors.primary, 0.28) : "transparent")
                        border.width: selected || hovered ? 1 : 0
                        scale: selected ? 1.01 : (hovered ? 1.008 : 1.0)
                        layer.enabled: selected || hovered

                        Behavior on color {
                            ColorAnimation { duration: Colors.durationFast }
                        }
                        Behavior on border.color {
                            ColorAnimation { duration: Colors.durationFast }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: Colors.durationFast
                                easing.type: Easing.OutCubic
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Colors.spacingS
                            spacing: Colors.paddingSmall

                            Rectangle {
                                implicitWidth: 28
                                implicitHeight: 28
                                radius: Colors.radiusXS
                                color: selected ? Colors.withAlpha(Colors.primary, 0.14) : (hovered ? Colors.withAlpha(Colors.primary, 0.12) : Colors.surface)
                                border.color: selected ? Colors.withAlpha(Colors.primary, 0.32) : "transparent"
                                border.width: selected ? 1 : 0
                                Layout.alignment: Qt.AlignVCenter

                                SharedWidgets.AppIcon {
                                    anchors.centerIn: parent
                                    iconName: modelData ? String(modelData.icon || "") : ""
                                    desktopId: modelData ? String(modelData.desktopId || "") : ""
                                    appId: modelData ? String(modelData.appId || "") : ""
                                    execName: modelData ? String(modelData.exec || "") : ""
                                    appName: root.primaryText(modelData)
                                    iconSize: 18
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
                                    font.pixelSize: Colors.fontSizeSmall
                                    font.weight: selected ? Font.Bold : Font.DemiBold
                                    elide: Text.ElideRight
                                    wrapMode: Text.NoWrap
                                    maximumLineCount: 1
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: root.secondaryText(modelData)
                                    color: selected ? Colors.withAlpha(Colors.primary, 0.84) : Colors.textSecondary
                                    font.pixelSize: Colors.fontSizeXS
                                    elide: Text.ElideRight
                                    wrapMode: Text.NoWrap
                                    maximumLineCount: 1
                                    Layout.fillWidth: true
                                    visible: text !== ""
                                }
                            }
                        }

                        SharedWidgets.StateLayer {
                            id: recentStateLayer
                            hovered: recentHover.containsMouse
                            pressed: recentHover.pressed
                        }

                        MouseArea {
                            id: recentHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                recentStateLayer.burst(mouse.x, mouse.y);
                                root.launcher.activateHomeItem(modelData);
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: root.showSuggestions
            clip: true
            color: Colors.bgWidget
            radius: Colors.radiusMedium
            border.color: Colors.border
            border.width: 1
            implicitHeight: suggestionColumn.implicitHeight + 24

            ColumnLayout {
                id: suggestionColumn
                anchors.fill: parent
                anchors.margins: Colors.spacingM
                spacing: Colors.spacingS

                SharedWidgets.SectionLabel {
                    label: "SUGGESTED"
                }

                Repeater {
                    model: root.launcher.suggestionItems
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 42
                        clip: true
                        radius: Colors.radiusSmall
                        readonly property bool hovered: suggestionHover.containsMouse
                        readonly property bool selected: root.isSelected(modelData)
                        color: selected ? Colors.withAlpha(Colors.primary, 0.14) : (hovered ? Colors.withAlpha(Colors.primary, 0.08) : "transparent")
                        border.color: selected ? Colors.withAlpha(Colors.primary, 0.52) : (hovered ? Colors.withAlpha(Colors.primary, 0.28) : "transparent")
                        border.width: selected || hovered ? 1 : 0
                        scale: selected ? 1.01 : (hovered ? 1.008 : 1.0)
                        layer.enabled: selected || hovered

                        Behavior on color {
                            ColorAnimation { duration: Colors.durationFast }
                        }
                        Behavior on border.color {
                            ColorAnimation { duration: Colors.durationFast }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: Colors.durationFast
                                easing.type: Easing.OutCubic
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Colors.spacingS
                            spacing: Colors.paddingSmall

                            Rectangle {
                                implicitWidth: 28
                                implicitHeight: 28
                                radius: Colors.radiusXS
                                color: selected ? Colors.withAlpha(Colors.primary, 0.14) : (hovered ? Colors.withAlpha(Colors.primary, 0.12) : Colors.surface)
                                border.color: selected ? Colors.withAlpha(Colors.primary, 0.32) : "transparent"
                                border.width: selected ? 1 : 0
                                Layout.alignment: Qt.AlignVCenter

                                SharedWidgets.AppIcon {
                                    anchors.centerIn: parent
                                    iconName: modelData ? String(modelData.icon || "") : ""
                                    desktopId: modelData ? String(modelData.desktopId || "") : ""
                                    appId: modelData ? String(modelData.appId || "") : ""
                                    execName: modelData ? String(modelData.exec || "") : ""
                                    appName: root.primaryText(modelData)
                                    iconSize: 18
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
                                    font.pixelSize: Colors.fontSizeSmall
                                    font.weight: selected ? Font.Bold : Font.DemiBold
                                    elide: Text.ElideRight
                                    wrapMode: Text.NoWrap
                                    maximumLineCount: 1
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: root.secondaryText(modelData) || "Frequently used"
                                    color: selected ? Colors.withAlpha(Colors.primary, 0.84) : Colors.textSecondary
                                    font.pixelSize: Colors.fontSizeXS
                                    elide: Text.ElideRight
                                    wrapMode: Text.NoWrap
                                    maximumLineCount: 1
                                    Layout.fillWidth: true
                                }
                            }

                            Rectangle {
                                radius: height / 2
                                color: selected ? Colors.withAlpha(Colors.primary, 0.14) : Colors.surface
                                border.color: selected ? Colors.withAlpha(Colors.primary, 0.4) : Colors.border
                                border.width: 1
                                implicitWidth: suggestionBadge.implicitWidth + 16
                                implicitHeight: 22

                                Text {
                                    id: suggestionBadge
                                    anchors.centerIn: parent
                                    text: (modelData._usage || 0) + "x"
                                    color: selected ? Colors.primary : Colors.textSecondary
                                    font.pixelSize: Colors.fontSizeXS
                                    font.weight: Font.Medium
                                }
                            }
                        }

                        SharedWidgets.StateLayer {
                            id: suggestionStateLayer
                            hovered: suggestionHover.containsMouse
                            pressed: suggestionHover.pressed
                        }

                        MouseArea {
                            id: suggestionHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                suggestionStateLayer.burst(mouse.x, mouse.y);
                                root.launcher.activateHomeItem(modelData);
                            }
                        }
                    }
                }
            }
        }
    }
}
