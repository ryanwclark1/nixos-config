import QtQuick
import QtQuick.Layouts
import "../services"
import "../shared"
import "../widgets" as SharedWidgets
import "LauncherSearch.js" as Search
import "LauncherModeData.js" as ModeData

Rectangle {
    id: root

    property var itemData: null
    property int itemIndex: -1
    property string searchText: ""
    property string mode: "drun"
    property bool compactMode: false
    property bool tightMode: false
    property bool ignoreMouseHover: false
    property var modeIcons: ({})
    property var iconMap: ({})
    property color accentColor: Colors.primary

    signal clicked
    signal entered
    signal secondaryActionRequested(var sourceItem, real localX, real localY)

    width: ListView.view ? ListView.view.width : (parent ? parent.width : 0)
    height: tightMode ? 54 : (compactMode ? 60 : 70)

    readonly property bool highlighted: ListView.isCurrentItem
    readonly property bool hovered: resultHover.containsMouse && !ignoreMouseHover

    color: highlighted ? Colors.withAlpha(accentColor, 0.16) : (hovered ? Colors.withAlpha(Colors.surface, 0.82) : "transparent")
    radius: Colors.radiusLarge
    border.color: highlighted ? Colors.withAlpha(accentColor, 0.38) : (hovered ? Colors.withAlpha(Colors.border, 0.42) : "transparent")
    border.width: 1
    scale: highlighted ? 1.01 : 1.0

    SharedWidgets.InnerHighlight {
        hovered: root.highlighted || root.hovered
        highlightOpacity: root.highlighted ? 0.2 : 0.08
    }

    Behavior on color { enabled: !Colors.isTransitioning && (highlighted || hovered); CAnim {} }
    Behavior on border.color { enabled: !Colors.isTransitioning && (highlighted || hovered); CAnim {} }
    Behavior on scale { enabled: highlighted || hovered; NumberAnimation { duration: Colors.durationMedium; easing.type: Easing.OutCubic } }
    layer.enabled: highlighted && scale !== 1.0

    function highlightMatch(text, query) {
        return Search.highlightMatch(text, query, ModeData.stripModePrefix, root.mode === "files");
    }

    function itemActionLabel(it) {
        if (!it)
            return "";
        if (String(it.entryKind || "") === "settings")
            return "Jump";
        if (String(it.entryKind || "") === "destination")
            return "Open";
        if (it.ipcTarget && it.ipcAction)
            return "System";
        if (it.isCalc)
            return "Calc";
        if (it.fullPath)
            return "File";
        if (it.url)
            return "Bookmark";
        return "";
    }

    function itemProviderLabel(it) {
        if (!it)
            return "";
        if (root.mode === "emoji")
            return String(it.categoryLabel || it.category || "");
        if (it.providerName)
            return it.providerName;
        if (root.mode === "files") {
            var extension = String(it.extension || "");
            if (extension !== "")
                return extension.toUpperCase();
        }
        if (root.mode === "web")
            return it.category || "";
        return "";
    }

    function itemSecondaryLabel(it) {
        if (!it)
            return "";

        var primary = String(it.name || it.title || "");
        var breadcrumb = String(it.breadcrumb || "");
        var description = String(it.description || "");
        var fullPath = String(it.fullPath || "");
        var exec = String(it.exec || "");
        var windowAppId = String(it.appId || it.class || "");
        var title = String(it.title || "");

        if (breadcrumb !== "" && breadcrumb !== primary)
            return breadcrumb;
        if (description !== "" && description !== primary)
            return description;
        if (root.mode === "files") {
            var displayPath = String(it.displayPath || "");
            if (displayPath !== "")
                return displayPath;
        }
        if (fullPath !== "" && fullPath !== primary)
            return fullPath;
        if (windowAppId !== "" && windowAppId !== primary)
            return windowAppId;
        if (title !== "" && title !== primary)
            return title;
        if (exec !== "" && exec !== primary)
            return exec;
        return "";
    }

    function itemIconName(it) {
        if (!it)
            return "";
        var explicitIcon = String(it.icon || "");
        if (explicitIcon !== "")
            return explicitIcon;
        if (root.mode === "window")
            return String(it.appId || it.class || "");
        return "";
    }

    function itemFallbackIcon(it) {
        if (root.mode === "window")
            return "󰖯";
        if (root.mode === "files")
            return "󰈔";
        if (root.mode === "web")
            return "󰖟";
        return root.modeIcons[root.mode] || "󰀻";
    }

    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: highlighted ? 5 : 0
        radius: Colors.radiusPill
        color: root.accentColor
        opacity: highlighted ? 1.0 : 0.0
        Behavior on width { NumberAnimation { duration: Colors.durationFast } }
        Behavior on opacity { NumberAnimation { duration: Colors.durationFast } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.compactMode ? Colors.spacingM : Colors.spacingL
        anchors.rightMargin: root.compactMode ? Colors.spacingS : Colors.spacingM
        spacing: root.compactMode ? Colors.spacingS : Colors.paddingMedium

        Rectangle {
            width: root.compactMode ? 34 : 40
            height: root.compactMode ? 34 : 40
            radius: root.compactMode ? Colors.radiusMedium : Colors.radiusLarge
            color: highlighted ? Colors.withAlpha(root.accentColor, 0.16) : (hovered ? Colors.withAlpha(Colors.surface, 0.78) : Colors.withAlpha(Colors.surface, 0.66))
            border.color: highlighted ? Colors.withAlpha(root.accentColor, 0.34) : Colors.withAlpha(Colors.border, 0.24)
            border.width: 1

            SharedWidgets.AppIcon {
                anchors.centerIn: parent
                iconName: root.itemIconName(itemData)
                desktopId: itemData ? String(itemData.desktopId || "") : ""
                appId: itemData ? String(itemData.appId || itemData.class || "") : ""
                execName: itemData ? String(itemData.exec || "") : ""
                appName: itemData ? String(itemData.name || itemData.title || "") : ""
                iconMap: root.iconMap
                iconSize: root.compactMode ? 19 : 22
                fallbackIcon: root.itemFallbackIcon(itemData)
            }
        }

        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true
            Layout.minimumWidth: 0

            Text {
                text: root.highlightMatch(itemData ? itemData.name || itemData.title || "" : "", root.searchText)
                color: highlighted ? Colors.text : Colors.text
                textFormat: Text.StyledText
                font.pixelSize: root.compactMode ? Colors.fontSizeSmall : Colors.fontSizeMedium
                font.weight: highlighted ? Font.Bold : Font.DemiBold
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                maximumLineCount: 1
                Layout.fillWidth: true
                Layout.minimumWidth: 0
            }

            Text {
                text: root.itemSecondaryLabel(itemData)
                color: highlighted ? Colors.withAlpha(root.accentColor, 0.84) : Colors.textSecondary
                font.pixelSize: Colors.fontSizeXS
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                maximumLineCount: 1
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                visible: text !== ""
            }
        }

        ColumnLayout {
            spacing: Colors.spacingXS
            Layout.alignment: Qt.AlignVCenter
            visible: !root.tightMode

            Rectangle {
                property string provider: root.itemProviderLabel(itemData)
                visible: provider !== ""
                radius: Colors.radiusPill
                color: Colors.withAlpha(root.accentColor, highlighted ? 0.14 : 0.08)
                border.color: Colors.withAlpha(root.accentColor, highlighted ? 0.3 : 0.16)
                border.width: 1
                implicitHeight: 20
                implicitWidth: providerBadgeText.implicitWidth + 12

                Text {
                    id: providerBadgeText
                    anchors.centerIn: parent
                    text: parent.provider
                    color: highlighted ? root.accentColor : Colors.textSecondary
                    font.pixelSize: Colors.fontSizeXXS
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, root.mode === "files" ? (root.compactMode ? 100 : 140) : (root.compactMode ? 82 : 110))
                }
            }

            Rectangle {
                property string action: root.itemActionLabel(itemData)
                visible: action !== ""
                radius: Colors.radiusPill
                color: Colors.withAlpha(Colors.surface, 0.84)
                border.color: Colors.withAlpha(Colors.border, 0.5)
                border.width: 1
                implicitHeight: 20
                implicitWidth: actionBadgeText.implicitWidth + 12

                Text {
                    id: actionBadgeText
                    anchors.centerIn: parent
                    text: parent.action
                    color: highlighted ? Colors.text : Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXXS
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, root.compactMode ? 70 : 92)
                }
            }
        }

    }

    MouseArea {
        id: resultHover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onEntered: root.entered()
        onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
                root.secondaryActionRequested(root, mouse.x, mouse.y);
                return;
            }
            root.clicked();
        }
    }
}
