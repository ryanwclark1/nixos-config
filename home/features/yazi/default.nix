{
  lib,
  pkgs,
  config,
  ...
}:

{
  imports = [
    ./flavors/theme.yazi/flavor.toml.nix
    ./flavors/theme.yazi/tmtheme.xml.nix
  ];

  home.file.".config/yazi/flavors/theme.yazi/README.md" = {
    source = ./flavors/theme.yazi/README.md;
    executable = false;
  };

  home.file.".config/yazi/flavors/theme.yazi/preview.png" = {
    source = ./flavors/theme.yazi/preview.png;
    executable = false;
  };

  home.file.".config/yazi/flavors/theme.yazi/LICENSE" = {
    source = ./flavors/theme.yazi/LICENSE;
    executable = false;
  };

  home.file.".config/yazi/keymap.toml" = {
    source = ./keymap.toml;
    executable = false;
  };

  home.file.".config/yazi/yazi.toml" = {
    source = ./yazi.toml;
    executable = false;
  };

  home.packages = with pkgs; [
    # Core file analysis
    file              # File type detection (MIME types)
    exiftool          # Metadata extraction

    # Image/Video processing
    ueberzugpp        # Yazi image display
    ffmpegthumbnailer # Legacy video thumbnails (can be removed eventually)
    ffmpeg           # Modern video thumbnail generation
    chafa            # Terminal image display
    librsvg          # SVG handling

    # Document processing
    poppler_utils    # PDF text extraction (pdftotext, pdfinfo)
    epub2txt2        # EPUB text extraction
    xlsx2csv         # Excel/spreadsheet conversion
    odt2txt          # OpenDocument text extraction

    # Archive handling
    atool            # Universal archive tool
    p7zip            # 7z archive support

    # Data processing
    mediainfo        # Audio/video metadata
    hexyl            # Binary file viewer
    miller           # CSV/data processing (mlr)
    jq               # JSON formatting and processing

    # Web content
    elinks           # HTML text rendering

    # Additional document tools
    glow             # Markdown rendering
    pandoc           # Document conversion

    # Archive utilities
    unzip            # ZIP extraction
    unar             # Archive listing (provides lsar command)

    # Development tools
    bat              # Syntax highlighting (should be available via programs.bat)

    # Utilities
    ripdrag          # Drag and drop support
    sqlite           # Database inspection
    transmission_4     # Torrent info (transmission-show)
  ];

  programs.yazi = {
    enable = true;
    package = pkgs.yazi;
    initLua = ./main.lua;
    shellWrapperName = "yy";
    enableBashIntegration = lib.mkIf config.programs.bash.enable true;
    enableFishIntegration = lib.mkIf config.programs.fish.enable true;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
    enableNushellIntegration = lib.mkIf config.programs.nushell.enable true;
    plugins = {
      arrow = ./plugins/arrow.yazi;
      chmod = pkgs.yaziPlugins.chmod;
      excel = ./plugins/excel.yazi;
      eza-preview = ./plugins/eza-preview.yazi;
      folder-rules = ./plugins/folder-rules.yazi;
      fzfbm = ./plugins/fzfbm.yazi;
      glow = pkgs.yaziPlugins.glow;
      hexyl = ./plugins/hexyl.yazi;
      lazygit = pkgs.yaziPlugins.lazygit;
      max-preview = ./plugins/max-preview.yazi;
      mediainfo = pkgs.yaziPlugins.mediainfo;
      ouch = pkgs.yaziPlugins.ouch;
      parent-arrow = ./plugins/parent-arrow.yazi;
      preview = ./plugins/preview.yazi;
      smart-enter = pkgs.yaziPlugins.smart-enter;
      smart-filter = pkgs.yaziPlugins.smart-filter;
      smart-paste = pkgs.yaziPlugins.smart-paste;
      yatline = pkgs.yaziPlugins.yatline;
      yatline-catppuccin = pkgs.yaziPlugins.yatline-catppuccin;
    };
    theme = {
      flavor = {
        dark = "theme";
        light = "theme";
      };
    };
    # keymap = {
    #   manager.prepend_keymap = [
    #     # https://yazi-rs.github.io/docs/tips/#dropping-to-shell
    #     {
    #       on   = "!";
    #       run  = ''shell "$SHELL" --block --confirm'';
    #       desc = "Open shell here";
    #     }
    #     # Smart enter: enter for directory, open for file
    #     {
    #       on   = ["l"];
    #       run  = "plugin smart-enter";
    #       desc = "Enter the child directory, or open the file";
    #     }
    #     #  Smart paste: paste files without entering the directory
    #     {
    #       on   = ["p"];
    #       run  = "plugin smart-paste";
    #       desc = "Paste into the hovered directory or CWD";
    #     }
    #     # Copy selected files to the system clipboard while yanking
    #     {
    #       on = ["y"];
    #       run = [
    #         ''
    #           shell 'for path in "$@"; do echo "file://$path"; done | wl-copy -t text/uri-list' --confirm
    #         ''
    #         "yank"
    #       ];
    #       desc = "Copy the selected files to the system clipboard while yanking";
    #     }
    #     # https://yazi-rs.github.io/docs/tips/#drag-and-drop
    #     {
    #       on = ["<C-n>"];
    #       run = [''
    #         shell 'ripdrag "$@" -x 2>/dev/null &' --confirm
    #       ''
    #       ''echo "Control + N Pressed"
    #       ''
    #       ];
    #       desc = "Drag and drop via ripdrag";
    #     }
    #     # Maximize preview pane
    #     # https://github.com/yazi-rs/plugins/tree/main/max-preview.yazi
    #     {
    #       on   = ["T"];
    #       run  = "plugin max-preview";
    #       desc = "Maximize or restore preview pane";
    #     }
    #     # https://yazi-rs.github.io/docs/tips/#navigation-wraparound
    #     {
    #       on = ["k"];
    #       run = "plugin arrow --args=-1";
    #       desc = "Move the cursor down";
    #     }
    #     {
    #       on = ["j"];
    #       run = "plugin arrow --args=1";
    #       desc = "Move the cursor up";
    #     }
    #     # cd back to the root of the current Git repository
    #     {
    #       on = ["g" "r"];
    #       run = ''
    #         shell 'ya emit cd "$(git rev-parse --show-toplevel)"' --confirm
    #         '';
    #       desc = "Go to the root of the current Git repository";
    #     }
    #     # Runs lazygit
    #     {
    #       on   = ["g" "i"];
    #       run  = ''plugin lazygit'';
    #       desc = "run lazygit";
    #     }
    #     # preview directories using eza, can be switched between list and tree modes.
    #     {
    #       on = ["E"];
    #       run = "plugin eza-preview";
    #       desc = "Toggle tree/list dir preview";
    #     }
    #     {
    #       on = ["c,m"];
    #       run = "plugin chmod";
    #       desc = "Chmod the selected files";
    #     }
    #     # Compress files
    #     {
    #       on = ["C"];
    #       run = "plugin ouch --args=zip";
    #       desc = "Compress with ouch";
    #     }
    #   ];
    #   manager.keymap = [
    #     {
    #       on = "<Esc>";
    #       run = "escape";
    #       desc = "Exit visual mode, clear selected, or cancel search";
    #     }
    #     {
    #       on = "<C-[>";
    #       run = "escape";
    #       desc = "Exit visual mode, clear selected, or cancel search";
    #     }
    #     {
    #       on = "q";
    #       run = "quit";
    #       desc = "Exit the process";
    #     }
    #     {
    #       on = "Q";
    #       run = "quit --no-cwd-file";
    #       desc = "Exit the process without writing cwd-file";
    #     }
    #     {
    #       on = "<C-c>";
    #       run = "close";
    #       desc = "Close the current tab, or quit if it is last tab";
    #     }
    #     {
    #       on = "<C-z>";
    #       run = "suspend";
    #       desc = "Suspend the process";
    #     }
    #     # Hopping
    #     {
    #       on = "k";
    #       run = "arrow -1";
    #       desc = "Move cursor up";
    #     }
    #     {
    #       on = "j";
    #       run = "arrow 1";
    #       desc = "Move cursor down";
    #     }
    #     {
    #       on = "<Up>";
    #       run = "arrow -1";
    #       desc = "Move cursor up";
    #     }
    #     {
    #       on = "<Down>";
    #       run = "arrow 1";
    #       desc = "Move cursor down";
    #     }
    #     {
    #       on = "<C-u>";
    #       run = "arrow -50%";
    #       desc = "Move cursor up half page";
    #     }
    #     {
    #       on = "<C-d>";
    #       run = "arrow 50%";
    #       desc = "Move cursor down half page";
    #     }
    #     {
    #       on = "<C-b>";
    #       run = "arrow -100%";
    #       desc = "Move cursor up one page";
    #     }
    #     {
    #       on = "<C-f>";
    #       run = "arrow 100%";
    #       desc = "Move cursor down one page";
    #     }
    #     {
    #       on = "<S-PageUp>";
    #       run = "arrow -50%";
    #       desc = "Move cursor up half page";
    #     }
    #     {
    #       on = "<S-PageDown>";
    #       run = "arrow 50%";
    #       desc = "Move cursor down half page";
    #     }
    #     {
    #       on = "<PageUp>";
    #       run = "arrow -100%";
    #       desc = "Move cursor up one page";
    #     }
    #     {
    #       on = "<PageDown>";
    #       run = "arrow 100%";
    #       desc = "Move cursor down one page";
    #     }
    #     {
    #       on = [ "g" "g" ];
    #       run = "arrow top";
    #       desc = "Move cursor to the top";
    #     }
    #     {
    #       on = "G";
    #       run = "arrow bottom";
    #       desc = "Move cursor to the bottom";
    #     }
    #     # Navigation
    #     {
    #       on = "h";
    #       run = "leave";
    #       desc = "Go back to the parent directory";
    #     }
    #     {
    #       on = "l";
    #       run = "enter";
    #       desc = "Enter the child directory";
    #     }
    #     {
    #       on = "<Left>";
    #       run = "leave";
    #       desc = "Go back to the parent directory";
    #     }
    #     {
    #       on = "<Right>";
    #       run = "enter";
    #       desc = "Enter the child directory";
    #     }
    #     {
    #       on = "H";
    #       run = "back";
    #       desc = "Go back to the previous directory";
    #     }
    #     {
    #       on = "L";
    #       run = "forward";
    #       desc = "Go forward to the next directory";
    #     }
    #     # Seeking
    #     {
    #       on = "K";
    #       run = "seek -5";
    #       desc = "Seek up 5 units in the preview";
    #     }
    #     {
    #       on = "J";
    #       run = "seek 5";
    #       desc = "Seek down 5 units in the preview";
    #     }
    #     # Selection
    #     {
    #       on = "<Space>";
    #       run = [ "toggle --state=none" "arrow 1" ];
    #       desc = "Toggle the current selection state";
    #     }
    #     {
    #       on = "v";
    #       run = "visual_mode";
    #       desc = "Enter visual mode (selection mode)";
    #     }
    #     {
    #       on = "V";
    #       run = "visual_mode --unset";
    #       desc = "Enter visual mode (unset mode)";
    #     }
    #     {
    #       on = "<C-a>";
    #       run = "toggle_all --state=true";
    #       desc = "Select all files";
    #     }
    #     {
    #       on = "<C-r>";
    #       run = "toggle_all --state=none";
    #       desc = "Inverse selection of all files";
    #     }
    #     # Operation
    #     {
    #       on = "o";
    #       run = "open";
    #       desc = "Open selected files";
    #     }
    #     {
    #       on = "O";
    #       run = "open --interactive";
    #       desc = "Open selected files interactively";
    #     }
    #     {
    #       on = "<Enter>";
    #       run = "open";
    #       desc = "Open selected files";
    #     }
    #     {
    #       on = "<S-Enter>";
    #       run = "open --interactive";
    #       desc = "Open selected files interactively";
    #     }
    #     {
    #       on = "y";
    #       run = "yank";
    #       desc = "Yank selected files (copy)";
    #     }
    #     {
    #       on = "x";
    #       run = "yank --cut";
    #       desc = "Yank selected files (cut)";
    #     }
    #     {
    #       on = "p";
    #       run = "paste";
    #       desc = "Paste yanked files";
    #     }
    #     {
    #       on = "P";
    #       run = "paste --force";
    #       desc = "Paste yanked files (overwrite if the destination exists)";
    #     }
    #     {
    #       on = "-";
    #       run = "link";
    #       desc = "Symlink the absolute path of yanked files";
    #     }
    #     {
    #       on = "_";
    #       run = "link --relative";
    #       desc = "Symlink the relative path of yanked files";
    #     }
    #     {
    #       on = "<C-->";
    #       run = "hardlink";
    #       desc = "Hardlink yanked files";
    #     }
    #     {
    #       on = "Y";
    #       run = "unyank";
    #       desc = "Cancel the yank status";
    #     }
    #     {
    #       on = "X";
    #       run = "unyank";
    #       desc = "Cancel the yank status";
    #     }
    #     {
    #       on = "d";
    #       run = "remove";
    #       desc = "Trash selected files";
    #     }
    #     {
    #       on = "D";
    #       run = "remove --permanently";
    #       desc = "Permanently delete selected files";
    #     }
    #     {
    #       on = "a";
    #       run = "create";
    #       desc = "Create a file (ends with / for directories)";
    #     }
    #     {
    #       on = "r";
    #       run = "rename --cursor=before_ext";
    #       desc = "Rename selected file(s)";
    #     }
    #     {
    #       on = ";";
    #       run = "shell --interactive";
    #       desc = "Run a shell command";
    #     }
    #     {
    #       on = ":";
    #       run = "shell --block --interactive";
    #       desc = "Run a shell command (block until finishes)";
    #     }
    #     {
    #       on = ".";
    #       run = "hidden toggle";
    #       desc = "Toggle the visibility of hidden files";
    #     }
    #     {
    #       on = "s";
    #       run = "search fd";
    #       desc = "Search files by name using fd";
    #     }
    #     {
    #       on = "S";
    #       run = "search rg";
    #       desc = "Search files by content using ripgrep";
    #     }
    #     {
    #       on = "<C-s>";
    #       run = "escape --search";
    #       desc = "Cancel the ongoing search";
    #     }
    #     {
    #       on = "z";
    #       run = "plugin zoxide";
    #       desc = "Jump to a directory using zoxide";
    #     }
    #     {
    #       on = "Z";
    #       run = "plugin fzf";
    #       desc = "Jump to a directory or reveal a file using fzf";
    #     }
    #     # Linemode
    #     {
    #       on = [ "m" "s" ];
    #       run = "linemode size";
    #       desc = "Set linemode to size";
    #     }
    #     {
    #       on = [ "m" "p" ];
    #       run = "linemode permissions";
    #       desc = "Set linemode to permissions";
    #     }
    #     {
    #       on = [ "m" "c" ];
    #       run = "linemode ctime";
    #       desc = "Set linemode to ctime";
    #     }
    #     {
    #       on = [ "m" "m" ];
    #       run = "linemode mtime";
    #       desc = "Set linemode to mtime";
    #     }
    #     {
    #       on = [ "m" "o" ];
    #       run = "linemode owner";
    #       desc = "Set linemode to owner";
    #     }
    #     {
    #       on = [ "m" "n" ];
    #       run = "linemode none";
    #       desc = "Set linemode to none";
    #     }
    #     # Copy
    #     {
    #       on = [ "c" "c" ];
    #       run = "copy path";
    #       desc = "Copy the file path";
    #     }
    #     {
    #       on = [ "c" "d" ];
    #       run = "copy dirname";
    #       desc = "Copy the directory path";
    #     }
    #     {
    #       on = [ "c" "f" ];
    #       run = "copy filename";
    #       desc = "Copy the filename";
    #     }
    #     {
    #       on = [ "c" "n" ];
    #       run = "copy name_without_ext";
    #       desc = "Copy the filename without extension";
    #     }
    #     # Filter
    #     {
    #       on = "f";
    #       run = "filter --smart";
    #       desc = "Filter files";
    #     }
    #     # Find
    #     {
    #       on = "/";
    #       run = "find --smart";
    #       desc = "Find next file";
    #     }
    #     {
    #       on = "?";
    #       run = "find --previous --smart";
    #       desc = "Find previous file";
    #     }
    #     {
    #       on = "n";
    #       run = "find_arrow";
    #       desc = "Go to the next found";
    #     }
    #     {
    #       on = "N";
    #       run = "find_arrow --previous";
    #       desc = "Go to the previous found";
    #     }
    #     # Sorting
    #     {
    #       on = [ "," "m" ];
    #       run = [ "sort modified --reverse=no" "linemode mtime" ];
    #       desc = "Sort by modified time";
    #     }
    #     {
    #       on = [ "," "M" ];
    #       run = [ "sort modified --reverse" "linemode mtime" ];
    #       desc = "Sort by modified time (reverse)";
    #     }
    #     {
    #       on = [ "," "c" ];
    #       run = [ "sort created --reverse=no" "linemode ctime" ];
    #       desc = "Sort by created time";
    #     }
    #     {
    #       on = [ "," "C" ];
    #       run = [ "sort created --reverse" "linemode ctime" ];
    #       desc = "Sort by created time (reverse)";
    #     }
    #     {
    #       on = [ "," "e" ];
    #       run = "sort extension --reverse=no";
    #       desc = "Sort by extension";
    #     }
    #     {
    #       on = [ "," "E" ];
    #       run = "sort extension --reverse";
    #       desc = "Sort by extension (reverse)";
    #     }
    #     {
    #       on = [ "," "a" ];
    #       run = "sort alphabetical --reverse=no";
    #       desc = "Sort alphabetically";
    #     }
    #     {
    #       on = [ "," "A" ];
    #       run = "sort alphabetical --reverse";
    #       desc = "Sort alphabetically (reverse)";
    #     }
    #     {
    #       on = [ "," "n" ];
    #       run = "sort natural --reverse=no";
    #       desc = "Sort naturally";
    #     }
    #     {
    #       on = [ "," "N" ];
    #       run = "sort natural --reverse";
    #       desc = "Sort naturally (reverse)";
    #     }
    #     {
    #       on = [ "," "s" ];
    #       run = [ "sort size --reverse=no" "linemode size" ];
    #       desc = "Sort by size";
    #     }
    #     {
    #       on = [ "," "S" ];
    #       run = [ "sort size --reverse" "linemode size" ];
    #       desc = "Sort by size (reverse)";
    #     }
    #     {
    #       on = [ "," "r" ];
    #       run = "sort random --reverse=no";
    #       desc = "Sort randomly";
    #     }
    #     # Goto
    #     {
    #       on = [ "g" "h" ];
    #       run = "cd ~";
    #       desc = "Go to the home directory";
    #     }
    #     {
    #       on = [ "g" "c" ];
    #       run = "cd ~/.config";
    #       desc = "Go to the config directory";
    #     }
    #     {
    #       on = [ "g" "d" ];
    #       run = "cd ~/Downloads";
    #       desc = "Go to the downloads directory";
    #     }
    #     {
    #       on = [ "g" "<Space>" ];
    #       run = "cd --interactive";
    #       desc = "Go to a directory interactively";
    #     }
    #     # Tabs
    #     {
    #       on = "t";
    #       run = "tab_create --current";
    #       desc = "Create a new tab with CWD";
    #     }
    #     {
    #       on = "1";
    #       run = "tab_switch 0";
    #       desc = "Switch to the first tab";
    #     }
    #     {
    #       on = "2";
    #       run = "tab_switch 1";
    #       desc = "Switch to the second tab";
    #     }
    #     {
    #       on = "3";
    #       run = "tab_switch 2";
    #       desc = "Switch to the third tab";
    #     }
    #     {
    #       on = "4";
    #       run = "tab_switch 3";
    #       desc = "Switch to the fourth tab";
    #     }
    #     {
    #       on = "5";
    #       run = "tab_switch 4";
    #       desc = "Switch to the fifth tab";
    #     }
    #     {
    #       on = "6";
    #       run = "tab_switch 5";
    #       desc = "Switch to the sixth tab";
    #     }
    #     {
    #       on = "7";
    #       run = "tab_switch 6";
    #       desc = "Switch to the seventh tab";
    #     }
    #     {
    #       on = "8";
    #       run = "tab_switch 7";
    #       desc = "Switch to the eighth tab";
    #     }
    #     {
    #       on = "9";
    #       run = "tab_switch 8";
    #       desc = "Switch to the ninth tab";
    #     }
    #     {
    #       on = "[";
    #       run = "tab_switch -1 --relative";
    #       desc = "Switch to the previous tab";
    #     }
    #     {
    #       on = "]";
    #       run = "tab_switch 1 --relative";
    #       desc = "Switch to the next tab";
    #     }
    #     {
    #       on = "{";
    #       run = "tab_swap -1";
    #       desc = "Swap current tab with previous tab";
    #     }
    #     {
    #       on = "}";
    #       run = "tab_swap 1";
    #       desc = "Swap current tab with next tab";
    #     }
    #     # Tasks
    #     {
    #       on = "w";
    #       run = "tasks_show";
    #       desc = "Show task manager";
    #     }
    #     # Help
    #     {
    #       on = "~";
    #       run = "help";
    #       desc = "Open help";
    #     }
    #     {
    #       on = "<F1>";
    #       run = "help";
    #       desc = "Open help";
    #     }
    #   ];
    #   tasks.keymap = [
    #     {
    #       on = "<Esc>";
    #       run = "close";
    #       desc = "Close task manager";
    #     }
    #     {
    #       on = "<C-[>";
    #       run = "close";
    #       desc = "Close task manager";
    #     }
    #     {
    #       on = "<C-c>";
    #       run = "close";
    #       desc = "Close task manager";
    #     }
    #     {
    #       on = "w";
    #       run = "close";
    #       desc = "Close task manager";
    #     }
    #     {
    #       on = "k";
    #       run = "arrow -1";
    #       desc = "Move cursor up";
    #     }
    #     {
    #       on = "j";
    #       run = "arrow 1";
    #       desc = "Move cursor down";
    #     }
    #     {
    #       on = "<Up>";
    #       run = "arrow -1";
    #       desc = "Move cursor up";
    #     }
    #     {
    #       on = "<Down>";
    #       run = "arrow 1";
    #       desc = "Move cursor down";
    #     }
    #     {
    #       on = "<Enter>";
    #       run = "inspect";
    #       desc = "Inspect the task";
    #     }
    #     {
    #       on = "x";
    #       run = "cancel";
    #       desc = "Cancel the task";
    #     }
    #     # Help
    #     {
    #       on = "~";
    #       run = "help";
    #       desc = "Open help";
    #     }
    #     {
    #       on = "<F1>";
    #       run = "help";
    #       desc = "Open help";
    #     }
    #   ];
    #   select.keymap = [
    #     {
    #       on = "<Esc>";
    #       run = "close";
    #       desc = "Cancel selection";
    #     }
    #     {
    #       on = "<C-[>";
    #       run = "close";
    #       desc = "Cancel selection";
    #     }
    #     {
    #       on = "<C-c>";
    #       run = "close";
    #       desc = "Cancel selection";
    #     }
    #     {
    #       on = "<Enter>";
    #       run = "close --submit";
    #       desc = "Submit the selection";
    #     }
    #     {
    #       on = "k";
    #       run = "arrow -1";
    #       desc = "Move cursor up";
    #     }
    #     {
    #       on = "j";
    #       run = "arrow 1";
    #       desc = "Move cursor down";
    #     }
    #     {
    #       on = "<Up>";
    #       run = "arrow -1";
    #       desc = "Move cursor up";
    #     }
    #     {
    #       on = "<Down>";
    #       run = "arrow 1";
    #       desc = "Move cursor down";
    #     }
    #     # Help
    #     {
    #       on = "~";
    #       run = "help";
    #       desc = "Open help";
    #     }
    #     {
    #       on = "<F1>";
    #       run = "help";
    #       desc = "Open help";
    #     }
    #   ];
    #   input.keymap = [
    #     {
    #       on = "<C-c>";
    #       run = "close";
    #       desc = "Cancel input";
    #     }
    #     {
    #       on = "<Enter>";
    #       run = "close --submit";
    #       desc = "Submit input";
    #     }
    #     {
    #       on = "<Esc>";
    #       run = "escape";
    #       desc = "Go back the normal mode, or cancel input";
    #     }
    #     {
    #       on = "<C-[>";
    #       run = "escape";
    #       desc = "Go back the normal mode, or cancel input";
    #     }
    #     # Mode
    #     {
    #       on = "i";
    #       run = "insert";
    #       desc = "Enter insert mode";
    #     }
    #     {
    #       on = "a";
    #       run = "insert --append";
    #       desc = "Enter append mode";
    #     }
    #     {
    #       on = "I";
    #       run = [ "move -999" "insert" ];
    #       desc = "Move to the BOL, and enter insert mode";
    #     }
    #     {
    #       on = "A";
    #       run = [ "move 999" "insert --append" ];
    #       desc = "Move to the EOL, and enter append mode";
    #     }
    #     {
    #       on = "v";
    #       run = "visual";
    #       desc = "Enter visual mode";
    #     }
    #     {
    #       on = "V";
    #       run = [ "move -999" "visual" "move 999" ];
    #       desc = "Enter visual mode and select all";
    #     }
    #     # Character-wise movement
    #     {
    #       on = "h";
    #       run = "move -1";
    #       desc = "Move back a character";
    #     }
    #     {
    #       on = "l";
    #       run = "move 1";
    #       desc = "Move forward a character";
    #     }
    #     {
    #       on = "<Left>";
    #       run = "move -1";
    #       desc = "Move back a character";
    #     }
    #     {
    #       on = "<Right>";
    #       run = "move 1";
    #       desc = "Move forward a character";
    #     }
    #     {
    #       on = "<C-b>";
    #       run = "move -1";
    #       desc = "Move back a character";
    #     }
    #     {
    #       on = "<C-f>";
    #       run = "move 1";
    #       desc = "Move forward a character";
    #     }
    #     # Word-wise movement
    #     {
    #       on = "b";
    #       run = "backward";
    #       desc = "Move back to the start of the current or previous word";
    #     }
    #     {
    #       on = "w";
    #       run = "forward";
    #       desc = "Move forward to the start of the next word";
    #     }
    #     {
    #       on = "e";
    #       run = "forward --end-of-word";
    #       desc = "Move forward to the end of the current or next word";
    #     }
    #     {
    #       on = "<A-b>";
    #       run = "backward";
    #       desc = "Move back to the start of the current or previous word";
    #     }
    #     {
    #       on = "<A-f>";
    #       run = "forward --end-of-word";
    #       desc = "Move forward to the end of the current or next word";
    #     }
    #     # Line-wise movement
    #     {
    #       on = "0";
    #       run = "move -999";
    #       desc = "Move to the BOL";
    #     }
    #     {
    #       on = "$";
    #       run = "move 999";
    #       desc = "Move to the EOL";
    #     }
    #     {
    #       on = "<C-a>";
    #       run = "move -999";
    #       desc = "Move to the BOL";
    #     }
    #     {
    #       on = "<C-e>";
    #       run = "move 999";
    #       desc = "Move to the EOL";
    #     }
    #     {
    #       on = "<Home>";
    #       run = "move -999";
    #       desc = "Move to the BOL";
    #     }
    #     {
    #       on = "<End>";
    #       run = "move 999";
    #       desc = "Move to the EOL";
    #     }
    #     # Delete
    #     {
    #       on = "<Backspace>";
    #       run = "backspace";
    #       desc = "Delete the character before the cursor";
    #     }
    #     {
    #       on = "<Delete>";
    #       run = "backspace --under";
    #       desc = "Delete the character under the cursor";
    #     }
    #     {
    #       on = "<C-h>";
    #       run = "backspace";
    #       desc = "Delete the character before the cursor";
    #     }
    #     {
    #       on = "<C-d>";
    #       run = "backspace --under";
    #       desc = "Delete the character under the cursor";
    #     }
    #     # Kill
    #     {
    #       on = "<C-u>";
    #       run = "kill bol";
    #       desc = "Kill backwards to the BOL";
    #     }
    #     {
    #       on = "<C-k>";
    #       run = "kill eol";
    #       desc = "Kill forwards to the EOL";
    #     }
    #     {
    #       on = "<C-w>";
    #       run = "kill backward";
    #       desc = "Kill backwards to the start of the current word";
    #     }
    #     {
    #       on = "<A-d>";
    #       run = "kill forward";
    #       desc = "Kill forwards to the end of the current word";
    #     }
    #     # Cut/Yank/Paste
    #     {
    #       on = "d";
    #       run = "delete --cut";
    #       desc = "Cut the selected characters";
    #     }
    #     {
    #       on = "D";
    #       run = [ "delete --cut" "move 999" ];
    #       desc = "Cut until the EOL";
    #     }
    #     {
    #       on = "c";
    #       run = "delete --cut --insert";
    #       desc = "Cut the selected characters, and enter insert mode";
    #     }
    #     {
    #       on = "C";
    #       run = [ "delete --cut --insert" "move 999" ];
    #       desc = "Cut until the EOL, and enter insert mode";
    #     }
    #     {
    #       on = "x";
    #       run = [ "delete --cut" "move 1 --in-operating" ];
    #       desc = "Cut the current character";
    #     }
    #     {
    #       on = "y";
    #       run = "yank";
    #       desc = "Copy the selected characters";
    #     }
    #     {
    #       on = "p";
    #       run = "paste";
    #       desc = "Paste the copied characters after the cursor";
    #     }
    #     {
    #       on = "P";
    #       run = "paste --before";
    #       desc = "Paste the copied characters before the cursor";
    #     }
    #     # Undo/Redo
    #     {
    #       on = "u";
    #       run = "undo";
    #       desc = "Undo the last operation";
    #     }
    #     {
    #       on = "<C-r>";
    #       run = "redo";
    #       desc = "Redo the last operation";
    #     }
    #     # Help
    #     {
    #       on = "~";
    #       run = "help";
    #       desc = "Open help";
    #     }
    #     {
    #       on = "<F1>";
    #       run = "help";
    #       desc = "Open help";
    #     }
    #   ];
    #   input.prepend_keymap = [
    #     # https://yazi-rs.github.io/docs/tips/#close-input-by-esc
    #     {
    #       on = ["<Esc>"];
    #       run = "close";
    #       desc = "Cancel input";
    #     }
    #   ];
    #   confirm.keymap = [
    #     {
    #       on = "<Esc>";
    #       run = "close";
    #       desc = "Cancel the confirm";
    #     }
    #     {
    #       on = "<C-[>";
    #       run = "close";
    #       desc = "Cancel the confirm";
    #     }
    #     {
    #       on = "<C-c>";
    #       run = "close";
    #       desc = "Cancel the confirm";
    #     }
    #     {
    #       on = "<Enter>";
    #       run = "close --submit";
    #       desc = "Submit the confirm";
    #     }
    #     {
    #       on = "n";
    #       run = "close";
    #       desc = "Cancel the confirm";
    #     }
    #     {
    #       on = "y";
    #       run = "close --submit";
    #       desc = "Submit the confirm";
    #     }
    #     {
    #       on = "k";
    #       run = "arrow -1";
    #       desc = "Move cursor up";
    #     }
    #     {
    #       on = "j";
    #       run = "arrow 1";
    #       desc = "Move cursor down";
    #     }
    #     {
    #       on = "<Up>";
    #       run = "arrow -1";
    #       desc = "Move cursor up";
    #     }
    #     {
    #       on = "<Down>";
    #       run = "arrow 1";
    #       desc = "Move cursor down";
    #     }
    #     # Help
    #     {
    #       on = "~";
    #       run = "help";
    #       desc = "Open help";
    #     }
    #     {
    #       on = "<F1>";
    #       run = "help";
    #       desc = "Open help";
    #     }
    #   ];
    #   completion.keymap = [
    #     {
    #       on = "<C-c>";
    #       run = "close";
    #       desc = "Cancel completion";
    #     }
    #     {
    #       on = "<Tab>";
    #       run = "close --submit";
    #       desc = "Submit the completion";
    #     }
    #     {
    #       on = "<Enter>";
    #       run = [ "close --submit" "close_input --submit" ];
    #       desc = "Submit the completion and input";
    #     }
    #     {
    #       on = "<A-k>";
    #       run = "arrow -1";
    #       desc = "Move cursor up";
    #     }
    #     {
    #       on = "<A-j>";
    #       run = "arrow 1";
    #       desc = "Move cursor down";
    #     }
    #     {
    #       on = "<Up>";
    #       run = "arrow -1";
    #       desc = "Move cursor up";
    #     }
    #     {
    #       on = "<Down>";
    #       run = "arrow 1";
    #       desc = "Move cursor down";
    #     }
    #     {
    #       on = "<C-p>";
    #       run = "arrow -1";
    #       desc = "Move cursor up";
    #     }
    #     {
    #       on = "<C-n>";
    #       run = "arrow 1";
    #       desc = "Move cursor down";
    #     }
    #     # Help
    #     {
    #       on = "~";
    #       run = "help";
    #       desc = "Open help";
    #     }
    #     {
    #       on = "<F1>";
    #       run = "help";
    #       desc = "Open help";
    #     }
    #   ];
    #   help.keymap = [
    #     {
    #       on = "<Esc>";
    #       run = "escape";
    #       desc = "Clear the filter, or hide the help";
    #     }
    #     {
    #       on = "<C-[>";
    #       run = "escape";
    #       desc = "Clear the filter, or hide the help";
    #     }
    #     {
    #       on = "q";
    #       run = "close";
    #       desc = "Exit the process";
    #     }
    #     {
    #       on = "<C-c>";
    #       run = "close";
    #       desc = "Hide the help";
    #     }
    #     # Navigation
    #     {
    #       on = "k";
    #       run = "arrow -1";
    #       desc = "Move cursor up";
    #     }
    #     {
    #       on = "j";
    #       run = "arrow 1";
    #       desc = "Move cursor down";
    #     }
    #     {
    #       on = "<Up>";
    #       run = "arrow -1";
    #       desc = "Move cursor up";
    #     }
    #     {
    #       on = "<Down>";
    #       run = "arrow 1";
    #       desc = "Move cursor down";
    #     }
    #     # Filtering
    #     {
    #       on = "f";
    #       run = "filter";
    #       desc = "Apply a filter for the help items";
    #     }
    #   ];
    # };
    # # theme = {
    # #   flavor = {
    # #     use = "";
    # #   };
    # #   manager = {
    # #     cwd = { fg = "cyan"; };

    # #     # Hovered
    # #     hovered = { reversed = true; };
    # #     preview_hovered = { underline = true; };

    # #     # Find
    # #     find_keyword = { fg = "yellow"; bold = true; italic = true; underline = true; };
    # #     find_position = { fg = "magenta"; bg = "reset"; bold = true; italic = true; };

    # #     # Marker
    # #     marker_copied = { fg = "lightgreen";  bg = "lightgreen"; };
    # #     marker_cut = { fg = "lightred";    bg = "lightred"; };
    # #     marker_marked = { fg = "lightcyan";   bg = "lightcyan"; };
    # #     marker_selected = { fg = "lightyellow"; bg = "lightyellow"; };

    # #     # Tab
    # #     tab_active = { reversed = true; };
    # #     tab_inactive = {};
    # #     tab_width = 1;

    # #     # Count
    # #     count_copied = { fg = "white"; bg = "green"; };
    # #     count_cut = { fg = "white"; bg = "red"; };
    # #     count_selected = { fg = "white"; bg = "yellow"; };

    # #     # Border
    # #     border_symbol = "│";
    # #     border_style = { fg = "gray"; };

    # #     # Highlighting
    # #     syntect_theme = "";
    # #   };
    # #   status = {
    # #     separator_open = "";
    # #     separator_close = "";
    # #     separator_style = { fg = "gray"; bg = "gray"; };

    # #     # Mode
    # #     mode_normal = { bg = "blue"; bold = true; };
    # #     mode_select = { bg = "red"; bold = true; };
    # #     mode_unset = { bg = "red"; bold = true; };

    # #     # Progress
    # #     progress_label = { bold = true; };
    # #     progress_normal = { fg = "blue"; bg = "black"; };
    # #     progress_error = { fg = "red"; bg = "black"; };

    # #     # Permissions
    # #     permissions_t = { fg = "green"; };
    # #     permissions_r = { fg = "yellow"; };
    # #     permissions_w = { fg = "red"; };
    # #     permissions_x = { fg = "cyan"; };
    # #     permissions_s = { fg = "darkgray"; };
    # #   };
    # #   select = {
    # #     border = { fg = "blue"; };
    # #     active = { fg = "magenta"; bold = true; };
    # #     inactive = {};
    # #   };
    # #   input = {
    # #     border = { fg = "blue"; };
    # #     title = {};
    # #     value = {};
    # #     selected = { reversed = true; };
    # #   };
    # #   completion = {
    # #     border = { fg = "blue"; };
    # #     active = { reversed = true; };
    # #     inactive = {};

    # #     # Icons
    # #     icon_file = "";
    # #     icon_folder = "";
    # #     icon_command = "";
    # #   };
    # #   tasks = {
    # #     border = { fg = "blue"; };
    # #     title = {};
    # #     hovered = { fg = "magenta"; underline = true; };
    # #   };
    # #   which = {
    # #     cols = 3;
    # #     mask = { bg = "black"; };
    # #     cand = { fg = "lightcyan"; };
    # #     rest = { fg = "darkgray"; };
    # #     desc = { fg = "lightmagenta"; };
    # #     separator = "  ";
    # #     separator_style = { fg = "darkgray"; };
    # #   };
    # #   help = {
    # #     on = { fg = "cyan"; };
    # #     run = { fg = "magenta"; };
    # #     desc = {};
    # #     hovered = { reversed = true; bold = true; };
    # #     footer = { fg = "black"; bg = "white"; };
    # #   };
    # #   notify = {
    # #     title_info = { fg = "green"; };
    # #     title_warn = { fg = "yellow"; };
    # #     title_error = { fg = "red"; };

    # #     # Icons
    # #     icon_info = "";
    # #     icon_warn = "";
    # #     icon_error = "";
    # #   };
    # #   filetype = {
    # #     rules = [
    # #       # Images
    # #       { mime = "image/*"; fg = "yellow"; }

    # #       # Media
    # #       { mime = "{audio;video}/*"; fg = "magenta"; }

    # #       # Archives
    # #       { mime = "application/{;g}zip"; fg = "red"; }
    # #       { mime = "application/x-{tar;bzip*;7z-compressed;xz;rar}"; fg = "red"; }

    # #       # Documents
    # #       { mime = "application/{pdf;doc;rtf;vnd.*}"; fg = "cyan"; }

    # #       # Empty files
    # #       # { mime = "inode/x-empty"; fg = "red"; };

    # #       # Special files
    # #       { name = "*"; is = "orphan"; bg = "red"; }
    # #       { name = "*"; is = "exec"; fg = "green"; }

    # #       # Dummy files
    # #       { name = "*"; is = "dummy"; bg = "red"; }
    # #       { name = "*/"; is = "dummy"; bg = "red"; }

    # #       # Fallback
    # #       # { name = "*"; fg = "white"; };
    # #       { name = "*/"; fg = "blue"; }
    # #     ];
    # #   };
    # #   icon = {
    # #     globs = [];
    # #     dirs = [
    # #       { name = ".config"; text = ""; }
    # #       { name = ".git"; text = ""; }
    # #       { name = "Desktop"; text = ""; }
    # #       { name = "Code"; text = ""; }
    # #       { name = "Documents"; text = ""; }
    # #       { name = "Downloads"; text = ""; }
    # #       { name = "Library"; text = ""; }
    # #       { name = "Movies"; text = ""; }
    # #       { name = "Music"; text = ""; }
    # #       { name = "Pictures"; text = ""; }
    # #       { name = "Public"; text = ""; }
    # #       { name = "Videos"; text = ""; }
    # #     ];
    # #     files = [
    # #       { name = ".babelrc"; text = ""; fg_dark = "#cbcb41"; fg_light = "#666620"; }
    # #       { name = ".bash_profile"; text = ""; fg_dark = "#89e051"; fg_light = "#447028"; }
    # #       { name = ".bashrc"; text = ""; fg_dark = "#89e051"; fg_light = "#447028"; }
    # #       { name = ".dockerignore"; text = "󰡨"; fg_dark = "#458ee6"; fg_light = "#2e5f99"; }
    # #       { name = ".ds_store"; text = ""; fg_dark = "#41535b"; fg_light = "#41535b"; }
    # #       { name = ".editorconfig"; text = ""; fg_dark = "#fff2f2"; fg_light = "#333030"; }
    # #       { name = ".env"; text = ""; fg_dark = "#faf743"; fg_light = "#32310d"; }
    # #       { name = ".eslintignore"; text = ""; fg_dark = "#4b32c3"; fg_light = "#4b32c3"; }
    # #       { name = ".eslintrc"; text = ""; fg_dark = "#4b32c3"; fg_light = "#4b32c3"; }
    # #       { name = ".gitattributes"; text = ""; fg_dark = "#f54d27"; fg_light = "#b83a1d"; }
    # #       { name = ".gitconfig"; text = ""; fg_dark = "#f54d27"; fg_light = "#b83a1d"; }
    # #       { name = ".gitignore"; text = ""; fg_dark = "#f54d27"; fg_light = "#b83a1d"; }
    # #       { name = ".gitlab-ci.yml"; text = ""; fg_dark = "#e24329"; fg_light = "#aa321f"; }
    # #       { name = ".gitmodules"; text = ""; fg_dark = "#f54d27"; fg_light = "#b83a1d"; }
    # #       { name = ".gtkrc-2.0"; text = ""; fg_dark = "#ffffff"; fg_light = "#333333"; }
    # #       { name = ".gvimrc"; text = ""; fg_dark = "#019833"; fg_light = "#017226"; }
    # #       { name = ".luaurc"; text = ""; fg_dark = "#00a2ff"; fg_light = "#007abf"; }
    # #       { name = ".mailmap"; text = "󰊢"; fg_dark = "#41535b"; fg_light = "#41535b"; }
    # #       { name = ".npmignore"; text = ""; fg_dark = "#e8274b"; fg_light = "#ae1d38"; }
    # #       { name = ".npmrc"; text = ""; fg_dark = "#e8274b"; fg_light = "#ae1d38"; }
    # #       { name = ".prettierrc"; text = ""; fg_dark = "#4285f4"; fg_light = "#3264b7"; }
    # #       { name = ".settings.json"; text = ""; fg_dark = "#854cc7"; fg_light = "#643995"; }
    # #       { name = ".SRCINFO"; text = "󰣇"; fg_dark = "#0f94d2"; fg_light = "#0b6f9e"; }
    # #       { name = ".vimrc"; text = ""; fg_dark = "#019833"; fg_light = "#017226"; }
    # #       { name = ".Xauthority"; text = ""; fg_dark = "#e54d18"; fg_light = "#ac3a12"; }
    # #       { name = ".xinitrc"; text = ""; fg_dark = "#e54d18"; fg_light = "#ac3a12"; }
    # #       { name = ".Xresources"; text = ""; fg_dark = "#e54d18"; fg_light = "#ac3a12"; }
    # #       { name = ".xsession"; text = ""; fg_dark = "#e54d18"; fg_light = "#ac3a12"; }
    # #       { name = ".zprofile"; text = ""; fg_dark = "#89e051"; fg_light = "#447028"; }
    # #       { name = ".zshenv"; text = ""; fg_dark = "#89e051"; fg_light = "#447028"; }
    # #       { name = ".zshrc"; text = ""; fg_dark = "#89e051"; fg_light = "#447028"; }
    # #       { name = "_gvimrc"; text = ""; fg_dark = "#019833"; fg_light = "#017226"; }
    # #       { name = "_vimrc"; text = ""; fg_dark = "#019833"; fg_light = "#017226"; }
    # #       { name = "avif"; text = ""; fg_dark = "#a074c4"; fg_light = "#6b4d83"; }
    # #       { name = "brewfile"; text = ""; fg_dark = "#701516"; fg_light = "#701516"; }
    # #       { name = "bspwmrc"; text = ""; fg_dark = "#2f2f2f"; fg_light = "#2f2f2f"; }
    # #       { name = "build"; text = ""; fg_dark = "#89e051"; fg_light = "#447028"; }
    # #       { name = "build.gradle"; text = ""; fg_dark = "#005f87"; fg_light = "#005f87"; }
    # #       { name = "build.zig.zon"; text = ""; fg_dark = "#f69a1b"; fg_light = "#7b4d0e"; }
    # #       { name = "cantorrc"; text = ""; fg_dark = "#1c99f3"; fg_light = "#1573b6"; }
    # #       { name = "checkhealth"; text = "󰓙"; fg_dark = "#75b4fb"; fg_light = "#3a5a7e"; }
    # #       { name = "cmakelists.txt"; text = ""; fg_dark = "#6d8086"; fg_light = "#526064"; }
    # #       { name = "commit_editmsg"; text = ""; fg_dark = "#f54d27"; fg_light = "#b83a1d"; }
    # #       { name = "compose.yaml"; text = "󰡨"; fg_dark = "#458ee6"; fg_light = "#2e5f99"; }
    # #       { name = "compose.yml"; text = "󰡨"; fg_dark = "#458ee6"; fg_light = "#2e5f99"; }
    # #       { name = "config"; text = ""; fg_dark = "#6d8086"; fg_light = "#526064"; }
    # #       { name = "containerfile"; text = "󰡨"; fg_dark = "#458ee6"; fg_light = "#2e5f99"; }
    # #       { name = "copying"; text = ""; fg_dark = "#cbcb41"; fg_light = "#666620"; }
    # #       { name = "copying.lesser"; text = ""; fg_dark = "#cbcb41"; fg_light = "#666620"; }
    # #       { name = "docker-compose.yaml"; text = "󰡨"; fg_dark = "#458ee6"; fg_light = "#2e5f99"; }
    # #       { name = "docker-compose.yml"; text = "󰡨"; fg_dark = "#458ee6"; fg_light = "#2e5f99"; }
    # #       { name = "dockerfile"; text = "󰡨"; fg_dark = "#458ee6"; fg_light = "#2e5f99"; }
    # #       { name = "ext_typoscript_setup.txt"; text = ""; fg_dark = "#ff8700"; fg_light = "#aa5a00"; }
    # #       { name = "favicon.ico"; text = ""; fg_dark = "#cbcb41"; fg_light = "#666620"; }
    # #       { name = "fp-info-cache"; text = ""; fg_dark = "#ffffff"; fg_light = "#333333"; }
    # #       { name = "fp-lib-table"; text = ""; fg_dark = "#ffffff"; fg_light = "#333333"; }
    # #       { name = "FreeCAD.conf"; text = ""; fg_dark = "#cb0d0d"; fg_light = "#cb0d0d"; }
    # #       { name = "gemfile$"; text = ""; fg_dark = "#701516"; fg_light = "#701516"; }
    # #       { name = "gnumakefile"; text = ""; fg_dark = "#6d8086"; fg_light = "#526064"; }
    # #       { name = "gradle-wrapper.properties"; text = ""; fg_dark = "#005f87"; fg_light = "#005f87"; }
    # #       { name = "gradle.properties"; text = ""; fg_dark = "#005f87"; fg_light = "#005f87"; }
    # #       { name = "gradlew"; text = ""; fg_dark = "#005f87"; fg_light = "#005f87"; }
    # #       { name = "groovy"; text = ""; fg_dark = "#4a687c"; fg_light = "#384e5d"; }
    # #       { name = "gruntfile.babel.js"; text = ""; fg_dark = "#e37933"; fg_light = "#975122"; }
    # #       { name = "gruntfile.coffee"; text = ""; fg_dark = "#e37933"; fg_light = "#975122"; }
    # #       { name = "gruntfile.js"; text = ""; fg_dark = "#e37933"; fg_light = "#975122"; }
    # #       { name = "gruntfile.ts"; text = ""; fg_dark = "#e37933"; fg_light = "#975122"; }
    # #       { name = "gtkrc"; text = ""; fg_dark = "#ffffff"; fg_light = "#333333"; }
    # #       { name = "gulpfile.babel.js"; text = ""; fg_dark = "#cc3e44"; fg_light = "#992e33"; }
    # #       { name = "gulpfile.coffee"; text = ""; fg_dark = "#cc3e44"; fg_light = "#992e33"; }
    # #       { name = "gulpfile.js"; text = ""; fg_dark = "#cc3e44"; fg_light = "#992e33"; }
    # #       { name = "gulpfile.ts"; text = ""; fg_dark = "#cc3e44"; fg_light = "#992e33"; }
    # #       { name = "hyprland.conf"; text = ""; fg_dark = "#00aaae"; fg_light = "#008082"; }
    # #       { name = "i3blocks.conf"; text = ""; fg_dark = "#e8ebee"; fg_light = "#2e2f30"; }
    # #       { name = "i3status.conf"; text = ""; fg_dark = "#e8ebee"; fg_light = "#2e2f30"; }
    # #       { name = "kalgebrarc"; text = ""; fg_dark = "#1c99f3"; fg_light = "#1573b6"; }
    # #       { name = "kdeglobals"; text = ""; fg_dark = "#1c99f3"; fg_light = "#1573b6"; }
    # #       { name = "kdenlive-layoutsrc"; text = ""; fg_dark = "#83b8f2"; fg_light = "#425c79"; }
    # #       { name = "kdenliverc"; text = ""; fg_dark = "#83b8f2"; fg_light = "#425c79"; }
    # #       { name = "kritadisplayrc"; text = ""; fg_dark = "#f245fb"; fg_light = "#a12ea7"; }
    # #       { name = "kritarc"; text = ""; fg_dark = "#f245fb"; fg_light = "#a12ea7"; }
    # #       { name = "license"; text = ""; fg_dark = "#d0bf41"; fg_light = "#686020"; }
    # #       { name = "lxde-rc.xml"; text = ""; fg_dark = "#909090"; fg_light = "#606060"; }
    # #       { name = "lxqt.conf"; text = ""; fg_dark = "#0192d3"; fg_light = "#016e9e"; }
    # #       { name = "makefile"; text = ""; fg_dark = "#6d8086"; fg_light = "#526064"; }
    # #       { name = "mix.lock"; text = ""; fg_dark = "#a074c4"; fg_light = "#6b4d83"; }
    # #       { name = "mpv.conf"; text = ""; fg_dark = "#3b1342"; fg_light = "#3b1342"; }
    # #       { name = "node_modules"; text = ""; fg_dark = "#e8274b"; fg_light = "#ae1d38"; }
    # #       { name = "package-lock.json"; text = ""; fg_dark = "#7a0d21"; fg_light = "#7a0d21"; }
    # #       { name = "package.json"; text = ""; fg_dark = "#e8274b"; fg_light = "#ae1d38"; }
    # #       { name = "PKGBUILD"; text = ""; fg_dark = "#0f94d2"; fg_light = "#0b6f9e"; }
    # #       { name = "platformio.ini"; text = ""; fg_dark = "#f6822b"; fg_light = "#a4571d"; }
    # #       { name = "pom.xml"; text = ""; fg_dark = "#7a0d21"; fg_light = "#7a0d21"; }
    # #       { name = "procfile"; text = ""; fg_dark = "#a074c4"; fg_light = "#6b4d83"; }
    # #       { name = "PrusaSlicer.ini"; text = ""; fg_dark = "#ec6b23"; fg_light = "#9d4717"; }
    # #       { name = "PrusaSlicerGcodeViewer.ini"; text = ""; fg_dark = "#ec6b23"; fg_light = "#9d4717"; }
    # #       { name = "py.typed"; text = ""; fg_dark = "#ffbc03"; fg_light = "#805e02"; }
    # #       { name = "QtProject.conf"; text = ""; fg_dark = "#40cd52"; fg_light = "#2b8937"; }
    # #       { name = "R"; text = "󰟔"; fg_dark = "#2266ba"; fg_light = "#1a4c8c"; }
    # #       { name = "r"; text = "󰟔"; fg_dark = "#2266ba"; fg_light = "#1a4c8c"; }
    # #       { name = "rakefile"; text = ""; fg_dark = "#701516"; fg_light = "#701516"; }
    # #       { name = "rmd"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "settings.gradle"; text = ""; fg_dark = "#005f87"; fg_light = "#005f87"; }
    # #       { name = "svelte.config.js"; text = ""; fg_dark = "#ff3e00"; fg_light = "#bf2e00"; }
    # #       { name = "sxhkdrc"; text = ""; fg_dark = "#2f2f2f"; fg_light = "#2f2f2f"; }
    # #       { name = "sym-lib-table"; text = ""; fg_dark = "#ffffff"; fg_light = "#333333"; }
    # #       { name = "tailwind.config.js"; text = "󱏿"; fg_dark = "#20c2e3"; fg_light = "#158197"; }
    # #       { name = "tailwind.config.mjs"; text = "󱏿"; fg_dark = "#20c2e3"; fg_light = "#158197"; }
    # #       { name = "tailwind.config.ts"; text = "󱏿"; fg_dark = "#20c2e3"; fg_light = "#158197"; }
    # #       { name = "tmux.conf"; text = ""; fg_dark = "#14ba19"; fg_light = "#0f8c13"; }
    # #       { name = "tmux.conf.local"; text = ""; fg_dark = "#14ba19"; fg_light = "#0f8c13"; }
    # #       { name = "tsconfig.json"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "unlicense"; text = ""; fg_dark = "#d0bf41"; fg_light = "#686020"; }
    # #       { name = "vagrantfile$"; text = ""; fg_dark = "#1563ff"; fg_light = "#104abf"; }
    # #       { name = "vlcrc"; text = "󰕼"; fg_dark = "#ee7a00"; fg_light = "#9f5100"; }
    # #       { name = "webpack"; text = "󰜫"; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "weston.ini"; text = ""; fg_dark = "#ffbb01"; fg_light = "#805e00"; }
    # #       { name = "workspace"; text = ""; fg_dark = "#89e051"; fg_light = "#447028"; }
    # #       { name = "xmobarrc"; text = ""; fg_dark = "#fd4d5d"; fg_light = "#a9333e"; }
    # #       { name = "xmobarrc.hs"; text = ""; fg_dark = "#fd4d5d"; fg_light = "#a9333e"; }
    # #       { name = "xmonad.hs"; text = ""; fg_dark = "#fd4d5d"; fg_light = "#a9333e"; }
    # #       { name = "xorg.conf"; text = ""; fg_dark = "#e54d18"; fg_light = "#ac3a12"; }
    # #       { name = "xsettingsd.conf"; text = ""; fg_dark = "#e54d18"; fg_light = "#ac3a12"; }
    # #     ];
    # #     exts = [
    # #       { name = "3gp"; text = ""; fg_dark = "#fd971f"; fg_light = "#7e4c10"; }
    # #       { name = "3mf"; text = "󰆧"; fg_dark = "#888888"; fg_light = "#5b5b5b"; }
    # #       { name = "7z"; text = ""; fg_dark = "#eca517"; fg_light = "#76520c"; }
    # #       { name = "a"; text = ""; fg_dark = "#dcddd6"; fg_light = "#494a47"; }
    # #       { name = "aac"; text = ""; fg_dark = "#00afff"; fg_light = "#0075aa"; }
    # #       { name = "ai"; text = ""; fg_dark = "#cbcb41"; fg_light = "#666620"; }
    # #       { name = "aif"; text = ""; fg_dark = "#00afff"; fg_light = "#0075aa"; }
    # #       { name = "aiff"; text = ""; fg_dark = "#00afff"; fg_light = "#0075aa"; }
    # #       { name = "android"; text = ""; fg_dark = "#34a853"; fg_light = "#277e3e"; }
    # #       { name = "ape"; text = ""; fg_dark = "#00afff"; fg_light = "#0075aa"; }
    # #       { name = "apk"; text = ""; fg_dark = "#34a853"; fg_light = "#277e3e"; }
    # #       { name = "app"; text = ""; fg_dark = "#9f0500"; fg_light = "#9f0500"; }
    # #       { name = "applescript"; text = ""; fg_dark = "#6d8085"; fg_light = "#526064"; }
    # #       { name = "asc"; text = "󰦝"; fg_dark = "#576d7f"; fg_light = "#41525f"; }
    # #       { name = "ass"; text = "󰨖"; fg_dark = "#ffb713"; fg_light = "#805c0a"; }
    # #       { name = "astro"; text = ""; fg_dark = "#e23f67"; fg_light = "#aa2f4d"; }
    # #       { name = "awk"; text = ""; fg_dark = "#4d5a5e"; fg_light = "#3a4446"; }
    # #       { name = "azcli"; text = ""; fg_dark = "#0078d4"; fg_light = "#005a9f"; }
    # #       { name = "bak"; text = "󰁯"; fg_dark = "#6d8086"; fg_light = "#526064"; }
    # #       { name = "bash"; text = ""; fg_dark = "#89e051"; fg_light = "#447028"; }
    # #       { name = "bat"; text = ""; fg_dark = "#c1f12e"; fg_light = "#40500f"; }
    # #       { name = "bazel"; text = ""; fg_dark = "#89e051"; fg_light = "#447028"; }
    # #       { name = "bib"; text = "󱉟"; fg_dark = "#cbcb41"; fg_light = "#666620"; }
    # #       { name = "bicep"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "bicepparam"; text = ""; fg_dark = "#9f74b3"; fg_light = "#6a4d77"; }
    # #       { name = "bin"; text = ""; fg_dark = "#9f0500"; fg_light = "#9f0500"; }
    # #       { name = "blade.php"; text = ""; fg_dark = "#f05340"; fg_light = "#a0372b"; }
    # #       { name = "blend"; text = "󰂫"; fg_dark = "#ea7600"; fg_light = "#9c4f00"; }
    # #       { name = "blp"; text = "󰺾"; fg_dark = "#5796e2"; fg_light = "#3a6497"; }
    # #       { name = "bmp"; text = ""; fg_dark = "#a074c4"; fg_light = "#6b4d83"; }
    # #       { name = "brep"; text = "󰻫"; fg_dark = "#839463"; fg_light = "#576342"; }
    # #       { name = "bz"; text = ""; fg_dark = "#eca517"; fg_light = "#76520c"; }
    # #       { name = "bz2"; text = ""; fg_dark = "#eca517"; fg_light = "#76520c"; }
    # #       { name = "bz3"; text = ""; fg_dark = "#eca517"; fg_light = "#76520c"; }
    # #       { name = "bzl"; text = ""; fg_dark = "#89e051"; fg_light = "#447028"; }
    # #       { name = "c"; text = ""; fg_dark = "#599eff"; fg_light = "#3b69aa"; }
    # #       { name = "c++"; text = ""; fg_dark = "#f34b7d"; fg_light = "#a23253"; }
    # #       { name = "cache"; text = ""; fg_dark = "#ffffff"; fg_light = "#333333"; }
    # #       { name = "cast"; text = ""; fg_dark = "#fd971f"; fg_light = "#7e4c10"; }
    # #       { name = "cbl"; text = "⚙"; fg_dark = "#005ca5"; fg_light = "#005ca5"; }
    # #       { name = "cc"; text = ""; fg_dark = "#f34b7d"; fg_light = "#a23253"; }
    # #       { name = "ccm"; text = ""; fg_dark = "#f34b7d"; fg_light = "#a23253"; }
    # #       { name = "cfg"; text = ""; fg_dark = "#6d8086"; fg_light = "#526064"; }
    # #       { name = "cjs"; text = ""; fg_dark = "#cbcb41"; fg_light = "#666620"; }
    # #       { name = "clj"; text = ""; fg_dark = "#8dc149"; fg_light = "#466024"; }
    # #       { name = "cljc"; text = ""; fg_dark = "#8dc149"; fg_light = "#466024"; }
    # #       { name = "cljd"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "cljs"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "cmake"; text = ""; fg_dark = "#6d8086"; fg_light = "#526064"; }
    # #       { name = "cob"; text = "⚙"; fg_dark = "#005ca5"; fg_light = "#005ca5"; }
    # #       { name = "cobol"; text = "⚙"; fg_dark = "#005ca5"; fg_light = "#005ca5"; }
    # #       { name = "coffee"; text = ""; fg_dark = "#cbcb41"; fg_light = "#666620"; }
    # #       { name = "conf"; text = ""; fg_dark = "#6d8086"; fg_light = "#526064"; }
    # #       { name = "config.ru"; text = ""; fg_dark = "#701516"; fg_light = "#701516"; }
    # #       { name = "cp"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "cpp"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "cppm"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "cpy"; text = "⚙"; fg_dark = "#005ca5"; fg_light = "#005ca5"; }
    # #       { name = "cr"; text = ""; fg_dark = "#c8c8c8"; fg_light = "#434343"; }
    # #       { name = "crdownload"; text = ""; fg_dark = "#44cda8"; fg_light = "#226654"; }
    # #       { name = "cs"; text = "󰌛"; fg_dark = "#596706"; fg_light = "#434d04"; }
    # #       { name = "csh"; text = ""; fg_dark = "#4d5a5e"; fg_light = "#3a4446"; }
    # #       { name = "cshtml"; text = "󱦗"; fg_dark = "#512bd4"; fg_light = "#512bd4"; }
    # #       { name = "cson"; text = ""; fg_dark = "#cbcb41"; fg_light = "#666620"; }
    # #       { name = "csproj"; text = "󰪮"; fg_dark = "#512bd4"; fg_light = "#512bd4"; }
    # #       { name = "css"; text = ""; fg_dark = "#42a5f5"; fg_light = "#2c6ea3"; }
    # #       { name = "csv"; text = ""; fg_dark = "#89e051"; fg_light = "#447028"; }
    # #       { name = "cts"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "cu"; text = ""; fg_dark = "#89e051"; fg_light = "#447028"; }
    # #       { name = "cue"; text = "󰲹"; fg_dark = "#ed95ae"; fg_light = "#764a57"; }
    # #       { name = "cuh"; text = ""; fg_dark = "#a074c4"; fg_light = "#6b4d83"; }
    # #       { name = "cxx"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "cxxm"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "d"; text = ""; fg_dark = "#427819"; fg_light = "#325a13"; }
    # #       { name = "d.ts"; text = ""; fg_dark = "#d59855"; fg_light = "#6a4c2a"; }
    # #       { name = "dart"; text = ""; fg_dark = "#03589c"; fg_light = "#03589c"; }
    # #       { name = "db"; text = ""; fg_dark = "#dad8d8"; fg_light = "#494848"; }
    # #       { name = "dconf"; text = ""; fg_dark = "#ffffff"; fg_light = "#333333"; }
    # #       { name = "desktop"; text = ""; fg_dark = "#563d7c"; fg_light = "#563d7c"; }
    # #       { name = "diff"; text = ""; fg_dark = "#41535b"; fg_light = "#41535b"; }
    # #       { name = "dll"; text = ""; fg_dark = "#4d2c0b"; fg_light = "#4d2c0b"; }
    # #       { name = "doc"; text = "󰈬"; fg_dark = "#185abd"; fg_light = "#185abd"; }
    # #       { name = "Dockerfile"; text = "󰡨"; fg_dark = "#458ee6"; fg_light = "#2e5f99"; }
    # #       { name = "docx"; text = "󰈬"; fg_dark = "#185abd"; fg_light = "#185abd"; }
    # #       { name = "dot"; text = "󱁉"; fg_dark = "#30638e"; fg_light = "#244a6a"; }
    # #       { name = "download"; text = ""; fg_dark = "#44cda8"; fg_light = "#226654"; }
    # #       { name = "drl"; text = ""; fg_dark = "#ffafaf"; fg_light = "#553a3a"; }
    # #       { name = "dropbox"; text = ""; fg_dark = "#0061fe"; fg_light = "#0049be"; }
    # #       { name = "dump"; text = ""; fg_dark = "#dad8d8"; fg_light = "#494848"; }
    # #       { name = "dwg"; text = "󰻫"; fg_dark = "#839463"; fg_light = "#576342"; }
    # #       { name = "dxf"; text = "󰻫"; fg_dark = "#839463"; fg_light = "#576342"; }
    # #       { name = "ebook"; text = ""; fg_dark = "#eab16d"; fg_light = "#755836"; }
    # #       { name = "edn"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "eex"; text = ""; fg_dark = "#a074c4"; fg_light = "#6b4d83"; }
    # #       { name = "ejs"; text = ""; fg_dark = "#cbcb41"; fg_light = "#666620"; }
    # #       { name = "el"; text = ""; fg_dark = "#8172be"; fg_light = "#61568e"; }
    # #       { name = "elc"; text = ""; fg_dark = "#8172be"; fg_light = "#61568e"; }
    # #       { name = "elf"; text = ""; fg_dark = "#9f0500"; fg_light = "#9f0500"; }
    # #       { name = "elm"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "eln"; text = ""; fg_dark = "#8172be"; fg_light = "#61568e"; }
    # #       { name = "env"; text = ""; fg_dark = "#faf743"; fg_light = "#32310d"; }
    # #       { name = "eot"; text = ""; fg_dark = "#ececec"; fg_light = "#2f2f2f"; }
    # #       { name = "epp"; text = ""; fg_dark = "#ffa61a"; fg_light = "#80530d"; }
    # #       { name = "epub"; text = ""; fg_dark = "#eab16d"; fg_light = "#755836"; }
    # #       { name = "erb"; text = ""; fg_dark = "#701516"; fg_light = "#701516"; }
    # #       { name = "erl"; text = ""; fg_dark = "#b83998"; fg_light = "#8a2b72"; }
    # #       { name = "ex"; text = ""; fg_dark = "#a074c4"; fg_light = "#6b4d83"; }
    # #       { name = "exe"; text = ""; fg_dark = "#9f0500"; fg_light = "#9f0500"; }
    # #       { name = "exs"; text = ""; fg_dark = "#a074c4"; fg_light = "#6b4d83"; }
    # #       { name = "f#"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "f3d"; text = "󰻫"; fg_dark = "#839463"; fg_light = "#576342"; }
    # #       { name = "f90"; text = "󱈚"; fg_dark = "#734f96"; fg_light = "#563b70"; }
    # #       { name = "fbx"; text = "󰆧"; fg_dark = "#888888"; fg_light = "#5b5b5b"; }
    # #       { name = "fcbak"; text = ""; fg_dark = "#cb0d0d"; fg_light = "#cb0d0d"; }
    # #       { name = "fcmacro"; text = ""; fg_dark = "#cb0d0d"; fg_light = "#cb0d0d"; }
    # #       { name = "fcmat"; text = ""; fg_dark = "#cb0d0d"; fg_light = "#cb0d0d"; }
    # #       { name = "fcparam"; text = ""; fg_dark = "#cb0d0d"; fg_light = "#cb0d0d"; }
    # #       { name = "fcscript"; text = ""; fg_dark = "#cb0d0d"; fg_light = "#cb0d0d"; }
    # #       { name = "fcstd"; text = ""; fg_dark = "#cb0d0d"; fg_light = "#cb0d0d"; }
    # #       { name = "fcstd1"; text = ""; fg_dark = "#cb0d0d"; fg_light = "#cb0d0d"; }
    # #       { name = "fctb"; text = ""; fg_dark = "#cb0d0d"; fg_light = "#cb0d0d"; }
    # #       { name = "fctl"; text = ""; fg_dark = "#cb0d0d"; fg_light = "#cb0d0d"; }
    # #       { name = "fdmdownload"; text = ""; fg_dark = "#44cda8"; fg_light = "#226654"; }
    # #       { name = "fish"; text = ""; fg_dark = "#4d5a5e"; fg_light = "#3a4446"; }
    # #       { name = "flac"; text = ""; fg_dark = "#0075aa"; fg_light = "#005880"; }
    # #       { name = "flc"; text = ""; fg_dark = "#ececec"; fg_light = "#2f2f2f"; }
    # #       { name = "flf"; text = ""; fg_dark = "#ececec"; fg_light = "#2f2f2f"; }
    # #       { name = "fnl"; text = ""; fg_dark = "#fff3d7"; fg_light = "#33312b"; }
    # #       { name = "fs"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "fsi"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "fsscript"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "fsx"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "gcode"; text = "󰐫"; fg_dark = "#1471ad"; fg_light = "#0f5582"; }
    # #       { name = "gd"; text = ""; fg_dark = "#6d8086"; fg_light = "#526064"; }
    # #       { name = "gemspec"; text = ""; fg_dark = "#701516"; fg_light = "#701516"; }
    # #       { name = "gif"; text = ""; fg_dark = "#a074c4"; fg_light = "#6b4d83"; }
    # #       { name = "git"; text = ""; fg_dark = "#f14c28"; fg_light = "#b5391e"; }
    # #       { name = "glb"; text = ""; fg_dark = "#ffb13b"; fg_light = "#80581e"; }
    # #       { name = "gnumakefile"; text = ""; fg_dark = "#6d8086"; fg_light = "#526064"; }
    # #       { name = "go"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "godot"; text = ""; fg_dark = "#6d8086"; fg_light = "#526064"; }
    # #       { name = "gql"; text = ""; fg_dark = "#e535ab"; fg_light = "#ac2880"; }
    # #       { name = "graphql"; text = ""; fg_dark = "#e535ab"; fg_light = "#ac2880"; }
    # #       { name = "gresource"; text = ""; fg_dark = "#ffffff"; fg_light = "#333333"; }
    # #       { name = "gv"; text = "󱁉"; fg_dark = "#30638e"; fg_light = "#244a6a"; }
    # #       { name = "gz"; text = ""; fg_dark = "#eca517"; fg_light = "#76520c"; }
    # #       { name = "h"; text = ""; fg_dark = "#a074c4"; fg_light = "#6b4d83"; }
    # #       { name = "haml"; text = ""; fg_dark = "#eaeae1"; fg_light = "#2f2f2d"; }
    # #       { name = "hbs"; text = ""; fg_dark = "#f0772b"; fg_light = "#a04f1d"; }
    # #       { name = "heex"; text = ""; fg_dark = "#a074c4"; fg_light = "#6b4d83"; }
    # #       { name = "hex"; text = ""; fg_dark = "#2e63ff"; fg_light = "#224abf"; }
    # #       { name = "hh"; text = ""; fg_dark = "#a074c4"; fg_light = "#6b4d83"; }
    # #       { name = "hpp"; text = ""; fg_dark = "#a074c4"; fg_light = "#6b4d83"; }
    # #       { name = "hrl"; text = ""; fg_dark = "#b83998"; fg_light = "#8a2b72"; }
    # #       { name = "hs"; text = ""; fg_dark = "#a074c4"; fg_light = "#6b4d83"; }
    # #       { name = "htm"; text = ""; fg_dark = "#e34c26"; fg_light = "#aa391c"; }
    # #       { name = "html"; text = ""; fg_dark = "#e44d26"; fg_light = "#ab3a1c"; }
    # #       { name = "huff"; text = "󰡘"; fg_dark = "#4242c7"; fg_light = "#4242c7"; }
    # #       { name = "hurl"; text = ""; fg_dark = "#ff0288"; fg_light = "#bf0266"; }
    # #       { name = "hx"; text = ""; fg_dark = "#ea8220"; fg_light = "#9c5715"; }
    # #       { name = "hxx"; text = ""; fg_dark = "#a074c4"; fg_light = "#6b4d83"; }
    # #       { name = "ical"; text = ""; fg_dark = "#2b2e83"; fg_light = "#2b2e83"; }
    # #       { name = "icalendar"; text = ""; fg_dark = "#2b2e83"; fg_light = "#2b2e83"; }
    # #       { name = "ico"; text = ""; fg_dark = "#cbcb41"; fg_light = "#666620"; }
    # #       { name = "ics"; text = ""; fg_dark = "#2b2e83"; fg_light = "#2b2e83"; }
    # #       { name = "ifb"; text = ""; fg_dark = "#2b2e83"; fg_light = "#2b2e83"; }
    # #       { name = "ifc"; text = "󰻫"; fg_dark = "#839463"; fg_light = "#576342"; }
    # #       { name = "ige"; text = "󰻫"; fg_dark = "#839463"; fg_light = "#576342"; }
    # #       { name = "iges"; text = "󰻫"; fg_dark = "#839463"; fg_light = "#576342"; }
    # #       { name = "igs"; text = "󰻫"; fg_dark = "#839463"; fg_light = "#576342"; }
    # #       { name = "image"; text = ""; fg_dark = "#d0bec8"; fg_light = "#453f43"; }
    # #       { name = "img"; text = ""; fg_dark = "#d0bec8"; fg_light = "#453f43"; }
    # #       { name = "import"; text = ""; fg_dark = "#ececec"; fg_light = "#2f2f2f"; }
    # #       { name = "info"; text = ""; fg_dark = "#ffffcd"; fg_light = "#333329"; }
    # #       { name = "ini"; text = ""; fg_dark = "#6d8086"; fg_light = "#526064"; }
    # #       { name = "ino"; text = ""; fg_dark = "#56b6c2"; fg_light = "#397981"; }
    # #       { name = "ipynb"; text = ""; fg_dark = "#51a0cf"; fg_light = "#366b8a"; }
    # #       { name = "iso"; text = ""; fg_dark = "#d0bec8"; fg_light = "#453f43"; }
    # #       { name = "ixx"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "java"; text = ""; fg_dark = "#cc3e44"; fg_light = "#992e33"; }
    # #       { name = "jl"; text = ""; fg_dark = "#a270ba"; fg_light = "#6c4b7c"; }
    # #       { name = "jpeg"; text = ""; fg_dark = "#a074c4"; fg_light = "#6b4d83"; }
    # #       { name = "jpg"; text = ""; fg_dark = "#a074c4"; fg_light = "#6b4d83"; }
    # #       { name = "js"; text = ""; fg_dark = "#cbcb41"; fg_light = "#666620"; }
    # #       { name = "json"; text = ""; fg_dark = "#cbcb41"; fg_light = "#666620"; }
    # #       { name = "json5"; text = ""; fg_dark = "#cbcb41"; fg_light = "#666620"; }
    # #       { name = "jsonc"; text = ""; fg_dark = "#cbcb41"; fg_light = "#666620"; }
    # #       { name = "jsx"; text = ""; fg_dark = "#20c2e3"; fg_light = "#158197"; }
    # #       { name = "jwmrc"; text = ""; fg_dark = "#0078cd"; fg_light = "#005a9a"; }
    # #       { name = "jxl"; text = ""; fg_dark = "#a074c4"; fg_light = "#6b4d83"; }
    # #       { name = "kbx"; text = "󰯄"; fg_dark = "#737672"; fg_light = "#565856"; }
    # #       { name = "kdb"; text = ""; fg_dark = "#529b34"; fg_light = "#3e7427"; }
    # #       { name = "kdbx"; text = ""; fg_dark = "#529b34"; fg_light = "#3e7427"; }
    # #       { name = "kdenlive"; text = ""; fg_dark = "#83b8f2"; fg_light = "#425c79"; }
    # #       { name = "kdenlivetitle"; text = ""; fg_dark = "#83b8f2"; fg_light = "#425c79"; }
    # #       { name = "kicad_dru"; text = ""; fg_dark = "#ffffff"; fg_light = "#333333"; }
    # #       { name = "kicad_mod"; text = ""; fg_dark = "#ffffff"; fg_light = "#333333"; }
    # #       { name = "kicad_pcb"; text = ""; fg_dark = "#ffffff"; fg_light = "#333333"; }
    # #       { name = "kicad_prl"; text = ""; fg_dark = "#ffffff"; fg_light = "#333333"; }
    # #       { name = "kicad_pro"; text = ""; fg_dark = "#ffffff"; fg_light = "#333333"; }
    # #       { name = "kicad_sch"; text = ""; fg_dark = "#ffffff"; fg_light = "#333333"; }
    # #       { name = "kicad_sym"; text = ""; fg_dark = "#ffffff"; fg_light = "#333333"; }
    # #       { name = "kicad_wks"; text = ""; fg_dark = "#ffffff"; fg_light = "#333333"; }
    # #       { name = "ko"; text = ""; fg_dark = "#dcddd6"; fg_light = "#494a47"; }
    # #       { name = "kpp"; text = ""; fg_dark = "#f245fb"; fg_light = "#a12ea7"; }
    # #       { name = "kra"; text = ""; fg_dark = "#f245fb"; fg_light = "#a12ea7"; }
    # #       { name = "krz"; text = ""; fg_dark = "#f245fb"; fg_light = "#a12ea7"; }
    # #       { name = "ksh"; text = ""; fg_dark = "#4d5a5e"; fg_light = "#3a4446"; }
    # #       { name = "kt"; text = ""; fg_dark = "#7f52ff"; fg_light = "#5f3ebf"; }
    # #       { name = "kts"; text = ""; fg_dark = "#7f52ff"; fg_light = "#5f3ebf"; }
    # #       { name = "lck"; text = ""; fg_dark = "#bbbbbb"; fg_light = "#5e5e5e"; }
    # #       { name = "leex"; text = ""; fg_dark = "#a074c4"; fg_light = "#6b4d83"; }
    # #       { name = "less"; text = ""; fg_dark = "#563d7c"; fg_light = "#563d7c"; }
    # #       { name = "lff"; text = ""; fg_dark = "#ececec"; fg_light = "#2f2f2f"; }
    # #       { name = "lhs"; text = ""; fg_dark = "#a074c4"; fg_light = "#6b4d83"; }
    # #       { name = "lib"; text = ""; fg_dark = "#4d2c0b"; fg_light = "#4d2c0b"; }
    # #       { name = "license"; text = ""; fg_dark = "#cbcb41"; fg_light = "#666620"; }
    # #       { name = "liquid"; text = ""; fg_dark = "#95bf47"; fg_light = "#4a6024"; }
    # #       { name = "lock"; text = ""; fg_dark = "#bbbbbb"; fg_light = "#5e5e5e"; }
    # #       { name = "log"; text = "󰌱"; fg_dark = "#dddddd"; fg_light = "#4a4a4a"; }
    # #       { name = "lrc"; text = "󰨖"; fg_dark = "#ffb713"; fg_light = "#805c0a"; }
    # #       { name = "lua"; text = ""; fg_dark = "#51a0cf"; fg_light = "#366b8a"; }
    # #       { name = "luac"; text = ""; fg_dark = "#51a0cf"; fg_light = "#366b8a"; }
    # #       { name = "luau"; text = ""; fg_dark = "#00a2ff"; fg_light = "#007abf"; }
    # #       { name = "m"; text = ""; fg_dark = "#599eff"; fg_light = "#3b69aa"; }
    # #       { name = "m3u"; text = "󰲹"; fg_dark = "#ed95ae"; fg_light = "#764a57"; }
    # #       { name = "m3u8"; text = "󰲹"; fg_dark = "#ed95ae"; fg_light = "#764a57"; }
    # #       { name = "m4a"; text = ""; fg_dark = "#00afff"; fg_light = "#0075aa"; }
    # #       { name = "m4v"; text = ""; fg_dark = "#fd971f"; fg_light = "#7e4c10"; }
    # #       { name = "magnet"; text = ""; fg_dark = "#a51b16"; fg_light = "#a51b16"; }
    # #       { name = "makefile"; text = ""; fg_dark = "#6d8086"; fg_light = "#526064"; }
    # #       { name = "markdown"; text = ""; fg_dark = "#dddddd"; fg_light = "#4a4a4a"; }
    # #       { name = "material"; text = "󰔉"; fg_dark = "#b83998"; fg_light = "#8a2b72"; }
    # #       { name = "md"; text = ""; fg_dark = "#dddddd"; fg_light = "#4a4a4a"; }
    # #       { name = "md5"; text = "󰕥"; fg_dark = "#8c86af"; fg_light = "#5d5975"; }
    # #       { name = "mdx"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "mint"; text = "󰌪"; fg_dark = "#87c095"; fg_light = "#44604a"; }
    # #       { name = "mjs"; text = ""; fg_dark = "#f1e05a"; fg_light = "#504b1e"; }
    # #       { name = "mk"; text = ""; fg_dark = "#6d8086"; fg_light = "#526064"; }
    # #       { name = "mkv"; text = ""; fg_dark = "#fd971f"; fg_light = "#7e4c10"; }
    # #       { name = "ml"; text = ""; fg_dark = "#e37933"; fg_light = "#975122"; }
    # #       { name = "mli"; text = ""; fg_dark = "#e37933"; fg_light = "#975122"; }
    # #       { name = "mm"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "mo"; text = "∞"; fg_dark = "#9772fb"; fg_light = "#654ca7"; }
    # #       { name = "mobi"; text = ""; fg_dark = "#eab16d"; fg_light = "#755836"; }
    # #       { name = "mov"; text = ""; fg_dark = "#fd971f"; fg_light = "#7e4c10"; }
    # #       { name = "mp3"; text = ""; fg_dark = "#00afff"; fg_light = "#0075aa"; }
    # #       { name = "mp4"; text = ""; fg_dark = "#fd971f"; fg_light = "#7e4c10"; }
    # #       { name = "mpp"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "msf"; text = ""; fg_dark = "#137be1"; fg_light = "#0e5ca9"; }
    # #       { name = "mts"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "mustache"; text = ""; fg_dark = "#e37933"; fg_light = "#975122"; }
    # #       { name = "nfo"; text = ""; fg_dark = "#ffffcd"; fg_light = "#333329"; }
    # #       { name = "nim"; text = ""; fg_dark = "#f3d400"; fg_light = "#514700"; }
    # #       { name = "nix"; text = ""; fg_dark = "#7ebae4"; fg_light = "#3f5d72"; }
    # #       { name = "nswag"; text = ""; fg_dark = "#85ea2d"; fg_light = "#427516"; }
    # #       { name = "nu"; text = ">"; fg_dark = "#3aa675"; fg_light = "#276f4e"; }
    # #       { name = "o"; text = ""; fg_dark = "#9f0500"; fg_light = "#9f0500"; }
    # #       { name = "obj"; text = "󰆧"; fg_dark = "#888888"; fg_light = "#5b5b5b"; }
    # #       { name = "ogg"; text = ""; fg_dark = "#0075aa"; fg_light = "#005880"; }
    # #       { name = "opus"; text = ""; fg_dark = "#0075aa"; fg_light = "#005880"; }
    # #       { name = "org"; text = ""; fg_dark = "#77aa99"; fg_light = "#4f7166"; }
    # #       { name = "otf"; text = ""; fg_dark = "#ececec"; fg_light = "#2f2f2f"; }
    # #       { name = "out"; text = ""; fg_dark = "#9f0500"; fg_light = "#9f0500"; }
    # #       { name = "part"; text = ""; fg_dark = "#44cda8"; fg_light = "#226654"; }
    # #       { name = "patch"; text = ""; fg_dark = "#41535b"; fg_light = "#41535b"; }
    # #       { name = "pck"; text = ""; fg_dark = "#6d8086"; fg_light = "#526064"; }
    # #       { name = "pcm"; text = ""; fg_dark = "#0075aa"; fg_light = "#005880"; }
    # #       { name = "pdf"; text = ""; fg_dark = "#b30b00"; fg_light = "#b30b00"; }
    # #       { name = "php"; text = ""; fg_dark = "#a074c4"; fg_light = "#6b4d83"; }
    # #       { name = "pl"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "pls"; text = "󰲹"; fg_dark = "#ed95ae"; fg_light = "#764a57"; }
    # #       { name = "ply"; text = "󰆧"; fg_dark = "#888888"; fg_light = "#5b5b5b"; }
    # #       { name = "pm"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "png"; text = ""; fg_dark = "#a074c4"; fg_light = "#6b4d83"; }
    # #       { name = "po"; text = ""; fg_dark = "#2596be"; fg_light = "#1c708e"; }
    # #       { name = "pot"; text = ""; fg_dark = "#2596be"; fg_light = "#1c708e"; }
    # #       { name = "pp"; text = ""; fg_dark = "#ffa61a"; fg_light = "#80530d"; }
    # #       { name = "ppt"; text = "󰈧"; fg_dark = "#cb4a32"; fg_light = "#983826"; }
    # #       { name = "prisma"; text = ""; fg_dark = "#5a67d8"; fg_light = "#444da2"; }
    # #       { name = "pro"; text = ""; fg_dark = "#e4b854"; fg_light = "#725c2a"; }
    # #       { name = "ps1"; text = "󰨊"; fg_dark = "#4273ca"; fg_light = "#325698"; }
    # #       { name = "psb"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "psd"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "psd1"; text = "󰨊"; fg_dark = "#6975c4"; fg_light = "#4f5893"; }
    # #       { name = "psm1"; text = "󰨊"; fg_dark = "#6975c4"; fg_light = "#4f5893"; }
    # #       { name = "pub"; text = "󰷖"; fg_dark = "#e3c58e"; fg_light = "#4c422f"; }
    # #       { name = "pxd"; text = ""; fg_dark = "#5aa7e4"; fg_light = "#3c6f98"; }
    # #       { name = "pxi"; text = ""; fg_dark = "#5aa7e4"; fg_light = "#3c6f98"; }
    # #       { name = "py"; text = ""; fg_dark = "#ffbc03"; fg_light = "#805e02"; }
    # #       { name = "pyc"; text = ""; fg_dark = "#ffe291"; fg_light = "#332d1d"; }
    # #       { name = "pyd"; text = ""; fg_dark = "#ffe291"; fg_light = "#332d1d"; }
    # #       { name = "pyi"; text = ""; fg_dark = "#ffbc03"; fg_light = "#805e02"; }
    # #       { name = "pyo"; text = ""; fg_dark = "#ffe291"; fg_light = "#332d1d"; }
    # #       { name = "pyx"; text = ""; fg_dark = "#5aa7e4"; fg_light = "#3c6f98"; }
    # #       { name = "qm"; text = ""; fg_dark = "#2596be"; fg_light = "#1c708e"; }
    # #       { name = "qml"; text = ""; fg_dark = "#40cd52"; fg_light = "#2b8937"; }
    # #       { name = "qrc"; text = ""; fg_dark = "#40cd52"; fg_light = "#2b8937"; }
    # #       { name = "qss"; text = ""; fg_dark = "#40cd52"; fg_light = "#2b8937"; }
    # #       { name = "query"; text = ""; fg_dark = "#90a850"; fg_light = "#607035"; }
    # #       { name = "r"; text = "󰟔"; fg_dark = "#2266ba"; fg_light = "#1a4c8c"; }
    # #       { name = "rake"; text = ""; fg_dark = "#701516"; fg_light = "#701516"; }
    # #       { name = "rar"; text = ""; fg_dark = "#eca517"; fg_light = "#76520c"; }
    # #       { name = "razor"; text = "󱦘"; fg_dark = "#512bd4"; fg_light = "#512bd4"; }
    # #       { name = "rb"; text = ""; fg_dark = "#701516"; fg_light = "#701516"; }
    # #       { name = "res"; text = ""; fg_dark = "#cc3e44"; fg_light = "#992e33"; }
    # #       { name = "resi"; text = ""; fg_dark = "#f55385"; fg_light = "#a33759"; }
    # #       { name = "rlib"; text = ""; fg_dark = "#dea584"; fg_light = "#6f5242"; }
    # #       { name = "rmd"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "rproj"; text = "󰗆"; fg_dark = "#358a5b"; fg_light = "#286844"; }
    # #       { name = "rs"; text = ""; fg_dark = "#dea584"; fg_light = "#6f5242"; }
    # #       { name = "rss"; text = ""; fg_dark = "#fb9d3b"; fg_light = "#7e4e1e"; }
    # #       { name = "sass"; text = ""; fg_dark = "#f55385"; fg_light = "#a33759"; }
    # #       { name = "sbt"; text = ""; fg_dark = "#cc3e44"; fg_light = "#992e33"; }
    # #       { name = "sc"; text = ""; fg_dark = "#cc3e44"; fg_light = "#992e33"; }
    # #       { name = "scad"; text = ""; fg_dark = "#f9d72c"; fg_light = "#53480f"; }
    # #       { name = "scala"; text = ""; fg_dark = "#cc3e44"; fg_light = "#992e33"; }
    # #       { name = "scm"; text = "󰘧"; fg_dark = "#eeeeee"; fg_light = "#303030"; }
    # #       { name = "scss"; text = ""; fg_dark = "#f55385"; fg_light = "#a33759"; }
    # #       { name = "sh"; text = ""; fg_dark = "#4d5a5e"; fg_light = "#3a4446"; }
    # #       { name = "sha1"; text = "󰕥"; fg_dark = "#8c86af"; fg_light = "#5d5975"; }
    # #       { name = "sha224"; text = "󰕥"; fg_dark = "#8c86af"; fg_light = "#5d5975"; }
    # #       { name = "sha256"; text = "󰕥"; fg_dark = "#8c86af"; fg_light = "#5d5975"; }
    # #       { name = "sha384"; text = "󰕥"; fg_dark = "#8c86af"; fg_light = "#5d5975"; }
    # #       { name = "sha512"; text = "󰕥"; fg_dark = "#8c86af"; fg_light = "#5d5975"; }
    # #       { name = "sig"; text = "λ"; fg_dark = "#e37933"; fg_light = "#975122"; }
    # #       { name = "signature"; text = "λ"; fg_dark = "#e37933"; fg_light = "#975122"; }
    # #       { name = "skp"; text = "󰻫"; fg_dark = "#839463"; fg_light = "#576342"; }
    # #       { name = "sldasm"; text = "󰻫"; fg_dark = "#839463"; fg_light = "#576342"; }
    # #       { name = "sldprt"; text = "󰻫"; fg_dark = "#839463"; fg_light = "#576342"; }
    # #       { name = "slim"; text = ""; fg_dark = "#e34c26"; fg_light = "#aa391c"; }
    # #       { name = "sln"; text = ""; fg_dark = "#854cc7"; fg_light = "#643995"; }
    # #       { name = "slvs"; text = "󰻫"; fg_dark = "#839463"; fg_light = "#576342"; }
    # #       { name = "sml"; text = "λ"; fg_dark = "#e37933"; fg_light = "#975122"; }
    # #       { name = "so"; text = ""; fg_dark = "#dcddd6"; fg_light = "#494a47"; }
    # #       { name = "sol"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "spec.js"; text = ""; fg_dark = "#cbcb41"; fg_light = "#666620"; }
    # #       { name = "spec.jsx"; text = ""; fg_dark = "#20c2e3"; fg_light = "#158197"; }
    # #       { name = "spec.ts"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "spec.tsx"; text = ""; fg_dark = "#1354bf"; fg_light = "#1354bf"; }
    # #       { name = "sql"; text = ""; fg_dark = "#dad8d8"; fg_light = "#494848"; }
    # #       { name = "sqlite"; text = ""; fg_dark = "#dad8d8"; fg_light = "#494848"; }
    # #       { name = "sqlite3"; text = ""; fg_dark = "#dad8d8"; fg_light = "#494848"; }
    # #       { name = "srt"; text = "󰨖"; fg_dark = "#ffb713"; fg_light = "#805c0a"; }
    # #       { name = "ssa"; text = "󰨖"; fg_dark = "#ffb713"; fg_light = "#805c0a"; }
    # #       { name = "ste"; text = "󰻫"; fg_dark = "#839463"; fg_light = "#576342"; }
    # #       { name = "step"; text = "󰻫"; fg_dark = "#839463"; fg_light = "#576342"; }
    # #       { name = "stl"; text = "󰆧"; fg_dark = "#888888"; fg_light = "#5b5b5b"; }
    # #       { name = "stp"; text = "󰻫"; fg_dark = "#839463"; fg_light = "#576342"; }
    # #       { name = "strings"; text = ""; fg_dark = "#2596be"; fg_light = "#1c708e"; }
    # #       { name = "styl"; text = ""; fg_dark = "#8dc149"; fg_light = "#466024"; }
    # #       { name = "sub"; text = "󰨖"; fg_dark = "#ffb713"; fg_light = "#805c0a"; }
    # #       { name = "sublime"; text = ""; fg_dark = "#e37933"; fg_light = "#975122"; }
    # #       { name = "suo"; text = ""; fg_dark = "#854cc7"; fg_light = "#643995"; }
    # #       { name = "sv"; text = "󰍛"; fg_dark = "#019833"; fg_light = "#017226"; }
    # #       { name = "svelte"; text = ""; fg_dark = "#ff3e00"; fg_light = "#bf2e00"; }
    # #       { name = "svg"; text = "󰜡"; fg_dark = "#ffb13b"; fg_light = "#80581e"; }
    # #       { name = "svh"; text = "󰍛"; fg_dark = "#019833"; fg_light = "#017226"; }
    # #       { name = "swift"; text = ""; fg_dark = "#e37933"; fg_light = "#975122"; }
    # #       { name = "t"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "tbc"; text = "󰛓"; fg_dark = "#1e5cb3"; fg_light = "#1e5cb3"; }
    # #       { name = "tcl"; text = "󰛓"; fg_dark = "#1e5cb3"; fg_light = "#1e5cb3"; }
    # #       { name = "templ"; text = ""; fg_dark = "#dbbd30"; fg_light = "#6e5e18"; }
    # #       { name = "terminal"; text = ""; fg_dark = "#31b53e"; fg_light = "#217929"; }
    # #       { name = "test.js"; text = ""; fg_dark = "#cbcb41"; fg_light = "#666620"; }
    # #       { name = "test.jsx"; text = ""; fg_dark = "#20c2e3"; fg_light = "#158197"; }
    # #       { name = "test.ts"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "test.tsx"; text = ""; fg_dark = "#1354bf"; fg_light = "#1354bf"; }
    # #       { name = "tex"; text = ""; fg_dark = "#3d6117"; fg_light = "#3d6117"; }
    # #       { name = "tf"; text = ""; fg_dark = "#5f43e9"; fg_light = "#4732af"; }
    # #       { name = "tfvars"; text = ""; fg_dark = "#5f43e9"; fg_light = "#4732af"; }
    # #       { name = "tgz"; text = ""; fg_dark = "#eca517"; fg_light = "#76520c"; }
    # #       { name = "tmux"; text = ""; fg_dark = "#14ba19"; fg_light = "#0f8c13"; }
    # #       { name = "toml"; text = ""; fg_dark = "#9c4221"; fg_light = "#753219"; }
    # #       { name = "torrent"; text = ""; fg_dark = "#44cda8"; fg_light = "#226654"; }
    # #       { name = "tres"; text = ""; fg_dark = "#6d8086"; fg_light = "#526064"; }
    # #       { name = "ts"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "tscn"; text = ""; fg_dark = "#6d8086"; fg_light = "#526064"; }
    # #       { name = "tsconfig"; text = ""; fg_dark = "#ff8700"; fg_light = "#aa5a00"; }
    # #       { name = "tsx"; text = ""; fg_dark = "#1354bf"; fg_light = "#1354bf"; }
    # #       { name = "ttf"; text = ""; fg_dark = "#ececec"; fg_light = "#2f2f2f"; }
    # #       { name = "twig"; text = ""; fg_dark = "#8dc149"; fg_light = "#466024"; }
    # #       { name = "txt"; text = "󰈙"; fg_dark = "#89e051"; fg_light = "#447028"; }
    # #       { name = "txz"; text = ""; fg_dark = "#eca517"; fg_light = "#76520c"; }
    # #       { name = "typoscript"; text = ""; fg_dark = "#ff8700"; fg_light = "#aa5a00"; }
    # #       { name = "ui"; text = ""; fg_dark = "#0c306e"; fg_light = "#0c306e"; }
    # #       { name = "v"; text = "󰍛"; fg_dark = "#019833"; fg_light = "#017226"; }
    # #       { name = "vala"; text = ""; fg_dark = "#7239b3"; fg_light = "#562b86"; }
    # #       { name = "vh"; text = "󰍛"; fg_dark = "#019833"; fg_light = "#017226"; }
    # #       { name = "vhd"; text = "󰍛"; fg_dark = "#019833"; fg_light = "#017226"; }
    # #       { name = "vhdl"; text = "󰍛"; fg_dark = "#019833"; fg_light = "#017226"; }
    # #       { name = "vim"; text = ""; fg_dark = "#019833"; fg_light = "#017226"; }
    # #       { name = "vsh"; text = ""; fg_dark = "#5d87bf"; fg_light = "#3e5a7f"; }
    # #       { name = "vsix"; text = ""; fg_dark = "#854cc7"; fg_light = "#643995"; }
    # #       { name = "vue"; text = ""; fg_dark = "#8dc149"; fg_light = "#466024"; }
    # #       { name = "wasm"; text = ""; fg_dark = "#5c4cdb"; fg_light = "#4539a4"; }
    # #       { name = "wav"; text = ""; fg_dark = "#00afff"; fg_light = "#0075aa"; }
    # #       { name = "webm"; text = ""; fg_dark = "#fd971f"; fg_light = "#7e4c10"; }
    # #       { name = "webmanifest"; text = ""; fg_dark = "#f1e05a"; fg_light = "#504b1e"; }
    # #       { name = "webp"; text = ""; fg_dark = "#a074c4"; fg_light = "#6b4d83"; }
    # #       { name = "webpack"; text = "󰜫"; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "wma"; text = ""; fg_dark = "#00afff"; fg_light = "#0075aa"; }
    # #       { name = "woff"; text = ""; fg_dark = "#ececec"; fg_light = "#2f2f2f"; }
    # #       { name = "woff2"; text = ""; fg_dark = "#ececec"; fg_light = "#2f2f2f"; }
    # #       { name = "wrl"; text = "󰆧"; fg_dark = "#888888"; fg_light = "#5b5b5b"; }
    # #       { name = "wrz"; text = "󰆧"; fg_dark = "#888888"; fg_light = "#5b5b5b"; }
    # #       { name = "x"; text = ""; fg_dark = "#599eff"; fg_light = "#3b69aa"; }
    # #       { name = "xaml"; text = "󰙳"; fg_dark = "#512bd4"; fg_light = "#512bd4"; }
    # #       { name = "xcf"; text = ""; fg_dark = "#635b46"; fg_light = "#4a4434"; }
    # #       { name = "xcplayground"; text = ""; fg_dark = "#e37933"; fg_light = "#975122"; }
    # #       { name = "xcstrings"; text = ""; fg_dark = "#2596be"; fg_light = "#1c708e"; }
    # #       { name = "xls"; text = "󰈛"; fg_dark = "#207245"; fg_light = "#207245"; }
    # #       { name = "xlsx"; text = "󰈛"; fg_dark = "#207245"; fg_light = "#207245"; }
    # #       { name = "xm"; text = ""; fg_dark = "#519aba"; fg_light = "#36677c"; }
    # #       { name = "xml"; text = "󰗀"; fg_dark = "#e37933"; fg_light = "#975122"; }
    # #       { name = "xpi"; text = ""; fg_dark = "#ff1b01"; fg_light = "#bf1401"; }
    # #       { name = "xul"; text = ""; fg_dark = "#e37933"; fg_light = "#975122"; }
    # #       { name = "xz"; text = ""; fg_dark = "#eca517"; fg_light = "#76520c"; }
    # #       { name = "yaml"; text = ""; fg_dark = "#6d8086"; fg_light = "#526064"; }
    # #       { name = "yml"; text = ""; fg_dark = "#6d8086"; fg_light = "#526064"; }
    # #       { name = "zig"; text = ""; fg_dark = "#f69a1b"; fg_light = "#7b4d0e"; }
    # #       { name = "zip"; text = ""; fg_dark = "#eca517"; fg_light = "#76520c"; }
    # #       { name = "zsh"; text = ""; fg_dark = "#89e051"; fg_light = "#447028"; }
    # #       { name = "zst"; text = ""; fg_dark = "#eca517"; fg_light = "#76520c"; }
    # #     ];
    # #     conds = [
    # #       # Special files
    # #       { "if" = "orphan"; text = ""; }
    # #       { "if" = "link"; text = ""; }
    # #       { "if" = "block"; text = ""; }
    # #       { "if" = "char"; text = ""; }
    # #       { "if" = "fifo"; text = ""; }
    # #       { "if" = "sock"; text = ""; }
    # #       { "if" = "sticky"; text = ""; }
    # #       { "if" = "dummy";  text = ""; }

    # #       # Fallback
    # #       { "if" = "dir"; text = "󰉋"; }
    # #       { "if" = "exec"; text = ""; }
    # #       { "if" = "!dir"; text = "󰈔"; }
    # #     ];
    # #   };
    # # };
    # settings = {
    #   manager = {
    #     #  3-element array
    #     ratio = [
    #       1 # parent
    #       3 # current
    #       4 # preview
    #     ];
    #     sort_by = "alphabetical";
    #     sort_sensitive = false;
    #     sort_reverse = false;
    #     sort_dir_first = true;
    #     sort_translit = false;
    #     linemode = "none";
    #     show_hidden = false;
    #     show_symlink = true;
    #     scrolloff = 5;
    #     mouse_events = [ "click" "scroll" ];
    #     title_format = "Yazi: {cwd}";
    #   };
    #   preview = {
    #     wrap = "no";
    #     tab_size = 2;
    #     max_width = 1200;
    #     max_height = 1800;
    #     cache_dir = "${config.home.homeDirectory}/.cache/yazi";
    #     image_delay = 5;
    #     # image_filter = "triangle";
    #     image_quality = 75;
    #     sixel_fraction = 15;
    #     ueberzug_scale = 1;
    #     ueberzug_offset = [ 0 0 0 0 ];
    #   };
    #   opener = {
    #     edit = [
    #       {
    #         run = ''nvim "$@"'';
    #         desc = "nvim";
    #         block = true;
    #         for = "unix";
    #       }
    #       {
    #         run = ''code %*'';
    #         orphan = true;
    #         desc = "code";
    #         for = "windows";
    #       }
    #       {
    #         run = ''code -w %*'';
    #         block = true;
    #         desc = "code (block)";
    #         for = "windows";
    #       }
    #     ];
    #     open = [
    #       {
    #         run = ''xdg-open "$1"'';
    #         desc = "Open";
    #         for = "linux";
    #       }
    #       {
    #         run = ''open "$@"'';
    #         desc = "Open";
    #         for = "macos";
    #       }
    #       {
    #         run = ''start "" "%1"'';
    #         orphan = true;
    #         desc = "Open";
    #         for = "windows";
    #       }
    #     ];
    #     reveal = [
    #       {
    #         run = ''xdg-open "$(dirname "$1")"'';
    #         desc = "Reveal";
    #         for = "linux";
    #       }
    #       {
    #         run = ''open -R "$1"'';
    #         desc = "Reveal";
    #         for = "macos";
    #       }
    #       {
    #         run = ''explorer /select,"%1"'';
    #         orphan = true;
    #         desc = "Reveal";
    #         for = "windows";
    #       }
    #       {
    #         run = ''exiftool "$1"; echo "Press enter to exit"; read _'';
    #         block = true;
    #         desc = "Show EXIF";
    #         for = "unix";
    #       }
    #     ];
    #     extract = [
    #       {
    #         run = ''ya pub extract --list "$@"'';
    #         desc = "Extract here";
    #         for = "unix";
    #       }
    #       {
    #         run = ''ya pub extract --list %*'';
    #         desc = "Extract here";
    #         for = "windows";
    #       }
    #     ];
    #     play = [
    #       {
    #         run = ''mpv --force-window "$@"'';
    #         orphan = true;
    #         for = "unix";
    #       }
    #       {
    #         run = ''mpv --force-window %*'';
    #         orphan = true;
    #         for = "windows";
    #       }
    #       {
    #         run = ''mediainfo "$1"; echo "Press enter to exit"; read _'';
    #         block = true;
    #         desc = "Show media info";
    #         for = "unix";
    #       }
    #     ];
    #   };
    #   open = {
    #     rules = [
    #       # Folder
    #       {
    #         name = "*/";
    #         use = [ "edit" "open" "reveal" ];
    #       }

    #       # Text
    #       {
    #         mime = "text/*";
    #         use = [ "edit" "reveal" ];
    #       }

    #       # Image
    #       {
    #         mime = "image/*";
    #         use = [ "open" "reveal" ];
    #       }

    #       # Media
    #       {
    #         mime = "{audio,video}/*";
    #         use = [ "play" "reveal" ];
    #       }

    #       # Archive
    #       {
    #         mime = "application/{,g}zip";
    #         use = [ "extract" "reveal" ];
    #       }

    #       {
    #         mime = "application/x-{tar,bzip*,7z-compressed,xz,rar}";
    #         use = [ "extract" "reveal" ];
    #       }

    #       # JSON
    #       {
    #         mime = "application/{json,x-ndjson}";
    #         use = [ "edit" "reveal" ];
    #       }

    #       {
    #         mime = "*/javascript";
    #         use = [ "edit" "reveal" ];
    #       }

    #       # Empty file
    #       {
    #         mime = "inode/x-empty";
    #         use = [ "edit" "reveal" ];
    #       }

    #       # Fallback
    #       {
    #         name = "*";
    #         use = [ "open" "reveal" ];
    #       }
    #     ];
    #   };
    #   tasks = {
    #     micro_workers = 10;
    #     macro_workers = 25;
    #     bizarre_retry = 5;
    #     image_alloc = 536870912;  # 512MB
    #     image_bound = [ 0 0 ];
    #     suppress_preload = false;
    #   };
    #   plugin = {
    #     prepend_fetchers = [
    #       # Mimetype
    #       # {
    #       #   id = "mime";
    #       #   "if" = "!mime";
    #       #   name = "*";
    #       #   run = "mime-ext";
    #       #   prio = "high";
    #       # }
    #     ];
    #     fetchers = [
    #       # Mimetype
    #       {
    #         id = "mime";
    #         name = "*";
    #         run = "mime";
    #         "if" = "!mime";
    #         prio = "high";
    #       }
    #     ];
    #     preloaders = [
    #       # Image
    #       {
    #         mime = "image/{avif,hei?,jxl,svg+xml}";
    #         run = "magick";
    #       }

    #       {
    #         mime = "image/*";
    #         run = "image";
    #       }

    #       # Video
    #       {
    #         mime = "video/*";
    #         run = "video";
    #       }

    #       # PDF
    #       {
    #         mime = "application/pdf";
    #         run = "pdf";
    #       }

    #       # Font
    #       {
    #         mime = "font/*";
    #         run = "font";
    #       }

    #       {
    #         mime = "application/vnd.ms-opentype";
    #         run = "font";
    #       }

    #     ];
    #     prepend_previewers = [
    #       {
    #         name = "*/";
    #         run = "eza-preview";
    #       }
    #       {
    #         mime = "{image,audio,video}/*";
    #         run = "mediainfo";
    #       }
    #       {
    #         mime = "application/x-subrip";
    #         run = "mediainfo";
    #       }
    #       {
    #         mime = "application/*zip";
    #         run = "ouch";
    #       }
    #       {
    #         mime = "application/x-tar";
    #         run = "ouch";
    #       }
    #       {
    #         mime = "application/x-bzip2";
    #         run = "ouch";
    #       }
    #       {
    #         mime = "application/x-7z-compressed";
    #         run = "ouch";
    #       }
    #       {
    #         mime = "application/x-rar";
    #         run = "ouch";
    #       }
    #       {
    #         mime = "application/x-xz";
    #         run = "ouch";
    #       }
    #       {
    #         mime = "application/vnd.excel";
    #         run = "excel";
    #       }
    #       {
    #         mime = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
    #         run = "excel";
    #       }
    #       {
    #         mime = "application/octet-stream";
    #         run = "hexyl";
    #       }
    #     ];
    #     previewers = [
    #       # Code
    #       {
    #         mime = "text/*";
    #         run = "code";
    #       }

    #       {
    #         mime = "*/{xml,javascript,x-wine-extension-ini}";
    #         run = "code";
    #       }

    #       # JSON
    #       {
    #         mime = "application/{json,x-ndjson}";
    #         run = "json";
    #       }

    #       # Image
    #       {
    #         mime = "image/{avif,hei?,jxl,svg+xml}";
    #         run = "magick";
    #       }

    #       {
    #         mime = "image/*";
    #         run = "image";
    #       }

    #       # Video
    #       {
    #         mime = "video/*";
    #         run = "video";
    #       }

    #       # PDF
    #       {
    #         mime = "application/pdf";
    #         run = "pdf";
    #       }

    #       # Archive
    #       {
    #         mime = "application/{,g}zip";
    #         run = "archive";
    #       }

    #       {
    #         mime = "application/x-{tar,bzip*,7z-compressed,xz,rar,iso9660-image}";
    #         run = "archive";
    #       }

    #       # Font
    #       {
    #         mime = "font/*";
    #         run = "font";
    #       }

    #       {
    #         mime = "application/vnd.ms-opentype";
    #         run = "font";
    #       }

    #       # Empty file
    #       {
    #         mime = "inode/x-empty";
    #         run = "empty";
    #       }

    #       # Fallback
    #       {
    #         name = "*";
    #         run = "file";
    #       }
    #     ];
    #   };
    #   input = {
    #     cursor_blink = false;

    #     # cd
    #     cd_title = "Change directory:";
    #     cd_origin = "top-center";
    #     cd_offset = [ 0 2 50 3 ];

    #     # create
    #     create_title = ["Create:" "Create (dir):"];
    #     create_origin = "top-center";
    #     create_offset = [ 0 2 50 3 ];

    #     # rename
    #     rename_title = "Rename:";
    #     rename_origin = "hovered";
    #     rename_offset = [ 0 1 50 3 ];

    #     # filter
    #     filter_title = "Filter:";
    #     filter_origin = "top-center";
    #     filter_offset = [ 0 2 50 3 ];

    #     # find
    #     find_title = [ "Find next:" "Find previous:" ];
    #     find_origin = "top-center";
    #     find_offset = [ 0 2 50 3 ];

    #     # search
    #     search_title = "Search via {n}:";
    #     search_origin = "top-center";
    #     search_offset = [ 0 2 50 3 ];

    #     # shell
    #     shell_title = [ "Shell:" "Shell (block):" ];
    #     shell_origin = "top-center";
    #     shell_offset = [ 0 2 50 3 ];
    #   };
    #   confirm = {
    #     # trash
    #     trash_title = "Trash {n} selected file{s}?";
    #     trash_origin = "center";
    #     trash_offset = [ 0 0 70 20 ];

    #     # delete
    #     delete_title = "Permanently delete {n} selected file{s}?";
    #     delete_origin = "center";
    #     delete_offset = [ 0 0 70 20 ];

    #     # overwrite
    #     overwrite_title = "Overwrite file?";
    #     overwrite_content = "Will overwrite the following file:";
    #     overwrite_origin = "center";
    #     overwrite_offset = [ 0 0 50 15 ];

    #     # quit
    #     quit_title = "Quit?";
    #     quit_content = "The following task is still running, are you sure you want to quit?";
    #     quit_origin = "center";
    #     quit_offset = [ 0 0 50 15 ];
    #   };
    #   select = {
    #     open_title = "Open with:";
    #     open_origin = "hovered";
    #     open_offset = [ 0 1 50 7 ];
    #   };
    #   which = {
    #     sort_by = "none";
    #     sort_sensitive = false;
    #     sort_reverse = false;
    #     sort_translit = false;
    #   };
    #   log = {
    #     enabled = true;
    #   };
    # };
  };
}
