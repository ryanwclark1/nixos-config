{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./plugins.nix
  ];
  # Traditional Neovim configuration with nixpkgs integration
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    withNodeJs = false; # We handle Node.js separately
    withPython3 = true;
    withRuby = true;
    
    # Essential packages for neovim functionality
    # Note: LSP servers are now managed by Mason
    extraPackages = with pkgs; [
      # Core tools needed by neovim and plugins
      ripgrep               # Fast grep (required by Telescope)
      fd                    # Fast find (required by Telescope)
      tree-sitter           # Syntax highlighting
      git                   # Git integration
      
      # Clipboard support
      wl-clipboard          # Wayland clipboard
      xclip                 # X11 clipboard
      
      # Node.js for some plugins that need it
      nodejs                # Some plugins require Node.js
      
      # Keep essential formatters that Mason might not handle well
      nixpkgs-fmt           # Nix formatter (better to use system version)
      
      # Specialized language servers that work better from nixpkgs
      nil                   # Alternative Nix LSP (nixd is handled by Mason)
      terraform-ls          # Terraform LSP
      ansible-language-server # Ansible LSP  
      helm-ls               # Helm LSP
      docker-compose-language-service # Docker Compose LSP
      dockerfile-language-server-nodejs # Docker LSP
      htmx-lsp              # HTMX LSP
      jsonnet-language-server # Jsonnet LSP
      typos-lsp             # Typos LSP
    ];
    
    # Basic Neovim configuration
    extraLuaConfig = ''
      -- Load our custom configuration
      require('config')
    '';
  };
  
  # Create the Lua configuration directory structure
  home.file = {
    # Main configuration entry point
    ".config/nvim/lua/config/init.lua".text = ''
      -- Load all configuration modules
      require('config.options')
      require('config.keymaps')
      require('config.autocmds')
      require('config.lazy-bootstrap')
    '';
    
    # Enhanced options (migrated from nixvim)
    ".config/nvim/lua/config/options.lua".text = ''
      local opt = vim.opt
      
      -- Leader key
      vim.g.mapleader = " "
      vim.g.maplocalleader = " "
      
      -- Enhanced diagnostic signs
      vim.fn.sign_define("DiagnosticSignError", { text = " ", texthl = "DiagnosticError", linehl = "", numhl = "" })
      vim.fn.sign_define("DiagnosticSignWarn", { text = " ", texthl = "DiagnosticWarn", linehl = "", numhl = "" })
      vim.fn.sign_define("DiagnosticSignHint", { text = "󰌵", texthl = "DiagnosticHint", linehl = "", numhl = "" })
      vim.fn.sign_define("DiagnosticSignInfo", { text = " ", texthl = "DiagnosticInfo", linehl = "", numhl = "" })
      
      -- Basic settings
      opt.updatetime = 100                    -- Faster completion
      opt.number = true                       -- Show line numbers
      opt.relativenumber = true              -- Relative line numbers
      opt.hidden = true                      -- Keep closed buffer open in background
      opt.mouse = "a"                        -- Enable mouse control
      opt.mousemodel = "extend"              -- Mouse right-click extends selection
      opt.splitbelow = true                  -- New window below current
      opt.splitright = true                  -- New window right of current
      
      -- File handling
      opt.swapfile = false                   -- Disable swap file
      opt.backup = false                     -- Disable backup files
      opt.writebackup = false               -- Disable write backup
      opt.undofile = true                   -- Persistent undo history
      opt.modeline = true                   -- Enable modelines
      opt.modelines = 100                   -- Number of modelines to check
      
      -- Search settings
      opt.incsearch = true                  -- Incremental search
      opt.ignorecase = true                 -- Case insensitive search
      opt.smartcase = true                  -- Smart case sensitivity
      opt.hlsearch = false                  -- Don't highlight search results
      
      -- UI settings
      opt.cursorline = true                 -- Highlight cursor line
      opt.cursorcolumn = false              -- Don't highlight cursor column
      opt.signcolumn = "yes"                -- Always show sign column
      opt.colorcolumn = "100"               -- Highlight column 100
      opt.laststatus = 3                    -- Global statusline
      opt.showmode = false                  -- Don't show mode in cmdline
      opt.showtabline = 2                   -- Always show tabline
      opt.cmdheight = 0                     -- Hide command line when not used
      opt.pumheight = 10                    -- Popup menu height
      
      -- Indentation
      opt.tabstop = 2                       -- Tab width
      opt.shiftwidth = 2                    -- Indent width
      opt.softtabstop = 2                   -- Soft tab width
      opt.expandtab = true                  -- Use spaces instead of tabs
      opt.smartindent = true                -- Smart indentation
      opt.copyindent = true                 -- Copy indent structure
      opt.preserveindent = true             -- Preserve indent structure
      opt.breakindent = true                -- Wrap lines with indent
      
      -- Folding
      opt.foldlevel = 99                    -- High fold level
      opt.foldcolumn = "1"                  -- Show fold column
      opt.foldenable = true                 -- Enable folding
      opt.foldlevelstart = -1               -- Start with folds closed
      opt.fillchars = {
        horiz = "━", horizup = "┻", horizdown = "┳",
        vert = "┃", vertleft = "┫", vertright = "┣", verthoriz = "╋",
        eob = " ", diff = "╱", fold = " ", foldopen = "▼", foldclose = "▶",
        msgsep = "‾"
      }
      
      -- Performance
      opt.lazyredraw = false                -- Don't redraw during macros
      opt.synmaxcol = 240                   -- Max column for syntax highlight
      opt.timeoutlen = 500                  -- Key sequence timeout
      opt.updatetime = 100                  -- Faster completion
      
      -- Other settings
      opt.termguicolors = true              -- True color support
      opt.fileencoding = "utf-8"            -- File encoding
      opt.clipboard = "unnamedplus"         -- System clipboard
      opt.scrolloff = 8                     -- Lines to keep above/below cursor
      opt.splitkeep = "screen"              -- Keep screen position on split
      opt.completeopt = "menu,menuone,noselect"  -- Completion options
      opt.wrap = false                      -- Don't wrap lines
      opt.linebreak = true                  -- Break at word boundaries
      opt.showmatch = true                  -- Highlight matching brackets
      opt.matchtime = 1                     -- Duration of bracket highlight
      opt.startofline = true                -- Move to start of line with G, gg
      opt.report = 9001                     -- Disable "x more/fewer lines"
      opt.virtualedit = "block"             -- Virtual editing in visual block
      opt.title = true                      -- Set terminal title
      opt.history = 100                     -- Command history length
      opt.infercase = true                  -- Infer case for keyword completion
    '';
    
    # Enhanced keymaps (migrated from nixvim)
    ".config/nvim/lua/config/keymaps.lua".text = ''
      local keymap = vim.keymap.set
      
      -- Helper function for diagnostic navigation
      local function diagnostic_goto(next, severity)
        local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
        severity = severity and vim.diagnostic.severity[severity] or nil
        return function()
          go({ severity = severity })
        end
      end
      
      -- Better j/k navigation for wrapped lines
      keymap({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
      keymap({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
      keymap({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
      keymap({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
      
      -- Window navigation
      keymap("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
      keymap("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
      keymap("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
      keymap("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })
      
      -- Terminal window navigation
      keymap("t", "<C-h>", "<cmd>wincmd h<cr>", { desc = "Go to Left Window" })
      keymap("t", "<C-j>", "<cmd>wincmd j<cr>", { desc = "Go to Lower Window" })
      keymap("t", "<C-k>", "<cmd>wincmd k<cr>", { desc = "Go to Upper Window" })
      keymap("t", "<C-l>", "<cmd>wincmd l<cr>", { desc = "Go to Right Window" })
      keymap("t", "<C-/>", "<cmd>close<cr>", { desc = "Hide Terminal" })
      
      -- Window resizing
      keymap("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
      keymap("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
      keymap("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
      keymap("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })
      
      -- Move lines up and down
      keymap("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move Down" })
      keymap("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move Up" })
      keymap("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
      keymap("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
      keymap("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move Down" })
      keymap("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move Up" })
      
      -- Better indenting
      keymap("v", "<", "<gv", { desc = "Indent left" })
      keymap("v", ">", ">gv", { desc = "Indent right" })
      
      -- Undo breakpoints
      keymap("i", ";", ";<c-g>u")
      keymap("i", ".", ".<c-g>u")
      
      -- Save file
      keymap({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })
      
      -- Better escape
      keymap({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and Clear hlsearch" })
      keymap("n", "<leader>ur", "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>", { desc = "Redraw / Clear hlsearch / Diff Update" })
      
      -- Better search
      keymap("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
      keymap("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
      keymap("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
      keymap("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
      keymap("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
      keymap("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
      
      -- Diagnostic navigation
      keymap("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
      keymap("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
      keymap("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
      keymap("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
      keymap("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
      keymap("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
      keymap("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })
      
      -- Quit commands
      keymap("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })
      
      -- Utility
      keymap("n", "<leader>ui", vim.show_pos, { desc = "Inspect Pos" })
      
      -- Terminal mode
      keymap("t", "<esc><esc>", "<c-\\><c-n>", { desc = "Enter Normal Mode" })
      
      -- Window management
      keymap("n", "<leader>ww", "<C-W>p", { desc = "Other Window", remap = true })
      keymap("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })
      keymap("n", "<leader>w-", "<C-W>s", { desc = "Split Window Below", remap = true })
      keymap("n", "<leader>w|", "<C-W>v", { desc = "Split Window Right", remap = true })
      keymap("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
      keymap("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })
      
      -- Tab management
      keymap("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
      keymap("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
      keymap("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
      keymap("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
      keymap("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
      keymap("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })
    '';
    
    # Enhanced autocmds (migrated from nixvim)
    ".config/nvim/lua/config/autocmds.lua".text = ''
      local augroup = vim.api.nvim_create_augroup
      local autocmd = vim.api.nvim_create_autocmd
      
      -- Highlight on yank
      augroup("highlight_yank", { clear = true })
      autocmd("TextYankPost", {
        group = "highlight_yank",
        callback = function()
          vim.highlight.on_yank()
        end,
      })
      
      -- Resize splits if window got resized
      augroup("resize_splits", { clear = true })
      autocmd({ "VimResized" }, {
        group = "resize_splits",
        callback = function()
          vim.cmd("tabdo wincmd =")
        end,
      })
      
      -- Close some filetypes with <q>
      augroup("close_with_q", { clear = true })
      autocmd("FileType", {
        group = "close_with_q",
        pattern = {
          "PlenaryTestPopup",
          "help",
          "lspinfo",
          "man",
          "notify",
          "qf",
          "spectre_panel",
          "startuptime",
          "tsplayground",
          "neotest-output",
          "checkhealth",
          "neotest-summary",
          "neotest-output-panel",
          "alpha",
        },
        callback = function(event)
          vim.bo[event.buf].buflisted = false
          vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
        end,
      })
      
      -- Remove trailing whitespace
      augroup("TrimWhitespace", { clear = true })
      autocmd("BufWritePre", {
        group = "TrimWhitespace",
        pattern = "*",
        command = "%s/\\s\\+$//e",
      })
      
      -- Restore cursor position when opening a file
      augroup("restore_cursor", { clear = true })
      autocmd("BufReadPost", {
        group = "restore_cursor",
        callback = function()
          if
            vim.fn.line "'\"" > 1
            and vim.fn.line "'\"" <= vim.fn.line "$"
            and vim.bo.filetype ~= "commit"
            and vim.fn.index({ "xxd", "gitrebase" }, vim.bo.filetype) == -1
          then
            vim.cmd "normal! g`\""
          end
        end,
      })
      
      -- Disable indentscope for certain filetypes
      augroup("indentscope", { clear = true })
      autocmd("FileType", {
        group = "indentscope", 
        pattern = {
          "help", "alpha", "dashboard", "neo-tree", "Trouble", "trouble", 
          "lazy", "mason", "notify", "toggleterm", "lazyterm"
        },
        callback = function()
          vim.b.miniindentscope_disable = true
        end,
      })
    '';
    
    # Lazy.nvim bootstrap
    ".config/nvim/lua/config/lazy-bootstrap.lua".text = ''
      local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
      if not vim.loop.fs_stat(lazypath) then
        vim.fn.system({
          "git",
          "clone",
          "--filter=blob:none",
          "https://github.com/folke/lazy.nvim.git",
          "--branch=stable",
          lazypath,
        })
      end
      vim.opt.rtp:prepend(lazypath)
      
      -- Load plugins
      require("lazy").setup("plugins", {
        change_detection = {
          notify = false,
        },
      })
    '';
  };
}