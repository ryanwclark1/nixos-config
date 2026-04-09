pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // ── Public state ──────────────────────────────
    property var results: []           // [{id, url, thumbUrl, resolution, category, purity}]
    property bool searching: false
    property bool downloading: false
    property string currentQuery: ""
    property int currentPage: 1
    property int totalPages: 0
    property string error: ""

    // ── Search API ────────────────────────────────
    function search(query, page) {
        if (searching) return;
        currentQuery = query || "";
        currentPage = page || 1;
        error = "";
        searching = true;

        var apiKey = Config.wallhavenApiKey || "";
        var url = "https://wallhaven.cc/api/v1/search?q=" + encodeURIComponent(currentQuery)
            + "&page=" + currentPage
            + "&atleast=1920x1080"
            + "&sorting=relevance";
        if (apiKey) url += "&apikey=" + apiKey;

        _searchProc.command = ["curl", "-s", "--max-time", "15", url];
        _searchProc.running = true;
    }

    function nextPage() {
        if (currentPage < totalPages)
            search(currentQuery, currentPage + 1);
    }

    function prevPage() {
        if (currentPage > 1)
            search(currentQuery, currentPage - 1);
    }

    // ── Download API ──────────────────────────────
    function download(wallpaperUrl, filename) {
        if (downloading) return;
        downloading = true;

        var dir = Config.wallhavenDownloadDir || ((Quickshell.env("HOME") || "/home") + "/Pictures/Wallhaven");
        var outPath = dir + "/" + (filename || "wallhaven.jpg");

        _downloadProc.command = ["sh", "-c",
            'mkdir -p "$(dirname "$2")" && curl -sL --max-time 60 -o "$2" "$1"',
            "sh", wallpaperUrl, outPath
        ];
        _downloadProc._savedPath = outPath;
        _downloadProc.running = true;
    }

    signal downloadComplete(string filePath)
    signal downloadFailed(string error)

    // ── Internal ──────────────────────────────────
    property Process _searchProc: Process {
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.searching = false;
                try {
                    var data = JSON.parse(this.text || "{}");
                    if (data.error) {
                        root.error = data.error;
                        root.results = [];
                        return;
                    }
                    var items = data.data || [];
                    var parsed = [];
                    for (var i = 0; i < items.length; i++) {
                        var item = items[i];
                        parsed.push({
                            id: item.id || "",
                            url: item.path || "",
                            thumbUrl: (item.thumbs && item.thumbs.small) || "",
                            resolution: item.resolution || "",
                            category: item.category || "",
                            purity: item.purity || "",
                            fileSize: item.file_size || 0,
                            colors: item.colors || []
                        });
                    }
                    root.results = parsed;
                    if (data.meta) {
                        root.totalPages = data.meta.last_page || 1;
                        root.currentPage = data.meta.current_page || 1;
                    }
                } catch (e) {
                    root.error = "Failed to parse response";
                    root.results = [];
                    Logger.e("WallhavenService", "Parse error:", e);
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text && this.text.trim())
                    Logger.w("WallhavenService", "curl stderr:", this.text.trim());
            }
        }
        onExited: (code, status) => {
            if (code !== 0) {
                root.searching = false;
                root.error = "Network error (curl exit " + code + ")";
            }
        }
    }

    property Process _downloadProc: Process {
        running: false
        property string _savedPath: ""
        onExited: (code, status) => {
            root.downloading = false;
            if (code === 0) {
                root.downloadComplete(_savedPath);
                ToastService.showSuccess("Wallpaper downloaded", _savedPath.split("/").pop());
                WallpaperService.scanWallpapers("wallhaven-download");
            } else {
                root.downloadFailed("Download failed (exit " + code + ")");
                ToastService.showError("Download failed", "Could not fetch wallpaper");
            }
        }
    }
}
