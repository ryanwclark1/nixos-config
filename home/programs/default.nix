{
  inputs,
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./alias.nix
    ./broot.nix
    ./carapace.nix
    ./cliphist.nix
    ./colors.nix
    ./common.nix
    ./compression.nix
    ./chromium.nix
    ./deno.nix
    ./direnv.nix
    ./doc.nix
    ./download.nix
    ./firefox.nix
    ./filesearch.nix
    ./fzf.nix
    ./git.nix
    ./gitui.nix
    ./global-fonts.nix
    ./go.nix
    ./graphical.nix
    ./grpc.nix
    ./htop.nix
    ./insomnia.nix
    ./jq.nix
    ./just.nix
    ./lazygit.nix
    ./lf.nix
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
  brootFile.enable = true;
  carapace.enable = true;
  chrome.enable = true;
  cliphist.enable = true;
  compression.enable = true;
  deno.enable = true;
  direnv.enable = true;
  doc.enable = true;
  download.enable = true;
  firefox.enable = true;
  filesearch.enable = true;
  fzf.enable = true;
  git.enable = true;
  gitui.enable = true;
  go.enable = true;
  graphical.enable = true;
  grpc.enable = true;
  insomnia.enable = true;
  jq.enable = true;
  just.enable = true;
  lazygit.enable = true;
  lf.enable = true;
  skim.enable = true;
}
