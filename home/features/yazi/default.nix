{
  lib,
  pkgs,
  config,
  ...
}:

{
  home.packages = with pkgs; [
    exiftool
    ueberzugpp
    ffmpegthumbnailer
    poppler_utils
    mediainfo
    hexyl
    # xdragon
    ripdrag
  ];

  programs.yazi = {
    enable = true;
    package = pkgs.yazi;
    initLua = ./init.lua;
    plugins = {
      # fzfbm = ./plugins/fzfbm.yazi;
      chmod = ./plugins/chmod.yazi;
      full-border = ./plugins/full-border.yazi;
      glow = ./plugins/glow.yazi;
      hexyl = ./plugins/hexyl.yazi;
      lazygit = ./plugins/lazygit.yazi;
      max-preview = ./plugins/max-preview.yazi;
      mediainfo = ./plugins/mediainfo.yazi;
      smart-enter = ./plugins/smart-enter.yazi;
      smart-filter = ./plugins/smart-filter.yazi;
      smart-paste = ./plugins/smart-paste.yazi;
      starship = ./plugins/starship.yazi;
    };
    # enableNushellIntegration = true;
    # https://yazi-rs.github.io/docs/configuration/keymap
    # https://yazi-rs.github.io/docs/quick-start/#keybindings
    # https://github.com/sxyazi/yazi/blob/latest/yazi-config/preset/keymap.toml
    settings =
      let
          # TODO: better ref to nixvim?
          # editor = lib.getExe config.programs.nixvim.package;
          editor = "nvim";
          alacrity = lib.getExe pkgs.alacritty;
          mpv = lib.getExe pkgs.mpv;
          xdg-utils = "${pkgs.xdg-utils}/bin/xdg-open";
          thumbnailer = lib.getExe pkgs.ffmpegthumbnailer;
          pdftoppm = "${pkgs.poppler_utils}/bin/pdftoppm";
          dragon = lib.getExe pkgs.xdragon;
          ripdrag = lib.getExe pkgs.ripdrag;
          wl-copy = "${pkgs.wl-clipboard}/bin/wl-copy";
        in
    {
        log = {
          enabled = true;
        };
        input = {
          prepend_keymap = [
            # https://yazi-rs.github.io/docs/tips/#close-input-by-esc
            {
              on = ["<Esc>"];
              run = "close";
              desc = "Cancel input";
            }
            {
              on = ["i"];
              run = "insert";
              desc = "Enter insert mode";
            }
            {
              on = ["a"];
              run = "insert --prepend";
              desc = "Enter prepend mode";
            }
            {
              on = ["I"];
              run = ["move -999" "insert"];
              desc = "Move to the BOL; and enter insert mode";
            }
            {
              on = ["A"];
              run = ["move 999" "insert --prepend"];
              desc = "Move to the EOL; and enter prepend mode";
            }
            {
              on = ["v"];
              run = "visual";
              desc = "Enter visual mode";
            }
            {
              on = ["V"];
              run = ["move -999" "visual" "move 999"];
              desc = "Enter visual mode and select all";
            }
            {
              on   = ["F"];
              run  = "plugin smart-filter";
              desc = "Smart filter";
            }

          #   # Character-wise movement
          #   {
          #     on = ["h"];
          #     run = "move -1";
          #     desc = "Move back a character";
          #   }
          #   {
          #     on = ["l"];
          #     run = "move 1";
          #     desc = "Move forward a character";
          #   }
          #   {
          #     on = ["<Left>"];
          #     run = "move -1";
          #     desc = "Move back a character";
          #   }
          #   {
          #     on = ["<Right>"];
          #     run = "move 1";
          #     desc = "Move forward a character";
          #   }
          #   {
          #     on = ["<C-b>"];
          #     run = "move -1";
          #     desc = "Move back a character";
          #   }
          #   {
          #     on = ["<C-f>"];
          #     run = "move 1";
          #     desc = "Move forward a character";
          #   }
          #   # Word-wise movement
          #   {
          #     on = ["b"];
          #     run = "backward";
          #     desc = "Move back to the start of the current or previous word";
          #   }
          #   {
          #     on = ["w"];
          #     run = "forward";
          #     desc = "Move forward to the start of the next word";
          #   }
          #   {
          #     on = ["e"];
          #     run = "forward --end-of-word";
          #     desc = "Move forward to the end of the current or next word";
          #   }
          #   {
          #     on = ["<A-b>"];
          #     run = "backward";
          #     desc = "Move back to the start of the current or previous word";
          #   }
          #   {
          #     on = ["<A-f>"];
          #     run = "forward --end-of-word";
          #     desc = "Move forward to the end of the current or next word";
          #   }
          #   # Line-wise movement
          #   {
          #     on = ["<C-a>"];
          #     run = "move -999";
          #     desc = "Move to the BOL";
          #   }
          #   {
          #     on = ["<C-e>"];
          #     run = "move 999";
          #     desc = "Move to the EOL";
          #   }
          #   # Delete
          #   {
          #     on = ["<Backspace>"];
          #     run = "backspace";
          #     desc = "Delete the character before the cursor";
          #   }
          #   {
          #     on = ["<Delete>"];
          #     run = "backspace --under";
          #     desc = "Delete the character under the cursor";
          #   }
          #   {
          #     on = ["<C-h>"];
          #     run = "backspace";
          #     desc = "Delete the character before the cursor";
          #   }
          #   {
          #     on = ["<C-d>"];
          #     run = "backspace --under";
          #     desc = "Delete the character under the cursor";
          #   }
          #   # Kill
          #   {
          #     on = ["<C-u>"];
          #     run = "kill bol";
          #     desc = "Kill backwards to the BOL";
          #   }
          #   {
          #     on = ["<C-k>"];
          #     run = "kill eol";
          #     desc = "Kill forwards to the EOL";
          #   }
          #   {
          #     on = ["<C-w>"];
          #     run = "kill backward";
          #     desc = "Kill backwards to the start of the current word";
          #   }
          #   {
          #     on = ["<A-d>"];
          #     run = "kill forward";
          #     desc = "Kill forwards to the end of the current word";
          #   }
          #   # Cut/Yank/Paste
          #   {
          #     on = ["d"];
          #     run = "delete --cut";
          #     desc = "Cut the selected characters";
          #   }
          #   {
          #     on = ["D"];
          #     run = ["delete --cut" "move 999"];
          #     desc = "Cut until the EOL";
          #   }
          #   {
          #     on = ["c"];
          #     run = "delete --cut --insert";
          #     desc = "Cut the selected characters; and enter insert mode";
          #   }
          #   {
          #     on = ["C"];
          #     run = ["delete --cut --insert" "move 999"];
          #     desc = "Cut until the EOL; and enter insert mode";
          #   }
          #   {
          #     on = ["x"];
          #     run = ["delete --cut" "move 1 --in-operating"];
          #     desc = "Cut the current character";
          #   }
          #   {
          #     on = ["y"];
          #     run = "yank";
          #     desc = "Copy the selected characters";
          #   }
          #   {
          #     on = ["p"];
          #     run = "paste";
          #     desc = "Paste the copied characters after the cursor";
          #   }
          #   {
          #     on = ["P"];
          #     run = "paste --before";
          #     desc = "Paste the copied characters before the cursor";
          #   }
          #   # Undo/Redo
          #   {
          #     on = ["u"];
          #     run = "undo";
          #     desc = "Undo the last operation";
          #   }
          #   {
          #     on = ["<C-r>"];
          #     run = "redo";
          #     desc = "Redo the last operation";
          #   }
          ];
        };
        manager = {
          #  3-element array
          ratio = [
            1 # parent
            3 # current
            4 # preview
          ];
          sort_by = "natural";
          sort_sensitive = false;
          sort_reverse = false;
          sort_dir_first = true;
          sort_translit = true;
          show_hidden = true;
          show_symlink = false;
          prepend_keymap =
          [
            {
              on = ["q"];
              run = "close";
              desc = "Exit the process";
            }
            # https://yazi-rs.github.io/docs/tips/#dropping-to-shell
            {
              on = ["<C-s>"];
              run = ''shell $SHELL --block --confirm'';
              desc = "Open shell here";
            }
            {
              on = ["<C-t>"];
              run = "echo $SHELL";
              desc = "Open shell here";
            }
            # {
            #   on  = ["<C-n>"];
            #   run = ''
            #     shell '${dragon} -x -i -T "$1"' --confirm
            #   '';
            # }

            # https://yazi-rs.github.io/docs/tips/#drag-and-drop
            {
              on = ["<C-n>"];
              run = ''
                shell '${ripdrag} "$@" -x 2>/dev/null &' --confirm
              '';
            }
            # https://yazi-rs.github.io/docs/tips/#smart-enter

            {
              on   = ["l"];
              run  = "plugin --sync smart-enter";
              desc = "Enter the child directory, or open the file";
            }
            {
              on   = ["p"];
              run  = "plugin --sync smart-paste";
              desc = "Paste into the hovered directory or CWD";
            }
            {
              on = ["<Right>"];
              run = "plugin --sync smart-enter";
              desc = "Enter the child directory or open the file";
            }
            # https://yazi-rs.github.io/docs/tips/#selected-files-to-clipboard
            {
              on = ["y"];
              run = [
                "yank"
                ''
                  shell --confirm 'for path in "$@"; do echo "file://$path"; done | ${wl-copy} -t text/uri-list'
                ''
              ];
            }
            {
              on   = ["T"];
              run  = "plugin --sync max-preview";
              desc = "Maximize or restore preview";
            }
            # https://yazi-rs.github.io/docs/tips/#navigation-wraparound
            {
              on = ["h"];
              run = "plugin --sync arrow --args=-1";
            }
            {
              on = ["<Up>"];
              run = "plugin --sync arrow --args=-1";
            }
            {
              on = ["l"];
              run = "plugin --sync arrow --args=1";
            }
            {
              on = ["<Down>"];
              run = "plugin --sync arrow --args=1";
            }
            {
              on = ["J"];
              run = "plugin --sync arrow --args=-5";
            }
            {
              on = ["K"];
              run = "plugin --sync arrow --args=5";
            }
            # skip confirm on delete
            {
              on = ["d"];
              run = "remove --force";
              desc = "Move the files to the trash";
            }
            {
              on = ["h"];
              run = "leave";
              desc = "Go back to the parent directory";
            }
            {
              on = ["<Left>"];
              run = "leave";
              desc = "Go back to the parent directory";
            }
            # { on = [ l ]; run = "enter"; desc = "Enter the child directory"; }
            {
              on = ["H"];
              run = "back";
              desc = "Go back to the previous directory";
            }
            {
              on = ["L"];
              run = "forward";
              desc = "Go forward to the next directory";
            }
            # {
            #   on = ["<A-${k}>"];
            #   run = "seek -5";
            #   desc = "Seek up 5 units in the preview";
            # }
            # {
            #   on = ["<A-${j}>"];
            #   run = "seek 5";
            #   desc = "Seek down 5 units in the preview";
            # }
            {
              on = ["o"];
              run = "open";
              desc = "Open the selected files";
            }
            {
              on = ["O"];
              run = "open --interactive";
              desc = "Open the selected files interactively";
            }
            # {
            #   on = ["y"];
            #   run = "yank";
            #   desc = "Copy the selected files";
            # }
            {
              on = ["Y"];
              run = "unyank";
              desc = "Cancel the yank status of files";
            }
            # {
            #   on = ["<C-s>"];
            #   run = "search none";
            #   desc = "Cancel the ongoing search";
            # }
            {
              on = ["<PageUp>"];
              run = "arrow -100%";
              desc = "Move cursor up one page";
            }
            {
              on = ["<PageDown>"];
              run = "arrow 100%";
              desc = "Move cursor down one page";
            }
            # Linemode
            {
              on = ["m" "n"];
              run = "linemode none";
              desc = "Set linemode to none";
            }

            # Copy
            {
              on = ["c" "n"];
              run = "copy name_without_ext";
              desc = "Copy the name of the file without the extension";
            }

            # Find
            {
              on = ["n"];
              run = "find_arrow";
              desc = "Go to next found file";
            }
            {
              on = ["N"];
              run = "find_arrow --previous";
              desc = "Go to previous found file";
            }

            # lazyfetchGit
            {
              on = ["g" "i"];
              run = "plugin lazygit";
              desc = "run lazygit";
            }
            # fzf bookmark
            # {
            #   on = [ "u" "a"];
            #   run = "plugin fzfbm --args=save";
            #   desc = "Add bookmark";
            # }

            # {
            #   on = [ "u" "g"];
            #   run = "plugin fzfbm --args=jump_by_key";
            #   desc = "Jump bookmark by key";
            # }

            # {
            #   on = [ "u" "G"];
            #   run = "plugin fzfbm --args=jump_by_fzf";
            #   desc = "Jump bookmark by fzf";
            # }
            # {
            #   on = [ "u" "d"];
            #   run = "plugin fzfbm --args=delete_by_key";
            #   desc = "Delete bookmark by key";
            # }

            # {
            #   on = [ "u" "D"];
            #   run = "plugin fzfbm --args=delete_by_fzf";
            #   desc = "Delete bookmark by fzf";
            # }

            # {
            #   on = [ "u" "A"];
            #   run = "plugin fzfbm --args=delete_all";
            #   desc = "Delete all bookmarks";
            # }

            # {
            #   on = [ "u" "r"];
            #   run = "plugin fzfbm --args=rename_by_key";
            #   desc = "Rename bookmark by key";
            # }

            # {
            #   on = [ "u" "R"];
            #   run = "plugin fzfbm --args=rename_by_fzf";
            #   desc = "Rename bookmark by fzf";
            # }


          ];
        };
        preview = {
          tab_size = 2;
          max_height = 1200;
          max_width = 800;
          cache_dir = "${config.xdg.cacheHome}/yazi";
          # image_filter = "lanczos3";
          # image_quality = 90;
          # sixel_fraction = 15;
          # https://github.com/jstkdng/ueberzugpp/issues/122
          ueberzug_scale = 1;
          ueberzug_offset = [(0.5) (0.5) (-0.5) (-0.5)];
        };
        plugin = {
          prepend_previewers = [
            {
              mime = "application/epub";
              run = "pdf";
            }
            {
              mime = "application/pdf";
              run = "pdf";
            }
            # markdown files to glow
            {
              name = "*.md";
              run = "glow";
            }
            {
              mime = "text/markdown";
              run = "glow";
            }
            {
              mime = "{image,audio,video}/*";
              run = "mediainfo";
            }
            {
              mime = "application/x-subrip";
              run = "mediainfo";
            }
            {
              mime = "application/octet-stream";
              run = "hexyl";
            }
          ];
        };
        opener ={
          edit-text = [
            {
              run = ''${editor} "$@"'';
              block = true;
            }
          ];
          play = [
            {
              run = ''${mpv} "$@"'';
              orphan = true;
            }
          ];
          terminal = [
            {
              run = ''${alacrity} -e "$0"'';
              orphan = true;
            }
          ];
          open = [
            {
              run = ''${xdg-utils} "$@"'';
              orphan = true;
            }
          ];
        };
        open.rules = [
          {
            mime = "text/*";
            use = ["edit-text"];
          }
          {
            mime = "application/json";
            use = ["edit-text"];
          }
          {
            mime = "inode/directory";
            use = ["terminal"];
          }
          {
            mime = "*";
            use = ["open"];
          }
          {
            name = "*";
            use = ["open"];
          }
        ];
        # tasks = {
        #   prepend_keymap = [
        #     {
        #       on = ["k"];
        #       run = "arrow -1";
        #       desc = "Move cursor up";
        #     }
        #     {
        #       on = ["j"];
        #       run = "arrow 1";
        #       desc = "Move cursor down";
        #     }
        #   ];
        # };
        # select = {
        #   prepend_keymap = [
        #     {
        #       on = ["k"];
        #       run = "arrow -1";
        #       desc = "Move cursor up";
        #     }
        #     {
        #       on = ["j"];
        #       run = "arrow 1";
        #       desc = "Move cursor down";
        #     }
        #     {
        #       on = ["K"];
        #       run = "arrow -5";
        #       desc = "Move cursor up 5 lines";
        #     }
        #     {
        #       on = ["J"];
        #       run = "arrow 5";
        #       desc = "Move cursor down 5 lines";
        #     }
        #   ];
        # };
        # completion = {
        #   prepend_keymap = [
        #     {
        #       on = ["<A-p>"];
        #       run = "arrow -1";
        #       desc = "Move cursor up";
        #     }
        #     {
        #       on = ["<A-n>"];
        #       run = "arrow 1";
        #       desc = "Move cursor down";
        #     }
        #     {
        #       on = ["<C-p>"];
        #       run = "arrow -1";
        #       desc = "Move cursor up";
        #     }
        #     {
        #       on = ["<C-n>"];
        #       run = "arrow 1";
        #       desc = "Move cursor down";
        #     }
        #   ];
        # };
        # help = {
        #   prepend_keymap = [
        #     {
        #       on = ["k"];
        #       run = "arrow -1";
        #       desc = "Move cursor up";
        #     }
        #     {
        #       on = ["j"];
        #       run = "arrow 1";
        #       desc = "Move cursor down";
        #     }
        #     {
        #       on = ["K"];
        #       run = "arrow -5";
        #       desc = "Move cursor up 5 lines";
        #     }
        #     {
        #       on = ["J"];
        #       run = "arrow 5";
        #       desc = "Move cursor down 5 lines";
        #     }
        #   ];
        # };
    };
  };
}