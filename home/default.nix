{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
let
  d = config.xdg.dataHome;
  c = config.xdg.configHome;
  cache = config.xdg.cacheHome;
in
{
  imports = [
    ./pref.nix
    ./alacritty.nix
    ./alias.nix
    ./android_file_browser.nix
    ./asciidoc.nix
    ./atuin.nix
    ./audio.nix
    ./broot.nix
    ./build.nix
    ./carapace.nix
    # ./cliphist.nix
    ./colors.nix
    ./common.nix
    # ./communication.nix
    ./compression.nix
    ./chromium.nix
    ./deno.nix
    ./direnv.nix
    ./doc.nix
    ./download.nix
    ./exercism.nix
    ./firefox.nix
    ./filesearch.nix
    ./filezilla.nix
    ./fzf.nix
    ./git.nix
    ./gitui.nix
    ./global-fonts.nix
    ./go.nix
    ./graphical.nix
    ./grpc.nix
    ./insomnia.nix
    ./jq.nix
    ./just.nix
    ./lazygit.nix
    ./lf.nix
    ./media.nix
    ./monitor.nix
    ./music.nix
    ./neovim.nix
    ./nixdev.nix
    ./nnn.nix
    ./nushell.nix
    ./obs.nix
    ./office.nix
    ./ollama.nix
    ./pandoc.nix
    ./pdf.nix
    ./protobuf.nix
    ./pueue.nix
    ./ranger.nix
    ./rename.nix
    ./rust.nix
    ./slack.nix
    ./skim.nix
    # ./spotify.nix
    ./sql.nix
    ./starship.nix
    ./steam.nix
    ./syncthing.nix
    ./tmux.nix
    # ./transmission.nix
    ./video.nix
    ./vscode.nix
    ./watson.nix
    ./xdg.nix
    ./yt-dlp.nix
    ./bash.nix
    ./fish.nix
    ./zsh.nix
    ./helix.nix
  ];

  alacritty.enable = true;
  alias.enable = true;
  android.enable = true;
  asciidoc.enable = true;
  atuin.enable = true;
  audio.enable = true;
  brootFile.enable = true;
  build.enable = true;
  carapace.enable = true;
  chrome.enable = true;
  # cliphist.enable = true;
  compression.enable = true;
  deno.enable = true;
  direnv.enable = true;
  doc.enable = true;
  download.enable = true;
  exercism.enable = true;
  firefox.enable = true;
  filesearch.enable = true;
  filezilla.enable = true;
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
  monitor.enable = true;
  music.enable = true;
  nixdev.enable = true;
  nnn.enable = false;
  nushell.enable = true;
  obs.enable = true;
  office.enable = true;
  ollama.enable = true;
  pdf.enable = true;
  protobuf.enable = true;
  pueue.enable = true;
  ranger.enable = true;
  rename.enable = true;
  rust.enable = true;
  skim.enable = true;
  slack.enable = true;
  starship.enable = true;
  steam.enable = true;
  # syncthing.enable = true;
  sql.enable = true;
  tmux.enable = true;
  video.enable = true;
  watson.enable = true;
  yt-dlp.enable = true;

  # telegram.enable = false;
  # discord.enable = false;
  # slack.enable = true;


  bash.enable = true;
  fish.enable = true;
  zsh.enable = true;

  # neovim.enable = true;
  helix.enable = true;
  # shell.user = "${pkgs.bash}/bin/bash";
  # editor = {
  #   terminal = "${config.editor.helix.package}/bin/hx";
  #   helix.package = inputs.helix.packages.${pkgs.system}.default;
  # };
  # terminal = "${pkgs.alacritty}/bin/alacritty";

  home = {
    username = "administrator";
    homeDirectory = "/home/administrator";
    sessionVariables = {
      # clean up ~
      LESSHISTFILE = cache + "/less/history";
      LESSKEY = c + "/less/lesskey";
      WINEPREFIX = d + "/wine";

      # set default applications
      # EDITOR = "nvim";
      # BROWSER = "firefox";
      TERMINAL = "alacritty";

      # enable scrolling in git diff
      DELTA_PAGER = "less -R";

      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    };
  };

  programs.home-manager.enable = true;
}
