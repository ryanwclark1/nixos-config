{
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
    ./plugins
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
      clipboard.providers.wl-copy.enable = true;
      plugins = {
        bufferline = {
          enable = true;
        };
        cmp = {
          enable = true;
          autoEnableSources = true;
        };
        lsp = {
          enable = true;
          servers = {
            dockerls.enable = true;
            emmet-ls = {
              enable = true;
            };
            gopls = {
              enable = true;
            };
            htmx = {
              enable = true;
            };
            jsonls = {
              enable = true;
            };
            pyright = {
              enable = true;
            };
            ruff = {
              enable = true;
            };
            templ = {
              enable = true;
            };
            tsserver = {
              enable = true;
            };
            lua-ls = {
              enable = true;
            };
            # rust-analyzer.enable = true;
          };
        };
        lualine = {
          enable = true;
        };
        luasnip = {
          enable = true;
        };
        # All commands available straight away
        telescope = {
          enable = true;
        };
        # Treesitter for syntax highlighting
        treesitter = {
          enable = true;
        };
        yazi = {
          enable = true;
        };
        zellij = {
          enable = true;
        };
      };
      keymaps = [
        {
          key = "<CR>";
          action = "cmp.mapping.confirm({ select = true })";
        }
        {
          key = "<Tab>";
          action = ''
            function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
              elseif luasnip.expandable() then
                luasnip.expand()
              elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
              elseif checkbackspace() then
                fallback()
              else
                fallback()
              end
            end
          '';
          mode = [ "i" "s" ];
        }
      ];
    };
  };
}