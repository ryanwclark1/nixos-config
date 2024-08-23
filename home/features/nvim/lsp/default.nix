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
        dockerls = {
          enable = true;
        };
        docker-compose-language-service = {
          enable = true;
        };
        emmet-ls = {
          enable = true;
        };
        gopls = {
          enable = true;
        };
        graphql = {
          enable = true;
        };
        helm-ls = {
          enable = true;
        };
        html = {
          enable = true;
        };
        htmx = {
          enable = true;
        };
        jsonls = {
          enable = true;
        };
        jsonnet-ls = {
          enable = true;
        };
        lua-ls = {
          enable = true;
        };
        marksman = {
          enable = true;
        };
        nil-ls = {
          enable = false;
        };
        nixd = {
          enable = true;
        };
        pyright = {
          enable = true;
        };
        ruff = {
          enable = true;
        };
        rust-analyzer = {
          enable = true;
        };
        sqls = {
          enable = true;
        };
        tailwindcss = {
          enable = true;
        };
        templ = {
          enable = true;
        };
        tsserver = {
          enable = true;
        };
        typos-lsp = {
          enable = true;
        };

        # rust-analyzer.enable = true;
      };
    };
  };
}