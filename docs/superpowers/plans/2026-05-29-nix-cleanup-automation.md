# Nix Cleanup Automation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Nix cleanup daily, aggressive, automated, and consistent between declarative host config and the manual `make gc` command.

**Architecture:** Keep `nh.clean` as the single scheduled cleanup mechanism and avoid enabling a competing `nix.gc` timer. Update the shared NixOS module for all hosts that import `hosts/common/global`, then align the `Makefile` manual cleanup retention policy with the same 3-day rule.

**Tech Stack:** NixOS modules, `nh`, Nix store settings, GNU Make, `nixfmt`, `nix eval`.

---

### Task 1: Add Policy Assertions

**Files:**
- Modify: `hosts/common/global/nix/default.nix`
- Modify: `Makefile`

- [ ] **Step 1: Verify current Nix cleanup policy is not the target policy**

Run:

```bash
rg -n 'dates = "weekly"|--keep-since 10d --keep 25|min-free = 134217728|max-free = 1000000000' hosts/common/global/nix/default.nix
```

Expected: command exits `0` and prints the current weekly, 10-day, 25-generation, 128MB, and 1GB values.

- [ ] **Step 2: Verify current manual cleanup policy is not the target policy**

Run:

```bash
rg -n 'older-than 7d|delete-older-than 7d' Makefile
```

Expected: command exits `0` and prints the current 7-day manual cleanup values.

### Task 2: Implement Daily Aggressive Automated Cleanup

**Files:**
- Modify: `hosts/common/global/nix/default.nix`

- [ ] **Step 1: Update the shared Nix cleanup policy**

Change `hosts/common/global/nix/default.nix` so the relevant settings are:

```nix
      min-free = 1073741824; # 1GB
      max-free = 5368709120; # 5GB
```

and:

```nix
      clean = {
        enable = true;
        dates = "daily";
        extraArgs = "--keep-since 3d --keep 5";
      };
```

- [ ] **Step 2: Run formatter**

Run:

```bash
nixfmt hosts/common/global/nix/default.nix
```

Expected: command exits `0`.

- [ ] **Step 3: Verify target automated cleanup policy appears**

Run:

```bash
rg -n 'dates = "daily"|--keep-since 3d --keep 5|min-free = 1073741824|max-free = 5368709120|auto-optimise-store = true|automatic = false' hosts/common/global/nix/default.nix
```

Expected: command exits `0` and prints all target settings.

### Task 3: Align Manual Cleanup

**Files:**
- Modify: `Makefile`

- [ ] **Step 1: Update manual cleanup retention**

Change the `gc` target in `Makefile` so:

```make
	echo "Wiping profile history older than 3 days..."; \
	sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 3d; \
	echo "Running garbage collection..."; \
	sudo nix store gc; \
	echo "Deleting old generations of garbage..."; \
	sudo nix-collect-garbage --delete-older-than 3d; \
```

- [ ] **Step 2: Verify target manual cleanup policy appears**

Run:

```bash
rg -n 'older than 3 days|older-than 3d|delete-older-than 3d' Makefile
```

Expected: command exits `0` and prints the updated manual cleanup lines.

### Task 4: Evaluate Configuration

**Files:**
- Read: `hosts/common/global/nix/default.nix`
- Read: `Makefile`

- [ ] **Step 1: Evaluate frametop cleanup settings**

Run:

```bash
nix eval .#nixosConfigurations.frametop.config.programs.nh.clean.dates --raw
nix eval .#nixosConfigurations.frametop.config.programs.nh.clean.extraArgs --raw
nix eval .#nixosConfigurations.frametop.config.nix.settings.min-free
nix eval .#nixosConfigurations.frametop.config.nix.settings.max-free
```

Expected output:

```text
daily
--keep-since 3d --keep 5
1073741824
5368709120
```

- [ ] **Step 2: Evaluate woody cleanup settings**

Run:

```bash
nix eval .#nixosConfigurations.woody.config.programs.nh.clean.dates --raw
nix eval .#nixosConfigurations.woody.config.programs.nh.clean.extraArgs --raw
nix eval .#nixosConfigurations.woody.config.nix.settings.min-free
nix eval .#nixosConfigurations.woody.config.nix.settings.max-free
```

Expected output:

```text
daily
--keep-since 3d --keep 5
1073741824
5368709120
```

- [ ] **Step 3: Check changed files**

Run:

```bash
git diff -- hosts/common/global/nix/default.nix Makefile
```

Expected: diff only contains the cleanup policy changes described above.
