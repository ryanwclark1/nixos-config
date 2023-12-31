{
  lib,
  config,
  ...
}:
with lib; {
  options.pdf.enable = mkEnableOption "pdf settings";

  config = mkIf config.pdf.enable {
    programs.zathura.enable = true;
    programs.zathura.options = {
      default-bg = config.colors.macchiato.base.hex;
      default-fg = config.colors.macchiato.text.hex;
      recolor-darkcolor = config.colors.macchiato.text.hex;
      recolor-lightcolor = config.colors.macchiato.base.hex;
      recolor-keephue = true;
      recolor = true;
    };
  };
}
