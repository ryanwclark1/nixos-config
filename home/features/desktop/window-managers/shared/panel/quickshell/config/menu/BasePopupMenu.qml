import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import "../widgets" as SharedWidgets

PopupWindow {
  id: root
  color: "transparent"

  // ── Required customization ────────────────────
  property string title: ""
  property string toggleMethod: ""

  // ── Optional customization ────────────────────
  property alias headerExtras: headerExtrasSlot.children
  default property alias content: contentSlot.data
  property string subtitle: ""
  property color surfaceTint: "transparent"
  property int contentSpacing: 14
  property string preferredEdge: "top"
  property bool focusOnOpen: false
  property var initialFocusTarget: null

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
  // The popup stays mapped during fade-out, then unmaps after the delay.
  property bool wantVisible: false
  visible: wantVisible || _unmapDelay.running
  property bool showContent: wantVisible

  function allowLayer(width, height) {
    return width > 0 && height > 0
      && width <= maxLayerTextureSize
      && height <= maxLayerTextureSize;
  }

  onWantVisibleChanged: {
    if (!wantVisible) _unmapDelay.restart();
  }

  onShowContentChanged: {
    if (showContent && focusOnOpen) {
      Qt.callLater(function() {
        if (!root.showContent) return;
        if (root.initialFocusTarget && root.initialFocusTarget.forceActiveFocus)
          root.initialFocusTarget.forceActiveFocus();
        else if (surface.forceActiveFocus)
          surface.forceActiveFocus();
      });
    } else if (!showContent && root.initialFocusTarget && root.initialFocusTarget.activeFocus) {
      root.initialFocusTarget.focus = false;
    }
  }

  Timer {
    id: _unmapDelay
    interval: 350
  }

  // ── Shadow ────────────────────────────────────
  SharedWidgets.ElevationShadow {}

  // ── Surface ───────────────────────────────────
  Rectangle {
    id: surface
    anchors.fill: parent
    color: Colors.withAlpha(Colors.surface, 0.94)
    border.color: Colors.border
    border.width: 1
    radius: Colors.radiusLarge
    clip: true
    focus: true

    gradient: Gradient {
      orientation: Gradient.Vertical
      GradientStop { position: 0.0; color: Colors.surfaceGradientStart }
      GradientStop { position: 1.0; color: Colors.surfaceGradientEnd }
    }

    // Inner subtle highlight border
    Rectangle {
      anchors.fill: parent
      anchors.margins: 1
      radius: parent.radius - 1
      color: "transparent"
      border.color: Colors.borderLight
      border.width: 1
      opacity: 0.15
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

    Behavior on opacity { NumberAnimation { id: _opacAnim; duration: Colors.durationNormal; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { id: _scaleAnim; duration: Colors.durationNormal; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
    Behavior on transform { NumberAnimation { duration: Colors.durationNormal; easing.type: Easing.OutCubic } }

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
          icon: "󰅖"
          size: 32
          iconSize: Colors.fontSizeXL
          iconColor: Colors.textDisabled
          stateColor: Colors.error
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
