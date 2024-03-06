{
  imports = [
    ./flameshot.nix
    # ./khal.nix
    ./khard.nix
    ./todoman.nix
    # ./vdirsyncer.nix
    ./mail.nix
    ./neomutt.nix
    ./office.nix
    ./zathura.nix

    # Pass feature is required
    ../pass
  ];
}
