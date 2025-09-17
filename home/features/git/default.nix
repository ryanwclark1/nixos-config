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
      # Nix
      ".direnv"
      "result"
      "result-*"

      # Environment files
      ".env"
      ".env.local"
      ".venv"
      ".envrc"

      # Dependencies
      "node_modules"
      "vendor"

      # Compiled source
      "*.class"
      "*.dll"
      "*.exe"
      "*.o"
      "*.so"
      "*.pyc"
      "__pycache__/"

      # Temporary files
      "*.swp"
      "*.swo"
      "*~"
      ".netrwhist"

      # Packages
      "*.7z"
      "*.dmg"
      "*.gz"
      "*.iso"
      "*.jar"
      "*.rar"
      "*.tar"
      "*.zip"

      # Logs
      "*.log"
      "npm-debug.log*"
      "yarn-debug.log*"
      "yarn-error.log*"

      # OS generated files
      ".DS_Store"
      ".DS_Store?"
      "._*"
      ".Spotlight-V100"
      ".Trashes"
      "ehthumbs.db"
      "Icon?"
      "Thumbs.db"

      # Personal notes
      ".notes/"
      "TODO.md"
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
