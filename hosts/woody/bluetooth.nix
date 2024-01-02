# ./host/woody/bluetooth.nix

{
  ...
}:


{
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;

    };
  };
}