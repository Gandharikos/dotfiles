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

## AeroSpace on macOS

`eir` uses Rex as its terminal launcher and Google Chrome as its browser launcher. Both apps must
already be installed on macOS; launchers resolve their bundle IDs rather than a version-specific
application name. AeroSpace's terminal shortcut uses the configured terminal command, and newly
detected Rex and Chrome windows go to workspace 1. Existing window placements are not changed by
editing the configuration. `TERMINAL` and `BROWSER` point to launch scripts that forward arguments
to `open -b`; Rex launch arguments are macOS open targets, not terminal `-e` commands. The Rex CLI
remains available separately. macOS default-browser associations are not overwritten by this
configuration; select Chrome in System Settings if needed.

`tyr` keeps Ghostty as its default terminal. On macOS, the terminal command uses
`/usr/bin/open -n -b com.mitchellh.ghostty` to open the Homebrew app, avoiding the GTK/Wayland build
dependencies of `pkgs.ghostty`. Linux retains the Nix-packaged Ghostty command and its `+new-window`
argument.

The Darwin AeroSpace module corrects a path bug in the pinned Home Manager module: stripping the
home directory from `xdg.configHome` leaves a leading slash, which Putter interprets as a root path
such as `/.config/aerospace/aerospace.toml`. The local target override keeps the configuration under
the configured XDG directory without changing its generated contents or reload hook. Putter remains
enabled; no root-directory permission changes are needed.

Validate application defaults, macOS/Linux Ghostty commands, the default and custom XDG paths, and
XDG-disabled mode:

```sh
nix --extra-experimental-features pipe-operators eval --impure --json \
  --file tests/aerospace.nix
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

## JACK Audio on Linux

GUI-enabled NixOS hosts use PipeWire with PulseAudio and ALSA compatibility. JACK applications must
be launched with `pw-jack <program>`, provided by the configured PipeWire package's `jack` output.
This scopes JACK library overrides to that process instead of setting a global `LD_LIBRARY_PATH`
through the deprecated `services.pipewire.jack.enable` option.

## Fastfetch images

Home Manager builds the images in `config/fastfetch/pngs/` into 512×512 RGBA PNGs, matching the
original `Makima_nixos.png` canvas. Images are scaled proportionally and centered with transparent
padding; the source files are not changed. ImageMagick is only a build dependency. Fastfetch
randomly selects a generated image and uses the original Makima display settings: 18 rows high, with
width calculated automatically rather than forced to 36 columns. It uses Kitty graphics when Kitty
or Ghostty is enabled and Chafa otherwise.

Existing padding inside an image is retained, so the visible subject may still vary in size.

## Herdr smart quit

`Ctrl+Q` follows the tmux smart-quit behavior: forward the key to foreground Vim/Neovim (including
view/diff variants), otherwise close the current pane. This can terminate a running command or AI
tool; it is not limited to idle shells. Editor save/quit behavior is controlled by its own `Ctrl+Q`
mapping.

The binding in `users/johnson/home/cli/mux/herdr.nix` runs `scripts/herdr-smart-quit.sh`. It targets
the pane captured by Herdr in `HERDR_ACTIVE_PANE_ID`, even if focus changes while the command runs.
Failed queries, empty or malformed process information, and mismatched pane IDs never close a pane.
Only local foreground process names are inspected; an editor running behind SSH or a nested
multiplexer is not detected.

Validate without closing real panes:

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s tests -p 'test_herdr_smart_quit.py' -v
```

After activating the Home Manager configuration, reload Herdr with `prefix+Ctrl+R`.

## Theme

The active theme modules keep shell, terminal, GTK, Qt, editor, and CLI tools visually consistent.
Theme-specific files live under `users/johnson/home/theme/`.
