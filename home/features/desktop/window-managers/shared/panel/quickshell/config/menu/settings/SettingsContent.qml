pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../widgets" as SharedWidgets
import "."

Item {
  id: root

  property string currentTabId: SettingsRegistry.defaultTabId
  property var settingsRoot: null
  property string searchQuery: ""
  property bool compactMode: false
  property bool tightSpacing: false
  property int requestedScrollY: 0
  signal tabSelected(string tabId)
  signal searchQueryEdited(string query)

  readonly property var currentTab: SettingsRegistry.findTab(currentTabId)
  readonly property var searchResults: SettingsRegistry.searchTabs(searchQuery)
  readonly property bool showCompactSearch: compactMode
  readonly property bool showCompactResults: compactMode && searchQuery.length > 0

  function findScrollable(node) {
    if (!node)
      return null;
    if (node.flickable !== undefined && node.flickable)
      return node;
    if (!node.children)
      return null;
    for (var i = 0; i < node.children.length; ++i) {
      var match = findScrollable(node.children[i]);
      if (match)
        return match;
    }
    return null;
  }

  function applyRequestedScroll() {
    var scrollable = findScrollable(tabLoader.item);
    if (!scrollable || scrollable.flickable === undefined || !scrollable.flickable)
      return false;
    var flick = scrollable.flickable;
    var maxY = Math.max(0, flick.contentHeight - flick.height);
    flick.contentY = Math.max(0, Math.min(requestedScrollY, maxY));
    return true;
  }

  function applyLayoutProps(item) {
    if (!item) return;
    if (item.settingsRoot !== undefined)
      item.settingsRoot = root.settingsRoot;
    if (item.tabId !== undefined)
      item.tabId = root.currentTabId;
    if (item.compactMode !== undefined)
      item.compactMode = root.compactMode;
    if (item.tightSpacing !== undefined)
      item.tightSpacing = root.tightSpacing;
    Qt.callLater(root.applyRequestedScroll);
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: 0

    Rectangle {
      visible: root.showCompactSearch
      Layout.fillWidth: true
      Layout.margins: root.tightSpacing ? Colors.spacingM : Colors.spacingL
      Layout.bottomMargin: root.tightSpacing ? 0 : Colors.spacingS
      implicitHeight: compactSearchRow.implicitHeight + Colors.spacingM
      radius: Colors.radiusPill
      color: Colors.modalFieldSurface
      border.color: compactSearchInput.activeFocus ? Colors.primary : Colors.border
      border.width: 1

      RowLayout {
        id: compactSearchRow
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
          id: compactSearchInput
          Layout.fillWidth: true
          color: Colors.text
          font.pixelSize: Colors.fontSizeSmall
          clip: true
          wrapMode: TextInput.Wrap
          onTextChanged: {
            if (text !== root.searchQuery)
              root.searchQueryEdited(text);
          }

          Text {
            text: "Search settings"
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
          visible: compactSearchInput.text.length > 0

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.searchQueryEdited("")
          }
        }
      }
    }

    Loader {
      id: tabLoader
      Layout.fillWidth: true
      Layout.fillHeight: true
      active: !!root.currentTab && !root.showCompactResults
      source: root.currentTab ? ("tabs/" + root.currentTab.component) : ""

      onLoaded: root.applyLayoutProps(item)
    }

    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true
      visible: root.showCompactResults

      SharedWidgets.ScrollableContent {
        anchors.fill: parent
        columnSpacing: Colors.spacingL

        ColumnLayout {
          Layout.fillWidth: true
          Layout.leftMargin: root.tightSpacing ? 20 : 24
          Layout.rightMargin: root.tightSpacing ? 20 : 24
          Layout.topMargin: root.tightSpacing ? 20 : 24
          Layout.bottomMargin: root.tightSpacing ? 20 : 24
          spacing: Colors.spacingL

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingXS

            Text {
              text: "Search Results"
              color: Colors.text
              font.pixelSize: Colors.fontSizeHuge
              font.weight: Font.Bold
              font.letterSpacing: Colors.letterSpacingTight
            }

            Text {
              text: root.searchResults.length > 0
                ? root.searchResults.length + " matching settings"
                : "No matching settings"
              color: Colors.fgSecondary
              font.pixelSize: Colors.fontSizeSmall
              Layout.fillWidth: true
              wrapMode: Text.WordWrap
            }
          }

          Repeater {
            model: root.searchResults

            delegate: Rectangle {
              required property var modelData
              Layout.fillWidth: true
              implicitHeight: resultColumn.implicitHeight + Colors.spacingM * 2
              radius: Colors.radiusMedium
              color: Colors.modalFieldSurface
              border.color: Colors.border
              border.width: 1

              SharedWidgets.StateLayer {
                id: compactResultState
                hovered: compactResultMouse.containsMouse
                pressed: compactResultMouse.pressed
                stateColor: Colors.primary
              }

              ColumnLayout {
                id: resultColumn
                anchors.fill: parent
                anchors.margins: Colors.spacingM
                spacing: Colors.spacingS

                RowLayout {
                  Layout.fillWidth: true
                  spacing: Colors.spacingM

                  Rectangle {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: Colors.radiusSmall
                    color: Colors.withAlpha(Colors.primary, 0.12)

                    Text {
                      anchors.centerIn: parent
                      text: modelData.icon
                      color: Colors.primary
                      font.family: Colors.fontMono
                      font.pixelSize: Colors.fontSizeLarge
                    }
                  }

                  Text {
                    text: modelData.label
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeMedium
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                  }
                }

                Text {
                  text: String(modelData.categoryId || "settings").replace(/-/g, " ")
                  color: Colors.fgSecondary
                  font.pixelSize: Colors.fontSizeSmall
                  Layout.fillWidth: true
                  wrapMode: Text.WordWrap
                }
              }

              MouseArea {
                id: compactResultMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                  compactResultState.burst(mouse.x, mouse.y);
                  root.tabSelected(modelData.id);
                  root.searchQueryEdited("");
                }
              }
            }
          }
        }
      }
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.fillHeight: true
      visible: !tabLoader.active && !root.showCompactResults
      color: "transparent"

      Text {
        anchors.centerIn: parent
        text: "Unknown settings tab"
        color: Colors.fgDim
        font.pixelSize: Colors.fontSizeMedium
      }
    }
  }

  onSettingsRootChanged: root.applyLayoutProps(tabLoader.item)
  onCurrentTabIdChanged: root.applyLayoutProps(tabLoader.item)
  onCompactModeChanged: root.applyLayoutProps(tabLoader.item)
  onTightSpacingChanged: root.applyLayoutProps(tabLoader.item)
  onRequestedScrollYChanged: Qt.callLater(root.applyRequestedScroll)
  onSearchQueryChanged: {
    if (compactSearchInput.text !== searchQuery)
      compactSearchInput.text = searchQuery;
  }
}
