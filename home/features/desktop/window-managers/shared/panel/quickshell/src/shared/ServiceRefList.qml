import QtQuick
import "."

// Keeps subscriberCount Ref semantics for a fixed list of singleton services (zero layout footprint).
Item {
    id: root

    property var services: []
    implicitWidth: 0
    implicitHeight: 0

    Repeater {
        model: root.services
        delegate: Item {
            required property var modelData
            width: 0
            height: 0

            Ref {
                service: modelData
            }
        }
    }
}
