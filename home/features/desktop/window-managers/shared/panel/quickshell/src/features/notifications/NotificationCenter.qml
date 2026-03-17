import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import "../system/sections"
import "../../services"
import "../../widgets" as SharedWidgets

PanelWindow {
  id: root

  property int panelWidth: Config.controlCenterWidth
  readonly property var edgeMargins: Config.reservedEdgesForScreen(screen, "")
  property int reservedTop: edgeMargins.top
  property int reservedRight: edgeMargins.right
  property int reservedBottom: edgeMargins.bottom

  anchors {
    top: true
    right: true
    bottom: true
  }

  margins.top: reservedTop + Colors.spacingS
  margins.right: reservedRight + Colors.spacingS
  margins.bottom: reservedBottom + Colors.spacingS

  implicitWidth: panelWidth + 20
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-notifications"

  property var manager: null
  property bool showContent: false
  readonly property int maxLayerTextureSize: 4096
  signal closeRequested()
  property string searchQuery: ""
  visible: showContent || ncSlideAnim.running || ncFadeAnim.running

  function allowLayer(width, height) {
    return width > 0 && height > 0
      && width <= maxLayerTextureSize
      && height <= maxLayerTextureSize;
  }

  onShowContentChanged: {
    if (showContent) {
      Qt.callLater(function() {
        if (root.showContent && searchInput)
          searchInput.forceActiveFocus();
      });
    } else {
      if (searchInput && searchInput.activeFocus)
        searchInput.focus = false;
      if (sidebarContent.activeFocus)
        sidebarContent.focus = false;
    }
  }

  SharedWidgets.ElevationShadow {
    anchors.fill: sidebarContent
    visible: sidebarContent.visible && sidebarContent.opacity > 0.5
  }

  Rectangle {
    id: sidebarContent
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    width: root.panelWidth

    color: Colors.bgGlass
    border.color: Colors.border
    border.width: 1
    radius: Colors.radiusLarge
    focus: true

    transform: Translate {
      x: root.showContent ? 0 : root.panelWidth + 40
      Behavior on x {
        NumberAnimation {
          id: ncSlideAnim
          duration: Colors.durationSlow
          easing.type: Easing.OutQuint
        }
      }
    }

    opacity: root.showContent ? 1.0 : 0.0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { id: ncFadeAnim; duration: Colors.durationNormal } }
    layer.enabled: (ncSlideAnim.running || ncFadeAnim.running) && root.allowLayer(width, height)

    SharedWidgets.InnerHighlight { highlightOpacity: 0.12 }
    SharedWidgets.SurfaceGradient {}

    Keys.onEscapePressed: root.closeRequested()

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Colors.paddingLarge
      spacing: Colors.spacingLG

      RowLayout {
        Layout.fillWidth: true
        spacing: Colors.spacingM
        Text {
          text: "Notifications"
          color: Colors.text
          font.pixelSize: Colors.fontSizeHuge
          font.weight: Font.DemiBold
          font.letterSpacing: Colors.letterSpacingTight
        }

        Item { Layout.fillWidth: true }

        // DND Toggle
        SharedWidgets.IconButton {
          size: 32
          icon: root.manager && root.manager.dndEnabled ? "󰂛" : "󰂚"
          iconColor: root.manager && root.manager.dndEnabled ? Colors.error : Colors.textSecondary
          onClicked: if (root.manager) root.manager.dndEnabled = !root.manager.dndEnabled
        }

        // Clear all
        SharedWidgets.IconButton {
          size: 32
          icon: "󰎟"
          iconColor: Colors.textDisabled
          onClicked: if (root.manager) root.manager.dismissAll()
        }

        // Close button
        SharedWidgets.IconButton {
          size: 32
          icon: "󰅖"
          onClicked: root.closeRequested()
        }
      }

      WeatherWidget {}

      Calendar {
         visible: root.searchQuery === ""
      }

      // Search Bar
      Rectangle {
        Layout.fillWidth: true
        height: 44
        color: Colors.cardSurface
        radius: Colors.radiusMedium
        border.color: searchInput.activeFocus ? Colors.primary : Colors.border
        border.width: 1

        RowLayout {
          anchors.fill: parent
          anchors.margins: Colors.spacingM
          spacing: Colors.spacingS
          Text {
            text: "󰍉"
            color: Colors.textDisabled
            font.family: Colors.fontMono
            font.pixelSize: Colors.fontSizeLarge
          }
          TextInput {
            id: searchInput
            Layout.fillWidth: true
            verticalAlignment: Text.AlignVCenter
            color: Colors.text
            font.pixelSize: Colors.fontSizeMedium
            onVisibleChanged: if (!visible && activeFocus) focus = false
            Keys.onEscapePressed: root.closeRequested()
            onTextChanged: root.searchQuery = text
          }
          Text {
            Layout.alignment: Qt.AlignVCenter
            text: "Search..."
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeMedium
            visible: !searchInput.text && !searchInput.activeFocus
          }
        }
      }

      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ListView {
          id: notifList
          anchors.fill: parent
          spacing: Colors.spacingM; clip: true; focus: true
          model: root.manager ? root.manager.notifications : null

          property var collapsedGroups: ({})

          add: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: Colors.durationPanelOpen; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.95; to: 1.0; duration: Colors.durationPanelOpen; easing.type: Easing.OutBack }
          }

          remove: Transition {
            NumberAnimation { property: "opacity"; to: 0; duration: Colors.durationNormal }
          }

          displaced: Transition {
            NumberAnimation { properties: "y"; duration: Colors.durationPanelOpen; easing.type: Easing.OutCubic }
          }

          // Empty state
          ColumnLayout {
            anchors.centerIn: parent
            visible: (notifList.count === 0 && root.searchQuery === "") || (root.searchQuery !== "" && notifList.visibleCount === 0)
            spacing: Colors.spacingM
            opacity: 0.6
            Text {
              Layout.alignment: Qt.AlignHCenter
              text: root.searchQuery === "" ? "󰂚" : "󰍉"
              color: Colors.textDisabled
              font.pixelSize: 64
              font.family: Colors.fontMono
            }
            Text {
              Layout.alignment: Qt.AlignHCenter
              text: root.searchQuery === "" ? "No new notifications" : "No matches found"
              color: Colors.textDisabled
              font.pixelSize: Colors.fontSizeLarge
              font.weight: Font.Medium
            }
          }

          readonly property int visibleCount: {
            var count = 0;
            if (!root.manager || !root.manager.notifications) return 0;
            for (var i = 0; i < root.manager.notifications.count; i++) {
              var n = root.manager.notifications.get(i);
              if (!n || n.dismissed) continue;
              var q = root.searchQuery.toLowerCase();
              if (q === "" || (n.appName && n.appName.toLowerCase().includes(q)) || (n.summary && n.summary.toLowerCase().includes(q)) || (n.body && n.body.toLowerCase().includes(q))) {
                count++;
              }
            }
            return count;
          }

          function toggleGroup(name) {
            var groups = JSON.parse(JSON.stringify(collapsedGroups));
            groups[name] = !groups[name];
            collapsedGroups = groups;
          }

          section.property: "appName"
          section.criteria: ViewSection.FullString
          section.delegate: Item {
            width: notifList.width
            height: 44
            property bool isCollapsed: notifList.collapsedGroups[section] || false

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: Colors.spacingS
              spacing: Colors.spacingM

              MouseArea {
                Layout.preferredWidth: 24; Layout.preferredHeight: 24
                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                Text {
                  anchors.centerIn: parent; text: isCollapsed ? "󰅂" : "󰅀"; color: Colors.primary
                  font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeLarge
                }
                onClicked: notifList.toggleGroup(section)
              }

              Text {
                text: section || "System"
                color: Colors.text; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Black
                font.capitalization: Font.AllUppercase; font.letterSpacing: Colors.letterSpacingWide
              }

              Rectangle { Layout.fillWidth: true; height: 1; color: Colors.border; opacity: 0.4 }

              Rectangle {
                width: 24; height: 18; radius: Colors.radiusSmall; color: Colors.highlight
                readonly property int sectionCount: {
                  var count = 0;
                  var notifs = root.manager ? root.manager.notifications : null;
                  if (!notifs) return 0;
                  for (var i = 0; i < notifs.count; i++) {
                    var n = notifs.get(i);
                    if (n && n.appName === section) count++;
                  }
                  return count;
                }
                Text { anchors.centerIn: parent; text: parent.sectionCount; color: Colors.primary; font.pixelSize: Colors.fontSizeXXS; font.weight: Font.Bold }
              }

              SharedWidgets.IconButton {
                size: 28; icon: "󰅖"; iconColor: Colors.textDisabled
                stateColor: Colors.error
                onClicked: if (root.manager) root.manager.dismissAll(section)
              }
            }
          }

          delegate: NotificationDelegate {
            id: ncDelegate
            notification: modelData
            property bool isGroupCollapsed: notifList.collapsedGroups[modelData.appName] || false
            visible: !notification.dismissed && matchesSearch && !isGroupCollapsed
            height: visible ? implicitHeight : 0
            opacity: isGroupCollapsed ? 0 : 1
            width: notifList.width

            property bool matchesSearch: {
               if (root.searchQuery === "") return true;
               var q = root.searchQuery.toLowerCase();
               return (modelData.appName && modelData.appName.toLowerCase().includes(q)) ||
                      (modelData.summary && modelData.summary.toLowerCase().includes(q)) ||
                      (modelData.body && modelData.body.toLowerCase().includes(q));
            }

            onDismissRequested: notification.dismiss()
            onActionInvoked: action => { action.invoke(); notification.dismiss(); }
            onReplySent: text => { notification.invoke(text); notification.dismiss(); }
          }

          SharedWidgets.Scrollbar { flickable: notifList }
          SharedWidgets.OverscrollGlow { flickable: notifList }
        }
      }

      // Archive Section
      ColumnLayout {
        Layout.fillWidth: true
        spacing: Colors.spacingS
        visible: root.manager && root.manager.archivedNotifications.length > 0 && root.searchQuery === ""

        RowLayout {
          Layout.fillWidth: true
          Text {
            text: "RECENTLY DISMISSED"
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeXXS
            font.weight: Font.Black
            font.letterSpacing: Colors.letterSpacingWide
          }
          Item { Layout.fillWidth: true }
          SharedWidgets.Button {
            text: "Clear Archive"
            fontSize: Colors.fontSizeXXS
            Layout.preferredHeight: 22
            onClicked: if (root.manager) root.manager.clearArchive()
          }
        }

        ListView {
          Layout.fillWidth: true
          height: Math.min(contentHeight, 240)
          clip: true
          model: root.manager ? root.manager.archivedNotifications : null
          spacing: Colors.spacingS
          delegate: Rectangle {
            width: ListView.view.width; height: 54; color: Colors.cardSurface; radius: Colors.radiusMedium; opacity: 0.7
            border.color: Colors.border; border.width: 1

            SharedWidgets.InnerHighlight { highlightOpacity: 0.08 }

            RowLayout {
              anchors.fill: parent; anchors.margins: Colors.paddingSmall; spacing: Colors.paddingMedium
              SharedWidgets.AppIcon {
                iconName: modelData.appIcon || ""
                appName: modelData.appName || ""
                iconSize: 24
                fallbackIcon: "󰂚"
              }
              ColumnLayout {
                Layout.fillWidth: true; spacing: 0
                Text { text: modelData.summary; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Bold; elide: Text.ElideRight; Layout.fillWidth: true }
                Text { text: modelData.body; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXXS; elide: Text.ElideRight; Layout.fillWidth: true; visible: modelData.body !== "" }
              }
            }
          }
        }
      }
    }
  }
}
