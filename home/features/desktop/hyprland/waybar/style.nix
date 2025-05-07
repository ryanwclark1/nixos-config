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
in {
  home.file.".config/waybar/colors.css" = {
    text = ''
      @define-color backgrounddark1 #${base00};
      @define-color backgrounddark2 #${base01};
      @define-color backgrounddark3 #${base02};
      @define-color bordercolor #FFFFFF;
      @define-color textcolor1 #${base05};
      @define-color textcolor2 #FFFFFF;
      @define-color textcolor3 #FFFFFF;
      @define-color iconcolor #${base0E};
      @define-color backgroundhex ${hexToRgba base00 "0.75"};

    '';
    executable = false;
  };
}
