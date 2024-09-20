_: {
  programs.nixvim.plugins.yazi.enable = true;

  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>e";
      action.__raw = ''
        function()
          require('yazi').yazi()
        end
      '';
      options = {
        desc = "Yazi toggle";
        silent = true;
      };
    }
  ];
}