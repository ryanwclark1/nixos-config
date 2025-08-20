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
    
    # Essential packages that your LSP servers need
    extraPackages = with pkgs; [
      # Language servers (managed by nixpkgs)
      nixd                    # Nix LSP
      nil                     # Alternative Nix LSP
      lua-language-server     # Lua LSP
      rust-analyzer           # Rust LSP
      gopls                   # Go LSP
      pyright                 # Python LSP
      nodePackages.typescript-language-server  # TypeScript/JavaScript LSP
      nodePackages.vscode-langservers-extracted # HTML/CSS/JSON LSP
      yaml-language-server    # YAML LSP
      marksman               # Markdown LSP
      terraform-ls           # Terraform LSP
      ansible-language-server # Ansible LSP
      helm-ls                # Helm LSP
      docker-compose-language-service # Docker Compose LSP
      dockerfile-language-server-nodejs # Docker LSP
      htmx-lsp               # HTMX LSP
      jsonnet-language-server # Jsonnet LSP
      ruff                   # Python linting (includes LSP)
      tailwindcss-language-server # Tailwind CSS
      templ                  # Templ LSP
      typos-lsp              # Typos LSP
      emmet-ls               # Emmet LSP
      sqls                   # SQL LSP
      
      # Formatters and linters
      stylua                 # Lua formatter
      nixpkgs-fmt           # Nix formatter
      black                 # Python formatter
      isort                 # Python import sorter
      prettier              # JS/TS/HTML/CSS formatter
      eslint_d              # JS/TS linter
      
      # Tools
      ripgrep               # Fast grep
      fd                    # Fast find
      tree-sitter           # Syntax highlighting
      git                   # Git integration
      
      # Clipboard support
      wl-clipboard          # Wayland clipboard
      xclip                 # X11 clipboard
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
    
    # Basic options
    ".config/nvim/lua/config/options.lua".text = ''
      local opt = vim.opt
      
      -- Leader key
      vim.g.mapleader = " "
      vim.g.maplocalleader = " "
      
      -- Basic settings
      opt.number = true
      opt.relativenumber = true
      opt.tabstop = 2
      opt.shiftwidth = 2
      opt.expandtab = true
      opt.smartindent = true
      opt.wrap = false
      opt.swapfile = false
      opt.backup = false
      opt.hlsearch = false
      opt.incsearch = true
      opt.termguicolors = true
      opt.scrolloff = 8
      opt.signcolumn = "yes"
      opt.updatetime = 50
      opt.colorcolumn = "80"
      opt.cursorline = true
      
      -- Clipboard integration
      opt.clipboard = "unnamedplus"
      
      -- Split settings
      opt.splitbelow = true
      opt.splitright = true
      
      -- Completion
      opt.completeopt = "menu,menuone,noselect"
      
      -- Mouse support
      opt.mouse = "a"
      
      -- Case insensitive searching UNLESS /C or capital in search
      opt.ignorecase = true
      opt.smartcase = true
      
      -- Decrease update time
      opt.updatetime = 250
      opt.timeoutlen = 300
      
      -- Enable break indent
      opt.breakindent = true
      
      -- Save undo history
      opt.undofile = true
    '';
    
    # Keymaps
    ".config/nvim/lua/config/keymaps.lua".text = ''
      local keymap = vim.keymap.set
      
      -- Better window navigation
      keymap("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
      keymap("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
      keymap("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
      keymap("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })
      
      -- Resize with arrows
      keymap("n", "<C-Up>", ":resize -2<CR>", { desc = "Increase window height" })
      keymap("n", "<C-Down>", ":resize +2<CR>", { desc = "Decrease window height" })
      keymap("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width" })
      keymap("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase window width" })
      
      -- Navigate buffers
      keymap("n", "<S-l>", ":bnext<CR>", { desc = "Next buffer" })
      keymap("n", "<S-h>", ":bprevious<CR>", { desc = "Previous buffer" })
      
      -- Clear highlights
      keymap("n", "<leader>h", "<cmd>nohlsearch<CR>", { desc = "Clear highlights" })
      
      -- Better indenting
      keymap("v", "<", "<gv", { desc = "Indent left" })
      keymap("v", ">", ">gv", { desc = "Indent right" })
      
      -- Move text up and down
      keymap("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
      keymap("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })
      
      -- Stay in visual mode when indenting
      keymap("v", "<", "<gv")
      keymap("v", ">", ">gv")
      
      -- Diagnostic keymaps
      keymap("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
      keymap("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
      keymap("n", "<leader>e", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
      keymap("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })
    '';
    
    # Autocmds
    ".config/nvim/lua/config/autocmds.lua".text = ''
      local augroup = vim.api.nvim_create_augroup
      local autocmd = vim.api.nvim_create_autocmd
      
      -- Highlight on yank
      augroup("YankHighlight", { clear = true })
      autocmd("TextYankPost", {
        group = "YankHighlight",
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