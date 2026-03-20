import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import "../shared"
import "../widgets" as SharedWidgets
import "LauncherModeData.js" as ModeData

StackLayout {
    id: root

    required property var launcher

    signal fileContextMenuRequested(var menuModel, point menuPoint)

    readonly property bool compactMode: launcher.compactMode
    readonly property bool tightMode: launcher.tightMode
    readonly property string mode: launcher.mode
    readonly property bool isModeLoading: launcher.isModeLoading
    readonly property var filteredItems: launcher.filteredItems
    readonly property bool hasResults: launcher.hasResults
    readonly property color accentColor: launcher.modeAccentColor ? launcher.modeAccentColor : Colors.primary

    currentIndex: mode === "media" ? 1 : 0

    ScriptModel { id: resultsModel; values: root.filteredItems }

    StackLayout {
        currentIndex: root.filteredItems.length > 0 ? 0 : (root.isModeLoading ? 1 : 2)

        RowLayout {
            spacing: Appearance.spacingS

            ListView {
                id: resultsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: resultsModel
                clip: true
                cacheBuffer: 400
                spacing: root.compactMode ? Appearance.spacingXS : Appearance.spacingS
                currentIndex: root.filteredItems.length > 0
                    ? Math.min(root.launcher.selectedIndex, root.filteredItems.length - 1)
                    : -1
                enabled: !root.launcher.showingConfirm
                topMargin: 0
                section.property: "sectionLabel"
                section.delegate: LauncherSectionHeader {
                    compactMode: root.compactMode
                    accentColor: root.accentColor
                }

                delegate: LauncherResultDelegate {
                    itemData: modelData
                    itemIndex: index
                    searchText: root.launcher.searchText
                    mode: root.mode
                    compactMode: root.compactMode
                    tightMode: root.tightMode
                    ignoreMouseHover: root.launcher.ignoreMouseHover
                    modeIcons: root.launcher.modeIcons
                    iconMap: root.launcher.launcherIconMap
                    accentColor: root.accentColor
                    onClicked: root.launcher.executeSelection()
                    onSecondaryActionRequested: function(sourceItem, localX, localY) {
                        if (root.mode !== "files" || !modelData || !modelData.fullPath)
                            return;
                        var pt = sourceItem ? sourceItem.mapToItem(root.launcher, localX, localY) : Qt.point(localX, localY);
                        root.launcher.selectedIndex = index;
                        root.fileContextMenuRequested(root.launcher.fileContextMenuModel(modelData), pt);
                    }
                    onEntered: if (!root.launcher.ignoreMouseHover)
                        root.launcher.selectedIndex = index
                }
            }

            LauncherFilePreview {
                id: filePreview
                visible: root.launcher.filePreviewVisible && root.mode === "files"
                         && root.launcher.selectedItem
                         && !!root.launcher.selectedItem.fullPath
                Layout.preferredWidth: visible ? Math.min(400, root.width * 0.4) : 0
                Layout.fillHeight: true
                selectedItem: root.launcher.selectedItem
            }
        }

        Rectangle {
            color: Colors.withAlpha(root.accentColor, 0.08)
            radius: Appearance.radiusXL
            border.color: Colors.withAlpha(root.accentColor, 0.24)
            border.width: 1

            SharedWidgets.InnerHighlight {
                highlightOpacity: 0.12
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Appearance.spacingS

                SharedWidgets.LoadingSpinner {
                    Layout.alignment: Qt.AlignHCenter
                    size: root.compactMode ? 18 : 24
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.launcher.modeLoadMessage !== "" ? root.launcher.modeLoadMessage : ("Loading " + ModeData.modeInfo(root.mode).label)
                    color: Colors.text
                    font.pixelSize: Appearance.fontSizeSmall
                    font.weight: Font.Black
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Preparing the next result stage"
                    color: Colors.textSecondary
                    font.pixelSize: Appearance.fontSizeXS
                }
            }
        }

        LauncherEmptyState {
            icon: root.launcher.modeIcons[root.mode] || "document.svg"
            title: root.launcher.emptyStateTitle
            subtitle: root.launcher.emptyStateSubtitle
            primaryCta: root.launcher.emptyPrimaryCta
            secondaryCta: root.launcher.emptySecondaryCta
            primaryHint: root.launcher.emptyPrimaryHint
            primaryHintIcon: root.launcher.emptyPrimaryHintIcon
            secondaryHint: root.launcher.emptySecondaryHint
            secondaryHintIcon: root.launcher.emptySecondaryHintIcon
            accentColor: root.accentColor
            onPrimaryClicked: root.launcher.executeEmptyPrimary()
            onSecondaryClicked: root.launcher.executeEmptySecondary()
        }
    }

    LauncherMediaView {
        mediaPlayers: root.launcher.mediaPlayers
        compactMode: root.compactMode
        tightMode: root.tightMode
    }
}
