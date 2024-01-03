{
  lib,
  config,
  pkgs,
  ...
}:
with lib; {
  options.alias.enable = mkEnableOption "alias settings";

  config = mkIf config.alias.enable {
    # programs.exa.enableAliases = mkIf config.filesearch.enable true;

    home.shellAliases = {
      tree = mkIf config.filesearch.enable "eza --tree --icons";
      rg = mkIf config.filesearch.enable "rg --sort path";
      jctl = "journalctl -p 3 -xb";
      df = "df -h";
      cp = "cp -r";
      go = mkIf config.go.enable "richgo";
      # sudo = "sudo -E";
      fzf = mkIf config.fzf.enable "fzf --preview='pistol {}'";
      j = "jobs";
      f = "fg";
      # h = "hx";
      b = "bg";
      n = "nvim";
      pc = "proxychains4 -q";
      y = "yazi";

      # k = "kubectl";
      # urldecode = "python3 -c 'import sys, urllib.parse as ul; print(ul.unquote_plus(sys.stdin.read()))'";
      # urlencode = "python3 -c 'import sys, urllib.parse as ul; print(ul.quote_plus(sys.stdin.read()))'";

      #  Use `lib.mkForce value` or `lib.mkDefault value` to change the priority on any of these definitions.
      # ls = "eza -lag --icons --header --group-directories-first";
      # lr = "eza -lTg --icons --header --group-directories-first";

      # git related stuff
      gl = "git lg";
      gc = "git commit -S -m ";
      ga = "git add --patch";
      gd = "git diff";
      gsi = "git si";

      #tmux
      # t = "${pkgs.tmux}/bin/tmux new -A -s $(${pkgs.gum}/bin/gum input --placeholder=name)";
      # mhx = "echo \"{ } \" | ${pkgs.jq}/bin/jq --arg s subject --arg sv $(${pkgs.gum}/bin/gum choose  --header=\"subject\" movement changes shell selection search minor-modes view-mode goto-mode match-mode window-mode space-mode popup unimpaired insert select-extend picker prompt) --arg k key --arg kv $(gum input --placeholder=\"key\") --arg d description  --arg dv $(gum input --placeholder=\"description\") --arg c command --arg cv $(gum input --placeholder=\"command\") '. + { ($s): $sv, ($k): $kv, ($d): $dv, ($c): $cv }' | ${config.repos.hxkeyboards.path}";

      # t = config.multiplexer.tmux.newSession.withNameAndAttach;
      # ta = config.multiplexer.tmux.openAndSelect;
      # zl = config.multiplexer.zellij.newSession.withNameAndAttach;
      # za = config.multiplexer.zellij.openAndSelect;
    };
  };
}