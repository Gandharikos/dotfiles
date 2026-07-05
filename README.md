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

## Docs

Please read [document](docs/src/content/docs/index.md).

Documentation lives at <https://gandharikos.github.io/.dotfiles/> and in [`docs/`](docs/). The docs
site is built with Astro Starlight:

```bash
cd docs
npm install
npm run dev
```

Build a static copy with:

```bash
npm run build
```

## Common Commands

```bash
just switch <host>
just test <host>
just deploy <host>
just check
just fmt
```

## License

See [`LICENSE`](LICENSE).
