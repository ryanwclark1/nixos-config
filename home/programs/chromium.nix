{
  lib,
  config,
  ...
}:

with lib; {
  options.chrome.enable = mkEnableOption "chrome settings";

  config = mkIf config.chrome.enable {
    programs.chromium = {
      enable = true;
      extensions = [
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
        "cojpndognjdcakkimaloeealehpkljna" # caretTab
        "nngceckbapebfimnlniiiahkandclblb" # bitwarden
        "padekgcemlokbadohgkifijomclgjgif" # SwitchyOmega
        "cmpdlhmnmjhihmcfnigoememnffkimlk" # catppuccin-macchiato
        "gnnhhfiajnkfjfnnojggfdlpjifhlmom" # word tune
        "cdglnehniifkbagbbombnjghhcihifij" # kagi extension
        "icpgjfneehieebagbmdbhnlpiopdcmna" # new tab redirect
      ];
      commandLineArgs = ["--ozone-platform-hint=wayland" "--gtk-version=4"];
    };
  };
}
