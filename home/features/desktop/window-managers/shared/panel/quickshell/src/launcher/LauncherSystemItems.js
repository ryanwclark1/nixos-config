.pragma library
.import "LauncherEntryRegistry.js" as EntryRegistry

/**
 * LauncherSystemItems.js
 *
 * Static item catalog builders for the System, NixOS, and DevOps launcher modes.
 * Items that require QML closures receive an `actions` capabilities object so
 * that this module remains a pure .pragma library (no QML object access).
 *
 * Usage from Launcher.qml:
 *
 *   import "LauncherSystemItems.js" as SystemItems
 *
 *   function loadSystem() {
 *       allItems = SystemItems.buildSystemItems({
 *           sessionActions:        SystemActionRegistry.sessionActions,
 *           shellEntryActions:     SystemActionRegistry.shellEntryActions,
 *           makeConfirmedSystemAction: makeConfirmedSystemAction,
 *           makeDetachedSystemAction:  makeDetachedSystemAction,
 *           execDetached:          function(cmd) { Quickshell.execDetached(cmd); },
 *           resolveCommand:        function(name, args) { return DependencyService.resolveCommand(name, args); },
 *           launchInTerminal:      launchInTerminal,
 *           defaultAdapter:        Bluetooth.defaultAdapter,
 *       });
 *       filterItems();
 *       completeModeLoad("system", true, "");
 *   }
 *
 *   function loadNixos() {
 *       allItems = SystemItems.buildNixosItems({
 *           launchInTerminal: launchInTerminal,
 *           close:            close,
 *           generations:      NixOS.generations,
 *           rollbackTo:       function(id) { NixOS.rollbackTo(id); },
 *       });
 *       filterItems();
 *       completeModeLoad("nixos", true, "");
 *   }
 *
 *   function loadDevOps() {
 *       allItems = SystemItems.buildDevOpsItems({
 *           dockerContainers: ServiceUnitService.dockerContainers,
 *           sshSessions:      ServiceUnitService.sshSessions,
 *           userUnits:        ServiceUnitService.userUnits,
 *           runDockerAction:  function(id, op) { ServiceUnitService.runDockerAction(id, op); },
 *           restartUnit:      function(scope, name) { ServiceUnitService.restartUnit(scope, name); },
 *           close:            close,
 *       });
 *       filterItems();
 *       completeModeLoad("devops", true, "");
 *   }
 */

// ---------------------------------------------------------------------------
// buildSystemItems
// ---------------------------------------------------------------------------

/**
 * Build the items array for the "system" launcher mode.
 *
 * @param {object} actions
 * @param {Array}    actions.sessionActions          - SystemActionRegistry.sessionActions
 * @param {Array}    actions.shellEntryActions       - SystemActionRegistry.shellEntryActions
 * @param {Function} actions.makeConfirmedSystemAction(title, id) -> function
 * @param {Function} actions.makeDetachedSystemAction(id) -> function
 * @param {Function} actions.execDetached(cmd)
 * @param {Function} actions.resolveCommand(name, fallbackArgs) -> string[]
 * @param {Function} actions.launchInTerminal(cmd)
 * @param {object}   actions.defaultAdapter          - Bluetooth.defaultAdapter (may be null)
 * @returns {Array}
 */
function buildSystemItems(actions) {
    var items = EntryRegistry.buildSystemDestinationItems(actions);

    // --- Power / session actions (from SystemActionRegistry.sessionActions) ---
    var powerActions = actions.sessionActions || [];
    for (var i = 0; i < powerActions.length; ++i) {
        var action = powerActions[i];
        var item = {
            category: action.category,
            name:     action.name,
            title:    action.title,
            icon:     action.icon
        };
        if (action.ipcTarget && action.ipcAction) {
            item.ipcTarget = action.ipcTarget;
            item.ipcAction = action.ipcAction;
        } else if (action.requiresConfirmation) {
            item.action = actions.makeConfirmedSystemAction(action.title, action.id);
        } else {
            item.action = actions.makeDetachedSystemAction(action.id);
        }
        items.push(item);
    }

    return items;
}

// ---------------------------------------------------------------------------
// buildNixosItems
// ---------------------------------------------------------------------------

/**
 * Build the items array for the "nixos" launcher mode.
 *
 * @param {object} actions
 * @param {Function} actions.launchInTerminal(cmd)
 * @param {Function} actions.close()
 * @param {Array}    actions.generations  - NixOS.generations (may be null/empty)
 * @param {Function} actions.rollbackTo(id)
 * @returns {Array}
 */
