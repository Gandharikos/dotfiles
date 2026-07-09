# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this
repository.

## Repository Overview

This is a comprehensive NixOS dotfiles repository using Nix flakes and flake-parts for
multi-platform system configuration (NixOS, macOS/nix-darwin, WSL). It employs a modular
architecture with custom library functions, declarative secret management via SOPS, and Home Manager
for cross-platform user environments.

## Common Commands

All commands use the `just` command runner (see `justfile`):

### Building & Deployment

```bash
# Build configuration without switching (test)
just build [hostname]            # Defaults to current hostname
just test [hostname]             # Alias for build without activation

# Apply configuration
just switch [hostname]           # Switch to new configuration
just boot [hostname]             # Set as boot default (don't activate now)
just rollback                    # Rollback to previous generation

# Remote deployment
just deploy <hostname> [action]  # Deploy to remote host (default: switch)
                                 # Shows nix store diff after deployment

# Installation (new systems)
just install <hostname> <target> # Install via nixos-anywhere
just disko <hostname>            # Declarative disk partitioning + install
```

### Development & Maintenance

```bash
# Code quality
just fmt                         # Format all Nix files (treefmt + nixfmt)
just check                       # Validate flake + run statix linter

# Updates
just update [inputs...]          # Update flake inputs (all or specific)

# Garbage collection
just clean                       # Remove system generations >7 days old
just gc                          # Garbage collect + optimize Nix store
just gcroot                      # List GC roots

# Utilities
just verify                      # Verify Nix store integrity
just repair [paths...]           # Repair corrupted store entries
just history                     # Show system generation history
```

### Development Workflows

```bash
# REPL
just repl                        # Open Nix REPL with flake loaded
just repl-host [hostname]        # Open REPL for specific host config

# Dev shells
just dev [name]                  # Enter dev shell (default or named)

# Config management (for testing non-NixOS programs)
just cfg <program>               # Copy config from repo to ~/.config/
just add <program>               # Copy config from ~/.config/ to repo
just rm <program>                # Remove program config from ~/.config/
```

### Secret Management

```bash
# Decrypt secrets to local paths
just decrypt [hostname]          # Decrypt SSH keys for host

# Initialize remote host with secrets
just init-remote <host> <ip>     # Setup SSH keys on remote host
```

## Architecture & Module Organization

### Layered Module System

The repository follows a 4-layer architecture:

1. **Platform Layer** (`modules/{common,nixos,darwin}/`): Platform-specific system configs
2. **User Layer** (`modules/home/`): Cross-platform user environment (Home Manager)
3. **Host Layer** (`hosts/`): Machine-specific configurations and overrides
4. **Library Layer** (`lib/`): Reusable functions shared across modules

### Custom Library (`lib.my.*`)

All custom library functions are available under `lib.my`:

**Path Helpers:**

- `lib.my.relativeToRoot`: Path relative to repository root
- `lib.my.relativeToConfig`: Path relative to `config/` directory
- `lib.my.getFile <path>`: Get file path relative to root
- `lib.my.scanPaths <dir>`: Auto-import all `.nix` files and directories with `default.nix`
- `lib.my.importDir <dir> <args>`: Import all `.nix` files from directory and merge

**Module Helpers:**

- `lib.my.mkProgram pkgs "name" {...}`: Create standard program option with enable + package

**Theme & UI Helpers:**

- See `lib/theme.nix`, `lib/geometry.nix`, `lib/workspaces.nix` for desktop-specific utilities

### Module Pattern

Standard module structure:

```nix
{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) str;
  cfg = config.my.category.feature;
in
{
  options.my.category.feature = {
    enable = mkEnableOption "feature description";
    # ... more options
  };

  config = mkIf cfg.enable {
    # Implementation
  };
}
```

**Key conventions:**

- All user options go under `config.my.*` namespace
- Use `inherit` to import frequently-used functions from lib
- Store config in `cfg` variable (convention: `cfg = config.my.<path-to-module>`)
- Wrap implementation in `mkIf cfg.enable` when module is optional
- Use `lib.my.scanPaths ./.` in `default.nix` to auto-import submodules

### Directory Auto-Import

Most `default.nix` files use:

```nix
{ lib, ... }: {
  imports = lib.my.scanPaths ./.;
}
```

