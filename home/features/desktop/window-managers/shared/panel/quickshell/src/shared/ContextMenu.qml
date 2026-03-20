import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets"

// Right-click context menu with keyboard navigation, separators, and icons.
//
// Usage:
//   ContextMenu {
//     id: myMenu
//     model: [
//       { label: "Copy",    icon: "󰆏", action: () => doCopy() },
//       { separator: true },
//       { label: "Delete",  icon: "󰆴", action: () => doDelete(), danger: true },
//     ]
//   }
//
//   MouseArea {
//     acceptedButtons: Qt.RightButton
//     onClicked: (mouse) => myMenu.popup(mouse.x, mouse.y)
//   }
ThemedContainer {
    id: root
    variant: "popup"

    property var model: []
    property bool showMenu: false
    property int focusedIndex: -1
    property real popupX: 0
    property real popupY: 0

    readonly property int itemHeight: 32
    readonly property int separatorHeight: 9
    readonly property int menuPadding: Colors.spacingXS

    x: popupX
    y: popupY
    width: 180
    height: menuPadding * 2 + contentColumn.implicitHeight
    visible: root.showMenu
    z: 9999
    customHighlightOpacity: 0.15

    scale: showMenu ? 1.0 : 0.9
    opacity: showMenu ? 1.0 : 0.0
    Behavior on scale { NumberAnimation { duration: Colors.durationFast; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
    Behavior on opacity { NumberAnimation { duration: Colors.durationSnap } }

    layer.enabled: showMenu || opacity > 0
    layer.smooth: true

    function popup(mx, my) {
        popupX = mx
        popupY = my
        focusedIndex = -1
        showMenu = true
        forceActiveFocus()
    }

    function close() {
        showMenu = false
        focusedIndex = -1
    }

    function executeItem(index) {
        var item = model[index]
        if (!item || item.separator || item.disabled) return
        if (typeof item.action === "function") item.action()
        close()
    }

    function moveFocus(delta) {
        if (model.length === 0) return
        var next = focusedIndex + delta
        // Skip separators and disabled items
        for (var attempts = 0; attempts < model.length; attempts++) {
            if (next < 0) next = model.length - 1
            else if (next >= model.length) next = 0

            if (!model[next].separator && !model[next].disabled) {
                focusedIndex = next
                return
            }
            next += delta
        }
    }

    Keys.onUpPressed: moveFocus(-1)
    Keys.onDownPressed: moveFocus(1)
    Keys.onReturnPressed: executeItem(focusedIndex)
    Keys.onEnterPressed: executeItem(focusedIndex)
    Keys.onEscapePressed: close()

    // Close when clicking outside
    MouseArea {
        parent: root.parent
        x: 0
        y: 0
        width: parent ? parent.width : 0
        height: parent ? parent.height : 0
        visible: root.showMenu
        z: root.z - 1
        onClicked: root.close()
    }

    ElevationShadow {}

    ColumnLayout {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: root.menuPadding
        spacing: 0

        Repeater {
            model: root.model

            delegate: Item {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                Layout.preferredHeight: modelData.separator ? root.separatorHeight : root.itemHeight

                // Separator
                Rectangle {
                    visible: modelData.separator === true
                    anchors.centerIn: parent
                    width: parent.width - Colors.spacingS * 2
                    height: 1
                    color: Colors.border
                }

                // Menu item
                Rectangle {
                    visible: !modelData.separator
                    anchors.fill: parent
                    radius: Colors.radiusXS
                    color: root.focusedIndex === index || itemMouse.containsMouse
                        ? Colors.highlightLight : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Colors.spacingS
                        anchors.rightMargin: Colors.spacingS
                        spacing: Colors.spacingS

                        Loader {
                            visible: !!modelData.icon
                            property string _icon: modelData.icon || ""
                            property color _color: modelData.danger ? Colors.error
                                : (modelData.disabled ? Colors.textDisabled : Colors.textSecondary)
                            sourceComponent: _icon.endsWith(".svg") ? _ctxSvg : _ctxNerd
                        }
                        Component {
                            id: _ctxSvg
                            SvgIcon { source: parent._icon; color: parent._color; size: Colors.fontSizeMedium }
                        }
                        Component {
                            id: _ctxNerd
                            Text {
                                text: parent._icon
                                color: parent._color
                                font.family: Colors.fontMono
                                font.pixelSize: Colors.fontSizeMedium
                            }
                        }

                        Text {
                            text: modelData.label || ""
                            color: modelData.danger ? Colors.error
                                : (modelData.disabled ? Colors.textDisabled : Colors.text)
                            font.pixelSize: Colors.fontSizeSmall
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: !!modelData.shortcut
                            text: modelData.shortcut || ""
                            color: Colors.textDisabled
                            font.pixelSize: Colors.fontSizeXS
                            font.family: Colors.fontMono
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !modelData.separator && !modelData.disabled
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.executeItem(index)
                        onEntered: root.focusedIndex = index
                    }
                }
            }
        }
    }

    onShowMenuChanged: {
        if (showMenu) forceActiveFocus()
    }
}
