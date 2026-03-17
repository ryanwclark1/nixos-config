import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

Rectangle {
    id: root
    property var modelData: null
    property int index: -1
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

    width: parent ? parent.width : 0
    height: tightMode ? 48 : (compactMode ? 52 : 58)

    readonly property bool highlighted: index === selectedIndex
    readonly property bool hovered: resultHover.containsMouse && !ignoreMouseHover

    color: highlighted ? Colors.withAlpha(Colors.primary, 0.12) : (hovered ? Colors.withAlpha(Colors.primary, 0.05) : "transparent")
    radius: Colors.radiusSmall
    border.color: highlighted ? Colors.withAlpha(Colors.primary, 0.58) : (hovered ? Colors.withAlpha(Colors.primary, 0.18) : "transparent")
    border.width: highlighted || hovered ? 1 : 0
    scale: highlighted ? 1.012 : (hovered ? 1.004 : 1.0)

    Behavior on color {
        ColorAnimation {
            duration: Colors.durationFast
        }
    }
    Behavior on border.color {
        ColorAnimation {
            duration: Colors.durationFast
        }
    }
    Behavior on scale {
        NumberAnimation {
            duration: Colors.durationFast
            easing.type: Easing.OutCubic
        }
    }

    function highlightMatch(text, query) {
        if (!query)
            return text;
        var escaped = query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        var regex = new RegExp("(" + escaped + ")", "gi");
        return text.replace(regex, "<b>$1</b>");
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
        if (it.providerName)
            return it.providerName;
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
        var windowClass = String(it.class || "");
        var title = String(it.title || "");

        if (description !== "" && description !== primary)
            return description;
        if (fullPath !== "" && fullPath !== primary)
            return fullPath;
        if (windowClass !== "" && windowClass !== primary)
            return windowClass;
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
            return String(it.class || "");
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
        anchors.leftMargin: root.compactMode ? 4 : 6
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: highlighted ? Math.max(22, parent.height - (root.compactMode ? 18 : 16)) : (hovered ? 18 : 0)
        radius: width / 2
        color: Colors.primary
        opacity: highlighted ? 0.95 : (hovered ? 0.4 : 0.0)
        Behavior on height {
            NumberAnimation {
                duration: Colors.durationFast
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: Colors.durationSnap
            }
        }
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
            color: highlighted ? Colors.withAlpha(Colors.primary, 0.14) : (hovered ? Colors.withAlpha(Colors.primary, 0.08) : Colors.surface)
            border.color: highlighted ? Colors.withAlpha(Colors.primary, 0.3) : "transparent"
            border.width: highlighted ? 1 : 0
            scale: highlighted ? 1.04 : 1.0

            Behavior on color {
                ColorAnimation {
                    duration: Colors.durationFast
                }
            }
            Behavior on border.color {
                ColorAnimation {
                    duration: Colors.durationFast
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: Colors.durationFast
                    easing.type: Easing.OutCubic
                }
            }

            SharedWidgets.AppIcon {
                anchors.centerIn: parent
                iconName: root.itemIconName(modelData)
                appName: modelData ? String(modelData.name || modelData.title || "") : ""
                iconMap: root.mode === "window" ? root.iconMap : null
                iconSize: root.compactMode ? 18 : 20
                fallbackIcon: root.itemFallbackIcon(modelData)
            }
        }

        ColumnLayout {
            spacing: 1
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Text {
                text: root.highlightMatch(modelData ? modelData.name || modelData.title || "" : "", root.searchText)
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
                text: root.itemSecondaryLabel(modelData)
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
                property string provider: root.itemProviderLabel(modelData)
                visible: provider !== ""
                radius: Colors.radiusPill
                color: highlighted ? Colors.withAlpha(Colors.primary, 0.22) : Colors.highlight
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
                    width: Math.min(implicitWidth, root.compactMode ? 84 : 120)
                }
            }

            // Action Badge
            Rectangle {
                property string action: root.itemActionLabel(modelData)
                visible: action !== ""
                radius: Colors.radiusPill
                color: highlighted ? Colors.withAlpha(Colors.primary, 0.18) : Colors.surface
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
                color: highlighted ? Colors.withAlpha(Colors.primary, 0.18) : "transparent"
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
        cursorShape: Qt.PointingHandCursor
        onEntered: root.entered()
        onClicked: root.clicked()
    }
}
