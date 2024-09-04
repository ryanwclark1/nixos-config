_: {
  imports = [
    # General Configuration
    ./auto_cmds.nix
    ./file_types.nix
    ./keymaps.nix
    ./settings.nix

    # Themes
    ./plugins/themes/default.nix

    # Completion
    ./plugins/cmp/autopairs.nix
    ./plugins/cmp/cmp-copilot.nix
    ./plugins/cmp/cmp.nix
    ./plugins/cmp/lspkind.nix

    # Snippets
    ./plugins/snippets/luasnip.nix

    # Editor plugins and configurations
    ./plugins/editor/copilot-chat.nix
    ./plugins/editor/illuminate.nix
    ./plugins/editor/indent-blankline.nix
    ./plugins/editor/navic.nix
    ./plugins/editor/neo-tree.nix
    ./plugins/editor/todo-comments.nix
    ./plugins/editor/treesitter.nix
    ./plugins/editor/undotree.nix

    # UI plugins
    ./plugins/ui/alpha.nix
    ./plugins/ui/bufferline.nix
    ./plugins/ui/lualine.nix
    ./plugins/ui/startup.nix

    # LSP and formatting
    ./plugins/lsp/conform.nix
    ./plugins/lsp/fidget.nix
    ./plugins/lsp/lsp.nix

    # Git
    ./plugins/git/gitsigns.nix
    ./plugins/git/lazygit.nix

    # Utils
    ./plugins/utils/colorizer.nix
    ./plugins/utils/extra_plugins.nix
    ./plugins/utils/markdown-preview.nix
    ./plugins/utils/mini.nix
    ./plugins/utils/telescope.nix
    ./plugins/utils/toggleterm.nix
    ./plugins/utils/whichkey.nix
    ./plugins/utils/yazi.nix
  ];
}
