{
  inputs,
  system,
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./browsers.nix
    # ./chromium.nix
    ./common.nix
    ./fzf.nix
    # ./gh.nix
    ./git.nix
    ./gitui.nix
    ./go.nix
    ./grpc.nix
    ./htop.nix
    ./insomnia.nix
    ./jq.nix
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
}
