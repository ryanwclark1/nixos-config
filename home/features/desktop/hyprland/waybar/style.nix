{ config, lib, ... }:
let
  inherit (lib) stringToCharacters reverseList imap0 foldl mod toLower;
  inherit (builtins) stringLength substring add;

  pow = base: exponent:
    if exponent > 1 then
      let
        x = pow base (exponent / 2);
        odd_exp = mod exponent 2 == 1;
      in
      x * x * (if odd_exp then base else 1)
    else if exponent == 1 then
      base
    else if exponent == 0 && base == 0 then
      throw "undefined"
    else if exponent == 0 then
      1
    else
      throw "undefined";

  hexToDecMap = {
    "0" = 0; "1" = 1; "2" = 2; "3" = 3; "4" = 4; "5" = 5;
    "6" = 6; "7" = 7; "8" = 8; "9" = 9; "a" = 10; "b" = 11;
    "c" = 12; "d" = 13; "e" = 14; "f" = 15;
  };

  hexCharToDec = hex:
    let lowerHex = toLower hex;
    in if stringLength hex != 1 then
      throw "Function only accepts a single character."
    else if hexToDecMap ? ${lowerHex} then
      hexToDecMap."${lowerHex}"
    else
      throw "Character ${hex} is not a hexadecimal value.";

  base16To10 = exponent: scalar: scalar * (pow 16 exponent);

  hexToDec = hex:
    let
      chars = stringToCharacters hex;
      reversed = reverseList chars;
      decimals = imap0 (i: c: base16To10 i (hexCharToDec c)) reversed;
    in foldl add 0 decimals;

  hexToRGB = hex:
    {
      r = hexToDec (substring 0 2 hex);
      g = hexToDec (substring 2 2 hex);
      b = hexToDec (substring 4 2 hex);
    };

  hexToRgba = hex: alpha:
    let rgb = hexToRGB hex;
    in "rgba(${toString rgb.r}, ${toString rgb.g}, ${toString rgb.b}, ${alpha})";


  base00 = "303446"; # base
  base01 = "292c3c"; # mantle
  base02 = "414559"; # surface0
  base03 = "51576d"; # surface1
  base04 = "626880"; # surface2
  base05 = "c6d0f5"; # text
  base06 = "f2d5cf"; # rosewater
  base07 = "babbf1"; # lavender
  base08 = "e78284"; # red
  base09 = "ef9f76"; # peach
  base0A = "e5c890"; # yellow
  base0B = "a6d189"; # green
  base0C = "81c8be"; # teal
  base0D = "8caaee"; # blue
  base0E = "ca9ee6"; # mauve
  base0F = "eebebe"; # flamingo
  base10 = "292c3c"; # mantle - darker background
  base11 = "232634"; # crust - darkest background
  base12 = "ea999c"; # maroon - bright red
  base13 = "f2d5cf"; # rosewater - bright yellow
  base14 = "a6d189"; # green - bright green
  base15 = "99d1db"; # sky - bright cyan
  base16 = "85c1dc"; # sapphire - bright blue
  base17 = "f4b8e4"; # pink - bright purple
in
 {
  home.file.".config/waybar/style.css" = {
    text = ''
      @define-color backgrounddark1 #${base00};
      @define-color backgrounddark2 #${base01};
      @define-color backgrounddark3 #${base02};
      @define-color bordercolor #FFFFFF;
      @define-color textcolor1 #${base05};
      @define-color textcolor3 #FFFFFF;
      @define-color iconcolor #${base0E};

      * {
        font-size: 16px;
        font-family: DejaVu Sans, UbuntuMono Nerd Font;
        font-weight: bold;
      }

      window#waybar {
        background-color: ${hexToRgba base00 "0.75"};
        color: @textcolor1;
        border: none;
        transition: background-color 0.5s;
      }

      window#waybar.hidden {
        opacity: 0.2;
      }

      .modules-left,
      .modules-center,
      .modules-right {
        padding: 0 15px;
        spacing: 10px;
      }

      .modules-left > widget,
      .modules-center > widget,
      .modules-right > widget {
        margin: 0 5px;
      }

      .modules-left > widget:hover,
      .modules-right > widget:hover {
        background-color: @backgrounddark3;
        border-radius: 6px;
        transition: background-color 0.3s ease-in-out;
      }

      #tray > * {
        transition: all 0.3s ease;
        margin: 0 5px;
      }

      #workspaces button {
        transition: all 0.3s cubic-bezier(.55,-0.68,.48,1.682);
      }

      #workspaces button.active {
        background-color: @backgrounddark3;
        border-radius: 6px;
        color: @textcolor3;
      }

      tooltip {
        background-color: ${hexToRgba base01 "0.95"};
        color: @textcolor1;
        padding: 12px 16px;
        font-size: 14px;
        font-weight: normal;
        border-radius: 8px;
        border: 1px solid @bordercolor;
      }

      #clock:hover,
      #battery:hover,
      #network:hover,
      #custom-exit:hover {
        background-color: @backgrounddark3;
        border-radius: 4px;
        transition: background-color 0.2s;
      }

      #battery.icon,
      #network.icon,
      #bluetooth.icon,
      #custom-nix-updates.icon,
      #custom-hyprbindings.icon,
      #custom-cliphist.icon {
        color: @iconcolor;
        font-size: 18px;
      }
    '';
    executable = false;
  };
}
