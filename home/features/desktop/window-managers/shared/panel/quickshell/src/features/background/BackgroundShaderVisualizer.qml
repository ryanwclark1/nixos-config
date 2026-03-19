import QtQuick
import "../../services"

Item {
    id: root

    property int barCount: SpectrumService.barsCount
    property real gap: 2.0
    property color colorStart: Colors.withAlpha(Colors.secondary, 0.4)
    property color colorEnd: Colors.withAlpha(Colors.primary, 0.6)

    opacity: SpectrumService.isIdle ? 0 : 1
    Behavior on opacity { Anim { duration: Colors.durationSlow } }

    ShaderEffect {
        anchors.fill: parent
        enabled: !Colors._isEcoMode

        readonly property real barCount: root.barCount
        readonly property real gap: root.gap
        readonly property color colorStart: root.colorStart
        readonly property color colorEnd: root.colorEnd

        // Pass all 32 bars as individual uniforms (ShaderEffect doesn't support arrays)
        readonly property real v0: SpectrumService.values[0]
        readonly property real v1: SpectrumService.values[1]
        readonly property real v2: SpectrumService.values[2]
        readonly property real v3: SpectrumService.values[3]
        readonly property real v4: SpectrumService.values[4]
        readonly property real v5: SpectrumService.values[5]
        readonly property real v6: SpectrumService.values[6]
        readonly property real v7: SpectrumService.values[7]
        readonly property real v8: SpectrumService.values[8]
        readonly property real v9: SpectrumService.values[9]
        readonly property real v10: SpectrumService.values[10]
        readonly property real v11: SpectrumService.values[11]
        readonly property real v12: SpectrumService.values[12]
        readonly property real v13: SpectrumService.values[13]
        readonly property real v14: SpectrumService.values[14]
        readonly property real v15: SpectrumService.values[15]
        readonly property real v16: SpectrumService.values[16]
        readonly property real v17: SpectrumService.values[17]
        readonly property real v18: SpectrumService.values[18]
        readonly property real v19: SpectrumService.values[19]
        readonly property real v20: SpectrumService.values[20]
        readonly property real v21: SpectrumService.values[21]
        readonly property real v22: SpectrumService.values[22]
        readonly property real v23: SpectrumService.values[23]
        readonly property real v24: SpectrumService.values[24]
        readonly property real v25: SpectrumService.values[25]
        readonly property real v26: SpectrumService.values[26]
        readonly property real v27: SpectrumService.values[27]
        readonly property real v28: SpectrumService.values[28]
        readonly property real v29: SpectrumService.values[29]
        readonly property real v30: SpectrumService.values[30]
        readonly property real v31: SpectrumService.values[31]

        fragmentShader: "
            varying highp vec2 qt_TexCoord0;
            uniform lowp float qt_Opacity;
            uniform highp float barCount;
            uniform highp float gap;
            uniform lowp vec4 colorStart;
            uniform lowp vec4 colorEnd;

            // Uniforms for each bar
            uniform highp float v0, v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15;
            uniform highp float v16, v17, v18, v19, v20, v21, v22, v23, v24, v25, v26, v27, v28, v29, v30, v31;

            float getVal(int index) {
                if (index == 0) return v0; if (index == 1) return v1; if (index == 2) return v2; if (index == 3) return v3;
                if (index == 4) return v4; if (index == 5) return v5; if (index == 6) return v6; if (index == 7) return v7;
                if (index == 8) return v8; if (index == 9) return v9; if (index == 10) return v10; if (index == 11) return v11;
                if (index == 12) return v12; if (index == 13) return v13; if (index == 14) return v14; if (index == 15) return v15;
                if (index == 16) return v16; if (index == 17) return v17; if (index == 18) return v18; if (index == 19) return v19;
                if (index == 20) return v20; if (index == 21) return v21; if (index == 22) return v22; if (index == 23) return v23;
                if (index == 24) return v24; if (index == 25) return v25; if (index == 26) return v26; if (index == 27) return v27;
                if (index == 28) return v28; if (index == 29) return v29; if (index == 30) return v30; if (index == 31) return v31;
                return 0.0;
            }

            void main() {
                highp float x = qt_TexCoord0.x * barCount;
                int index = int(floor(x));
                highp float localX = fract(x);

                // Bar width accounting for gap
                highp float normGap = gap / (1.0 / barCount); // gap in local coords? no.
                // Simplified: if localX is within [0, 1 - gapPercentage], show bar
                highp float gapSize = 0.1; // 10% gap
                if (localX > (1.0 - gapSize)) {
                    discard;
                }

                highp float val = getVal(index);
                if (qt_TexCoord0.y < (1.0 - val)) {
                    discard;
                }

                // Vertical gradient
                lowp vec4 color = mix(colorEnd, colorStart, qt_TexCoord0.y);
                gl_FragColor = color * qt_Opacity;
            }
        "
    }
}
