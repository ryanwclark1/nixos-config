{
  ...
}:

{
  imports = [
    ./alpha.nix
    ./floaterm.nix
    ./harpoon.nix
    ./lualine.nix
    ./telescope.nix
    ./treesitter.nix
    ./vimtext.nix
  ];
  programs.nixvim = {
    plugins = {
      bufferline = {
        enable = true;
      };
      cmp = {
        enable = true;
        autoEnableSources = true;
      };
      luasnip = {
        enable = true;
      };
      yazi = {
        enable = true;
      };
      zellij = {
        enable = true;
      };
      gitsigns = {
        enable = true;
        settings.signs = {
          add.text = "+";
          change.text = "~";
        };
      };
      nvim-autopairs.enable = true;
      nvim-colorizer = {
        enable = true;
        userDefaultOptions.names = false;
      };
      oil.enable = true;
      trim = {
        enable = true;
        settings = {
          highlight = true;
          ft_blocklist = [
            "checkhealth"
            "floaterm"
            "lspinfo"
            "neo-tree"
            "TelescopePrompt"
          ];
        };
      };
    };
  };
}