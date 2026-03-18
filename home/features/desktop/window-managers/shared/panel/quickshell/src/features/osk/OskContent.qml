import QtQuick
import QtQuick.Layouts
import "../../services"
import "./layouts.js" as Layouts

// Renders the active keyboard layout as a grid of OskKey rows.
Item {
    id: root

    readonly property var  _layouts:     Layouts.byName
    readonly property string _layoutName: _layouts.hasOwnProperty(Config.oskLayout)
                                          ? Config.oskLayout
                                          : Layouts.defaultLayout
    readonly property var  _layout:      _layouts[_layoutName]

    implicitWidth:  keyRows.implicitWidth
    implicitHeight: keyRows.implicitHeight

    ColumnLayout {
        id: keyRows
        anchors.fill: parent
        spacing: Colors.spacingXS

        Repeater {
            model: root._layout.keys

            delegate: RowLayout {
                id: keyRow
                required property var modelData
                spacing: Colors.spacingXS

                Repeater {
                    model: modelData
                    delegate: OskKey {
                        required property var modelData
                        keyData: modelData
                    }
                }
            }
        }
    }
}
