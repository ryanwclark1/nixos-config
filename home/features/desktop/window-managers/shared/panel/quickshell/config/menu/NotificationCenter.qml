import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import "../modules"
import "../notifications"

PanelWindow {
  id: root
  
  anchors {
    top: true
    right: true
    bottom: true
  }
  margins.top: 40
  margins.right: 12
  margins.bottom: 60
  
  implicitWidth: 350
  color: "transparent"
  mask: Region {
  }
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  WlrLayershell.namespace: "quickshell"

  property var manager: null
  property bool showContent: false
  property string searchQuery: ""
  visible: showContent || sidebarContent.x < 350

  // Ensure focus is grabbed when shown
  onShowContentChanged: {
    if (showContent) {
      notifList.focus = true;
    }
  }

  Rectangle {
    id: sidebarContent
    width: 350
    height: parent.height
    color: "#a6101014"
    border.color: "#33ffffff"
    border.width: 1
    radius: 16

    x: root.showContent ? 0 : 360
    opacity: root.showContent ? 1.0 : 0.0
    
    Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 250 } }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 24
      spacing: 20

      RowLayout {
        Layout.fillWidth: true
        Text {
          text: "Notifications"
          color: "#ffffff"
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
            color: root.manager && root.manager.dndEnabled ? "#e57373" : "#1affffff"
            radius: 6
            Text {
              anchors.centerIn: parent
              text: root.manager && root.manager.dndEnabled ? "󰂛 DND" : "󰂚 DND"
              color: "#ffffff"; font.pixelSize: 11; font.weight: Font.Medium; font.family: "JetBrainsMono Nerd Font"
            }
          }
          onClicked: if (root.manager) root.manager.dndEnabled = !root.manager.dndEnabled
        }
        
        // Clear all
        MouseArea {
          width: 70; height: 28
          Rectangle {
            anchors.fill: parent; color: "#1affffff"; radius: 6
            Text { anchors.centerIn: parent; text: "Clear All"; color: "#aaaaaa"; font.pixelSize: 11; font.weight: Font.Medium }
          }
          onClicked: if (root.manager) { for (var i = 0; i < root.manager.notifications.count; i++) root.manager.notifications.get(i).dismiss(); }
        }
      }

      WeatherWidget {}

      Calendar {
         visible: root.searchQuery === ""
      }

      // Search Bar
      Rectangle {
        Layout.fillWidth: true; height: 40; color: "#1affffff"; radius: 8
        border.color: searchInput.activeFocus ? Colors.primary : "transparent"; border.width: 1
        RowLayout {
          anchors.fill: parent; anchors.margins: 10; spacing: 10
          Text { text: ""; color: Colors.textDisabled; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14 }
          TextInput {
            id: searchInput; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter
            color: Colors.text; font.pixelSize: 12
            onTextChanged: root.searchQuery = text
          }
          Text { 
            anchors.fill: parent; anchors.leftMargin: 35; verticalAlignment: Text.AlignVCenter
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

        function toggleGroup(name) {
          var groups = collapsedGroups;
          groups[name] = !groups[name];
          collapsedGroups = groups;
          // Force refresh visible items
          notifList.model = null;
          notifList.model = root.manager.notifications;
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
                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14 
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
              onClicked: if (root.manager) { for (var i = root.manager.notifications.count - 1; i >= 0; i--) { var n = root.manager.notifications.get(i); if (n.appName === section) n.dismiss(); } }
            }
          }
        }

        delegate: Rectangle {
          id: notifItem
          property bool isCollapsed: notifList.collapsedGroups[modelData.appName] || false
          
          visible: matchesSearch && !isCollapsed
          width: notifList.width
          height: visible ? colItem.height + (isReplying ? 50 : 20) : 0
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
            width: parent.width - 24; anchors.centerIn: parent; spacing: 10

            RowLayout {
              width: parent.width; spacing: 12
              Image {
                Layout.preferredWidth: 32; Layout.preferredHeight: 32
                source: modelData.appIcon ? (modelData.appIcon.startsWith("/") ? "file://" + modelData.appIcon : "image://icon/" + modelData.appIcon) : ""
                visible: modelData.appIcon !== ""
                Rectangle { anchors.fill: parent; color: "transparent"; visible: parent.status !== Image.Ready; Text { anchors.centerIn: parent; text: "󰂚"; color: Colors.text; font.pixelSize: 20; font.family: "JetBrainsMono Nerd Font" } }
              }

              ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                RowLayout {
                  Layout.fillWidth: true
                  Text {
                    text: modelData.summary; color: Colors.text; font.pixelSize: 13; font.weight: Font.Bold
                    Layout.fillWidth: true; elide: Text.ElideRight
                  }
                  Text {
                    text: Qt.formatDateTime(new Date(), "HH:mm"); color: Colors.textDisabled; font.pixelSize: 10
                  }
                }
                Text { text: modelData.body; color: Colors.textSecondary; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.Wrap; visible: modelData.body !== "" }
              }
            }

            // Media Controls (if applicable)
            Rectangle {
              width: parent.width; height: 40; radius: 8; color: Colors.highlightLight; visible: mprisPlayer !== null
              RowLayout {
                anchors.fill: parent; anchors.margins: 8; spacing: 15
                Item { Layout.fillWidth: true }
                MouseArea { width: 24; height: 24; Text { anchors.centerIn: parent; text: "󰒮"; color: Colors.text; font.family: "JetBrainsMono Nerd Font" } onClicked: mprisPlayer.previous() }
                MouseArea { 
                  width: 32; height: 32
                  Rectangle { anchors.fill: parent; radius: 16; color: Colors.primary }
                  Text { anchors.centerIn: parent; text: mprisPlayer && mprisPlayer.playbackState === Mpris.Playing ? "󰏤" : "󰐊"; color: Colors.background; font.family: "JetBrainsMono Nerd Font" }
                  onClicked: mprisPlayer.playPause()
                }
                MouseArea { width: 24; height: 24; Text { anchors.centerIn: parent; text: "󰒭"; color: Colors.text; font.family: "JetBrainsMono Nerd Font" } onClicked: mprisPlayer.next() }
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
              width: parent.width; height: 32; radius: 6; color: Colors.highlightLight; visible: isReplying
              TextInput {
                id: replyInput; anchors.fill: parent; anchors.margins: 8; verticalAlignment: Text.AlignVCenter
                color: Colors.text; font.pixelSize: 11; focus: isReplying
                Keys.onReturnPressed: { modelData.invoke(text); notifItem.isReplying = false; modelData.dismiss(); }
                Keys.onEscapePressed: notifItem.isReplying = false
              }
            }

            // Actions
            RowLayout {
              width: parent.width; spacing: 8; visible: !isReplying
              
              // Dynamic Actions from Notification
              Repeater {
                model: modelData.actions
                delegate: Rectangle {
                  Layout.fillWidth: true; height: 28; color: Colors.highlightLight; radius: 6
                  Text { anchors.centerIn: parent; text: modelData.label; color: Colors.text; font.pixelSize: 10; font.weight: Font.Medium }
                  MouseArea {
                    anchors.fill: parent; hoverEnabled: true
                    onEntered: parent.color = Colors.highlight; onExited: parent.color = Colors.highlightLight
                    onClicked: {
                      if (modelData.label.toLowerCase().includes("reply")) notifItem.isReplying = true;
                      else { modelData.invoke(); modelData.dismiss(); }
                    }
                  }
                }
              }
              
              // Archive Action
              Rectangle {
                Layout.preferredWidth: 32; height: 28; color: Colors.highlightLight; radius: 6
                Text { anchors.centerIn: parent; text: "󰅨"; color: Colors.textSecondary; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14 }
                MouseArea {
                  anchors.fill: parent; hoverEnabled: true
                  onEntered: parent.color = Colors.highlight; onExited: parent.color = Colors.highlightLight
                  onClicked: {
                    // Logic to archive: dismiss it, but it's already in tracked archive
                    modelData.dismiss();
                  }
                }
              }

              // Dismiss Action
              Rectangle {
                Layout.preferredWidth: 32; height: 28; color: Colors.highlightLight; radius: 6
                Text { anchors.centerIn: parent; text: "󰅖"; color: Colors.error; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14 }
                MouseArea {
                  anchors.fill: parent; hoverEnabled: true
                  onEntered: parent.color = Colors.highlight; onExited: parent.color = Colors.highlightLight
                  onClicked: modelData.dismiss()
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
          Text { text: "ARCHIVE"; color: "#666666"; font.pixelSize: 10; font.weight: Font.Bold }
          Item { Layout.fillWidth: true }
          MouseArea {
            width: 40; height: 20
            Text { anchors.centerIn: parent; text: "Clear"; color: "#666666"; font.pixelSize: 10 }
            onClicked: if (root.manager) root.manager.clearArchive()
          }
        }

        Repeater {
          model: root.manager ? root.manager.archivedNotifications : null
          delegate: Rectangle {
            width: parent.width; height: 60; color: "#0dffffff"; radius: 8; opacity: 0.7
            Row {
              anchors.fill: parent; anchors.margins: 10; spacing: 10
              Rectangle { width: 32; height: 32; color: "transparent"
                Text { anchors.centerIn: parent; text: "󰂚"; color: "#666666"; font.pixelSize: 20; font.family: "JetBrainsMono Nerd Font" }
              }
              Column {
                width: parent.width - 50; spacing: 2
                Text { text: modelData.summary; color: "#aaaaaa"; font.pixelSize: 12; font.weight: Font.Bold; elide: Text.ElideRight; width: parent.width }
                Text { text: modelData.body; color: "#888888"; font.pixelSize: 10; elide: Text.ElideRight; width: parent.width }
              }
            }
          }
        }
      }
    }
  }
}
