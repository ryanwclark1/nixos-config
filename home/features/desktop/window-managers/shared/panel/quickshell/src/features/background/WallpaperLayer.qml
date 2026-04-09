import QtQuick
import QtMultimedia
import Quickshell
import "../../services"

Item {
    id: root
    anchors.fill: parent
    readonly property bool debugDisableVideoWallpaper: (Quickshell.env("QS_DEBUG_DISABLE_VIDEO_WALLPAPER") || "") === "1"
    readonly property bool effectiveShowVideo: root.showVideo && !root.debugDisableVideoWallpaper

    // Public API
    property url currentSource: ""
    property string transitionType: "fade"  // fade | pixelate | wipe | none
    property int transitionDuration: Appearance.durationWallpaper
    property color solidColor: "transparent"
    property bool showSolid: false
    property url videoSource: ""
    property bool showVideo: false

    signal imageLoadError(url source)

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

    Loader {
        id: videoLayerLoader
        anchors.fill: parent
        active: root.effectiveShowVideo && root.videoSource !== ""
        sourceComponent: videoWallpaperComponent
    }

    Component.onCompleted: {
        if (root.debugDisableVideoWallpaper)
            Logger.i("WallpaperLayer", "video wallpaper disabled via QS_DEBUG_DISABLE_VIDEO_WALLPAPER");
    }

    Image {
        id: imageA
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        visible: source !== ""
        opacity: root._transitioning ? (root._flip ? root._progress : (1 - root._progress)) : (root._flip ? 0 : 1)
        sourceSize: Qt.size(root.width, root.height)
        Behavior on opacity {
            NumberAnimation {
                duration: Math.max(1, root.transitionDuration)
                easing.type: Easing.InOutQuad
            }
        }
        onStatusChanged: {
            if (status === Image.Error && source !== "") {
                Logger.w("WallpaperLayer", "Failed to load image A:", source);
                root.imageLoadError(source);
                source = "";
            }
        }
    }

    Image {
        id: imageB
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        visible: source !== ""
        opacity: root._transitioning ? (root._flip ? (1 - root._progress) : root._progress) : (root._flip ? 1 : 0)
        sourceSize: Qt.size(root.width, root.height)
        Behavior on opacity {
            NumberAnimation {
                duration: Math.max(1, root.transitionDuration)
                easing.type: Easing.InOutQuad
            }
        }
        onStatusChanged: {
            if (status === Image.Error && source !== "") {
                Logger.w("WallpaperLayer", "Failed to load image B:", source);
                root.imageLoadError(source);
                source = "";
            }
        }
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
        if (transitionType === "none" || (!imageA.source && !imageB.source)) {
            // First load or no transition — just set directly
            imageA.source = source;
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
        if (transitionType === "random") {
            var shaders = [_fadeShader, _pixelateShader, _wipeShader, _dissolveShader, _zoomShader, _radialShader];
            return shaders[Math.floor(Math.random() * shaders.length)];
        }
        if (transitionType === "pixelate") return _pixelateShader;
        if (transitionType === "wipe") return _wipeShader;
        if (transitionType === "dissolve") return _dissolveShader;
        if (transitionType === "zoom") return _zoomShader;
        if (transitionType === "radial") return _radialShader;
        return _fadeShader;
    }

    Component {
        id: videoWallpaperComponent

        Item {
            anchors.fill: parent

            MediaPlayer {
                id: videoPlayer
                source: root.videoSource
                loops: MediaPlayer.Infinite
                audioOutput: AudioOutput { muted: true }
                videoOutput: videoOutput
                onSourceChanged: {
                    if (source !== "") {
                        Logger.i("WallpaperLayer", "video wallpaper source activated", source);
                        play();
                    }
                }
                onErrorOccurred: (error, errorString) => {
                    Logger.w("WallpaperLayer", "Video playback error:", errorString);
                }
            }

            VideoOutput {
                id: videoOutput
                anchors.fill: parent
                fillMode: VideoOutput.PreserveAspectCrop
                visible: videoPlayer.playbackState === MediaPlayer.PlayingState
            }
        }
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

    readonly property string _dissolveShader: "
        varying highp vec2 qt_TexCoord0;
        uniform lowp float qt_Opacity;
        uniform sampler2D textureA;
        uniform sampler2D textureB;
        uniform highp float progress;
        uniform bool flipDirection;

        // Pseudo-random noise
        highp float rand(highp vec2 co) {
            return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
        }

        void main() {
            lowp vec4 colA = texture2D(textureA, qt_TexCoord0);
            lowp vec4 colB = texture2D(textureB, qt_TexCoord0);
            lowp vec4 fromCol = flipDirection ? colB : colA;
            lowp vec4 toCol = flipDirection ? colA : colB;

            highp float noise = rand(qt_TexCoord0);
            highp float threshold = smoothstep(0.0, 1.0, progress);
            highp float alpha = step(noise, threshold);
            gl_FragColor = mix(fromCol, toCol, alpha) * qt_Opacity;
        }
    "

    readonly property string _zoomShader: "
        varying highp vec2 qt_TexCoord0;
        uniform lowp float qt_Opacity;
        uniform sampler2D textureA;
        uniform sampler2D textureB;
        uniform highp float progress;
        uniform bool flipDirection;

        void main() {
            // Zoom out from center on the old image, zoom in on the new
            highp float zoomOld = 1.0 + progress * 0.3;
            highp float zoomNew = 1.3 - progress * 0.3;
            highp vec2 center = vec2(0.5, 0.5);

            highp vec2 uvOld = (qt_TexCoord0 - center) * zoomOld + center;
            highp vec2 uvNew = (qt_TexCoord0 - center) * zoomNew + center;

            lowp vec4 colOld = texture2D(flipDirection ? textureB : textureA, uvOld);
            lowp vec4 colNew = texture2D(flipDirection ? textureA : textureB, uvNew);

            // Clamp UV to avoid edge artifacts
            highp float maskOld = step(0.0, uvOld.x) * step(uvOld.x, 1.0) * step(0.0, uvOld.y) * step(uvOld.y, 1.0);
            highp float maskNew = step(0.0, uvNew.x) * step(uvNew.x, 1.0) * step(0.0, uvNew.y) * step(uvNew.y, 1.0);

            colOld *= maskOld;
            colNew *= maskNew;

            highp float fade = smoothstep(0.2, 0.8, progress);
            gl_FragColor = mix(colOld, colNew, fade) * qt_Opacity;
        }
    "

    readonly property string _radialShader: "
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

            // Circular reveal from center
            highp float dist = distance(qt_TexCoord0, vec2(0.5, 0.5));
            highp float maxDist = 0.7071; // sqrt(0.5^2 + 0.5^2)
            highp float reveal = smoothstep(progress * maxDist - 0.05, progress * maxDist + 0.05, dist);
            gl_FragColor = mix(toCol, fromCol, reveal) * qt_Opacity;
        }
    "
}
