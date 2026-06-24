{ pkgs, lib, ... }:

{
  home.packages = lib.filter (p: p != null) [
    pkgs.cli-proxy-api
    pkgs.mcporter
    pkgs.claude-code-router
    pkgs.rtk
  ];

  xdg.configFile."agent-desk/architecture/model-proxy.md".text = ''
    # Model Abstraction Layer

    The workstation should be ready for an OpenAI-compatible proxy layer.

    Goal:

    Agents -> Compatibility Layer -> Claude / GPT / Gemini / Local Models

    This keeps Gastown and other orchestration tools from needing provider-
    specific SDK wiring for every agent role.
  '';
}
