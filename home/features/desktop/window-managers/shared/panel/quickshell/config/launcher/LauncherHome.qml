import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

ColumnLayout {
    id: root

    required property var launcher

    function resolvedIconSource(iconValue) {
        return Config.resolveIconSource(String(iconValue || ""));
    }

    function iconFallback(iconValue, fallbackValue) {
        var icon = String(iconValue || "");
        if (icon === "")
            return fallbackValue;
        return resolvedIconSource(icon) === "" ? icon : fallbackValue;
    }

    function primaryText(item) {
        if (!item)
            return "";
        return String(item.name || item.label || item.title || "");
    }

    function secondaryText(item) {
        if (!item)
            return "";

        var title = String(item.title || "");
        var description = String(item.description || "");
        var fullPath = String(item.fullPath || "");
        var exec = String(item.exec || "");
        var primary = primaryText(item);

        if (title !== "" && title !== primary)
            return title;
        if (description !== "" && description !== primary)
            return description;
        if (fullPath !== "" && fullPath !== primary)
            return fullPath;
        if (exec !== "" && exec !== primary)
            return exec;
        return "";
    }

    // Section 1: Featured actions
    Rectangle {
        Layout.fillWidth: true
        visible: root.launcher.showLauncherHome
        clip: true
        color: Colors.bgWidget
        radius: Colors.radiusMedium
        border.color: Colors.border
        border.width: 1
        implicitHeight: root.launcher.compactMode ? 116 : 130

        // Inner highlight lives on the card itself, not inside the layout flow.
        SharedWidgets.InnerHighlight {}

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Colors.spacingM
            spacing: Colors.spacingM

            SharedWidgets.SectionLabel {
                label: "FEATURED"
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: Colors.paddingSmall
                Repeater {
                    model: root.launcher.featuredActions
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 74
                        radius: Colors.radiusMedium
                        readonly property bool hovered: featureHover.containsMouse
                        color: hovered ? Colors.withAlpha(Colors.primary, 0.12) : Colors.surface
                        border.color: hovered ? Colors.primary : Colors.border
                        border.width: 1
                        scale: hovered ? 1.02 : 1.0
                        layer.enabled: hovered
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

                        // Depth border
                        SharedWidgets.InnerHighlight {
                            highlightOpacity: 0.15
                            hoveredOpacity: 0.3
                            hovered: parent.hovered
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Colors.spacingM
                            spacing: Colors.spacingXS
                            Text {
                                text: modelData.icon
                                color: Colors.primary
                                font.family: Colors.fontMono
                                font.pixelSize: Colors.fontSizeXL
                            }
                            Text {
                                text: modelData.label
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeSmall
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: modelData.description
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeXS
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        SharedWidgets.StateLayer {
                            id: featureStateLayer
                            hovered: featureHover.containsMouse
                            pressed: featureHover.pressed
                        }
                        MouseArea {
                            id: featureHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                featureStateLayer.burst(mouse.x, mouse.y);
                                root.launcher.activateFeatured(modelData);
                            }
                        }
                    }
                }
            }
        }
    }

    // Section 2: Category filters
    Rectangle {
        Layout.fillWidth: true
        visible: root.launcher.showLauncherHome && root.launcher.drunCategoryFiltersEnabled && root.launcher.mode === "drun" && root.launcher.drunCategoryOptions.length > 1
        clip: true
        color: Colors.bgWidget
        radius: Colors.radiusMedium
        border.color: Colors.border
        border.width: 1
        implicitHeight: categoryFilterFlow.implicitHeight + 30

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Colors.spacingM
            spacing: Colors.spacingS
            SharedWidgets.SectionLabel {
                label: "CATEGORIES • " + root.launcher.drunCategoryFilterLabel
            }
            Text {
                text: root.launcher.drunCategoryFilterSummary
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeXS
            }
            Flow {
                id: categoryFilterFlow
                Layout.fillWidth: true
                spacing: Colors.spacingS

                Repeater {
                    model: root.launcher.drunCategoryOptions
                    delegate: SharedWidgets.FilterChip {
                        required property var modelData

                        icon: modelData.hotkey === "0" ? "󰍉" : "󰌌"
                        label: String(modelData.label || "All") + " (" + String(modelData.count || 0) + ")" + (String(modelData.hotkey || "") !== "" ? (" [" + String(modelData.hotkey || "") + "]") : "")
                        selected: String(modelData.key || "") === root.launcher.drunCategoryFilter

                        onClicked: root.launcher.setDrunCategoryFilter(String(modelData.key || ""))
                    }
                }
            }
        }
    }

    // Section 3: Recent items
    Rectangle {
        Layout.fillWidth: true
        visible: root.launcher.showLauncherHome && root.launcher.recentItems.length > 0
        clip: true
        color: Colors.bgWidget
        radius: Colors.radiusMedium
        border.color: Colors.border
        border.width: 1
        implicitHeight: recentColumn.implicitHeight + 24

        ColumnLayout {
            id: recentColumn
            anchors.fill: parent
            anchors.margins: Colors.spacingM
            spacing: Colors.spacingS
            SharedWidgets.SectionLabel {
                label: "RECENT"
            }

            Repeater {
                model: root.launcher.recentItems
                delegate: Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 40
                    clip: true
                    radius: Colors.radiusSmall
                    readonly property bool hovered: recentHover.containsMouse
                    color: hovered ? Colors.withAlpha(Colors.primary, 0.08) : "transparent"
                    border.color: hovered ? Colors.withAlpha(Colors.primary, 0.28) : "transparent"
                    border.width: hovered ? 1 : 0
                    scale: hovered ? 1.01 : 1.0
                    layer.enabled: hovered
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

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Colors.spacingS
                        spacing: Colors.paddingSmall
                        Rectangle {
                            implicitWidth: 28
                            implicitHeight: 28
                            radius: Colors.radiusXS
                            color: hovered ? Colors.withAlpha(Colors.primary, 0.12) : Colors.surface
                            border.color: hovered ? Colors.withAlpha(Colors.primary, 0.24) : "transparent"
                            border.width: hovered ? 1 : 0
                            Layout.alignment: Qt.AlignVCenter

                            Image {
                                id: recentIconImage
                                anchors.fill: parent
                                anchors.margins: Colors.spacingXS
                                source: root.resolvedIconSource(modelData ? modelData.icon : "")
                                sourceSize: Qt.size(56, 56)
                                asynchronous: true
                                fillMode: Image.PreserveAspectFit
                                visible: source !== "" && status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                text: root.iconFallback(modelData ? modelData.icon : "", "󰀻")
                                color: Colors.primary
                                font.family: Colors.fontMono
                                font.pixelSize: Colors.fontSizeMedium
                                visible: !recentIconImage.visible
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 0
                            Text {
                                text: root.primaryText(modelData)
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeSmall
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                                maximumLineCount: 1
                                Layout.fillWidth: true
                            }
                            Text {
                                text: root.secondaryText(modelData)
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeXS
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                                maximumLineCount: 1
                                Layout.fillWidth: true
                                visible: text !== ""
                            }
                        }
                    }

                    SharedWidgets.StateLayer {
                        id: recentStateLayer
                        hovered: recentHover.containsMouse
                        pressed: recentHover.pressed
                    }
                    MouseArea {
                        id: recentHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            recentStateLayer.burst(mouse.x, mouse.y);
                            root.launcher.activateFeatured(modelData);
                        }
                    }
                }
            }
        }
    }

    // Section 4: Suggestions
    Rectangle {
        Layout.fillWidth: true
        visible: root.launcher.showLauncherHome && root.launcher.mode === "drun" && root.launcher.suggestionItems.length > 0
        clip: true
        color: Colors.bgWidget
        radius: Colors.radiusMedium
        border.color: Colors.border
        border.width: 1
        implicitHeight: suggestionColumn.implicitHeight + 24

        ColumnLayout {
            id: suggestionColumn
            anchors.fill: parent
            anchors.margins: Colors.spacingM
            spacing: Colors.spacingS
            SharedWidgets.SectionLabel {
                label: "SUGGESTED"
            }

            Repeater {
                model: root.launcher.suggestionItems
                delegate: Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 42
                    clip: true
                    radius: Colors.radiusSmall
                    readonly property bool hovered: suggestionHover.containsMouse
                    color: hovered ? Colors.withAlpha(Colors.primary, 0.08) : "transparent"
                    border.color: hovered ? Colors.withAlpha(Colors.primary, 0.28) : "transparent"
                    border.width: hovered ? 1 : 0
                    scale: hovered ? 1.01 : 1.0
                    layer.enabled: hovered
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

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Colors.spacingS
                        spacing: Colors.paddingSmall
                        Rectangle {
                            implicitWidth: 28
                            implicitHeight: 28
                            radius: Colors.radiusXS
                            color: hovered ? Colors.withAlpha(Colors.primary, 0.12) : Colors.surface
                            border.color: hovered ? Colors.withAlpha(Colors.primary, 0.24) : "transparent"
                            border.width: hovered ? 1 : 0
                            Layout.alignment: Qt.AlignVCenter

                            Image {
                                id: suggestionIconImage
                                anchors.fill: parent
                                anchors.margins: Colors.spacingXS
                                source: root.resolvedIconSource(modelData ? modelData.icon : "")
                                sourceSize: Qt.size(56, 56)
                                asynchronous: true
                                fillMode: Image.PreserveAspectFit
                                visible: source !== "" && status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                text: root.iconFallback(modelData ? modelData.icon : "", "󰀻")
                                color: Colors.primary
                                font.family: Colors.fontMono
                                font.pixelSize: Colors.fontSizeMedium
                                visible: !suggestionIconImage.visible
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 0
                            Text {
                                text: root.primaryText(modelData)
                                color: Colors.text
                                font.pixelSize: Colors.fontSizeSmall
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                                maximumLineCount: 1
                                Layout.fillWidth: true
                            }
                            Text {
                                text: root.secondaryText(modelData) || "Frequently used"
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeXS
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                                maximumLineCount: 1
                                Layout.fillWidth: true
                            }
                        }
                        Rectangle {
                            radius: height / 2
                            color: Colors.surface
                            border.color: Colors.border
                            border.width: 1
                            implicitWidth: suggestionBadge.implicitWidth + 16
                            implicitHeight: 22
                            Text {
                                id: suggestionBadge
                                anchors.centerIn: parent
                                text: (modelData._usage || 0) + "x"
                                color: Colors.textSecondary
                                font.pixelSize: Colors.fontSizeXS
                                font.weight: Font.Medium
                            }
                        }
                    }

                    SharedWidgets.StateLayer {
                        id: suggestionStateLayer
                        hovered: suggestionHover.containsMouse
                        pressed: suggestionHover.pressed
                    }
                    MouseArea {
                        id: suggestionHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            suggestionStateLayer.burst(mouse.x, mouse.y);
                            root.launcher.selectedIndex = 0;
                            if (modelData.exec) {
                                root.launcher.trackLaunch(modelData);
                                root.launcher.launchExecString(modelData.exec, modelData.terminal === "true" || modelData.terminal === "True");
                                root.launcher.close();
                            }
                        }
                    }
                }
            }
        }
    }
}
