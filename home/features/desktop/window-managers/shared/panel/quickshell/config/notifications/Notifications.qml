import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import "../services"

PanelWindow {
  id: root

  anchors {
    top: true
    right: true
  }
  margins.top: 40
  margins.right: 12

  implicitWidth: Config.notifWidth
  implicitHeight: col.implicitHeight
  color: "transparent"
  mask: Region {
    item: col
  }

  property var manager: null

  function resolveNotificationIcon(iconName) {
    if (!iconName) return "";
    if (iconName.startsWith("/")) return "file://" + iconName;
    var normalized = iconName.toLowerCase();
    if (normalized === "alacritty" || normalized === "org.alacritty.alacritty") {
      var terminalFallbacks = ["utilities-terminal", "terminal", "org.gnome.Console"];
      for (var i = 0; i < terminalFallbacks.length; ++i) {
        var fallbackResolved = Quickshell.iconPath(terminalFallbacks[i]);
        if (fallbackResolved) return fallbackResolved.startsWith("file://") ? fallbackResolved : "file://" + fallbackResolved;
      }
      return "";
    }
    var resolved = Quickshell.iconPath(iconName);
    if (resolved) return resolved.startsWith("file://") ? resolved : "file://" + resolved;
    return "";
  }

  ColumnLayout {
    id: col
    width: Config.notifWidth
    spacing: 10
    
    Repeater {
      model: root.manager ? root.manager.notifications : null
      
      delegate: Rectangle {
        id: notifDelegate
        property var notification: modelData || null
        visible: notification && !notification.dismissed && (!root.manager || !root.manager.dndEnabled || isUrgent)
        Layout.preferredWidth: Config.notifWidth
        Layout.preferredHeight: visible ? colMain.implicitHeight + 20 : 0
        
        // Entrance animation properties
        property real entranceProgress: 0
        x: (1.0 - entranceProgress) * 100
        opacity: entranceProgress

        Component.onCompleted: entranceAnim.start()
        NumberAnimation { id: entranceAnim; target: notifDelegate; property: "entranceProgress"; from: 0; to: 1.0; duration: 500; easing.type: Easing.OutBack }

        // Use Colors singleton
        color: isUrgent ? Colors.withAlpha(Colors.error, 0.8) : Colors.bgGlass
        border.color: isUrgent ? Colors.error : Colors.border
        border.width: isUrgent ? 2 : 1
        radius: Colors.radiusLarge
        clip: true

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.RightButton
          onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton && notifDelegate.notification) {
              notifDelegate.notification.dismiss();
            }
          }
        }

        property bool isReplying: false
        property bool isUrgent: modelData.urgency === Notifications.Critical

        // Pulse animation for urgent notifications
        SequentialAnimation on border.color {
          running: notifDelegate.isUrgent
          loops: Animation.Infinite
          ColorAnimation { from: Colors.error; to: Qt.lighter(Colors.error, 1.4); duration: 800 }
          ColorAnimation { from: Qt.lighter(Colors.error, 1.4); to: Colors.error; duration: 800 }
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
              width: 44; height: 44
              source: root.resolveNotificationIcon(modelData.appIcon)
              fillMode: Image.PreserveAspectFit
              visible: modelData.appIcon !== ""
              
              Rectangle {
                anchors.fill: parent; color: "transparent"; visible: parent.status !== Image.Ready
                Text { anchors.centerIn: parent; text: "󰂚"; color: Colors.fgMain; font.pixelSize: 24; font.family: Colors.fontMono }
              }
            }

            Column {
              width: parent.width - 52; spacing: 4
              Text { text: modelData.appName || "Notification"; color: Colors.textSecondary; font.pixelSize: 12; font.weight: Font.Bold; font.capitalization: Font.AllUppercase }
              Text { text: modelData.summary; color: Colors.fgMain; font.pixelSize: 17; font.weight: Font.Bold; width: parent.width; wrapMode: Text.Wrap }
              Text { text: modelData.body; color: Colors.textSecondary; font.pixelSize: 14; width: parent.width; wrapMode: Text.Wrap; visible: modelData.body !== "" }
            }

            MouseArea {
              width: 32
              height: 32
              hoverEnabled: true
              Rectangle {
                anchors.fill: parent
                radius: 16
                color: parent.containsMouse ? Colors.highlightLight : "transparent"
              }
              Text {
                anchors.centerIn: parent
                text: "󰅖"
                color: Colors.error
                font.pixelSize: 18
                font.family: Colors.fontMono
              }
              onClicked: notifDelegate.notification.dismiss()
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
            width: parent.width - 24; height: 40; radius: 8
            anchors.horizontalCenter: parent.horizontalCenter
            color: Colors.highlightLight
            visible: notifDelegate.isReplying
            border.color: replyInput.activeFocus ? Colors.primary : "transparent"
            border.width: 1
            TextInput {
              id: replyInput
              anchors.fill: parent; anchors.margins: Colors.paddingSmall
              verticalAlignment: Text.AlignVCenter
              color: Colors.fgMain; font.pixelSize: 14
              onVisibleChanged: if (!visible && activeFocus) focus = false
              Keys.onReturnPressed: { notifDelegate.notification.invoke(replyInput.text); notifDelegate.notification.dismiss(); }
              Keys.onEscapePressed: notifDelegate.isReplying = false
            }
            Text {
              anchors.fill: parent; anchors.leftMargin: 10
              verticalAlignment: Text.AlignVCenter
              text: "Type a reply..."; color: Colors.fgDim; font.pixelSize: 13
              visible: !replyInput.text && !replyInput.activeFocus
            }
          }

          // Actions
          Row {
            width: parent.width - 24; spacing: 8
            anchors.horizontalCenter: parent.horizontalCenter
            visible: notifDelegate.notification && notifDelegate.notification.actions &&
                     notifDelegate.notification.actions.count > 0 && !notifDelegate.isReplying
            Repeater {
              model: notifDelegate.notification ? notifDelegate.notification.actions : null
              delegate: Rectangle {
                width: {
                  var actionCount = notifDelegate.notification && notifDelegate.notification.actions
                    ? notifDelegate.notification.actions.count
                    : 1;
                  return (parent.width - (actionCount - 1) * 8) / actionCount;
                }
                height: 34; color: Colors.highlightLight; radius: 6; border.color: Colors.border
                Text { anchors.centerIn: parent; text: modelData && modelData.label ? modelData.label : ""; color: Colors.fgMain; font.pixelSize: 13 }
                MouseArea {
                  anchors.fill: parent; hoverEnabled: true
                  onEntered: parent.color = Colors.surface
                  onExited: parent.color = Colors.highlightLight
                  onClicked: {
                    var label = modelData && modelData.label ? modelData.label.toLowerCase() : "";
                    if (label.includes("reply")) { notifDelegate.isReplying = true; replyInput.forceActiveFocus(); }
                    else if (modelData) { modelData.invoke(); notifDelegate.notification.dismiss(); }
                  }
                }
              }
            }
          }

          Rectangle {
            width: parent.width - 24
            height: 36
            anchors.horizontalCenter: parent.horizontalCenter
            radius: 8
            color: Colors.highlightLight
            visible: !notifDelegate.isReplying

            Text {
              anchors.centerIn: parent
              text: "Dismiss"
              color: Colors.error
              font.pixelSize: 14
              font.weight: Font.DemiBold
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              onEntered: parent.color = Colors.surface
              onExited: parent.color = Colors.highlightLight
              onClicked: if (notifDelegate.notification) notifDelegate.notification.dismiss()
            }
          }

        }
        
        Timer {
          id: dismissTimer
          interval: Config.popupTimer
          running: notifDelegate.notification && !notifDelegate.isReplying
                   && !notifDelegate.notification.dismissed && !notifDelegate.isUrgent
          onTriggered: if (notifDelegate.notification) notifDelegate.notification.dismiss()
        }
      }
    }
  }
}
