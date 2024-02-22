# lf (as in "list files") is a terminal file manager written in Go with a heavy inspiration from ranger file manager.
{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    exiftool
    mediainfo
    poppler_utils #pdftotext and pdfinfo
    hexyl
    epub2txt2
    ueberzugpp #for lf image previews
    xlsx2csv
    librsvg
    chafa #for lf image previews
    odt2txt
    elinks
  ];

  # programs.zathura = {
  #   enable = true;

  # };

  # General purpose file previewer designed for Ranger, Lf to make scope.sh redundant
  programs.pistol = {
    enable = true;
    associations = [
      {
        mime = "image/*";
        command = "${pkgs.exiftool}/bin/exiftool %pistol-filename%";
      }
      {
        mime = "video/*";
        command = "${pkgs.exiftool}/bin/exiftool %pistol-filename%";
      }
      {
        mime = "audio/*";
        command = "${pkgs.exiftool}/bin/exiftool %pistol-filename%";
      }
      {
        mime = "application/gzip";
        command = "${pkgs.atool}/bin/atool -l %pistol-filename%";
      }
      {
        mime = "application/pdf";
        command = "sh: pdftotext -l 10 -nopgbrk -q -- %pistol-filename% - | fmt -w $(tput cols)";
      }
      {
        mime = "application/epub+zip";
        command = "epub2txt %pistol-filename%";
      }
      {
        mime = "application/x-msdownload";
        command = "${pkgs.exiftool}/bin/exiftool %pistol-filename%";
      }
      {
        mime = "application/x-sharedlib";
        command = "${pkgs.exiftool}/bin/exiftool %pistol-filename%";
      }
      {
        mime = "application/x-executable";
        command = "${pkgs.exiftool}/bin/exiftool %pistol-filename%";
      }
      {
        mime = "application/x-font-ttf";
        command = "${pkgs.exiftool}/bin/exiftool %pistol-filename%";
      }
      {
        mime = "application/x-font-woff";
        command = "${pkgs.exiftool}/bin/exiftool %pistol-filename%";
      }
      {
        mime = "application/x-font-otf";
        command = "${pkgs.exiftool}/bin/exiftool %pistol-filename%";
      }
      {
        mime = "application/vnd.ms-opentype";
        command = "${pkgs.exiftool}/bin/exiftool %pistol-filename%";
      }
      {
        mime = "application/vnd.ms-fontobject";
        command = "${pkgs.exiftool}/bin/exiftool %pistol-filename%";
      }
      {
        mime = "application/vnd.ms-excel";
        command = "${pkgs.exiftool}/bin/exiftool %pistol-filename%";
      }
      {
        mime = "application/application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
        command = "${pkgs.xlsx2csv}/bin/xlsx2csv %pistol-filename%";
      }
      {
        mime = "application/vnd.ms-excel";
        command = "${pkgs.xlsx2csv}/bin/xlsx2csv %pistol-filename%";
      }
      # {
      #   mime = "application/*";
      #   command = "${pkgs.hexyl}/bin/hexyl %pistol-filename%";
      # }
      {
        fpath = ".*.md$";
        command = "sh: bat --paging=never --color=always %pistol-filename% | head -8";
      }
    ];
  };

  programs.lf = {
    enable = true;
    previewer = {
      keybinding = "i";
      source = pkgs.writeShellScript "pv.sh" ''
        #!/usr/bin/env bash

        case "''${1,,}" in
            a|ace|alz|arc|arj|bz|bz2|cab|cpio|deb|gz|jar|lha|lz|lzh|lzma|lzo|\
            rpm|rz|tlz|txz|tZ|tzo|war|xpi|xz|Z)\
              type archive >/dev/null 2>&1 && archive ${pkgs.atool}/bin/atool --list -- "$1"||
              echo "ERROR: no atool program installed"
              ;;
            *.tar*|*.tbz|*.tbz2|*.tgz)
              type tar >/dev/null 2>&1 && tar tf "$1"||
              echo "ERROR: no tar program installed"
              ;;
            *.zip|*.7z|*.t7z|*.rar)
              type zip >/dev/null 2>&1 &&  ${pkgs.p7zip}/bin/7z l "$1" | tail -n +15;;
            *.pdf) ${pkgs.poppler_utils}/bin/pdftotext -l 10 -nopgbrk -q -- "$1" - | fmt -w $(tput cols);;
            *.odt|*.sxw) ${pkgs.odt2txt}/bin/odt2txt "$1";;
            *.ods|*.odp) ${pkgs.odt2txt}/bin/odt2txt "$1";;
            *.htm|*.html|*.xhtml) ${pkgs.elinks}/bin/elinks -dump "$1";;
            *.json) jq --color-output . "$1";;
            *.dll|*.exe|*.ttf|*.woff|*.otf|*eot) ${pkgs.exiftool}/bin/exiftool "$1";;
            *.xlsx) ${pkgs.xlsx2csv}/bin/xlsx2csv -"$1";;
            *) ${pkgs.pistol}/bin/pistol "$1";;
        esac

      '';
    };

    settings = {
      preview = true;
      hidden = true;
      drawbox = true;
      icons = true;
      ignorecase = true;
      color256 = true;
      sixel = true;
      shell = "sh";
      shellopts = "-eu";
    };

    keybindings = {
      f = "$(fzf)";
      nd = "mkdir";
      nf = "mkfile";
      "<c-f>" = "fzf_jump";
      gs = "fzf_search";
      "<space>" = "toggle";
      # use enter for shell commands
      "<enter>" = "shell";
      # show the result of execution of previous commands
      "`" = "!true";
      # execute current file (must be executable)
      x = "$$f";
      X = "!$f";
      # dedicated keys for file opener actions
      o = "&mimeopen $f";
      O = "&mimeopen -a $f";
    };

    commands = {

      # Shows information in bottom bar
      on-select = ''
        &{{
            lf -remote "send $id set statfmt \"$(eza -ld --color=always "$f")\""
        }}
      '';

      on-cd = ''
        &{{
          export STARSHIP_SHELL=
          fmt="$(starship prompt)"
          lf -remote "send $id set promptfmt \"$fmt\""
        }}
      '';

      fzf_jump = ''
        ''${{
          res="$(find . -maxdepth 1 | fzf --reverse --header='Jump to location')"
          if [ -n "$res" ]; then
              if [ -d "$res" ]; then
                  cmd="cd"
              else
                  cmd="select"
              fi
              res="$(printf '%s' "$res" | sed 's/\\/\\\\/g;s/"/\\"/g')"
              lf -remote "send $id $cmd \"$res\""
          fi
        }}
      '';

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
        &{{
            test -L $f && f=$(readlink -f $f)
            case $(file --mime-type -Lb $f) in
                text/*) lf -remote "send $id \$$EDITOR \$fx";;
                *) for f in $fx; do $OPENER $f > /dev/null 2> /dev/null & done;;
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

      # extract the current file with the right command
      # (xkcd link: https://xkcd.com/1168/)
      extract = ''
        ''${{
            set -f
            case $f in
                *.tar.bz|*.tar.bz2|*.tbz|*.tbz2) tar xjvf $f;;
                *.tar.gz|*.tgz) tar xzvf $f;;
                *.tar.xz|*.txz) tar xJvf $f;;
                *.zip) unzip $f;;
                *.rar) unrar x $f;;
                *.7z) 7z x $f;;
            esac
        }}
      '';

      # compress current file or selected files with tar and gunzip
      tar = ''
        ''${{
            set -f
            mkdir $1
            cp -r $fx $1
            tar czf $1.tar.gz $1
            rm -rf $1
        }}
      '';

      # compress current file or selected files with zip
      zip = ''
        ''${{
            set -f
            mkdir $1
            cp -r $fx $1
            zip -r $1.zip $1
            rm -rf $1
        }}
      '';

    };

    #   open = ''
    #     ''${{
    #         test -L $f && f=$(readlink -f $f)
    #         case $(file --mime-type $f -b) in
    #             text/*) $EDITOR $fx;;
    #             *) for f in $fx; do setsid $OPENER $f > /dev/null 2> /dev/null & done;;
    #         esac
    #     }}
    #   '';

    #   extract = ''
    #     ''${{
    #         set -f
    #         atool -x $f
    #     }}
    #   '';

      # z = ''
      #   %{{
      #       result="$(zoxide query --exclude $PWD $@)"
      #       lf -remote "send $id cd $result"
      #   }}
      # '';

    #   zi = ''
    #     ''${{
    #     	result="$(zoxide query -i)"
    #     	lf -remote "send $id cd $result"
    #     }}
    #   '';
    # };

  };
  home.file = {
    lf_icons = {
      source = ./icons;
      target = ".config/lf/icons";
    };
    lf_colors = {
      source = ./colors;
      target = ".config/lf/colors";
    };
    pv = {
      source = ./pv.sh;
      target = ".config/lf/pv.sh";
      executable = true;
    };
    mime_types = {
      source = ./mime.types;
      target = ".config/lf/mime.types";
    };
  };

}
