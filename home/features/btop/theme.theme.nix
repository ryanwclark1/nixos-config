{
  ...
}:
let
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
  home.file.".config/btop/themes/theme.theme" = {
    text = ''
    # Main background, empty for terminal default, need to be empty if you want transparent background
    # theme[main_bg]=""

    # Main text color
    theme[main_fg]="#${base05}"

    # Title color for boxes
    theme[title]="#${base05}"

    # Highlight color for keyboard shortcuts
    theme[hi_fg]="#${base0D}"

    # Background color of selected item in processes box
    theme[selected_bg]="#${base03}"

    # Foreground color of selected item in processes box
    theme[selected_fg]="#${base0D}"

    # Color of inactive/disabled text
    theme[inactive_fg]="#${base04}"

    # Color of text appearing on top of graphs, i.e uptime and current network graph scaling
    theme[graph_text]="#${base13}"

    # Background color of the percentage meters
    theme[meter_bg]="#${base03}"

    # Misc colors for processes box including mini cpu graphs, details memory graph and details status text
    theme[proc_misc]="#${base13}"

    # CPU, Memory, Network, Proc box outline colors
    theme[cpu_box]="#${base0E}" #Mauve
    theme[mem_box]="#${base0B}" #Green
    theme[net_box]="#${base12}" #Maroon
    theme[proc_box]="#${base0D}" #Blue

    # Box divider line and small boxes line color
    theme[div_line]="#${base02}"

    # Temperature graph color (Green -> Yellow -> Red)
    theme[temp_start]="#${base0B}"
    theme[temp_mid]="#${base0A}"
    theme[temp_end]="#${base08}"

    # CPU graph colors (Teal -> Lavender)
    theme[cpu_start]="#${base0C}"
    theme[cpu_mid]="#${base16}"
    theme[cpu_end]="#${base07}"

    # Mem/Disk free meter (Mauve -> Lavender -> Blue)
    theme[free_start]="#${base0E}"
    theme[free_mid]="#${base07}"
    theme[free_end]="#${base0D}"

    # Mem/Disk cached meter (Sapphire -> Lavender)
    theme[cached_start]="#${base16}"
    theme[cached_mid]="#${base0D}"
    theme[cached_end]="#${base07}"

    # Mem/Disk available meter (Peach -> Red)
    theme[available_start]="#${base09}"
    theme[available_mid]="#${base12}"
    theme[available_end]="#${base08}"

    # Mem/Disk used meter (Green -> Sky)
    theme[used_start]="#${base0B}"
    theme[used_mid]="#${base0C}"
    theme[used_end]="#${base15}"

    # Download graph colors (Peach -> Red)
    theme[download_start]="#${base09}"
    theme[download_mid]="#${base12}"
    theme[download_end]="#${base08}"

    # Upload graph colors (Green -> Sky)
    theme[upload_start]="#${base0B}"
    theme[upload_mid]="#${base0C}"
    theme[upload_end]="#${base15}"

    # Process box color gradient for threads, mem and cpu usage (Sapphire -> Mauve)
    theme[process_start]="#${base16}"
    theme[process_mid]="#${base07}"
    theme[process_end]="#${base0E}"
    '';
  };
}