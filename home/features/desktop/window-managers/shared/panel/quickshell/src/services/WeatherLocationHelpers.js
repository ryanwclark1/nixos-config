.pragma library

function buildLocationPlan(priority, hasLatLon, hasCity, hasAuto) {
    var order = String(priority || "latlon_city_auto").split("_");
    var plan = [];
    var seen = {};

    function add(kind, available) {
        if (!available || seen[kind])
            return;
        seen[kind] = true;
        plan.push(kind);
    }

    for (var i = 0; i < order.length; i++) {
        var token = String(order[i] || "").trim();
        if (token === "latlon")
            add("latlon", hasLatLon);
        else if (token === "city")
            add("city", hasCity);
        else if (token === "auto")
            add("auto", hasAuto);
    }

    add("latlon", hasLatLon);
    add("city", hasCity);
    add("auto", hasAuto);
    return plan;
}

function cityQueryVariants(query) {
    var raw = String(query || "").trim();
    if (!raw)
        return [];

    var variants = [raw];
    var comma = raw.indexOf(",");
    if (comma !== -1) {
        var simplified = raw.substring(0, comma).trim();
        if (simplified && variants.indexOf(simplified) === -1)
            variants.push(simplified);
    }

    return variants;
}
