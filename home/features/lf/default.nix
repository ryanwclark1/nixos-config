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
      source =  "${pkgs.pistol}/bin/pistol";

    };

    settings = {
      preview = true;
      hidden = true;
      drawbox = true;
      icons = true;
      ignorecase = true;
      color256 = true;
      # shell = "zsh";
      # shellopts = "-c";
    };

    keybindings = {
      f = "$(fzf)";
      nd = "mkdir";
      nf = "mkfile";
      "<c-f>" = "fzf_jump";
      gs = "fzf_search";
      "<space>" = "toggle";
    };

    #   f = "$EDITOR $(fzf)";
    #   "<enter>" = "shell";
    #   o = "&mimeopen $f";
    #   O = "map O $mimeopen --ask $f";
    # };

    commands = {

      on-select = ''
        &{{
            lf -remote "send $id set statfmt \"$(eza -ld --color=always "$f")\""
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
    };
    #   f = "${pkgs.fzf}/bin/fzf --print0 --preview='${pkgs.pistol}/bin/pistol {}'";
    # };
    #   f = "$EDITOR $(fzf --preview='pistol {})";

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

}
