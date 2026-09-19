<p align="center">
  <img src=".assets/nixos_logo.png" alt="NixOS logo" width="120" />
</p>

<h1 align="center">dotfiles</h1>

<p align="center">
  Personal NixOS, nix-darwin, and Home Manager configuration.
  Modular, reproducible, and built around flakes.
</p>

![Desktop screenshot](.assets/Screenshot_2026-07-04_10-16-06.png-region.png)

## Foreword

This is a personal system configuration. It is useful as a reference, but it is not meant to be
cloned and switched blindly. Host names, disks, secrets, keys, and hardware assumptions are specific
to my machines.

Encrypted secrets are required for most real deployments. Read the docs before reusing any module.

## What's Inside

- NixOS, nix-darwin, WSL, and Home Manager configurations
- Reusable modules for desktop, networking, hardware, security, and services
- SOPS-managed secrets for users, hosts, and self-hosted services
- Declarative disks with Disko and installer-oriented host layouts
- Wayland desktops with Hyprland, Niri, shells, themes, and tools

## Common Commands

```bash
just switch <host>
just test <host>
just deploy <host>
just check
just fmt
```

## Chromium Extension Updates

The **Update Chromium extensions** GitHub Action runs daily and supports manual dispatch. It opens a
PR updating extension versions and SHA-256 hashes in `users/johnson/home/gui/browsers/chromium.nix`.
Enable GitHub Actions pull request creation in repository settings. Review updates before merging;
Chrome Web Store download URLs are mutable. Extensions returning HTTP 204 retain their existing pins
with a warning; other download or validation errors abort the update without writing changes.

To run locally:

```bash
python3 scripts/update-chromium-extensions.py
python3 -m unittest discover -s scripts/tests -v
```

## Docs

Please read the [documentation](https://gandharikos.github.io/dotfiles/).

## License

See [`LICENSE`](LICENSE).
