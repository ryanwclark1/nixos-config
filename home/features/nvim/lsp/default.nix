{
  ...
}:


{
  imports = [
    ./none-ls.nix
    # ./trouble.nix
  ];

  programs.nixvim = {
    plugins.lsp = {
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
  };
}