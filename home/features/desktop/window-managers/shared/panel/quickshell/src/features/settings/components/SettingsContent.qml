pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../services"
import "../../../widgets" as SharedWidgets
import "."

Item {
  id: root

  property bool _destroyed: false
  property string currentTabId: SettingsRegistry.defaultTabId
  property var settingsRoot: null
  property string searchQuery: ""
  property bool compactMode: false
  property bool tightSpacing: false
  property int requestedScrollY: 0
  property string highlightCardTitle: ""
  property string highlightSettingLabel: ""
  signal tabSelected(string tabId)
  signal searchQueryEdited(string query)
  signal highlightConsumed()

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
    Qt.callLater(function() { if (_destroyed) return; root.applyRequestedScroll(); });
  }

  // ── Scroll-to-highlight logic ────────────────────
  function scrollToHighlightedSetting() {
    if (!highlightSettingLabel) return;
    if (!tabLoader.item) return;

    // Wait for the tab to finish layout, then walk the tree
    Qt.callLater(function() {
      if (_destroyed) return;
      _doScrollToHighlight();
    });
  }

  function _findChildByTitle(parent, title) {
    if (!parent || !parent.children) return null;
    for (var i = 0; i < parent.children.length; ++i) {
      var child = parent.children[i];
      if (child.title !== undefined && String(child.title) === title)
        return child;
      var deep = _findChildByTitle(child, title);
      if (deep) return deep;
    }
    return null;
  }

  function _findSettingByLabel(parent, label) {
    if (!parent || !parent.children) return null;
    for (var i = 0; i < parent.children.length; ++i) {
      var child = parent.children[i];
      if (child.label !== undefined && String(child.label) === label) {
        // Set highlighted if supported
        if (child.highlighted !== undefined)
          child.highlighted = true;
        return child;
      }
      var deep = _findSettingByLabel(child, label);
      if (deep) return deep;
    }
    return null;
  }

  function _doScrollToHighlight() {
    var item = tabLoader.item;
    if (!item) return;

    var scrollable = findScrollable(item);
    if (!scrollable || !scrollable.flickable) return;
    var flick = scrollable.flickable;

    // Find the card with matching title, or fall back to searching the whole tab
    var card = highlightCardTitle ? _findChildByTitle(item, highlightCardTitle) : null;
    var searchRoot = card || item;

    // Find the setting within the card (or whole tab if no card)
    var setting = _findSettingByLabel(searchRoot, highlightSettingLabel);
    if (!setting && !card) {
      highlightConsumed();
      return;
    }
    var target = setting || card;

    // Map target position to flickable coordinates
    var mapped = target.mapToItem(flick.contentItem, 0, 0);
    var targetY = mapped.y - flick.height / 4; // Center-ish in viewport
    var maxY = Math.max(0, flick.contentHeight - flick.height);
    flick.contentY = Math.max(0, Math.min(targetY, maxY));

    // Clear highlight after animation
    _highlightClearTimer.restart();
    highlightConsumed();
  }

  Timer {
    id: _highlightClearTimer
    interval: 2400
    repeat: false
    onTriggered: {
      // Walk tree to clear any highlighted properties
      root._clearHighlights(tabLoader.item);
    }
  }

  function _clearHighlights(node) {
    if (!node) return;
    if (node.highlighted !== undefined)
      node.highlighted = false;
    if (node.children) {
      for (var i = 0; i < node.children.length; ++i)
        _clearHighlights(node.children[i]);
    }
  }

  onHighlightCardTitleChanged: {
    if (highlightSettingLabel && tabLoader.item) {
      // Tab already loaded — scroll immediately
      Qt.callLater(function() { if (!_destroyed) scrollToHighlightedSetting(); });
    }
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: 0

    Rectangle {
      visible: root.showCompactSearch
      Layout.fillWidth: true
      Layout.margins: root.tightSpacing ? Appearance.spacingM : Appearance.spacingL
      Layout.bottomMargin: root.tightSpacing ? 0 : Appearance.spacingS
      implicitHeight: compactSearchRow.implicitHeight + Appearance.spacingM
      radius: Appearance.radiusPill
      color: Colors.modalFieldSurface
      border.color: compactSearchInput.activeFocus ? Colors.primary : Colors.border
      border.width: 1

      RowLayout {
        id: compactSearchRow
        anchors.fill: parent
        anchors.leftMargin: Appearance.spacingM
        anchors.rightMargin: Appearance.spacingM
        spacing: Appearance.spacingS

        SharedWidgets.SvgIcon {
          source: "search-visual.svg"
          color: Colors.textDisabled
          size: Appearance.fontSizeMedium
        }

        TextInput {
          id: compactSearchInput
          Layout.fillWidth: true
          color: Colors.text
          font.pixelSize: Appearance.fontSizeSmall
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
            text: "Search settings"
            color: Colors.textDisabled
            font.pixelSize: parent.font.pixelSize
            visible: !parent.text && !parent.activeFocus
          }
        }

        SharedWidgets.SvgIcon {
          source: "dismiss.svg"
          color: Colors.textDisabled
          size: Appearance.fontSizeSmall
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

      onLoaded: {
        root.applyLayoutProps(item);
        if (root.highlightCardTitle && root.highlightSettingLabel)
          root.scrollToHighlightedSetting();
      }
    }

    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true
      visible: root.showCompactResults

      SharedWidgets.ScrollableContent {
        anchors.fill: parent
        columnSpacing: Appearance.spacingL

        ColumnLayout {
          Layout.fillWidth: true
          Layout.leftMargin: root.tightSpacing ? 20 : 24
          Layout.rightMargin: root.tightSpacing ? 20 : 24
          Layout.topMargin: root.tightSpacing ? 20 : 24
          Layout.bottomMargin: root.tightSpacing ? 20 : 24
          spacing: Appearance.spacingL

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingXS

            Text {
              text: "Search Results"
              color: Colors.text
              font.pixelSize: Appearance.fontSizeHuge
              font.weight: Font.Bold
              font.letterSpacing: Appearance.letterSpacingTight
            }

            Text {
              text: root.searchResults.length > 0
                ? root.searchResults.length + " matching settings"
                : "No matching settings"
              color: Colors.textSecondary
              font.pixelSize: Appearance.fontSizeSmall
              Layout.fillWidth: true
              wrapMode: Text.WordWrap
            }
          }

          Repeater {
            model: root.searchResults

            delegate: Rectangle {
              required property var modelData
              Layout.fillWidth: true
              implicitHeight: resultColumn.implicitHeight + Appearance.spacingM * 2
              radius: Appearance.radiusMedium
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
                anchors.margins: Appearance.spacingM
                spacing: Appearance.spacingS

                RowLayout {
                  Layout.fillWidth: true
                  spacing: Appearance.spacingM

                  Rectangle {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: Appearance.radiusSmall
                    color: Colors.primarySubtle

                    SettingsMetricIcon { anchors.centerIn: parent; icon: modelData.icon }
                  }

                  Text {
                    text: modelData.label
                    color: Colors.text
                    font.pixelSize: Appearance.fontSizeMedium
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                  }
                }

                Text {
                  text: String(modelData.categoryId || "settings").replace(/-/g, " ")
                  color: Colors.textSecondary
                  font.pixelSize: Appearance.fontSizeSmall
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
        color: Colors.textDisabled
        font.pixelSize: Appearance.fontSizeMedium
      }
    }
  }

  Component.onDestruction: _destroyed = true
  onSettingsRootChanged: root.applyLayoutProps(tabLoader.item)
  onCurrentTabIdChanged: root.applyLayoutProps(tabLoader.item)
  onCompactModeChanged: root.applyLayoutProps(tabLoader.item)
  onTightSpacingChanged: root.applyLayoutProps(tabLoader.item)
  onRequestedScrollYChanged: Qt.callLater(function() { if (_destroyed) return; root.applyRequestedScroll(); })
  onSearchQueryChanged: {
    if (compactSearchInput.text !== searchQuery)
      compactSearchInput.text = searchQuery;
  }
}
