.pragma library
.import "../../../../services/BarPresetPolicy.js" as BarPresetPolicy
.import "../../../../bar/VerticalWidgetPolicy.js" as VerticalWidgetPolicy

function _sectionScore(itemSection, addSection) {
    return String(itemSection || "") === String(addSection || "") ? 0 : 1;
}

function _recommendedScore(widgetType, addSection) {
    return BarPresetPolicy.verticalPresetSection(widgetType) === String(addSection || "") ? 0 : 1;
}

function comparePickerItems(left, right, addSection, verticalBar) {
    if (verticalBar) {
        var recommendedDelta = _recommendedScore(left.widgetType, addSection) - _recommendedScore(right.widgetType, addSection);
        if (recommendedDelta !== 0)
            return recommendedDelta;

        var behaviorDelta = VerticalWidgetPolicy.verticalBehaviorSortRank(left.widgetType) - VerticalWidgetPolicy.verticalBehaviorSortRank(right.widgetType);
        if (behaviorDelta !== 0)
            return behaviorDelta;
    }

    var sectionDelta = _sectionScore(left.section, addSection) - _sectionScore(right.section, addSection);
    if (sectionDelta !== 0)
        return sectionDelta;

    return String(left.label || "").localeCompare(String(right.label || ""));
}

function sortPickerItems(items, addSection, verticalBar) {
    var source = Array.isArray(items) ? items.slice() : [];
    return source.sort(function(left, right) {
        return comparePickerItems(left, right, addSection, verticalBar);
    });
}
