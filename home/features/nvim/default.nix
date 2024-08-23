{
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
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
      clipboard.providers.wl-copy.enable = true;
      colorschemes.base16.enable = true;
      plugins = {
        bufferline = {
          enable = true;
        };
        cmp = {
          enable = true;
          autoEnableSources = true;
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