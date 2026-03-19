import QtQuick
import "../../services"

Item {
    id: root
    anchors.fill: parent

    // Public API
    property url currentSource: ""
    property string transitionType: "fade"  // fade | pixelate | wipe | none
    property int transitionDuration: 1500
    property color solidColor: "transparent"
    property bool showSolid: false

    // Internal state
    property bool _flip: false
    property real _progress: 0.0
    property bool _transitioning: false

    // Solid color background (below images)
    Rectangle {
        anchors.fill: parent
        color: root.showSolid ? root.solidColor : "transparent"
        visible: root.showSolid
    }

    Image {
        id: imageA
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        visible: !root._transitioning && !root._flip
        sourceSize: Qt.size(root.width, root.height)
    }

    Image {
        id: imageB
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        visible: !root._transitioning && root._flip
        sourceSize: Qt.size(root.width, root.height)
    }

    // ShaderEffect for transitions — visible only during transition
    ShaderEffect {
        id: transitionShader
        anchors.fill: parent
        visible: root._transitioning

        property var textureA: imageA
        property var textureB: imageB
        property real progress: root._progress
        property bool flipDirection: root._flip

        fragmentShader: root._shaderSource()
    }

    NumberAnimation {
        id: transitionAnim
        target: root
        property: "_progress"
        from: 0; to: 1
        duration: root.transitionDuration
        easing.type: Easing.InOutQuad
        onFinished: root._finishTransition()
    }

    onCurrentSourceChanged: {
        if (!currentSource || currentSource === "") return;
        _startTransition(currentSource);
    }

    function _startTransition(source) {
        if (transitionType === "none" || !imageA.source || imageA.source === "") {
            // First load or no transition — just set directly
            if (_flip) {
                imageA.source = source;
            } else {
                imageA.source = source;
            }
            _flip = false;
            return;
        }

        // Load the new image into the inactive slot
        if (_flip) {
            imageA.source = source;
        } else {
            imageB.source = source;
        }

        // Start transition animation
        _progress = 0;
        _transitioning = true;
        transitionAnim.restart();
    }

    function _finishTransition() {
        _transitioning = false;
        _flip = !_flip;
        _progress = 0;
    }

    function _shaderSource() {
        if (transitionType === "pixelate") return _pixelateShader;
        if (transitionType === "wipe") return _wipeShader;
        return _fadeShader;
    }

    // ── Shader sources (GLSL ES 2.0, inline) ──────────────

    readonly property string _fadeShader: "
        varying highp vec2 qt_TexCoord0;
        uniform lowp float qt_Opacity;
        uniform sampler2D textureA;
        uniform sampler2D textureB;
        uniform highp float progress;
        uniform bool flipDirection;

        void main() {
            lowp vec4 colA = texture2D(textureA, qt_TexCoord0);
            lowp vec4 colB = texture2D(textureB, qt_TexCoord0);
            lowp vec4 fromCol = flipDirection ? colB : colA;
            lowp vec4 toCol = flipDirection ? colA : colB;
            gl_FragColor = mix(fromCol, toCol, progress) * qt_Opacity;
        }
    "

    readonly property string _pixelateShader: "
        varying highp vec2 qt_TexCoord0;
        uniform lowp float qt_Opacity;
        uniform sampler2D textureA;
        uniform sampler2D textureB;
        uniform highp float progress;
        uniform bool flipDirection;

        void main() {
            // Pixelation: increase pixel size during first half, decrease during second half
            highp float pixelPhase = progress < 0.5 ? progress * 2.0 : (1.0 - progress) * 2.0;
            highp float pixelSize = mix(1.0, 48.0, pixelPhase);
            highp vec2 pixelCoord = floor(qt_TexCoord0 * pixelSize) / pixelSize;

            lowp vec4 colA = texture2D(textureA, pixelCoord);
            lowp vec4 colB = texture2D(textureB, pixelCoord);
            lowp vec4 fromCol = flipDirection ? colB : colA;
            lowp vec4 toCol = flipDirection ? colA : colB;

            // Cross-fade in the middle of the pixelation
            highp float fade = smoothstep(0.3, 0.7, progress);
            gl_FragColor = mix(fromCol, toCol, fade) * qt_Opacity;
        }
    "

    readonly property string _wipeShader: "
        varying highp vec2 qt_TexCoord0;
        uniform lowp float qt_Opacity;
        uniform sampler2D textureA;
        uniform sampler2D textureB;
        uniform highp float progress;
        uniform bool flipDirection;

        void main() {
            lowp vec4 colA = texture2D(textureA, qt_TexCoord0);
            lowp vec4 colB = texture2D(textureB, qt_TexCoord0);
            lowp vec4 fromCol = flipDirection ? colB : colA;
            lowp vec4 toCol = flipDirection ? colA : colB;

            // Directional wipe from left to right with soft edge
            highp float edge = smoothstep(progress - 0.05, progress + 0.05, qt_TexCoord0.x);
            gl_FragColor = mix(toCol, fromCol, edge) * qt_Opacity;
        }
    "
}
