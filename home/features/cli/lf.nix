# lf (as in "list files") is a terminal file manager written in Go with a heavy inspiration from ranger file manager.
{
  lib,
  config,
  pkgs,
  ...
}:
with lib; {
  options.lf.enable = mkEnableOption "lf";

  config = mkIf config.lf.enable {
    programs.lf = {
      enable = true;
      previewer = {
        keybinding = "i";

        source = pkgs.writeShellScript "pv.sh" ''
          #!/bin/sh
          case "''${1,,}" in
              *.tar*) tar tf "$1";;
              *.zip) ${pkgs.p7zip}/bin/7z l "$1";;
              *.rar) ${pkgs.p7zip}/bin/7z l "$1";;
              *.7z) ${pkgs.p7zip}/bin/7z l "$1";;
              *.dll|*.exe|*.ttf|*.woff|*.otf|*eot) ${pkgs.exiftool}/bin/exiftool "$1";;
              *) ${pkgs.pistol}/bin/pistol "$1";;
          esac
        '';
      };

      settings = {
        # color256 = false;
        hidden = true;
        icons = true;
        shell = "zsh";
        shellopts = "-c";
      };

      keybindings = {
        nd = "mkdir";
        nf = "mkfile";
        "<c-f>" = "search";
        "<space>" = "toggle";
        f = "$vi $(fzf)";
        "<enter>" = "shell";
        o = "&mimeopen $f";
        O = "map O $mimeopen --ask $f";
      };

      commands = {
        f = "$vi $(fzf)";
        fzf_search = ''
          ''${{
              res="$( \
                  RG_PREFIX="rg --column --line-number --no-heading --color=always \
                      --smart-case "
                  FZF_DEFAULT_COMMAND="$RG_PREFIX \'\'" \
                      fzf --bind "change:reload:$RG_PREFIX {q} || true" \
                      --ansi --layout=reverse --header 'Search in files' \
                      | cut -d':' -f1
              )"
              [ ! -z "$res" ] && lf -remote "send $id select \"$res\""
          }}
        '';

        open = ''
          ''${{
              test -L $f && f=$(readlink -f $f)
              case $(file --mime-type $f -b) in
                  text/*) $EDITOR $fx;;
                  *) for f in $fx; do setsid $OPENER $f > /dev/null 2> /dev/null & done;;
              esac
          }}
        '';

        mkdir = ''
          ''${{
            printf "Directory Name: "
            read ans
            mkdir $ans
          }}
        '';

        mkfile = ''
          ''${{
            printf "File Name: "
            read ans
            $EDITOR $ans
          }}
        '';

        extract = ''
          ''${{
              set -f
              atool -x $f
          }}
        '';

        z = ''
          %{{
                	result="$(zoxide query --exclude $PWD $@)"
                	lf -remote "send $id cd $result"
          }}
        '';

        zi = ''
          ''${{
          	result="$(zoxide query -i)"
          	lf -remote "send $id cd $result"
          }}
        '';
      };
    };
  };
}