function buildNixosItems(actions) {
    var items = [
        {
            category: "System",
            name:     "Rebuild Switch (flake)",
            icon:     "󰒓",
            action:   (function(a) {
                return function() {
                    a.launchInTerminal("sudo nixos-rebuild switch --flake .#");
                };
            })(actions)
        },
        {
            category: "System",
            name:     "Update Flake Locks",
            icon:     "󰚰",
            action:   (function(a) {
                return function() {
                    a.launchInTerminal("nix flake update");
                };
            })(actions)
        },
        {
            category: "System",
            name:     "Collect Garbage",
            icon:     "󰃢",
            action:   (function(a) {
                return function() {
                    a.launchInTerminal("sudo nix-env --delete-generations old");
                };
            })(actions)
        }
    ];

    var gens = actions.generations;
    if (gens && gens.length > 0) {
        for (var i = 0; i < gens.length; i++) {
            var g = gens[i];
            items.push({
                category: "Generations",
                name:     "Generation " + g.id + (g.current ? " (current)" : ""),
                title:    g.date + " • " + g.version,
                icon:     g.current ? "󰄬" : "󰋚",
                action:   (function(id, a) {
                    return function() {
                        a.rollbackTo(id);
                        a.close();
                    };
                })(g.id, actions)
            });
        }
    }

    return items;
}

// ---------------------------------------------------------------------------
// buildDevOpsItems
// ---------------------------------------------------------------------------

/**
 * Build the items array for the "devops" launcher mode.
 *
 * @param {object} actions
 * @param {Array}    actions.dockerContainers  - ServiceUnitService.dockerContainers
 * @param {Array}    actions.sshSessions       - ServiceUnitService.sshSessions
 * @param {Array}    actions.userUnits         - ServiceUnitService.userUnits
 * @param {Function} actions.runDockerAction(id, op)
 * @param {Function} actions.restartUnit(scope, name)
 * @param {Function} actions.close()
 * @returns {Array}
 */
function buildDevOpsItems(actions) {
    var items = [];

    // --- Docker containers ---
    var containers = actions.dockerContainers || [];
    for (var i = 0; i < containers.length; i++) {
        var c = containers[i];
        items.push({
            category:    "Docker",
            name:        c.name,
            description: c.status + " (" + c.image + ")",
            icon:        "󰡨",
            action:      (function(id, state, a) {
                return function() {
                    a.runDockerAction(id, state === "running" ? "stop" : "start");
                    a.close();
                };
            })(c.id, c.state, actions)
        });
    }

    // --- SSH sessions ---
    var ssh = actions.sshSessions || [];
    var sshTypeIcons = { scp: "󰆏", sftp: "󰉋", rsync: "󰓦", sshfs: "󰋊" };
    for (var j = 0; j < ssh.length; j++) {
        var session = ssh[j];
        var sType = session.type || "ssh";
        var sLabel = session.label || "";
        var sCount = session.count || 1;
        items.push({
            category: sType === "ssh" ? "SSH" : sType.toUpperCase(),
            name:     sLabel + (sCount > 1 ? " ×" + sCount : ""),
            icon:     sshTypeIcons[sType] || "󰣀",
            action:   (function(a) {
                return function() {
                    a.close();
                };
            })(actions)
        });
    }

    // --- User systemd units ---
    var units = actions.userUnits || [];
    for (var k = 0; k < units.length; k++) {
        var u = units[k];
        if (u.active === "active" || u.name.indexOf("quickshell") !== -1) {
            items.push({
                category: "Service",
                name:     u.name.replace(".service", ""),
                icon:     u.active === "active" ? "󰄬" : "󰅚",
                action:   (function(name, a) {
                    return function() {
                        a.restartUnit("user", name);
                        a.close();
                    };
                })(u.name, actions)
            });
        }
    }

    return items;
}

// ---------------------------------------------------------------------------
// SSH items
// ---------------------------------------------------------------------------

/**
 * Parse an ad-hoc SSH target string into connection parts.
 *
 * @param {string} query - Raw user input like "user@host:port", "host", etc.
 * @returns {{ user: string, host: string, port: number }|null}
 */
function parseAdHocTarget(query) {
    var raw = String(query || "").trim();
    if (raw.length > 0 && raw[0] === ";")
        raw = raw.substring(1).trim();
    if (raw === "")
        return null;

    var user = "";
    var rest = raw;
    var atIdx = raw.indexOf("@");
    if (atIdx !== -1) {
        user = raw.substring(0, atIdx);
        rest = raw.substring(atIdx + 1);
    }

    var host = rest;
    var port = 22;
    var colonIdx = rest.lastIndexOf(":");
    if (colonIdx !== -1) {
        var portStr = rest.substring(colonIdx + 1);
        var portNum = parseInt(portStr, 10);
        if (!isNaN(portNum) && portNum >= 1 && portNum <= 65535 && String(portNum) === portStr) {
            host = rest.substring(0, colonIdx);
            port = portNum;
        }
    }

    if (host === "")
        return null;
    return { user: user, host: host, port: port };
}

