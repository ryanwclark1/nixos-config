{
  pkgs
}:

pkgs.writeShellScriptBin "microphone-status" ''
  WP_OUTPUT=$(${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_AUDIO_SOURCE@)

  if [[ "$WP_OUTPUT" == *"[MUTED]" ]]; then
      printf ""
  else
      printf ""
  fi
''