{ ... }:

{
  home.file.".config/rofi/style/config-emoji.rasi" = {
    text = ''
      @import "~/.config/rofi/style/config-long.rasi"
      entry {
        width: 45%;
        placeholder: "🔎 Search Emoji's 👀";
      }
    '';
  };
}
