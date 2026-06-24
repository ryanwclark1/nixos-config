{ pkgs, lib, ... }:

let
  available = lib.filter (pkg: pkg != null);
in
{
  home.packages = available [
    (pkgs.workmux or null)
    pkgs.tmux
    pkgs.zellij
  ];

  xdg.configFile."agent-desk/workspaces/conventions.md".text = ''
    # Workspace Conventions

    WorkMux owns short-lived, isolated workspaces for agent work.

    Expected layout:

    - agent-desk
    - k8s-infra
    - accent-monitoring

    Workspace naming:

    - feature-<short-name>
    - bugfix-<short-name>
    - docs-<short-name>
    - research-<short-name>

    Each workspace should map to one Beads work item or one Gastown workflow
    stage whenever possible.
  '';
}