This automatically imports:

- All `.nix` files in the directory (except `default.nix`)
- All subdirectories containing `default.nix`

### The `my.*` Options Namespace

Core user/system options are defined in `modules/common/my/`:

- `my.name`: Username (default: "johnson")
- `my.fullName`: Full name
- `my.email`: Email address
- `my.shell`: Default shell (bash/fish/zsh/nushell)
- `my.home`: Home directory path
- `my.theme.*`: Theme configuration (wallpaper, avatar, colorscheme)
- `my.keyboard.*`: Keyboard layout and custom key mappings
- `my.machine.*`: Hardware type and capabilities
- `my.gui.*`: GUI/desktop configuration
- `my.network.*`: Network and proxy settings

Access these throughout the config via `config.my.*`

## Host Configuration

### Host Discovery

Hosts are auto-discovered from `hosts/` directory by `flake/hosts.nix` using the flake-hosts module.
Each host directory must contain:

- `default.nix`: Entry point with module imports
- `config.nix`: Host-specific options (sets `my.*` options)
- `hardware-configuration.nix`: Hardware config (NixOS only, generated via `nixos-generate-config`)

### Creating a New Host

```bash
# 1. Create directory
mkdir -p hosts/hostname

# 2. Create config.nix (set my.* options)
cat > hosts/hostname/config.nix <<EOF
{ ... }: {
  my = {
    name = "username";
    machine.type = "laptop";  # workstation/server/laptop/desktop/vm/wsl
    gui.enable = true;
    # ... other my.* options
  };
}
EOF

# 3. Create default.nix (import modules)
cat > hosts/hostname/default.nix <<EOF
{ ... }: {
  imports = [
    ./config.nix
    ./hardware-configuration.nix  # NixOS only
  ];
}
EOF

# 4. Generate hardware config (NixOS only)
nixos-generate-config --show-hardware-config > hosts/hostname/hardware-configuration.nix

# 5. Test build
just build hostname
```

Host is automatically added to flake outputs by flake-hosts.

## Secrets with SOPS

Secrets are encrypted using SOPS with age keys. Configuration in `.sops.yaml`.

### Secret Structure

```
secrets/
├── core/           # System-level secrets (SSH keys)
├── johnson/        # User-specific secrets
└── services/       # Service credentials and API keys
```

### Working with Secrets

```bash
# Edit encrypted file (uses $EDITOR)
sops secrets/path/to/secret.yaml

# View encrypted file
sops -d secrets/path/to/secret.yaml

# Rotate keys after adding new host
sops updatekeys secrets/path/to/secret.yaml
```

### Using Secrets in Modules

```nix
{ config, ... }: {
  sops.secrets."service/api-key" = {
    sopsFile = ../../../secrets/services/example.yaml;
    owner = config.my.name;
  };

  # Reference the secret path
  services.example.apiKeyFile = config.sops.secrets."service/api-key".path;
}
```

Secrets are decrypted at activation time to `/run/secrets/`.

## Flake Structure

```
flake/
├── hosts.nix              # Host auto-discovery and class-specific modules
├── packages.nix           # Export custom packages
├── devshell.nix           # Development shell environments
├── formatter.nix          # treefmt configuration
├── overlays.nix           # Package overlays
├── pre-commit-hooks.nix   # Git hooks (formatting, linting)
└── templates.nix          # Flake templates
```

Each flake-parts module exports specific outputs (nixosConfigurations, packages, devShells, etc.).

## Common Patterns

### Adding a New GUI Application

1. Add package to appropriate module in `modules/home/gui/apps/`
2. Configure using `my.gui.apps.<name>.enable` option
3. Theme integration typically lives in the same module
4. Fonts go in `modules/home/gui/fonts/`

### Adding a New CLI Tool

1. Add to `modules/home/cli/tools/` or appropriate subcategory
2. Create option under `my.cli.<category>.<name>`
3. Shell integration (aliases, functions) in respective shell modules
4. Use `programs.<name>` from Home Manager when available

### Adding a New NixOS Service

1. Create module in `modules/nixos/services/<category>/`
2. Define options under `my.<category>.<service>`
3. Use systemd service definitions when needed
4. Secrets via sops if credentials required

### Modifying Desktop Environment

