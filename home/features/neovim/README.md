# Neovim Hybrid Configuration

This is a hybrid approach that gives you the flexibility of custom Neovim configuration while keeping the benefits of nixpkgs integration.

## Benefits of This Approach

### 🎯 **Best of Both Worlds**
- **LSP servers managed by nixpkgs**: Always up-to-date, properly integrated
- **Custom Lua configuration**: Full control over your editor experience
- **Lazy.nvim for plugins**: Modern plugin management with lazy loading
- **No build dependencies**: All formatters/linters provided by Nix

### 🔧 **What's Managed by Nix**
- LSP servers (nixd, rust-analyzer, gopls, etc.)
- Formatters (prettier, stylua, black, etc.)
- Linters and tools (ripgrep, fd, tree-sitter)
- System dependencies (clipboard, git)

### ⚡ **What's Managed by Lazy.nvim**
- Plugin installation and updates
- Lazy loading for performance
- Plugin configuration in pure Lua
- Easy customization and extension

## Transition from nixvim

### 1. **Disable nixvim** (temporarily)
```nix
# In your home configuration, comment out:
# ./features/nixvim
```

### 2. **Enable the hybrid configuration**
```nix
# Add to your home configuration:
./features/neovim-hybrid
```

### 3. **Apply the configuration**
```bash
home-manager switch --flake .#administrator@woody
```

### 4. **First-time setup**
When you first open Neovim, Lazy.nvim will automatically:
- Install itself
- Download and install all configured plugins
- Set up LSP servers (which are provided by nixpkgs)

## Configuration Structure

```
~/.config/nvim/
├── lua/
│   ├── config/
│   │   ├── init.lua          # Main entry point
│   │   ├── options.lua       # Neovim options
│   │   ├── keymaps.lua       # Global keymaps
│   │   ├── autocmds.lua      # Autocommands
│   │   └── lazy-bootstrap.lua # Lazy.nvim setup
│   └── plugins/
│       ├── lsp.lua           # LSP configuration
│       ├── completion.lua    # nvim-cmp setup
│       ├── telescope.lua     # Fuzzy finder
│       ├── neo-tree.lua      # File explorer
│       ├── treesitter.lua    # Syntax highlighting
│       ├── gitsigns.lua      # Git integration
│       ├── lualine.lua       # Status line
│       ├── colorscheme.lua   # Theme
│       ├── which-key.lua     # Keybind help
│       └── formatting.lua    # Code formatting
```

## Customization

### Adding New Plugins
Create a new file in `~/.config/nvim/lua/plugins/` or add to existing files:

```lua
return {
  {
    "plugin-author/plugin-name",
    event = "VeryLazy",  -- or other lazy-loading triggers
    config = function()
      -- Plugin configuration
    end,
  },
}
```

### Adding New LSP Servers
1. Add the LSP server package to the nixpkgs `extraPackages` in `default.nix`
2. Add the server name to the `servers` list in `plugins/lsp.lua`
3. Rebuild with `home-manager switch`

### Custom Keymaps
Add to `~/.config/nvim/lua/config/keymaps.lua`:

```lua
vim.keymap.set("n", "<leader>custom", ":YourCommand<CR>", { desc = "Your description" })
```

## Migration Notes

### From nixvim
- All your LSP servers are preserved and managed by nixpkgs
- Plugin functionality is replicated with popular alternatives
- Keybindings are mostly compatible
- Theme is set to Catppuccin Frappe (similar to your current setup)

### Key Differences
- Plugins are managed by Lazy.nvim instead of nixvim
- Configuration is in pure Lua (more standard)
- Plugin updates happen in Neovim, not with system rebuilds
- More flexibility for plugin customization

## Troubleshooting

### LSP Not Working
- Check that the language server is in `extraPackages` in `default.nix`
- Verify the server name in `plugins/lsp.lua` matches lspconfig naming
- Run `:LspInfo` to see active servers

### Plugin Issues
- Run `:Lazy` to manage plugins
- Use `:Lazy sync` to update all plugins
- Check `:Lazy log` for error messages

### Formatting Not Working
- Ensure the formatter is in `extraPackages` in `default.nix`
- Check the formatter name in `plugins/formatting.lua`
- Use `:ConformInfo` to see available formatters

## Future Enhancements

You can easily extend this configuration with:
- More advanced LSP features (lsp-signature, lsp-saga)
- Additional plugins (copilot, DAP for debugging)
- Custom colorschemes or themes
- Workspace-specific configurations
- Custom snippets and templates

This setup gives you a solid foundation while maintaining the reliability of nixpkgs-managed tools.