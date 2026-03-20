import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "."
import "../services"

Rectangle {
    id: root
    
    property var command: []
    property string title: "Live Logs"
    property alias running: logProc.running
    
    signal closeRequested()

    radius: Colors.radiusLarge
    color: Colors.withAlpha(Colors.surface, 0.98)
    border.color: Colors.border
    border.width: 1
    clip: true

    gradient: SurfaceGradient {}

    // Inner highlight
    InnerHighlight { highlightOpacity: 0.15 }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Colors.paddingMedium
        spacing: Colors.spacingM

        RowLayout {
            Layout.fillWidth: true
            Text { 
                text: "󰆍  " + root.title 
                color: Colors.primary
                font.pixelSize: Colors.fontSizeLarge
                font.weight: Font.Bold
            }
            Item { Layout.fillWidth: true }
            IconButton {
                icon: "dismiss.svg"
                size: 28; iconSize: 16
                tooltipText: "Close"
                onClicked: root.closeRequested()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Colors.withAlpha(Colors.background, 0.4)
            radius: Colors.radiusSmall
            border.color: Colors.border
            border.width: 1
            clip: true

            Flickable {
                id: logFlick
                anchors.fill: parent
                anchors.margins: 8
                contentHeight: logText.implicitHeight
                contentWidth: width
                flickableDirection: Flickable.VerticalFlick
                
                Text {
                    id: logText
                    width: parent.width
                    color: Colors.textSecondary
                    font.family: Colors.fontMono
                    font.pixelSize: Colors.fontSizeXS
                    wrapMode: Text.WrapAnywhere
                    text: ""
                    
                    onTextChanged: {
                        // Auto-scroll to bottom
                        if (logFlick.atYEnd || logText.lineCount < 20) {
                            scrollTimer.restart();
                        }
                    }
                }
                
                Timer {
                    id: scrollTimer
                    interval: 50
                    onTriggered: logFlick.contentY = Math.max(0, logText.implicitHeight - logFlick.height)
                }
            }
        }
    }

    Process {
        id: logProc
        command: root.command
        running: false
        stdout: SplitParser {
            onRead: line => {
                logText.text += line + "\n";
                // Cap log size to 2000 lines
                if (logText.lineCount > 2000) {
                    var lines = logText.text.split("\n");
                    logText.text = lines.slice(lines.length - 1000).join("\n");
                }
            }
        }
    }

    onCommandChanged: {
        logText.text = "";
        if (command.length > 0) logProc.running = true;
    }

    Component.onDestruction: logProc.running = false
}
