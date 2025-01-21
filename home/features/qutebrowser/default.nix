{
  ...
}:

{
  programs.qutebrowser = {
    enable = true;
    loadAutoconfig = true;
    settings = {
      editor.command = [ "xdg-open" "{file}" ];
      tabs = {
        show = "multiple";
        position = "left";
      };
    };
    extraConfig = ''
      c.tabs.padding = {"bottom": 10, "left": 10, "right": 10, "top": 10}
    '';
  };
}
