import QtQuick
import QtQuick.Layouts
import Quickshell
import "./settings"
import "../services"
import "../widgets"
import "../widgets" as SharedWidgets
import "settings"

BasePopupMenu {
  id: root
  popupMaxWidth: 400
  compactThreshold: 360
  implicitHeight: compactMode ? 560 : 520
  title: "SSH"
  subtitle: sshData.importBusy ? "Refreshing aliases..." : "Hosts, aliases, and quick actions"
  toggleMethod: "toggleSshMenu"
  contentSpacing: Colors.spacingM

  property var surfaceContext: null
  readonly property var fallbackWidgetInstance: ({
    widgetType: "ssh",
    settings: BarWidgetRegistry.defaultSettings("ssh")
  })
  readonly property var menuWidgetInstance: surfaceContext && surfaceContext.widgetInstance ? surfaceContext.widgetInstance : fallbackWidgetInstance

  SharedWidgets.SshWidgetData {
    id: sshData
    widgetInstance: root.menuWidgetInstance
  }

  onVisibleChanged: {
    if (visible && sshData.enableSshConfigImport)
      sshData.refreshImport();
  }

  headerExtras: [
    Rectangle {
      visible: sshData.importErrors.length > 0
      implicitWidth: errorChipLabel.implicitWidth + 18
      implicitHeight: 24
      radius: Colors.radiusCard
      color: Colors.withAlpha(Colors.warning, 0.16)

      Text {
        id: errorChipLabel
        anchors.centerIn: parent
        text: sshData.importErrors.length + " error" + (sshData.importErrors.length !== 1 ? "s" : "")
        color: Colors.warning
        font.pixelSize: Colors.fontSizeXS
        font.weight: Font.DemiBold
      }
    },
    SharedWidgets.IconButton {
      visible: sshData.enableSshConfigImport
      icon: "󰑐"
      onClicked: sshData.refreshImport()
    }
  ]

  Rectangle {
    Layout.fillWidth: true
    implicitHeight: statusGrid.implicitHeight + 16
    radius: Colors.radiusMedium
    color: Colors.cardSurface
    border.color: Colors.border
    border.width: 1

    GridLayout {
      id: statusGrid
      anchors {
        left: parent.left
        right: parent.right
        top: parent.top
        margins: Colors.spacingM
      }
      columns: root.compactMode ? 2 : 4
      columnSpacing: Colors.spacingM
      rowSpacing: Colors.spacingS

      ColumnLayout {
        spacing: Colors.spacingXXS
        Text {
          text: sshData.mergedHosts.length
          color: Colors.text
          font.pixelSize: Colors.fontSizeHuge
          font.weight: Font.Bold
        }
        Text {
          text: "visible hosts"
          color: Colors.textDisabled
          font.pixelSize: Colors.fontSizeXS
          font.weight: Font.Medium
        }
      }

      ColumnLayout {
        spacing: Colors.spacingXXS
        Text {
          text: sshData.manualHosts.length
          color: Colors.text
          font.pixelSize: Colors.fontSizeHuge
          font.weight: Font.Bold
        }
        Text {
          text: "manual"
          color: Colors.textDisabled
          font.pixelSize: Colors.fontSizeXS
          font.weight: Font.Medium
        }
      }

      ColumnLayout {
        spacing: Colors.spacingXXS
        Text {
          text: sshData.importedHosts.length
          color: sshData.enableSshConfigImport ? Colors.primary : Colors.textDisabled
          font.pixelSize: Colors.fontSizeHuge
          font.weight: Font.Bold
        }
        Text {
          text: "imported"
          color: Colors.textDisabled
          font.pixelSize: Colors.fontSizeXS
          font.weight: Font.Medium
        }
      }

      ColumnLayout {
        spacing: Colors.spacingXXS
        Text {
          text: sshData.recentHostLabel() !== "" ? sshData.recentHostLabel() : "None"
          color: sshData.recentHostLabel() !== "" ? Colors.text : Colors.textDisabled
          font.pixelSize: Colors.fontSizeSmall
          font.weight: Font.DemiBold
          elide: Text.ElideRight
          Layout.preferredWidth: root.compactMode ? 120 : 140
        }
        Text {
          text: "last connected"
          color: Colors.textDisabled
          font.pixelSize: Colors.fontSizeXS
          font.weight: Font.Medium
        }
      }
    }
  }

  SharedWidgets.ScrollableContent {
    Layout.fillWidth: true
    Layout.fillHeight: true
    columnSpacing: Colors.spacingS

    SharedWidgets.EmptyState {
      Layout.fillWidth: true
      Layout.topMargin: 32
      visible: !sshData.importBusy && sshData.mergedHosts.length === 0
      icon: "󰣀"
      iconSize: 48
      message: sshData.enableSshConfigImport ? "No SSH hosts found yet" : "No SSH hosts configured"
    }

    Text {
      visible: !sshData.importBusy && sshData.mergedHosts.length === 0
      Layout.fillWidth: true
      text: sshData.enableSshConfigImport ? "Refresh import or add manual hosts in widget settings." : "Enable SSH config import or add manual hosts in widget settings."
      color: Colors.textSecondary
      font.pixelSize: Colors.fontSizeXS
      wrapMode: Text.WordWrap
      horizontalAlignment: Text.AlignHCenter
    }

    SharedWidgets.SectionLabel {
      visible: sshData.mergedHosts.length > 0
      label: "HOSTS"
    }

    Repeater {
      model: sshData.mergedHosts

      delegate: Rectangle {
        required property var modelData

        Layout.fillWidth: true
        implicitHeight: hostLayout.implicitHeight + 20
        radius: Colors.radiusMedium
        color: Colors.cardSurface
        border.color: Colors.border
        border.width: 1

        ColumnLayout {
          id: hostLayout
          anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: Colors.spacingM
          }
          spacing: Colors.spacingS

          RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingS

            Text {
              text: modelData.icon || "󰣀"
              color: Colors.primary
              font.family: Colors.fontMono
              font.pixelSize: Colors.fontSizeLarge
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: Colors.spacingXXS

              Text {
                text: String(modelData.label || modelData.alias || modelData.host || "SSH")
                color: Colors.text
                font.pixelSize: Colors.fontSizeMedium
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              Text {
                text: sshData.buildDisplayCommand(modelData)
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeXS
                font.family: Colors.fontMono
                elide: Text.ElideMiddle
                Layout.fillWidth: true
              }
            }
          }

          Flow {
            Layout.fillWidth: true
            width: parent.width
            spacing: Colors.spacingS

            SharedWidgets.FilterChip {
              label: modelData.source === "imported" ? "Imported" : "Manual"
              selected: false
              enabled: false
            }

            SharedWidgets.FilterChip {
              visible: !!modelData.group
              label: modelData.group
              selected: false
              enabled: false
            }

            SharedWidgets.FilterChip {
              visible: !!modelData.user
              label: modelData.user
              selected: false
              enabled: false
            }
          }

          Flow {
            Layout.fillWidth: true
            width: parent.width
            spacing: Colors.spacingS

            SettingsActionButton {
              compact: true
              iconName: "󰆍"
              label: "Connect"
              onClicked: {
                sshData.connectHost(modelData);
                root.closeRequested();
              }
            }

            SettingsActionButton {
              compact: true
              iconName: "󰅍"
              label: "Copy"
              onClicked: {
                sshData.copyHostCommand(modelData);
                root.closeRequested();
              }
            }
          }
        }
      }
    }

    SettingsInfoCallout {
      visible: sshData.importErrors.length > 0
      title: "SSH import warnings"
      body: sshData.importErrors.slice(0, 3).map(function(entry) {
        return entry.path + (entry.line > 0 ? (":" + entry.line) : "") + " - " + entry.message;
      }).join("\n")
    }
  }
}
