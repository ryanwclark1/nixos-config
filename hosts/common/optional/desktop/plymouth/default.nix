{
  config,
  lib,
  pkgs,
  ...
}@args:
let
  logo = "${pkgs.nixos-icons}/share/icons/hicolor/256x256/apps/nix-snowflake.png";
  logoAnimated = true;


  themeScript = import ./theme-script.nix args;

  theme = pkgs.runCommand "custom-plymouth" { } ''
    themeDir="$out/share/plymouth/themes/custom"
    mkdir -p $themeDir

    ${lib.getExe' pkgs.imagemagick "convert"} \
      -background transparent \
      -bordercolor transparent \
      ${
        # A transparent border ensures the image is not clipped when rotated
        lib.optionalString logoAnimated "-border 42%"
      } \
      ${logo} \
      $themeDir/logo.png

    cp ${themeScript} $themeDir/custom.script

    echo "
    [Plymouth Theme]
    Name=Custom
    ModuleName=script

    [script]
    ImageDir=$themeDir
    ScriptFile=$themeDir/custom.script
    " > $themeDir/custom.plymouth
  '';
in {
  boot.plymouth = {
    enable = true;
    logo = logo;
    themePackages = [ theme ];
    theme = "custom"; # Uncomment when ready
  };
}
