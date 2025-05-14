{ config, lib, pkgs, ... }:

let

  themeScript = import ./theme-script.nix { inherit lib config; };

  theme = pkgs.runCommand "custom-plymouth-theme" { } ''
    themeDir="$out/share/plymouth/themes/custom"
    mkdir -p "$themeDir"

    ${lib.getExe' pkgs.imagemagick "convert"} \
      -background transparent \
      -bordercolor transparent \
       "-border 42%" \
      "$themeDir/logo.png"

    cp "${themeScript}" "$themeDir/custom.script"

    cat > "$themeDir/custom.plymouth" <<EOF
[Plymouth Theme]
Name=Custom
ModuleName=script

[script]
ImageDir=$themeDir
ScriptFile=$themeDir/custom.script
EOF
  '';
in {
  boot.plymouth = {
    enable = true;
    logo = "${pkgs.nixos-icons}/share/icons/hicolor/256x256/apps/nix-snowflake.png";
    theme = "custom";
    themePackages = [ theme ];
  };
}
