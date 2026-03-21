import QtQuick
import "."

// Keeps subscriberCount Ref semantics for a fixed list of singleton services (zero layout footprint).
Item {
    id: root

    property var services: []
    implicitWidth: 0
    implicitHeight: 0

    Repeater {
        model: root.services.length
        delegate: Ref {
            service: root.services[index]
        }
    }
}
