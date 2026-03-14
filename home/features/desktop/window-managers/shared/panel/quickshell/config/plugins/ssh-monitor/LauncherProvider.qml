import QtQuick

QtObject {
    id: root

    property var pluginApi: null
    property var pluginManifest: null
    property var pluginService: null

    property var pluginData: null

    function ensurePluginData() {
        if (pluginData)
            return pluginData;
        pluginData = pluginDataComponent.createObject(root, {
            pluginApi: root.pluginApi,
            pluginManifest: root.pluginManifest,
            pluginService: root.pluginService
        });
        return pluginData;
    }

    function syncPluginData() {
        var instance = ensurePluginData();
        if (!instance)
            return null;
        instance.pluginApi = root.pluginApi;
        instance.pluginManifest = root.pluginManifest;
        instance.pluginService = root.pluginService;
        instance.refresh();
        return instance;
    }

    function items(query, context) {
        var instance = syncPluginData();
        return instance ? instance.launcherItems(query) : [];
    }

    function execute(item, context) {
        var instance = syncPluginData();
        return instance ? instance.executeLauncherItem(item) : false;
    }

    function shutdown() {
        if (!pluginData)
            return;
        pluginData.destroy();
        pluginData = null;
    }

    onPluginApiChanged: syncPluginData()
    onPluginManifestChanged: syncPluginData()
    onPluginServiceChanged: syncPluginData()

    Component.onCompleted: syncPluginData()
    Component.onDestruction: shutdown()

    property Component pluginDataComponent: Component {
        SshPluginData {}
    }
}
