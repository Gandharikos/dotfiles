---
title: Desktop
description: Desktop stack and visual configuration.
---

The desktop layer is Wayland-first and centered around reusable Home Manager and NixOS modules.

## Window Managers

- Hyprland
- Niri
- COSMIC-related modules where useful

Window manager configuration lives under:

```text
users/johnson/home/gui/desktop/wayland/wms/
modules/nixos/gui/desktop/wayland/wms/
```

## Shells And Tools

The Wayland desktop includes launchers, idle handling, screenshot tools, desktop shell integrations,
terminals, browsers, editors, and GUI applications.

Important areas:

- `users/johnson/home/gui/desktop/wayland/`
- `users/johnson/home/gui/apps/`
- `users/johnson/home/gui/browsers/`
- `users/johnson/home/gui/terminals/`
- `users/johnson/home/theme/`

## Theme

The active theme modules keep shell, terminal, GTK, Qt, editor, and CLI tools visually consistent.
Theme-specific files live under `users/johnson/home/theme/`.
