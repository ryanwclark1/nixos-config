{ pkgs, lib, ... }:

{
  home.packages = lib.filter (p: p != null) [
    pkgs.gitbutler
    pkgs.but
    pkgs.git-surgeon
    pkgs.hunk
    pkgs.tuicr
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
