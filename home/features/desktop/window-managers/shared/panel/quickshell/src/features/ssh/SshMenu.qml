import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../shared"
import "../../services"
import "../../services/SearchUtils.js" as SU
import "../../widgets" as SharedWidgets
import "."
import "../settings/components"

BasePopupMenu {
  id: root
  popupMaxWidth: 400
  compactThreshold: 360
  implicitHeight: compactMode ? 560 : 520
  title: "SSH"
  subtitle: sshData.importBusy ? "Refreshing aliases..." : "Hosts, aliases, and quick actions"
  contentSpacing: Appearance.spacingM
  focusOnOpen: true
  initialFocusTarget: searchBar.inputItem

  property var surfaceContext: null
  property string searchQuery: ""
  readonly property var fallbackWidgetInstance: ({
    widgetType: "ssh",
    settings: BarWidgetRegistry.defaultSettings("ssh")
  })
  readonly property var menuWidgetInstance: surfaceContext && surfaceContext.widgetInstance ? surfaceContext.widgetInstance : fallbackWidgetInstance
  readonly property var filteredHostsResult: {
    return SU.filterByFuzzy(sshData.mergedHosts, searchQuery, _hostSearchText, { minFuzzyLength: 2, minFuzzyScore: 24 });
  }
  readonly property bool hasSearchQuery: searchQuery.trim() !== ""
  readonly property bool hasHosts: sshData.mergedHosts.length > 0
  readonly property bool hasFilteredHosts: filteredHostsResult.length > 0
  readonly property var groupedHostsResult: {
    var groups = [];
    var byKey = ({});
    for (var i = 0; i < filteredHostsResult.length; ++i) {
      var host = filteredHostsResult[i];
      var section = _hostSectionMeta(host);
      var existing = byKey[section.key];
      if (!existing) {
        existing = {
          key: section.key,
          title: section.title,
          subtitle: section.subtitle,
          icon: section.icon,
          hosts: []
        };
        byKey[section.key] = existing;
        groups.push(existing);
      }
      existing.hosts.push(host);
    }
    return groups;
  }

  function _hostSearchText(host) {
    if (!host)
      return "";
    var values = [
      host.label,
      host.alias,
      host.host,
      host.user,
      host.group,
      host.source,
      host.sourcePath,
      host.searchText
    ];
    if (Array.isArray(host.tags))
      values = values.concat(host.tags);
    return values.map(function(value) {
      return String(value || "").toLowerCase();
    }).join(" ");
  }


  function _hostSectionMeta(host) {
    var isImported = host && String(host.source || "") === "imported";
    var groupName = String(host && host.group ? host.group : "").trim();
    if (groupName !== "" && groupName !== "ssh-config") {
      return {
        key: String(host.source || "manual") + "|" + groupName.toLowerCase(),
        title: groupName,
        subtitle: isImported ? "Imported group" : "Manual group",
        icon: isImported ? "󰣀" : "󰌆"
      };
    }
    return {
      key: isImported ? "imported" : "manual",
      title: isImported ? "Imported Aliases" : "Manual Hosts",
      subtitle: isImported ? "From SSH config import" : "Configured in widget settings",
      icon: isImported ? "󰮔" : "󰌆"
    };
  }

  function openBarWidgetSettings() {
    var instanceId = menuWidgetInstance && menuWidgetInstance.instanceId ? String(menuWidgetInstance.instanceId) : "";
    if (instanceId !== "")
      Quickshell.execDetached(["quickshell", "ipc", "call", "SettingsHub", "openBarWidgetInstance", instanceId]);
    else
      Quickshell.execDetached(["quickshell", "ipc", "call", "SettingsHub", "openTab", "bar-widgets"]);
    root.closeRequested();
  }

  SshWidgetData {
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
      radius: Appearance.radiusCard
      color: Colors.warningLight

      Text {
        id: errorChipLabel
        anchors.centerIn: parent
        text: sshData.importErrors.length + " error" + (sshData.importErrors.length !== 1 ? "s" : "")
        color: Colors.warning
        font.pixelSize: Appearance.fontSizeXS
        font.weight: Font.DemiBold
      }
    },
    SharedWidgets.IconButton {
      icon: "settings.svg"
      tooltipText: "Settings"
      onClicked: root.openBarWidgetSettings()
    },
    SharedWidgets.IconButton {
      visible: sshData.enableSshConfigImport
      icon: "arrow-clockwise.svg"
      tooltipText: "Refresh SSH config"
      onClicked: sshData.refreshImport()
    }
  ]

  Rectangle {
    Layout.fillWidth: true
    implicitHeight: statusGrid.implicitHeight + 16
    radius: Appearance.radiusMedium
    color: Colors.cardSurface
    border.color: Colors.border
    border.width: 1

    GridLayout {
      id: statusGrid
      anchors {
        left: parent.left
        right: parent.right
        top: parent.top
        margins: Appearance.spacingM
      }
      columns: root.compactMode ? 2 : 4
      columnSpacing: Appearance.spacingM
      rowSpacing: Appearance.spacingS

      ColumnLayout {
        spacing: Appearance.spacingXXS
        Text {
          text: root.filteredHostsResult.length
          color: Colors.text
          font.pixelSize: Appearance.fontSizeHuge
          font.weight: Font.Bold
        }
        Text {
          text: root.hasSearchQuery ? ("matching of " + sshData.mergedHosts.length) : "visible hosts"
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeXS
          font.weight: Font.Medium
        }
      }

      ColumnLayout {
        spacing: Appearance.spacingXXS
        Text {
          text: sshData.manualHosts.length
          color: Colors.text
          font.pixelSize: Appearance.fontSizeHuge
          font.weight: Font.Bold
        }
        Text {
          text: "manual"
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeXS
          font.weight: Font.Medium
        }
      }

      ColumnLayout {
        spacing: Appearance.spacingXXS
        Text {
          text: sshData.importedHosts.length
          color: sshData.enableSshConfigImport ? Colors.primary : Colors.textDisabled
          font.pixelSize: Appearance.fontSizeHuge
          font.weight: Font.Bold
        }
        Text {
          text: "imported"
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeXS
          font.weight: Font.Medium
        }
      }

      ColumnLayout {
        spacing: Appearance.spacingXXS
        Text {
          text: sshData.recentHostLabel() !== "" ? sshData.recentHostLabel() : "None"
          color: sshData.recentHostLabel() !== "" ? Colors.text : Colors.textDisabled
          font.pixelSize: Appearance.fontSizeSmall
          font.weight: Font.DemiBold
          elide: Text.ElideRight
          Layout.preferredWidth: root.compactMode ? 120 : 140
        }
        Text {
          text: "last connected"
          color: Colors.textDisabled
          font.pixelSize: Appearance.fontSizeXS
          font.weight: Font.Medium
        }
      }
    }
  }

  SharedWidgets.SearchBar {
    id: searchBar
    placeholder: "Search SSH hosts..."
    preferredHeight: root.compactMode ? 34 : 36
    Layout.fillWidth: true
    onTextChanged: root.searchQuery = text
    inputItem.Keys.onEscapePressed: {
      if (searchBar.text !== "")
        searchBar.text = "";
      else
        root.closeRequested();
    }
  }

  SharedWidgets.ScrollableContent {
    Layout.fillWidth: true
    Layout.fillHeight: true
    columnSpacing: Appearance.spacingS

    SharedWidgets.EmptyState {
      Layout.fillWidth: true
      Layout.topMargin: 32
      visible: !sshData.importBusy && !root.hasHosts
      icon: "server.svg"
      iconSize: Appearance.iconSizeLarge
      message: sshData.enableSshConfigImport ? "No SSH hosts found yet" : "No SSH hosts configured"
    }

    Text {
      visible: !sshData.importBusy && !root.hasHosts
      Layout.fillWidth: true
      text: sshData.enableSshConfigImport ? "Refresh import or add manual hosts in widget settings." : "Enable SSH config import or add manual hosts in widget settings."
      color: Colors.textSecondary
      font.pixelSize: Appearance.fontSizeXS
      wrapMode: Text.WordWrap
      horizontalAlignment: Text.AlignHCenter
    }

    SharedWidgets.EmptyState {
      Layout.fillWidth: true
      Layout.topMargin: 32
      visible: !sshData.importBusy && root.hasHosts && root.hasSearchQuery && !root.hasFilteredHosts
      icon: "search-visual.svg"
      iconSize: Appearance.iconSizeLarge
      message: "No SSH hosts match \"" + root.searchQuery + "\""
    }

    Text {
      visible: !sshData.importBusy && root.hasHosts && root.hasSearchQuery && !root.hasFilteredHosts
      Layout.fillWidth: true
      text: "Try alias, hostname, user, group, or tag. Manage host entries in Bar Widgets settings."
      color: Colors.textSecondary
      font.pixelSize: Appearance.fontSizeXS
      wrapMode: Text.WordWrap
      horizontalAlignment: Text.AlignHCenter
    }

    RowLayout {
      Layout.fillWidth: true
      visible: !sshData.importBusy
      spacing: Appearance.spacingS

      SharedWidgets.SectionLabel {
        Layout.fillWidth: true
        visible: root.hasFilteredHosts
        label: root.hasSearchQuery ? ("MATCHES (" + root.filteredHostsResult.length + ")") : "HOSTS"
      }

      SettingsActionButton {
        compact: true
        iconName: "󰒓"
        label: "Edit Hosts"
        onClicked: root.openBarWidgetSettings()
      }
    }

    Repeater {
      model: ScriptModel { values: root.groupedHostsResult }

      delegate: SharedWidgets.CollapsibleSection {
        required property var modelData
        Layout.fillWidth: true
        expanded: true
        title: String(modelData.title || "Hosts") + " (" + ((modelData.hosts && modelData.hosts.length) || 0) + ")"
        icon: String(modelData.icon || "󰣀")

        ColumnLayout {
          Layout.fillWidth: true
          spacing: Appearance.spacingS

          Text {
            Layout.fillWidth: true
            text: String(modelData.subtitle || "")
            visible: text !== ""
            color: Colors.textSecondary
            font.pixelSize: Appearance.fontSizeXS
            wrapMode: Text.WordWrap
          }

          Repeater {
            model: ScriptModel { values: modelData.hosts || [] }

            delegate: Rectangle {
              required property var modelData

              Layout.fillWidth: true
              implicitHeight: hostLayout.implicitHeight + 20
              radius: Appearance.radiusMedium
              color: Colors.cardSurface
              border.color: Colors.border
              border.width: 1

              ColumnLayout {
                id: hostLayout
                anchors {
                  left: parent.left
                  right: parent.right
                  top: parent.top
                  margins: Appearance.spacingM
                }
                spacing: Appearance.spacingS

                RowLayout {
                  Layout.fillWidth: true
                  spacing: Appearance.spacingS

                  Loader {
                    property string _ic: modelData.icon || "󰣀"
                    sourceComponent: _ic.endsWith(".svg") ? _shSvg : _shNerd
                  }
                  Component { id: _shSvg; SvgIcon { source: parent._ic; color: Colors.primary; size: Appearance.fontSizeLarge } }
                  Component { id: _shNerd; Text { text: parent._ic; color: Colors.primary; font.family: Appearance.fontMono; font.pixelSize: Appearance.fontSizeLarge } }

                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacingXXS

                    Text {
                      text: String(modelData.label || modelData.alias || modelData.host || "SSH")
                      color: Colors.text
                      font.pixelSize: Appearance.fontSizeMedium
                      font.weight: Font.DemiBold
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                    }

                    Text {
                      text: sshData.buildDisplayCommand(modelData)
                      color: Colors.textSecondary
                      font.pixelSize: Appearance.fontSizeXS
                      font.family: Appearance.fontMono
                      elide: Text.ElideMiddle
                      Layout.fillWidth: true
                    }

                    Text {
                      text: sshData.hostSourceLabel(modelData)
                      visible: text !== ""
                      color: Colors.textDisabled
                      font.pixelSize: Appearance.fontSizeXS
                      font.family: Appearance.fontMono
                      elide: Text.ElideMiddle
                      Layout.fillWidth: true
                    }
                  }
                }

                Flow {
                  Layout.fillWidth: true
                  width: parent.width
                  spacing: Appearance.spacingS

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

                  Repeater {
                    model: Array.isArray(modelData.tags) ? modelData.tags : []

                    delegate: SharedWidgets.FilterChip {
                      required property var modelData
                      visible: String(modelData || "").trim() !== ""
                      label: "#" + String(modelData || "")
                      selected: false
                      enabled: false
                    }
                  }
                }

                Flow {
                  Layout.fillWidth: true
                  width: parent.width
                  spacing: Appearance.spacingS

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
                    label: "Copy Cmd"
                    onClicked: {
                      sshData.copyHostCommand(modelData);
                      root.closeRequested();
                    }
                  }

                  SettingsActionButton {
                    compact: true
                    iconName: "󰌹"
                    label: "Copy Alias"
                    visible: sshData.hostAliasText(modelData) !== ""
                    onClicked: sshData.copyHostAlias(modelData)
                  }

                  SettingsActionButton {
                    compact: true
                    iconName: "󰇖"
                    label: "Copy Host"
                    visible: sshData.hostNameText(modelData) !== ""
                    onClicked: sshData.copyHostName(modelData)
                  }

                  SettingsActionButton {
                    compact: true
                    iconName: "󰞇"
                    label: "Copy User@Host"
                    visible: sshData.hostUserHostText(modelData) !== "" && sshData.hostUserHostText(modelData) !== sshData.hostNameText(modelData)
                    onClicked: sshData.copyHostUserHost(modelData)
                  }

                  SettingsActionButton {
                    compact: true
                    iconName: "󰈔"
                    label: "Copy Source"
                    visible: sshData.hostSourceLabel(modelData) !== ""
                    onClicked: sshData.copyHostSourcePath(modelData)
                  }
                }
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
