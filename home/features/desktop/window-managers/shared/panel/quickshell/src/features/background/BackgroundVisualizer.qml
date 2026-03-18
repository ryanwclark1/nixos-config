import QtQuick
import "../../services"
import "../../shared"

Item {
    id: root

    opacity: SpectrumService.isIdle ? 0 : 1

    Behavior on opacity { Anim { duration: Colors.durationSlow } }

    Ref { service: SpectrumService }

    Repeater {
        model: SpectrumService.barsCount

        Rectangle {
            required property int index

            readonly property real barWidth: root.width / SpectrumService.barsCount
            readonly property real value: {
                var vals = SpectrumService.values;
                return (vals && index < vals.length) ? vals[index] : 0;
            }

            x: index * barWidth
            width: barWidth - 1
            height: value * root.height
            anchors.bottom: parent.bottom
            radius: Colors.radiusMicro

            gradient: Gradient {
                GradientStop { position: 0.0; color: Colors.withAlpha(Colors.secondary, 0.4) }
                GradientStop { position: 1.0; color: Colors.withAlpha(Colors.primary, 0.6) }
            }

            Behavior on height { Anim { duration: Colors.durationSnap } }
        }
    }
}
