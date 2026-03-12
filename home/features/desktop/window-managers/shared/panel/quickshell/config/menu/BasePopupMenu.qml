import Quickshell
import QtQuick
import QtQuick.Layouts
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

  // ── Deferred unmapping ────────────────────────
  // Parent binds wantVisible instead of visible/showContent.
  // The popup stays mapped during fade-out, then unmaps after the delay.
  property bool wantVisible: false
  visible: wantVisible || _unmapDelay.running
  property bool showContent: wantVisible

  onWantVisibleChanged: {
    if (!wantVisible) _unmapDelay.restart();
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
    color: Colors.popupSurface
    border.color: Colors.border
    border.width: 1
    radius: Colors.radiusMedium
    clip: true
    focus: true

    Keys.onEscapePressed: Quickshell.execDetached(["quickshell", "ipc", "call", "Shell", root.toggleMethod])

    opacity: root.showContent ? 1.0 : 0.0
    scale: root.showContent ? 1.0 : 0.95
    transformOrigin: Item.Top
    Behavior on opacity { NumberAnimation { id: _opacAnim; duration: 200; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { id: _scaleAnim; duration: 250; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
    layer.enabled: _opacAnim.running || _scaleAnim.running

    // Optional surface tint (e.g. for MusicMenu accent color)
    Rectangle {
      anchors.fill: parent
      radius: parent.radius
      color: root.surfaceTint
      visible: root.surfaceTint !== Qt.rgba(0,0,0,0) && root.surfaceTint.a > 0
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Colors.paddingLarge
      spacing: root.contentSpacing

      // ── Header row ──────────────────────────
      RowLayout {
        Layout.fillWidth: true

        ColumnLayout {
          spacing: 2
          Text {
            text: root.title
            color: Colors.text
            font.pixelSize: Colors.fontSizeXL
            font.weight: Font.DemiBold
          }
          Text {
            visible: root.subtitle !== ""
            text: root.subtitle
            color: Colors.textSecondary
            font.pixelSize: Colors.fontSizeSmall
          }
        }

        Item { Layout.fillWidth: true }

        // Slot for extra header widgets (buttons, chips, etc.)
        Row {
          id: headerExtrasSlot
          spacing: Colors.spacingS
        }

        SharedWidgets.MenuCloseButton { toggleMethod: root.toggleMethod }
      }

      // ── Separator ───────────────────────────
      Rectangle {
        Layout.fillWidth: true
        height: 1
        color: Colors.border
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
