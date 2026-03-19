import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../services"
import "../widgets" as SharedWidgets
import "../features/workspace/FileBrowserHelpers.js" as FBH

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
    property string _fileSize: ""
    property string _relativePath: ""

    readonly property var _imageExts: ({ "png": 1, "jpg": 1, "jpeg": 1, "gif": 1, "webp": 1, "svg": 1, "ico": 1, "bmp": 1 })
    readonly property var _binaryExts: ({ "zip": 1, "tar": 1, "gz": 1, "xz": 1, "bz2": 1, "zst": 1, "7z": 1, "rar": 1,
        "mp3": 1, "mp4": 1, "mkv": 1, "avi": 1, "mov": 1, "flac": 1, "wav": 1, "ogg": 1, "webm": 1,
        "pdf": 1, "doc": 1, "docx": 1, "xls": 1, "xlsx": 1,
        "so": 1, "o": 1, "a": 1, "dylib": 1, "exe": 1, "bin": 1, "class": 1, "pyc": 1,
        "woff": 1, "woff2": 1, "ttf": 1, "otf": 1, "eot": 1 })

    // Extension → language category for syntax coloring
    readonly property var _langMap: ({
        "js": "js", "mjs": "js", "cjs": "js", "jsx": "js", "ts": "js", "tsx": "js",
        "qml": "js", "json": "js", "jsonc": "js",
        "py": "py", "pyw": "py", "pyi": "py",
        "rs": "rs", "go": "rs", "c": "rs", "cpp": "rs", "h": "rs", "hpp": "rs",
        "java": "rs", "kt": "rs", "kts": "rs", "scala": "rs", "cs": "rs",
        "nix": "nix",
        "sh": "sh", "bash": "sh", "zsh": "sh", "fish": "sh",
        "html": "html", "htm": "html", "xml": "html", "svg": "html",
        "css": "css", "scss": "css", "sass": "css", "less": "css",
        "md": "md", "mdx": "md", "rst": "md",
        "yaml": "yaml", "yml": "yaml", "toml": "yaml", "ini": "yaml", "conf": "yaml",
        "sql": "sql", "lua": "lua", "rb": "py", "php": "py", "pl": "py",
        "zig": "rs", "nim": "rs", "hs": "rs", "ml": "rs", "ex": "rs", "exs": "rs"
    })

    // Keyword sets per language category
    readonly property var _keywords: ({
        "js":   ["function","const","let","var","if","else","return","import","export","from",
                 "class","extends","new","this","async","await","for","while","switch","case",
                 "default","break","continue","try","catch","throw","typeof","instanceof",
                 "true","false","null","undefined","property","signal","readonly","required",
                 "id","Component","Item","Rectangle","Text","Timer","ColumnLayout","RowLayout"],
        "py":   ["def","class","if","elif","else","return","import","from","as","for","while",
                 "with","try","except","raise","yield","lambda","True","False","None","self",
                 "and","or","not","in","is","pass","break","continue","global","nonlocal"],
        "rs":   ["fn","let","mut","const","if","else","return","struct","enum","impl","trait",
                 "pub","use","mod","match","for","while","loop","break","continue","type",
                 "self","super","crate","true","false","async","await","where","unsafe",
                 "int","void","char","bool","auto","static","extern","include","define"],
        "nix":  ["let","in","if","then","else","with","inherit","rec","import","true","false",
                 "null","assert","or","builtins","lib","mkIf","mkOption","mkDefault",
                 "pkgs","config","options","enable","package","programs","services"],
        "sh":   ["if","then","else","elif","fi","for","do","done","while","until","case","esac",
                 "function","return","local","export","source","echo","exit","set","unset",
                 "true","false","read","shift","eval","exec","test"],
        "html": ["div","span","class","style","href","src","id","type","name","value",
                 "script","link","meta","head","body","html","input","button","form"],
        "css":  ["color","background","border","margin","padding","display","position",
                 "width","height","flex","grid","font","text","transition","animation",
                 "important","none","auto","inherit","solid","relative","absolute","fixed"],
        "md":   [],
        "yaml": ["true","false","null","yes","no","on","off"],
        "sql":  ["SELECT","FROM","WHERE","INSERT","UPDATE","DELETE","CREATE","DROP","ALTER",
                 "JOIN","LEFT","RIGHT","INNER","ON","AND","OR","NOT","NULL","INTO","VALUES",
                 "TABLE","INDEX","GROUP","ORDER","BY","HAVING","LIMIT","AS","SET","LIKE"],
        "lua":  ["function","local","if","then","else","elseif","end","for","while","do",
                 "return","repeat","until","in","not","and","or","true","false","nil","self"]
    })

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
            _fileSize = "";
            _relativePath = "";
            return;
        }
        var path = String(item.fullPath);
        if (path === _currentPath) return;
        _currentPath = path;
        _relativePath = item.relativePath || "";
        _fileSize = "";

        var ext = item.extension || _extractExt(path);
        var type = _detectType(ext);

        // Fetch file size asynchronously
        _statProc.running = false;
        _statProc.command = ["stat", "--printf=%s", path];
        _statProc.running = true;

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
        _previewProc.command = ["sh", "-c", "head -50 \"$1\" 2>/dev/null | head -c 8192", "sh", path];
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

    // Apply basic syntax highlighting to content
    function _highlightContent(content, ext) {
        var source = String(content || "");
        var lang = _langMap[(ext || "").toLowerCase()] || "";
        if (!lang || lang === "md") return _escapeHtml(source);

        var kws = _keywords[lang] || [];
        if (kws.length === 0) return _escapeHtml(source);

        var kwSet = {};
        for (var k = 0; k < kws.length; k++) kwSet[kws[k]] = true;

        var lines = source.split("\n");
        var result = [];
        var commentColor = Colors.textDisabled;
        var keywordColor = Colors.primary;
        var numberColor = Colors.warning || Colors.primary;

        for (var li = 0; li < lines.length; li++) {
            var line = String(lines[li] || "");
            var escaped = _escapeHtml(line);

            // Comment detection (single-line)
            var trimmed = line.replace(/^\s+/, "");
            if (trimmed.indexOf("//") === 0 || trimmed.indexOf("#") === 0 || trimmed.indexOf("--") === 0) {
                result.push("<font color=\"" + commentColor + "\">" + escaped + "</font>");
                continue;
            }

            // Highlight keywords as whole words
            var highlighted = escaped.replace(/\b([a-zA-Z_][a-zA-Z0-9_]*)\b/g, function(match) {
                if (kwSet[match]) return "<font color=\"" + keywordColor + "\">" + match + "</font>";
                return match;
            });

            // Highlight numbers
            highlighted = highlighted.replace(/\b(\d+\.?\d*)\b/g,
                "<font color=\"" + numberColor + "\">$1</font>");

            result.push(highlighted);
        }
        return result.join("\n");
    }

    function _escapeHtml(text) {
        return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    // Build line numbers text matching content lines
    function _lineNumbers(content) {
        if (!content) return "1";
        var count = 1;
        for (var i = 0; i < content.length; i++) {
            if (content[i] === "\n") count++;
        }
        var nums = [];
        for (var n = 1; n <= count; n++) nums.push(String(n));
        return nums.join("\n");
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

    Process {
        id: _statProc
        property bool _destroyed: false
        Component.onDestruction: _destroyed = true
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (_statProc._destroyed || root._destroyed) return;
                root._fileSize = FBH.formatSize(this.text || "");
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Colors.spacingS
        spacing: Colors.spacingXS

        // Header: filename + extension pill + size
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

            // File size badge
            Text {
                visible: root._fileSize !== ""
                text: root._fileSize
                color: Colors.textSecondary
                font.pixelSize: Colors.fontSizeXXS
                font.family: Colors.fontMono
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

        // Relative path subtitle
        Text {
            Layout.fillWidth: true
            visible: root._relativePath !== "" && root._relativePath !== (root.selectedItem ? root.selectedItem.name : "")
            text: root._relativePath
            color: Colors.textDisabled
            font.pixelSize: Colors.fontSizeXXS
            font.family: Colors.fontMono
            elide: Text.ElideMiddle
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Colors.withAlpha(Colors.border, 0.2)
        }

        // Content area. Avoid placing Flickable directly in a StackLayout because
        // repeated width animations and layout polish were causing Qt 6.10 crashes.
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // 0: Text preview with line numbers
            Item {
                anchors.fill: parent
                visible: root._currentType === 0
                clip: true

                Row {
                    anchors.fill: parent
                    spacing: Colors.spacingXS

                    Text {
                        id: lineNumbers
                        text: root._lineNumbers(root._currentContent)
                        color: Colors.withAlpha(Colors.textDisabled, 0.5)
                        font.pixelSize: Colors.fontSizeXXS
                        font.family: Colors.fontMono
                        lineHeight: 1.3
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignTop
                        width: {
                            var count = (root._currentContent || "").split("\n").length;
                            return count > 99 ? 24 : count > 9 ? 18 : 12;
                        }
                    }

                    Rectangle {
                        id: gutterSeparator
                        width: 1
                        height: parent.height
                        color: Colors.withAlpha(Colors.border, 0.15)
                    }

                    Text {
                        id: previewText
                        width: Math.max(0, parent.width - lineNumbers.width - gutterSeparator.width - (Colors.spacingXS * 2))
                        text: root._highlightContent(
                            root._currentContent,
                            root.selectedItem ? (root.selectedItem.extension || "") : ""
                        )
                        textFormat: Text.RichText
                        color: Colors.textSecondary
                        font.pixelSize: Colors.fontSizeXXS
                        font.family: Colors.fontMono
                        wrapMode: Text.WrapAnywhere
                        lineHeight: 1.3
                        verticalAlignment: Text.AlignTop
                    }
                }
            }

            // 1: Image preview
            Item {
                anchors.fill: parent
                visible: root._currentType === 1

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
                anchors.fill: parent
                visible: root._currentType === 2

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
                        text: root._fileSize !== "" ? root._fileSize : "Preview not available"
                        color: Colors.textDisabled
                        font.pixelSize: Colors.fontSizeXS
                    }
                }
            }

            // 3: Loading spinner
            Item {
                anchors.fill: parent
                visible: root._currentType === 3

                SharedWidgets.LoadingSpinner {
                    anchors.centerIn: parent
                    size: 18
                }
            }
        }
    }
}
