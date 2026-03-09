import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import "../services"

PanelWindow {
  id: root

  anchors {
    top: true
    right: true
  }
  margins.top: 40
  margins.right: 12

  implicitWidth: 350
  implicitHeight: col.implicitHeight
  color: "transparent"
  mask: Region {}

  property var manager: null

  ColumnLayout {
    id: col
    width: 350
    spacing: 10
    
    Repeater {
      model: root.manager ? root.manager.notifications : null
      
      delegate: Rectangle {
        id: notifDelegate
        visible: !modelData.dismissed && (!root.manager || !root.manager.dndEnabled || isUrgent)
        Layout.preferredWidth: 350
        Layout.preferredHeight: visible ? colMain.implicitHeight + 20 : 0
        
        // Use Colors singleton
        color: isUrgent ? Qt.rgba(Colors.error.r, Colors.error.g, Colors.error.b, 0.8) : Colors.bgGlass
        border.color: isUrgent ? Colors.error : Colors.border
        border.width: isUrgent ? 2 : 1
        radius: Colors.radiusLarge
        clip: true

        property bool isReplying: false
        property bool isUrgent: modelData.urgency === Notifications.Critical

        // Pulse animation for urgent notifications
        SequentialAnimation on border.color {
          running: notifDelegate.isUrgent
          loops: Animation.Infinite
          ColorAnimation { from: Colors.error; to: "#ff0000"; duration: 800 }
          ColorAnimation { from: "#ff0000"; to: Colors.error; duration: 800 }
        }

        Column {
          id: colMain
          width: parent.width
          spacing: 10
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.verticalCenter: parent.verticalCenter

          Row {
            width: parent.width - 24
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            Image {
              width: 40; height: 40
              source: modelData.appIcon ? (modelData.appIcon.startsWith("/") ? "file://" + modelData.appIcon : "image://icon/" + modelData.appIcon) : ""
              fillMode: Image.PreserveAspectFit
              visible: modelData.appIcon !== ""
              
              Rectangle {
                anchors.fill: parent; color: "transparent"; visible: parent.status !== Image.Ready
                Text { anchors.centerIn: parent; text: "󰂚"; color: Colors.fgMain; font.pixelSize: 24; font.family: Colors.fontMono }
              }
            }

            Column {
              width: parent.width - 52; spacing: 4
              Text { text: modelData.appName || "Notification"; color: Colors.textSecondary; font.pixelSize: 10; font.weight: Font.Bold; font.capitalization: Font.AllUppercase }
              Text { text: modelData.summary; color: Colors.fgMain; font.pixelSize: 13; font.weight: Font.Bold; width: parent.width; wrapMode: Text.Wrap }
              Text { text: modelData.body; color: Colors.textSecondary; font.pixelSize: 11; width: parent.width; wrapMode: Text.Wrap; visible: modelData.body !== "" }
            }
          }

          // Large Image Preview
          Rectangle {
            width: parent.width - 24
            height: 180
            anchors.horizontalCenter: parent.horizontalCenter
            visible: modelData.image !== ""
            radius: 8
            clip: true
            color: "transparent"
            border.color: Colors.border
            border.width: 1

            Image {
              anchors.fill: parent
              source: modelData.image || ""
              fillMode: Image.PreserveAspectCrop
            }
          }

          // Reply Input
          Rectangle {
            width: parent.width - 24; height: 36; anchors.horizontalCenter: parent.horizontalCenter; color: Colors.highlightLight; radius: 8; visible: notifDelegate.isReplying
            border.color: replyInput.activeFocus ? Colors.primary : "transparent"; border.width: 1
            TextInput {
              id: replyInput; anchors.fill: parent; anchors.margins: 10; verticalAlignment: Text.AlignVCenter; color: Colors.fgMain; font.pixelSize: 12
              Keys.onReturnPressed: { modelData.invoke(replyInput.text); notifDelegate.modelData.dismiss(); }
              Keys.onEscapePressed: notifDelegate.isReplying = false
            }
            Text { anchors.fill: parent; anchors.leftMargin: 10; verticalAlignment: Text.AlignVCenter; text: "Type a reply..."; color: Colors.fgDim; font.pixelSize: 12; visible: !replyInput.text && !replyInput.activeFocus }
          }

          // Actions
          Row {
            width: parent.width - 24; anchors.horizontalCenter: parent.horizontalCenter; spacing: 8; visible: modelData.actions.count > 0 && !notifDelegate.isReplying
            Repeater {
              model: modelData.actions
              delegate: Rectangle {
                width: (parent.width - (modelData.actions.count - 1) * 8) / modelData.actions.count
                height: 30; color: Colors.highlightLight; radius: 6; border.color: Colors.border
                Text { anchors.centerIn: parent; text: modelData.label; color: Colors.fgMain; font.pixelSize: 11 }
                MouseArea {
                  anchors.fill: parent; hoverEnabled: true
                  onEntered: parent.color = Colors.surface; onExited: parent.color = Colors.highlightLight
                  onClicked: {
                    if (modelData.label.toLowerCase().includes("reply")) { notifDelegate.isReplying = true; replyInput.forceActiveFocus(); }
                    else { modelData.invoke(); notifDelegate.modelData.dismiss(); }
                  }
                }
              }
            }
          }
          Item { width: 1; height: 1 } 
        }
        
        Timer {
          id: dismissTimer
          interval: 5000
          running: !notifDelegate.isReplying && !notifDelegate.modelData.dismissed && !notifDelegate.isUrgent
          onTriggered: modelData.dismiss()
        }
      }
    }
  }
}
