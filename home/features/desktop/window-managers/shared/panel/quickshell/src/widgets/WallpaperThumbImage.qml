import QtQuick
import Quickshell
import "../shared/WallpaperThumbnailCache.js" as WTC
import "../features/settings/components/tabs/WallpaperTabHelpers.js" as WTH
import "../services"

// Loads wallpaper grid previews by trying Freedesktop large thumbnails, then the
// Quickshell WebP cache (generated on demand via WallpaperService), then the original file.
// Avoids pinning decoded previews in the global Qt image cache.
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
    cache: false
    sourceSize: Qt.size(216, 160)

    function _syncSource() {
        var nextTier = _tier;
        if (nextTier === 0 && WTC.hasFreedesktopLargeMiss(imagePath))
            nextTier = 1;
        if (nextTier === 1 && WTC.hasQuickshellThumbMiss(imagePath, fileMtime) && thumbRev <= 0)
            nextTier = 2;
        _tier = nextTier;
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
        WTC.clearQuickshellThumbMiss(imagePath, fileMtime);
        if (_tier === 2) {
            _tier = 1;
            _syncSource();
        }
    }

    onStatusChanged: {
        if (status === Image.Error && source !== "") {
            if (_tier === 0) {
                WTC.markFreedesktopLargeMiss(imagePath);
                _tier = 1;
                _syncSource();
            } else if (_tier === 1) {
                WTC.markQuickshellThumbMiss(imagePath, fileMtime);
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
