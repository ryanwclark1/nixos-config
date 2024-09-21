
{
  pkgs
}:
  pkgs.writeShellScriptBin "screenshooting" ''
    SCREENSHOTS="$HOME/Pictures/Screenshots"
    NOW=$(date +%Y-%m-%d_%H-%M-%S)
    TARGET="$SCREENSHOTS/$NOW.png"

    mkdir -p $SCREENSHOTS

    if [[ -n "$1" ]]; then
        "${pkgs.wayshot}/bin/wayshot" -f $TARGET
    else
        "${pkgs.wayshot}/bin/wayshot" -f $TARGET -s "$("${pkgs.slurp}/bin/slurp")"
    fi

    "${pkgs.wl-clipboard}/bin/wl-copy" < $TARGET

    RES=$("${pkgs.libnotify}/bin/notify-send" \
        -a "Screenshot" \
        -i "image-x-generic-symbolic" \
        -h string:image-path:$TARGET \
        -A "file=Show in Files" \
        -A "view=View" \
        -A "edit=Edit" \
        "Screenshot Taken" \
        $TARGET)

    case "$RES" in
        "file") xdg-open "$SCREENSHOTS" ;;
        "view") xdg-open $TARGET ;;
        "edit") swappy = "${pkgs.swappy}/bin/swappy" -f $TARGET ;;
        *) ;;
    esac
  ''
  # ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" - | ${pkgs.swappy}/bin/swappy -f -