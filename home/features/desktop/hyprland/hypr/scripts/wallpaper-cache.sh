#!/usr/bin/env bash
generated_versions="$HOME/.config/hypr/scripts/cache/wallpaper-generated"
rm $generated_versions/*
echo ":: Wallpaper cache cleared"
notify-send "Wallpaper cache cleared"
