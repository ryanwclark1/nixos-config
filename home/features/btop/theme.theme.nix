{
  config,
  ...
}:
let
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
      theme[cpu_box]="#"
      theme[mem_box]="#${base0B}" #Green
      theme[net_box]="#${base12}" #Maroon
      theme[proc_box]="#${base0D}" #Blue

      # Box divider line and small boxes line color
      theme[div_line]="#${base02}"

      # Temperature graph color (Green -> Yellow -> Red)
      theme[temp_start]="#${base0B}"
      theme[temp_mid]="#${base0A}"
      theme[temp_end]="#${base08}"

      # CPU graph colors
      theme[cpu_start]="#${base0C}"
      theme[cpu_mid]="#${base16}"
      theme[cpu_end]="#${base07}"

      # Mem/Disk free meter
      theme[free_start]="#${base0E}"
      theme[free_mid]="#${base07}"
      theme[free_end]="#${base0D}"

      # Mem/Disk cached meter
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

      # Process box color gradient for threads, mem and cpu usage
      theme[process_start]="#${base16}"
      theme[process_mid]="#${base07}"
      theme[process_end]="#${base0E}"
    '';
  };
}
