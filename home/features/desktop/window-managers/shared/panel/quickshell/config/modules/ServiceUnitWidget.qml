import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

SharedWidgets.CardBase {
    id: root

    property string searchQuery: ""
    property string filterMode: "failed"
    property bool showSystemUnits: false
    property int defaultLimit: 5
    property int searchLimit: 10
    readonly property var visibleUserUnits: filterUnits(ServiceUnitService.userUnits)
    readonly property var visibleSystemUnits: filterUnits(ServiceUnitService.systemUnits)
    readonly property bool systemAvailable: ServiceUnitService.systemStatus === "ready"

    Layout.fillWidth: true
    Layout.preferredHeight: unitsColumn.implicitHeight + root.pad * 2

    function matchesQuery(unit) {
        var query = String(searchQuery || "").trim().toLowerCase();
        if (query === "")
            return true;

        var haystack = [String(unit.name || ""), String(unit.description || ""), String(unit.active || ""), String(unit.sub || "")].join(" ").toLowerCase();
        return haystack.indexOf(query) !== -1;
    }

    function matchesFilter(unit) {
        var mode = String(filterMode || "failed");
        if (mode === "all")
            return true;
        if (mode === "busy")
            return String(unit.active || "") === "activating" || String(unit.sub || "").indexOf("running") === -1;
        return String(unit.active || "") === "failed" || String(unit.sub || "") === "failed";
    }

    function filterUnits(source) {
        var units = source || [];
        var filtered = [];
        for (var i = 0; i < units.length; i++) {
            var unit = units[i];
            if (!matchesQuery(unit) || !matchesFilter(unit))
                continue;
            filtered.push(unit);
        }
        filtered.sort(function (a, b) {
            return root.unitPriority(a) - root.unitPriority(b);
        });
        var limit = String(searchQuery || "").trim() === "" ? defaultLimit : searchLimit;
        return filtered.slice(0, limit);
    }

    function unitPriority(unit) {
        var active = String(unit.active || "");
        var sub = String(unit.sub || "");
        if (active === "failed" || sub === "failed")
            return 0;
        if (active === "activating" || active === "reloading")
            return 1;
        if (sub.indexOf("auto-restart") !== -1 || sub.indexOf("dead") !== -1)
            return 2;
        return 3;
    }

    function stateColor(unit) {
        var active = String(unit.active || "");
        if (active === "failed")
            return Colors.error;
        if (active === "active")
            return Colors.success;
        if (active === "activating" || active === "reloading")
            return Colors.warning;
        return Colors.textSecondary;
    }

    function running(unit) {
        return String(unit.active || "") === "active" && String(unit.sub || "").indexOf("running") !== -1;
    }

    ColumnLayout {
        id: unitsColumn
        Layout.fillWidth: true
        spacing: Colors.spacingS

        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingS

            Text {
                text: "SERVICES"
                color: Colors.textDisabled
                font.pixelSize: Colors.fontSizeXS
                font.weight: Font.Bold
            }

            Item {
                Layout.fillWidth: true
            }

            SharedWidgets.IconButton {
                icon: "󰑐"
                size: 28
                iconSize: Colors.fontSizeSmall
                iconColor: Colors.textSecondary
                onClicked: ServiceUnitService.refresh()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 38
            radius: Colors.radiusSmall
            color: Colors.highlightLight
            border.color: unitSearchInput.activeFocus ? Colors.primary : "transparent"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: Colors.spacingS
                spacing: Colors.spacingS

                Text {
                    text: "󰍉"
                    color: Colors.textDisabled
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeMedium
                }

                TextInput {
                    id: unitSearchInput
                    Layout.fillWidth: true
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeSmall
                    verticalAlignment: Text.AlignVCenter
                    onTextChanged: root.searchQuery = text
                }

                Text {
                    text: "Filter services..."
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeSmall
                    visible: !unitSearchInput.text && !unitSearchInput.activeFocus
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingS

            SharedWidgets.FilterChip {
                label: "Failed"
                selected: root.filterMode === "failed"
                onClicked: root.filterMode = "failed"
            }

            SharedWidgets.FilterChip {
                label: "Busy"
                selected: root.filterMode === "busy"
                onClicked: root.filterMode = "busy"
            }

            SharedWidgets.FilterChip {
                label: "All"
                selected: root.filterMode === "all"
                onClicked: root.filterMode = "all"
            }
        }

        Text {
            Layout.fillWidth: true
            text: ServiceUnitService.userStatus === "ready" ? ("User units  •  " + String(root.visibleUserUnits.length)) : (ServiceUnitService.userMessage || "User services unavailable")
            color: Colors.fgDim
            font.pixelSize: Colors.fontSizeXS
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingXS
            visible: ServiceUnitService.userStatus === "ready" && visibleUserUnits.length > 0

            Repeater {
                model: root.visibleUserUnits

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    radius: Colors.radiusSmall
                    color: Colors.highlightLight
                    border.color: Colors.withAlpha(root.stateColor(modelData), 0.65)
                    border.width: 1
                    implicitHeight: unitColumn.implicitHeight + Colors.spacingS * 2

                    ColumnLayout {
                        id: unitColumn
                        anchors.fill: parent
                        anchors.margins: Colors.spacingS
                        spacing: Colors.spacingXS

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Colors.spacingS

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: modelData.name || "service"
                                    color: Colors.text
                                    font.pixelSize: Colors.fontSizeSmall
                                    font.weight: Font.DemiBold
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: modelData.description || modelData.sub || ""
                                    color: Colors.textSecondary
                                    font.pixelSize: Colors.fontSizeXS
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }

                            Text {
                                text: String(modelData.active || "unknown").toUpperCase()
                                color: root.stateColor(modelData)
                                font.pixelSize: Colors.fontSizeXS
                                font.weight: Font.Bold
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Colors.spacingS

                            SharedWidgets.FilterChip {
                                label: root.running(modelData) ? "Stop" : "Start"
                                icon: root.running(modelData) ? "󰓛" : "󰐊"
                                enabled: !ServiceUnitService.isUnitPending("user", modelData.name)
                                selected: false
                                onClicked: {
                                    if (root.running(modelData))
                                        ServiceUnitService.stopUnit("user", modelData.name);
                                    else
                                        ServiceUnitService.startUnit("user", modelData.name);
                                }
                            }

                            SharedWidgets.FilterChip {
                                label: "Restart"
                                icon: "󰑐"
                                enabled: !ServiceUnitService.isUnitPending("user", modelData.name)
                                selected: false
                                onClicked: ServiceUnitService.restartUnit("user", modelData.name)
                            }

                            Text {
                                text: ServiceUnitService.pendingActionForUnit("user", modelData.name).toUpperCase()
                                color: Colors.warning
                                font.pixelSize: Colors.fontSizeXS
                                visible: ServiceUnitService.isUnitPending("user", modelData.name)
                            }
                        }
                    }
                }
            }
        }

        SharedWidgets.EmptyState {
            Layout.fillWidth: true
            visible: ServiceUnitService.userStatus === "ready" && visibleUserUnits.length === 0
            icon: "󰜺"
            message: String(searchQuery || "").trim() === "" ? "No matching user services for this filter." : "No user services match the current search."
        }

        Rectangle {
            Layout.fillWidth: true
            visible: ServiceUnitService.userStatus !== "ready"
            color: Colors.bgWidget
            radius: Colors.radiusSmall
            border.color: Colors.border
            border.width: 1
            implicitHeight: userUnavailable.implicitHeight + Colors.spacingS * 2

            SharedWidgets.EmptyState {
                id: userUnavailable
                anchors.centerIn: parent
                icon: "󰅚"
                message: ServiceUnitService.userMessage || "User services unavailable."
            }
        }

        Rectangle {
            Layout.fillWidth: true
            radius: Colors.radiusSmall
            color: Colors.bgWidget
            border.color: Colors.border
            border.width: 1
            implicitHeight: systemHeader.implicitHeight + Colors.spacingS * 2

            RowLayout {
                id: systemHeader
                anchors.fill: parent
                anchors.margins: Colors.spacingS
                spacing: Colors.spacingS

                Text {
                    text: "SYSTEM UNITS"
                    color: Colors.textDisabled
                    font.pixelSize: Colors.fontSizeXS
                    font.weight: Font.Bold
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    text: ServiceUnitService.systemStatus === "ready" ? String(ServiceUnitService.systemUnits.length) : (ServiceUnitService.systemMessage || "unavailable")
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeXS
                }

                SharedWidgets.FilterChip {
                    label: root.showSystemUnits ? "Hide" : "Show"
                    selected: root.showSystemUnits
                    enabled: root.systemAvailable
                    onClicked: root.showSystemUnits = !root.showSystemUnits
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingXS
            visible: root.showSystemUnits && root.systemAvailable && visibleSystemUnits.length > 0

            Repeater {
                model: root.visibleSystemUnits

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    radius: Colors.radiusSmall
                    color: Colors.bgWidget
                    border.color: Colors.withAlpha(root.stateColor(modelData), 0.55)
                    border.width: 1
                    implicitHeight: systemUnitColumn.implicitHeight + Colors.spacingS * 2

                    ColumnLayout {
                        id: systemUnitColumn
                        anchors.fill: parent
                        anchors.margins: Colors.spacingS
                        spacing: Colors.spacingXS

                        Text {
                            text: modelData.name || "service"
                            color: Colors.text
                            font.pixelSize: Colors.fontSizeSmall
                            font.weight: Font.Medium
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: (modelData.description || "") + "  •  " + String(modelData.active || "unknown")
                            color: root.stateColor(modelData)
                            font.pixelSize: Colors.fontSizeXS
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Colors.spacingS

                            SharedWidgets.FilterChip {
                                label: "Restart"
                                icon: "󰑐"
                                enabled: !ServiceUnitService.isUnitPending("system", modelData.name)
                                selected: false
                                onClicked: ServiceUnitService.restartUnit("system", modelData.name)
                            }

                            SharedWidgets.FilterChip {
                                label: root.running(modelData) ? "Stop" : "Start"
                                icon: root.running(modelData) ? "󰓛" : "󰐊"
                                enabled: !ServiceUnitService.isUnitPending("system", modelData.name)
                                selected: false
                                onClicked: {
                                    if (root.running(modelData))
                                        ServiceUnitService.stopUnit("system", modelData.name);
                                    else
                                        ServiceUnitService.startUnit("system", modelData.name);
                                }
                            }
                        }
                    }
                }
            }
        }

        SharedWidgets.EmptyState {
            Layout.fillWidth: true
            visible: root.showSystemUnits && root.systemAvailable && visibleSystemUnits.length === 0
            icon: "󰜺"
            message: String(searchQuery || "").trim() === "" ? "No system units matched the current filter." : "No system units match the current search."
        }

        Rectangle {
            Layout.fillWidth: true
            visible: root.showSystemUnits && !root.systemAvailable
            color: Colors.bgWidget
            radius: Colors.radiusSmall
            border.color: Colors.border
            border.width: 1
            implicitHeight: systemUnavailable.implicitHeight + Colors.spacingS * 2

            SharedWidgets.EmptyState {
                id: systemUnavailable
                anchors.centerIn: parent
                icon: "󰅚"
                message: ServiceUnitService.systemMessage || "System services unavailable."
            }
        }
    }
}
