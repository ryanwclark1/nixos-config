{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    nil # Nix LSP
    nixfmt # Nix formatter
    nvd # Differ
    nix-output-monitor
    nh # Nice wrapper for NixOS and HM
    nurl # Generate Nix fetcher calls from repository URLs
  ];
}
