_: {
  programs.nixvim.plugins.navic = {
    enable = true;
    click = false;
    depthLimit = 5;
    depthLimitIndicator = "..";
    highlight = true;
    lazyUpdateContext = false;
    safeOutput = true;
    separator = "  ";
    lsp = {
      autoAttach = true;
    };
    icons = {
      Array = "󰅪 ";
      Boolean = "  ";
      Class = "  ";
      Constant = "  ";
      Constructor = "  ";
      Enum = " ";
      EnumMember = " ";
      Event = " ";
      Field = "󰽏 ";
      File = "󰈙 ";
      Function = "󰊕 ";
      Interface = " ";
      Key = "  ";
      Method = " ";
      Module = "󰕳 ";
      Namespace = " ";
      Null = "󰟢 ";
      Number = "󰎠 ";
      Object = "  ";
      Operator = "󰆕 ";
      Package = " ";
      Property = " ";
      String = "󰀬 ";
      Struct = " ";
      TypeParameter = "󰊄 ";
      Variable = "󰆧 ";
    };
  };
}
