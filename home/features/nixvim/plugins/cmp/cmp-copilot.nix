{
  programs.nixvim.plugins.copilot-cmp = {
    enable = true;
  };
  programs.nixvim.plugins.copilot-lua = {
    enable = true;
    settings = {
      suggestion = {enabled = false;};
      panel = {enabled = false;};
    };
  };

  programs.nixvim.extraConfigLua = ''
    require("copilot").setup({
      suggestion = { enabled = false },
      panel = { enabled = false },
    })
  '';
}
