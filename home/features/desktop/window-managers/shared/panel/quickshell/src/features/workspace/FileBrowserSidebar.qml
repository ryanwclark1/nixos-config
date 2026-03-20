import QtQuick
import QtQuick.Layouts
import "../../services"
import "../../shared" as Shared
import "../../widgets" as SharedWidgets

Rectangle {
    id: root

    required property string currentPath
    required property var quickLocations

    signal navigate(string path)

    Layout.preferredWidth: 180
    Layout.fillHeight: true
    color: Colors.cardSurface

    // right border
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: Colors.border
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Colors.spacingS
        spacing: Colors.spacingXXS

        Text {
            Layout.leftMargin: Colors.spacingS
            Layout.topMargin: Colors.spacingS
            text: "QUICK ACCESS"
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeXS
            font.weight: Font.Bold
            font.letterSpacing: Colors.letterSpacingWide
        }

        Repeater {
            model: root.quickLocations

            delegate: Rectangle {
                required property var modelData
                required property int index

                Layout.fillWidth: true
                height: 34
                radius: Colors.radiusSmall
                color: {
                    var isActive = root.currentPath === modelData.path;
                    if (isActive) return Colors.primaryMarked;
                    if (locHover.containsMouse) return Colors.withAlpha(Colors.text, 0.07);
                    return "transparent";
                }
                Behavior on color { enabled: !Colors.isTransitioning; ColorAnimation { duration: Colors.durationSnap } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Colors.spacingM
                    anchors.rightMargin: Colors.spacingS
                    spacing: Colors.spacingS

                    Loader {
                        property string _ic: modelData.icon
                        property color _co: root.currentPath === modelData.path ? Colors.primary : Colors.textSecondary
                        sourceComponent: _ic.endsWith(".svg") ? _fbSvg : _fbNerd
                    }
                    Component { id: _fbSvg; Shared.SvgIcon { source: parent._ic; color: parent._co; size: Colors.fontSizeLarge } }
                    Component { id: _fbNerd; Text { text: parent._ic; color: parent._co; font.family: Colors.fontMono; font.pixelSize: Colors.fontSizeLarge } }
                    Text {
                        text: modelData.label
                        color: root.currentPath === modelData.path ? Colors.text : Colors.textSecondary
                        font.pixelSize: Colors.fontSizeMedium
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    id: locHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.navigate(modelData.path)
                }
            }
        }

        Item { Layout.fillHeight: true }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colors.border
            Layout.bottomMargin: Colors.spacingS
        }

        Text {
            Layout.fillWidth: true
            Layout.leftMargin: Colors.spacingS
            Layout.bottomMargin: Colors.spacingS
            text: root.currentPath
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeXS
            wrapMode: Text.WrapAnywhere
            maximumLineCount: 3
            elide: Text.ElideRight
        }
    }
}
