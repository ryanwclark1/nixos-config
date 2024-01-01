{
  lib,
  config,
  pkgs,
  ...
}:

with lib; {
  options.git.enable = mkEnableOption "git settings";

  config = mkIf config.git.enable {
    home.packages = with pkgs; [
      git-gone # trim stale branches
      git-bug # bug reporting right inside the repo
      git-workspace # workspace management
      codeberg-cli
    ];
    programs.git = {
      enable = true;
      userName = "Ryan Clark";
      userEmail = "ryanc@accentservices.com";
      ignores = [
        ".env"
        ".vscode"
      ];
      delta = {
        enable = true;
        options = {
          line-numbers = "true";
          side-by-side = "true";
          decorations = "true";
        };
      };
      diff-so-fancy.enable = true;
      lfs = {
        enable = true;
      };
      extraConfig = {
        init = {
          defaultBranch = "main";
        };
        rebase.autosquash = true;
        rebase.autoStash = true;
        url = {
          # "ssh://git@codeberg.org".insteadOf = "https://codeberg.org";
          # "ssh://git@gitlab.com".insteadOf = "https://gitlab.com";
          # "ssh://git@github.com".insteadOf = "https://github.com";
          "https://github.com/" = {
            insteadOf = [
              "gh:"
              "github:"
            ];
          };
          "https://codeberg.org/" = {
            insteadOf = [
              "cb:"
              "codeberg:"
            ];
          };
        };
      };
    };
    programs.gh = {
      enable = true;
      gitCredentialHelper.enable = false;
      extensions = [
        pkgs.gh-dash
        pkgs.gh-eco
        # gh-poi # not yet available
        pkgs.gh-cal
        pkgs.gh-markdown-preview
      ];
    };
  };
}