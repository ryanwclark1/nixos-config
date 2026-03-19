.pragma library

var _defaultPortMap = {
    "nginx": 80,
    "httpd": 80,
    "apache": 80,
    "caddy": 80,
    "traefik": 80,
    "postgres": 5432,
    "postgresql": 5432,
    "mysql": 3306,
    "mariadb": 3306,
    "redis": 6379,
    "mongo": 27017,
    "mongodb": 27017,
    "rabbitmq": 5672,
    "elasticsearch": 9200,
    "grafana": 3000,
    "prometheus": 9090,
    "node": 3000,
    "python": 8000,
    "django": 8000,
    "flask": 5000,
    "minio": 9000,
    "jenkins": 8080,
    "sonarqube": 9000,
    "vault": 8200,
    "consul": 8500
};

function guessDefaultPort(imageName) {
    var name = String(imageName || "").toLowerCase();
    // Strip registry prefix and tag
    var lastSlash = name.lastIndexOf("/");
    if (lastSlash !== -1)
        name = name.slice(lastSlash + 1);
    var colonIdx = name.indexOf(":");
    if (colonIdx !== -1)
        name = name.slice(0, colonIdx);

    for (var key in _defaultPortMap) {
        if (name.indexOf(key) !== -1)
            return _defaultPortMap[key];
    }
    return 8080;
}

function formatBytes(bytes) {
    var value = Number(bytes);
    if (!isFinite(value) || value < 0)
        return "0 B";
    if (value < 1024)
        return value + " B";
    if (value < 1024 * 1024)
        return (value / 1024).toFixed(1) + " KB";
    if (value < 1024 * 1024 * 1024)
        return (value / (1024 * 1024)).toFixed(1) + " MB";
    return (value / (1024 * 1024 * 1024)).toFixed(2) + " GB";
}

function normalizeImage(raw, runningImageIds) {
    if (!raw || typeof raw !== "object")
        return null;
    var repo = String(raw.Repository || raw.repository || "");
    var tag = String(raw.Tag || raw.tag || "");
    var id = String(raw.ID || raw.Id || raw.id || "");
    var size = raw.Size || raw.size || raw.VirtualSize || 0;
    var created = String(raw.CreatedSince || raw.CreatedAt || raw.Created || "");

    if (repo === "" && id === "")
        return null;

    var displayName = repo;
    if (repo === "<none>")
        displayName = id.slice(0, 12);

    var inUse = false;
    if (runningImageIds) {
        // Check by full image reference or ID prefix
        var ref = repo + (tag && tag !== "<none>" ? ":" + tag : "");
        if (runningImageIds[ref] || runningImageIds[repo] || runningImageIds[id])
            inUse = true;
        // Also check short ID matches
        for (var key in runningImageIds) {
            if (id && key.indexOf(id.slice(0, 12)) !== -1)
                inUse = true;
        }
    }

    return {
        id: id,
        repo: repo,
        tag: tag,
        displayName: displayName,
        size: size,
        created: created,
        inUse: inUse
    };
}

function normalizeVolume(raw) {
    if (!raw || typeof raw !== "object")
        return null;
    var name = String(raw.Name || raw.name || "");
    if (name === "")
        return null;
    return {
        name: name,
        driver: String(raw.Driver || raw.driver || "local"),
        mountpoint: String(raw.Mountpoint || raw.mountpoint || "")
    };
}

function normalizeNetwork(raw) {
    if (!raw || typeof raw !== "object")
        return null;
    var name = String(raw.Name || raw.name || "");
    if (name === "")
        return null;
    return {
        name: name,
        driver: String(raw.Driver || raw.driver || ""),
        scope: String(raw.Scope || raw.scope || ""),
        isDefault: isDefaultNetwork(name)
    };
}

function isDefaultNetwork(name) {
    var n = String(name || "").toLowerCase();
    return n === "bridge" || n === "host" || n === "none";
}

function sortImages(a, b) {
    // In-use first
    if (a.inUse !== b.inUse)
        return a.inUse ? -1 : 1;
    // Then alphabetical by repo
    return String(a.repo || "").localeCompare(String(b.repo || ""));
}

function sortVolumes(a, b) {
    return String(a.name || "").localeCompare(String(b.name || ""));
}

function sortNetworks(a, b) {
    // Defaults last
    if (a.isDefault !== b.isDefault)
        return a.isDefault ? 1 : -1;
    return String(a.name || "").localeCompare(String(b.name || ""));
}

function matchesFilter(item, query) {
    if (!item || typeof item !== "object")
        return false;
    var q = String(query || "").toLowerCase().trim();
    if (q === "")
        return true;
    var fields = ["name", "image", "repo", "tag", "driver", "composeProject", "composeService", "displayName", "scope"];
    for (var i = 0; i < fields.length; ++i) {
        var value = item[fields[i]];
        if (value && String(value).toLowerCase().indexOf(q) !== -1)
            return true;
    }
    // Also check ID prefix
    if (item.id && String(item.id).toLowerCase().indexOf(q) !== -1)
        return true;
    return false;
}
