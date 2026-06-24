{ pkgs, lib, ... }:

let
  available = lib.filter (pkg: pkg != null);
in
{
  home.packages = available [
    (pkgs.gitbutler or null)
    (pkgs.but or null)
    (pkgs.git-surgeon or null)
    (pkgs.hunk or null)
    (pkgs.tuicr or null)
  ];

  xdg.configFile."agent-desk/architecture/gitbutler.md".text = ''
    # GitButler

    GitButler is the change-management layer for agent-heavy work.

    Use it for:

    - Parallel virtual branches
    - Stacked branch workflows
    - Separating agent-produced changesets
    - Reviewing layered implementation work

    Typical stack:

    schema -> api -> ui -> docs
  '';
}
