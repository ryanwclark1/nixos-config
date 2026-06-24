{ pkgs, lib, ... }:

let
  available = lib.filter (pkg: pkg != null);
in
{
  home.packages = available [
    (pkgs.cli-proxy-api or null)
    (pkgs.mcporter or null)
    (pkgs.claude-code-router or null)
    (pkgs.rtk or null)
  ];

  xdg.configFile."accent-ai/architecture/model-proxy.md".text = ''
    # Model Abstraction Layer

    The workstation should be ready for an OpenAI-compatible proxy layer.

    Goal:

    Agents -> Compatibility Layer -> Claude / GPT / Gemini / Local Models

    This keeps Gastown and other orchestration tools from needing provider-
    specific SDK wiring for every agent role.
  '';
}
