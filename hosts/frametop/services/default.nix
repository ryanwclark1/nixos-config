{
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    inputs.vscode-server.nixosModules.default
  ];

  services = {
    fwupd = {
      enable = true;
      package = pkgs.fwupd;
    };
    fprintd = {
      enable = true;
    };
    logind = {
      lidSwitch = "suspend";
      lidSwitchExternalPower = "lock";
    };
    vscode-server = {
      enable = true;
    };
    libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = false;
        scrollMethod = "twofinger";
      };
    };
};

  # Issues with kde powerdevil
  powerManagement.powertop.enable = true;

  security.pam.services.login.fprintAuth = true;
}