Desktop configs are in `modules/home/gui/desktop/`:

- `wayland/wms/`: Window manager configs (Hyprland, Niri, COSMIC)
- `wayland/shells/`: Desktop shells (DankMaterialShell)
- `darwin/`: macOS desktop (Aerospace window manager)

Keybindings use `config.my.keyboard.keys.*` for cross-WM consistency.

### Theme Customization

1. Theme definitions in `modules/common/my/theme/`
2. Wallpapers: `my.theme.wallpaper` (defaults to `modules/common/my/theme/nix.png`)
3. Avatar: `my.theme.avatar` (defaults to `config/avatars/makima.jpg`)
4. Colorscheme: `my.theme.default` ("tokyonight" or "catppuccin")
5. Theme files in `config/<program>/themes/` for program-specific themes

## Pre-commit Hooks

Enabled automatically in dev shell (`just dev` or `nix develop`):

- `treefmt`: Formats all Nix code with nixfmt
- `statix`: Lints Nix code for anti-patterns
- `deadnix`: Detects unused Nix code
- Conventional commit message validation
- Large file detection
- Merge conflict detection

Run manually: `just fmt` and `just check`

## Testing Changes

1. **Build test**: `just build hostname` - builds without switching
2. **Local test**: `just switch hostname` - activates on local machine
3. **VM test**: `nixos-rebuild build-vm --flake .#hostname` - test in VM
4. **Remote test**: `just deploy hostname test` - build on remote without activation

Always test on a non-production host first (e.g., `loki` or `ymir` hosts).

## Troubleshooting

### Build Failures

```bash
# Check flake structure
nix flake check

# Build with verbose output
nix build .#nixosConfigurations.hostname.config.system.build.toplevel -L -v

# Clean and retry
nix-collect-garbage -d
just build hostname
```

### Module Import Errors

- Verify `lib.my.scanPaths` is used in `default.nix`
- Check for circular imports
- Ensure all required arguments are in function signature

### Secret Decryption Issues

```bash
# Verify age key exists
ls ~/.config/sops/age/keys.txt

# Check key permissions
chmod 600 ~/.config/sops/age/keys.txt

# Verify key is in .sops.yaml
age-keygen -y ~/.config/sops/age/keys.txt
```

### Home Manager Conflicts

If Home Manager fails due to existing files:

```bash
# Backup existing config
mv ~/.config/conflicting-app ~/.config/conflicting-app.bak

# Or remove if safe
just rm conflicting-app

# Retry
just switch hostname
```

## Rollback Procedures

### NixOS

```bash
# CLI rollback
just rollback

# Or at boot: select previous generation in bootloader menu
```

### macOS (Darwin)

```bash
# List generations
ls -l /nix/var/nix/profiles/system-*

# Activate previous
/nix/var/nix/profiles/system-<N>-link/activate
```

### Home Manager

```bash
# List generations
home-manager generations

# Activate specific generation
/nix/var/nix/profiles/per-user/$USER/home-manager-<N>-link/activate
```

## Key Files Reference

- `flake.nix`: Flake inputs and outputs (delegates to `flake/` modules)
- `justfile`: Command definitions
- `.sops.yaml`: Secret encryption configuration
- `lib/default.nix`: Custom library functions entry point
- `modules/common/my/default.nix`: Core user options
- `config/`: Application dotfiles (sourced via `lib.my.relativeToConfig`)

## Platform Detection

```nix
# In modules, use:
pkgs.stdenv.hostPlatform.isLinux    # True on NixOS/WSL
pkgs.stdenv.hostPlatform.isDarwin   # True on macOS
config.my.machine.type              # "laptop"/"desktop"/"server"/etc
```

## Important Conventions

1. **Never hardcode paths**: Use `lib.my.relativeToRoot` or `lib.my.relativeToConfig`
2. **Use `my.*` namespace**: All custom options under `config.my.*`
3. **Auto-import pattern**: `imports = lib.my.scanPaths ./.;` in most `default.nix`
4. **Secrets externalized**: Never inline secrets, use SOPS
5. **Cross-platform first**: Prefer `modules/home/` unless platform-specific
6. **Enable options**: Most modules have `*.enable` to toggle features
7. **Conventional commits**: Use `feat:`, `fix:`, `docs:`, `refactor:`, etc.
