{
  lib,
  pkgs,
  ...
}:

{
  programs.nixvim.extraConfigLuaPre =
    # lua
    ''
      vim.fn.sign_define("diagnosticsignerror", { text = " ", texthl = "diagnosticerror", linehl = "", numhl = "" })
      vim.fn.sign_define("diagnosticsignwarn", { text = " ", texthl = "diagnosticwarn", linehl = "", numhl = "" })
      vim.fn.sign_define("diagnosticsignhint", { text = "󰌵", texthl = "diagnostichint", linehl = "", numhl = "" })
      vim.fn.sign_define("diagnosticsigninfo", { text = " ", texthl = "diagnosticinfo", linehl = "", numhl = "" })
    '';

  programs.nixvim.clipboard = {
    providers.wl-copy = {
      enable = true;
      package = pkgs.wl-clipboard;
    };
  };

  programs.nixvim.opts = {
    updatetime = 100; # Faster completion

    # Line numbers
    hidden = true; # Keep closed buffer open in the background
    mouse = "a"; # Enable mouse control
    mousemodel = "extend"; # Mouse right-click extends the current selection
    number = true; # Display the absolute line number of the current line
    relativenumber = true; # Relative line numbers
    splitbelow = true; # A new window is put below the current one
    splitright = true; # A new window is put right of the current one

    swapfile = false; # Disable the swap file
    modeline = true; # Tags such as 'vim:ft=sh'
    modelines = 100; # Sets the type of modelines
    undofile = true; # Automatically save and restore undo history
    incsearch = true; # Incremental search: show match for partly typed search command
    ignorecase = true; # When the search query is lower-case, match both lower and upper-case
    #   patterns
    smartcase = true; # Override the 'ignorecase' option if the search pattern contains upper
    #   case characters
    cursorline = true; # Highlight the screen line of the cursor
    cursorcolumn = false; # Highlight the screen column of the cursor
    signcolumn = "yes"; # Whether to show the signcolumn
    colorcolumn = "100"; # Columns to highlight
    laststatus = 3; # When to use a status line for the last window
    fileencoding = "utf-8"; # File-content encoding for the current buffer
    termguicolors = true; # Enables 24-bit RGB color in the |TUI|
    spelllang = lib.mkDefault [ "en_us" ]; # Spell check languages
    spell = false; # Highlight spelling mistakes (local to window)
    wrap = false; # Prevent text from wrapping

    # Tab Options
    tabstop = 2;
    shiftwidth = 2;
    softtabstop = 2;
    expandtab = true;
    smartindent = true;

    # Folding
    foldlevel = 99; # Folds with a level higher than this number will be closed
    foldcolumn = "1";
    foldenable = true;
    foldlevelstart = -1;
    fillchars = {
      horiz = "━";
      horizup = "┻";
      horizdown = "┳";
      vert = "┃";
      vertleft = "┫";
      vertright = "┣";
      verthoriz = "╋";

      eob = " ";
      diff = "╱";

      fold = " ";
      foldopen = "";
      foldclose = "";

      msgsep = "‾";
    };

    # backspace = { append = [ "nostop" ]; };
    breakindent = true;
    cmdheight = 0;
    copyindent = true;
    # diffopt = { append = [ "algorithm:histogram" "linematch:60" ]; };
    # fillchars = { eob = " "; };
    history = 100;
    infercase = true;
    linebreak = true;
    preserveindent = true;
    pumheight = 10;
    # shortmess = { append = { s = true; I = true; }; };
    showmode = false;
    showtabline = 2;
    timeoutlen = 500;
    title = true;
    # viewoptions = { remove = [ "curdir" ]; };
    virtualedit = "block";
    writebackup = false;

    lazyredraw = false; # Faster scrolling if enabled, breaks noice
    synmaxcol = 240; # Max column for syntax highlight
    showmatch = true; # when closing a bracket, briefly flash the matching one
    matchtime = 1; # duration of that flashing n deci-seconds
    startofline = true; # motions like "G" also move to the first char
    report = 9001; # disable "x more/fewer lines" messages

    clipboard = "unnamedplus";

    scrolloff = 8;
    splitkeep = "screen";
  };
}