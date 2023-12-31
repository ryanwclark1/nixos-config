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
      # signing = {
      #   key = "39FEBB6A870385E3";
      #   signByDefault = true;
      # };

      diff-so-fancy.enable = true;
      delta.enable = true;
      lfs.enable = true;
      aliases = {
        lg = "log --pretty=\"%C(green bold)%h%C(reset) %C(blue)%d%C(reset) %C(italic)%s%C(reset) %C(Cyan)(%ar)%C(reset)\" --graph";
        gsi = "stash save --keep-index";
        new = "lg main..HEAD";
        missing = "lg HEAD..main";
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
