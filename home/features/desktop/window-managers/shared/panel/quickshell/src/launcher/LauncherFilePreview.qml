import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../services"
import "../widgets" as SharedWidgets

Rectangle {
    id: root

    required property var selectedItem

    color: Colors.withAlpha(Colors.surface, 0.6)
    radius: Colors.radiusSmall
    border.color: Colors.withAlpha(Colors.border, 0.3)
    border.width: 1
    clip: true

    property bool _destroyed: false
    Component.onDestruction: _destroyed = true

    // LRU cache: { path: { content, type, ts } } — max 10 entries
    property var _previewCache: ({})
    property int _cacheSize: 0
    property string _currentPath: ""
    property string _currentContent: ""
    property int _currentType: 3 // 0=text, 1=image, 2=binary, 3=loading

    readonly property var _imageExts: ({ "png": 1, "jpg": 1, "jpeg": 1, "gif": 1, "webp": 1, "svg": 1, "ico": 1, "bmp": 1 })
    readonly property var _binaryExts: ({ "zip": 1, "tar": 1, "gz": 1, "xz": 1, "bz2": 1, "zst": 1, "7z": 1, "rar": 1,
        "mp3": 1, "mp4": 1, "mkv": 1, "avi": 1, "mov": 1, "flac": 1, "wav": 1, "ogg": 1, "webm": 1,
        "pdf": 1, "doc": 1, "docx": 1, "xls": 1, "xlsx": 1,
        "so": 1, "o": 1, "a": 1, "dylib": 1, "exe": 1, "bin": 1, "class": 1, "pyc": 1,
        "woff": 1, "woff2": 1, "ttf": 1, "otf": 1, "eot": 1 })

    function _detectType(ext) {
        var e = (ext || "").toLowerCase();
        if (_imageExts[e]) return 1;
        if (_binaryExts[e]) return 2;
        return 0; // text
    }

    onSelectedItemChanged: _debounceTimer.restart()

    Timer {
        id: _debounceTimer
        interval: 200
        onTriggered: root._loadPreview()
    }

    function _loadPreview() {
        var item = selectedItem;
        if (!item || !item.fullPath) {
            _currentType = 3;
            _currentPath = "";
            return;
        }
        var path = String(item.fullPath);
        if (path === _currentPath) return;
        _currentPath = path;

        var ext = item.extension || _extractExt(path);
        var type = _detectType(ext);

        // Images: no subprocess needed
        if (type === 1) {
            _currentType = 1;
            _currentContent = "";
            return;
        }
        // Binary: show info card
        if (type === 2) {
            _currentType = 2;
            _currentContent = (ext || "binary").toUpperCase();
            return;
        }

        // Text: check cache first
        var cached = _previewCache[path];
        if (cached) {
            _currentContent = cached.content;
            _currentType = 0;
            cached.ts = Date.now();
            return;
        }

        _currentType = 3; // loading
        _previewProc.running = false;
        _previewProc.command = ["sh", "-c", "head -30 \"$1\" 2>/dev/null | head -c 4096", "sh", path];
        _previewProc.running = true;
    }

    function _extractExt(path) {
        var dot = path.lastIndexOf(".");
        var slash = path.lastIndexOf("/");
        if (dot > slash + 1) return path.substring(dot + 1);
        return "";
    }

    function _evictOldest() {
        if (_cacheSize < 10) return;
        var oldest = null;
        var oldestTs = Infinity;
        for (var k in _previewCache) {
            if (_previewCache[k].ts < oldestTs) {
                oldestTs = _previewCache[k].ts;
                oldest = k;
            }
        }
        if (oldest) {
            delete _previewCache[oldest];
            _cacheSize--;
        }
    }

    Process {
        id: _previewProc
        property bool _destroyed: false
        Component.onDestruction: _destroyed = true
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (_previewProc._destroyed || root._destroyed) return;
                var text = this.text || "";
                var path = root._currentPath;
                if (path) {
                    root._evictOldest();
                    root._previewCache[path] = { content: text, type: 0, ts: Date.now() };
                    root._cacheSize++;
                }
                root._currentContent = text;
                root._currentType = 0;
            }
        }
        onExited: exitCode => {
            if (exitCode !== 0 && !_previewProc._destroyed && !root._destroyed) {
                root._currentContent = "";
                root._currentType = 2; // show as binary/unreadable
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Colors.spacingS
        spacing: Colors.spacingXS

        // Header: filename + extension pill
        RowLayout {
            Layout.fillWidth: true
            spacing: Colors.spacingXS

            Text {
                Layout.fillWidth: true
                text: root.selectedItem ? (root.selectedItem.name || "") : ""
                color: Colors.text
                font.pixelSize: Colors.fontSizeSmall
                font.weight: Font.DemiBold
                elide: Text.ElideMiddle
            }

            Rectangle {
                visible: !!(root.selectedItem && root.selectedItem.extension)
                color: Colors.withAlpha(Colors.primary, Colors.primarySubtle)
                radius: Colors.radiusMicro
                implicitWidth: extLabel.implicitWidth + Colors.spacingS * 2
                implicitHeight: extLabel.implicitHeight + Colors.spacingXXS * 2

                Text {
                    id: extLabel
                    anchors.centerIn: parent
                    text: root.selectedItem ? ("." + (root.selectedItem.extension || "")) : ""
                    color: Colors.primary
                    font.pixelSize: Colors.fontSizeXS
                    font.family: Colors.fontMono
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Colors.withAlpha(Colors.border, 0.2)
        }

        // Content area
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root._currentType

            // 0: Text preview
            Flickable {
                contentWidth: width
                contentHeight: previewText.implicitHeight
                clip: true

                Text {
                    id: previewText
                    width: parent.width
                    text: root._currentContent
                    color: Colors.textSecondary
                    font.pixelSize: Colors.fontSizeXS
                    font.family: Colors.fontMono
                    wrapMode: Text.WrapAnywhere
                    lineHeight: 1.3
                }
            }

            // 1: Image preview
            Item {
                Image {
                    anchors.fill: parent
                    source: root._currentType === 1 && root._currentPath ? ("file://" + root._currentPath) : ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    sourceSize.width: 400
                    sourceSize.height: 400
                }
            }

            // 2: Binary info card
            Item {
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: Colors.spacingS

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "󰈔"
                        color: Colors.textDisabled
                        font.pixelSize: Colors.fontSizeDisplay
                        font.family: Colors.fontMono
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root._currentContent || "Binary"
                        color: Colors.textDisabled
                        font.pixelSize: Colors.fontSizeMedium
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Preview not available"
                        color: Colors.textDisabled
                        font.pixelSize: Colors.fontSizeXS
                    }
                }
            }

            // 3: Loading spinner
            Item {
                SharedWidgets.LoadingSpinner {
                    anchors.centerIn: parent
                    size: 18
                }
            }
        }
    }
}
