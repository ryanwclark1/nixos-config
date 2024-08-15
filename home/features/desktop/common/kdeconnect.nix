{
  pkgs,
  ...
}:

let

  kdeconnect-cli = "${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnect-cli";
  fortune = "${pkgs.fortune}/bin/fortune";

  script-fortune = pkgs.writeShellScriptBin "fortune" ''
    ${kdeconnect-cli} -d $(${kdeconnect-cli} --list-available --id-only) --ping-msg "$(${fortune})"
  '';

in
{
  # Hide all .desktop, except for org.kde.kdeconnect.settings
  xdg.desktopEntries = {
    "org.kde.kdeconnect.sms" = {
      exec = "";
      name = "KDE Connect SMS";
      settings.NoDisplay = "true";
    };
    "org.kde.kdeconnect.nonplasma" = {
      exec = "";
      name = "KDE Connect Indicator";
      settings.NoDisplay = "true";
    };
    "org.kde.kdeconnect.app" = {
      exec = "";
      name = "KDE Connect";
      settings.NoDisplay = "true";
    };
  };

  services.kdeconnect = {
    enable = true;
    indicator = true;
    packages = with pkgs; [
      kdePackages.kdeconnect-kde
    ];
  };

  xdg.configFile = {
    "kdeconnect-scripts/fortune.sh".source = "${script-fortune}/bin/fortune";
  };

  networking.firewall = {
    allowedTCPPortRanges = [{ from = 1714; to = 1764; }];
    allowedUDPPortRanges = [{ from = 1714; to = 1764; }];
  };

}
