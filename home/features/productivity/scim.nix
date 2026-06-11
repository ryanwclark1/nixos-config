# SCIM

{
  config,
  pkgs,
  ...
}:
let
  rgb = config.theme.formats.base24.rgbSpace;
in

{
  home.packages = with pkgs; [
    sc-im
  ];

  home.file."sc-im.scimrc".text = ''
    REDEFINE_COLOR "BASE00" ${rgb.base00}
    DEFINE_COLOR   "BASE01" ${rgb.base01}
    DEFINE_COLOR   "BASE02" ${rgb.base02}
    DEFINE_COLOR   "BASE03" ${rgb.base03}
    DEFINE_COLOR   "BASE05" ${rgb.base05}
    DEFINE_COLOR   "BASE06" ${rgb.base06}
    REDEFINE_COLOR "BASE08" ${rgb.base08}
    DEFINE_COLOR   "BASE09" ${rgb.base09}
    REDEFINE_COLOR "BASE0B" ${rgb.base0B}
    DEFINE_COLOR   "BASE0D" ${rgb.base0D}
    DEFINE_COLOR   "BASE0E" ${rgb.base0E}
    DEFINE_COLOR   "BASE0F" ${rgb.base0F}
    DEFINE_COLOR   "BASE15" ${rgb.base15}

    color "type=NORMAL fg=BASE05 bg=BASE00"
    color "type=WELCOME fg=BASE0E bg=BASE00 bold=0"
    color "type=HEADINGS fg=BASE05 bg=BASE01"
    color "type=HEADINGS_ODD fg=BASE05 bg=BASE01"
    color "type=MODE fg=BASE01 bg=BASE0D"
    color "type=NUMB fg=BASE09 bg=BASE00"
    color "type=STRG fg=BASE0B bg=BASE00"
    color "type=DATEF fg=BASE06 bg=BASE00"
    color "type=CELL_SELECTION fg=BASE05 bg=BASE03"
    color "type=CELL_SELECTION_SC fg=BASE00 bg=BASE06"
    color "type=GRID_EVEN fg=BASE05 bg=BASE00"
    color "type=GRID_ODD fg=BASE05 bg=BASE01"
    color "type=EXPRESSION fg=BASE15 bg=BASE00"
    color "type=CELL_ERROR fg=BASE00 bg=BASE08"
    color "type=CELL_NEGATIVE fg=BASE08 bg=BASE00"
    color "type=CELL_ID fg=BASE06 bg=BASE01"
    color "type=CELL_FORMAT fg=BASE0E bg=BASE01"
    color "type=CELL_CONTENT fg=BASE0F bg=BASE01"
    color "type=INFO_MSG fg=BASE01 bg=BASE15"
    color "type=ERROR_MSG fg=BASE05 bg=BASE00"
    color "type=INPUT fg=BASE05 bg=BASE01"
    color "type=HELP_HIGHLIGHT fg=BASE06 bg=BASE02"
  '';
}
