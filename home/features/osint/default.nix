{ pkgs
, ...
}:

{

  imports = [
    # ./snoint.nix

  ];

  home.packages = with pkgs; [
    sn0int
  ];

}
