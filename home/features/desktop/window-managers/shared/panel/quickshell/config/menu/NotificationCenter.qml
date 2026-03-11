import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Services.Mpris
import Quickshell.Wayland
import Quickshell.Widgets
import "../modules"
import "../notifications"
import "../services"

PanelWindow {
  id: root

  anchors {
    top: true
    right: true
    bottom: true
  }
  margins.top: Config.barHeight + Config.barMargin + 8
  margins.right: Config.barMargin
  margins.bottom: 60

  implicitWidth: Config.controlCenterWidth
  color: "transparent"
  mask: Region {
    item: sidebarContent
  }
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  WlrLayershell.namespace: "quickshell"

  property var manager: null
  property bool showContent: false
  signal closeRequested()
  property string searchQuery: ""
  visible: showContent || sidebarContent.x < Config.controlCenterWidth

  // Ensure focus is grabbed when shown
  onShowContentChanged: {
    if (showContent) {
      searchInput.forceActiveFocus();
    } else if (searchInput && searchInput.activeFocus) {
      searchInput.focus = false;
    }
  }

  Rectangle {
    id: sidebarContent
    width: Config.controlCenterWidth
    height: parent.height
    color: Colors.bgGlass
    border.color: Colors.border
    border.width: 1
    radius: Colors.radiusLarge

    x: root.showContent ? 0 : Config.controlCenterWidth + 10
    opacity: root.showContent ? 1.0 : 0.0

    Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 250 } }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Colors.paddingLarge
      spacing: 20

      RowLayout {
        Layout.fillWidth: true
        Text {
          text: "Notifications"
          color: Colors.text
          font.pixelSize: 22
          font.weight: Font.DemiBold
          font.letterSpacing: -0.5
        }

        Item { Layout.fillWidth: true }

        // DND Toggle
        MouseArea {
          width: 80; height: 28
          Rectangle {
            anchors.fill: parent
            color: root.manager && root.manager.dndEnabled ? Colors.error : Colors.highlight
            radius: 6
            Text {
              anchors.centerIn: parent
              text: root.manager && root.manager.dndEnabled ? "󰂛 DND" : "󰂚 DND"
              color: Colors.text; font.pixelSize: 11; font.weight: Font.Medium; font.family: Colors.fontMono
            }
          }
          onClicked: if (root.manager) root.manager.dndEnabled = !root.manager.dndEnabled
        }

        // Clear all
        MouseArea {
          width: 70; height: 28
          Rectangle {
            anchors.fill: parent; color: Colors.highlight; radius: 6
            Text { anchors.centerIn: parent; text: "Clear All"; color: Colors.textSecondary; font.pixelSize: 11; font.weight: Font.Medium }
          }
          onClicked: if (root.manager) { for (var i = root.manager.notifications.count - 1; i >= 0; i--) root.manager.notifications.get(i).dismiss(); }
        }

        // Close button
        MouseArea {
          width: 28; height: 28
          Rectangle {
            anchors.fill: parent; color: closeHover.containsMouse ? Colors.highlight : "transparent"; radius: 6
            Text { anchors.centerIn: parent; text: "󰅖"; color: Colors.textSecondary; font.family: Colors.fontMono; font.pixelSize: 14 }
          }
          id: closeHover; hoverEnabled: true
          onClicked: root.closeRequested()
        }
      }

      WeatherWidget {}

      Calendar {
         visible: root.searchQuery === ""
      }

      // Search Bar
      Rectangle {
        Layout.fillWidth: true; height: 40; color: Colors.highlightLight; radius: 8
        border.color: searchInput.activeFocus ? Colors.primary : "transparent"; border.width: 1
        RowLayout {
          anchors.fill: parent; anchors.margins: Colors.paddingSmall; spacing: 10
          Text { text: ""; color: Colors.textDisabled; font.family: Colors.fontMono; font.pixelSize: 14 }
          TextInput {
            id: searchInput; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter
            color: Colors.text; font.pixelSize: 12
            onVisibleChanged: if (!visible && activeFocus) focus = false
            onTextChanged: root.searchQuery = text
          }
          Text {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 35
            text: "Search notifications..."; color: Colors.textDisabled; font.pixelSize: 12
            visible: !searchInput.text && !searchInput.activeFocus
          }
        }
      }

      ListView {
        id: notifList
        Layout.fillWidth: true; Layout.fillHeight: true; spacing: 12; clip: true; focus: true
        highlightFollowsCurrentItem: true; keyNavigationEnabled: true
        model: root.manager ? root.manager.notifications : null

        property var collapsedGroups: ({})

        add: Transition {
          NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: 400; easing.type: Easing.OutCubic }
          NumberAnimation { property: "scale"; from: 0.9; to: 1.0; duration: 400; easing.type: Easing.OutBack }
        }

        remove: Transition {
          NumberAnimation { property: "opacity"; to: 0; duration: 300 }
          NumberAnimation { property: "scale"; to: 0.9; duration: 300 }
        }

        function toggleGroup(name) {
          var groups = JSON.parse(JSON.stringify(collapsedGroups));
          groups[name] = !groups[name];
          collapsedGroups = groups;
        }

        section.property: "appName"
        section.criteria: ViewSection.FullString
        section.delegate: Rectangle {
          width: notifList.width; height: 35; color: "transparent"
          property bool isCollapsed: notifList.collapsedGroups[section] || false

          RowLayout {
            anchors.fill: parent; spacing: 10

            MouseArea {
              width: 20; height: 20
              Text {
                anchors.centerIn: parent; text: isCollapsed ? "󰅂" : "󰅀"; color: Colors.primary
                font.family: Colors.fontMono; font.pixelSize: 14
              }
              onClicked: notifList.toggleGroup(section)
            }

            Text {
              text: section || "System"
              color: Colors.text; font.pixelSize: 11; font.weight: Font.Bold
              font.capitalization: Font.AllUppercase; font.letterSpacing: 1
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.border; opacity: 0.5 }

            // App Count Badge
            Rectangle {
              width: 20; height: 16; radius: 10; color: Colors.highlight
              Text { anchors.centerIn: parent; text: getCount(); color: Colors.primary; font.pixelSize: 9; font.weight: Font.Bold }
              function getCount() {
                var count = 0;
                for (var i = 0; i < root.manager.notifications.count; i++) {
                  if (root.manager.notifications.get(i).appName === section) count++;
                }
                return count;
              }
            }

            MouseArea {
              width: 24; height: 24
              Rectangle {
                anchors.fill: parent; radius: 12; color: clearHover.containsMouse ? Colors.highlight : "transparent"
                Text { anchors.centerIn: parent; text: "󰅖"; color: Colors.textDisabled; font.pixelSize: 14 }
              }
              id: clearHover; hoverEnabled: true
              onClicked: {
                if (!root.manager) return;
                for (var i = root.manager.notifications.count - 1; i >= 0; i--) {
                  var n = root.manager.notifications.get(i);
                  if (n.appName === section) n.dismiss();
                }
              }
            }
          }
        }

        delegate: Rectangle {
          id: notifItem
          property var notification: modelData
          property bool isCollapsed: notifList.collapsedGroups[modelData.appName] || false

          visible: !notification.dismissed && matchesSearch && !isCollapsed
          width: notifList.width
          height: visible ? colItem.implicitHeight + 24 + (isReplying ? 50 : 0) : 0
          color: Colors.surface
          opacity: isCollapsed ? 0 : 1
          radius: 12
          border.color: ListView.isCurrentItem && notifList.activeFocus ? Colors.primary : Colors.border
          border.width: 1
          clip: true

          // Search filtering logic
          property bool matchesSearch: {
             if (root.searchQuery === "") return true;
             var q = root.searchQuery.toLowerCase();
             return (modelData.appName && modelData.appName.toLowerCase().includes(q)) ||
                    (modelData.summary && modelData.summary.toLowerCase().includes(q)) ||
                    (modelData.body && modelData.body.toLowerCase().includes(q));
          }

          property bool isReplying: false
          onIsReplyingChanged: {
            if (isReplying) replyInput.forceActiveFocus();
            else if (replyInput.activeFocus) replyInput.focus = false;
          }

          // MPRIS Integration
          property var mprisPlayer: {
            if (!modelData.appName) return null;
            var app = modelData.appName.toLowerCase();
            for (var i = 0; i < Mpris.players.length; i++) {
              var p = Mpris.players[i];
              if (p.identity.toLowerCase().includes(app) || p.desktopEntry === app) return p;
            }
            return null;
          }

          Column {
            id: colItem
            width: parent.width - 24; anchors.top: parent.top; anchors.topMargin: 12; anchors.horizontalCenter: parent.horizontalCenter; spacing: 10

            RowLayout {
              width: parent.width; spacing: 12
              Image {
                Layout.preferredWidth: 32; Layout.preferredHeight: 32
                source: Config.resolveIconSource(modelData.appIcon || "")
                visible: modelData.appIcon !== ""
                Rectangle { anchors.fill: parent; color: "transparent"; visible: parent.status !== Image.Ready; Text { anchors.centerIn: parent; text: "󰂚"; color: Colors.text; font.pixelSize: 20; font.family: Colors.fontMono } }
              }

              ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                RowLayout {
                  Layout.fillWidth: true
                  Text {
                    text: modelData.summary; color: Colors.text; font.pixelSize: 15; font.weight: Font.Bold
                    Layout.fillWidth: true; elide: Text.ElideRight
                  }
                  Text {
                    text: modelData.time ? Qt.formatDateTime(modelData.time, "HH:mm") : ""
                    color: Colors.textDisabled; font.pixelSize: 11
                  }
                }
                Text {
                  text: modelData.body; color: Colors.textSecondary; font.pixelSize: 13
                  Layout.fillWidth: true; wrapMode: Text.Wrap; visible: modelData.body !== ""
                }
              }
            }

            // Media Controls (if applicable)
            Rectangle {
              width: parent.width; height: 40; radius: 8; color: Colors.highlightLight; visible: mprisPlayer !== null
              RowLayout {
                anchors.fill: parent; anchors.margins: 8; spacing: 15
                Item { Layout.fillWidth: true }
                MouseArea {
                  width: 24; height: 24
                  Text { anchors.centerIn: parent; text: "󰒮"; color: Colors.text; font.family: Colors.fontMono }
                  onClicked: mprisPlayer.previous()
                }
                MouseArea {
                  width: 32; height: 32
                  Rectangle { anchors.fill: parent; radius: 16; color: Colors.primary }
                  Text { anchors.centerIn: parent; text: mprisPlayer && mprisPlayer.playbackState === Mpris.Playing ? "󰏤" : "󰐊"; color: Colors.background; font.family: Colors.fontMono }
                  onClicked: mprisPlayer.playPause()
                }
                MouseArea {
                  width: 24; height: 24
                  Text { anchors.centerIn: parent; text: "󰒭"; color: Colors.text; font.family: Colors.fontMono }
                  onClicked: mprisPlayer.next()
                }
                Item { Layout.fillWidth: true }
              }
            }

            // Large Image Preview
            Rectangle {
              width: parent.width; height: 150; visible: modelData.image !== ""; radius: 8; clip: true; color: "transparent"; border.color: Colors.border; border.width: 1
              Image { anchors.fill: parent; source: modelData.image || ""; fillMode: Image.PreserveAspectCrop }
            }

            // Inline Reply Area
            Rectangle {
              width: parent.width; height: 36; radius: 6; color: Colors.highlightLight; visible: isReplying
              TextInput {
                id: replyInput; anchors.fill: parent; anchors.margins: 8
                verticalAlignment: Text.AlignVCenter
                color: Colors.text; font.pixelSize: 13
                onVisibleChanged: if (!visible && activeFocus) focus = false
                Keys.onReturnPressed: {
                  notifItem.notification.invoke(text);
                  notifItem.isReplying = false;
                  notifItem.notification.dismiss();
                }
                Keys.onEscapePressed: notifItem.isReplying = false
              }
            }

            // Actions
            RowLayout {
              width: parent.width; spacing: 8; visible: !isReplying

              // Dynamic Actions from Notification
              Repeater {
                model: notifItem.notification ? notifItem.notification.actions : null
                delegate: Rectangle {
                  Layout.fillWidth: true; height: 28; color: Colors.highlightLight; radius: 6
                  Text { anchors.centerIn: parent; text: modelData && modelData.label ? modelData.label : ""; color: Colors.text; font.pixelSize: 12; font.weight: Font.Medium }
                  MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: parent.color = Colors.highlight
                    onExited: parent.color = Colors.highlightLight
                    onClicked: {
                      var label = modelData && modelData.label ? modelData.label.toLowerCase() : "";
                      if (label.includes("reply")) notifItem.isReplying = true;
                      else if (modelData) { modelData.invoke(); notifItem.notification.dismiss(); }
                    }
                  }
                }
              }

              // Dismiss Action
              Rectangle {
                Layout.preferredWidth: 32; height: 28; color: Colors.highlightLight; radius: 6
                Text { anchors.centerIn: parent; text: "󰅖"; color: Colors.error; font.family: Colors.fontMono; font.pixelSize: 14 }
                MouseArea {
                  anchors.fill: parent; hoverEnabled: true
                  onEntered: parent.color = Colors.highlight
                  onExited: parent.color = Colors.highlightLight
                  onClicked: notifItem.notification.dismiss()
                }
              }
            }
          }
        }
      }

      // Archive Section
      Column {
        width: parent.width; spacing: 8
        visible: root.manager && root.manager.archivedNotifications.length > 0

        RowLayout {
          width: parent.width
          Text { text: "ARCHIVE"; color: Colors.textDisabled; font.pixelSize: 10; font.weight: Font.Bold }
          Item { Layout.fillWidth: true }
          MouseArea {
            width: 40; height: 20
            Text { anchors.centerIn: parent; text: "Clear"; color: Colors.textDisabled; font.pixelSize: 10 }
            onClicked: if (root.manager) root.manager.clearArchive()
          }
        }

        Repeater {
          model: root.manager ? root.manager.archivedNotifications : null
          delegate: Rectangle {
            width: parent.width; height: 60; color: Colors.bgWidget; radius: 8; opacity: 0.7
            Row {
              anchors.fill: parent; anchors.margins: Colors.paddingSmall; spacing: 10
              Rectangle { width: 32; height: 32; color: "transparent"
                Text { anchors.centerIn: parent; text: "󰂚"; color: Colors.textDisabled; font.pixelSize: 20; font.family: Colors.fontMono }
              }
              Column {
                width: parent.width - 50; spacing: 2
                Text { text: modelData.summary; color: Colors.textSecondary; font.pixelSize: 12; font.weight: Font.Bold; elide: Text.ElideRight; width: parent.width }
                Text { text: modelData.body; color: Colors.textDisabled; font.pixelSize: 10; elide: Text.ElideRight; width: parent.width }
              }
            }
          }
        }
      }
    }
  }
}
