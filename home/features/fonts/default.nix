{
  pkgs,
  ...
}:

{
  fonts = {
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "DejaVu Sans Mono" ];
        sansSerif = [ "DejaVu Sans" ];
        serif = [ "DejaVu Serif" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  home.packages = with pkgs; [
    # Essential monospace fonts for development
    nerd-fonts.fira-code          # Most popular, excellent ligatures
    nerd-fonts.hack               # Clean, readable terminal font
    nerd-fonts.iosevka            # Narrow, space-efficient
    nerd-fonts.symbols-only       # Powerline and icon symbols
    # Note: jetbrains-mono and ubuntu-mono available system-wide

    # Base fonts for Stylix themes
    dejavu_fonts                  # Default serif/sans fonts used by Stylix

    # Essential emoji and icon support
    noto-fonts-color-emoji
    icomoon-feather

    # Font management
    font-manager
  ];

}
