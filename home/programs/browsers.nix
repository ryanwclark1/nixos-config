{
  pkgs,
  config,
  ...
}:

{
  programs = {
    chromium = {
      enable = true;
      commandLineArgs = ["--enable-features=TouchpadOverscrollHistoryNavigation" "--ozone-platform-hint=wayland" "--gtk-version=4"];
      extensions = [
        # {id = "";}  // extension id, query from chrome web store
        # "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
        # "dhdgffkkebhmkfjojejmpbldmpobfkfo" # Tampermonkey
        # "cojpndognjdcakkimaloeealehpkljna" # caretTab
        # "gjnmgffpgcigkfipakdijeonkoelhcdh" # rose pine
        # "eimadpbcbfnmbkopoojfekhnkhdbieeh" # dark reader
        # "nngceckbapebfimnlniiiahkandclblb" # bitwarden
        # "padekgcemlokbadohgkifijomclgjgif" # SwitchyOmega
        "ennpfpdlaclocpomkiablnmbppdnlhoh" # rust search engine
        # "cmpdlhmnmjhihmcfnigoememnffkimlk" # catppuccin-macchiato
        # "gnnhhfiajnkfjfnnojggfdlpjifhlmom" # word tune
        # "cdglnehniifkbagbbombnjghhcihifij" # kagi extension

        # "icpgjfneehieebagbmdbhnlpiopdcmna" # new tab redirect
      ];
    };

    firefox = {
      enable = true;
      profiles.administrator = {};
    };
  };
}
