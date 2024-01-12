{ pkgs, lib, config, ... }:
let
  ssh = "${pkgs.openssh}/bin/ssh";

  git-m7 = pkgs.writeShellScriptBin "git-m7" ''
    case "''${1:-ls}" in
      ls)
        ${ssh} -TA git@techcasa.io ls | grep '\.git$'
        ;;
      init)
        name="''${2:-$(basename "$PWD")}"
        ${ssh} -TA git@techcasa.io << EOF
          git init --bare "$name.git"
          git -C "$name.git" branch -m main
    EOF
        git remote add origin git@techcasa.io:"$name.git"
        ;;
      *)
        repo="$(git remote -v | grep git@techcasa.io | head -1 | cut -d ':' -f2 | cut -d ' ' -f1)"
        if [[ "$repo" != *".git" ]]; then repo="$repo.git"; fi
        ${ssh} -TA git@techcasa.io git -C "/srv/git/$repo" "$@"
        ;;
    esac
  '';
  # git commit --amend, but for older commits
  git-fixup = pkgs.writeShellScriptBin "git-fixup" ''
    rev="$(git rev-parse "$1")"
    git commit --fixup "$@"
    GIT_SEQUENCE_EDITOR=true git rebase -i --autostash --autosquash $rev^
  '';
in
{
  home.packages = [ git-m7 git-fixup ];
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
    userEmail = "hi@techcasa.io";
    extraConfig = {
      init.defaultBranch = "main";
      user.signing.key = "CE707A2C17FAAC97907FF8EF2E54EA7BFE630916";
      commit.gpgSign = true;
      gpg.program = "${config.programs.gpg.package}/bin/gpg2";
    };
    lfs.enable = true;
    ignores = [ ".direnv" "result" ];
  };
}
