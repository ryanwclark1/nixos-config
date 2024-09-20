{
  ...
}:

{
  home.file.".config/hypr/scripts/screenshooting.sh" = {
    text = ''
      #!/usr/bin/env bash
      grim -g "$(slurp)" - | swappy -f -
    '';
  executable = true;
  };
}
