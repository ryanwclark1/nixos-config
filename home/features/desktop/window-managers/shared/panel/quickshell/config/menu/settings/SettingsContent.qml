import QtQuick
import QtQuick.Layouts
import "../../services"
import "."

Item {
  id: root

  property string currentTabId: SettingsRegistry.defaultTabId
  property var settingsRoot: null

  readonly property var currentTab: SettingsRegistry.findTab(currentTabId)

  Loader {
    id: tabLoader
    anchors.fill: parent
    active: !!root.currentTab
    source: root.currentTab ? ("tabs/" + root.currentTab.component) : ""

    onLoaded: {
      if (item && item.settingsRoot !== undefined)
        item.settingsRoot = root.settingsRoot;
      if (item && item.tabId !== undefined)
        item.tabId = root.currentTabId;
    }
  }

  onSettingsRootChanged: {
    if (tabLoader.item && tabLoader.item.settingsRoot !== undefined)
      tabLoader.item.settingsRoot = root.settingsRoot;
  }

  onCurrentTabIdChanged: {
    if (tabLoader.item && tabLoader.item.tabId !== undefined)
      tabLoader.item.tabId = root.currentTabId;
  }

  Rectangle {
    anchors.fill: parent
    visible: !tabLoader.active
    color: "transparent"

    Text {
      anchors.centerIn: parent
      text: "Unknown settings tab"
      color: Colors.fgDim
      font.pixelSize: Colors.fontSizeMedium
    }
  }
}
