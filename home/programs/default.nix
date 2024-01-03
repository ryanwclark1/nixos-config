{
  inputs,
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./alias.nix
    ./carapace.nix
    ./colors.nix
    ./common.nix
    ./compression.nix
    ./chromium.nix
    ./firefox.nix
    ./filesearch.nix
    ./fzf.nix
    # ./gh.nix
    ./git.nix
    ./gitui.nix
    ./global-fonts.nix
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
    ./skim.nix
    # ./spotify.nix
    ./sql.nix
    ./steam.nix
    ./syncthing.nix
    ./tmux.nix
    # ./transmission.nix
    ./vscode.nix
    ./xdg.nix
  ];
  alias.enable = true;
  carapace.enable = true;
  chrome.enable = true;
  compression.enable = true;
  firefox.enable = true;
  filesearch.enable = true;
  fzf.enable = true;
  go.enable = true;
  skim.enable = true;
}
