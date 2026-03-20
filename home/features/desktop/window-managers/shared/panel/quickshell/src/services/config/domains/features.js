.pragma library

var sectionKey = "screenshot"

var maps = [
    ["editor", "screenshotEditor"],
    ["editAfterCapture", "screenshotEditAfterCapture"],
    ["delay", "screenshotDelay"],
    ["ocrLanguage", "ocrLanguage"],
    ["history", "screenshotHistory"],
    ["historyMax", "screenshotHistoryMax"]
]

var recording = {
    sectionKey: "recording",
    maps: [
        ["captureSource", "recordingCaptureSource"],
        ["fps", "recordingFps"],
        ["quality", "recordingQuality"],
        ["recordCursor", "recordingRecordCursor"],
        ["outputDir", "recordingOutputDir"],
        ["includeDesktopAudio", "recordingIncludeDesktopAudio"],
        ["includeMicrophoneAudio", "recordingIncludeMicrophoneAudio"]
    ]
}

var privacy = {
    sectionKey: "privacy",
    maps: [
        ["indicatorsEnabled", "privacyIndicatorsEnabled"],
        ["cameraMonitoring", "privacyCameraMonitoring"]
    ]
}

var colorPicker = {
    sectionKey: "colorPicker",
    maps: [
        ["recentColors", "recentPickerColors"]
    ]
}

var notepad = {
    sectionKey: "notepad",
    maps: [
        ["projectSync", "notepadProjectSync"]
    ]
}

var hooks = {
    sectionKey: "hooks",
    maps: [
        ["enabled", "hooksEnabled"],
        ["paths", "hookPaths"]
    ]
}

var colorExport = {
    sectionKey: "colorExport",
    maps: [
        ["enabled", "colorExportEnabled"],
        ["kitty", "colorExportKitty"],
        ["gtkScheme", "colorExportGtkScheme"]
    ]
}

var osk = {
    sectionKey: "osk",
    maps: [
        ["layout", "oskLayout"],
        ["pinnedOnStartup", "oskPinnedOnStartup"]
    ]
}

var hotCorners = {
    sectionKey: "hotCorners",
    maps: [
        ["enabled", "hotCornersEnabled"]
    ]
}

var screenBorders = {
    sectionKey: "screenBorders",
    maps: [
        ["show", "showScreenBorders"]
    ]
}

var screenCorners = {
    sectionKey: "screenCorners",
    maps: [
        ["show", "showScreenCorners"],
        ["radius", "screenCornerRadius"]
    ]
}
