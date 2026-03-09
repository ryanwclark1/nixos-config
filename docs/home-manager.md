# Home Manager (Standalone)

This flake exposes Home Manager configurations under `homeConfigurations` in `flake.nix`. Use the `user@host` identifiers when switching.

## Prerequisites

- Nix with `nix-command` and `flakes` enabled.
- This repo checked out locally.

## Apply a Home Manager config

```sh
home-manager switch --flake .#administrator@woody --show-trace --verbose
```

If `home-manager` is not installed globally, run it via nix:

```sh
nix shell nixpkgs#home-manager -c home-manager switch --flake .#administrator@woody --show-trace --verbose
```

## Find available profiles

```sh
nix flake show
```

Look under `homeConfigurations` for the available `user@host` values.
