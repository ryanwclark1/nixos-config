import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Services.Mpris
import Quickshell.Wayland
import "../modules"
import "../notifications"
import "../services"
import "../widgets" as SharedWidgets

PanelWindow {
  id: root

  property string surfaceEdge: "right"
  property int panelWidth: Config.controlCenterWidth
  property int panelHeight: 640
  property real panelX: 0
  readonly property var edgeMargins: Config.reservedEdgesForScreen(screen, "")
  property int reservedTop: edgeMargins.top
  property int reservedRight: edgeMargins.right
  property int reservedBottom: edgeMargins.bottom
  property int reservedLeft: edgeMargins.left
  anchors {
    top: surfaceEdge === "right" || surfaceEdge === "left" || surfaceEdge === "top"
    right: surfaceEdge === "right"
    bottom: surfaceEdge === "right" || surfaceEdge === "left" || surfaceEdge === "bottom"
    left: surfaceEdge === "left" || surfaceEdge === "top" || surfaceEdge === "bottom"
  }
  margins.top: surfaceEdge === "right" || surfaceEdge === "left" || surfaceEdge === "top" ? reservedTop : 0
  margins.right: surfaceEdge === "right" ? reservedRight : 0
  margins.bottom: surfaceEdge === "right" || surfaceEdge === "left" || surfaceEdge === "bottom" ? reservedBottom : 0
  margins.left: surfaceEdge === "left" ? reservedLeft : ((surfaceEdge === "top" || surfaceEdge === "bottom") ? panelX : 0)

  implicitWidth: panelWidth
  implicitHeight: surfaceEdge === "top" || surfaceEdge === "bottom" ? panelHeight : 0
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
  visible: showContent || ncSlideAnim.running || ncFadeAnim.running

  // Ensure focus is grabbed when shown
  onShowContentChanged: {
    if (showContent) {
      Qt.callLater(function() {
        if (root.showContent && searchInput)
          searchInput.forceActiveFocus();
      });
    } else if (searchInput && searchInput.activeFocus) {
      searchInput.focus = false;
    }
  }

  Rectangle {
    id: sidebarContent
    width: root.panelWidth
    height: root.surfaceEdge === "top" || root.surfaceEdge === "bottom" ? root.panelHeight : parent.height
    color: Colors.bgGlass
    border.color: Colors.border
    border.width: 1
    radius: Colors.radiusLarge

    x: {
      if (root.surfaceEdge === "right") return root.showContent ? 0 : root.panelWidth + 10;
      if (root.surfaceEdge === "left") return root.showContent ? 0 : -root.panelWidth - 10;
      return 0;
    }
    y: {
      if (root.surfaceEdge === "top") return root.showContent ? 0 : -height - 10;
      if (root.surfaceEdge === "bottom") return root.showContent ? 0 : height + 10;
      return 0;
    }
    opacity: root.showContent ? 1.0 : 0.0
    visible: opacity > 0

    Behavior on x { NumberAnimation { id: ncSlideAnim; duration: Colors.durationSlow; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: Colors.durationSlow; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { id: ncFadeAnim; duration: Colors.durationNormal } }
    layer.enabled: ncSlideAnim.running || ncFadeAnim.running
    Keys.onEscapePressed: root.closeRequested()

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Colors.paddingLarge
      spacing: Colors.spacingLG

      RowLayout {
        Layout.fillWidth: true
        Text {
          text: "Notifications"
          color: Colors.text
          font.pixelSize: Colors.fontSizeHuge
          font.weight: Font.DemiBold
          font.letterSpacing: Colors.letterSpacingTight
        }

        Item { Layout.fillWidth: true }

        // DND Toggle
        MouseArea {
          width: 80; height: 28
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          Rectangle {
            anchors.fill: parent
            color: parent.containsMouse
              ? (root.manager && root.manager.dndEnabled ? Qt.darker(Colors.error, 1.1) : Colors.highlightLight)
              : (root.manager && root.manager.dndEnabled ? Colors.error : Colors.highlight)
            radius: Colors.radiusXXS
            Behavior on color { ColorAnimation { duration: Colors.durationFast } }
            Text {
              anchors.centerIn: parent
              text: root.manager && root.manager.dndEnabled ? "󰂛 DND" : "󰂚 DND"
              color: Colors.text; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Medium; font.family: Colors.fontMono
            }
          }
          onClicked: if (root.manager) root.manager.dndEnabled = !root.manager.dndEnabled
        }

        // Clear all
        Rectangle {
          width: 70; height: 28; radius: Colors.radiusXXS
          color: Colors.highlight

          SharedWidgets.StateLayer {
            id: clearAllStateLayer
            hovered: clearAllHover.containsMouse
            pressed: clearAllHover.pressed
          }

          Text { anchors.centerIn: parent; text: "Clear All"; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Medium }

          MouseArea {
            id: clearAllHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => {
              clearAllStateLayer.burst(mouse.x, mouse.y);
              if (root.manager) { for (var i = root.manager.notifications.count - 1; i >= 0; i--) { var n = root.manager.notifications.get(i); if (n) n.dismiss(); } }
            }
          }
        }

        // Close button
        SharedWidgets.IconButton {
          size: 28; radius: Colors.radiusXXS
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
        Layout.fillWidth: true; height: 40; color: Colors.highlightLight; radius: Colors.radiusXS
        border.color: searchInput.activeFocus ? Colors.primary : "transparent"; border.width: 1
        RowLayout {
          anchors.fill: parent; anchors.margins: Colors.paddingSmall; spacing: Colors.paddingSmall
          Text { text: ""; color: Colors.textDisabled; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeLarge }
          TextInput {
            id: searchInput; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter
            color: Colors.text; font.pixelSize: Colors.fontSizeMedium
            onVisibleChanged: if (!visible && activeFocus) focus = false
            Keys.onEscapePressed: root.closeRequested()
            onTextChanged: root.searchQuery = text
          }
          Text {
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 35
            text: "Search notifications..."; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeMedium
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
          highlightFollowsCurrentItem: true; keyNavigationEnabled: true
          Keys.onEscapePressed: root.closeRequested()
          model: root.manager ? root.manager.notifications : null

        property var collapsedGroups: ({})

        add: Transition {
          NumberAnimation { property: "opacity"; from: 0; to: 1.0; duration: Colors.durationEmphasis; easing.type: Easing.OutCubic }
          NumberAnimation { property: "scale"; from: 0.9; to: 1.0; duration: Colors.durationEmphasis; easing.type: Easing.OutBack }
        }

        remove: Transition {
          NumberAnimation { property: "opacity"; to: 0; duration: Colors.durationSlow }
          NumberAnimation { property: "scale"; to: 0.9; duration: Colors.durationSlow }
        }

        displaced: Transition {
          NumberAnimation { properties: "x,y"; duration: Colors.durationSlow; easing.type: Easing.OutCubic }
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
            anchors.fill: parent; spacing: Colors.paddingSmall

            MouseArea {
              width: 20; height: 20
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              Text {
                anchors.centerIn: parent; text: isCollapsed ? "󰅂" : "󰅀"; color: Colors.primary
                font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeLarge
              }
              onClicked: notifList.toggleGroup(section)
            }

            Text {
              text: section || "System"
              color: Colors.text; font.pixelSize: Colors.fontSizeSmall; font.weight: Font.Bold
              font.capitalization: Font.AllUppercase; font.letterSpacing: Colors.letterSpacingWide
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Colors.border; opacity: 0.5 }

            // App Count Badge
            Rectangle {
              width: 20; height: 16; radius: Colors.radiusSmall; color: Colors.highlight
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
              Text { anchors.centerIn: parent; text: parent.sectionCount; color: Colors.primary; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold }
            }

            SharedWidgets.IconButton {
              size: 24; radius: Colors.radiusCard
              icon: "󰅖"; iconColor: Colors.textDisabled
              onClicked: {
                if (!root.manager) return;
                for (var i = root.manager.notifications.count - 1; i >= 0; i--) {
                  var n = root.manager.notifications.get(i);
                  if (n && n.appName === section) n.dismiss();
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
          radius: Colors.radiusCard
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
              if ((p.identity || "").toLowerCase().includes(app) || p.desktopEntry === app) return p;
            }
            return null;
          }

          Column {
            id: colItem
            width: parent.width - 24; anchors.top: parent.top; anchors.topMargin: Colors.spacingM; anchors.horizontalCenter: parent.horizontalCenter; spacing: Colors.paddingSmall

            RowLayout {
              width: parent.width; spacing: Colors.spacingM
              Image {
                Layout.preferredWidth: 32; Layout.preferredHeight: 32
                source: Config.resolveIconSource(modelData.appIcon || "")
                sourceSize: Qt.size(64, 64)
                asynchronous: true
                visible: modelData.appIcon !== ""
                Rectangle { anchors.fill: parent; color: "transparent"; visible: parent.status !== Image.Ready; Text { anchors.centerIn: parent; text: "󰂚"; color: Colors.text; font.pixelSize: Colors.fontSizeHuge; font.family: Colors.fontMono } }
              }

              ColumnLayout {
                Layout.fillWidth: true; spacing: Colors.spacingXXS
                RowLayout {
                  Layout.fillWidth: true
                  Text {
                    text: modelData.summary; color: Colors.text; font.pixelSize: Colors.fontSizeLarge; font.weight: Font.Bold
                    Layout.fillWidth: true; elide: Text.ElideRight
                  }
                  Text {
                    text: modelData.time ? Qt.formatDateTime(modelData.time, "HH:mm") : ""
                    color: Colors.textDisabled; font.pixelSize: Colors.fontSizeSmall
                  }
                }
                Text {
                  text: modelData.body; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeMedium
                  Layout.fillWidth: true; wrapMode: Text.Wrap; visible: modelData.body !== ""
                }
              }
            }

            // Media Controls (if applicable)
            Rectangle {
              width: parent.width; height: 40; radius: Colors.radiusXS; color: Colors.highlightLight; visible: mprisPlayer !== null
              RowLayout {
                anchors.fill: parent; anchors.margins: Colors.spacingS; spacing: Colors.paddingMedium
                Item { Layout.fillWidth: true }
                SharedWidgets.IconButton {
                  size: 24; icon: "󰒮"; iconColor: Colors.text
                  onClicked: { if (mprisPlayer) mprisPlayer.previous(); }
                }
                SharedWidgets.IconButton {
                  size: 32; color: Colors.primary
                  icon: mprisPlayer && mprisPlayer.playbackState === Mpris.Playing ? "󰏤" : "󰐊"
                  iconColor: Colors.background
                  onClicked: { if (mprisPlayer) mprisPlayer.playPause(); }
                }
                SharedWidgets.IconButton {
                  size: 24; icon: "󰒭"; iconColor: Colors.text
                  onClicked: { if (mprisPlayer) mprisPlayer.next(); }
                }
                Item { Layout.fillWidth: true }
              }
            }

            // Large Image Preview
            Rectangle {
              width: parent.width; height: 150; visible: modelData.image !== ""; radius: Colors.radiusXS; clip: true; color: "transparent"; border.color: Colors.border; border.width: 1
              Image { anchors.fill: parent; source: modelData.image || ""; sourceSize: Qt.size(600, 300); asynchronous: true; fillMode: Image.PreserveAspectCrop }
            }

            // Inline Reply Area
            Rectangle {
              width: parent.width; height: 36; radius: Colors.radiusXXS; color: Colors.highlightLight; visible: isReplying
              TextInput {
                id: replyInput; anchors.fill: parent; anchors.margins: Colors.spacingS
                verticalAlignment: Text.AlignVCenter
                color: Colors.text; font.pixelSize: Colors.fontSizeMedium
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
              width: parent.width; spacing: Colors.spacingS; visible: !isReplying

              // Dynamic Actions from Notification
              Repeater {
                model: notifItem.notification ? notifItem.notification.actions : null
                delegate: Rectangle {
                  id: actionRect
                  Layout.fillWidth: true; height: 28; color: Colors.highlightLight; radius: Colors.radiusXXS
                  Text { anchors.centerIn: parent; text: modelData && modelData.label ? modelData.label : ""; color: Colors.text; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.Medium }
                  SharedWidgets.StateLayer {
                    id: actionStateLayer
                    hovered: actionMa.containsMouse
                    pressed: actionMa.pressed
                  }
                  MouseArea {
                    id: actionMa
                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: (mouse) => {
                      actionStateLayer.burst(mouse.x, mouse.y);
                      var label = modelData && modelData.label ? modelData.label.toLowerCase() : "";
                      if (label.includes("reply")) notifItem.isReplying = true;
                      else if (modelData) { modelData.invoke(); notifItem.notification.dismiss(); }
                    }
                  }
                }
              }

              // Dismiss Action
              Rectangle {
                Layout.preferredWidth: 32; height: 28; color: Colors.highlightLight; radius: Colors.radiusXXS
                Text { anchors.centerIn: parent; text: "󰅖"; color: Colors.error; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeLarge }
                SharedWidgets.StateLayer {
                  id: dismissStateLayer
                  hovered: dismissMa.containsMouse
                  pressed: dismissMa.pressed
                }
                MouseArea {
                  id: dismissMa
                  anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                  onClicked: (mouse) => {
                    dismissStateLayer.burst(mouse.x, mouse.y);
                    notifItem.notification.dismiss();
                  }
                }
              }
            }
          }
        }

          SharedWidgets.Scrollbar { flickable: notifList }
          SharedWidgets.OverscrollGlow { flickable: notifList }
        }
      }

      // Archive Section
      Column {
        width: parent.width; spacing: Colors.spacingS
        visible: root.manager && root.manager.archivedNotifications.length > 0

        RowLayout {
          width: parent.width
          Text { text: "ARCHIVE"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; font.weight: Font.Bold }
          Item { Layout.fillWidth: true }
          MouseArea {
            width: 40; height: 20
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            Text { anchors.centerIn: parent; text: "Clear"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS }
            onClicked: if (root.manager) root.manager.clearArchive()
          }
        }

        ListView {
          width: parent.width
          height: Math.min(contentHeight, 300)
          clip: true
          model: root.manager ? root.manager.archivedNotifications : null
          cacheBuffer: 120
          spacing: Colors.spacingS
          delegate: Rectangle {
            width: ListView.view.width; height: 60; color: Colors.bgWidget; radius: Colors.radiusXS; opacity: 0.7
            Row {
              anchors.fill: parent; anchors.margins: Colors.paddingSmall; spacing: Colors.paddingSmall
              Rectangle { width: 32; height: 32; color: "transparent"
                Text { anchors.centerIn: parent; text: "󰂚"; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeHuge; font.family: Colors.fontMono }
              }
              Column {
                width: parent.width - 50; spacing: Colors.spacingXXS
                Text { text: modelData.summary; color: Colors.textSecondary; font.pixelSize: Colors.fontSizeMedium; font.weight: Font.Bold; elide: Text.ElideRight; width: parent.width }
                Text { text: modelData.body; color: Colors.textDisabled; font.pixelSize: Colors.fontSizeXS; elide: Text.ElideRight; width: parent.width }
              }
            }
          }
        }
      }
    }
  }
}
