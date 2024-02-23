# lf (as in "list files") is a terminal file manager written in Go with a heavy inspiration from ranger file manager.
{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    file #A program that shows the type of files.
    exiftool #A program that shows the metadata of files.
    mediainfo
    poppler_utils #pdftotext and pdfinfo
    epub2txt2
    xlsx2csv #for xlsx files
    librsvg
    chafa #for lf image previews
    odt2txt
    elinks
    hexyl
    notcurses
  ];

  programs.lf = {
    enable = true;
    previewer = {
      keybinding = "i";
      source = pkgs.writeShellScript "pv.sh" ''
        #!/usr/bin/env bash
        EXIF_TAGS="-FileName -FileSize -FileModifyDate -FilePermissions -FileTypeExtension -MIMEType -ImageSize"

        MIMETYPE="$(file --dereference --brief --mime-type -- "$1")"

        case "$MIMETYPE" in
          text/html)
            ${pkgs.exiftool}/bin/exiftool -s $EXIF_TAGS "$1"; echo -e "\n"; ${pkgs.elinks}/bin/elinks dump "$1"
            ;;
          text/*)
            ${pkgs.exiftool}/bin/exiftool -s $EXIF_TAGS "$1"; echo -e "\n"; ${pkgs.bat}/bin/bat --style=plain --paging=never --color=always -- "$1"
            ;;
          image/*)
            # kitty chafa format is not working.
            case "$TERM" in
              *kitty)
                CHAFA_FORMAT="kitty";;
              *)
                CHAFA_FORMAT="symbols";;
            esac
            ${pkgs.exiftool}/bin/exiftool -s $EXIF_TAGS "$1"; echo -e "\n"; ${pkgs.chafa}/bin/chafa --format=symbols -- "$1"
            ;;
          video/*)
            ${pkgs.mediainfo}/bin/mediainfo -- "$1"
            ;;
          audio/*)
            ${pkgs.mediainfo}/bin/mediainfo -- "$1"
            ;;
          application/json)
            ${pkgs.exiftool}/bin/exiftool -s $EXIF_TAGS "$1"; echo -e "\n"; ${pkgs.jq}/bin/jq --color-output . "$1" | head -n 100
            ;;
          application/x-7z-compressed|application/x-bzip|application/x-bzip2)
              ${pkgs.exiftool}/bin/exiftool -s $EXIF_TAGS "$1";echo -e "\n"; ${pkgs.p7zip}/bin/7z l "$1" | awk '/  Date/{print}'
            ;;
          application/zip)
              ${pkgs.exiftool}/bin/exiftool -s $EXIF_TAGS "$1"; echo -e "\n"; ${pkgs.atool}/bin/atool --list -- "$1"
            ;;
          application/gzip|application/x-xz)
            ${pkgs.exiftool}/bin/exiftool -s $EXIF_TAGS "$1";echo -e "\n"; ${pkgs.atool}/bin/atool --list -- "$1"| sed '\Permission\tUID/GID\t\tSize\tDate\tTime\tFileName\n---------\t-------\t\t----\t----\t----\t--------'
            ;;
          application/pdf)
            ${pkgs.exiftool}/bin/exiftool -s $EXIF_TAGS "$1"; echo -e "\n"; ${pkgs.poppler_utils}/bin/pdftotext -l 4 -nopgbrk -q -- "$1" - | fmt -w $(tput cols)
            ;;
          application/epub+zip)
            ${pkgs.exiftool}/bin/exiftool -s $EXIF_TAGS "$1"; echo -e "\n"; ${pkgs.epub2txt2}/bin/epub2txt "$1"
            ;;
          application/x-msdownload)
            ${pkgs.exiftool}/bin/exiftool "$1"
            ;;
          application/x-sharedlib)
            ${pkgs.exiftool}/bin/exiftool "$1"
            ;;
          application/x-executable)
            ${pkgs.exiftool}/bin/exiftool "$1"
            ;;
          application/x-font-ttf)
            ${pkgs.exiftool}/bin/exiftool "$1"
            ;;
          application/x-font-woff)
            ${pkgs.exiftool}/bin/exiftool "$1"
            ;;
          application/x-font-otf)
            ${pkgs.exiftool}/bin/exiftool "$1"
            ;;
          application/vnd.ms-opentype)
            ${pkgs.exiftool}/bin/exiftool "$1"
            ;;
          application/vnd.ms-fontobject)
            ${pkgs.exiftool}/bin/exiftool "$1"
            ;;
          application/vnd.openxmlformats-officedocument.spreadsheetml.sheet)
            ${pkgs.exiftool}/bin/exiftool -s $EXIF_TAGS "$1"; echo -e "\n"; ${pkgs.xlsx2csv}/bin/xlsx2csv -i -- "$1"
            ;;
          application/vnd.ms-excel)
            ${pkgs.exiftool}/bin/exiftool -s $EXIF_TAGS "$1"; echo -e "\n"; ${pkgs.xlsx2csv}/bin/xlsx2csv -i -- "$1"
            ;;
          application/vnd.sqlite3)
            # open sqlite3 database and show table names in the terminal
            ${pkgs.exiftool}/bin/exiftool "$1"; echo -e "\n"; sqlite3 "$1" ".tables";echo "$MIMETYPE"; echo "$1"
            ;;
          application/*)
            ${pkgs.exiftool}/bin/exiftool -s $EXIF_TAGS "$1"; echo -e "\n"; echo "$MIMETYPE"; echo "$1"
            ;;
          *)
            ${pkgs.exiftool}/bin/exiftool -s $EXIF_TAGS "$1"; echo -e "\n"; echo "$MIMETYPE"; echo "$1"
            ;;
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
    mime_types = {
      source = ./mime.types;
      target = ".config/lf/mime.types";
    };
  };

}
