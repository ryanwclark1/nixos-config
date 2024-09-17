_: {
  programs.nixvim.plugins.navic = {
    enable = true;
    settings = {
      click = false;
      depthLimit = 5;
      lazyUpdateContext = false;
      depthLimitIndicator = "..";
      safeOutput = true;
      separator = "  ";
      highlight = true;
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
    lsp = {
      autoAttach = true;
    };
  };
}
