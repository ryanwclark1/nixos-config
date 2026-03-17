import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
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
  focusOnOpen: true
  initialFocusTarget: searchInput

  property var surfaceContext: null
  property string searchQuery: ""
  readonly property var fallbackWidgetInstance: ({
    widgetType: "ssh",
    settings: BarWidgetRegistry.defaultSettings("ssh")
  })
  readonly property var menuWidgetInstance: surfaceContext && surfaceContext.widgetInstance ? surfaceContext.widgetInstance : fallbackWidgetInstance
  readonly property var filteredHostsResult: {
    if (!searchQuery)
      return sshData.mergedHosts;
    var query = searchQuery.toLowerCase();
    var scored = [];
    for (var i = 0; i < sshData.mergedHosts.length; ++i) {
      var host = sshData.mergedHosts[i];
      var score = _searchScore(query, host);
      if (score > 0)
        scored.push({ host: host, score: score });
    }
    scored.sort(function(a, b) { return b.score - a.score; });
    var out = [];
    for (var j = 0; j < scored.length; ++j)
      out.push(scored[j].host);
    return out;
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

  function _searchScore(query, host) {
    var haystack = _hostSearchText(host);
    if (!haystack)
      return 0;
    var queryLength = query.length;
    var exactIndex = haystack.indexOf(query);
    if (exactIndex !== -1)
      return 1000 + (1.0 / (1 + exactIndex));
    if (queryLength <= 2)
      return 0;

    var qi = 0;
    var score = 0;
    var lastMatch = -1;
    for (var i = 0; i < haystack.length && qi < query.length; ++i) {
      if (haystack[i] !== query[qi])
        continue;
      var gap = lastMatch >= 0 ? (i - lastMatch - 1) : 0;
      score += 10 - Math.min(gap, 8);
      if (i === 0 || haystack[i - 1] === " " || haystack[i - 1] === "/" || haystack[i - 1] === "-" || haystack[i - 1] === "_")
        score += 5;
      lastMatch = i;
      qi += 1;
    }
    if (qi !== query.length)
      return 0;
    if (queryLength === 3 && score < 24)
      return 0;
    return score;
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
      icon: "󰒓"
      onClicked: root.openBarWidgetSettings()
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
          text: root.filteredHostsResult.length
          color: Colors.text
          font.pixelSize: Colors.fontSizeHuge
          font.weight: Font.Bold
        }
        Text {
          text: root.hasSearchQuery ? ("matching of " + sshData.mergedHosts.length) : "visible hosts"
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

  Rectangle {
    Layout.fillWidth: true
    height: root.compactMode ? 34 : 36
    radius: height / 2
    color: Colors.bgWidget
    border.color: searchInput.activeFocus ? Colors.primary : Colors.border
    border.width: 1

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: Colors.spacingM
      anchors.rightMargin: Colors.spacingM
      spacing: Colors.spacingS

      Text {
        text: "󰍉"
        color: Colors.textDisabled
        font.family: Colors.fontMono
        font.pixelSize: Colors.fontSizeMedium
      }

      TextInput {
        id: searchInput
        Layout.fillWidth: true
        color: Colors.text
        font.pixelSize: Colors.fontSizeMedium
        clip: true
        onVisibleChanged: if (!visible && activeFocus) focus = false
        onTextChanged: root.searchQuery = text
        Keys.onEscapePressed: {
          if (text !== "")
            text = "";
          else
            root.closeRequested();
        }

        Text {
          anchors.fill: parent
          text: "Search SSH hosts..."
          color: Colors.textDisabled
          font.pixelSize: Colors.fontSizeMedium
          visible: !searchInput.text && !searchInput.activeFocus
          verticalAlignment: Text.AlignVCenter
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
      visible: !sshData.importBusy && !root.hasHosts
      icon: "󰣀"
      iconSize: 48
      message: sshData.enableSshConfigImport ? "No SSH hosts found yet" : "No SSH hosts configured"
    }

    Text {
      visible: !sshData.importBusy && !root.hasHosts
      Layout.fillWidth: true
      text: sshData.enableSshConfigImport ? "Refresh import or add manual hosts in widget settings." : "Enable SSH config import or add manual hosts in widget settings."
      color: Colors.textSecondary
      font.pixelSize: Colors.fontSizeXS
      wrapMode: Text.WordWrap
      horizontalAlignment: Text.AlignHCenter
    }

    SharedWidgets.EmptyState {
      Layout.fillWidth: true
      Layout.topMargin: 32
      visible: !sshData.importBusy && root.hasHosts && root.hasSearchQuery && !root.hasFilteredHosts
      icon: "󰍉"
      iconSize: 48
      message: "No SSH hosts match \"" + root.searchQuery + "\""
    }

    Text {
      visible: !sshData.importBusy && root.hasHosts && root.hasSearchQuery && !root.hasFilteredHosts
      Layout.fillWidth: true
      text: "Try alias, hostname, user, group, or tag. Manage host entries in Bar Widgets settings."
      color: Colors.textSecondary
      font.pixelSize: Colors.fontSizeXS
      wrapMode: Text.WordWrap
      horizontalAlignment: Text.AlignHCenter
    }

    RowLayout {
      Layout.fillWidth: true
      visible: !sshData.importBusy
      spacing: Colors.spacingS

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
          spacing: Colors.spacingS

          Text {
            Layout.fillWidth: true
            text: String(modelData.subtitle || "")
            visible: text !== ""
            color: Colors.textSecondary
            font.pixelSize: Colors.fontSizeXS
            wrapMode: Text.WordWrap
          }

          Repeater {
            model: ScriptModel { values: modelData.hosts || [] }

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

                    Text {
                      text: sshData.hostSourceLabel(modelData)
                      visible: text !== ""
                      color: Colors.textDisabled
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
