import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import "../shared"
import "../widgets" as SharedWidgets
import "LauncherModeData.js" as ModeData

// LauncherResultView: the stacked results/loading/empty-state/media area.
// Owns the file context menu. The parent ColumnLayout gives it fillWidth + fillHeight.
StackLayout {
    id: root

    required property var launcher

    // Convenience aliases so bindings below stay readable
    readonly property bool compactMode: launcher.compactMode
    readonly property bool tightMode: launcher.tightMode
    readonly property string mode: launcher.mode
    readonly property bool isModeLoading: launcher.isModeLoading
    readonly property var filteredItems: launcher.filteredItems
    readonly property bool hasResults: launcher.hasResults

    currentIndex: mode === "media" ? 1 : 0

    // ScriptModel for efficient list diffing on the results ListView
    ScriptModel { id: resultsModel; values: root.filteredItems }

    // ── Slot 0: results / loading / empty ──────────────────────────────────
    StackLayout {
        currentIndex: root.filteredItems.length > 0 ? 0 : (root.isModeLoading ? 1 : 2)

        ListView {
            id: resultsList
            model: resultsModel
            clip: true
            cacheBuffer: 400
            spacing: root.compactMode ? Colors.spacingXS : Colors.spacingS
            currentIndex: root.launcher.selectedIndex
            enabled: !root.launcher.showingConfirm
            topMargin: root.compactMode ? Colors.spacingXXS : Colors.spacingXS
            section.property: "sectionLabel"
            section.delegate: LauncherSectionHeader {
                compactMode: root.compactMode
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
                onClicked: root.launcher.executeSelection()
                onSecondaryActionRequested: function(sourceItem, localX, localY) {
                    if (root.mode !== "files" || !modelData || !modelData.fullPath)
                        return;
                    var point = sourceItem ? sourceItem.mapToItem(root.launcher, localX, localY) : Qt.point(localX, localY);
                    root.launcher.selectedIndex = index;
                    fileResultContextMenu.model = root.launcher.fileContextMenuModel(modelData);
                    fileResultContextMenu.popup(point.x, point.y);
                }
                onEntered: if (!root.launcher.ignoreMouseHover)
                    root.launcher.selectedIndex = index
            }
        }

        // Loading state
        Rectangle {
            color: Colors.bgWidget
            radius: Colors.radiusMedium
            border.color: Colors.border
            border.width: 1

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Colors.spacingS

                SharedWidgets.LoadingSpinner {
                    Layout.alignment: Qt.AlignHCenter
                    size: root.compactMode ? 18 : 24
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.launcher.modeLoadMessage !== "" ? root.launcher.modeLoadMessage : ("Loading " + ModeData.modeInfo(root.mode).label)
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeSmall
                    font.weight: Font.DemiBold
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Please wait"
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeXS
                }
            }
        }

        // Empty state
        LauncherEmptyState {
            icon: root.launcher.modeIcons[root.mode] || "󰈔"
            title: root.launcher.emptyStateTitle
            subtitle: root.launcher.emptyStateSubtitle
            primaryCta: root.launcher.emptyPrimaryCta
            secondaryCta: root.launcher.emptySecondaryCta
            primaryHint: root.launcher.emptyPrimaryHint
            primaryHintIcon: root.launcher.emptyPrimaryHintIcon
            secondaryHint: root.launcher.emptySecondaryHint
            secondaryHintIcon: root.launcher.emptySecondaryHintIcon
            onPrimaryClicked: root.launcher.executeEmptyPrimary()
            onSecondaryClicked: root.launcher.executeEmptySecondary()
        }
    }

    // ── Slot 1: media view ─────────────────────────────────────────────────
    LauncherMediaView {
        mediaPlayers: root.launcher.mediaPlayers
        compactMode: root.compactMode
        tightMode: root.tightMode
    }

    // ── File result context menu ───────────────────────────────────────────
    ContextMenu {
        id: fileResultContextMenu
    }
}
