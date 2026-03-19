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
    property int selectedIndex: -1
    property string searchText: ""
    property string mode: "drun"
    property bool compactMode: false
    property bool tightMode: false
    property bool ignoreMouseHover: false
    property var modeIcons: ({})
    property var iconMap: ({})

    signal clicked
    signal entered
    signal secondaryActionRequested(real globalX, real globalY)

    width: parent ? parent.width : 0
    height: tightMode ? 48 : (compactMode ? 54 : 64)

    readonly property bool highlighted: itemIndex === selectedIndex
    readonly property bool hovered: resultHover.containsMouse && !ignoreMouseHover

    color: highlighted ? Colors.highlight : (hovered ? Colors.withAlpha("#ffffff", 0.04) : "transparent")
    radius: Colors.radiusMedium
    border.color: highlighted ? Colors.withAlpha(Colors.primary, 0.4) : (hovered ? Colors.withAlpha(Colors.border, 0.5) : "transparent")
    border.width: 1
    scale: highlighted ? 1.01 : 1.0

    Behavior on color { CAnim {} }
    Behavior on border.color { CAnim {} }
    Behavior on scale { NumberAnimation { duration: Colors.durationMedium; easing.type: Easing.OutCubic } }
    layer.enabled: highlighted && scale !== 1.0

    // Glow Effect
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        z: -1
        color: Colors.primary
        opacity: highlighted ? 0.08 : 0
        visible: highlighted
        Behavior on opacity { NumberAnimation { duration: Colors.durationNormal } }
    }

    function highlightMatch(text, query) {
        return Search.highlightMatch(text, query, ModeData.stripModePrefix);
    }

    function itemActionLabel(it) {
        if (!it)
            return "";
        if (it.ipcTarget && it.ipcAction)
            return "System";
        if (it.isCalc)
            return "Calculator";
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
        var description = String(it.description || "");
        var fullPath = String(it.fullPath || "");
        var exec = String(it.exec || "");
        var windowAppId = String(it.appId || it.class || "");
        var title = String(it.title || "");

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

    // Indicator bar
    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.verticalCenter: parent.verticalCenter
        width: highlighted ? 4 : 0
        height: highlighted ? parent.height * 0.5 : 0
        radius: Colors.radiusPill
        color: Colors.primary
        opacity: highlighted ? 1.0 : 0.0
        Behavior on height { NumberAnimation { duration: Colors.durationNormal; easing.type: Easing.OutBack } }
        Behavior on width { NumberAnimation { duration: Colors.durationMedium } }
        Behavior on opacity { NumberAnimation { duration: Colors.durationFast } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.compactMode ? (Colors.spacingS + 4) : (Colors.spacingM + 4)
        anchors.rightMargin: root.compactMode ? Colors.spacingS : Colors.spacingM
        spacing: root.compactMode ? Colors.paddingSmall : Colors.paddingMedium

        // Icon area
        Rectangle {
            width: root.compactMode ? 30 : 34
            height: root.compactMode ? 30 : 34
            radius: Colors.radiusXS
            color: highlighted ? Colors.primaryAccent : (hovered ? Colors.primaryFaint : Colors.surface)
            border.color: highlighted ? Colors.primaryRing : "transparent"
            border.width: highlighted ? 1 : 0
            scale: highlighted ? 1.04 : 1.0

            Behavior on color {
                CAnim {}
            }
            Behavior on border.color {
                CAnim {}
            }
            Behavior on scale {
                Anim { duration: Colors.durationFast }
            }

            SharedWidgets.AppIcon {
                anchors.centerIn: parent
                iconName: root.itemIconName(itemData)
                desktopId: itemData ? String(itemData.desktopId || "") : ""
                appId: itemData ? String(itemData.appId || itemData.class || "") : ""
                execName: itemData ? String(itemData.exec || "") : ""
                appName: itemData ? String(itemData.name || itemData.title || "") : ""
                iconMap: root.iconMap
                iconSize: root.compactMode ? 18 : 20
                fallbackIcon: root.itemFallbackIcon(itemData)
            }
        }

        ColumnLayout {
            spacing: Colors.spacingXXS
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Text {
                text: root.highlightMatch(itemData ? itemData.name || itemData.title || "" : "", root.searchText)
                color: highlighted ? Colors.primary : Colors.text
                textFormat: Text.StyledText
                font.pixelSize: root.compactMode ? Colors.fontSizeSmall : Colors.fontSizeMedium
                font.weight: highlighted ? Font.Bold : Font.Normal
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                maximumLineCount: 1
                Layout.fillWidth: true
                Layout.minimumWidth: 0
            }
            Text {
                text: root.itemSecondaryLabel(itemData)
                color: highlighted ? Colors.withAlpha(Colors.primary, 0.82) : Colors.textSecondary
                font.pixelSize: Colors.fontSizeXS
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                maximumLineCount: 1
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                visible: text !== ""
            }
        }

        RowLayout {
            spacing: Colors.spacingXS
            Layout.maximumWidth: root.compactMode ? 160 : 220
            Layout.alignment: Qt.AlignVCenter

            // Provider Badge
            Rectangle {
                property string provider: root.itemProviderLabel(itemData)
                visible: provider !== ""
                radius: Colors.radiusPill
                color: highlighted ? Colors.primaryMarked : Colors.highlight
                border.color: Colors.withAlpha(Colors.primary, 0.45)
                border.width: 1
                implicitHeight: 22
                implicitWidth: providerBadgeText.implicitWidth + 12
                Text {
                    id: providerBadgeText
                    anchors.centerIn: parent
                    text: parent.provider
                    color: Colors.primary
                    font.pixelSize: Colors.fontSizeXS
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, root.mode === "files" ? (root.compactMode ? 110 : 160) : (root.compactMode ? 84 : 120))
                }
            }

            // Action Badge
            Rectangle {
                property string action: root.itemActionLabel(itemData)
                visible: action !== ""
                radius: Colors.radiusPill
                color: highlighted ? Colors.primaryMid : Colors.surface
                border.color: Colors.border
                border.width: 1
                implicitHeight: 22
                implicitWidth: actionBadgeText.implicitWidth + 12
                Text {
                    id: actionBadgeText
                    anchors.centerIn: parent
                    text: parent.action
                    color: highlighted ? Colors.primary : Colors.textSecondary
                    font.pixelSize: Colors.fontSizeXS
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, root.compactMode ? 72 : 96)
                }
            }

            // Execute icon
            Rectangle {
                width: root.compactMode ? 24 : 28
                height: root.compactMode ? 24 : 28
                radius: Colors.radiusMedium
                visible: highlighted || hovered
                color: highlighted ? Colors.primaryMid : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: "󰄮"
                    color: highlighted ? Colors.primary : Colors.textDisabled
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeSmall
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
                var target = root.window ? root.window.contentItem : null;
                var point = root.mapToItem(target, mouse.x, mouse.y);
                root.secondaryActionRequested(point.x, point.y);
                return;
            }
            root.clicked();
        }
    }
}
