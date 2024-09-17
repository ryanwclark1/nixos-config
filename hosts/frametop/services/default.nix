{
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    inputs.vscode-server.nixosModules.default
    ./auto-cpufreq.nix
    ./fprintd.nix
    ./framework-firmware.nix
    ./libinput.nix
    ./logind.nix
    ./upower.nix
  ];

  services = {
    vscode-server = {
      enable = true;
    };
  };


}
