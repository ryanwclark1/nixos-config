import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets" as SharedWidgets

Item {
    id: root

    required property string section
    required property bool compactMode

    width: ListView.view ? ListView.view.width : 0
    height: compactMode ? 26 : 30

    RowLayout {
        anchors.fill: parent
        anchors.topMargin: root.compactMode ? Colors.spacingXXS : Colors.spacingXS
        spacing: root.compactMode ? Colors.spacingXS : Colors.spacingS

        Rectangle {
            radius: Colors.radiusPill
            color: Colors.primarySubtle
            border.color: Colors.primaryMarked
            border.width: 1
            implicitHeight: root.compactMode ? 18 : 20
            implicitWidth: sectionHeaderLabel.implicitWidth + (root.compactMode ? 12 : 14)

            SharedWidgets.SectionLabel {
                id: sectionHeaderLabel
                anchors.centerIn: parent
                label: root.section
                color: Colors.primary
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            implicitHeight: 1
            radius: Colors.radiusXXXS
            color: Colors.withAlpha(Colors.border, 0.9)
        }
    }
}
