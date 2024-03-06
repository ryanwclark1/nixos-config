{
  inputs,
  ...
}:

{
  imports = [
    inputs.vscode-server.nixosModules.default
  ];

  services = {
    fwupd.enable = true;
    # fprintd = {
    #   enable = true;
    # };
    logind = {
      lidSwitch = "suspend";
      lidSwitchExternalPower = "lock";
    };
    vscode-server = {
      enable = true;
    };

  };

  powerManagement.powertop.enable = true;

  # security.pam.services.login.fprintAuth = true;
}
