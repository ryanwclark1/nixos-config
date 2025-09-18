# home/vivid.nix
{ pkgs, lib, config, ... }:
let
  # Base24 palette mapping
  base00 = "303446"; # Default Background
  base01 = "292c3c"; # Lighter Background (Used for status bars, line number and folding marks)
  base02 = "414559"; # Selection Background
  base03 = "51576d"; # Comments, Invisibles, Line Highlighting
  base04 = "626880"; # Dark Foreground (Used for status bars)
  base05 = "c6d0f5"; # Default Foreground, Caret, Delimiters, Operators
  base06 = "f2d5cf"; # Light Foreground (Not often used)
  base07 = "babbf1"; # Light Background (Not often used)
  base08 = "e78284"; # Variables, XML Tags, Markup Link Text, Markup Lists, Diff Deleted
  base09 = "ef9f76"; # Integers, Boolean, Constants, XML Attributes, Markup Link Url
  base0A = "e5c890"; # Classes, Markup Bold, Search Text Background
  base0B = "a6d189"; # Strings, Inherited Class, Markup Code, Diff Inserted
  base0C = "81c8be"; # Support, Regular Expressions, Escape Characters, Markup Quotes
  base0D = "8caaee"; # Functions, Methods, Attribute IDs, Headings
  base0E = "ca9ee6"; # Keywords, Storage, Selector, Markup Italic, Diff Changed
  base0F = "eebebe"; # Deprecated, Opening/Closing Embedded Language Tags
  base10 = "292c3c"; # Darker Background
  base11 = "232634"; # Darkest Background
  base12 = "ea999c"; # Bright Red
  base13 = "f2d5cf"; # Bright Orange
  base14 = "a6d189"; # Bright Yellow
  base15 = "99d1db"; # Bright Green
  base16 = "85c1dc"; # Bright Cyan
  base17 = "f4b8e4"; # Bright Blue

  # Write the vivid theme YAML following the correct schema
  themeYml = pkgs.writeText "theme.yml" ''
    colors:
      # Expose Base24 keys directly for use below
      base00: "${base00}"
      base01: "${base01}"
      base02: "${base02}"
      base03: "${base03}"
      base04: "${base04}"
      base05: "${base05}"
      base06: "${base06}"
      base07: "${base07}"
      base08: "${base08}"
      base09: "${base09}"
      base0A: "${base0A}"
      base0B: "${base0B}"
      base0C: "${base0C}"
      base0D: "${base0D}"
      base0E: "${base0E}"
      base0F: "${base0F}"
      base10: "${base10}"
      base11: "${base11}"
      base12: "${base12}"
      base13: "${base13}"
      base14: "${base14}"
      base15: "${base15}"
      base16: "${base16}"
      base17: "${base17}"

    core:
      # --- Top-level classes (structure matches your example) ---
      normal_text: {}
      regular_file: {}
      reset_to_normal: {}

      directory:
        foreground: base0D      # blue

      symlink:
        foreground: base17      # pink (your hex f4b8e4)

      multi_hard_link: {}

      fifo:
        foreground: base11      # crust
        background: base0D      # blue bg

      socket:
        foreground: base11
        background: base17

      door:
        foreground: base11
        background: base17

      block_device:
        foreground: base16      # sapphire
        background: base02      # surface0

      character_device:
        foreground: base17      # pink
        background: base02

      broken_symlink:
        foreground: base11
        background: base08      # red

      missing_symlink_target:
        foreground: base11
        background: base08

      setuid: {}
      setgid: {}
      file_with_capability: {}

      sticky_other_writable: {}
      other_writable: {}
      sticky: {}

      executable_file:
        foreground: base08      # red
        font-style: bold

    # --- Category sections ---
    text:
      special:
        foreground: base00     # base background as text color on…
        background: base0A     # yellow highlight
      todo:
        font-style: bold
      licenses:
        foreground: base04     # overlay-ish (surface2)
      configuration:
        foreground: base0A     # yellow
      other:
        foreground: base0A

    markup:
      foreground: base0A       # yellow

    programming:
      source:
        foreground: base0B     # green
      tooling:
        foreground: base0C     # teal
        continuous-integration:
          foreground: base0B   # green

    media:
      foreground: base0F       # flamingo

    office:
      foreground: base08       # red

    archives:
      foreground: base16       # sapphire
      font-style: underline

    executable:
      foreground: base08       # red
      font-style: bold

    unimportant:
      foreground: base04       # surface2
  '';
in
{
  programs.vivid = {
    enable = true;
    package = pkgs.vivid;
    enableBashIntegration = lib.mkIf config.programs.bash.enable true;
    enableFishIntegration = lib.mkIf config.programs.fish.enable true;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
    themes.theme = themeYml;
    colorMode = "24-bit";          # or "8-bit" for limited color support
    activeTheme = "theme";  # Use our base24 theme

    # Home-Manager expects an attrset of absolute paths.
    # We feed our generated base24 theme file here.


    # If you maintain a theme filetype DB, you can also add it like:
    # filetypes = pkgs.fetchurl { url = ".../filetypes.yml"; hash = "sha256-..."; };
  };

  # Note: Vivid program configuration automatically manages theme files
  # No need to manually create theme files
}
