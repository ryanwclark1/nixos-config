{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Plugin configurations that can be managed via Nix
  home.file = {
    # LSP configuration is now handled in mason.lua
    # This file is kept for any custom LSP configurations that don't go through Mason
    ".config/nvim/lua/plugins/lsp.lua".text = ''
      return {
        -- Custom LSP configurations that bypass Mason can go here
        -- Most LSP setup is now handled by mason-lspconfig in mason.lua
        
        -- LSP file operations support
        {
          "antosha417/nvim-lsp-file-operations",
          dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-tree.lua",
          },
          config = true,
        },
      }
    '';
    
    # Completion configuration
    ".config/nvim/lua/plugins/completion.lua".text = ''
      return {
        {
          "hrsh7th/nvim-cmp",
          event = "InsertEnter",
          dependencies = {
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-nvim-lsp",
            "L3MON4D3/LuaSnip",
            "saadparwaiz1/cmp_luasnip",
            "rafamadriz/friendly-snippets",
            "onsails/lspkind.nvim",
          },
          config = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")
            local lspkind = require("lspkind")
            
            -- Load snippets from friendly-snippets
            require("luasnip.loaders.from_vscode").lazy_load()
            
            cmp.setup({
              completion = {
                completeopt = "menu,menuone,preview,noselect",
              },
              snippet = {
                expand = function(args)
                  luasnip.lsp_expand(args.body)
                end,
              },
              mapping = cmp.mapping.preset.insert({
                ["<C-k>"] = cmp.mapping.select_prev_item(),
                ["<C-j>"] = cmp.mapping.select_next_item(),
                ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                ["<C-f>"] = cmp.mapping.scroll_docs(4),
                ["<C-Space>"] = cmp.mapping.complete(),
                ["<C-e>"] = cmp.mapping.abort(),
                ["<CR>"] = cmp.mapping.confirm({ select = false }),
              }),
              sources = cmp.config.sources({
                { name = "nvim_lsp" },
                { name = "luasnip" },
                { name = "buffer" },
                { name = "path" },
              }),
              formatting = {
                format = lspkind.cmp_format({
                  maxwidth = 50,
                  ellipsis_char = "...",
                }),
              },
            })
          end,
        },
      }
    '';
    
    # Telescope configuration  
    ".config/nvim/lua/plugins/telescope.lua".text = ''
      return {
        {
          "nvim-telescope/telescope.nvim",
          branch = "0.1.x",
          dependencies = {
            "nvim-lua/plenary.nvim",
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
            "nvim-tree/nvim-web-devicons",
          },
          config = function()
            local telescope = require("telescope")
            local actions = require("telescope.actions")
            
            telescope.setup({
              defaults = {
                path_display = { "truncate" },
                mappings = {
                  i = {
                    ["<C-k>"] = actions.move_selection_previous,
                    ["<C-j>"] = actions.move_selection_next,
                    ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
                  },
                },
              },
            })
            
            telescope.load_extension("fzf")
            
            -- Set keymaps
            local keymap = vim.keymap
            
            keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy find files in cwd" })
            keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Fuzzy find recent files" })
            keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", { desc = "Find string in cwd" })
            keymap.set("n", "<leader>fc", "<cmd>Telescope grep_string<cr>", { desc = "Find string under cursor in cwd" })
          end,
        },
      }
    '';
    
    # File explorer
    ".config/nvim/lua/plugins/neo-tree.lua".text = ''
      return {
        {
          "nvim-neo-tree/neo-tree.nvim",
          branch = "v3.x",
          dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "MunifTanjim/nui.nvim",
          },
          config = function()
            require("neo-tree").setup({
              close_if_last_window = true,
              popup_border_style = "rounded",
              enable_git_status = true,
              enable_diagnostics = true,
              filesystem = {
                follow_current_file = {
                  enabled = true,
                },
                hijack_netrw_behavior = "open_current",
              },
            })
            
            vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { desc = "Toggle file explorer" })
          end,
        },
      }
    '';
    
    # Treesitter
    ".config/nvim/lua/plugins/treesitter.lua".text = ''
      return {
        {
          "nvim-treesitter/nvim-treesitter",
          event = { "BufReadPre", "BufNewFile" },
          build = ":TSUpdate",
          dependencies = {
            "windwp/nvim-autopairs",
          },
          config = function()
            local treesitter = require("nvim-treesitter.configs")
            
            treesitter.setup({
              highlight = { enable = true },
              indent = { enable = true },
              autopairs = { enable = true },
              ensure_installed = {
                "json",
                "javascript",
                "typescript",
                "tsx",
                "yaml",
                "html",
                "css",
                "markdown",
                "markdown_inline",
                "lua",
                "vim",
                "dockerfile",
                "gitignore",
                "query",
                "nix",
                "go",
                "rust",
                "python",
              },
              auto_install = false,
            })
          end,
        },
      }
    '';
    
    # Git integration
    ".config/nvim/lua/plugins/gitsigns.lua".text = ''
      return {
        {
          "lewis6991/gitsigns.nvim",
          event = { "BufReadPre", "BufNewFile" },
          config = function()
            require("gitsigns").setup({
              signs = {
                add = { text = "+" },
                change = { text = "~" },
                delete = { text = "_" },
                topdelete = { text = "‾" },
                changedelete = { text = "~" },
              },
            })
          end,
        },
      }
    '';
    
    # Status line
    ".config/nvim/lua/plugins/lualine.lua".text = ''
      return {
        {
          "nvim-lualine/lualine.nvim",
          dependencies = { "nvim-tree/nvim-web-devicons" },
          config = function()
            require("lualine").setup({
              options = {
                theme = "auto",
                globalstatus = true,
              },
              sections = {
                lualine_x = {
                  {
                    function()
                      local clients = vim.lsp.get_clients({ bufnr = 0 })
                      if #clients == 0 then
                        return "󱚧 No LSP"
                      end
                      
                      local client_names = {}
                      for _, client in ipairs(clients) do
                        table.insert(client_names, client.name)
                      end
                      
                      return " " .. table.concat(client_names, ", ")
                    end,
                    color = function()
                      local clients = vim.lsp.get_clients({ bufnr = 0 })
                      if #clients == 0 then
                        return { fg = "#f38ba8" }  -- Red for no LSP
                      else
                        return { fg = "#a6e3a1" }  -- Green for active LSP
                      end
                    end,
                  },
                  "encoding",
                  "fileformat",
                  "filetype",
                },
              },
            })
            
            -- Auto-refresh lualine when LSP clients attach/detach
            vim.api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
              callback = function()
                require("lualine").refresh()
              end,
            })
          end,
        },
      }
    '';
    
    # Colorscheme
    ".config/nvim/lua/plugins/colorscheme.lua".text = ''
      return {
        {
          "catppuccin/nvim",
          name = "catppuccin",
          priority = 1000,
          config = function()
            require("catppuccin").setup({
              flavour = "frappe",
              background = {
                light = "latte",
                dark = "frappe",
              },
              transparent_background = true,
              show_end_of_buffer = false,
              term_colors = false,
              dim_inactive = {
                enabled = false,
                shade = "dark",
                percentage = 0.15,
              },
              no_italic = false,
              no_bold = false,
              no_underline = false,
              styles = {
                comments = { "italic" },
                conditionals = { "italic" },
                loops = {},
                functions = {},
                keywords = {},
                strings = {},
                variables = {},
                numbers = {},
                booleans = {},
                properties = {},
                types = {},
                operators = {},
              },
              integrations = {
                cmp = true,
                gitsigns = true,
                nvimtree = true,
                treesitter = true,
                telescope = {
                  enabled = true,
                },
                lsp_trouble = false,
                which_key = false,
              },
            })
            
            vim.cmd.colorscheme("catppuccin")
          end,
        },
      }
    '';
    
    # Which-key for keybind help
    ".config/nvim/lua/plugins/which-key.lua".text = ''
      return {
        {
          "folke/which-key.nvim",
          event = "VeryLazy",
          init = function()
            vim.o.timeout = true
            vim.o.timeoutlen = 300
          end,
          config = function()
            require("which-key").setup({})
          end,
        },
      }
    '';
    
    # Alpha start screen
    ".config/nvim/lua/plugins/alpha.lua".text = ''
      return {
        {
          "goolord/alpha-nvim",
          event = "VimEnter",
          dependencies = { "nvim-tree/nvim-web-devicons" },
          config = function()
            local alpha = require("alpha")
            local dashboard = require("alpha.themes.dashboard")
            
            -- Set header with NEOVIM ASCII art
            dashboard.section.header.val = {
              "                                                     ",
              "  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
              "  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
              "  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
              "  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
              "  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
              "  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
              "                                                     ",
            }
            
            -- Set menu buttons
            dashboard.section.buttons.val = {
              dashboard.button("n", "󰈔  New File", "<cmd>ene<CR>"),
              dashboard.button("r", "󰋚  Recent Files", "<cmd>Telescope oldfiles<CR>"),
              dashboard.button("f", "󰈞  Find Files", "<cmd>Telescope find_files<CR>"),
              dashboard.button("w", "󰾹  Find Text", "<cmd>Telescope live_grep<CR>"),
              dashboard.button("e", "󰙅  File Explorer", "<cmd>Neotree toggle<CR>"),
              dashboard.button("c", "󰒓  Edit Config", "<cmd>edit ~/.config/nvim/lua/config/init.lua<CR>"),
              dashboard.button("l", "󰒲  Lazy", "<cmd>Lazy<CR>"),
              dashboard.button("m", "󰏗  Mason", "<cmd>Mason<CR>"),
              dashboard.button("q", "󰗼  Quit", "<cmd>qa<CR>"),
            }
            
            -- Footer with plugin count
            local function footer()
              local total_plugins = require("lazy").stats().count
              local datetime = os.date(" %Y-%m-%d   %H:%M:%S")
              local plugins_text = "   " .. total_plugins .. " plugins" .. datetime
              
              return plugins_text
            end
            
            dashboard.section.footer.val = footer()
            
            -- Disable folding on alpha buffer
            dashboard.config.opts.noautocmd = true
            
            -- Send config to alpha
            alpha.setup(dashboard.config)
            
            -- Custom highlight groups
            vim.api.nvim_set_hl(0, "AlphaHeader", { fg = "#89b4fa", bold = true })
            vim.api.nvim_set_hl(0, "AlphaButtons", { fg = "#cdd6f4" })
            vim.api.nvim_set_hl(0, "AlphaShortcut", { fg = "#fab387", bold = true })
            vim.api.nvim_set_hl(0, "AlphaFooter", { fg = "#6c7086", italic = true })
            
            -- Apply custom highlights
            dashboard.section.header.opts.hl = "AlphaHeader"
            dashboard.section.buttons.opts.hl = "AlphaButtons"
            dashboard.section.footer.opts.hl = "AlphaFooter"
            
            -- Disable statusline in dashboard
            vim.api.nvim_create_autocmd("User", {
              pattern = "AlphaReady",
              callback = function()
                vim.cmd [[
                  set showtabline=0 | autocmd BufUnload <buffer> set showtabline=2
                  set laststatus=0 | autocmd BufUnload <buffer> set laststatus=3
                ]]
              end,
            })
          end,
        },
      }
    '';
    
    # Mason for LSP server management
    ".config/nvim/lua/plugins/mason.lua".text = ''
      return {
        {
          "williamboman/mason.nvim",
          priority = 1000,
          cmd = { "Mason", "MasonInstall", "MasonUninstall", "MasonUpdate" },
          build = ":MasonUpdate",
          config = function()
            require("mason").setup({
              ui = {
                icons = {
                  package_installed = "✓",
                  package_pending = "➜",
                  package_uninstalled = "✗",
                },
              },
              install_root_dir = vim.fn.stdpath("data") .. "/mason",
            })
          end,
        },
        {
          "williamboman/mason-lspconfig.nvim",
          dependencies = { 
            "mason.nvim",
            "nvim-lspconfig",
          },
          priority = 999,
          config = function()
            local mason_lspconfig = require("mason-lspconfig")
            mason_lspconfig.setup({
              -- Automatically install these LSP servers
              ensure_installed = {
                "lua_ls",          -- Lua
                "nixd",            -- Nix  
                "yamlls",          -- YAML
                "jsonls",          -- JSON
                "html",            -- HTML
                "cssls",           -- CSS
                "tailwindcss",     -- Tailwind CSS
                "emmet_ls",        -- Emmet
                "pyright",         -- Python
                "ruff",            -- Python linting/formatting
                "rust_analyzer",   -- Rust
                "gopls",           -- Go
                "marksman",        -- Markdown
                "templ",           -- Templ
                "sqls",            -- SQL
              },
              -- Automatically install LSP servers when opening supported files
              automatic_installation = true,
            })
            
            -- Set up LSP configuration after VimEnter to ensure everything is loaded
            vim.api.nvim_create_autocmd("VimEnter", {
              callback = function()
                -- Add a small delay to ensure all plugins are fully loaded
                vim.defer_fn(function()
                  local lspconfig_ok, lspconfig = pcall(require, "lspconfig")
                  local cmp_ok, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
                  
                  if not lspconfig_ok or not cmp_ok then
                    vim.notify("LSP dependencies not available", vim.log.levels.WARN)
                    return
                  end
                  
                  local capabilities = cmp_nvim_lsp.default_capabilities()
                  
                  -- Common on_attach function
                  local function on_attach(client, bufnr)
                    local opts = { noremap = true, silent = true, buffer = bufnr }
                    vim.keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)
                    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
                    vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)
                    vim.keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)
                    vim.keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)
                    vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
                    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
                    vim.keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)
                    vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
                    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
                    vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
                    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
                    vim.keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)
                  end
                  
                  -- Set up handlers for automatic LSP configuration
                  mason_lspconfig.setup_handlers({
                    -- Default handler for all servers
                    function(server_name)
                      lspconfig[server_name].setup({
                        capabilities = capabilities,
                        on_attach = on_attach,
                      })
                    end,
                    
                    -- Custom configurations for specific servers
                    ["lua_ls"] = function()
                      lspconfig.lua_ls.setup({
                        capabilities = capabilities,
                        on_attach = on_attach,
                        settings = {
                          Lua = {
                            runtime = { version = 'LuaJIT' },
                            diagnostics = { globals = {'vim'} },
                            workspace = {
                              library = vim.api.nvim_get_runtime_file("", true),
                              checkThirdParty = false,
                            },
                            telemetry = { enable = false },
                          },
                        },
                      })
                    end,
                  })
                end, 100)
              end,
            })
          end,
        },
        {
          "neovim/nvim-lspconfig",
          event = { "BufReadPre", "BufNewFile" },
          dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "hrsh7th/cmp-nvim-lsp",
          },
          config = function()
            -- LSP setup is handled by the separate lsp-setup plugin below
            -- This just ensures nvim-lspconfig is loaded
          end,
        },
        {
          "WhoIsSethDaniel/mason-tool-installer.nvim",
          dependencies = { "mason.nvim" },
          config = function()
            require("mason-tool-installer").setup({
              ensure_installed = {
                -- Formatters
                "stylua",          -- Lua formatter
                "prettier",        -- JS/TS/HTML/CSS formatter
                "nixpkgs-fmt",     -- Nix formatter
                
                -- Linters  
                "eslint_d",        -- JS/TS linter
                "shellcheck",      -- Shell script linter
              },
              auto_update = false,
              run_on_start = true,
            })
          end,
        },
      }
    '';
    
    # ToggleTerm for terminal management
    ".config/nvim/lua/plugins/toggleterm.lua".text = ''
      return {
        {
          "akinsho/toggleterm.nvim",
          version = "*",
          config = function()
            require("toggleterm").setup({
              direction = "float",
              float_opts = {
                border = "rounded",
              },
              shading_factor = 2,
              size = 10,
              highlights = {
                Normal = { link = "Normal" },
                NormalNC = { link = "NormalNC" },
                NormalFloat = { link = "NormalFloat" },
                FloatBorder = { link = "FloatBorder" },
                StatusLine = { link = "StatusLine" },
                StatusLineNC = { link = "StatusLineNC" },
                WinBar = { link = "WinBar" },
                WinBarNC = { link = "WinBarNC" },
              },
              on_create = function(t)
                vim.opt_local.foldcolumn = "0"
                vim.opt_local.signcolumn = "no"
                if t.hidden then
                  vim.keymap.set({ "n", "t", "i" }, "<F7>", function() t:toggle() end, 
                    { desc = "Toggle terminal", buffer = t.bufnr })
                end
              end,
            })
            
            -- Keymaps
            vim.keymap.set("n", "<leader>tv", "<cmd>ToggleTerm direction=vertical<cr>", { desc = "Toggle Vertical Terminal" })
            vim.keymap.set("n", "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", { desc = "Toggle Horizontal Terminal" })
            vim.keymap.set("n", "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", { desc = "Toggle Floating Terminal" })
            vim.keymap.set("n", "<F7>", "<Cmd>execute v:count . 'ToggleTerm'<CR>", { desc = "Toggle terminal" })
            vim.keymap.set("t", "<F7>", "<Cmd>ToggleTerm<CR>", { desc = "Toggle terminal" })
            vim.keymap.set("i", "<F7>", "<Esc><Cmd>ToggleTerm<CR>", { desc = "Toggle terminal" })
            vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Switch to normal mode" })
          end,
        },
      }
    '';
    
    # Illuminate for highlighting word under cursor
    ".config/nvim/lua/plugins/illuminate.lua".text = ''
      return {
        {
          "RRethy/vim-illuminate",
          event = { "BufReadPre", "BufNewFile" },
          config = function()
            require("illuminate").configure({
              under_cursor = false,
              filetypes_denylist = {
                "Outline",
                "TelescopePrompt",
                "alpha",
                "harpoon",
                "reason",
                "neo-tree",
                "Trouble",
                "trouble",
              },
            })
          end,
        },
      }
    '';
    
    # Indent guides
    ".config/nvim/lua/plugins/indent-blankline.lua".text = ''
      return {
        {
          "lukas-reineke/indent-blankline.nvim",
          main = "ibl",
          event = { "BufReadPre", "BufNewFile" },
          config = function()
            require("ibl").setup({
              indent = {
                char = "│",
                tab_char = "│",
              },
              scope = { enabled = false },
              exclude = {
                filetypes = {
                  "help",
                  "alpha",
                  "dashboard",
                  "neo-tree",
                  "Trouble",
                  "trouble",
                  "lazy",
                  "mason",
                  "notify",
                  "toggleterm",
                },
              },
            })
          end,
        },
      }
    '';
    
    # Mini plugins for surround and indentscope
    ".config/nvim/lua/plugins/mini.lua".text = ''
      return {
        {
          "echasnovski/mini.nvim",
          version = false,
          config = function()
            -- Surround plugin
            require("mini.surround").setup()
            
            -- Indent scope
            require("mini.indentscope").setup({
              symbol = "│",
              options = { try_as_border = true },
            })
            
            -- Disable for certain filetypes
            vim.api.nvim_create_autocmd("FileType", {
              pattern = {
                "help", "alpha", "dashboard", "neo-tree", "Trouble", "trouble", "lazy", 
                "mason", "notify", "toggleterm", "lazyterm"
              },
              callback = function()
                vim.b.miniindentscope_disable = true
              end,
            })
          end,
        },
      }
    '';
    
    # Todo Comments
    ".config/nvim/lua/plugins/todo-comments.lua".text = ''
      return {
        {
          "folke/todo-comments.nvim",
          dependencies = { "nvim-lua/plenary.nvim" },
          event = { "BufReadPre", "BufNewFile" },
          config = function()
            require("todo-comments").setup({
              colors = {
                error = { "DiagnosticError", "ErrorMsg", "#ED8796" },
                warning = { "DiagnosticWarn", "WarningMsg", "#EED49F" },
                info = { "DiagnosticInfo", "#EED49F" },
                default = { "Identifier", "#F5A97F" },
                test = { "Identifier", "#8AADF4" },
              },
            })
          end,
        },
      }
    '';
    
    # Copilot Chat (AI assistance)
    ".config/nvim/lua/plugins/copilot.lua".text = ''
      return {
        {
          "CopilotC-Nvim/CopilotChat.nvim",
          dependencies = {
            { "github/copilot.vim" },
            { "nvim-lua/plenary.nvim" },
          },
          config = function()
            require("CopilotChat").setup({})
            
            -- Keymaps
            vim.keymap.set("n", "<leader>ct", "<CMD>CopilotChatToggle<CR>", { desc = "Toggle Copilot Chat" })
            vim.keymap.set("n", "<leader>cs", "<CMD>CopilotChatStop<CR>", { desc = "Stop Copilot output" })
            vim.keymap.set("n", "<leader>cr", "<CMD>CopilotChatReview<CR>", { desc = "Review selected code" })
            vim.keymap.set("n", "<leader>ce", "<CMD>CopilotChatExplain<CR>", { desc = "Explain selected code" })
            vim.keymap.set("n", "<leader>cd", "<CMD>CopilotChatDocs<CR>", { desc = "Add documentation" })
            vim.keymap.set("n", "<leader>cp", "<CMD>CopilotChatTests<CR>", { desc = "Add tests" })
          end,
        },
      }
    '';
    
    # Formatting
    ".config/nvim/lua/plugins/formatting.lua".text = ''
      return {
        {
          "stevearc/conform.nvim",
          lazy = true,
          event = { "BufReadPre", "BufNewFile" },
          config = function()
            local conform = require("conform")
            
            conform.setup({
              formatters_by_ft = {
                javascript = { "prettier" },
                typescript = { "prettier" },
                javascriptreact = { "prettier" },
                typescriptreact = { "prettier" },
                css = { "prettier" },
                html = { "prettier" },
                json = { "prettier" },
                yaml = { "prettier" },
                markdown = { "prettier" },
                lua = { "stylua" },
                python = { "ruff_fix", "ruff_format" },
                nix = { "nixpkgs-fmt" },
              },
              format_on_save = {
                lsp_fallback = true,
                async = false,
                timeout_ms = 1000,
              },
            })
            
            vim.keymap.set({ "n", "v" }, "<leader>mp", function()
              conform.format({
                lsp_fallback = true,
                async = false,
                timeout_ms = 1000,
              })
            end, { desc = "Format file or range (in visual mode)" })
          end,
        },
      }
    '';
  };
}