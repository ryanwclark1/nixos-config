import QtQuick
import Quickshell
import Quickshell.Io
import "../../services"
import "../../widgets" as SharedWidgets
import "../PanelWidgetHelpers.js" as PanelHelpers

Item {
    id: root
    property var widgetInstance: null
    required property var anchorWindow
    property bool vertical: false
    property real iconScale: 1.0
    property real fontScale: 1.0

    property string updatesIcon: "arrow-sync.svg"
    property string updatesCount: "0"
    readonly property bool iconOnly: PanelHelpers.isSummaryWidgetIconOnly(widgetInstance, vertical)

    visible: updatesCount !== "0" && updatesCount !== ""
    implicitWidth: visible ? updatesPill.width : 0
    implicitHeight: visible ? updatesPill.height : 0

    readonly property string _cacheDir: Quickshell.env("XDG_CACHE_HOME") !== ""
        ? Quickshell.env("XDG_CACHE_HOME") + "/quickshell/updates"
        : Quickshell.env("HOME") + "/.cache/quickshell/updates"

    FileView {
        id: _nixCacheFile
        path: root._cacheDir + "/nixos"
        watchChanges: true
        printErrors: false
        onTextChanged: root._updateFromCache()
    }

    FileView {
        id: _flatpakCacheFile
        path: root._cacheDir + "/flatpak"
        watchChanges: true
        printErrors: false
        onTextChanged: root._updateFromCache()
    }

    function _updateFromCache() {
        var nix = parseInt(String(_nixCacheFile.text() || "").trim(), 10) || 0;
        var flat = parseInt(String(_flatpakCacheFile.text() || "").trim(), 10) || 0;
        var total = Math.max(0, nix) + Math.max(0, flat);
        root.updatesCount = total > 0 ? total.toString() : "0";
        root.updatesIcon = total > 0 ? "arrow-sync.svg" : "arrow-sync.svg";
    }

    SharedWidgets.BarPill {
        id: updatesPill
        visible: root.visible
        anchors.centerIn: parent
        anchorWindow: root.anchorWindow
        tooltipText: "System updates"
        iconScale: root.iconScale
        fontScale: root.fontScale

        Row {
            spacing: Appearance.spacingXS * root.iconScale
            SharedWidgets.SvgIcon {
                source: root.updatesIcon
                color: Colors.accent
                size: Appearance.fontSizeXL * root.iconScale
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                visible: !root.iconOnly
                text: root.updatesCount
                color: Colors.text
                font.pixelSize: Appearance.fontSizeSmall * root.fontScale
                font.weight: Font.DemiBold
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
