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
  ];

  # programs.zathura = {
  #   enable = true;

  # };

  # General purpose file previewer designed for Ranger, Lf to make scope.sh redundant
  programs.pistol = {
    enable = true;
    associations = [
      { mime = "image/*"; command = "mediainfo %pistol-filename%"; }
      { mime = "video/*"; command = "mediainfo %pistol-filename%"; }
      { mime = "audio/*"; command = "mediainfo %pistol-filename%"; }
      { mime = "text/*"; command = "bat %pistol-filename%"; }
      { mime = "application/pdf"; command = "sh: pdftotext -l 10 -nopgbrk -q -- %pistol-filename% - | fmt -w $(tput cols)"; }
      { mime = "application/epub+zip"; command = "foliate %pistol-filename%"; }
      { mime = "application/zip"; command = "unzip -l %pistol-filename%"; }
      { mime = "application/x-tar"; command = "tar tf %pistol-filename%"; }
      { mime = "application/x-xz"; command = "tar tf %pistol-filename%"; }
      { mime = "application/x-bzip2"; command = "tar tf %pistol-filename%"; }
      { mime = "application/x-rar"; command = "unrar l %pistol-filename%"; }
      { mime = "application/x-7z-compressed"; command = "7z l %pistol-filename%"; }
      { mime = "application/x-msdownload"; command = "exiftool %pistol-filename%"; }
      { mime = "application/x-sharedlib"; command = "exiftool %pistol-filename%"; }
      { mime = "application/x-executable"; command = "exiftool %pistol-filename%"; }
      { mime = "application/x-font-ttf"; command = "exiftool %pistol-filename%"; }
      { mime = "application/x-font-woff"; command = "exiftool %pistol-filename%"; }
      { mime = "application/x-font-otf"; command = "exiftool %pistol-filename%"; }
      { mime = "application/vnd.ms-opentype"; command = "exiftool %pistol-filename%"; }
      { mime = "application/vnd.ms-fontobject"; command = "exiftool %pistol-filename%"; }
      { mime = "application/vnd.ms-excel"; command = "exiftool %pistol-filename%"; }
      { mime = "application/json"; command = "bat %pistol-filename%"; }
      { mime = "application/*"; command = "hexyl %pistol-filename%"; }
      { fpath = ".*.md$"; command = "sh: bat --paging=never --color=always %pistol-filename% | head -8"; }
    ];
  };

  programs.lf = {
    enable = true;
    previewer = {
      keybinding = "i";
      # source = pkgs.pistol;

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
      # shell = "zsh";
      # shellopts = "-c";
    };

    keybindings = {
      nd = "mkdir";
      nf = "mkfile";
      "<c-f>" = "search";
      "<space>" = "toggle";
      f = "$nvim $(fzf)";
      "<enter>" = "shell";
      o = "&mimeopen $f";
      O = "map O $mimeopen --ask $f";
    };

    commands = {
      f = "$nvim $(fzf)";
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

}
