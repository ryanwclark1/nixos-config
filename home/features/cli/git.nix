{
  pkgs,
  ...
}:
let
  ssh = "${pkgs.openssh}/bin/ssh";

  # git commit --amend, but for older commits
  git-fixup = pkgs.writeShellScriptBin "git-fixup" ''
    rev="$(git rev-parse "$1")"
    git commit --fixup "$@"
    GIT_SEQUENCE_EDITOR=true git rebase -i --autostash --autosquash $rev^
  '';
in
{
  home.packages = with pkgs; [
    git-fixup
    git-gone
    git-bug
    git-workspace
    codeberg-cli
  ];

  programs.git = {
    enable = true;

    package = pkgs.gitAndTools.gitFull;

    aliases = {
      p = "pull --ff-only";
      ff = "merge --ff-only";
      graph = "log --decorate --oneline --graph";
      pushall = "!git remote | xargs -L1 git push --all";
      add-nowhitespace = "!git diff -U0 -w --no-color | git apply --cached --ignore-whitespace --unidiff-zero -";
    };
    userName = "Ryan Clark";
    userEmail = "ryanc@accentservices.com";
    lfs.enable = true;

    ignores = [
      ".direnv"
      "result"
      ".env"
      ".venv"
      ".vscode"
      "node_modules"
      ".envrc"
    ];

    delta = {
      enable = true;
      options = {
        line-numbers = "true";
        side-by-side = "true";
        decorations = "true";
      };
    };

    extraConfig = {
      init.defaultBranch = "main";
      rebase.autosquash = true;
      rebase.autoStash = true;
      push.autoSetupRemote = true; # automatically create upstream branch on push
      url = {
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
}
