_: {
  programs.nixvim.plugins.zellij = {
    enable = true;
    settings = {
      debug = true;
      path = "zellij";
      replaceVimWindowNavigationKeybinds = true;
      vimTmuxNavigatorKeybinds = false;
    };
  };
}