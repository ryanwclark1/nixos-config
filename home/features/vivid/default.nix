# home/vivid.nix
{
  pkgs,
  lib,
  config,
  ...
}:
let
  colors = import ../../theme/colors.nix;
  inherit (colors)
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
    themes.theme = builtins.toPath themeYml;
    colorMode = "24-bit"; # or "8-bit" for limited color support
    activeTheme = "theme"; # Use our base24 theme

    # Home-Manager expects an attrset of absolute paths.
    # We feed our generated base24 theme file here.

    # If you maintain a theme filetype DB, you can also add it like:
    # filetypes = pkgs.fetchurl { url = ".../filetypes.yml"; hash = "sha256-..."; };
  };

  # Note: Vivid program configuration automatically manages theme files
  # No need to manually create theme files
}
