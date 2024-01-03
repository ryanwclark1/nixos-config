{
  inputs,
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./colors.nix
    ./common.nix
    ./browsers.nix
    # ./chromium.nix
    ./firefox.nix
    ./fzf.nix
    # ./gh.nix
    ./git.nix
    ./gitui.nix
    ./go.nix
    ./grpc.nix
    ./htop.nix
    ./insomnia.nix
    ./lazygit.nix
    ./media.nix
    ./monitor.nix
    # ./neovim.nix
    ./nnn.nix
    ./obs.nix
    ./office.nix
    ./pandoc.nix
    ./pdf.nix
    ./protobuf.nix
    # ./spotify.nix
    ./sql.nix
    ./steam.nix
    ./syncthing.nix
    ./tmux.nix
    # ./transmission.nix
    ./vscode.nix
    ./xdg.nix
  ];
  go.enable = true;
  firefox.enable = true;
}
