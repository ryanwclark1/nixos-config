import QtQuick
import QtQuick.Layouts
import "../../../../services"
import ".." as Components

ColumnLayout {
    id: root

    required property bool compactMode
    required property int launcherWideFieldMinimumWidth
    required property var defaultModeOptionsFn

    spacing: Appearance.spacingL

    Components.SettingsCard {
        Layout.fillWidth: true
        title: "Launcher Behavior"
        iconName: "search-visual.svg"
        description: "Choose the default launcher behavior and opening mode."

        Components.SettingsInfoCallout {
            iconName: "globe-search.svg"
            title: "Dedicated launcher settings"
            body: "Launcher controls now live under their own settings section so search, modes, home layout, and diagnostics are easier to tune without digging through Shell settings."
        }

        Components.SettingsModeRow {
            label: "Default Mode"
            icon: "info.svg"
            currentValue: Config.launcherDefaultMode
            options: root.defaultModeOptionsFn()
            onModeSelected: modeValue => Config.launcherDefaultMode = modeValue
        }

        Components.SettingsFieldGrid {
            maximumColumns: root.compactMode ? 1 : 2
            minimumColumnWidth: root.launcherWideFieldMinimumWidth

            Components.SettingsToggleRow {
                label: "Show Mode Hints"
                icon: "keyboard.svg"
                configKey: "launcherShowModeHints"
            }

            Components.SettingsToggleRow {
                label: "Keep Query on Mode Switch"
                icon: "timer.svg"
                configKey: "launcherKeepSearchOnModeSwitch"
            }

            Components.SettingsToggleRow {
                label: "Paste Characters on Select"
                icon: "paste.svg"
                configKey: "launcherCharacterPasteOnSelect"
            }

            Components.SettingsModeRow {
                label: "Tab Behavior"
                icon: "keyboard.svg"
                currentValue: Config.launcherTabBehavior
                options: [
                    {
                        value: "contextual",
                        label: "Contextual",
                        icon: "eye.svg"
                    },
                    {
                        value: "results",
                        label: "Results Only",
                        icon: "search-visual.svg"
                    },
                    {
                        value: "mode",
                        label: "Mode Switch",
                        icon: "keyboard.svg"
                    }
                ]
                onModeSelected: modeValue => Config.launcherTabBehavior = modeValue
            }

            Components.SettingsTextInputRow {
                label: "Character Trigger"
                leadingIcon: "add.svg"
                placeholderText: ":"
                text: Config.launcherCharacterTrigger
                onSubmitted: value => Config.launcherCharacterTrigger = value.trim() === "" ? ":" : value.trim()
                onTextEdited: value => Config.launcherCharacterTrigger = value.trim() === "" ? ":" : value.trim()
            }
        }
    }

    Components.SettingsCard {
        Layout.fillWidth: true
        title: "Home Layout"
        iconName: "terminal.svg"
        description: "Control what the launcher home view shows before a search is entered."

        Components.SettingsFieldGrid {
            maximumColumns: root.compactMode ? 1 : 2
            minimumColumnWidth: root.launcherWideFieldMinimumWidth

            Components.SettingsToggleRow {
                label: "Show Home Sections"
                icon: "terminal.svg"
                configKey: "launcherShowHomeSections"
            }

            Components.SettingsToggleRow {
                label: "App Category Filters"
                icon: "info.svg"
                configKey: "launcherDrunCategoryFiltersEnabled"
            }
        }

        Components.SettingsSliderRow {
            label: "Recents History Limit"
            icon: "arrow-counterclockwise.svg"
            min: 4
            max: 40
            step: 1
            value: Config.launcherRecentsLimit
            unit: ""
            onMoved: v => Config.launcherRecentsLimit = v
        }

        Components.SettingsSliderRow {
            label: "Recent Apps on Home"
            icon: "arrow-counterclockwise.svg"
            min: 1
            max: 20
            step: 1
            value: Config.launcherRecentAppsLimit
            unit: ""
            onMoved: v => Config.launcherRecentAppsLimit = v
        }

        Components.SettingsSliderRow {
            label: "Suggestions on Home"
            icon: "copy.svg"
            min: 0
            max: 12
            step: 1
            value: Config.launcherSuggestionsLimit
            unit: ""
            onMoved: v => Config.launcherSuggestionsLimit = v
        }
    }
}
