# Nix Cleanup Automation Design

## Goal

Make Nix-related disk cleanup more aggressive and more automated across shared NixOS hosts. The system should reclaim space without relying on a manual `make gc` habit, while keeping enough rollback history for ordinary recovery.

## Current State

The shared Nix module at `hosts/common/global/nix/default.nix` enables `nh` and currently runs `nh.clean` weekly with:

```text
--keep-since 10d --keep 25
```

Nix built-in garbage collection is disabled because cleanup is delegated to `nh`. Nix store optimization is already enabled through `nix.settings.auto-optimise-store = true`. The `Makefile` also has a manual `gc` target with a separate 7-day retention policy.

## Recommended Approach

Keep `nh.clean` as the primary automated cleanup mechanism, but make it daily and more aggressive:

```text
--keep-since 3d --keep 5
```

This keeps the existing cleanup tool, avoids competing timers, and directly addresses the overly large generation count. Daily cleanup reduces the chance that build outputs, old generations, and unreferenced store paths accumulate for long periods.

## Configuration Changes

Update `hosts/common/global/nix/default.nix`:

- Keep `nix.gc.automatic = false` to avoid overlapping Nix and `nh` cleanup timers.
- Keep `nix.settings.auto-optimise-store = true`.
- Increase Nix free-space thresholds so Nix has more room to react under disk pressure:
  - `min-free = 1073741824`
  - `max-free = 5368709120`
- Change `programs.nh.clean.dates` from `weekly` to `daily`.
- Change `programs.nh.clean.extraArgs` from `--keep-since 10d --keep 25` to `--keep-since 3d --keep 5`.

Update the manual `Makefile` cleanup target so its retention policy matches the automated policy:

- Wipe system profile history older than 3 days.
- Delete garbage older than 3 days.
- Keep the explicit `nix store gc` step.
- Keep the rebuild step so a manual cleanup still refreshes the boot configuration for the current host.

## Behavior

Daily automated cleanup will keep recent rollback history but prune older system and user generations more quickly. Manual cleanup remains available for immediate maintenance and uses the same 3-day policy so there is one clear retention model.

The boot loader generation limits remain unchanged. They already cap visible boot entries globally and per host, while the cleanup policy controls store and profile retention.

## Error Handling

`nh.clean` is managed by systemd through the NixOS module. Failures should appear in the corresponding systemd unit logs. The configuration avoids two independent GC schedulers so errors and cleanup behavior remain easier to reason about.

## Verification

After implementation:

- Run `nixfmt` on changed Nix files, if needed.
- Evaluate at least the main NixOS hosts with `nix flake check` or targeted `nixos-rebuild dry-run --flake .#<host>` when full flake checks are too expensive.
- Confirm the generated configuration includes daily `nh.clean` settings.
- Confirm the manual `make gc` target uses the same 3-day retention policy.
