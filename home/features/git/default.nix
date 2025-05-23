{
  pkgs,
  ...
}:
let
  git-fixup = pkgs.writeShellScriptBin "git-fixup" ''
    rev="$(git rev-parse "$1")"
    git commit --fixup "$@"
    GIT_SEQUENCE_EDITOR=true git rebase -i --autostash --autosquash $rev^
  '';
in
{
  home.packages = with pkgs; [
    git-fixup
    git-workspace
    codeberg-cli
  ];

  programs.git = {
    enable = true;
    package = pkgs.git;
    userName = "Ryan Clark";
    userEmail = "36689148+ryanwclark1@users.noreply.github.com";

    aliases = {
      p = "pull --ff-only";
      ff = "merge --ff-only";
      graph = "log --decorate --oneline --graph";
      pushall = "!git remote | xargs -L1 git push --all";
      add-nowhitespace = "!git diff -U0 -w --no-color | git apply --cached --ignore-whitespace --unidiff-zero -";
    };

    attributes = [
      "*.pdf diff=pdf"
    ];

    ignores = [
      ".direnv"
      "result"
      ".env"
      ".venv"
      "node_modules"
      ".envrc"

       # Compiled source #
      ###################
      "*.class"
      "*.dll"
      "*.exe"
      "*.o"
      "*.so"

      # Temporary files #
      ###################
      "*.swp"
      "*.swo"
      "*~"

      # Packages #
      ############
      "*.7z"
      "*.dmg"
      "*.gz"
      "*.iso"
      "*.jar"
      "*.rar"
      "*.tar"
      "*.zip"

      # Logs #
      ######################
      "*.log"

      # OS generated files #
      ######################
      ".DS_Store*"
      "ehthumbs.db"
      "Icon?"
      "Thumbs.db"
    ];

    delta = {
      enable = true;
      options = {
        diff-so-fancy = true;
        line-numbers = true;
        side-by-side = true;
        decorations = true;
        true-color = "always";
      };
    };

    hooks = {
      # pre-commit = ./pre-commit-script;
    };

    lfs = {
      enable = true;
      skipSmudge = false;
    };

    extraConfig = {
      core.editor = "$EDITOR";
      github.user = "ryanwclark1";
      init.defaultBranch = "main";
      advice.objectNameWarning = false;
      pull.rebase = true;
      push.autoSetupRemote = true; # automatically create upstream branch on push
      rebase.autosquash = true;
      rebase.autoStash = true;
      trim.bases = "develop,master,main";
      url = {
        "https://github.com/" = {
          insteadOf = [
            "gh:"
            "github:"
          ];
        };
        "https://gitlab.com/" = {
          insteadOf = [
            "gl:"
            "gitlab:"
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
