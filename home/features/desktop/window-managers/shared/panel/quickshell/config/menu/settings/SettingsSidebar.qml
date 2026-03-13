import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../widgets" as SharedWidgets
import "."

Rectangle {
  id: root

  property string currentTabId: SettingsRegistry.defaultTabId
  signal tabSelected(string tabId)
  signal saveAndClose()

  Layout.preferredWidth: 240
  Layout.fillHeight: true
  color: Qt.rgba(0, 0, 0, 0.1)

  property string searchQuery: ""
  property bool isSearching: searchQuery.length > 0
  property var expandedCategories: ({})

  readonly property var orderedCategories: SettingsRegistry.sortedCategories()
  readonly property var searchResults: SettingsRegistry.searchTabs(searchQuery)

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
    anchors.margins: Colors.spacingL
    spacing: Colors.spacingS

    Text {
      text: "SETTINGS"
      color: Colors.textDisabled
      font.pixelSize: Colors.fontSizeXS
      font.weight: Font.Black
      font.letterSpacing: 1.5
      Layout.bottomMargin: 4
    }

    Rectangle {
      Layout.fillWidth: true
      height: 34
      radius: Colors.radiusPill
      color: Colors.bgWidget
      border.color: searchInput.activeFocus ? Colors.primary : Colors.border
      border.width: 1

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Colors.spacingM
        anchors.rightMargin: Colors.spacingM
        spacing: Colors.spacingS

        Text {
          text: "󰍉"
          color: Colors.fgDim
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeMedium
        }

        TextInput {
          id: searchInput
          Layout.fillWidth: true
          color: Colors.text
          font.pixelSize: Colors.fontSizeSmall
          clip: true
          onTextChanged: root.searchQuery = text

          Text {
            text: "Search..."
            color: Colors.fgDim
            font.pixelSize: parent.font.pixelSize
            visible: !parent.text && !parent.activeFocus
          }
        }

        Text {
          text: "󰅖"
          color: Colors.fgDim
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeSmall
          visible: searchInput.text.length > 0

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: searchInput.text = ""
          }
        }
      }
    }

    Item { height: 4 }

    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true

      Flickable {
        id: sidebarFlick
        anchors.fill: parent
        contentHeight: sidebarColumn.implicitHeight
        clip: true
        boundsBehavior: Flickable.DragOverBounds

        ColumnLayout {
          id: sidebarColumn
          width: parent.width
          spacing: 2

          Repeater {
            model: root.isSearching ? root.searchResults : []

            delegate: Rectangle {
              required property var modelData
              Layout.fillWidth: true
              height: 38
              radius: Colors.radiusSmall
              color: root.currentTabId === modelData.id ? Colors.highlight : "transparent"
              Behavior on color { ColorAnimation { duration: 120 } }

              SharedWidgets.StateLayer {
                id: resultState
                hovered: resultMouse.containsMouse
                pressed: resultMouse.pressed
                visible: root.currentTabId !== modelData.id
              }

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Colors.spacingL
                spacing: Colors.spacingM

                Text {
                  text: modelData.icon
                  color: root.currentTabId === modelData.id ? Colors.primary : Colors.fgDim
                  font.family: Colors.fontMono
                  font.pixelSize: Colors.fontSizeLarge
                }
                Text {
                  text: modelData.label
                  color: root.currentTabId === modelData.id ? Colors.text : Colors.fgSecondary
                  font.pixelSize: Colors.fontSizeMedium
                  font.weight: root.currentTabId === modelData.id ? Font.DemiBold : Font.Normal
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
                height: 36
                radius: Colors.radiusSmall
                color: "transparent"

                SharedWidgets.StateLayer {
                  id: categoryState
                  hovered: categoryMouse.containsMouse
                  pressed: categoryMouse.pressed
                }

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: Colors.spacingM
                  anchors.rightMargin: Colors.spacingM
                  spacing: Colors.spacingS

                  Text {
                    text: expanded ? "󰅀" : "󰅂"
                    color: Colors.fgDim
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeSmall
                  }

                  Text {
                    text: modelData.icon
                    color: Colors.fgSecondary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeLarge
                  }

                  Text {
                    text: modelData.label
                    color: Colors.fgSecondary
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
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
                spacing: 2

                Repeater {
                  model: expanded ? categoryTabs : []

                  delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    height: 36
                    radius: Colors.radiusSmall
                    color: root.currentTabId === modelData.id ? Colors.highlight : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }

                    SharedWidgets.StateLayer {
                      id: tabState
                      hovered: tabMouse.containsMouse
                      pressed: tabMouse.pressed
                      visible: root.currentTabId !== modelData.id
                    }

                    RowLayout {
                      anchors.fill: parent
                      anchors.leftMargin: Colors.spacingXL
                      anchors.rightMargin: Colors.spacingM
                      spacing: Colors.spacingM

                      Text {
                        text: modelData.icon
                        color: root.currentTabId === modelData.id ? Colors.primary : Colors.fgDim
                        font.family: Colors.fontMono
                        font.pixelSize: Colors.fontSizeMedium
                      }

                      Text {
                        text: modelData.label
                        color: root.currentTabId === modelData.id ? Colors.text : Colors.fgSecondary
                        font.pixelSize: Colors.fontSizeSmall
                        font.weight: root.currentTabId === modelData.id ? Font.DemiBold : Font.Normal
                        Layout.fillWidth: true
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

      SharedWidgets.DankScrollbar { flickable: sidebarFlick }
    }

    Rectangle {
      Layout.fillWidth: true
      height: 40
      radius: Colors.radiusPill
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
        anchors.centerIn: parent
        spacing: Colors.spacingS

        Text {
          text: "󰆓"
          color: Colors.primary
          font.family: Colors.fontMono
          font.pixelSize: Colors.fontSizeMedium
        }

        Text {
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
}
