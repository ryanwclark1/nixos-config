.pragma library

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
    var items = [];

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

    // --- Capture items ---
    items.push({
        category: "Capture",
        name:     "Screenshot (Area)",
        icon:     "󰹑",
        action:   (function(a) {
            return function() {
                a.execDetached(a.resolveCommand("qs-screenshot", ["area", "--satty"]));
            };
        })(actions)
    });
    items.push({
        category: "Capture",
        name:     "Screenshot (Display)",
        icon:     "󰍹",
        action:   (function(a) {
            return function() {
                a.execDetached(a.resolveCommand("qs-screenshot", ["screen", "--satty"]));
            };
        })(actions)
    });
    items.push({
        category: "Capture",
        name:     "Color Picker",
        icon:     "󰏘",
        action:   (function(a) {
            return function() {
                a.execDetached(["hyprpicker", "-a"]);
            };
        })(actions)
    });

    // --- Toggle items ---
    items.push({
        category: "Toggles",
        name:     "Toggle Bluetooth",
        icon:     "󰂯",
        action:   (function(adapter) {
            return function() {
                if (adapter)
                    adapter.enabled = !adapter.enabled;
            };
        })(actions.defaultAdapter)
    });
    items.push({
        category: "Toggles",
        name:     "Toggle Night Light",
        icon:     "󰖔",
        action:   (function(a) {
            return function() {
                a.execDetached(["os-toggle-nightlight"]);
            };
        })(actions)
    });

    // --- Shell entry / control actions (from SystemActionRegistry.shellEntryActions) ---
    var controlActions = actions.shellEntryActions || [];
    for (var j = 0; j < controlActions.length; ++j) {
        var control = controlActions[j];
        items.push({
            category:  control.category,
            name:      control.name,
            title:     control.title,
            icon:      control.icon,
            ipcTarget: control.ipcTarget,
            ipcAction: control.ipcAction
        });
    }

    // --- Utility items ---
    items.push({
        category: "Utilities",
        name:     "System Monitor",
        icon:     "󰄨",
        action:   (function(a) {
            return function() {
                a.execDetached(["quickshell", "ipc", "call", "Shell", "openSurface", "systemMonitor"]);
            };
        })(actions)
    });
    items.push({
        category: "Utilities",
        name:     "System Monitor (terminal btop)",
        icon:     "󱓞",
        action:   (function(a) {
            return function() {
                a.launchInTerminal("btop");
            };
        })(actions)
    });
    items.push({
        category: "Utilities",
        name:     "Audio Settings",
        icon:     "󰕾",
        action:   (function(a) {
            return function() {
                a.launchInTerminal("wiremix");
            };
        })(actions)
    });

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
    if (mode === "emoji")     return "Emoji";
    if (mode === "bookmarks") return "Bookmarks";
    if (mode === "web")       return String(item.providerName || item.category || "Web");

    var category = String(item.category || "");
    if (category !== "")
        return category;
    return String(opts.modeInfoFn(mode).label || "Results");
}
