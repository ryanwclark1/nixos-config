{
  ...
}:

{
  imports = [
    # ./airplane_mode.nix
    # ./appname.nix
    # ./battery.nix
    # ./battery2.nix
    # ./brightness.nix
    # ./mem-ad.nix
    # ./memory.nix
    # ./music_info.nix
    # ./notifications.nix
    # ./pop.nix
    # ./screenshot.nix
    # ./search.nix
    # ./volume.nix
    # ./weather.nix
    # ./wifi.nix
    # ./wifi2.nix
    ./workspace_code.nix
    ./workspace.nix
    ./workspaces.nix
  ];

  home.file.".config/eww/scripts/airplane_mode.sh" = {
    source = ./airplane_mode.sh;
    executable = true;
  };

  home.file.".config/eww/scripts/appname.sh" = {
    source = ./appname.sh;
		executable = true;
	};

  home.file.".config/eww/scripts/battery.sh" = {
    source = ./battery.sh;
    executable = true;
  };

  home.file.".config/eww/scripts/battery2.sh" = {
    source = ./battery2.sh;
    executable = true;
  };

  home.file.".config/eww/scripts/brightness.sh" = {
    source = ./brightness.sh;
    executable = true;
  };

  home.file.".config/eww/scripts/mem-ad.sh" = {
    source = ./mem-ad.sh;
    executable = true;
  };

  home.file.".config/eww/scripts/memory.sh" = {
    source = ./memory.sh;
    executable = true;
  };

  home.file.".config/eww/scripts/music_info.sh" = {
    source = ./music_info.sh;
    executable = true;
  };

  home.file.".config/eww/scripts/notifications.sh" = {
    source = ./notifications.sh;
    executable = true;
  };

  home.file.".config/eww/scripts/pop.sh" = {
    source = ./pop.sh;
    executable = true;
  };

  home.file.".config/eww/scripts/screenshot.sh" = {
    source = ./screenshot.sh;
    executable = true;
  };

  home.file.".config/eww/scripts/search.sh" = {
    source = ./search.sh;
    executable = true;
  };

  home.file.".config/eww/scripts/volume.sh" = {
    source = ./volume.sh;
    executable = true;
  };

  home.file.".config/eww/scripts/weather.sh" = {
    source = ./weather.sh;
    executable = true;
  };

  home.file.".config/eww/scripts/wifi.sh" = {
    source = ./wifi.sh;
    executable = true;
  };

  home.file.".config/eww/scripts/wifi2.sh" = {
    source = ./wifi2.sh;
    executable = true;
  };

  home.file.".config/eww/scripts/workspace.lua" = {
    source = ./workspace.lua;
    executable = true;
  };

  home.file.".config/eww/scripts/workspace.sh" = {
    source = ./workspaces.sh;
    executable = true;
  };

  home.file.".config/eww/scripts/workspaces.sh" = {
    source = ./workspaces.sh;
    executable = true;
  };


}