/**
 * Build the items array for the "ssh" launcher mode.
 *
 * @param {object} actions
 * @param {Array}    actions.mergedHosts        - SshWidgetData.mergedHosts
 * @param {Array}    actions.recentIds          - Recent host IDs (string[])
 * @param {string}   actions.sshCommand         - e.g. "ssh" or "kitten ssh"
 * @param {Function} actions.buildDisplayCommand(host) -> string
 * @param {Function} actions.connectHost(host)
 * @param {Function} actions.close()
 * @returns {Array}
 */
function buildSshItems(actions) {
    var items = [];
    var hosts = actions.mergedHosts || [];
    var recentIds = actions.recentIds || [];
    var recentMap = {};
    for (var r = 0; r < recentIds.length; ++r)
        recentMap[String(recentIds[r] || "")] = 100 - r;

    for (var i = 0; i < hosts.length; ++i) {
        var host = hosts[i];
        items.push({
            category: host.source === "imported" ? "Imported" : (host.group || "Manual"),
            name: host.label || host.alias || host.host,
            title: actions.buildDisplayCommand(host),
            icon: host.icon || "󰣀",
            _hostRef: host,
            _recentBoost: recentMap[String(host.id || "")] || 0
        });
    }
    return items;
}

/**
 * Build a fallback ad-hoc SSH item for an unknown host target.
 *
 * @param {string} query      - Cleaned search query
 * @param {string} sshCommand - e.g. "ssh" or "kitten ssh"
 * @returns {object|null}
 */
function buildAdHocSshItem(query, sshCommand) {
    var parsed = parseAdHocTarget(query);
    if (!parsed)
        return null;
    var target = parsed.user ? (parsed.user + "@" + parsed.host) : parsed.host;
    var displayCmd = sshCommand + " " + target;
    if (parsed.port !== 22)
        displayCmd = sshCommand + " -p " + String(parsed.port) + " " + target;
    return {
        category: "Ad-hoc",
        name: target,
        title: displayCmd,
        icon: "apps.svg",
        _adHoc: parsed,
        _recentBoost: -1
    };
}

// ---------------------------------------------------------------------------
// resultSectionLabel
// ---------------------------------------------------------------------------

/**
 * Compute the section header label for a result item.
 *
 * Extracted from the QML `resultSectionLabel(item)` method. The QML bridge
 * becomes a thin one-liner:
 *
 *   function resultSectionLabel(item) {
 *       return SystemItems.resultSectionLabel(mode, item, {
 *           drunCategoryFiltersEnabled: drunCategoryFiltersEnabled,
 *           drunCategoryFilter:        drunCategoryFilter,
 *           formatDrunCategoryLabel:   formatDrunCategoryLabel,
 *           ensureItemRankCache:       Search.ensureItemRankCache,
 *           modeInfoFn:                modeInfo,
 *       });
 *   }
 *
 * @param {string} mode   - Current launcher mode key
 * @param {object} item   - Result item (may be null)
 * @param {object} opts
 * @param {boolean}  opts.drunCategoryFiltersEnabled
 * @param {string}   opts.drunCategoryFilter
 * @param {Function} opts.formatDrunCategoryLabel(key) -> string
 * @param {Function} opts.ensureItemRankCache(item)
 * @param {Function} opts.modeInfoFn(mode) -> { label: string, ... }
 * @returns {string}
 */
function resultSectionLabel(mode, item, opts) {
    if (!item)
        return "";

    if (mode === "drun") {
        if (!opts.drunCategoryFiltersEnabled)
            return "Applications";
        opts.ensureItemRankCache(item);
        var drunKey = String(item._primaryCategoryKey || "");
        return drunKey === "" ? "Applications" : opts.formatDrunCategoryLabel(drunKey);
    }

    if (mode === "files")     return "Files";
    if (mode === "run")       return "Commands";
    if (mode === "clip")      return "Clipboard";
    if (mode === "emoji")     return String(item.categoryLabel || item.category || "Characters");
    if (mode === "bookmarks") return "Bookmarks";
    if (mode === "web")       return String(item.providerName || item.category || "Web");

    var category = String(item.category || "");
    if (category !== "")
        return category;
    return String(opts.modeInfoFn(mode).label || "Results");
}
