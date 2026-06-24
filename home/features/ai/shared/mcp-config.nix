{
  config,
  pkgs,
  lib,
}:

let
  playwrightMcpWrapper = import ./playwright-mcp-wrapper.nix { inherit pkgs lib; };
in
{
  programs = {
    time.enable = true;
    git.enable = true;
    fetch.enable = true;
    sequential-thinking.enable = true;

    context7 = {
      enable = true;
      passwordCommand.CONTEXT7_TOKEN = [
        "${pkgs.coreutils}/bin/cat"
        config.sops.secrets.context7-token.path
      ];
    };

    github = {
      enable = true;
      package = pkgs.github-mcp-server;
      env = {
        GITHUB_DYNAMIC_TOOLSETS = "1";
      };
      passwordCommand.GITHUB_PERSONAL_ACCESS_TOKEN = [
        "${pkgs.coreutils}/bin/cat"
        config.sops.secrets.github-pat.path
      ];
    };
  };

  settings.servers.playwright = {
    command = "${playwrightMcpWrapper}/bin/mcp-server-playwright-nixos";
    args = [ "--headless" ];
    env = {
      PLAYWRIGHT_BROWSERS_PATH = "${lib.getLib pkgs.playwright.browsers}";
    };
  };
}
