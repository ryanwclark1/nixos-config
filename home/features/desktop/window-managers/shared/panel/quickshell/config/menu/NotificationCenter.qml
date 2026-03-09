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
  mask: Region {}
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  WlrLayershell.namespace: "quickshell"

  property var manager: null
  property bool showContent: false
  visible: true

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

      Calendar {}

      ListView {
        id: notifList
        Layout.fillWidth: true; Layout.fillHeight: true; spacing: 12; clip: true; focus: true
        highlightFollowsCurrentItem: true; keyNavigationEnabled: true
        model: root.manager ? root.manager.notifications : null

        section.property: "appName"
        section.criteria: ViewSection.FullString
        section.delegate: Rectangle {
          width: notifList.width; height: 30; color: "transparent"
          RowLayout {
            anchors.fill: parent; spacing: 10
            Text { text: section || "System"; color: "#aaaaaa"; font.pixelSize: 10; font.weight: Font.Bold; font.capitalization: Font.AllUppercase }
            Rectangle { Layout.fillWidth: true; height: 1; color: "#33ffffff" }
            MouseArea {
              width: 20; height: 20
              Text { anchors.centerIn: parent; text: "󰅖"; color: "#666666"; font.pixelSize: 12 }
              onClicked: if (root.manager) { for (var i = root.manager.notifications.count - 1; i >= 0; i--) { var n = root.manager.notifications.get(i); if (n.appName === section) n.dismiss(); } }
            }
          }
        }

        delegate: Rectangle {
          id: notifItem
          width: notifList.width
          height: colItem.height + (isReplying ? 50 : 20)
          color: ListView.isCurrentItem && notifList.activeFocus ? "#334caf50" : "#1affffff"
          radius: 10
          border.color: ListView.isCurrentItem && notifList.activeFocus ? "#4caf50" : "transparent"
          border.width: 1
          
          property bool isReplying: false

          Column {
            id: colItem
            width: parent.width - 20; anchors.centerIn: parent; spacing: 8

            Row {
              width: parent.width; spacing: 10
              Image {
                width: 32; height: 32; fillMode: Image.PreserveAspectFit
                source: modelData.appIcon ? (modelData.appIcon.startsWith("/") ? "file://" + modelData.appIcon : "image://icon/" + modelData.appIcon) : ""
                visible: modelData.appIcon !== ""
                Rectangle { anchors.fill: parent; color: "transparent"; visible: parent.status !== Image.Ready; Text { anchors.centerIn: parent; text: "󰂚"; color: "#e6e6e6"; font.pixelSize: 20; font.family: "JetBrainsMono Nerd Font" } }
              }

              Column {
                width: parent.width - 42; spacing: 2
                Row {
                  width: parent.width
                  Text {
                    text: modelData.summary
                    color: "#e6e6e6"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    width: parent.width - 20
                    elide: Text.ElideRight
                  }
                  MouseArea {
                    width: 16
                    height: 16
                    Text {
                      anchors.centerIn: parent
                      text: "󰅖"
                      color: "#666666"
                    }
                    onClicked: modelData.dismiss()
                  }
                }
                Text { text: modelData.body; color: "#cccccc"; font.pixelSize: 11; width: parent.width; wrapMode: Text.Wrap; visible: modelData.body !== "" }
              }
            }

            // Large Image Preview
            Rectangle {
              width: parent.width
              height: 150
              visible: modelData.image !== ""
              radius: 8
              clip: true
              color: "transparent"
              border.color: "#33ffffff"
              border.width: 1

              Image {
                anchors.fill: parent
                source: modelData.image || ""
                fillMode: Image.PreserveAspectCrop
              }
            }

            // Inline Reply Area
            Rectangle {
              width: parent.width; height: 32; radius: 6; color: "#1affffff"; visible: isReplying
              TextInput {
                id: replyInput; anchors.fill: parent; anchors.margins: 8; verticalAlignment: Text.AlignVCenter
                color: "#ffffff"; font.pixelSize: 11; focus: isReplying
                Keys.onReturnPressed: { modelData.invoke(text); notifItem.isReplying = false; modelData.dismiss(); }
                Keys.onEscapePressed: notifItem.isReplying = false
              }
            }

            // Actions
            Row {
              width: parent.width; spacing: 8; visible: modelData.actions.count > 0 && !isReplying
              Repeater {
                model: modelData.actions
                delegate: Rectangle {
                  width: (parent.width - (modelData.actions.count - 1) * 8) / modelData.actions.count
                  height: 24; color: "#3d3e42"; radius: 4
                  Text { anchors.centerIn: parent; text: modelData.label; color: "#e6e6e6"; font.pixelSize: 10 }
                  MouseArea {
                    anchors.fill: parent
                    onClicked: {
                      if (modelData.label.toLowerCase().includes("reply")) notifItem.isReplying = true;
                      else { modelData.invoke(); modelData.dismiss(); }
                    }
                  }
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
