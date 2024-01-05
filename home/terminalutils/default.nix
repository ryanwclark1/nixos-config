{
  pkgs,
  lib,
  config,
  ...
}:
with lib; {

  imports = [
    ./atuin.nix
    ./carapace.nix
    ./direnv.nix
    ./doc.nix
    ./filesearch.nix
    ./fzf.nix
    ./jq.nix
    ./lf.nix
    ./nnn.nix
    ./pager.nix
    ./pueue.nix
    ./ranger.nix
    ./rename.nix
    ./skim.nix
  ];

  options.terminalutils.enable = mkEnableOption "terminal utilities packages";
  config = mkIf config.terminalutils.enable {

    atuin.enable = true;
    carapace.enable = true;
    direnv.enable = true;
    doc.enable = true;
    filesearch.enable = true;
    fzf.enable = true;
    jq.enable = true;
    lf.enable = true;
    nnn.enable = false;
    pager.enable = false;
    pueue.enable = false;
    ranger.enable = false;
    rename.enable = false;
    skim.enable = false;
  };
}