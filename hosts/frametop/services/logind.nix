{
  ...
}:

{
  services.logind.settings.Login = {
    HandleHibernateKey = "suspend-then-hibernate";
    HandleHibernateKeyLongPress = "hibernate";
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "lock";
    HandlePowerKey = "poweroff";
    HandlePowerKeyLongPress = "reboot";
    HandleSuspendKey = "suspend";
    HandleSuspendKeyLongPress = "suspend-then-hibernate";
  };
}