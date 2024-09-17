{
  ...
}:

{
  services = {
    logind = {
      hibernateKey = "suspend-then-hibernate";
      hibernateKeyLongPress = "hibernate";
      lidSwitch = "suspend-then-hibernate";
      lidSwitchDocked = "ignore";
      lidSwitchExternalPower = "lock";
      powerKey = "poweroff";
      powerKeyLongPress = "reboot";
      suspendKey = "suspend";
      suspendKeyLongPress = "suspend-then-hibernate";
    };
  };
}