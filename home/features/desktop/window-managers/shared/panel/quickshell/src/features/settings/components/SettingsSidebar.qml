pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets
import "."

Rectangle {
    id: root

    property string currentTabId: SettingsRegistry.defaultTabId
    property string searchQuery: ""
    property bool compactMode: false

    signal tabSelected(string tabId)
    signal saveAndClose()
    signal searchQueryEdited(string query)
    signal settingHighlightRequested(string tabId, string cardTitle, string settingLabel)

    readonly property bool isSearching: searchQuery.length > 0
    readonly property var orderedCategories: SettingsRegistry.sortedCategories()
    readonly property var searchResults: SettingsRegistry.searchTabs(searchQuery)
    readonly property var settingResults: SettingsRegistry.searchSettings(searchQuery)
    readonly property var compactEntries: buildCompactEntries()
    readonly property var currentTabMeta: SettingsRegistry.findTab(currentTabId)
    readonly property var currentCategoryMeta: SettingsRegistry.categoryForTab(currentTabId)

    Layout.fillHeight: true
    color: "transparent"

    property var expandedCategories: ({})

    function buildCompactEntries() {
        var out = [];
        for (var i = 0; i < orderedCategories.length; i++) {
            var category = orderedCategories[i];
            out.push({
                type: "separator",
                key: "sep-" + category.id,
                icon: category.icon
            });
            var tabs = SettingsRegistry.tabsForCategory(category.id);
            for (var j = 0; j < tabs.length; j++) {
                out.push({
                    type: "tab",
                    key: tabs[j].id,
                    id: tabs[j].id,
                    icon: tabs[j].icon,
                    label: tabs[j].label
                });
            }
        }
        return out;
    }

    function initializeExpandedState() {
        var states = {};
        for (var i = 0; i < orderedCategories.length; i++) {
            var category = orderedCategories[i];
            states[category.id] = !!category.expandedByDefault;
        }
        expandedCategories = states;
        autoExpandForTab(currentTabId);
    }

    function autoExpandForTab(tabId) {
        var tab = SettingsRegistry.findTab(tabId);
        if (!tab || !tab.categoryId)
            return;
        var states = Object.assign({}, expandedCategories);
        states[tab.categoryId] = true;
        expandedCategories = states;
    }

    function toggleCategory(categoryId) {
        var states = Object.assign({}, expandedCategories);
        states[categoryId] = !states[categoryId];
        expandedCategories = states;
    }

    function selectTab(tabId) {
        autoExpandForTab(tabId);
        tabSelected(tabId);
    }

    function categoryDescription(category) {
        return category && category.description ? String(category.description) : "";
    }

    function tabSearchSubtitle(tab) {
        if (!tab)
            return "";
        var category = SettingsRegistry.findCategory(tab.categoryId);
        var parts = [];
        if (category && category.label)
            parts.push(String(category.label));
        if (tab.description)
            parts.push(String(tab.description));
        return parts.join(" • ");
    }

    Component.onCompleted: initializeExpandedState()
    onCurrentTabIdChanged: autoExpandForTab(currentTabId)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.compactMode ? Colors.spacingS : Colors.spacingL
        spacing: Colors.spacingS

        Rectangle {
            visible: !root.compactMode
            Layout.fillWidth: true
            radius: Colors.radiusLarge
            color: Colors.withAlpha(Colors.surface, 0.44)
            border.color: Colors.withAlpha(Colors.primary, 0.16)
            border.width: 1
            implicitHeight: navHeaderColumn.implicitHeight + Colors.spacingM * 2

            SharedWidgets.InnerHighlight { highlightOpacity: 0.1 }

            ColumnLayout {
                id: navHeaderColumn
                anchors.fill: parent
                anchors.margins: Colors.spacingM
                spacing: Colors.spacingXS

                Text {
                    text: "SETTINGS HUB"
                    color: Colors.primary
                    font.pixelSize: Colors.fontSizeXXS
                    font.weight: Font.Black
                    font.letterSpacing: Colors.letterSpacingExtraWide
                }

                Text {
                    Layout.fillWidth: true
                    text: root.currentTabMeta ? String(root.currentTabMeta.label || "Settings") : "Settings"
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeXL
                    font.weight: Font.Black
                    wrapMode: Text.WordWrap
                }

                Text {
                    Layout.fillWidth: true
                    text: root.currentCategoryMeta && root.currentCategoryMeta.description
                        ? String(root.currentCategoryMeta.description)
                        : "Search pages or drill into categories from the rail."
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeSmall
                    wrapMode: Text.WordWrap
                }
            }
        }

        Rectangle {
            visible: !root.compactMode
            Layout.fillWidth: true
            implicitHeight: searchBarColumn.implicitHeight + Colors.spacingS * 2
            radius: Colors.radiusLarge
            color: Colors.withAlpha(Colors.surface, 0.36)
            border.color: searchInput.activeFocus ? Colors.primary : Colors.withAlpha(Colors.text, 0.16)
            border.width: 1

            ColumnLayout {
                id: searchBarColumn
                anchors.fill: parent
                anchors.leftMargin: Colors.spacingM
                anchors.rightMargin: Colors.spacingM
                anchors.topMargin: Colors.spacingS
                anchors.bottomMargin: Colors.spacingS
                spacing: Colors.spacingXS

                Text {
                    text: "SEARCH"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXXS
                    font.weight: Font.Black
                    font.letterSpacing: Colors.letterSpacingExtraWide
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Colors.spacingS

                    Text {
                        text: "󰍉"
                        color: Colors.textDisabled
                        font.family: Colors.fontMono
                        font.pixelSize: Colors.fontSizeMedium
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        color: Colors.text
                        font.pixelSize: Colors.fontSizeSmall
                        clip: true
                        wrapMode: TextInput.Wrap
                        onVisibleChanged: {
                            if (!visible && activeFocus)
                                focus = false;
                        }
                        onTextChanged: {
                            if (text !== root.searchQuery)
                                root.searchQueryEdited(text);
                        }

                        Text {
                            text: "Search pages or settings"
                            color: Colors.textDisabled
                            font.pixelSize: parent.font.pixelSize
                            visible: !parent.text && !parent.activeFocus
                        }
                    }

                    Rectangle {
                        visible: searchInput.text.length > 0
                        implicitWidth: 22
                        implicitHeight: 22
                        radius: Colors.radiusPill
                        color: Colors.withAlpha(Colors.surface, clearSearchMouse.containsMouse ? 0.65 : 0.45)
                        border.color: Colors.border
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "󰅖"
                            color: Colors.textDisabled
                            font.family: Colors.fontMono
                            font.pixelSize: Colors.fontSizeXS
                        }

                        MouseArea {
                            id: clearSearchMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.searchQueryEdited("")
                        }
                    }
                }
            }
        }

        Item {
            visible: !root.compactMode
            height: 2
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Flickable {
                id: sidebarFlick
                anchors.fill: parent
                contentHeight: root.compactMode ? compactColumn.implicitHeight : sidebarColumn.implicitHeight
                clip: true
                boundsBehavior: Flickable.DragOverBounds

                ColumnLayout {
                    id: compactColumn
                    visible: root.compactMode
                    width: parent.width
                    spacing: Colors.spacingS

                    Repeater {
                        model: root.compactEntries

                        delegate: Item {
                            required property var modelData
                            width: parent.width
                            height: modelData.type === "separator" ? 22 : 48

                            Rectangle {
                                anchors.centerIn: parent
                                visible: modelData.type === "tab"
                                width: 42
                                height: 42
                                radius: Colors.radiusLarge
                                color: root.currentTabId === modelData.id ? Colors.primarySubtle : Colors.withAlpha(Colors.surface, compactTabMouse.containsMouse ? 0.45 : 0.28)
                                border.color: root.currentTabId === modelData.id ? Colors.primaryRing : Colors.withAlpha(Colors.text, 0.1)
                                border.width: 1

                                Rectangle {
                                    visible: root.currentTabId === modelData.id
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: 3
                                    color: Colors.primary
                                }

                                SharedWidgets.StateLayer {
                                    id: compactTabState
                                    anchors.fill: parent
                                    hovered: compactTabMouse.containsMouse
                                    pressed: compactTabMouse.pressed
                                    visible: modelData.type === "tab" && root.currentTabId !== modelData.id
                                    stateColor: Colors.primary
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: root.currentTabId === modelData.id ? Colors.primary : Colors.textSecondary
                                    font.family: Colors.fontMono
                                    font.pixelSize: Colors.fontSizeLarge
                                }

                                MouseArea {
                                    id: compactTabMouse
                                    anchors.fill: parent
                                    enabled: modelData.type === "tab"
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: (mouse) => {
                                        compactTabState.burst(mouse.x, mouse.y);
                                        root.selectTab(modelData.id);
                                    }
                                }
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: Colors.spacingXXS
                                visible: modelData.type === "separator"

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.icon
                                    color: Colors.withAlpha(Colors.textDisabled, 0.85)
                                    font.family: Colors.fontMono
                                    font.pixelSize: Colors.fontSizeSmall
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 24
                                    height: 1
                                    color: Colors.withAlpha(Colors.border, 0.7)
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    id: sidebarColumn
                    visible: !root.compactMode
                    width: parent.width
                    spacing: Colors.spacingS

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Colors.spacingXS
                        visible: root.isSearching

                        Text {
                            visible: root.searchResults.length > 0
                            text: "PAGES"
                            color: Colors.textDisabled
                            font.pixelSize: Colors.fontSizeXXS
                            font.weight: Font.Black
                            font.letterSpacing: Colors.letterSpacingExtraWide
                            Layout.leftMargin: Colors.spacingXS
                        }

                        Repeater {
                            model: root.isSearching ? root.searchResults : []

                            delegate: Rectangle {
                                required property var modelData

                                Layout.fillWidth: true
                                implicitHeight: resultColumn.implicitHeight + Colors.spacingS * 2
                                radius: Colors.radiusLarge
                                color: root.currentTabId === modelData.id ? Colors.primarySubtle : Colors.withAlpha(Colors.surface, resultMouse.containsMouse ? 0.48 : 0.3)
                                border.color: root.currentTabId === modelData.id ? Colors.primaryRing : Colors.withAlpha(Colors.text, 0.08)
                                border.width: 1

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: 3
                                    color: root.currentTabId === modelData.id ? Colors.primary : "transparent"
                                }

                                SharedWidgets.StateLayer {
                                    id: resultState
                                    anchors.fill: parent
                                    hovered: resultMouse.containsMouse
                                    pressed: resultMouse.pressed
                                    visible: root.currentTabId !== modelData.id
                                    stateColor: Colors.primary
                                }

                                ColumnLayout {
                                    id: resultColumn
                                    anchors.fill: parent
                                    anchors.leftMargin: Colors.spacingL
                                    anchors.rightMargin: Colors.spacingM
                                    anchors.topMargin: Colors.spacingS
                                    anchors.bottomMargin: Colors.spacingS
                                    spacing: Colors.spacingXXS

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Colors.spacingM

                                        Text {
                                            text: modelData.icon
                                            color: root.currentTabId === modelData.id ? Colors.primary : Colors.textDisabled
                                            font.family: Colors.fontMono
                                            font.pixelSize: Colors.fontSizeMedium
                                        }

                                        Text {
                                            text: modelData.label
                                            color: root.currentTabId === modelData.id ? Colors.text : Colors.textSecondary
                                            font.pixelSize: Colors.fontSizeSmall
                                            font.weight: root.currentTabId === modelData.id ? Font.Bold : Font.DemiBold
                                            Layout.fillWidth: true
                                            wrapMode: Text.WordWrap
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: root.tabSearchSubtitle(modelData)
                                        color: Colors.textDisabled
                                        font.pixelSize: Colors.fontSizeXS
                                        wrapMode: Text.WordWrap
                                        visible: !!text
                                    }
                                }

                                MouseArea {
                                    id: resultMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: (mouse) => {
                                        resultState.burst(mouse.x, mouse.y);
                                        root.selectTab(modelData.id);
                                    }
                                }
                            }
                        }

                        Text {
                            visible: root.settingResults.length > 0
                            text: "SETTINGS"
                            color: Colors.textDisabled
                            font.pixelSize: Colors.fontSizeXXS
                            font.weight: Font.Black
                            font.letterSpacing: Colors.letterSpacingExtraWide
                            Layout.topMargin: Colors.spacingS
                            Layout.leftMargin: Colors.spacingXS
                        }

                        Repeater {
                            model: root.isSearching ? root.settingResults : []

                            delegate: Rectangle {
                                required property var modelData

                                Layout.fillWidth: true
                                implicitHeight: settingResultCol.implicitHeight + Colors.spacingS * 2
                                radius: Colors.radiusLarge
                                color: Colors.withAlpha(Colors.surface, settingResultMouse.containsMouse ? 0.48 : 0.28)
                                border.color: Colors.withAlpha(Colors.text, 0.08)
                                border.width: 1

                                SharedWidgets.StateLayer {
                                    id: settingResultState
                                    anchors.fill: parent
                                    hovered: settingResultMouse.containsMouse
                                    pressed: settingResultMouse.pressed
                                    stateColor: Colors.primary
                                }

                                ColumnLayout {
                                    id: settingResultCol
                                    anchors.fill: parent
                                    anchors.leftMargin: Colors.spacingL
                                    anchors.rightMargin: Colors.spacingM
                                    anchors.topMargin: Colors.spacingS
                                    anchors.bottomMargin: Colors.spacingS
                                    spacing: Colors.spacingXXS

                                    Text {
                                        text: modelData.label
                                        color: Colors.text
                                        font.pixelSize: Colors.fontSizeSmall
                                        font.weight: Font.DemiBold
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                    }

                                    Text {
                                        text: {
                                            var tab = SettingsRegistry.findTab(modelData.tabId);
                                            var tabLabel = tab ? tab.label : modelData.tabId;
                                            return tabLabel + " > " + modelData.cardTitle;
                                        }
                                        color: Colors.textDisabled
                                        font.pixelSize: Colors.fontSizeXS
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                MouseArea {
                                    id: settingResultMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: (mouse) => {
                                        settingResultState.burst(mouse.x, mouse.y);
                                        root.settingHighlightRequested(modelData.tabId, modelData.cardTitle, modelData.label);
                                    }
                                }
                            }
                        }

                        Rectangle {
                            visible: root.searchResults.length === 0 && root.settingResults.length === 0
                            Layout.fillWidth: true
                            radius: Colors.radiusLarge
                            color: Colors.withAlpha(Colors.surface, 0.3)
                            border.color: Colors.withAlpha(Colors.text, 0.08)
                            border.width: 1
                            implicitHeight: emptyColumn.implicitHeight + Colors.spacingM * 2

                            ColumnLayout {
                                id: emptyColumn
                                anchors.fill: parent
                                anchors.margins: Colors.spacingM
                                spacing: Colors.spacingXS

                                Text {
                                    text: "No matches"
                                    color: Colors.text
                                    font.pixelSize: Colors.fontSizeMedium
                                    font.weight: Font.Bold
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "Try a tab name, category, or the label of a setting."
                                    color: Colors.textSecondary
                                    font.pixelSize: Colors.fontSizeSmall
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }

                    Repeater {
                        model: root.isSearching ? [] : root.orderedCategories

                        delegate: ColumnLayout {
                            required property var modelData

                            readonly property var categoryTabs: SettingsRegistry.tabsForCategory(modelData.id)
                            readonly property bool expanded: !!root.expandedCategories[modelData.id]

                            Layout.fillWidth: true
                            spacing: Colors.spacingXS

                            Rectangle {
                                Layout.fillWidth: true
                                radius: Colors.radiusLarge
                                color: expanded ? Colors.withAlpha(Colors.primary, 0.08) : Colors.withAlpha(Colors.surface, 0.22)
                                border.color: expanded ? Colors.withAlpha(Colors.primary, 0.18) : Colors.withAlpha(Colors.text, 0.08)
                                border.width: 1
                                implicitHeight: categoryColumn.implicitHeight + Colors.spacingS * 2

                                SharedWidgets.StateLayer {
                                    id: categoryState
                                    anchors.fill: parent
                                    hovered: categoryMouse.containsMouse
                                    pressed: categoryMouse.pressed
                                    stateColor: Colors.primary
                                }

                                ColumnLayout {
                                    id: categoryColumn
                                    anchors.fill: parent
                                    anchors.leftMargin: Colors.spacingM
                                    anchors.rightMargin: Colors.spacingM
                                    anchors.topMargin: Colors.spacingS
                                    anchors.bottomMargin: Colors.spacingS
                                    spacing: Colors.spacingXXS

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Colors.spacingS

                                        Text {
                                            text: expanded ? "󰅀" : "󰅂"
                                            color: Colors.textDisabled
                                            font.family: Colors.fontMono
                                            font.pixelSize: Colors.fontSizeSmall
                                        }

                                        Text {
                                            text: modelData.icon
                                            color: expanded ? Colors.primary : Colors.textSecondary
                                            font.family: Colors.fontMono
                                            font.pixelSize: Colors.fontSizeMedium
                                        }

                                        Text {
                                            text: modelData.label
                                            color: Colors.text
                                            font.pixelSize: Colors.fontSizeSmall
                                            font.weight: Font.Black
                                            Layout.fillWidth: true
                                            wrapMode: Text.WordWrap
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: root.categoryDescription(modelData)
                                        color: Colors.textDisabled
                                        font.pixelSize: Colors.fontSizeXS
                                        wrapMode: Text.WordWrap
                                        visible: !!text
                                    }
                                }

                                MouseArea {
                                    id: categoryMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: (mouse) => {
                                        categoryState.burst(mouse.x, mouse.y);
                                        root.toggleCategory(modelData.id);
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                visible: expanded
                                radius: Colors.radiusLarge
                                color: Colors.withAlpha(Colors.surface, 0.24)
                                border.color: Colors.withAlpha(Colors.text, 0.08)
                                border.width: 1
                                implicitHeight: categoryTabsColumn.implicitHeight + Colors.spacingS * 2

                                ColumnLayout {
                                    id: categoryTabsColumn
                                    anchors.fill: parent
                                    anchors.leftMargin: Colors.spacingS
                                    anchors.rightMargin: Colors.spacingS
                                    anchors.topMargin: Colors.spacingS
                                    anchors.bottomMargin: Colors.spacingS
                                    spacing: Colors.spacingXXS

                                    Repeater {
                                        model: expanded ? categoryTabs : []

                                        delegate: Rectangle {
                                            required property var modelData

                                            Layout.fillWidth: true
                                            implicitHeight: tabRow.implicitHeight + Colors.spacingS * 2
                                            radius: Colors.radiusMedium
                                            color: root.currentTabId === modelData.id ? Colors.primarySubtle : Colors.withAlpha(Colors.surface, tabMouse.containsMouse ? 0.45 : 0.18)
                                            border.color: root.currentTabId === modelData.id ? Colors.primaryRing : "transparent"
                                            border.width: 1

                                            Rectangle {
                                                anchors.left: parent.left
                                                anchors.top: parent.top
                                                anchors.bottom: parent.bottom
                                                width: 3
                                                color: root.currentTabId === modelData.id ? Colors.primary : "transparent"
                                            }

                                            SharedWidgets.StateLayer {
                                                id: tabState
                                                anchors.fill: parent
                                                hovered: tabMouse.containsMouse
                                                pressed: tabMouse.pressed
                                                visible: root.currentTabId !== modelData.id
                                                stateColor: Colors.primary
                                            }

                                            RowLayout {
                                                id: tabRow
                                                anchors.fill: parent
                                                anchors.leftMargin: Colors.spacingL
                                                anchors.rightMargin: Colors.spacingM
                                                anchors.topMargin: Colors.spacingS
                                                anchors.bottomMargin: Colors.spacingS
                                                spacing: Colors.spacingM

                                                Text {
                                                    text: modelData.icon
                                                    color: root.currentTabId === modelData.id ? Colors.primary : Colors.textDisabled
                                                    font.family: Colors.fontMono
                                                    font.pixelSize: Colors.fontSizeMedium
                                                }

                                                Text {
                                                    text: modelData.label
                                                    color: root.currentTabId === modelData.id ? Colors.text : Colors.textSecondary
                                                    font.pixelSize: Colors.fontSizeSmall
                                                    font.weight: root.currentTabId === modelData.id ? Font.Bold : Font.DemiBold
                                                    Layout.fillWidth: true
                                                    wrapMode: Text.WordWrap
                                                }
                                            }

                                            MouseArea {
                                                id: tabMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: (mouse) => {
                                                    tabState.burst(mouse.x, mouse.y);
                                                    root.selectTab(modelData.id);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            SharedWidgets.Scrollbar { flickable: sidebarFlick }
            SharedWidgets.OverscrollGlow { flickable: sidebarFlick }
        }

        Rectangle {
            Layout.fillWidth: true
            radius: root.compactMode ? Colors.radiusLarge : Colors.radiusXL
            color: Colors.withAlpha(Colors.surface, 0.44)
            border.color: Colors.withAlpha(Colors.primary, 0.18)
            border.width: 1
            implicitHeight: footerColumn.implicitHeight + Colors.spacingS * 2

            ColumnLayout {
                id: footerColumn
                anchors.fill: parent
                anchors.leftMargin: Colors.spacingS
                anchors.rightMargin: Colors.spacingS
                anchors.topMargin: Colors.spacingS
                anchors.bottomMargin: Colors.spacingS
                spacing: Colors.spacingS

                Text {
                    visible: !root.compactMode
                    text: "SESSION ACTION"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXXS
                    font.weight: Font.Black
                    font.letterSpacing: Colors.letterSpacingExtraWide
                    Layout.leftMargin: Colors.spacingXS
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: saveButtonRow.implicitHeight + Colors.spacingS * 2
                    radius: root.compactMode ? Colors.radiusLarge : Colors.radiusPill
                    color: Colors.primaryAccent
                    border.color: Colors.primary
                    border.width: 1

                    SharedWidgets.StateLayer {
                        id: saveState
                        hovered: saveMouse.containsMouse
                        pressed: saveMouse.pressed
                        stateColor: Colors.primary
                    }

                    RowLayout {
                        id: saveButtonRow
                        anchors.centerIn: parent
                        spacing: Colors.spacingS

                        Text {
                            text: "󰆓"
                            color: Colors.primary
                            font.family: Colors.fontMono
                            font.pixelSize: Colors.fontSizeMedium
                        }

                        Text {
                            visible: !root.compactMode
                            text: "Save & Close"
                            color: Colors.text
                            font.pixelSize: Colors.fontSizeSmall
                            font.weight: Font.Bold
                        }
                    }

                    MouseArea {
                        id: saveMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (mouse) => {
                            saveState.burst(mouse.x, mouse.y);
                            root.saveAndClose();
                        }
                    }
                }
            }
        }
    }

    onSearchQueryChanged: {
        if (!root.compactMode && searchInput.text !== searchQuery)
            searchInput.text = searchQuery;
    }
}
