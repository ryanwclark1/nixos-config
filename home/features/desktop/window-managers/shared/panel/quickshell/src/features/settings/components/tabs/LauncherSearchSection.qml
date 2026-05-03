import QtQuick
import QtQuick.Layouts
import "../../../../services"
import ".."

ColumnLayout {
    id: root

    required property bool compactMode
    required property bool launcherFilePreviewToggleAvailable
    required property int launcherWideFieldMinimumWidth

    spacing: Appearance.spacingL

    SettingsCard {
        Layout.fillWidth: true
        title: "Search Limits"
        iconName: "clock.svg"
        description: "Tune search breadth, file query thresholds, and response timing."

        SettingsSliderRow {
            label: "Max Results"
            icon: "clock.svg"
            min: 20
            max: 200
            step: 5
            value: Config.launcherMaxResults
            onMoved: v => Config.launcherMaxResults = v
        }

        SettingsSliderRow {
            label: "File Query Min Length"
            icon: "document.svg"
            min: 1
            max: 6
            value: Config.launcherFileMinQueryLength
            onMoved: v => Config.launcherFileMinQueryLength = v
        }

        SettingsSliderRow {
            label: "File Search Max Results"
            icon: "document.svg"
            min: 20
            max: 300
            step: 10
            value: Config.launcherFileMaxResults
            onMoved: v => Config.launcherFileMaxResults = v
        }

        SettingsDirectoryPickerRow {
            label: "Default Search Directory"
            callerId: "launcher-search-folder"
            leadingIcon: "folder.svg"
            placeholderText: "Home (~)"
            text: Config.launcherFileSearchRoot
            onSubmitted: value => Config.launcherFileSearchRoot = value.trim() === "" ? "~" : value.trim()
            onTextEdited: value => Config.launcherFileSearchRoot = value.trim() === "" ? "~" : value.trim()
        }

        SettingsToggleRow {
            label: "Show Hidden Files"
            icon: "sort.svg"
            configKey: "launcherFileShowHidden"
            enabledText: "Include dotfiles and hidden directories in file mode."
            disabledText: "Hide dotfiles and hidden directories in file mode."
        }

        SettingsInfoCallout {
            visible: !root.launcherFilePreviewToggleAvailable
            iconName: "info.svg"
            title: "File Preview Temporarily Disabled"
            body: "The file preview pane is gated off by default while a QuickShell restart issue in files mode is being root-caused. Set QS_ENABLE_UNSTABLE_LAUNCHER_FILE_PREVIEW=1 only for debugging."
        }

        SettingsToggleRow {
            visible: root.launcherFilePreviewToggleAvailable
            label: "File Preview Pane"
            icon: "image.svg"
            configKey: "launcherFilePreviewEnabled"
            enabledText: "Show a content preview beside file search results (Alt+P)."
            disabledText: "Hide the file preview pane."
        }

        SettingsTextInputRow {
            label: "File Opener"
            leadingIcon: "document.svg"
            placeholderText: "xdg-open"
            text: Config.launcherFileOpener
            onSubmitted: value => Config.launcherFileOpener = value.trim() === "" ? "xdg-open" : value.trim()
            onTextEdited: value => Config.launcherFileOpener = value.trim() === "" ? "xdg-open" : value.trim()
        }

        SettingsSliderRow {
            label: "Cache TTL"
            icon: "timer.svg"
            min: 30
            max: 1800
            step: 30
            value: Config.launcherCacheTtlSec
            unit: "s"
            onMoved: v => Config.launcherCacheTtlSec = v
        }

        SettingsSliderRow {
            label: "Search Debounce"
            icon: "clock.svg"
            min: 0
            max: 250
            step: 5
            value: Config.launcherSearchDebounceMs
            unit: "ms"
            onMoved: v => Config.launcherSearchDebounceMs = v
        }

        SettingsSliderRow {
            label: "File Search Debounce"
            icon: "clock.svg"
            min: 50
            max: 1200
            step: 10
            value: Config.launcherFileSearchDebounceMs
            unit: "ms"
            onMoved: v => Config.launcherFileSearchDebounceMs = v
        }
    }

    SettingsCard {
        Layout.fillWidth: true
        title: "Result Scoring"
        iconName: "app-generic.svg"
        description: "Adjust how launcher results are ranked across labels, commands, and metadata."

        SettingsSectionLabel {
            text: "RESULT SCORING WEIGHTS"
        }

        SettingsSliderRow {
            label: "Name Weight"
            icon: "keyboard.svg"
            min: 0.1
            max: 2.0
            step: 0.05
            value: Config.launcherScoreNameWeight
            unit: ""
            onMoved: v => Config.launcherScoreNameWeight = v
        }

        SettingsSliderRow {
            label: "Title Weight"
            icon: "keyboard.svg"
            min: 0.1
            max: 2.0
            step: 0.05
            value: Config.launcherScoreTitleWeight
            unit: ""
            onMoved: v => Config.launcherScoreTitleWeight = v
        }

        SettingsSliderRow {
            label: "Exec/Class Weight"
            icon: "terminal.svg"
            min: 0.1
            max: 2.0
            step: 0.05
            value: Config.launcherScoreExecWeight
            unit: ""
            onMoved: v => Config.launcherScoreExecWeight = v
        }

        SettingsSliderRow {
            label: "Body Weight"
            icon: "document.svg"
            min: 0.1
            max: 2.0
            step: 0.05
            value: Config.launcherScoreBodyWeight
            unit: ""
            onMoved: v => Config.launcherScoreBodyWeight = v
        }

        SettingsSliderRow {
            label: "Category/Keywords Weight"
            icon: "apps.svg"
            min: 0.1
            max: 2.0
            step: 0.05
            value: Config.launcherScoreCategoryWeight
            unit: ""
            onMoved: v => Config.launcherScoreCategoryWeight = v
        }
    }
}
