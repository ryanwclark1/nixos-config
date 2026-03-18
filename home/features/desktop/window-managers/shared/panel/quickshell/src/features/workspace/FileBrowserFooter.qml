import QtQuick
import QtQuick.Layouts
import "../../services"

Rectangle {
    id: root

    required property string mode
    required property string currentPath
    required property string selectedFile
    required property string saveFileName
    required property var fileFilters
    required property int activeFilterIndex
    required property bool compactActions
    required property bool isOpen

    signal saveFileNameChanged(string name)
    signal filterCycled()
    signal confirmAction()
    signal cancelAction()
    signal saveConfirmed(string path)

    property alias saveFieldItem: saveField

    Layout.fillWidth: true
    height: mode === "save" ? 96 : 52
    color: Colors.cardSurface

    // top border
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Colors.border
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Colors.spacingM
        spacing: Colors.spacingS

        // Save: filename text field
        Rectangle {
            Layout.fillWidth: true
            height: 32
            radius: Colors.radiusSmall
            visible: root.mode === "save"
            color: Colors.cardSurface
            border.color: saveField.activeFocus ? Colors.primary : Colors.border
            border.width: 1
            Behavior on border.color { ColorAnimation { duration: Colors.durationSnap } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Colors.spacingM
                anchors.rightMargin: Colors.spacingS
                spacing: Colors.spacingS

                Text {
                    text: "󰈙"
                    color: Colors.textDisabled
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeMedium
                }

                TextInput {
                    id: saveField
                    Layout.fillWidth: true
                    enabled: root.mode === "save" && root.isOpen
                    text: root.saveFileName
                    color: Colors.text
                    font.pixelSize: Colors.fontSizeMedium
                    selectionColor: Colors.withAlpha(Colors.primary, 0.4)
                    clip: true
                    onVisibleChanged: {
                        if (!visible && activeFocus)
                            focus = false;
                    }

                    onTextChanged: root.saveFileNameChanged(text)

                    Keys.onReturnPressed: {
                        if (root.saveFileName.length > 0)
                            root.saveConfirmed(root.currentPath + "/" + root.saveFileName);
                    }
                }
            }
        }

        // Bottom row: selected path + filter + action buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: root.compactActions ? Colors.spacingS : Colors.spacingM

            // Selected file or path display
            Rectangle {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                height: 30
                radius: Colors.radiusSmall
                color: Colors.cardSurface
                border.color: Colors.border
                border.width: 1
                clip: true

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: Colors.spacingM
                    anchors.rightMargin: Colors.spacingS
                    verticalAlignment: Text.AlignVCenter
                    text: root.mode === "open"
                        ? (root.selectedFile.length > 0 ? root.selectedFile : root.currentPath)
                        : (root.mode === "save" ? (root.saveFileName.length > 0
                            ? root.currentPath + "/" + root.saveFileName
                            : root.currentPath)
                            : (root.selectedFile.length > 0 ? root.selectedFile : root.currentPath))
                    color: root.selectedFile.length > 0 || root.saveFileName.length > 0
                        ? Colors.text : Colors.textDisabled
                    font.pixelSize: Colors.fontSizeSmall
                    elide: Text.ElideLeft
                }
            }

            // Filter selector
            Rectangle {
                visible: root.fileFilters.length > 1 && !root.compactActions
                height: 30
                width: filterText.implicitWidth + 28
                radius: Colors.radiusSmall
                color: filterHover.containsMouse
                    ? Colors.textWash : Colors.cardSurface
                border.color: Colors.border
                border.width: 1
                Behavior on color { ColorAnimation { duration: Colors.durationSnap } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Colors.spacingS
                    anchors.rightMargin: Colors.spacingS
                    spacing: Colors.spacingXS

                    Text {
                        id: filterText
                        text: root.fileFilters.length > 0
                            ? root.fileFilters[root.activeFilterIndex].label
                            : "All Files"
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeSmall
                    }
                    Text {
                        text: "󰅀"
                        color: Colors.textDisabled
                        font.family: Colors.fontMono
                        font.pixelSize: Colors.fontSizeSmall
                    }
                }

                MouseArea {
                    id: filterHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.filterCycled()
                }
            }

            // Cancel button
            Rectangle {
                Layout.minimumWidth: 96
                height: 30
                width: Math.max(Layout.minimumWidth, cancelText.implicitWidth + 24)
                radius: Colors.radiusSmall
                color: cancelHover.containsMouse
                    ? Colors.textWash : Colors.cardSurface
                border.color: Colors.border
                border.width: 1
                Behavior on color { ColorAnimation { duration: Colors.durationSnap } }

                Text {
                    id: cancelText
                    anchors.centerIn: parent
                    text: "Cancel"
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeMedium
                }

                MouseArea {
                    id: cancelHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.cancelAction()
                }
            }

            // Open/Save button
            Rectangle {
                id: actionBtn
                Layout.minimumWidth: root.mode === "folder" ? (root.compactActions ? 96 : 128) : 96
                height: 30
                width: Math.max(Layout.minimumWidth, actionText.implicitWidth + 24)
                radius: Colors.radiusSmall

                readonly property bool canConfirm: root.mode === "open"
                    ? root.selectedFile.length > 0
                    : (root.mode === "save" ? root.saveFileName.length > 0 : true)

                color: canConfirm
                    ? (actionHover.containsMouse ? Colors.primary : Colors.withAlpha(Colors.primary, 0.75))
                    : Colors.cardSurface
                border.color: canConfirm ? Colors.primary : Colors.border
                border.width: 1
                Behavior on color { ColorAnimation { duration: Colors.durationSnap } }

                Text {
                    id: actionText
                    anchors.centerIn: parent
                    text: root.mode === "open" ? "Open" : (root.mode === "save" ? "Save" : (root.compactActions ? "Select" : "Select Folder"))
                    color: actionBtn.canConfirm ? Colors.text : Colors.textDisabled
                    font.pixelSize: Colors.fontSizeMedium
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: actionHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: actionBtn.canConfirm ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (actionBtn.canConfirm)
                            root.confirmAction();
                    }
                }
            }
        }
    }
}
