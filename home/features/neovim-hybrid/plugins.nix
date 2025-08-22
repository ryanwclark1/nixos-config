{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Plugin configurations that can be managed via Nix
  home.file = {
    # LSP configuration
    ".config/nvim/lua/plugins/lsp.lua".text = ''
      return {
        {
          "neovim/nvim-lspconfig",
          event = { "BufReadPre", "BufNewFile" },
          dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            { "antosha417/nvim-lsp-file-operations", config = true },
          },
          config = function()
            local lspconfig = require("lspconfig")
            local cmp_nvim_lsp = require("cmp_nvim_lsp")
            
            -- LSP keymaps
            local keymap = vim.keymap
            local opts = { noremap = true, silent = true }
            
            local on_attach = function(client, bufnr)
              opts.buffer = bufnr
              
              -- Set keybinds
              opts.desc = "Show LSP references"
              keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)
              
              opts.desc = "Go to declaration"
              keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
              
              opts.desc = "Show LSP definitions"
              keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)
              
              opts.desc = "Show LSP implementations"
              keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)
              
              opts.desc = "Show LSP type definitions"
              keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)
              
              opts.desc = "See available code actions"
              keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
              
              opts.desc = "Smart rename"
              keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
              
              opts.desc = "Show buffer diagnostics"
              keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)
              
              opts.desc = "Show line diagnostics"
              keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)
              
              opts.desc = "Go to previous diagnostic"
              keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
              
              opts.desc = "Go to next diagnostic"
              keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
              
              opts.desc = "Show documentation for what is under cursor"
              keymap.set("n", "K", vim.lsp.buf.hover, opts)
              
              opts.desc = "Restart LSP"
              keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)
            end
            
            -- Used to enable autocompletion (assign to every lsp server config)
            local capabilities = cmp_nvim_lsp.default_capabilities()
            
            -- Configure LSP servers (these binaries are provided by nixpkgs)
            local servers = {
              "nixd",
              "nil_ls", 
              "lua_ls",
              "rust_analyzer",
              "gopls",
              "pyright",
              "ts_ls",
              "html",
              "cssls",
              "jsonls",
              "yamlls",
              "marksman",
              "terraformls",
              "ansiblels",
              "helm_ls",
              "dockerls",
              "docker_compose_language_service",
              "htmx",
              "jsonnet_ls",
              "ruff",
              "tailwindcss",
              "templ",
              "typos_lsp",
              "emmet_ls",
              "sqls",
            }
            
            for _, server in ipairs(servers) do
              lspconfig[server].setup({
                capabilities = capabilities,
                on_attach = on_attach,
              })
            end
            
            -- Special configurations for specific servers
            lspconfig.lua_ls.setup({
              capabilities = capabilities,
              on_attach = on_attach,
              settings = {
                Lua = {
                  diagnostics = {
                    globals = { "vim" },
                  },
                  workspace = {
                    library = {
                      [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                      [vim.fn.stdpath("config") .. "/lua"] = true,
                    },
                  },
                },
              },
            })
            
            -- Configure diagnostic display (using new API)
            local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
            for type, icon in pairs(signs) do
              local hl = "DiagnosticSign" .. type
              vim.diagnostic.config({
                signs = {
                  text = {
                    [vim.diagnostic.severity.ERROR] = signs.Error,
                    [vim.diagnostic.severity.WARN] = signs.Warn,
                    [vim.diagnostic.severity.HINT] = signs.Hint,
                    [vim.diagnostic.severity.INFO] = signs.Info,
                  },
                },
              })
            end
            
            vim.diagnostic.config({
              virtual_text = {
                prefix = "●",
              },
              update_in_insert = true,
              float = {
                source = "always",
              },
            })
          end,
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
                      local msg = "No Active Lsp"
                      local buf_ft = vim.api.nvim_buf_get_option(0, "filetype")
                      local clients = vim.lsp.get_active_clients()
                      if next(clients) == nil then
                        return msg
                      end
                      for _, client in ipairs(clients) do
                        local filetypes = client.config.filetypes
                        if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
                          return client.name
                        end
                      end
                      return msg
                    end,
                    icon = " LSP:",
                    color = { fg = "#ffffff", gui = "bold" },
                  },
                  "encoding",
                  "fileformat",
                  "filetype",
                },
              },
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
                python = { "isort", "black" },
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