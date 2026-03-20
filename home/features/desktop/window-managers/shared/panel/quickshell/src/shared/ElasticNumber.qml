import QtQuick
import "../services"

// Two-tracker elastic animation: blends a fast response with a slow settling
// phase to produce spring-like motion without spring physics.
//
// Usage:
//   ElasticNumber {
//       id: elastic
//       target: root.showContent ? 1.0 : 0.0
//   }
//   opacity: elastic.value
//   scale: elastic.value
Item {
    id: root

    property real target: 0
    property int fastDuration: Colors.durationSnap
    property int slowDuration: Colors.durationSlow
    property real fastWeight: 0.5

    readonly property real value: _fast * fastWeight + _slow * (1.0 - fastWeight)
    readonly property bool running: _fastAnim.running || _slowAnim.running

    property real _fast: target
    property real _slow: target

    Behavior on _fast {
        NumberAnimation {
            id: _fastAnim
            duration: root.fastDuration
            easing.type: Easing.OutQuad
        }
    }

    Behavior on _slow {
        NumberAnimation {
            id: _slowAnim
            duration: root.slowDuration
            easing.type: Easing.OutCubic
        }
    }
}
