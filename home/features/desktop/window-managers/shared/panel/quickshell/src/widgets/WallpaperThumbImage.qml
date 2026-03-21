import QtQuick
import Quickshell
import "../shared/WallpaperThumbnailCache.js" as WTC
import "../features/settings/components/tabs/WallpaperTabHelpers.js" as WTH
import "../services"

// Loads wallpaper grid previews with caching: tries Freedesktop large thumbnails, then
// Quickshell WebP cache (generated on demand via WallpaperService), then the original file.
// Uses Qt Image.cache for decoded pixmap reuse while the shell stays open.
Image {
    id: root

    property string imagePath: ""
    property int fileMtime: 0
    property var unsupportedMap: ({})

    signal imageUnsupported(string path)

    property int _tier: 0

    readonly property int thumbRev: WallpaperService.thumbRevisionFor(imagePath)

    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    smooth: true
    cache: true
    sourceSize: Qt.size(216, 160)

    function _syncSource() {
        if (!imagePath || (unsupportedMap && unsupportedMap[imagePath])) {
            source = "";
            return;
        }
        if (_tier === 0) {
            source = WTC.freedesktopLargeFileUrl(
                imagePath,
                Quickshell.env("XDG_CACHE_HOME"),
                Quickshell.env("HOME")
            );
        } else if (_tier === 1) {
            var base = WTC.quickshellThumbFileUrl(
                imagePath,
                fileMtime,
                Quickshell.env("XDG_CACHE_HOME"),
                Quickshell.env("HOME")
            );
            source = base.length ? (base + "?v=" + thumbRev) : "";
        } else {
            source = WTH.imageSource(imagePath, unsupportedMap || {});
        }
    }

    onImagePathChanged: {
        _tier = 0;
        _syncSource();
    }

    onFileMtimeChanged: {
        _tier = 0;
        _syncSource();
    }

    onUnsupportedMapChanged: _syncSource()

    onThumbRevChanged: {
        if (!imagePath || thumbRev <= 0)
            return;
        if (_tier === 2) {
            _tier = 1;
            _syncSource();
        }
    }

    onStatusChanged: {
        if (status === Image.Error && source !== "") {
            if (_tier === 0) {
                _tier = 1;
                _syncSource();
            } else if (_tier === 1) {
                WallpaperService.requestThumbnail(imagePath, fileMtime);
                _tier = 2;
                _syncSource();
            } else {
                root.imageUnsupported(imagePath);
            }
        }
    }

    Component.onCompleted: _syncSource()
}
