{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkDefault mkOption types;
  defaultColors = import ./colors.nix;
  defaultFonts = import ./fonts.nix;

  pow =
    base: exponent:
    if exponent > 1 then
      let
        x = pow base (exponent / 2);
        oddExp = lib.mod exponent 2 == 1;
      in
      x * x * (if oddExp then base else 1)
    else if exponent == 1 then
      base
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
      lowerHex = lib.toLower hex;
    in
    if builtins.stringLength hex != 1 then
      throw "Function only accepts a single character."
    else if hexToDecMap ? ${lowerHex} then
      hexToDecMap.${lowerHex}
    else
      throw "Character ${hex} is not a hexadecimal value.";

  hexToDec =
    hex:
    let
      chars = lib.stringToCharacters hex;
      reversed = lib.reverseList chars;
      decimals = lib.imap0 (i: c: (hexCharToDec c) * (pow 16 i)) reversed;
    in
    lib.foldl builtins.add 0 decimals;

  hexToRgbMap = hex: {
    r = hexToDec (builtins.substring 0 2 hex);
    g = hexToDec (builtins.substring 2 2 hex);
    b = hexToDec (builtins.substring 4 2 hex);
  };

  hexToRgb =
    separator: hex:
    let
      rgb = hexToRgbMap hex;
    in
    "${toString rgb.r}${separator}${toString rgb.g}${separator}${toString rgb.b}";
in
{
  options.theme = {
    colors = mkOption {
      type = types.attrsOf types.str;
      description = "Base24 color aliases as raw lowercase hex strings without a leading #.";
    };

    fonts = mkOption {
      type = types.attrsOf types.str;
      description = "Shared font family names.";
    };

    formats.base24 = mkOption {
      readOnly = true;
      type = types.attrsOf (types.attrsOf types.str);
      description = "Base24 colors rendered in common configuration formats.";
    };
  };

  config.theme = {
    colors = lib.mapAttrs (_: mkDefault) defaultColors;
    fonts = lib.mapAttrs (_: mkDefault) defaultFonts;
    formats.base24 = {
      hash = lib.mapAttrs (_: value: "#${value}") config.theme.colors;
      ansiRgb = lib.mapAttrs (_: hex: "38;2;${hexToRgb ";" hex}") config.theme.colors;
      rgbSpace = lib.mapAttrs (_: hex: hexToRgb " " hex) config.theme.colors;
    };
  };
}
