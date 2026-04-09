.pragma library

var REPEATABLE_WIDGET_TYPES = {
    spacer: true,
    separator: true
};

function _normalizedSections(sectionWidgets) {
    var source = sectionWidgets || {};
    return {
        left: Array.isArray(source.left) ? source.left : [],
        center: Array.isArray(source.center) ? source.center : [],
        right: Array.isArray(source.right) ? source.right : []
    };
}

function isRepeatableWidgetType(widgetType) {
    return !!REPEATABLE_WIDGET_TYPES[String(widgetType || "")];
}

function usageByType(sectionWidgets) {
    var sections = _normalizedSections(sectionWidgets);
    var keys = ["left", "center", "right"];
    var usage = {};

    for (var i = 0; i < keys.length; ++i) {
        var section = keys[i];
        var items = sections[section];
        for (var j = 0; j < items.length; ++j) {
            var widgetType = String((items[j] && items[j].widgetType) || "");
            if (widgetType === "")
                continue;
            if (!usage[widgetType]) {
                usage[widgetType] = {
                    widgetType: widgetType,
                    instanceCount: 0,
                    sections: []
                };
            }
            usage[widgetType].instanceCount += 1;
            if (usage[widgetType].sections.indexOf(section) === -1)
                usage[widgetType].sections.push(section);
        }
    }

    return usage;
}

function usageForWidgetType(sectionWidgets, widgetType) {
    var typeName = String(widgetType || "");
    if (typeName === "") {
        return {
            widgetType: "",
            instanceCount: 0,
            sections: []
        };
    }
    var usage = usageByType(sectionWidgets);
    return usage[typeName] || {
        widgetType: typeName,
        instanceCount: 0,
        sections: []
    };
}

function canAddToBar(sectionWidgets, widgetType) {
    if (isRepeatableWidgetType(widgetType))
        return true;
    return usageForWidgetType(sectionWidgets, widgetType).instanceCount === 0;
}

function annotatePickerItems(items, sectionWidgets) {
    var source = Array.isArray(items) ? items : [];
    var usage = usageByType(sectionWidgets);
    var annotated = [];

    for (var i = 0; i < source.length; ++i) {
        var item = source[i] || {};
        var widgetType = String(item.widgetType || "");
        var details = usage[widgetType] || {
            widgetType: widgetType,
            instanceCount: 0,
            sections: []
        };
        var sections = details.sections.slice();
        annotated.push(Object.assign({}, item, {
            instanceCount: details.instanceCount,
            existingSections: sections,
            canAdd: isRepeatableWidgetType(widgetType) || details.instanceCount === 0,
            repeatable: isRepeatableWidgetType(widgetType)
        }));
    }

    return annotated;
}
