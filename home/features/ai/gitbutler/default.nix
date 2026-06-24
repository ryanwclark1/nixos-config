{ pkgs, lib, ... }:

let
  llmAgents = import ../shared/llm-agents-packages.nix { inherit pkgs lib; };
in
{
  home.packages = llmAgents.available [
    (llmAgents.from "gitbutler" (pkgs.gitbutler or null))
    (llmAgents.from "but" (pkgs.but or null))
    (llmAgents.from "git-surgeon" (pkgs.git-surgeon or null))
    (llmAgents.from "hunk" (pkgs.hunk or null))
    (llmAgents.from "tuicr" (pkgs.tuicr or null))
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
