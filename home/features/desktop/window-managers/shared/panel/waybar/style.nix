{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    stringToCharacters
    reverseList
    imap0
    foldl
    mod
    toLower
    ;
  inherit (builtins) stringLength substring add;

  pow =
    base: exponent:
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
    "0" = 0;
    "1" = 1;
    "2" = 2;
    "3" = 3;
    "4" = 4;
    "5" = 5;
    "6" = 6;
    "7" = 7;
    "8" = 8;
    "9" = 9;
    "a" = 10;
    "b" = 11;
    "c" = 12;
    "d" = 13;
    "e" = 14;
    "f" = 15;
  };

  hexCharToDec =
    hex:
    let
      lowerHex = toLower hex;
    in
    if stringLength hex != 1 then
      throw "Function only accepts a single character."
    else if hexToDecMap ? ${lowerHex} then
      hexToDecMap."${lowerHex}"
    else
      throw "Character ${hex} is not a hexadecimal value.";

  base16To10 = exponent: scalar: scalar * (pow 16 exponent);

  hexToDec =
    hex:
    let
      chars = stringToCharacters hex;
      reversed = reverseList chars;
      decimals = imap0 (i: c: base16To10 i (hexCharToDec c)) reversed;
    in
    foldl add 0 decimals;

  hexToRGBMap = hex: {
    r = hexToDec (substring 0 2 hex);
    g = hexToDec (substring 2 2 hex);
    b = hexToDec (substring 4 2 hex);
  };

  hexToRGB =
    hex:
    let
      rgb = hexToRGBMap hex;
    in
    "${toString rgb.r} ${toString rgb.g} ${toString rgb.b}";

  hexToRGBA =
    hex: alpha:
    let
      rgb = hexToRGBMap hex;
    in
    "rgba(${toString rgb.r}, ${toString rgb.g}, ${toString rgb.b}, ${alpha})";

  inherit (config.theme.colors)
    base00
    base01
    base02
    base03
    base04
    base05
    base06
    base07
    base08
    base09
    base0A
    base0B
    base0C
    base0D
    base0E
    base0F
    base10
    base11
    base12
    base13
    base14
    base15
    base16
    base17
    ;
in
{
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
      @define-color backgroundhex ${hexToRGBA base00 "0.75"};

    '';
    executable = false;
  };
}
