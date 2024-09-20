{ config, lib, ... }:

{
  programs.nixvim.plugins = {
      harpoon = {
      enable = true;
      keymapsSilent = true;
      keymaps = {
        addFile = "<leader>a";
        toggleQuickMenu = "<C-e>";
        navFile = {
          "1" = "<C-j>";
          "2" = "<C-k>";
          "3" = "<C-l>";
          "4" = "<C-m>";
        };
      };
    };
    which-key.settings.spec = lib.optionals config.plugins.harpoon.enable [
      {
        __unkeyed = "<leader>h";
        group = "󱡀 Harpoon";
      }
      {
        __unkeyed = "<leader>ha";
        desc = "Add";
      }
      {
        __unkeyed = "<leader>he";
        desc = "QuickMenu";
      }
      {
        __unkeyed = "<leader>hj";
        desc = "1";
      }
      {
        __unkeyed = "<leader>hk";
        desc = "2";
      }
      {
        __unkeyed = "<leader>hl";
        desc = "3";
      }
      {
        __unkeyed = "<leader>hm";
        desc = "4";
      }
    ];
  };
}