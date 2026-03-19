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

  width: parent.width
  height: root.showContent ? colMain.implicitHeight + Colors.paddingLarge * 2 : 0
  opacity: root.showContent ? 1.0 : 0.0
  visible: height > 0

  color: root.isUrgent ? Colors.errorLight : Colors.cardSurface
  border.color: root.isUrgent ? Colors.error : Colors.border
  border.width: 1
  radius: Colors.radiusLarge
  clip: true

  Behavior on height { NumberAnimation { duration: Colors.durationNormal; easing.type: Easing.OutCubic } }
  Behavior on opacity { NumberAnimation { duration: Colors.durationNormal } }

  SharedWidgets.InnerHighlight { highlightOpacity: root.isUrgent ? 0.25 : 0.12 }

  SequentialAnimation on border.color {
    running: root.isUrgent
    loops: Animation.Infinite
    ColorAnimation { from: Colors.error; to: Qt.lighter(Colors.error, 1.4); duration: Colors.durationLong }
    ColorAnimation { from: Qt.lighter(Colors.error, 1.4); to: Colors.error; duration: Colors.durationLong }
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
    anchors.margins: Colors.paddingLarge
    spacing: Colors.spacingM

    RowLayout {
      Layout.fillWidth: true
      spacing: Colors.spacingM

      SharedWidgets.AppIcon {
        iconName: notification ? notification.appIcon : ""
        appName: notification ? notification.appName : ""
        iconSize: 38
        fallbackIcon: "󰂚"
        visible: notification && notification.appIcon !== ""
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Text {
          text: notification ? (notification.appName || "Notification") : ""
          color: root.isUrgent ? Colors.error : Colors.textSecondary
          font.pixelSize: Colors.fontSizeXXS
          font.weight: Font.Black
          font.capitalization: Font.AllUppercase
          font.letterSpacing: Colors.letterSpacingWide
        }

        Text {
          text: notification ? notification.summary : ""
          color: Colors.text
          font.pixelSize: Colors.fontSizeMedium
          font.weight: Font.Bold
          Layout.fillWidth: true
          elide: Text.ElideRight
        }
      }

      Text {
        visible: !root.isPopup && notification && notification.time
        text: notification && notification.time ? Qt.formatDateTime(notification.time, "HH:mm") : ""
        color: Colors.textDisabled
        font.pixelSize: Colors.fontSizeXS
      }

      SharedWidgets.IconButton {
        icon: "󰅖"
        size: 28
        iconSize: Colors.fontSizeLarge
        iconColor: Colors.textDisabled
        stateColor: Colors.error
        onClicked: root.dismissRequested()
      }
    }

    Text {
      Layout.fillWidth: true
      text: notification ? notification.body : ""
      color: Colors.textSecondary
      font.pixelSize: Colors.fontSizeSmall
      wrapMode: Text.Wrap
      visible: notification && notification.body !== ""
      maximumLineCount: root.isPopup ? 3 : 10
      elide: Text.ElideRight
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: 160
      visible: root.previewImageSource !== ""
      radius: Colors.radiusMedium
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
      radius: Colors.radiusMedium
      color: Colors.highlightLight
      visible: root.mprisPlayer !== null

      RowLayout {
        anchors.fill: parent
        anchors.margins: Colors.spacingS
        spacing: Colors.spacingM

        Item { Layout.fillWidth: true }

        SharedWidgets.IconButton {
          icon: "󰒮"
          iconSize: Colors.fontSizeLarge
          onClicked: if (root.mprisPlayer) root.mprisPlayer.previous()
        }

        SharedWidgets.IconButton {
          size: 34
          color: Colors.primary
          icon: root.mprisPlayer && root.mprisPlayer.playbackState === Mpris.Playing ? "󰏤" : "󰐊"
          iconColor: Colors.background
          onClicked: if (root.mprisPlayer) root.mprisPlayer.playPause()
        }

        SharedWidgets.IconButton {
          icon: "󰒭"
          iconSize: Colors.fontSizeLarge
          onClicked: if (root.mprisPlayer) root.mprisPlayer.next()
        }

        Item { Layout.fillWidth: true }
      }
    }

    Rectangle {
      Layout.fillWidth: true
      height: 40
      radius: Colors.radiusSmall
      color: Colors.highlightLight
      visible: root.isReplying
      border.color: replyInput.activeFocus ? Colors.primary : Colors.border
      border.width: 1

      TextInput {
        id: replyInput
        anchors.fill: parent
        anchors.margins: Colors.paddingSmall
        verticalAlignment: Text.AlignVCenter
        color: Colors.text
        font.pixelSize: Colors.fontSizeSmall
        onVisibleChanged: if (!visible && activeFocus) focus = false
        Keys.onReturnPressed: {
          root.replySent(text);
          root.isReplying = false;
        }
        Keys.onEscapePressed: root.isReplying = false
      }

      Text {
        anchors.fill: parent
        anchors.leftMargin: Colors.paddingSmall
        verticalAlignment: Text.AlignVCenter
        text: "Type a reply..."
        color: Colors.textDisabled
        font.pixelSize: Colors.fontSizeSmall
        visible: !replyInput.text && !replyInput.activeFocus
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: Colors.spacingS
      visible: !root.isReplying && notification && notification.actions && notification.actions.count > 0

      Repeater {
        model: notification ? notification.actions : null

        delegate: SharedWidgets.Button {
          Layout.fillWidth: true
          Layout.preferredHeight: 32
          text: modelData.label || ""
          fontSize: Colors.fontSizeSmall
          onClicked: {
            var label = (modelData.label || "").toLowerCase();
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
      if (mouse.button === Qt.RightButton)
        root.dismissRequested();
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
