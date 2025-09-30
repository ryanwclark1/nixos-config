{
  config,
  lib,
  ...
}:
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

  hexToRGBA = hex: alpha:
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
  home.file.".config/zellij/themes/theme.kdl" = {
    text = ''
      themes {
        theme {
          text_unselected {
            base ${hexToRGB base05}.r ${hexToRGB base05}.g ${hexToRGB base05}.b;
            background ${hexToRGB base00}.r ${hexToRGB base00}.g ${hexToRGB base00}.b;
            emphasis_0 ${hexToRGB base09}.r ${hexToRGB base09}.g ${hexToRGB base09}.b;
            emphasis_1 ${hexToRGB base15}.r ${hexToRGB base15}.g ${hexToRGB base15}.b;
            emphasis_2 ${hexToRGB base0B}.r ${hexToRGB base0B}.g ${hexToRGB base0B}.b;
            emphasis_3 ${hexToRGB base17}.r ${hexToRGB base17}.g ${hexToRGB base17}.b;
          }
          text_selected {
            base ${hexToRGB base05}.r ${hexToRGB base05}.g ${hexToRGB base05}.b;
            background ${hexToRGB base04}.r ${hexToRGB base04}.g ${hexToRGB base04}.b;
            emphasis_0 ${hexToRGB base09}.r ${hexToRGB base09}.g ${hexToRGB base09}.b;
            emphasis_1   ${hexToRGB base15}.r ${hexToRGB base15}.g ${hexToRGB base15}.b;
            emphasis_2 ${hexToRGB base0B}.r ${hexToRGB base0B}.g ${hexToRGB base0B}.b;
            emphasis_3 ${hexToRGB base17}.r ${hexToRGB base17}.g ${hexToRGB base17}.b;
          }
          ribbon_selected {
            base ${hexToRGB base10}.r ${hexToRGB base10}.g ${hexToRGB base10}.b;
            background ${hexToRGB base0B}.r ${hexToRGB base0B}.g ${hexToRGB base0B}.b;
            emphasis_0 ${hexToRGB base08}.r ${hexToRGB base08}.g ${hexToRGB base08}.b;
            emphasis_1 ${hexToRGB base09}.r ${hexToRGB base09}.g ${hexToRGB base09}.b;
            emphasis_2 ${hexToRGB base17}.r ${hexToRGB base17}.g ${hexToRGB base17}.b;
            emphasis_3 ${hexToRGB base0D}.r ${hexToRGB base0D}.g ${hexToRGB base0D}.b;
          }
          ribbon_unselected {
            base ${hexToRGB base10}.r ${hexToRGB base10}.g ${hexToRGB base10}.b;
            background ${hexToRGB base05}.r ${hexToRGB base05}.g ${hexToRGB base05}.b;
            emphasis_0 ${hexToRGB base08}.r ${hexToRGB base08}.g ${hexToRGB base08}.b;
            emphasis_1 ${hexToRGB base05}.r ${hexToRGB base05}.g ${hexToRGB base05}.b;
            emphasis_2 ${hexToRGB base0D}.r ${hexToRGB base0D}.g ${hexToRGB base0D}.b;
            emphasis_3 ${hexToRGB base17}.r ${hexToRGB base17}.g ${hexToRGB base17}.b;
          }
          table_title {
            base ${hexToRGB base0B}.r ${hexToRGB base0B}.g ${hexToRGB base0B}.b;
            background 0
            emphasis_0 ${hexToRGB base09}.r ${hexToRGB base09}.g ${hexToRGB base09}.b;
            emphasis_1   ${hexToRGB base15}.r ${hexToRGB base15}.g ${hexToRGB base15}.b;
            emphasis_2 ${hexToRGB base0B}.r ${hexToRGB base0B}.g ${hexToRGB base0B}.b;
            emphasis_3 ${hexToRGB base17}.r ${hexToRGB base17}.g ${hexToRGB base17}.b;
          }
          table_cell_selected {
            base ${hexToRGB base05}.r ${hexToRGB base05}.g ${hexToRGB base05}.b;
            background ${hexToRGB base04}.r ${hexToRGB base04}.g ${hexToRGB base04}.b;
            emphasis_0 ${hexToRGB base09}.r ${hexToRGB base09}.g ${hexToRGB base09}.b;
            emphasis_1   ${hexToRGB base15}.r ${hexToRGB base15}.g ${hexToRGB base15}.b;
            emphasis_2 ${hexToRGB base0B}.r ${hexToRGB base0B}.g ${hexToRGB base0B}.b;
            emphasis_3 ${hexToRGB base17}.r ${hexToRGB base17}.g ${hexToRGB base17}.b;
          }
          table_cell_unselected {
            base ${hexToRGB base05}.r ${hexToRGB base05}.g ${hexToRGB base05}.b;
            background ${hexToRGB base10}.r ${hexToRGB base10}.g ${hexToRGB base10}.b;
            emphasis_0 ${hexToRGB base09}.r ${hexToRGB base09}.g ${hexToRGB base09}.b;
            emphasis_1   ${hexToRGB base15}.r ${hexToRGB base15}.g ${hexToRGB base15}.b;
            emphasis_2 ${hexToRGB base0B}.r ${hexToRGB base0B}.g ${hexToRGB base0B}.b;
            emphasis_3 ${hexToRGB base17}.r ${hexToRGB base17}.g ${hexToRGB base17}.b;
          }
          list_selected {
            base ${hexToRGB base05}.r ${hexToRGB base05}.g ${hexToRGB base05}.b;
            background ${hexToRGB base04}.r ${hexToRGB base04}.g ${hexToRGB base04}.b;
            emphasis_0 ${hexToRGB base09}.r ${hexToRGB base09}.g ${hexToRGB base09}.b;
            emphasis_1   ${hexToRGB base15}.r ${hexToRGB base15}.g ${hexToRGB base15}.b;
            emphasis_2 ${hexToRGB base0B}.r ${hexToRGB base0B}.g ${hexToRGB base0B}.b;
            emphasis_3 ${hexToRGB base17}.r ${hexToRGB base17}.g ${hexToRGB base17}.b;
          }
          list_unselected {
            base ${hexToRGB base05}.r ${hexToRGB base05}.g ${hexToRGB base05}.b;
            background ${hexToRGB base10}.r ${hexToRGB base10}.g ${hexToRGB base10}.b;
            emphasis_0 ${hexToRGB base09}.r ${hexToRGB base09}.g ${hexToRGB base09}.b;
            emphasis_1   ${hexToRGB base15}.r ${hexToRGB base15}.g ${hexToRGB base15}.b;
            emphasis_2 ${hexToRGB base0B}.r ${hexToRGB base0B}.g ${hexToRGB base0B}.b;
            emphasis_3 ${hexToRGB base17}.r ${hexToRGB base17}.g ${hexToRGB base17}.b;
          }
          frame_selected {
            base ${hexToRGB base0B}.r ${hexToRGB base0B}.g ${hexToRGB base0B}.b;
            background 0
            emphasis_0 ${hexToRGB base09}.r ${hexToRGB base09}.g ${hexToRGB base09}.b;
            emphasis_1   ${hexToRGB base15}.r ${hexToRGB base15}.g ${hexToRGB base15}.b;
            emphasis_2 ${hexToRGB base17}.r ${hexToRGB base17}.g ${hexToRGB base17}.b;
            emphasis_3 0
          }
          frame_highlight {
            base ${hexToRGB base09}.r ${hexToRGB base09}.g ${hexToRGB base09}.b;
            background 0
            emphasis_0 ${hexToRGB base17}.r ${hexToRGB base17}.g ${hexToRGB base17}.b;
            emphasis_1 ${hexToRGB base09}.r ${hexToRGB base09}.g ${hexToRGB base09}.b;
            emphasis_2 ${hexToRGB base09}.r ${hexToRGB base09}.g ${hexToRGB base09}.b;
            emphasis_3 ${hexToRGB base09}.r ${hexToRGB base09}.g ${hexToRGB base09}.b;
          }
          exit_code_success {
            base ${hexToRGB base0B}.r ${hexToRGB base0B}.g ${hexToRGB base0B}.b;
            background 0
            emphasis_0   ${hexToRGB base15}.r ${hexToRGB base15}.g ${hexToRGB base15}.b;
            emphasis_1 ${hexToRGB base10}.r ${hexToRGB base10}.g ${hexToRGB base10}.b;
            emphasis_2 ${hexToRGB base17}.r ${hexToRGB base17}.g ${hexToRGB base17}.b;
            emphasis_3 ${hexToRGB base0D}.r ${hexToRGB base0D}.g ${hexToRGB base0D}.b;
          }
          exit_code_error {
            base ${hexToRGB base08}.r ${hexToRGB base08}.g ${hexToRGB base08}.b;
            background 0
            emphasis_0 ${hexToRGB base0A}.r ${hexToRGB base0A}.g ${hexToRGB base0A}.b;
            emphasis_1 0
            emphasis_2 0
            emphasis_3 0
          }
          multiplayer_user_colors {
            player_1 ${hexToRGB base17}.r ${hexToRGB base17}.g ${hexToRGB base17}.b;
            player_2 ${hexToRGB base0D}.r ${hexToRGB base0D}.g ${hexToRGB base0D}.b;
            player_3 0
            player_4 ${hexToRGB base0A}.r ${hexToRGB base0A}.g ${hexToRGB base0A}.b;
            player_5   ${hexToRGB base15}.r ${hexToRGB base15}.g ${hexToRGB base15}.b;
            player_6 0
            player_7 ${hexToRGB base08}.r ${hexToRGB base08}.g ${hexToRGB base08}.b;
            player_8 0
            player_9 0
            player_10 0
          }
        }
      }

    '';
    executable = false;
  };
}
