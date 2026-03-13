import QtQuick
import QtQuick.Layouts
import "../../../services"
import ".."

Item {
  id: root
  property var settingsRoot: null
  property string tabId: ""

  SettingsTabPage {
    anchors.fill: parent
    tabId: root.tabId
    title: "Shell Behavior"
    iconName: "󰒓"

    SettingsCard {
      title: "Shell"
      iconName: "󰒓"

      SettingsFieldGrid {
        SettingsToggleRow { label: "Floating Bar"; icon: "󰖲"; configKey: "barFloating" }
        SettingsToggleRow { label: "Blur Effects"; icon: "󰃠"; configKey: "blurEnabled" }
      }

      SettingsSliderRow {
        label: "Notification Width"
        min: 280; max: 520
        value: Config.notifWidth
        onMoved: (v) => Config.notifWidth = v
      }

      SettingsSliderRow {
        label: "Popup Duration"
        min: 2000; max: 10000; step: 500
        value: Config.popupTimer
        unit: "ms"
        onMoved: (v) => Config.popupTimer = v
      }
    }

    SettingsCard {
      title: "Launcher"
      iconName: "󰍉"

      SettingsModeRow {
        label: "Default Mode"
        currentValue: Config.launcherDefaultMode
        options: [
          { value: "drun", label: "Apps" },
          { value: "window", label: "Windows" },
          { value: "files", label: "Files" },
          { value: "ai", label: "AI" },
          { value: "clip", label: "Clipboard" },
          { value: "system", label: "System" },
          { value: "media", label: "Media" }
        ]
        onModeSelected: (modeValue) => Config.launcherDefaultMode = modeValue
      }

      SettingsFieldGrid {
        SettingsToggleRow { label: "Show Mode Hints"; icon: "󰌌"; configKey: "launcherShowModeHints" }
        SettingsToggleRow { label: "Show Home Sections"; icon: "󰆍"; configKey: "launcherShowHomeSections" }
      }
    }

    SettingsCard {
      title: "Control Center"
      iconName: "󰖲"

      SettingsFieldGrid {
        SettingsToggleRow { label: "Quick Links"; icon: "󰖩"; configKey: "controlCenterShowQuickLinks" }
        SettingsToggleRow { label: "Media Widget"; icon: "󰝚"; configKey: "controlCenterShowMediaWidget" }
      }

      SettingsSliderRow {
        label: "Control Center Width"
        min: 320; max: 460
        value: Config.controlCenterWidth
        onMoved: (v) => Config.controlCenterWidth = v
      }
    }
  }
}
