{
  pkgs,
  ...
}:

{
  home.packages = (with pkgs; [
    nodejs
    yarn
    # deno
  ])
  ++ (with pkgs.nodePackages; [
    npm
    pnpm
    ts-node
  ]);
  programs = {
    bun = {
      enable = true;
      package = pkgs.bun;
      enableGitIntegration = true;
    };
  };
}
