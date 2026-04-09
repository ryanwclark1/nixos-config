import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../system/sections"
import "../../shared" as Shared
import "../../services"
import "../../services/IconHelpers.js" as IconHelpers
import "../../widgets" as SharedWidgets

PanelWindow {
  id: root
  property bool _destroyed: false

  property int panelWidth: Config.notifCenterWidth
  readonly property var edgeMargins: Config.reservedEdgesForScreen(screen, "")
  property int reservedTop: edgeMargins.top
  property int reservedRight: edgeMargins.right
  property int reservedBottom: edgeMargins.bottom
  readonly property bool compactLayout: panelWidth < 420

  anchors {
    top: true
    right: true
    bottom: true
  }

  margins.top: reservedTop + Appearance.spacingS
  margins.right: reservedRight + Appearance.spacingS
  margins.bottom: reservedBottom + Appearance.spacingS

  implicitWidth: panelWidth + 20
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "quickshell-notifications"

  property var manager: null
  property bool showContent: false
  readonly property int maxLayerTextureSize: 4096
  signal closeRequested()
  property string searchQuery: ""
  visible: root.showContent || ncSlideAnim.running || ncFadeAnim.running

  function allowLayer(width, height) {
    return width > 0 && height > 0
      && width <= maxLayerTextureSize
      && height <= maxLayerTextureSize;
  }

  Component.onDestruction: _destroyed = true

  onShowContentChanged: {
    if (showContent) {
      Qt.callLater(function() {
        if (_destroyed) return;
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
    radius: Appearance.radiusLarge
    focus: true

    transform: Translate {
      x: root.showContent ? 0 : root.panelWidth + 40
      Behavior on x {
        NumberAnimation {
          id: ncSlideAnim
          duration: Appearance.durationSlow
          easing.type: Easing.OutQuint
        }
      }
    }

    opacity: root.showContent ? 1.0 : 0.0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { id: ncFadeAnim; duration: Appearance.durationNormal } }
    layer.enabled: (ncSlideAnim.running || ncFadeAnim.running) && root.allowLayer(width, height)

    SharedWidgets.InnerHighlight { highlightOpacity: 0.12 }
    SharedWidgets.SurfaceGradient {}

    Keys.onEscapePressed: root.closeRequested()

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Appearance.paddingLarge
      spacing: Appearance.spacingLG

      // --- Header Area ---
      ColumnLayout {
        Layout.fillWidth: true
        spacing: root.compactLayout ? Appearance.spacingS : Appearance.spacingM

        RowLayout {
          Layout.fillWidth: true
          spacing: Appearance.spacingM

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
              Layout.fillWidth: true
              text: "Notification Center"
              color: Colors.text
              font.pixelSize: root.compactLayout ? Appearance.fontSizeXL : Appearance.fontSizeHuge
              font.weight: Font.DemiBold
              font.letterSpacing: Appearance.letterSpacingTight
              elide: Text.ElideRight
            }
            RowLayout {
              Layout.fillWidth: true
              spacing: Appearance.spacingS
              visible: notifList.count > 0
              Rectangle {
                width: 8; height: 8; radius: 4; color: Colors.primary
              }
              Text {
                Layout.fillWidth: true
                text: notifList.count + " active notifications"
                color: Colors.textDisabled
                font.pixelSize: Appearance.fontSizeXXS
                font.weight: Font.Medium
                elide: Text.ElideRight
              }
            }
          }

          Item { Layout.fillWidth: true; visible: !root.compactLayout }

          RowLayout {
            visible: !root.compactLayout
            spacing: Appearance.spacingXS
            Layout.alignment: Qt.AlignRight
            Layout.fillWidth: false
            Layout.preferredWidth: implicitWidth
            SharedWidgets.IconButton {
              size: Appearance.iconSizeMedium
              icon: IconHelpers.speechToggleIcon(Config.notifTtsEnabled)
              iconColor: Config.notifTtsEnabled ? Colors.primary : Colors.textSecondary
              tooltipText: Config.notifTtsEnabled ? "Disable read-aloud" : "Read notifications aloud"
              onClicked: Config.notifTtsEnabled = !Config.notifTtsEnabled
            }
            SharedWidgets.IconButton {
              size: Appearance.iconSizeMedium
              icon: "stop.svg"
              iconColor: Colors.error
              tooltipText: "Stop speaking"
              visible: !!(root.manager && root.manager.ttsSpeaking)
              onClicked: if (root.manager) root.manager.stopSpeaking()
            }
            SharedWidgets.IconButton {
              size: Appearance.iconSizeMedium
              icon: IconHelpers.doNotDisturbIcon(root.manager && root.manager.dndEnabled)
              iconColor: root.manager && root.manager.dndEnabled ? Colors.error : Colors.textSecondary
              tooltipText: root.manager && root.manager.dndEnabled ? "Disable do not disturb" : "Do not disturb"
              onClicked: if (root.manager) root.manager.dndEnabled = !root.manager.dndEnabled
            }
            SharedWidgets.IconButton {
              size: Appearance.iconSizeMedium
              icon: "archive.svg"
              iconColor: Colors.textDisabled
              tooltipText: "Clear all"
              onClicked: if (root.manager) root.manager.dismissAll()
            }
            SharedWidgets.IconButton {
              size: Appearance.iconSizeMedium
              icon: "dismiss.svg"
              tooltipText: "Close"
              onClicked: root.closeRequested()
            }
          }
        }

        RowLayout {
          visible: root.compactLayout
          Layout.fillWidth: true
          spacing: Appearance.spacingXS
          Layout.alignment: Qt.AlignLeft

          SharedWidgets.IconButton {
            size: Appearance.iconSizeMedium
            icon: IconHelpers.speechToggleIcon(Config.notifTtsEnabled)
            iconColor: Config.notifTtsEnabled ? Colors.primary : Colors.textSecondary
            tooltipText: Config.notifTtsEnabled ? "Disable read-aloud" : "Read notifications aloud"
            onClicked: Config.notifTtsEnabled = !Config.notifTtsEnabled
          }

          SharedWidgets.IconButton {
            size: Appearance.iconSizeMedium
            icon: "stop.svg"
            iconColor: Colors.error
            tooltipText: "Stop speaking"
            visible: !!(root.manager && root.manager.ttsSpeaking)
            onClicked: if (root.manager) root.manager.stopSpeaking()
          }

          SharedWidgets.IconButton {
            size: Appearance.iconSizeMedium
            icon: IconHelpers.doNotDisturbIcon(root.manager && root.manager.dndEnabled)
            iconColor: root.manager && root.manager.dndEnabled ? Colors.error : Colors.textSecondary
            tooltipText: root.manager && root.manager.dndEnabled ? "Disable do not disturb" : "Do not disturb"
            onClicked: if (root.manager) root.manager.dndEnabled = !root.manager.dndEnabled
          }

          SharedWidgets.IconButton {
            size: Appearance.iconSizeMedium
            icon: "archive.svg"
            iconColor: Colors.textDisabled
            tooltipText: "Clear all"
            onClicked: if (root.manager) root.manager.dismissAll()
          }

          Item { Layout.fillWidth: true }

          SharedWidgets.IconButton {
            size: Appearance.iconSizeMedium
            icon: "dismiss.svg"
            tooltipText: "Close"
            onClicked: root.closeRequested()
          }
        }
      }

      // --- Dashboard Section ---
      Shared.ThemedContainer {
        variant: "card"
        Layout.fillWidth: true
        implicitHeight: dashContent.implicitHeight + Appearance.paddingLarge * 2

        SystemClock { id: dashClock; precision: SystemClock.Minutes }

        GridLayout {
          id: dashContent
          anchors.fill: parent
          anchors.margins: Appearance.paddingLarge
          columns: root.compactLayout ? 1 : 3
          columnSpacing: root.compactLayout ? 0 : Appearance.spacingXL
          rowSpacing: root.compactLayout ? Appearance.spacingM : 0

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text {
              text: Qt.formatDateTime(dashClock.date, "HH:mm")
              color: Colors.text
              font.pixelSize: 32
              font.weight: Font.Black
              font.letterSpacing: -1
            }
            Text {
              Layout.fillWidth: true
              text: Qt.formatDateTime(dashClock.date, "dddd, MMMM d")
              color: Colors.primary
              font.pixelSize: Appearance.fontSizeSmall
              font.weight: Font.Bold
              opacity: 0.8
              elide: Text.ElideRight
            }
          }

          Rectangle {
            visible: !root.compactLayout
            Layout.fillHeight: true
            width: 1
            color: Colors.border
            opacity: 0.3
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingXXS
            SharedWidgets.Ref { service: WeatherService }
            
            RowLayout {
              spacing: Appearance.spacingS
              SharedWidgets.SvgIcon {
                source: Appearance.weatherIcon(WeatherService.condition)
                color: Colors.accent
                size: 24
              }
              Text {
                text: WeatherService.temp
                color: Colors.text
                font.pixelSize: Appearance.fontSizeLarge
                font.weight: Font.Bold
                elide: Text.ElideRight
              }
            }
            Text {
              Layout.fillWidth: true
              text: (WeatherService.condition || "Unknown")
              color: Colors.textSecondary
              font.pixelSize: Appearance.fontSizeXXS
              font.weight: Font.Black
              font.capitalization: Font.AllUppercase
              elide: Text.ElideRight
            }
          }
        }
      }

      Calendar {
         visible: root.searchQuery === "" && notifList.count < 3
         Layout.preferredHeight: 280
      }

      // --- Search Bar ---
      Rectangle {
        Layout.fillWidth: true
        height: 48
        color: Colors.withAlpha(Colors.surface, searchInput.activeFocus ? 0.15 : 0.08)
        radius: Appearance.radiusMedium
        border.color: searchInput.activeFocus ? Colors.primary : Colors.border
        border.width: 1

        RowLayout {
          anchors.fill: parent
          anchors.margins: Appearance.spacingM
          spacing: Appearance.spacingS
          SharedWidgets.SvgIcon {
            source: "search-visual.svg"
            color: searchInput.activeFocus ? Colors.primary : Colors.textDisabled
            size: Appearance.fontSizeLarge
            opacity: 0.7
          }
          TextInput {
            id: searchInput
            Layout.fillWidth: true
            verticalAlignment: Text.AlignVCenter
            color: Colors.text
            font.pixelSize: Appearance.fontSizeMedium
            onVisibleChanged: if (!visible && activeFocus) focus = false
            Keys.onEscapePressed: root.closeRequested()
            onTextChanged: root.searchQuery = text
          }
          Text {
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            text: "Filter notifications..."
            color: Colors.textDisabled
            font.pixelSize: Appearance.fontSizeMedium
            visible: !searchInput.text && !searchInput.activeFocus
            elide: Text.ElideRight
          }
        }
      }

      // --- Notifications List ---
      Item {
        Layout.fillWidth: true
        readonly property bool _hasTracked: notifList.count > 0
        Layout.fillHeight: _hasTracked
        Layout.preferredHeight: _hasTracked ? -1 : (_emptyState.visible ? _emptyState.implicitHeight + Appearance.spacingL * 2 : 0)

        ListView {
          id: notifList
          anchors.fill: parent
          spacing: Appearance.spacingM; clip: true; focus: true
          model: root.manager ? root.manager.notifications : null

          property var collapsedGroups: ({})

          add: SharedWidgets.ListTransitions.addFadeScale
          remove: SharedWidgets.ListTransitions.removeFade
          displaced: SharedWidgets.ListTransitions.displaced

          // Empty state
          ColumnLayout {
            id: _emptyState
            anchors.centerIn: parent
            visible: (notifList.count === 0 && root.searchQuery === "") || (root.searchQuery !== "" && notifList.visibleCount === 0)
            spacing: Appearance.spacingM
            opacity: 0.8
            SharedWidgets.SvgIcon {
              Layout.alignment: Qt.AlignHCenter
              source: root.searchQuery === "" ? "alert.svg" : "search-visual.svg"
              color: Colors.primary
              size: 48
              opacity: 0.4
            }
            Text {
              Layout.alignment: Qt.AlignHCenter
              text: root.searchQuery === "" ? "All caught up" : "No matches found"
              color: Colors.text
              font.pixelSize: Appearance.fontSizeLarge
              font.weight: Font.Bold
            }
            Text {
              Layout.alignment: Qt.AlignHCenter
              text: root.searchQuery === "" ? "No new notifications at this time." : "Try a different search term."
              color: Colors.textSecondary
              font.pixelSize: Appearance.fontSizeSmall
              horizontalAlignment: Text.AlignHCenter
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
            height: 48
            property bool isCollapsed: notifList.collapsedGroups[section] || false

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: Appearance.spacingS
              spacing: Appearance.spacingM

              MouseArea {
                Layout.preferredWidth: 24; Layout.preferredHeight: 24
                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                SharedWidgets.SvgIcon {
                  anchors.centerIn: parent; source: isCollapsed ? "chevron-right.svg" : "chevron-down.svg"; color: Colors.primary
                  size: 16
                }
                onClicked: notifList.toggleGroup(section)
              }

              Text {
                text: section || "System"
                color: Colors.textSecondary; font.pixelSize: Appearance.fontSizeXXS; font.weight: Font.Black
                font.capitalization: Font.AllUppercase; font.letterSpacing: Appearance.letterSpacingWide
              }

              Rectangle { Layout.fillWidth: true; height: 1; color: Colors.border; opacity: 0.2 }

              Rectangle {
                width: 20; height: 20; radius: 10; color: Colors.primarySubtle
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
                Text { anchors.centerIn: parent; text: parent.sectionCount; color: Colors.primary; font.pixelSize: 10; font.weight: Font.Bold }
              }

              SharedWidgets.IconButton {
                size: 28; icon: "dismiss.svg"; iconColor: Colors.textDisabled
                stateColor: Colors.error
                tooltipText: "Dismiss group"
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

            onDismissRequested: if (root.manager) root.manager.dismissNotification(notification)
            onActionInvoked: function(action) {
              action.invoke();
              if (root.manager) root.manager.dismissNotification(notification);
            }
            onReplySent: function(text) {
              notification.sendInlineReply(text);
              if (root.manager) root.manager.dismissNotification(notification);
            }
          }

          SharedWidgets.Scrollbar { flickable: notifList }
          SharedWidgets.OverscrollGlow { flickable: notifList }
        }
      }

      // Archive Section — shows dismissed notifications with relative timestamps
      // Fills remaining space when no tracked notifications, otherwise fixed height
      ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: notifList.count === 0
        spacing: Appearance.spacingS
        visible: root.manager && root.manager.archivedNotifications.length > 0

        RowLayout {
          Layout.fillWidth: true
          Text {
            text: "HISTORY"
            color: Colors.textDisabled
            font.pixelSize: Appearance.fontSizeXXS
            font.weight: Font.Black
            font.letterSpacing: Appearance.letterSpacingWide
          }
          Rectangle {
            Layout.fillWidth: true; height: 1; color: Colors.border; opacity: 0.4
          }
          SharedWidgets.IconButton {
            size: Appearance.iconSizeSmall
            icon: "archive.svg"
            iconColor: Colors.textDisabled
            stateColor: Colors.error
            tooltipText: "Clear history"
            onClicked: if (root.manager) root.manager.clearArchive()
          }
        }

        ListView {
          id: archiveList
          Layout.fillWidth: true
          Layout.fillHeight: notifList.count === 0
          height: notifList.count === 0 ? -1 : Math.min(contentHeight, 300)
          clip: true
          model: root.manager ? root.manager.archivedNotifications : null
          spacing: Appearance.spacingXS

          delegate: Rectangle {
            id: archiveDelegate
            width: ListView.view.width
            height: archiveMatchesSearch ? 54 : 0
            visible: archiveMatchesSearch
            color: Colors.cardSurface
            radius: Appearance.radiusMedium
            opacity: 0.7
            border.color: Colors.border
            border.width: 1

            property bool archiveMatchesSearch: {
              if (root.searchQuery === "") return true;
              var q = root.searchQuery.toLowerCase();
              return (modelData.appName && modelData.appName.toLowerCase().includes(q)) ||
                     (modelData.summary && modelData.summary.toLowerCase().includes(q)) ||
                     (modelData.body && modelData.body.toLowerCase().includes(q));
            }

            SharedWidgets.InnerHighlight { highlightOpacity: 0.08 }

            RowLayout {
              anchors.fill: parent; anchors.margins: Appearance.paddingSmall; spacing: Appearance.spacingM
              SharedWidgets.AppIcon {
                iconName: modelData.appIcon || ""
                appName: modelData.appName || ""
                iconSize: Appearance.iconSizeSmall
                fallbackIcon: "alert.svg"
              }
              ColumnLayout {
                Layout.fillWidth: true; spacing: 0
                RowLayout {
                  Layout.fillWidth: true; spacing: Appearance.spacingS
                  Text {
                    Layout.fillWidth: true
                    text: modelData.summary || modelData.appName || "Notification"
                    color: Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeSmall
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                  }
                  Text {
                    text: archiveDelegate._relativeTime(modelData.timestamp)
                    color: Colors.textDisabled
                    font.pixelSize: Appearance.fontSizeXXS
                  }
                }
                Text {
                  text: modelData.body || ""
                  color: Colors.textDisabled
                  font.pixelSize: Appearance.fontSizeXXS
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                  visible: (modelData.body || "") !== ""
                }
              }
            }

            function _relativeTime(ts) {
              if (!ts) return "";
              var diff = (Date.now() - ts) / 1000;
              if (diff < 60) return "just now";
              if (diff < 3600) return Math.floor(diff / 60) + "m ago";
              if (diff < 86400) return Math.floor(diff / 3600) + "h ago";
              return Math.floor(diff / 86400) + "d ago";
            }
          }
        }
      }
    }
  }
}
