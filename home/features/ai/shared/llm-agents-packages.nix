{ pkgs, lib }:

let
  llmAgents = pkgs.llm-agents or { };
in
{
  inherit llmAgents;

  from =
    name: fallback:
    if builtins.hasAttr name llmAgents then builtins.getAttr name llmAgents else fallback;

  optional = name: if builtins.hasAttr name llmAgents then builtins.getAttr name llmAgents else null;

  available = lib.filter (pkg: pkg != null);
}
