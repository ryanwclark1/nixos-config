{
  lib,
  config,
  ...
}:

with lib; {
  options.chromium.enable = mkEnableOption "chrome settings";

  config = mkIf config.chromium.enable {
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
      # commandLineArgs = ["--ozone-platform-hint=wayland" "--gtk-version=4"];
      # commandLineArgs = [ "--enable-features=UseOzonePlatform" "--ozone-platform=wayland"];
    };
  };
}
