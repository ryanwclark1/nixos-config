import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import "../widgets" as SharedWidgets

PopupWindow {
  id: root
  property bool _destroyed: false
  color: "transparent"

  // ── Required customization ────────────────────
  property string title: ""
  // ── Optional customization ────────────────────
  property alias headerExtras: headerExtrasSlot.children
  property alias backgroundContent: backgroundSlot.data
  default property alias content: contentSlot.data
  property string subtitle: ""
  property color surfaceTint: "transparent"
  property int contentSpacing: Colors.spacingML
  property string preferredEdge: "top"
  property bool focusOnOpen: true
  // focusTarget: if set, receives focus when the menu opens instead of the surface.
  // Child menus with a search bar should bind this to their TextInput item.
  property Item focusTarget: null
  // Keep old name as an alias for back-compat (both point to the same item).
  property alias initialFocusTarget: root.focusTarget

  // ── Responsive width ──────────────────────────
  property int popupMinWidth: 320
  property int popupMaxWidth: 380
  property int compactThreshold: 350
  property int maxLayerTextureSize: 4096
  readonly property int availablePopupWidth: screen ? Math.max(popupMinWidth, screen.width - 40) : popupMaxWidth
  readonly property bool compactMode: availablePopupWidth < compactThreshold
  implicitWidth: Math.min(popupMaxWidth, availablePopupWidth)

  // ── Close signal (avoids IPC round-trip) ────
  signal closeRequested()

  // ── Deferred unmapping ────────────────────────
  // Parent binds wantVisible instead of visible/showContent.
  // The popup stays mapped while exit animations are running, then unmaps.
  property bool wantVisible: false
  visible: root.wantVisible || _opacAnim.running || _scaleAnim.running
  property bool showContent: wantVisible

  function allowLayer(width, height) {
    return width > 0 && height > 0
      && width <= maxLayerTextureSize
      && height <= maxLayerTextureSize;
  }

  Component.onDestruction: _destroyed = true

  // ── Surface ID for FocusGrabManager ─────────
  // Derived from title by default; override if needed.
  property string _grabId: root.title ? root.title.toLowerCase().replace(/\s+/g, "") + "Popup" : "popup"

  onShowContentChanged: {
    if (showContent) {
      FocusGrabManager.requestGrab(root._grabId, function() {
        root.wantVisible = false;
      });
      if (focusOnOpen) {
        Qt.callLater(function() {
          if (_destroyed) return;
          if (!root.showContent) return;
          if (root.focusTarget && root.focusTarget.forceActiveFocus)
            root.focusTarget.forceActiveFocus();
          else if (surface.forceActiveFocus)
            surface.forceActiveFocus();
        });
      }
    } else {
      FocusGrabManager.releaseGrab(root._grabId);
      if (root.focusTarget && root.focusTarget.activeFocus)
        root.focusTarget.focus = false;
      if (surface.activeFocus)
        surface.focus = false;
    }
  }

  // ── Shadow ────────────────────────────────────
  SharedWidgets.ElevationShadow {}

  // ── Surface ───────────────────────────────────
  ThemedContainer {
    id: surface
    variant: "popup"
    showGradient: false
    anchors.fill: parent
    clip: true
    focus: true

    Item {
      id: backgroundSlot
      anchors.fill: parent
      z: -1
    }

    Keys.onEscapePressed: root.closeRequested()

    opacity: root.showContent ? 1.0 : 0.0
    scale: root.showContent ? 1.0 : 0.96
    transform: Translate {
      y: root.showContent ? 0 : (root.preferredEdge === "top" ? -10 : 10)
    }

    transformOrigin: {
      if (root.preferredEdge === "bottom") return Item.Bottom;
      if (root.preferredEdge === "left") return Item.Left;
      if (root.preferredEdge === "right") return Item.Right;
      return Item.Top;
    }

    Behavior on opacity { Anim { id: _opacAnim } }
    Behavior on scale { NumberAnimation { id: _scaleAnim; duration: Colors.durationNormal; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
    Behavior on transform { Anim {} }

    layer.enabled: (_opacAnim.running || _scaleAnim.running) && root.allowLayer(width, height)

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Colors.paddingLarge
      spacing: root.contentSpacing

      // ── Header row ──────────────────────────
      RowLayout {
        Layout.fillWidth: true
        spacing: Colors.spacingM

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 0
          Text {
            text: root.title
            color: Colors.text
            font.pixelSize: Colors.fontSizeXL
            font.weight: Font.Bold
            Layout.fillWidth: true
            elide: Text.ElideRight
          }
          Text {
            visible: root.subtitle !== ""
            text: root.subtitle
            color: Colors.textSecondary
            font.pixelSize: Colors.fontSizeSmall
            Layout.fillWidth: true
            elide: Text.ElideRight
          }
        }

        // Slot for extra header widgets (buttons, chips, etc.)
        Row {
          id: headerExtrasSlot
          spacing: Colors.spacingS
        }

        SharedWidgets.IconButton {
          icon: "dismiss.svg"
          size: Colors.iconSizeMedium
          iconSize: Colors.fontSizeXL
          iconColor: Colors.textDisabled
          stateColor: Colors.error
          tooltipText: "Close"
          onClicked: root.closeRequested()
        }
      }

      // ── Separator ───────────────────────────
      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Colors.border
        opacity: 0.6
      }

      // ── Content slot (ColumnLayout for Layout.* props) ──
      ColumnLayout {
        id: contentSlot
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: root.contentSpacing
      }
    }
  }
}
