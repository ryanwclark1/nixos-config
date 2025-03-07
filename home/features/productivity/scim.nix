# SCIM

{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    sc-im
  ];

  home.file."sc-im.scimrc".text = ''
    DEFINE_COLOR   "ROSEWATER" 242 213 207
    DEFINE_COLOR   "FLAMINGO"  238 190 190
    DEFINE_COLOR   "PINK"      244 184 228
    DEFINE_COLOR   "MAUVE"     202 158 230
    REDEFINE_COLOR "RED"       231 130 132
    DEFINE_COLOR   "MAROON"    234 153 156
    DEFINE_COLOR   "PEACH"     239 159 118
    REDEFINE_COLOR "YELLOW"    229 200 144
    REDEFINE_COLOR "GREEN"     166 209 137
    DEFINE_COLOR   "TEAL"      129 200 190
    DEFINE_COLOR   "SKY"       153 209 219
    DEFINE_COLOR   "SAPPHIRE"  133 193 220
    REDEFINE_COLOR "BLUE"      140 170 238
    DEFINE_COLOR   "LAVENDER"  186 187 241
    DEFINE_COLOR   "TEXT"      198 208 245
    DEFINE_COLOR   "SUBTEXT1"  181 191 226
    DEFINE_COLOR   "SUBTEXT0"  165 173 206
    DEFINE_COLOR   "OVERLAY2"  148 156 187
    DEFINE_COLOR   "OVERLAY1"  131 139 167
    DEFINE_COLOR   "OVERLAY0"  115 121 148
    DEFINE_COLOR   "SURFACE2"   98 104 128
    DEFINE_COLOR   "SURFACE1"   81  87 109
    DEFINE_COLOR   "SURFACE0"   65  69  89
    REDEFINE_COLOR "BLACK"      48  52  70
    DEFINE_COLOR   "MANTLE"     41  44  60
    DEFINE_COLOR   "CRUST"      35  38  52

    color "type=NORMAL fg=TEXT bg=BLACK"
    color "type=WELCOME fg=MAGENTA bg=BLACK bold=0"
    color "type=HEADINGS fg=TEXT bg=CRUST"
    color "type=HEADINGS_ODD fg=TEXT bg=MANTLE"
    color "type=MODE fg=CRUST bg=BLUE"
    color "type=NUMB fg=PEACH bg=BLACK"
    color "type=STRG fg=GREEN bg=BLACK"
    color "type=DATEF fg=ROSEWATER bg=BLACK"
    color "type=CELL_SELECTION fg=TEXT bg=OVERLAY0"
    color "type=CELL_SELECTION_SC fg=BLACK bg=ROSEWATER"
    color "type=GRID_EVEN fg=TEXT bg=BLACK"
    color "type=GRID_ODD fg=TEXT bg=MANTLE"
    color "type=EXPRESSION fg=SKY bg=BLACK"
    color "type=CELL_ERROR fg=BLACK bg=RED"
    color "type=CELL_NEGATIVE fg=RED bg=BLACK"
    color "type=CELL_ID fg=ROSEWATER bg=CRUST"
    color "type=CELL_FORMAT fg=MAGENTA bg=CRUST"
    color "type=CELL_CONTENT fg=FLAMINGO bg=CRUST"
    color "type=INFO_MSG fg=CRUST bg=SKY"
    color "type=ERROR_MSG fg=TEXT bg=BLACK"
    color "type=INPUT fg=SUBTEXT1 bg=MANTLE"
    color "type=HELP_HIGHLIGHT fg=ROSEWATER bg=SURFACE2"
  '';
}