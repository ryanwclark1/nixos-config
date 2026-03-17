pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../widgets" as SharedWidgets
import "."

Rectangle {
  id: root

  property string currentTabId: SettingsRegistry.defaultTabId
  property string searchQuery: ""
  property bool compactMode: false
  signal tabSelected(string tabId)
  signal saveAndClose()
  signal searchQueryEdited(string query)

  readonly property bool isSearching: searchQuery.length > 0
  readonly property var orderedCategories: SettingsRegistry.sortedCategories()
  readonly property var searchResults: SettingsRegistry.searchTabs(searchQuery)
  readonly property var compactEntries: buildCompactEntries()

  Layout.fillHeight: true
  color: Colors.withAlpha(Colors.surface, 0.25)

  Rectangle {
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: 1
    color: Colors.border
    opacity: 0.5
  }

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
      var c = orderedCategories[i];
      states[c.id] = !!c.expandedByDefault;
    }
    expandedCategories = states;
    autoExpandForTab(currentTabId);
  }

  function autoExpandForTab(tabId) {
    var tab = SettingsRegistry.findTab(tabId);
    if (!tab || !tab.categoryId) return;
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

  Component.onCompleted: initializeExpandedState()
  onCurrentTabIdChanged: autoExpandForTab(currentTabId)

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: root.compactMode ? Colors.spacingS : Colors.spacingL
    spacing: Colors.spacingS

    Text {
      visible: !root.compactMode
      text: "SETTINGS"
      color: Colors.textDisabled
      font.pixelSize: Colors.fontSizeXS
      font.weight: Font.Black
      font.letterSpacing: Colors.letterSpacingExtraWide
      Layout.bottomMargin: Colors.spacingXS
    }

    Rectangle {
      visible: !root.compactMode
      Layout.fillWidth: true
      implicitHeight: searchBarRow.implicitHeight + Colors.spacingS * 2
      radius: Colors.radiusPill
      color: Colors.modalFieldSurface
      border.color: searchInput.activeFocus ? Colors.primary : Colors.border
      border.width: 1

      RowLayout {
        id: searchBarRow
        anchors.fill: parent
        anchors.leftMargin: Colors.spacingM
        anchors.rightMargin: Colors.spacingM
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
            text: "Search..."
            color: Colors.textDisabled
            font.pixelSize: parent.font.pixelSize
            visible: !parent.text && !parent.activeFocus
          }
        }

        Text {
          text: "󰅖"
          color: Colors.textDisabled
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeSmall
          visible: searchInput.text.length > 0

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.searchQueryEdited("")
          }
        }
      }
    }

    Item {
      visible: !root.compactMode
      height: 4
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
              height: modelData.type === "separator" ? 22 : 44

              Rectangle {
                anchors.centerIn: parent
                visible: modelData.type === "tab"
                width: 40
                height: 40
                radius: Colors.radiusMedium
                color: root.currentTabId === modelData.id ? Colors.highlight : "transparent"
                border.color: root.currentTabId === modelData.id ? Colors.withAlpha(Colors.primary, 0.55) : "transparent"
                border.width: 1

                SharedWidgets.StateLayer {
                  id: compactTabState
                  anchors.fill: parent
                  hovered: compactTabMouse.containsMouse
                  pressed: compactTabMouse.pressed
                  visible: modelData.type === "tab" && root.currentTabId !== modelData.id
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
                  width: 22
                  height: 1
                  color: Colors.border
                }
              }
            }
          }
        }

        ColumnLayout {
          id: sidebarColumn
          visible: !root.compactMode
          width: parent.width
          spacing: Colors.spacingXXS

          Repeater {
            model: root.isSearching ? root.searchResults : []

            delegate: Rectangle {
              required property var modelData
              Layout.fillWidth: true
              implicitHeight: resultRow.implicitHeight + Colors.spacingS * 2
              radius: Colors.radiusSmall
              color: root.currentTabId === modelData.id ? Colors.highlight : "transparent"
              Behavior on color { ColorAnimation { duration: Colors.durationSnap } }

              SharedWidgets.StateLayer {
                id: resultState
                hovered: resultMouse.containsMouse
                pressed: resultMouse.pressed
                visible: root.currentTabId !== modelData.id
              }

              RowLayout {
                id: resultRow
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
                  font.pixelSize: Colors.fontSizeLarge
                }

                Text {
                  text: modelData.label
                  color: root.currentTabId === modelData.id ? Colors.text : Colors.textSecondary
                  font.pixelSize: Colors.fontSizeMedium
                  font.weight: root.currentTabId === modelData.id ? Font.DemiBold : Font.Normal
                  Layout.fillWidth: true
                  wrapMode: Text.WordWrap
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

          Repeater {
            model: root.isSearching ? [] : root.orderedCategories

            delegate: ColumnLayout {
              required property var modelData
              Layout.fillWidth: true
              spacing: 0

              readonly property var categoryTabs: SettingsRegistry.tabsForCategory(modelData.id)
              readonly property bool expanded: !!root.expandedCategories[modelData.id]

              Rectangle {
                Layout.fillWidth: true
                implicitHeight: categoryRow.implicitHeight + Colors.spacingS * 2
                radius: Colors.radiusSmall
                color: "transparent"

                SharedWidgets.StateLayer {
                  id: categoryState
                  hovered: categoryMouse.containsMouse
                  pressed: categoryMouse.pressed
                }

                RowLayout {
                  id: categoryRow
                  anchors.fill: parent
                  anchors.leftMargin: Colors.spacingM
                  anchors.rightMargin: Colors.spacingM
                  anchors.topMargin: Colors.spacingS
                  anchors.bottomMargin: Colors.spacingS
                  spacing: Colors.spacingS

                  Text {
                    text: expanded ? "󰅀" : "󰅂"
                    color: Colors.textDisabled
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeSmall
                  }

                  Text {
                    text: modelData.icon
                    color: Colors.textSecondary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeLarge
                  }

                  Text {
                    text: modelData.label
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
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

              ColumnLayout {
                Layout.fillWidth: true
                visible: expanded
                spacing: Colors.spacingXXS

                Repeater {
                  model: expanded ? categoryTabs : []

                  delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: tabRow.implicitHeight + Colors.spacingS * 2
                    radius: Colors.radiusSmall
                    color: root.currentTabId === modelData.id ? Colors.highlight : "transparent"
                    Behavior on color { ColorAnimation { duration: Colors.durationSnap } }

                    SharedWidgets.StateLayer {
                      id: tabState
                      hovered: tabMouse.containsMouse
                      pressed: tabMouse.pressed
                      visible: root.currentTabId !== modelData.id
                    }

                    RowLayout {
                      id: tabRow
                      anchors.fill: parent
                      anchors.leftMargin: Colors.spacingXL
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
                        font.weight: root.currentTabId === modelData.id ? Font.DemiBold : Font.Normal
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

      SharedWidgets.Scrollbar { flickable: sidebarFlick }
      SharedWidgets.OverscrollGlow { flickable: sidebarFlick }
    }

    Rectangle {
      Layout.fillWidth: true
      implicitHeight: saveButtonRow.implicitHeight + Colors.spacingS * 2
      radius: root.compactMode ? Colors.radiusMedium : Colors.radiusPill
      color: Colors.withAlpha(Colors.primary, 0.14)
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
          font.weight: Font.DemiBold
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

  onSearchQueryChanged: {
    if (!root.compactMode && searchInput.text !== searchQuery)
      searchInput.text = searchQuery;
  }
}
