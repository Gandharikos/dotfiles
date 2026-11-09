---
title: Deployment
description: Build, switch, and remote deployment commands.
---

Deployments are handled with `just` wrappers around NixOS, nix-darwin, and remote rebuild commands.

## Build Without Activation

Use the appropriate platform output:

```bash
nix build --no-link .#nixosConfigurations.<host>.config.system.build.toplevel
nix build --no-link .#darwinConfigurations.<host>.system
```

## Local Rebuilds

```bash
just switch <host>
just boot <host>
just test <host>
```

On NixOS, `just test` builds and activates the configuration temporarily without making it the boot
default. It can restart services and interrupt networking: it is not a build-only check. Build and
review the changes first, then follow the network recovery gates before a network-related
activation. Use the Darwin build command above for build-only validation on macOS.

## Darwin Host Profiles

`tyr` uses the desktop profile with GUI configuration and Kanata keyboard remapping enabled. The
minimal profile is disabled, so the full Home Manager defaults and Homebrew package lists, automatic
upgrades and `zap` cleanup apply on its next activation.

For a minimal host, `dot.profiles.minimal.enable = true` omits development environments and optional
tools. GUI configuration and keyboard remapping are separate settings; macOS itself, Remote Login
and Screen Sharing are not disabled by `dot.gui.enable = false`.

On minimal Darwin hosts, the shared Homebrew module contributes no formulae or casks and disables
activation-time upgrades and cleanup. Homebrew and its pinned taps remain available. Existing
applications and their data are intentionally retained; this is not an uninstall or disk-cleanup
operation. Other modules can still add Homebrew packages. Non-minimal hosts retain their existing
package lists, upgrades and `zap` cleanup policy.

Build before activation:

```bash
nix --extra-experimental-features pipe-operators build --no-link .#darwinConfigurations.tyr.system
```

Restoring the desktop profile does not change `tyr`'s Tailscale role or advertised subnet. They are
not proof of deployment or successful remote forwarding. Review the generated activation and
preserve a recovery path before switching a headless host.

## Remote Deployment

```bash
just deploy <host>
```

The deploy command records the remote system generation before and after the switch, then prints a
closure diff when the generation changes.

## Checks

```bash
just check
```

This runs `nix flake check`, optional `statix check .`, and the default regression suite.
`nix flake check` also includes the Python script regressions as a sandboxed check.

Run regressions separately:

```bash
just regression
```

The pinned `tests` development shell supplies Python with PyYAML, Bash, jq, OpenSSH and Nix. The
default suite runs mocked Python tests and Nix configuration assertions for networking, WSL, proxy
backends/profiles and storage. It does not decrypt real secrets, activate configurations or restart
services. The three real sing-box/converter tests are explicitly skipped in this mode. Nix may still
fetch locked inputs or tools.

For the real-core/converter tests, isolated routing checks and backup preparation fixtures:

```bash
just regression integration
```

Integration mode currently requires x86_64 Linux. It builds the pinned binaries and backup fixture,
and uses an unprivileged user/network namespace for routing tests. It does not alter host routes or
live service data; disabled user namespaces cause a test failure rather than a silent skip. The
provider-seed test remains a separate fixture requiring a built seed-program argument.

CI runs flake checks and default regressions for pull requests and main-branch changes to Nix,
Python, shell scripts, config data and the justfile. Relevant changes are not skipped based on
commit-message prefixes.

## Formatting

```bash
just fmt
```

The formatter is defined by the flake and should be run before committing Nix changes.
