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
        # "dhdgffkkebhmkfjojejmpbldmpobfkfo" # Tampermonkey
        "cojpndognjdcakkimaloeealehpkljna" # caretTab
        # "gjnmgffpgcigkfipakdijeonkoelhcdh" # rose pine
        # "eimadpbcbfnmbkopoojfekhnkhdbieeh" # dark reader
        "nngceckbapebfimnlniiiahkandclblb" # bitwarden
        "padekgcemlokbadohgkifijomclgjgif" # SwitchyOmega
        # "ennpfpdlaclocpomkiablnmbppdnlhoh" # rust search engine
        "cmpdlhmnmjhihmcfnigoememnffkimlk" # catppuccin-macchiato
        "gnnhhfiajnkfjfnnojggfdlpjifhlmom" # word tune
        "cdglnehniifkbagbbombnjghhcihifij" # kagi extension

        "icpgjfneehieebagbmdbhnlpiopdcmna" # new tab redirect
      ];
      commandLineArgs = ["--ozone-platform-hint=wayland" "--gtk-version=4"];
    };
  };
}
