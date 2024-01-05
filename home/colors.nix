{
  lib,
  ...
}:

with lib; {
  options = let
    # color ::  string -> listof.integers  -> color
    mkColor = s: {l ? [0 0 0]}: {
      hex = mkOption {
        type = types.str;
        default = "#${s}";
      };
      hexWithLastFF = mkOption {
        type = types.str;
        default = "#${s}FF";
      };
      rawHexWithLastFF = mkOption {
        type = types.str;
        default = "${s}FF";
      };

      rawHex = mkOption {
        type = types.str;
        default = s;
      };
      rgb = mkOption {
        type = types.listOf types.int;
        default = l;
      };
    };
  in {
    colors = {
      macchiato = {
        rosewater = mkColor "f4dbd6" {l = [244 219 214];};
        flamingo = mkColor "f0c6c6" {l = [240 198 198];};
        pink = mkColor "f5bde6" {l = [245 189 230];};
        mauve = mkColor "c6a0f6" {l = [198 160 246];};
        red = mkColor "ed8796" {l = [237 135 150];};
        maroon = mkColor "ee99a0" {l = [238 153 160];};
        peach = mkColor "f5a97f" {l = [245 169 127];};
        yellow = mkColor "eed49f" {l = [238 212 159];};
        green = mkColor "a6da95" {l = [166 218 149];};
        teal = mkColor "8bd5ca" {l = [139 213 202];};
        sky = mkColor "91d7e3" {l = [145 215 227];};
        sapphire = mkColor "7dc4e4" {l = [125 196 228];};
        blue = mkColor "8aadf4" {l = [138 173 244];};
        lavendar = mkColor "b7bdf8" {l = [183 189 248];};
        text = mkColor "cad3f5" {l = [202 211 245];};
        subtext1 = mkColor "b8c0e0" {l = [184 192 224];};
        subtext0 = mkColor "a5adcb" {l = [165 173 203];};
        overlay2 = mkColor "939ab7" {l = [147 154 183];};
        overlay1 = mkColor "8087a2" {l = [128 135 162];};
        overlay0 = mkColor "6e738d" {l = [110 115 141];};
        surface2 = mkColor "5b6078" {l = [91 96 120];};
        surface1 = mkColor "494d64" {l = [73 77 100];};
        surface0 = mkColor "363a4f" {l = [54 58 79];};
        base = mkColor "24273a" {l = [36 39 58];};
        mantle = mkColor "1e2030" {l = [30 32 48];};
        crust = mkColor "181926" {l = [24 25 38];};
      };

      rosepine = {
        rose = mkColor "ea9a97" {l = [234 154 151];};
        rosebg = mkColor "3f2f39" {l = [];};
        pine = mkColor "3e9fb0" {l = [62 143 176];};
        pinebg = mkColor "202d3d" {l = [];};
        love = mkColor "eb6f92" {l = [235 111 146];};
        lovebg = mkColor "3f2738" {l = [];};
        foam = mkColor "9ccfd8" {l = [156 207 216];};
        foambg = mkColor "313845" {l = [];};
        gold = mkColor "f5c177" {l = [246 193 119];};
        goldbg = mkColor "413633" {l = [];};
        iris = mkColor "c4a7e7" {l = [196 167 231];};
        irisbg = mkColor "383147" {l = [];};
        base = mkColor "232136" {l = [35 33 54];};
        surface = mkColor "2a273f" {l = [42 39 63];};
        overlay = mkColor "393552" {l = [57 53 82];};
        text = mkColor "e0def4" {l = [224 222 244];};
        subtle = mkColor "908caa" {l = [144 140 170];};
        muted = mkColor "6e6a86" {l = [110 106 134];};
        highlight-low = mkColor "2a283e" {l = [42 40 62];};
        highlight-med = mkColor "44415a" {l = [68 65 90];};
        highlight-high = mkColor "56526e" {l = [86 82 110];};
      };
    };
  };
}