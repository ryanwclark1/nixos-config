import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../shared"
import "../../services"
import "../../services/ClipboardDisplayHelpers.js" as ClipboardDisplay
import "../../services/SearchUtils.js" as SU
import "../../services/ShellUtils.js" as ShellUtils
import "../../widgets" as SharedWidgets

BasePopupMenu {
  id: root
  popupMaxWidth: 420; compactThreshold: 390
  implicitHeight: compactMode ? 640 : 600
  title: "Clipboard"
  contentSpacing: Appearance.spacingM
  focusOnOpen: true
  initialFocusTarget: searchBar.inputItem

  property var clipboardItems: ClipboardHistoryService.items
  property string searchQuery: ""
  property int selectedIndex: 0
  readonly property bool isLoadingHistory: ClipboardHistoryService.loading
  readonly property string clipboardError: String(ClipboardHistoryService.lastError || "")

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
    root.closeRequested();
  }

  function deleteClipboardItem(item) {
    if (!item)
      return;
    ClipboardHistoryService.deleteEntry(item.id);
  }

  readonly property var filteredItemsResult: {
    var items = Array.isArray(clipboardItems) ? clipboardItems : [];
    return SU.filterByFuzzy(items, searchQuery, function(it) {
      return it && it.content ? it.content.toLowerCase() : "";
    });
  }

  onClipboardItemsChanged: clampSelection()
  onSearchQueryChanged: selectedIndex = 0

  onVisibleChanged: {
    if (visible) {
      searchQuery = "";
      selectedIndex = 0;
      refresh();
    }
    else if (searchBar.inputItem.activeFocus) searchBar.inputItem.focus = false;
  }

  headerExtras: [
    SharedWidgets.IconButton {
      icon: "crop.svg"
      tooltipText: "Screenshot tool"
      onClicked: {
        root.closeRequested();
        Quickshell.execDetached(ShellUtils.shellSurfaceCall("openSurface", "screenshotMenu"));
      }
    },
    SharedWidgets.IconButton {
      icon: ClipboardHistoryService.loading ? "download.svg" : "arrow-clockwise.svg"
      tooltipText: "Refresh"
      onClicked: root.refresh()
    },
    SharedWidgets.IconButton {
      icon: "delete.svg"
      tooltipText: "Clear history"
      enabled: root.clipboardItems.length > 0
      onClicked: {
        ClipboardHistoryService.wipe();
      }
    }
  ]

  // Search bar
  SharedWidgets.SearchBar {
    id: searchBar
    placeholder: "Search clipboard..."
    preferredHeight: root.compactMode ? 34 : 36
    Layout.fillWidth: true
    onTextChanged: root.searchQuery = text
    inputItem.Keys.onEscapePressed: root.closeRequested()
    inputItem.Keys.onDownPressed: event => {
      if (root.moveSelection(1))
        event.accepted = true;
    }
    inputItem.Keys.onUpPressed: event => {
      if (root.moveSelection(-1))
        event.accepted = true;
    }
    inputItem.Keys.onPressed: event => {
      if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
        if (root.filteredItemsResult.length > 0) {
          root.activateClipboardItem(root.filteredItemsResult[root.selectedIndex]);
          event.accepted = true;
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
    columnSpacing: Appearance.spacingS

      Repeater {
        model: ScriptModel { values: root.filteredItemsResult }
        delegate: Rectangle {
          id: clipCard
          required property int index
          required property var modelData
          Layout.fillWidth: true
          readonly property bool isSelected: clipMouse.containsMouse || root.selectedIndex === index
          implicitHeight: clipContentCol.implicitHeight + Appearance.spacingM * 2
          radius: Appearance.radiusMedium
          color: isSelected ? Colors.primarySubtle : Colors.cardSurface
          border.color: isSelected ? Colors.withAlpha(Colors.primary, 0.4) : Colors.border
          border.width: 1
          Behavior on color { enabled: !Colors.isTransitioning; CAnim {} }

          readonly property bool isImage: ClipboardDisplay.isImageContent(modelData ? modelData.content : "")
          readonly property string imageSrc: {
            void ClipboardHistoryService._imageGeneration;
            return isImage ? ClipboardHistoryService.imagePath(modelData.id) : "";
          }
          readonly property string contentText: ClipboardDisplay.displayText(modelData ? modelData.content : "")
          readonly property int charCount: contentText.length

          SharedWidgets.InnerHighlight { highlightOpacity: 0.08 }

          SharedWidgets.StateLayer {
            id: clipStateLayer
            hovered: clipMouse.containsMouse
            pressed: clipMouse.pressed
          }

          ColumnLayout {
            id: clipContentCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Appearance.spacingM
            spacing: Appearance.spacingXS

            // Image preview
            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 120
              radius: Appearance.radiusXS
              color: Colors.withAlpha(Colors.text, 0.04)
              visible: clipCard.isImage && clipCard.imageSrc !== ""
              clip: true

              Image {
                id: clipImage
                anchors.fill: parent
                anchors.margins: 2
                source: clipCard.imageSrc !== "" ? ("file://" + clipCard.imageSrc) : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: false
                sourceSize.height: 120
                visible: status !== Image.Error

                onStatusChanged: {
                  if (status === Image.Error)
                    Logger.d("ClipboardMenu", "skipping unreadable image:", clipCard.imageSrc);
                }
              }

              // Fallback for broken images
              SharedWidgets.SvgIcon {
                anchors.centerIn: parent
                visible: clipImage.status === Image.Error
                source: "image.svg"
                size: Appearance.fontSizeXL
                color: Colors.withAlpha(Colors.text, 0.3)
              }
            }

            // Content text — multiline with word wrap
            Text {
              Layout.fillWidth: true
              text: clipCard.contentText
              color: Colors.text
              font.pixelSize: Appearance.fontSizeSmall
              font.family: clipCard.isImage ? Config.fontFamily : Appearance.fontMono
              wrapMode: Text.WrapAnywhere
              maximumLineCount: 3
              elide: Text.ElideRight
              lineHeight: 1.3
            }

            // Footer: character count + delete
            RowLayout {
              Layout.fillWidth: true
              spacing: Appearance.spacingS

              Text {
                text: clipCard.isImage ? "Image" : (clipCard.charCount + " chars")
                color: Colors.textSecondary
                font.pixelSize: Appearance.fontSizeXXS
                Layout.fillWidth: true
                verticalAlignment: Text.AlignVCenter
              }

              SharedWidgets.IconButton {
                id: deleteBtn
                icon: "delete.svg"
                size: 24
                iconSize: Appearance.fontSizeSmall
                iconColor: Colors.textDisabled
                stateColor: Colors.error
                tooltipText: "Delete"
                onClicked: root.deleteClipboardItem(modelData)
                z: 10
              }
            }
          }

          MouseArea {
            id: clipMouse
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.selectedIndex = index
            onClicked: (mouse) => {
              if (deleteBtn.containsMouse) {
                mouse.accepted = false;
                return;
              }
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
        Layout.topMargin: Appearance.spacingS
        Layout.bottomMargin: Appearance.spacingS
        visible: root.filteredItemsResult.length === 0
        icon: root.isLoadingHistory ? "clock.svg" : (root.clipboardError !== "" ? "error.svg" : (root.searchQuery ? "search-visual.svg" : "copy.svg"))
        message: root.isLoadingHistory
          ? "Loading clipboard history…"
          : (root.clipboardError !== ""
              ? root.clipboardError
              : (root.searchQuery ? "No matching items" : "Clipboard is empty"))
      }
  }
}
