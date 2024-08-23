{
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
    ./keymappings.nix
    ./autocommands.nix
    ./completion.nix
    ./todo.nix
    ./plugins
    ./lsp
  ];

  programs = {
    nixvim = {
      enable = true;
      defaultEditor = true;
      vimdiffAlias = true;
      enableMan = true;
      viAlias = true;
      vimAlias = true;
      package = pkgs.neovim-unwrapped;
      clipboard = {
        register = "unnamedplus";
        providers.wl-copy.enable = true;
      };
      colorschemes.base16.enable = true;
      luaLoader.enable = true;
      opts = {
        updatetime = 100; # Faster completion

        # Line numbers
        relativenumber = true; # Relative line numbers
        number = true; # Display the absolute line number of the current line
        hidden = true; # Keep closed buffer open in the background
        mouse = "a"; # Enable mouse control
        mousemodel = "extend"; # Mouse right-click extends the current selection
        splitbelow = true; # A new window is put below the current one
        splitright = true; # A new window is put right of the current one

        swapfile = false; # Disable the swap file
        modeline = true; # Tags such as 'vim:ft=sh'
        modelines = 100; # Sets the type of modelines
        undofile = true; # Automatically save and restore undo history
        incsearch = true; # Incremental search: show match for partly typed search command
        inccommand = "split"; # Search and replace: preview changes in quickfix list
        ignorecase = true; # When the search query is lower-case, match both lower and upper-case
        #   patterns
        smartcase = true; # Override the 'ignorecase' option if the search pattern contains upper
        #   case characters
        scrolloff = 8; # Number of screen lines to show around the cursor
        cursorline = false; # Highlight the screen line of the cursor
        cursorcolumn = false; # Highlight the screen column of the cursor
        signcolumn = "yes"; # Whether to show the signcolumn
        colorcolumn = "100"; # Columns to highlight
        laststatus = 3; # When to use a status line for the last window
        fileencoding = "utf-8"; # File-content encoding for the current buffer
        termguicolors = true; # Enables 24-bit RGB color in the |TUI|
        spell = false; # Highlight spelling mistakes (local to window)
        wrap = false; # Prevent text from wrapping

        # Tab options
        tabstop = 4; # Number of spaces a <Tab> in the text stands for (local to buffer)
        shiftwidth = 4; # Number of spaces used for each step of (auto)indent (local to buffer)
        expandtab = true; # Expand <Tab> to spaces in Insert mode (local to buffer)
        autoindent = true; # Do clever autoindenting

        textwidth = 0; # Maximum width of text that is being inserted.  A longer line will be
        #   broken after white space to get this width.

        # Folding
        foldlevel = 99; # Folds with a level higher than this number will be closed
      };

      # keymaps = [
      #   {
      #     key = "<CR>";
      #     action = "cmp.mapping.confirm({ select = true })";
      #   }
      #   {
      #     key = "<Tab>";
      #     action = ''
      #       function(fallback)
      #         if cmp.visible() then
      #           cmp.select_next_item()
      #         elseif luasnip.expandable() then
      #           luasnip.expand()
      #         elseif luasnip.expand_or_jumpable() then
      #           luasnip.expand_or_jump()
      #         elseif checkbackspace() then
      #           fallback()
      #         else
      #           fallback()
      #         end
      #       end
      #     '';
      #     mode = [ "i" "s" ];
      #   }
      # ];
    };
  };
}