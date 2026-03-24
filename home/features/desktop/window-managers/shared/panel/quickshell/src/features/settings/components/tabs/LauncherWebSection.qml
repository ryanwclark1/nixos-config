import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../../services"
import "../../../../widgets" as SharedWidgets
import ".."

ColumnLayout {
    id: root

    required property bool compactMode
    required property var webProviders
    required property var orderedWebProvidersFn
    required property var toggleWebProviderFn
    required property var webProviderReorderState
    required property string dragWebProviderKey
    required property int dragWebProviderTargetIndex
    required property var beginWebProviderDragFn
    required property var moveDraggedWebProviderFn
    required property var clearWebProviderDragStateFn
    required property var currentWebProviderDropIndexFn
    required property var moveWebProviderFn
    required property var webProviderMetaFn
    required property var webAliasStringFn
    required property var setWebAliasStringFn
    required property string newEngineKey
    required property string newEngineName
    required property string newEngineUrl
    required property string newEngineIcon
    required property var setNewEngineKeyFn
    required property var setNewEngineNameFn
    required property var setNewEngineUrlFn
    required property var setNewEngineIconFn

    spacing: Appearance.spacingL

    SettingsCard {
        Layout.fillWidth: true
        title: "Web Search Behavior"
        iconName: "globe-search.svg"
        description: "Web-mode defaults and keyboard behavior."

        SettingsFieldGrid {
            maximumColumns: root.compactMode ? 1 : 2
            minimumColumnWidth: 280

            SettingsToggleRow {
                label: "Web Enter Uses Primary"
                icon: "globe-search.svg"
                configKey: "launcherWebEnterUsesPrimary"
            }

            SettingsToggleRow {
                label: "Web Number Hotkeys"
                icon: "keyboard.svg"
                configKey: "launcherWebNumberHotkeysEnabled"
            }

            SettingsToggleRow {
                label: "Remember Web Provider"
                icon: "globe-search.svg"
                configKey: "launcherRememberWebProvider"
            }
        }
    }

    SettingsCard {
        Layout.fillWidth: true
        title: "Web Providers"
        iconName: "globe-search.svg"
        description: "Enable providers and control the order shown in web mode."

        SettingsSectionLabel {
            text: "WEB PROVIDERS"
        }

        Flow {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            Repeater {
                model: root.webProviders

                delegate: SharedWidgets.FilterChip {
                    required property var modelData
                    label: modelData.label
                    icon: modelData.icon
                    selected: root.orderedWebProvidersFn().indexOf(modelData.key) !== -1
                    onClicked: root.toggleWebProviderFn(modelData.key)
                }
            }
        }

        Column {
            id: webProviderOrderList
            Layout.fillWidth: true
            spacing: Appearance.spacingXS

            Repeater {
                model: root.orderedWebProvidersFn()

                delegate: SettingsReorderRow {
                    id: webProviderRow
                    required property int index
                    required property var modelData
                    reorderState: root.webProviderReorderState
                    listId: "launcher-web-provider"
                    itemId: String(webProviderRow.modelData || "")
                    rowIndex: webProviderRow.index
                    itemCount: root.orderedWebProvidersFn().length
                    listItem: webProviderOrderList
                    compactMode: root.compactMode
                    active: webProviderRow.dragging
                    minimumHeight: root.compactMode ? 76 : 44
                    beginDragFn: function(listId, itemId, index) {
                        root.beginWebProviderDragFn(itemId, index);
                    }
                    moveDraggedFn: function(listId, targetIndex) {
                        return root.moveDraggedWebProviderFn(targetIndex);
                    }
                    clearDragStateFn: root.clearWebProviderDragStateFn
                    dropIndexFn: root.currentWebProviderDropIndexFn

                    Rectangle {
                        Layout.alignment: root.compactMode ? Qt.AlignTop : Qt.AlignVCenter
                        border.color: Colors.border
                        border.width: 1
                        color: Colors.surface
                        implicitHeight: 24
                        implicitWidth: 24
                        radius: Appearance.radiusCard

                        SettingsMetricIcon {
                            anchors.centerIn: parent
                            iconColor: Colors.primary
                            iconSize: Appearance.fontSizeSmall
                            icon: {
                                for (var i = 0; i < root.webProviders.length; ++i) {
                                    if (root.webProviders[i].key === webProviderRow.modelData)
                                        return root.webProviders[i].icon;
                                }
                                return "globe-search.svg";
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Appearance.spacingXS

                        Text {
                            Layout.fillWidth: true
                            color: Colors.text
                            font.pixelSize: Appearance.fontSizeSmall
                            font.weight: Font.DemiBold
                            wrapMode: root.compactMode ? Text.WordWrap : Text.NoWrap
                            elide: root.compactMode ? Text.ElideNone : Text.ElideRight
                            text: {
                                for (var i = 0; i < root.webProviders.length; ++i) {
                                    if (root.webProviders[i].key === webProviderRow.modelData)
                                        return root.webProviders[i].label;
                                }
                                return webProviderRow.modelData;
                            }
                        }

                        Text {
                            text: "Drag to reorder, or use the arrow buttons."
                            color: Colors.textSecondary
                            font.pixelSize: Appearance.fontSizeXS
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }

                        Flow {
                            Layout.fillWidth: true
                            Layout.preferredWidth: parent.width
                            spacing: Appearance.spacingS

                            SettingsReorderButtons {
                                moveUpEnabled: webProviderRow.index > 0
                                moveDownEnabled: webProviderRow.index < (root.orderedWebProvidersFn().length - 1)
                                onMoveUp: root.moveWebProviderFn(webProviderRow.modelData, -1)
                                onMoveDown: root.moveWebProviderFn(webProviderRow.modelData, 1)
                            }
                        }
                    }
                }
            }

            SettingsDropIndicator {
                width: parent ? parent.width : 0
                active: root.dragWebProviderKey !== "" && root.dragWebProviderTargetIndex === root.orderedWebProvidersFn().length
                visible: active
                label: "Drop at end of provider order"
            }
        }
    }

    SettingsCard {
        Layout.fillWidth: true
        title: "Web Aliases"
        iconName: "globe-search.svg"
        description: "Customize short prefixes for each provider."

        SettingsSectionLabel {
            text: "WEB ALIASES"
        }

        SettingsInfoCallout {
            iconName: "globe-search.svg"
            title: "Alias format"
            body: "Enter aliases separated by commas. Example: g, gg"
        }

        Repeater {
            model: root.orderedWebProvidersFn()

            delegate: SettingsTextInputRow {
                id: aliasRow
                required property var modelData
                property bool syncingText: false
                label: root.webProviderMetaFn(modelData).label + " Aliases"
                leadingIcon: root.webProviderMetaFn(modelData).icon
                placeholderText: "comma-separated aliases"

                function syncFromConfig() {
                    var next = root.webAliasStringFn(modelData);
                    if (text === next)
                        return;
                    syncingText = true;
                    text = next;
                    syncingText = false;
                }

                Component.onCompleted: syncFromConfig()
                onSubmitted: value => root.setWebAliasStringFn(modelData, value)
                onTextEdited: value => {
                    if (!syncingText)
                        root.setWebAliasStringFn(modelData, value);
                }

                Connections {
                    target: Config

                    function onLauncherWebAliasesChanged() {
                        if (!aliasRow.inputActiveFocus)
                            aliasRow.syncFromConfig();
                    }
                }
            }
        }
    }

    SettingsCard {
        Layout.fillWidth: true
        title: "Custom Search Engines"
        iconName: "globe-search.svg"
        description: "Add your own search engines with URL templates. Use %s as the query placeholder."

        SettingsSectionLabel {
            text: "CUSTOM ENGINES"
        }

        Repeater {
            model: Array.isArray(Config.launcherWebCustomEngines) ? Config.launcherWebCustomEngines : []

            delegate: RowLayout {
                id: customEngineRow
                Layout.fillWidth: true
                required property int index
                required property var modelData
                spacing: Appearance.spacingS

                Rectangle {
                    implicitWidth: 24
                    implicitHeight: 24
                    radius: Appearance.radiusCard
                    color: Colors.surface
                    border.color: Colors.border
                    border.width: 1

                    SettingsMetricIcon {
                        anchors.centerIn: parent
                        iconColor: Colors.primary
                        iconSize: Appearance.fontSizeSmall
                        icon: customEngineRow.modelData.icon || "globe-search.svg"
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacingXXS

                    Text {
                        text: customEngineRow.modelData.name + " (" + customEngineRow.modelData.key + ")"
                        color: Colors.text
                        font.pixelSize: Appearance.fontSizeSmall
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: customEngineRow.modelData.exec
                        color: Colors.textSecondary
                        font.pixelSize: Appearance.fontSizeXS
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                SettingsActionButton {
                    compact: true
                    iconName: "delete.svg"
                    onClicked: {
                        var engines = Config.launcherWebCustomEngines.slice();
                        engines.splice(customEngineRow.index, 1);
                        Config.launcherWebCustomEngines = engines;
                    }
                }
            }
        }

        SettingsInfoCallout {
            visible: !Array.isArray(Config.launcherWebCustomEngines) || Config.launcherWebCustomEngines.length === 0
            iconName: "globe-search.svg"
            title: "No custom engines"
            body: "Add a custom search engine below. It will appear in the web provider list."
        }

        SettingsSectionLabel {
            text: "ADD NEW ENGINE"
        }

        SettingsTextInputRow {
            label: "Key (short ID)"
            placeholderText: "e.g. rustdoc"
            text: root.newEngineKey
            onSubmitted: value => root.setNewEngineKeyFn(value)
            onTextEdited: value => root.setNewEngineKeyFn(value)
        }

        SettingsTextInputRow {
            label: "Name"
            placeholderText: "e.g. Rust Docs"
            text: root.newEngineName
            onSubmitted: value => root.setNewEngineNameFn(value)
            onTextEdited: value => root.setNewEngineNameFn(value)
        }

        SettingsTextInputRow {
            label: "URL Template"
            placeholderText: "https://example.com/search?q=%s"
            text: root.newEngineUrl
            onSubmitted: value => root.setNewEngineUrlFn(value)
            onTextEdited: value => root.setNewEngineUrlFn(value)
        }

        SettingsTextInputRow {
            label: "Icon (optional)"
            placeholderText: "Nerd Font icon"
            text: root.newEngineIcon
            onSubmitted: value => root.setNewEngineIconFn(value)
            onTextEdited: value => root.setNewEngineIconFn(value)
        }

        SettingsActionButton {
            Layout.fillWidth: true
            label: "Add Custom Engine"
            iconName: "add.svg"
            enabled: root.newEngineKey.trim() !== "" && root.newEngineName.trim() !== "" && root.newEngineUrl.trim() !== ""
            onClicked: {
                var engines = Array.isArray(Config.launcherWebCustomEngines) ? Config.launcherWebCustomEngines.slice() : [];
                var key = root.newEngineKey.trim().toLowerCase().replace(/[^a-z0-9-]/g, "");
                if (key === "")
                    return;
                engines.push({
                    key: key,
                    name: root.newEngineName.trim(),
                    exec: root.newEngineUrl.trim(),
                    home: "",
                    icon: root.newEngineIcon.trim() || "globe-search.svg"
                });
                Config.launcherWebCustomEngines = engines;
                root.setNewEngineKeyFn("");
                root.setNewEngineNameFn("");
                root.setNewEngineUrlFn("");
                root.setNewEngineIconFn("");
            }
        }
    }

    SettingsCard {
        Layout.fillWidth: true
        title: "DuckDuckGo Bangs"
        iconName: "globe-search.svg"
        description: "Use DDG !bangs for quick site searches (e.g. !gh quickshell, !w quantum)."

        SettingsToggleRow {
            label: "Enable !Bangs"
            icon: "globe-search.svg"
            configKey: "launcherWebBangsEnabled"
        }

        SettingsInfoCallout {
            iconName: "globe-search.svg"
            title: "How bangs work"
            body: "Type ?!prefix query in web mode. The bang database must be synced first using the button below."
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingS

            SettingsActionButton {
                Layout.fillWidth: true
                label: "Sync Bang Database"
                iconName: "arrow-counterclockwise.svg"
                enabled: Config.launcherWebBangsEnabled
                onClicked: {
                    Quickshell.execDetached(["qs-bang-sync"]);
                    Config.launcherWebBangsLastSync = new Date().toISOString();
                }
            }
        }

        Text {
            visible: Config.launcherWebBangsLastSync !== ""
            text: "Last synced: " + Config.launcherWebBangsLastSync
            color: Colors.textSecondary
            font.pixelSize: Appearance.fontSizeXS
            Layout.fillWidth: true
        }

        Text {
            visible: Config.launcherWebBangsLastSync === "" && Config.launcherWebBangsEnabled
            text: "Bang database not yet synced. Click 'Sync' to download."
            color: Colors.textSecondary
            font.pixelSize: Appearance.fontSizeXS
            Layout.fillWidth: true
        }
    }
}
