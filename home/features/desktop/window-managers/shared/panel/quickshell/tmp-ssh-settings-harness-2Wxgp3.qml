import Quickshell
import QtQuick
import QtQuick.Layouts
import "./config/services"
import "./config/widgets" as SharedWidgets
import "./config/menu/settings/tabs"

Scope {
  id: root

  function scan(node, results) {
    if (!node)
      return;
    if (node.formPort !== undefined)
      results.sshSettingsNodes += 1;
    if (node.manualSearchQuery !== undefined)
      results.manualSearchNodes += 1;
    if (node.widgetInstance !== undefined && node.widgetInstance && String(node.widgetInstance.widgetType || "") === "ssh")
      results.sshBoundNodes += 1;
    var kids = node.children || [];
    for (var i = 0; i < kids.length; ++i)
      scan(kids[i], results);
  }

  SharedWidgets.SshWidgetSettings {
    id: directSettings
    widgetInstance: ({
      instanceId: "ssh-direct-1",
      widgetType: "ssh",
      enabled: true,
      settings: {
        manualHosts: [
          { id: "prod", label: "Prod", host: "prod.example.com", user: "root", port: 22, tags: ["ops"], group: "ops" }
        ],
        enableSshConfigImport: false
      }
    })
    visible: false
  }

  BarWidgetsTab {
    id: tab
    width: 960
    height: 760
    tabId: "bar-widgets"
    compactMode: true
    tightSpacing: false
    widgetSettingsOpen: true
    settingsSection: "left"
    settingsInstanceId: "ssh-left-1"
  }

  Component.onCompleted: {
    Config.load();
    Config.barConfigs = [{
      id: "bar-primary",
      name: "Primary",
      enabled: true,
      position: "top",
      sectionWidgets: {
        left: [
          {
            instanceId: "ssh-left-1",
            widgetType: "ssh",
            enabled: true,
            settings: {
              manualHosts: [
                { id: "manual-1", label: "Manual", host: "manual.example.com", user: "deploy", port: 22, tags: ["prod"], group: "ops" }
              ],
              enableSshConfigImport: false,
              displayMode: "recent"
            }
          }
        ],
        center: [],
        right: []
      }
    }];
    Config.selectedBarId = "bar-primary";
    tab.refreshEditingWidgetState();
    Qt.callLater(function() {
      var results = {
        directFilteredCount: directSettings.filteredManualHosts.length,
        directPortDefault: directSettings.formPort,
        editingWidgetType: tab.editingWidget ? String(tab.editingWidget.widgetType || "") : "",
        editingSchemaLength: tab.editingWidgetSchema ? tab.editingWidgetSchema.length : -1,
        widgetSettingsOpen: tab.widgetSettingsOpen,
        settingsInstanceId: tab.settingsInstanceId,
        sshSettingsNodes: 0,
        manualSearchNodes: 0,
        sshBoundNodes: 0
      };
      scan(tab, results);
      console.log("RESULT:" + JSON.stringify(results));
      Qt.quit();
    });
  }
}
