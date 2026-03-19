import QtQuick
import "../widgets" as SharedWidgets

Item {
    id: root

    property var sectionModel: []
    property Component sectionDelegate
    property bool vertical: false
    property real sectionSpacing: 0

    property var trailingModel: null
    property real trailingSpacing: -1

    readonly property real _trailingSpacing: trailingSpacing >= 0 ? trailingSpacing : sectionSpacing
    readonly property bool _hasTrailing: trailingModel !== null && trailingModel.length > 0

    implicitWidth: vertical ? _col.implicitWidth : _row.implicitWidth
    implicitHeight: vertical ? _col.implicitHeight : _row.implicitHeight
    width: implicitWidth
    height: implicitHeight

    Row {
        id: _row
        visible: !root.vertical
        spacing: root.sectionSpacing
        move: SharedWidgets.ListTransitions.move

        Repeater {
            model: root.sectionModel
            delegate: root.sectionDelegate
        }

        Row {
            visible: root._hasTrailing
            spacing: root._trailingSpacing
            move: SharedWidgets.ListTransitions.move

            Repeater {
                model: root.trailingModel || []
                delegate: root.sectionDelegate
            }
        }
    }

    Column {
        id: _col
        visible: root.vertical
        spacing: root.sectionSpacing
        move: SharedWidgets.ListTransitions.move

        Repeater {
            model: root.sectionModel
            delegate: root.sectionDelegate
        }

        Column {
            visible: root._hasTrailing
            spacing: root._trailingSpacing
            move: SharedWidgets.ListTransitions.move

            Repeater {
                model: root.trailingModel || []
                delegate: root.sectionDelegate
            }
        }
    }
}
