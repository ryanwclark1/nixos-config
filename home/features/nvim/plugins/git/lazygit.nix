{pkgs, ...}: {
  programs.nixvim.extraPlugins = with pkgs.vimPlugins; [
    lazygit-nvim
  ];

  programs.nixvim.extraConfigLua = ''
    require("telescope").load_extension("lazygit")
  '';

  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = "<leader>gg";
      action = "<cmd>LazyGit<CR>";
      options = {
        desc = "LazyGit (root dir)";
      };
    }
  ];
}
