import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Services.Mpris
import "../../services"
import "../../widgets" as SharedWidgets

Rectangle {
  id: root

  property var notification: null
  property bool isPopup: false
  property bool showContent: true
  property real swipeOffset: 0
  property bool isSwiping: false
  property bool isUrgent: !!(notification && notification.urgency === NotificationUrgency.Critical)
  property bool isReplying: false
  readonly property bool isHovered: delegateMouseArea.containsMouse

  signal dismissRequested()
  signal actionInvoked(var action)
  signal replySent(string text)

  function _openScreenshotEditor() {
    if (!root.notification || !root.notification.screenshotPath) return;
    var editor = Config.screenshotEditor !== "none" ? Config.screenshotEditor : "swappy";
    var path = root.notification.screenshotPath;
    if (editor === "satty")
      Quickshell.execDetached(["satty", "--filename", path]);
    else
      Quickshell.execDetached(["swappy", "-f", path]);
    root.dismissRequested();
  }

  width: parent.width
  height: root.showContent ? colMain.implicitHeight + Appearance.paddingLarge * 2 : 0
  opacity: root.showContent ? 1.0 : 0.0
  visible: height > 0

  color: root.isUrgent ? Colors.errorLight : Colors.cardSurface
  border.color: root.isUrgent ? Colors.error : Colors.border
  border.width: 1
  radius: Appearance.radiusLarge
  clip: true

  Behavior on height { NumberAnimation { duration: Appearance.durationNormal; easing.type: Easing.OutCubic } }
  Behavior on opacity { NumberAnimation { duration: Appearance.durationNormal } }

  SharedWidgets.InnerHighlight { highlightOpacity: root.isUrgent ? 0.25 : 0.12 }

  SequentialAnimation on border.color {
    running: root.isUrgent
    loops: Animation.Infinite
    ColorAnimation { from: Colors.error; to: Qt.lighter(Colors.error, 1.4); duration: Appearance.durationLong }
    ColorAnimation { from: Qt.lighter(Colors.error, 1.4); to: Colors.error; duration: Appearance.durationLong }
  }

  property var mprisPlayer: {
    if (!notification || !notification.appName)
      return null;
    var app = notification.appName.toLowerCase();
    for (var i = 0; i < Mpris.players.length; i++) {
      var player = Mpris.players[i];
      if ((player.identity || "").toLowerCase().includes(app) || player.desktopEntry === app)
        return player;
    }
    return null;
  }

  readonly property string previewImageSource: {
    var source = String((notification && notification.image) || "");
    if (source === "")
      return "";
    if (source.startsWith("/") || source.startsWith("file://")
        || source.startsWith("data:") || source.startsWith("image://")
        || source.startsWith("http://") || source.startsWith("https://")) {
      return source;
    }
    return "";
  }

  default property alias overlays: overlaySlot.data

  ColumnLayout {
    id: colMain
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Appearance.paddingLarge
    spacing: Appearance.spacingM

    RowLayout {
      Layout.fillWidth: true
      spacing: Appearance.spacingM

      SharedWidgets.AppIcon {
        iconName: notification ? notification.appIcon : ""
        appName: notification ? notification.appName : ""
        iconSize: 38
        fallbackIcon: "󰂚"
        visible: !!notification && notification.appIcon !== ""
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Text {
          text: notification ? (notification.appName || "Notification") : ""
          color: root.isUrgent ? Colors.error : Colors.textSecondary
          font.pixelSize: Appearance.fontSizeXXS
          font.weight: Font.Black
          font.capitalization: Font.AllUppercase
          font.letterSpacing: Appearance.letterSpacingWide
        }

        Text {
          text: notification ? notification.summary : ""
          color: Colors.text
          font.pixelSize: Appearance.fontSizeMedium
          font.weight: Font.Bold
          Layout.fillWidth: true
          elide: Text.ElideRight
        }
      }

      Text {
        visible: !root.isPopup && !!notification && !!notification._receivedAt
        text: notification && notification._receivedAt ? Qt.formatDateTime(notification._receivedAt, "HH:mm") : ""
        color: Colors.textDisabled
        font.pixelSize: Appearance.fontSizeXS
      }

      SharedWidgets.IconButton {
        icon: "dismiss.svg"
        size: 28
        iconSize: Appearance.fontSizeLarge
        iconColor: Colors.textDisabled
        stateColor: Colors.error
        tooltipText: "Dismiss"
        onClicked: root.dismissRequested()
      }
    }

    Text {
      Layout.fillWidth: true
      text: notification ? notification.body : ""
      color: Colors.textSecondary
      font.pixelSize: Appearance.fontSizeSmall
      wrapMode: Text.Wrap
      visible: !!notification && notification.body !== ""
      maximumLineCount: root.isPopup ? 3 : 10
      elide: Text.ElideRight
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 160
      visible: root.previewImageSource !== ""
      radius: Appearance.radiusMedium
      color: "#33000000"
      clip: true

      Image {
        anchors.fill: parent
        source: root.previewImageSource
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
      }
    }

    Rectangle {
      Layout.fillWidth: true
      height: 44
      radius: Appearance.radiusMedium
      color: Colors.highlightLight
      visible: root.mprisPlayer !== null

      RowLayout {
        anchors.fill: parent
        anchors.margins: Appearance.spacingS
        spacing: Appearance.spacingM

        Item { Layout.fillWidth: true }

        SharedWidgets.IconButton {
          icon: "previous.svg"
          iconSize: Appearance.fontSizeLarge
          tooltipText: "Previous track"
          onClicked: if (root.mprisPlayer) root.mprisPlayer.previous()
        }

        SharedWidgets.IconButton {
          size: 34
          color: Colors.primary
          icon: root.mprisPlayer && root.mprisPlayer.playbackState === Mpris.Playing ? "󰏤" : "󰐊"
          iconColor: Colors.background
          tooltipText: root.mprisPlayer && root.mprisPlayer.playbackState === Mpris.Playing ? "Pause" : "Play"
          onClicked: if (root.mprisPlayer) root.mprisPlayer.playPause()
        }

        SharedWidgets.IconButton {
          icon: "next.svg"
          iconSize: Appearance.fontSizeLarge
          tooltipText: "Next track"
          onClicked: if (root.mprisPlayer) root.mprisPlayer.next()
        }

        Item { Layout.fillWidth: true }
      }
    }

    Rectangle {
      Layout.fillWidth: true
      height: 40
      radius: Appearance.radiusSmall
      color: Colors.highlightLight
      visible: root.isReplying
      border.color: replyInput.activeFocus ? Colors.primary : Colors.border
      border.width: 1

      TextInput {
        id: replyInput
        anchors.fill: parent
        anchors.margins: Appearance.paddingSmall
        verticalAlignment: Text.AlignVCenter
        color: Colors.text
        font.pixelSize: Appearance.fontSizeSmall
        onVisibleChanged: if (!visible && activeFocus) focus = false
        Keys.onReturnPressed: {
          root.replySent(text);
          root.isReplying = false;
        }
        Keys.onEscapePressed: root.isReplying = false
      }

      Text {
        anchors.fill: parent
        anchors.leftMargin: Appearance.paddingSmall
        verticalAlignment: Text.AlignVCenter
        text: "Type a reply..."
        color: Colors.textDisabled
        font.pixelSize: Appearance.fontSizeSmall
        visible: !replyInput.text && !replyInput.activeFocus
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Appearance.spacingS
      visible: !root.isReplying && !!notification && !!notification.actions && notification.actions.count > 0

      Repeater {
        model: notification ? notification.actions : null

        delegate: SharedWidgets.Button {
          Layout.fillWidth: true
          Layout.preferredHeight: 32
          text: modelData.text || ""
          fontSize: Appearance.fontSizeSmall
          onClicked: {
            var label = (modelData.text || "").toLowerCase();
            if (label.includes("reply")) {
              root.isReplying = true;
              replyInput.forceActiveFocus();
            } else {
              root.actionInvoked(modelData);
            }
          }
        }
      }
    }

    // Screenshot-specific actions
    RowLayout {
      Layout.fillWidth: true
      spacing: Appearance.spacingS
      visible: !!(root.notification && root.notification.screenshotPath)

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 32
        radius: Appearance.radiusMedium
        color: editBtnMouse.containsMouse ? Colors.primaryFaint : Colors.cardSurface
        border.color: editBtnMouse.containsMouse ? Colors.primaryRing : Colors.border
        border.width: 1

        Row {
          anchors.centerIn: parent
          spacing: Appearance.spacingXS

          SharedWidgets.SvgIcon {
            source: "edit.svg"
            color: Colors.text
            size: Appearance.fontSizeSmall
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            text: "Edit in " + (Config.screenshotEditor === "satty" ? "Satty" : "Swappy")
            color: Colors.text
            font.pixelSize: Appearance.fontSizeSmall
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        MouseArea {
          id: editBtnMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root._openScreenshotEditor()
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 32
        radius: Appearance.radiusMedium
        color: folderBtnMouse.containsMouse ? Colors.primaryFaint : Colors.cardSurface
        border.color: folderBtnMouse.containsMouse ? Colors.primaryRing : Colors.border
        border.width: 1

        Row {
          anchors.centerIn: parent
          spacing: Appearance.spacingXS

          SharedWidgets.SvgIcon {
            source: "folder-open.svg"
            color: Colors.text
            size: Appearance.fontSizeSmall
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            text: "Open Folder"
            color: Colors.text
            font.pixelSize: Appearance.fontSizeSmall
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        MouseArea {
          id: folderBtnMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            var dir = root.notification.screenshotPath.substring(0, root.notification.screenshotPath.lastIndexOf("/"));
            Quickshell.execDetached(["xdg-open", dir]);
            root.dismissRequested();
          }
        }
      }
    }
  }

  Item {
    id: overlaySlot
    anchors.fill: parent
    z: 1
  }

  MouseArea {
    id: delegateMouseArea
    anchors.fill: parent
    z: -1
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    hoverEnabled: true
    onClicked: function(mouse) {
      if (mouse.button === Qt.RightButton) {
        root.dismissRequested();
      } else if (mouse.button === Qt.LeftButton && root.isPopup && root.notification && root.notification.screenshotPath) {
        root._openScreenshotEditor();
      }
    }
    onPressed: function(mouse) {
      if (mouse.button === Qt.LeftButton && root.isPopup) {
        root._swipeStartX = mouse.x;
        root.isSwiping = true;
      }
    }
    onPositionChanged: function(mouse) {
      if (root.isSwiping) {
        var delta = mouse.x - root._swipeStartX;
        root.swipeOffset = Math.max(0, delta);
      }
    }
    onReleased: function(mouse) {
      if (root.isSwiping) {
        root.isSwiping = false;
        var threshold = Math.max(80, root.width * 0.35);
        if (root.swipeOffset >= threshold) {
          root.dismissRequested();
        } else {
          root.swipeOffset = 0;
        }
      }
    }

    property real _swipeStartX: 0
  }
}
