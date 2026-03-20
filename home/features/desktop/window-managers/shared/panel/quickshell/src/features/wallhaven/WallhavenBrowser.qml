import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../services"
import "../../widgets" as SharedWidgets
import "../../shared"

PanelWindow {
    id: root
    property bool isOpen: false

    screen: Quickshell.cursorScreen
    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    exclusiveZone: -1
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-wallhaven"
    visible: isOpen

    signal closeRequested

    property string _searchText: Config.wallhavenLastQuery || ""

    // Escape to close
    Keys.onEscapePressed: root.closeRequested()

    // Background scrim
    Rectangle {
        anchors.fill: parent
        color: Colors.overlayScrim

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeRequested()
        }
    }

    // Main content panel
    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 1200)
        height: Math.min(parent.height - 80, 800)
        radius: Appearance.radiusLarge
        color: Colors.popupSurface
        border.color: Colors.border
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Appearance.paddingLarge
            spacing: Appearance.spacingL

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingM

                Text {
                    text: "Wallhaven"
                    color: Colors.text
                    font.pixelSize: Appearance.fontSizeXL
                    font.weight: Font.Bold
                }

                Item { Layout.fillWidth: true }

                SharedWidgets.IconButton {
                    icon: "dismiss.svg"
                    size: Appearance.iconSizeMedium
                    onClicked: root.closeRequested()
                }
            }

            // Search bar
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingS

                SharedWidgets.SearchBar {
                    id: searchBar
                    Layout.fillWidth: true
                    placeholder: "Search wallpapers..."
                    text: root._searchText

                    inputItem.Keys.onReturnPressed: {
                        root._searchText = searchBar.text;
                        Config.wallhavenLastQuery = searchBar.text;
                        WallhavenService.search(searchBar.text, 1);
                    }
                }

                Rectangle {
                    width: 80; height: Appearance.controlRowHeight
                    radius: Appearance.radiusSmall
                    color: Colors.primaryStrong

                    Text {
                        anchors.centerIn: parent
                        text: "Search"
                        color: Colors.primary
                        font.pixelSize: Appearance.fontSizeMedium
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root._searchText = searchBar.text;
                            Config.wallhavenLastQuery = searchBar.text;
                            WallhavenService.search(searchBar.text, 1);
                        }
                    }
                }
            }

            // Status
            Text {
                visible: WallhavenService.error !== ""
                text: WallhavenService.error
                color: Colors.error
                font.pixelSize: Appearance.fontSizeSmall
                Layout.fillWidth: true
            }

            // Loading indicator
            SharedWidgets.LoadingSpinner {
                visible: WallhavenService.searching
                Layout.alignment: Qt.AlignHCenter
            }

            // Results grid
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentHeight: resultsGrid.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                SharedWidgets.Scrollbar { flickable: parent }

                GridLayout {
                    id: resultsGrid
                    width: parent.width
                    columns: Math.max(1, Math.floor(width / 260))
                    rowSpacing: Appearance.spacingM
                    columnSpacing: Appearance.spacingM

                    Repeater {
                        model: WallhavenService.results

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            implicitHeight: 180
                            radius: Appearance.radiusSmall
                            color: Colors.cardSurface
                            border.color: thumbHover.containsMouse ? Colors.primary : Colors.border
                            border.width: 1
                            clip: true

                            Image {
                                anchors.fill: parent
                                anchors.margins: 1
                                source: modelData.thumbUrl || ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }

                            // Resolution badge
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right
                                anchors.margins: Appearance.spacingXS
                                height: 20; radius: Appearance.radiusXS
                                width: resText.implicitWidth + Appearance.spacingS * 2
                                color: Colors.withAlpha(Colors.background, 0.8)

                                Text {
                                    id: resText
                                    anchors.centerIn: parent
                                    text: modelData.resolution || ""
                                    color: Colors.textSecondary
                                    font.pixelSize: Appearance.fontSizeXS
                                }
                            }

                            // Download overlay on hover
                            Rectangle {
                                anchors.fill: parent
                                color: Colors.withAlpha(Colors.background, 0.6)
                                visible: thumbHover.containsMouse
                                radius: parent.radius

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: Appearance.spacingS

                                    Text {
                                        text: "\u{F0552}"
                                        color: Colors.primary
                                        font.family: Appearance.fontMono
                                        font.pixelSize: Appearance.iconSizeMedium
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                    Text {
                                        text: "Download & Apply"
                                        color: Colors.text
                                        font.pixelSize: Appearance.fontSizeMedium
                                        font.weight: Font.DemiBold
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }
                            }

                            MouseArea {
                                id: thumbHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (WallhavenService.downloading) return;
                                    var fname = "wallhaven-" + modelData.id + "." + _ext(modelData.url);
                                    WallhavenService.download(modelData.url, fname);
                                }
                            }

                            function _ext(url) {
                                var parts = (url || "").split(".");
                                return parts.length > 1 ? parts[parts.length - 1] : "jpg";
                            }
                        }
                    }
                }

                SharedWidgets.EmptyState {
                    visible: !WallhavenService.searching && WallhavenService.results.length === 0 && WallhavenService.error === ""
                    anchors.centerIn: parent
                    icon: "image.svg"
                    message: "Search Wallhaven for wallpapers"
                }
            }

            // Pagination
            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingM
                visible: WallhavenService.totalPages > 1

                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 70; height: 32; radius: Appearance.radiusSmall
                    color: WallhavenService.currentPage > 1 ? Colors.primaryStrong : Colors.textFaint
                    Text { anchors.centerIn: parent; text: "Prev"; color: Colors.text; font.pixelSize: Appearance.fontSizeSmall }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: WallhavenService.prevPage() }
                }

                Text {
                    text: WallhavenService.currentPage + " / " + WallhavenService.totalPages
                    color: Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeMedium
                }

                Rectangle {
                    width: 70; height: 32; radius: Appearance.radiusSmall
                    color: WallhavenService.currentPage < WallhavenService.totalPages ? Colors.primaryStrong : Colors.textFaint
                    Text { anchors.centerIn: parent; text: "Next"; color: Colors.text; font.pixelSize: Appearance.fontSizeSmall }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: WallhavenService.nextPage() }
                }

                Item { Layout.fillWidth: true }
            }
        }
    }

    // Auto-apply downloaded wallpaper
    Connections {
        target: WallhavenService
        function onDownloadComplete(filePath) {
            WallpaperService.setWallpaper(filePath, "");
        }
    }
}
