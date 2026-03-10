import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../services"
import "../modules"

Item {
  id: root
  implicitWidth: 800
  implicitHeight: 600

  RowLayout {
    anchors.fill: parent
    spacing: 40

    // Left Column: Time, Weather, System Stats, Quick Note
    ColumnLayout {
      Layout.alignment: Qt.AlignTop | Qt.AlignLeft
      spacing: 15
      Layout.preferredWidth: 350

      // Large Material You Clock
      ColumnLayout {
        Layout.alignment: Qt.AlignLeft
        spacing: -10

        Text {
          id: timeText
          text: Qt.formatDateTime(new Date(), "HH:mm")
          color: Colors.primary
          font.pixelSize: 96
          font.weight: Font.Bold
          font.letterSpacing: -4
          
          Timer {
            interval: 10000
            running: true
            repeat: true
            onTriggered: timeText.text = Qt.formatDateTime(new Date(), "HH:mm")
          }
        }

        Text {
          id: dateText
          text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
          color: Colors.text
          font.pixelSize: 24
          font.weight: Font.Medium
          Layout.leftMargin: 5
          
          Timer {
            interval: 60000
            running: true
            repeat: true
            onTriggered: dateText.text = Qt.formatDateTime(new Date(), "dddd, MMMM d")
          }
        }
      }

      Item { Layout.preferredHeight: 10 }

      // Weather
      WeatherWidget {
        Layout.fillWidth: true
      }

      Item { Layout.preferredHeight: 10 }

      // System Stats Row
      RowLayout {
        spacing: 30
        Layout.leftMargin: 5

        // CPU Stat
        ColumnLayout {
          spacing: 5
          Text { text: "CPU USAGE"; color: Colors.textDisabled; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
          RowLayout {
            spacing: 8
            Text { text: ""; color: Colors.primary; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20 }
            Text { 
              text: SystemStatus.cpuUsage
              color: Colors.text
              font.pixelSize: 18
              font.weight: Font.Bold
            }
          }
        }

        // RAM Stat
        ColumnLayout {
          spacing: 5
          Text { text: "MEMORY"; color: Colors.textDisabled; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
          RowLayout {
            spacing: 8
            Text { text: ""; color: Colors.secondary; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20 }
            Text { 
              text: SystemStatus.ramUsage
              color: Colors.text
              font.pixelSize: 18
              font.weight: Font.Bold
            }
          }
        }
      }

      Item { Layout.preferredHeight: 20 }

      // Quick Note Widget
      ColumnLayout {
        spacing: 12
        Layout.fillWidth: true
        
        Text { text: "QUICK NOTE"; color: Colors.textDisabled; font.pixelSize: 10; font.weight: Font.Bold; font.letterSpacing: 1 }
        
        Rectangle {
          Layout.preferredWidth: 350; Layout.preferredHeight: 180; color: Qt.rgba(1, 1, 1, 0.03); radius: Colors.radiusMedium; border.color: noteInput.activeFocus ? Colors.primary : Colors.border; border.width: 1
          
          TextArea {
            id: noteInput; anchors.fill: parent; anchors.margins: 15; color: Colors.text; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font"; wrapMode: TextEdit.Wrap; placeholderText: "Type a note..."
            
            property string notePath: Quickshell.env("HOME") + "/.cache/quickshell_note.txt"
            
            Component.onCompleted: {
              var file = Quickshell.openFile(notePath, File.ReadOnly);
              if (file) { text = file.readAll(); file.close(); }
            }
            
            onTextChanged: {
              var file = Quickshell.openFile(notePath, File.WriteOnly | File.Truncate);
              if (file) { file.write(text); file.close(); }
            }
          }
        }
      }

      Item { Layout.fillHeight: true }
    }

    // Right Column: Calendar
    ColumnLayout {
      Layout.alignment: Qt.AlignTop | Qt.AlignLeft
      Layout.topMargin: 20
      Layout.preferredWidth: 320

      Calendar {
        Layout.fillWidth: true
      }

      Item { Layout.fillHeight: true }
    }
  }
}
