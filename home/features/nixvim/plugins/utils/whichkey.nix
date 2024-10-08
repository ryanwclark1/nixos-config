_: {
  programs.nixvim.plugins.which-key = {
    enable = true;

    settings = {

      spec = [
        {
          __unkeyed = "<leader>b";
          group = "󰓩 Buffers";
        }
        {
          __unkeyed = "<leader>bs";
          group = "󰒺 Sort";
        }
        {
          __unkeyed = "<leader>g";
          group = "󰊢 Git";
        }
        {
          __unkeyed = "<leader>f";
          group = " Find";
        }
        {
          __unkeyed = "<leader>r";
          group = " Refactor";
        }
        {
          __unkeyed = "<leader>t";
          group = " Terminal";
        }
        {
          __unkeyed = "<leader>u";
          group = " UI/UX";
        }
      ];

      disable.ft = [
        "TelescopePrompt"
        "neo-tree"
        "neo-tree-popup"
      ];

      replace = {
        key = [
          [
            "<Space>"
            "SPC"
          ]
        ];

        desc = [
          [
            "<space>"
            "SPACE"
          ]
          [
            "<leader>"
            "SPACE"
          ]
          [
            "<[cC][rR]>"
            "RETURN"
          ]
          [
            "<[tT][aA][bB]>"
            "TAB"
          ]
          [
            "<[bB][sS]>"
            "BACKSPACE"
          ]
        ];
      };

      win = {
        border = "single";
      };
    };
  };
}