import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../widgets" as SharedWidgets
import "FileBrowserHelpers.js" as FBH

Rectangle {
    id: root

    required property string currentPath

    signal navigate(string path)
    signal navigateUp()
    signal refresh()

    Layout.fillWidth: true
    height: Appearance.controlRowHeight
    color: Colors.cardSurface

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Colors.border
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Appearance.spacingM
        anchors.rightMargin: Appearance.spacingM
        spacing: Appearance.spacingXS

        // Up button
        Rectangle {
            width: 26; height: 26; radius: Appearance.radiusSmall
            color: "transparent"

            Text {
                anchors.centerIn: parent
                text: "󰁞"
                color: Colors.textSecondary
                font.family: Appearance.fontMono
                font.pixelSize: Appearance.fontSizeMedium
            }
            SharedWidgets.StateLayer {
                id: upSL
                hovered: upHover.containsMouse
                pressed: upHover.containsPress
            }
            MouseArea {
                id: upHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => { upSL.burst(mouse.x, mouse.y); root.navigateUp(); }
            }
        }

        // Breadcrumbs
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: breadRow.implicitWidth
            contentHeight: height
            clip: true
            interactive: contentWidth > width

            Row {
                id: breadRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Repeater {
                    model: FBH.buildBreadcrumbs(root.currentPath)

                    delegate: Row {
                        required property var modelData
                        required property int index
                        spacing: Appearance.spacingXXS

                        Text {
                            text: "›"
                            color: Colors.textDisabled
                            font.pixelSize: Appearance.fontSizeSmall
                            anchors.verticalCenter: parent.verticalCenter
                            visible: index > 0
                        }

                        Rectangle {
                            width: crumbText.implicitWidth + 8
                            height: 22
                            radius: Appearance.radiusSmall
                            color: {
                                var crumbs = FBH.buildBreadcrumbs(root.currentPath);
                                var isLast = (index === crumbs.length - 1);
                                if (isLast) return Colors.primaryMid;
                                if (crumbHover.containsMouse) return Colors.textWash;
                                return "transparent";
                            }
                            Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Appearance.durationSnap } }

                            Text {
                                id: crumbText
                                anchors.centerIn: parent
                                text: modelData.label
                                color: {
                                    var crumbs = FBH.buildBreadcrumbs(root.currentPath);
                                    var isLast = (index === crumbs.length - 1);
                                    if (isLast) return Colors.primary;
                                    return Colors.textSecondary;
                                }
                                font.pixelSize: Appearance.fontSizeSmall
                            }

                            MouseArea {
                                id: crumbHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.navigate(modelData.path)
                            }
                        }
                    }
                }
            }
        }

        // Refresh button
        Rectangle {
            width: 26; height: 26; radius: Appearance.radiusSmall
            color: "transparent"

            Text {
                anchors.centerIn: parent
                text: "󰑐"
                color: Colors.textSecondary
                font.family: Appearance.fontMono
                font.pixelSize: Appearance.fontSizeMedium
            }
            SharedWidgets.StateLayer {
                id: refreshSL
                hovered: refreshHover.containsMouse
                pressed: refreshHover.containsPress
            }
            MouseArea {
                id: refreshHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => { refreshSL.burst(mouse.x, mouse.y); root.refresh(); }
            }
        }
    }
}
