{ pkgs, lib, ... }:

let
  llmAgents = import ../shared/llm-agents-packages.nix { inherit pkgs lib; };
  gascity = llmAgents.from "gascity" (pkgs.gascity or null);
in
{
  home.packages = llmAgents.available [
    (llmAgents.from "gastown" (pkgs.gastown or null))
    (if gascity != null then pkgs.lowPrio gascity else null)
    (llmAgents.from "bernstein" (pkgs.bernstein or null))
  ];

  xdg.configFile."agent-desk/architecture/gastown.md".text = ''
    # Gastown

    Gastown is the orchestration layer for the Agent Desk workstation.

    It coordinates:

    - Agent roles
    - Workflows
    - Workspaces
    - Messaging
    - Reviews

    Target flow:

    Human -> Gastown -> Specialized Agents -> Beads -> Git
  '';
}
