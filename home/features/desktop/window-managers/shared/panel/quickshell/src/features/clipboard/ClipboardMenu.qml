import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../menu"
import "../../services"
import "../../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  popupMaxWidth: 360; compactThreshold: 350
  implicitHeight: compactMode ? 520 : 480
  title: "Clipboard"
  toggleMethod: "toggleClipboardMenu"
  contentSpacing: Colors.spacingM
  focusOnOpen: true
  initialFocusTarget: searchInput

  property var clipboardItems: ClipboardHistoryService.items
  property string searchQuery: ""
  property int selectedIndex: 0

  function refresh() {
    ClipboardHistoryService.refresh(null);
  }

  function clampSelection() {
    var items = filteredItemsResult || [];
    if (items.length <= 0) {
      selectedIndex = 0;
      return;
    }
    selectedIndex = Math.max(0, Math.min(selectedIndex, items.length - 1));
  }

  function moveSelection(step) {
    var items = filteredItemsResult || [];
    if (items.length <= 0)
      return false;
    selectedIndex = Math.max(0, Math.min(items.length - 1, selectedIndex + step));
    return true;
  }

  function activateClipboardItem(item) {
    if (!item)
      return;
    ClipboardHistoryService.restore(item.id);
    Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", "toggleClipboardMenu"]);
  }

  function deleteClipboardItem(item) {
    if (!item)
      return;
    ClipboardHistoryService.deleteEntry(item.id);
  }

  // Fuzzy search: ranks by exact substring match first, then by
  // consecutive-character matching with gap penalty scoring.
  // Returns all items when query is empty, or items sorted by relevance.
  readonly property var filteredItemsResult: {
    var items = Array.isArray(clipboardItems) ? clipboardItems : [];
    if (!searchQuery) return items;
    var q = searchQuery.toLowerCase();
    var scored = [];
    for (var i = 0; i < items.length; i++) {
      var item = items[i];
      if (!item || !item.content) continue;
      var content = item.content.toLowerCase();
      var score = _fuzzyScore(q, content);
      if (score > 0) scored.push({ item: item, score: score });
    }
    scored.sort(function(a, b) { return b.score - a.score; });
    var result = [];
    for (var j = 0; j < scored.length; j++) result.push(scored[j].item);
    return result;
  }

  // Scores how well `query` matches `target`.
  // Returns 0 for no match; higher = better.
  // Exact substring → 1000 + position bonus.
  // Fuzzy consecutive chars → sum of match bonuses with gap penalties.
  function _fuzzyScore(query, target) {
    // Exact substring gets highest priority
    var exactIdx = target.indexOf(query);
    if (exactIdx !== -1) return 1000 + (1.0 / (1 + exactIdx));

    // Fuzzy: walk through query chars, find them in order in target
    var qi = 0, score = 0, lastMatch = -1;
    for (var ti = 0; ti < target.length && qi < query.length; ti++) {
      if (target[ti] === query[qi]) {
        // Bonus for consecutive matches, penalty for gaps
        var gap = lastMatch >= 0 ? (ti - lastMatch - 1) : 0;
        score += 10 - Math.min(gap, 8);
        // Extra bonus for matching at word boundaries
        if (ti === 0 || target[ti - 1] === ' ' || target[ti - 1] === '/' || target[ti - 1] === '-' || target[ti - 1] === '_')
          score += 5;
        lastMatch = ti;
        qi++;
      }
    }
    // All query chars must be found
    return qi === query.length ? score : 0;
  }

  onClipboardItemsChanged: clampSelection()
  onSearchQueryChanged: selectedIndex = 0

  onVisibleChanged: {
    if (visible) refresh();
    else if (searchInput.activeFocus) searchInput.focus = false;
  }

  headerExtras: [
    SharedWidgets.IconButton {
      icon: "󰃢"
      onClicked: {
        ClipboardHistoryService.wipe();
      }
    }
  ]

  // Search bar
  Rectangle {
    Layout.fillWidth: true
    height: root.compactMode ? 34 : 36
    radius: height / 2
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
        color: Colors.textDisabled
        font.family: Colors.fontMono
        font.pixelSize: Colors.fontSizeMedium
      }

      TextInput {
        id: searchInput
        Layout.fillWidth: true
        color: Colors.text
        font.pixelSize: Colors.fontSizeMedium
        clip: true
        Keys.onEscapePressed: root.closeRequested()
        onTextChanged: root.searchQuery = text
        Keys.onDownPressed: event => {
          if (root.moveSelection(1))
            event.accepted = true;
        }
        Keys.onUpPressed: event => {
          if (root.moveSelection(-1))
            event.accepted = true;
        }
        Keys.onPressed: event => {
          if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (root.filteredItemsResult.length > 0) {
              root.activateClipboardItem(root.filteredItemsResult[root.selectedIndex]);
              event.accepted = true;
            }
          }
        }

        Text {
          anchors.fill: parent
          text: "Search clipboard..."
          color: Colors.textDisabled
          font.pixelSize: Colors.fontSizeMedium
          visible: !searchInput.text && !searchInput.activeFocus
          verticalAlignment: Text.AlignVCenter
        }
      }
    }
  }

  Rectangle {
    Layout.fillWidth: true
    height: 1
    color: Colors.border
  }

  // Clipboard items list
  SharedWidgets.ScrollableContent {
    Layout.fillWidth: true
    Layout.fillHeight: true
    columnSpacing: Colors.spacingS

      Repeater {
        model: ScriptModel { values: root.filteredItemsResult }
        delegate: Rectangle {
          id: clipCard
          required property int index
          Layout.fillWidth: true
          implicitHeight: 54
          radius: Colors.radiusMedium
          color: (clipMouse.containsMouse || root.selectedIndex === index) ? Colors.highlight : Colors.cardSurface
          border.color: (clipMouse.containsMouse || root.selectedIndex === index) ? Colors.withAlpha(Colors.primary, 0.4) : Colors.border
          border.width: 1
          Behavior on color { ColorAnimation { duration: 150 } }

          readonly property bool isImage: modelData.content && modelData.content.includes("[[ binary data")

          SharedWidgets.InnerHighlight { highlightOpacity: 0.08 }

          SharedWidgets.StateLayer {
            id: clipStateLayer
            hovered: clipMouse.containsMouse
            pressed: clipMouse.pressed
          }

          RowLayout {
            id: clipContent
            anchors.fill: parent
            anchors.margins: Colors.paddingSmall
            spacing: Colors.spacingM

            Rectangle {
              width: 32; height: 32; radius: Colors.radiusSmall
              color: (clipMouse.containsMouse || root.selectedIndex === index) ? Colors.surface : Colors.chipSurface
              Text {
                anchors.centerIn: parent
                text: clipCard.isImage ? "󰋩" : "󰅍"
                color: (clipMouse.containsMouse || root.selectedIndex === index) ? Colors.primary : Colors.textSecondary
                font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeLarge
              }
            }

            ColumnLayout {
              Layout.fillWidth: true; spacing: 0
              Text {
                text: clipCard.isImage ? "IMAGE DATA" : modelData.content
                color: Colors.text; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Medium
                elide: Text.ElideRight; Layout.fillWidth: true
                font.capitalization: clipCard.isImage ? Font.AllUppercase : Font.MixedCase
                font.letterSpacing: clipCard.isImage ? 0.5 : 0
              }
              Text {
                text: modelData.id || ""
                color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXXS
                visible: text !== ""
              }
            }

            SharedWidgets.IconButton {
              icon: "󰎟"; size: 28; iconSize: Colors.fontSizeLarge; iconColor: Colors.textDisabled
              stateColor: Colors.error
              onClicked: {
                root.deleteClipboardItem(modelData);
              }
            }
          }

          MouseArea {
            id: clipMouse
            anchors.fill: parent
            anchors.rightMargin: 40
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.selectedIndex = index
            onClicked: (mouse) => {
              clipStateLayer.burst(mouse.x, mouse.y);
              root.selectedIndex = index;
              root.activateClipboardItem(modelData);
            }
          }
        }
      }

      // Empty state
      SharedWidgets.EmptyState {
        Layout.fillWidth: true
        Layout.topMargin: Colors.spacingS
        Layout.bottomMargin: Colors.spacingS
        visible: root.filteredItemsResult.length === 0
        icon: root.searchQuery ? "󰍉" : "󰅗"
        message: root.searchQuery ? "No matching items" : "Clipboard is empty"
      }
  }
}
