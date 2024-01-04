{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {
  options.neovim.enable = mkEnableOption "neovim settings";

  config = mkIf config.neovim.enable {
    programs.nixvim = {
      enable = true;
      # Configuration that can be only in the form of lua file
      extraConfigLua = builtins.readFile ./nvim.lua;

      # WARN: lua loader is experimental.
      luaLoader.enable = true;

      # Use wl-copy for clipboard provider
      clipboard.providers.wl-copy.enable = true;

      ###############################
      # Colorschemes
      ###############################

      colorschemes.catppuccin = {
        enable = true;
        flavour = "macchiato";
        terminalColors = true;
        showBufferEnd = true;
        integrations = {
          indent_blankline = {
            enabled = true;
            colored_indent_levels = true;
          };
          native_lsp.enabled = true;
        };
      };

      ###############################
      # plugins
      ###############################
      extraPlugins = with pkgs.vimPlugins; [
        rose-pine
        oxocarbon-nvim
        poimandres-nvim
        nord-nvim
        nightfox-nvim
        nightfly
        material-nvim
        falcon
        adwaita-nvim
        tokyonight-nvim
        gruvbox-nvim
        everforest
        kanagawa-nvim
      ];

      plugins = {
        ### Completion

        cmp_luasnip.enable = true;
        cmp-path.enable = true;
        cmp-treesitter.enable = true;
        cmp-nvim-lsp.enable = true;
        cmp-nvim-lsp-document-symbol.enable = true;
        cmp-nvim-lsp-signature-help.enable = true;
        cmp-nvim-lua.enable = true;
        nvim-cmp = {
          enable = true;
          sources = [
            {name = "nvim_lsp_signature_help";}
            {name = "nvim_lsp";}
            {name = "nvim_lsp_document_symbol";}
            {name = "path";}
            {name = "luasnip";}
          ];
          mappingPresets = ["insert"];
          mapping = {
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<Tab>" = {
              action = ''
                function(fallback)
                  if cmp.visible() then
                    cmp.select_next_item()
                  elseif require("luasnip").expandable() then
                    require("luasnip").expand()
                  elseif require("luasnip").expand_or_jumpable() then
                    require("luasnip").expand_or_jump()
                  elseif check_backspace() then
                    fallback()
                  else
                    fallback()
                  end
                end
              '';
              modes = [
                "i"
                "s"
              ];
            };
            "<s-Tab>" = {
              action = ''
                function(fallback)
                  if cmp.visible() then
                    cmp.select_previous_item()
                  elseif require("luasnip").expandable() then
                    require("luasnip").expand()
                  elseif require("luasnip").expand_or_jumpable() then
                    require("luasnip").expand_or_jump()
                  elseif check_backspace() then
                    fallback()
                  else
                    fallback()
                  end
                end
              '';
              modes = [
                "i"
                "s"
              ];
            };
          };
          formatting.fields = ["kind" "abbr" "menu"];
          snippet.expand = "luasnip";
        };

        luasnip = {
          enable = true;
          fromLua = [{paths = ./snippet.lua;}];
          extraConfig = {
            history = true;
            # for dynamic snippets it updates  as we type
            updateevents = "TextChanged,TextChangedI";
            enable_autosnippets = true;
          };
        };

        ### Utils
        harpoon = {
          enable = true;
          enableTelescope = true;
          keymaps = {
            addFile = "<leader>haf";
            navPrev = "<leader>hp";
            navNext = "<leader>hn";
          };
        };

        nvim-tree = {
          enable = true;
          disableNetrw = true;
          hijackCursor = true;
          respectBufCwd = true;
          syncRootWithCwd = true;
          diagnostics = {
            enable = true;
            showOnDirs = true;
          };
          git = {
            enable = true;
            ignore = false;
          };
          modified = {
            enable = true;
          };
          updateFocusedFile = {
            enable = true;
          };
        };

        telescope = {
          enable = true;
          keymapsSilent = true;
          keymaps = {
            "<leader>/" = "live_grep";
            "<leader>f" = "find_files";
            "<leader>b" = "buffers";
            "<leader>d" = "diagnostics";
            "<C-p>" = {
              action = "git_files";
              desc = "Telescope Git Files";
            };
          };
          extensions = {
            file_browser.enable = true;
            undo.enable = true;
          };
        };

        floaterm = {
          enable = true;
          shell = "fish";
          wintype = "split";
          keymaps.toggle = "<c-\\>";
          width = 1.0;
        };

        ### Git

        # fugitive.enable = true;
        diffview.enable = true;
        # gitgutter.enable = true;
        gitsigns.enable = true;
        neogit = {
          enable = true;
          integrations.diffview = true;
        };

        ### Languages

        ## Nix

        hmts.enable = true;
        nix.enable = true;
        nix-develop.enable = true;

        ## Rust

        rust-tools = {
          enable = true;
          server.check.command = "clippy";
        };

        crates-nvim.enable = true;

        ## Zig
        zig.enable = true;

        ### TreeSitter
        treesitter = {
          enable = true;
          nixGrammars = true;
          indent = true;
          incrementalSelection.enable = true;
          nixvimInjections = true;
          moduleConfig.highlight = {
            additional_vim_regex_highlighting = ["org"];
            enable = true;
            disable = ["pug"];
          };
        };

        treesitter-refactor = {
          enable = true;
          highlightCurrentScope.enable = false;
          highlightDefinitions.enable = true;
        };

        ts-autotag.enable = true;
        ts-context-commentstring.enable = true;

        ### UI
        rainbow-delimiters.enable = true;
        fidget.enable = true;
        noice = {
          enable = true;
          lsp.override = {
            "vim.lsp.util.convert_input_to_markdown_lines" = true;
            "vim.lsp.util.stylize_markdown" = true;
            "cmp.entry.get_documentation" = true;
          };
        };
        lsp-lines = {
          enable = true;
          currentLine = true;
        };
        indent-blankline.enable = true;
        trouble.enable = true;
        lualine = {
          enable = true;
          extensions = ["fzf" "symbols-outline" "trouble" "nvim-tree" "quickfix"];
          componentSeparators.left = "|";
          componentSeparators.right = "|";
          sectionSeparators.left = "▒";
          sectionSeparators.right = "▒";
          sections = {
            lualine_a = ["mode"];
            lualine_b = ["branch" "diagnostics"];
            lualine_c = [""];
            lualine_x = [""];
            lualine_y = [""];
            lualine_z = ["location"];
          };
          tabline = {
            lualine_a = ["buffers"];
            lualine_b = [""];
            lualine_c = [""];
            lualine_x = [""];
            lualine_y = [""];
            lualine_z = ["tabs"];
          };
        };

        notify.enable = true;
        which-key.enable = true;
        nvim-colorizer.enable = true;
        nvim-bqf.enable = true;

        ### LSP

        lsp = {
          enable = true;
          servers = {
            bashls.enable = true;
            cssls.enable = true;
            efm.enable = true;
            html.enable = true;
            jsonls.enable = true;
            lua-ls.enable = true;
            rust-analyzer = {
              enable = true;
              installCargo = false;
              installRustc = false;
              settings = {
                checkOnSave = true;
                check.command = "clippy";
              };
            };
            gopls.enable = true;
            zls.enable = true;
            nil_ls = {
              enable = true;
              settings = {
                formatting.command = ["${pkgs.alejandra}/bin/bin" "--quiet"];
              };
            };
            nixd.enable = true;
            yamlls.enable = true;
          };

          onAttach = ''
            vim.cmd [[autocmd BufWritePre <buffer> lua vim.lsp.buf.format()]]
          '';
          keymaps = {
            diagnostic = {
              "<leader>k" = "goto_prev";
              "<leader>j" = "goto_next";
            };
            lspBuf = {
              "gd" = "definition";
              "gD" = "references";
              "<leder>lt" = "type_definition";
              "gi" = "implementation";
              "K" = "hover";
              "<leader>k" = "hover";
              "<leader>r" = "rename";
            };
          };
        };

        lsp-format = {
          enable = true;
          setup = {
            nil_ls = {
              sync = true;
              force = true;
            };
          };
        };

        # none-ls = {
        #   enable = true;
        #   sources = {
        #     code_actions = {
        #       # gitsigns.enable = true;
        #       shellcheck.enable = true;
        #     };
        #     diagnostics = {
        #       deadnix.enable = true;
        #       gitlint.enable = true;
        #       luacheck.enable = true;
        #       protolint.enable = true;
        #       shellcheck.enable = true;
        #     };
        #     formatting = {
        #       alejandra.enable = true;
        #       gofmt.enable = true;
        #       jq.enable = true;
        #       markdownlint.enable = true;
        #       prettier_d_slim.enable = true;
        #       protolint.enable = true;
        #       rustfmt.enable = true;
        #       sqlfluff.enable = true;
        #       shfmt.enable = true;
        #       stylua.enable = true;
        #       taplo.enable = true;
        #     };
        #   };
        # };

        lspsaga = {
          enable = true;
          lightbulb.enable = false;
        };

        lspkind = {
          enable = true;
          mode = "symbol_text";
          cmp.ellipsisChar = "…";
          cmp.menu = {
            buffer = "[Buffer]";
            nvim_lsp = "[LSP]";
            luasnip = "[LuaSnip]";
            nvim_lua = "[Lua]";
            latex_symbols = "[Latex]";
          };
          cmp.after = ''
            function(entry, vim_item, kind)
              local strings = vim.split(kind.kind, "%s", { trimempty = true })
              if #strings == 2 then
                kind.kind = " " .. strings[1] .. " "
                kind.menu = "   " .. strings[2]
              end

              return kind
            end
          '';
        };

        ### Editing

        nvim-autopairs.enable = true;
        undotree.enable = true;
        surround.enable = true;
        comment-nvim = {
          enable = true;
          toggler = {line = "<C-c>";};
        };
      }; # end of plugins

      ###############################
      # Options
      ###############################
      options = {
        number = true;
        relativenumber = true;
        shiftwidth = 2;
        tabstop = 2;
        smartindent = true;
        expandtab = true;
        smartcase = true;
        undodir = "/home/administrator/.cache/nvim/undodir";
        undofile = true;
        clipboard = "unnamedplus";
        wrap = false;
        termguicolors = true;
        ignorecase = true;
        showmode = false;
      };

      ###############################
      # Keymaps
      ###############################

      globals = {
        mapleader = " ";
        maplocalleader = " ";
      };
      keymaps = [
        {
          key = "<leader>w";
          action = "<CMD>:w<CR>";
          mode = "n";
        }
        {
          key = "<leader>s";
          action = "<CMD>Telescope lsp_dynamic_workspace_symbols<CR>";
          mode = "n";
        }
        {
          key = "<leader>lr";
          action = "<CMD>Telescope lsp_references<CR>";
          mode = "n";
        }
        {
          key = "<leader>gg";
          action = "<CMD>Neogit<CR>";
          mode = "n";
        }
        {
          key = "<leader>gc";
          action = "<CMD>Neogit commit<CR>";
          mode = "n";
        }

        {
          key = "<S-Right>";
          action = "<CMD>bnext<CR>";
          mode = "n";
        }
        {
          key = "<s-left>";
          action = "<CMD>bprevious<CR>";
          mode = "n";
        }
        {
          key = "<leader>c";
          action = "<CMD>bdelete<CR>";
          mode = "n";
        }
        {
          key = "<leader>e";
          action = "<CMD>NvimTreeToggle<CR>";
          mode = "n";
        }
        {
          key = "<leader>a";
          action = "<CMD>Lspsaga code_action<CR>";
          mode = "n";
        }
        {
          key = "<leader>a";
          action = "<CMD>Lspsaga code_action<CR>";
          mode = "n";
        }

        {
          key = "<leader>xx";
          action = "<cmd>TroubleToggle<cr>";
          mode = "n";
        }
        {
          key = "<leader>xw";
          action = "<cmd>TroubleToggle workspace_diagnostics<cr>";
          mode = "n";
        }
        {
          key = "<leader>xd";
          action = "<cmd>TroubleToggle document_diagnostics<cr>";
          mode = "n";
        }
        {
          key = "<leader>xq";
          action = "<cmd>TroubleToggle quickfix<cr>";
          mode = "n";
        }
        {
          key = "<leader>xl";
          action = "<cmd>TroubleToggle loclist<cr>";
          mode = "n";
        }
        {
          key = "gR";
          action = "<cmd>TroubleToggle lsp_references<cr>";
          mode = "n";
        }
      ];
    };
  };
}