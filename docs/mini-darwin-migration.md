# Mini Darwin Migration

This documents how to migrate `mini` to match the standardized Darwin setup used by
`neo`.

## Target State

`mini` should use:

- `hosts/common/darwin/default.nix` for shared Darwin configuration.
- `nix-homebrew` for declarative Homebrew bootstrap and ownership.
- Determinate-managed Nix, with `nix.enable = false` in nix-darwin.
- `home-manager.useGlobalPkgs = true` and shared overlays.
- Shared Homebrew casks, including `tailscale-app`.

The host-specific file should stay small:

```nix
{
  ...
}:
let
  user = "administrator";
  hostName = "mini";
in
{
  imports = [
    ../common/darwin
  ];

  home-manager.users."${user}" = import ../../home/${hostName}.nix;

  users.users."${user}" = {
    name = "${user}";
    home = "/Users/${user}";
  };

  system.primaryUser = user;
}
```

## Before Migrating

On `mini`, check who currently manages Nix:

```bash
launchctl list | rg nix
```

If `mini` is still using nix-darwin-managed Nix, the old config likely included:

```nix
services.nix-daemon.enable = true;
nix.package = pkgs.nixVersions.latest;
```

The standardized config removes those and sets:

```nix
nix.enable = false;
```

That means the Nix daemon should be managed outside nix-darwin by the Determinate
installer.

## Migration Steps

1. Install or repair Determinate Nix on `mini`.

   Use Determinate's current official installer for macOS. After installation,
   open a fresh shell and confirm Nix still works:

   ```bash
   nix --version
   nix flake metadata
   ```

2. Confirm Homebrew is available.

   `nix-homebrew.autoMigrate = true` should adopt an existing Homebrew
   installation, but Homebrew should still be healthy before the switch:

   ```bash
   brew --version
   brew doctor
   ```

3. From this repo on `mini`, switch the Darwin config:

   ```bash
   darwin-rebuild switch --flake .#mini --show-trace
   ```

   Or use the Makefile target:

   ```bash
   make mini
   ```

4. Verify the expected tools and apps:

   ```bash
   nix eval .#darwinConfigurations.mini.config.system.build.toplevel.drvPath
   brew list --cask | rg 'ghostty|cursor|tailscale'
   open -a Tailscale
   ```

5. Finish Tailscale setup manually.

   The app installation is declarative, but macOS system extension approval,
   login, and machine authorization are stateful/manual:

   ```bash
   open -a Tailscale
   ```

   Then approve any macOS prompts and sign in.

## If Something Goes Wrong

The most likely failure is Nix daemon ownership confusion after moving from
nix-darwin-managed Nix to Determinate-managed Nix.

Check active services:

```bash
launchctl list | rg 'nix|determinate'
```

Check that the flake still evaluates:

```bash
nix eval .#darwinConfigurations.mini.config.system.build.toplevel.drvPath --show-trace
```

If `darwin-rebuild` is not available on PATH:

```bash
nix run nix-darwin -- switch --flake .#mini --show-trace
```

If Homebrew ownership is the issue, inspect:

```bash
brew --prefix
ls -ld "$(brew --prefix)"
```

`nix-homebrew` is configured with:

```nix
nix-homebrew = {
  enable = true;
  user = config.system.primaryUser;
  autoMigrate = true;
};
```

For `mini`, `config.system.primaryUser` resolves to `administrator`.

## Rollback

If the new generation activates but is broken, use Darwin's previous generation:

```bash
/run/current-system/sw/bin/darwin-rebuild --rollback
```

If the issue is specifically the Nix daemon, fix Determinate Nix first, then
rerun:

```bash
darwin-rebuild switch --flake .#mini --show-trace
```
