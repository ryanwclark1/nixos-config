import Quickshell
import QtQuick
import "./config/services"
import "./config/bar/widgets"
import "./config/widgets" as SharedWidgets

Scope {
  WindowTitle {
    id: titleWidget
    widgetInstance: ({ settings: { maxTitleWidth: 420, showAppIcon: false, showGitStatus: false, showMediaContext: true } })
  }

  KeyboardLayout {
    id: kbWidget
    widgetInstance: ({ settings: { labelMode: "full" } })
  }

  SharedWidgets.MediaBar {
    id: mediaWidget
    widgetInstance: ({ settings: { displayMode: "icon", maxTextWidth: 190 } })
    iconOnly: true
    maxTextWidth: 190
  }

  Component.onCompleted: {
    console.log("RESULT:" + JSON.stringify({
      windowTitleDefaults: BarWidgetRegistry.defaultSettings("windowTitle"),
      mediaBarDefaults: BarWidgetRegistry.defaultSettings("mediaBar"),
      keyboardLayoutDefaults: BarWidgetRegistry.defaultSettings("keyboardLayout"),
      titleMaxWidth: titleWidget.maxTitleWidth,
      titleShowAppIcon: titleWidget.showAppIcon,
      titleShowGitStatus: titleWidget.showGitStatus,
      keyboardLabelMode: kbWidget.labelMode,
      mediaIconOnly: mediaWidget.iconOnly,
      mediaMaxTextWidth: mediaWidget.maxTextWidth
    }));
    Qt.quit();
  }
}
