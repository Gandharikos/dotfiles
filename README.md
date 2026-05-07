# ❄️ My NixOS Configuration

[![Built with Nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Nix Flake](https://img.shields.io/badge/Nix-Flake-blue.svg)](https://wiki.nixos.org/wiki/Flakes)

> _"NixOS makes me feel like the world is my oyster"_ - A comprehensive, modular NixOS configuration
> supporting multiple platforms with declarative system management, dotfile synchronization, and
> secret management.

A sophisticated multi-platform Nix configuration repository utilizing flakes and flake-parts for
reproducible system configurations across NixOS, macOS (nix-darwin), and WSL environments. This
setup provides a unified development experience with consistent tooling, theming, and environment
management.

## 📑 Table of Contents

- [✨ Features & Highlights](#-features--highlights)
- [🚀 Quick Start](#-quick-start)
- [🏗️ Architecture](#️-architecture)
- [🖥️ Hosts](#️-hosts)
- [📚 Usage](#-usage)
- [🔧 Key Technologies](#-key-technologies)
- [🎨 Desktop Environment](#-desktop-environment)
- [🛠️ Development Environment](#️-development-environment)
- [🔐 Secret Management](#-secret-management)
- [🐛 Troubleshooting](#-troubleshooting)
- [🤝 Contributing](#-contributing)
- [📖 References](#-references)
- [📄 License](#-license)

## ✨ Features & Highlights

### 🌐 Cross-Platform Support

- **NixOS**: Full system configuration with desktop environment
- **macOS**: System preferences and package management via nix-darwin
- **WSL2**: Seamless Linux development environment on Windows
- **Home Manager**: Unified user environment across all platforms

### 🏛️ Modular Architecture

- **Flake-parts**: Clean, modular flake organization
- **Layered modules**: Common, platform-specific, and user configurations
- **Reusable components**: Shared configurations across multiple hosts
- **Type-safe configuration**: Leveraging Nix's type system for robust configs

### 🔒 Security & Secrets

- **SOPS Integration**: Encrypted secrets with age and GPG support
  - Per-host secret management
  - Multi-key encryption for team access
- **Impermanence**: Stateless system configuration for enhanced security
  - Declarative persistent data management
  - Automatic cleanup of temporary files
- **Hardware Security**:
  - YubiKey integration for GPG and SSH
  - Smart card support via gpg-agent
  - Hardware-backed authentication
- **Authentication**:
  - Soteria polkit agent for system authentication
  - Secure credential storage
- **Network Security**:
  - Firewall configurations
  - Proxy support with automatic configuration

### 🎮 Rich Desktop Experience

- **Multiple Wayland Compositors**: Hyprland, Niri, and COSMIC support
- **DMS Shell**: Material Design-inspired desktop shell with custom widgets
- **Extensive Plugin Ecosystem**: Hyprland plugins for enhanced functionality
- **Unified Theming**: Consistent Tokyo Night theme across all applications
- **Multi-Monitor**: Seamless multi-monitor configurations with per-monitor settings
- **Input Methods**: Full CJK support via fcitx5
- **Custom Keybindings**: Unified keyboard shortcuts across desktop environments

## 🚀 Quick Start

### Prerequisites

- **Nix package manager** (version 2.19+ with flakes enabled)
- **Git** for cloning the repository
- **Just** command runner (optional, but highly recommended)
- For NixOS: Installation media or existing NixOS system
- For macOS: macOS 12.0 (Monterey) or later

### Installation

#### 1. Enable Nix Flakes

If not already enabled:

```bash
# Create Nix config directory
mkdir -p ~/.config/nix

# Enable flakes and nix-command
cat >> ~/.config/nix/nix.conf <<EOF
experimental-features = nix-command flakes
EOF
```

#### 2. Clone the Repository

```bash
git clone https://github.com/yourusername/dotfiles ~/.dotfiles
cd ~/.dotfiles
```

#### 3. Initial Build

**For NixOS:**

```bash
# Using nixos-rebuild
sudo nixos-rebuild switch --flake .#hostname

# Or using nh (recommended, if available)
nh os switch .

# Or using just
just switch hostname
```

**For macOS (nix-darwin):**

```bash
# First-time setup
nix run nix-darwin -- switch --flake .#hostname

# Subsequent updates
darwin-rebuild switch --flake .#hostname

# Or using just
just switch hostname
```

**For Home Manager standalone:**

```bash
home-manager switch --flake .#username@hostname
```

### First-Time Setup Checklist

#### 1. Generate Age Key for Secrets

```bash
# Generate age key
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# Get public key
age-keygen -y ~/.config/sops/age/keys.txt

# Add public key to .sops.yaml in the repository
```

#### 2. Configure Host-Specific Settings

Create or modify your host configuration:

```bash
# Copy a template host
cp -r hosts/template hosts/yourhostname

# Edit configuration
vim hosts/yourhostname/config.nix

# Update username, timezone, hardware features, etc.
```

#### 3. Generate Hardware Configuration (NixOS only)

```bash
# Generate hardware config
nixos-generate-config --show-hardware-config > hosts/yourhostname/hardware-configuration.nix
```

#### 4. Setup SSH and GPG Keys

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your_email@example.com"

# Add to your Git provider (GitHub, GitLab, etc.)
cat ~/.ssh/id_ed25519.pub

# If using GPG with YubiKey, import your key
gpg --import your-key.asc
```

#### 5. First Build and Switch

```bash
# Test build without switching
just build yourhostname

# If successful, apply configuration
just switch yourhostname
```

### Quick Host Setup

For a new machine, use the installer ISO:

```bash
# Build installer ISO
just build installer

# Write to USB drive
dd if=result/iso/nixos.iso of=/dev/sdX bs=4M status=progress

# Boot from USB and follow installation prompts
```

## 🏗️ Architecture

### Repository Structure

```
📁 ~/.dotfiles/
├── 📁 flake/              # Flake-parts modules
│   ├── hosts.nix          # Host definitions and configuration loading
│   ├── packages.nix       # Custom package exports
│   ├── devshell.nix       # Development shell environments
│   ├── formatter.nix      # Code formatting (treefmt + nixfmt)
│   ├── overlays.nix       # Package overlays and modifications
│   ├── pre-commit-hooks.nix # Git pre-commit hooks configuration
│   └── templates.nix      # Flake templates for new projects
├── 📁 hosts/              # Host-specific configurations
│   ├── common/            # Shared configurations across all hosts
│   │   ├── cli/           # Common CLI tools and utilities
│   │   ├── development/   # Development environments and tools
│   │   └── nvim/          # Neovim configuration
│   ├── installer/         # NixOS installation ISO configuration
│   └── <hostname>/        # Individual host configurations
│       ├── default.nix    # Host entry point
│       ├── config.nix     # Host-specific options
│       └── hardware-configuration.nix  # Hardware-specific settings
├── 📁 modules/            # Modular system components
│   ├── common/            # Cross-platform modules
│   │   ├── environment/   # Environment variables and system paths
│   │   ├── nix/           # Nix configuration and settings
│   │   ├── packages/      # Common package lists
│   │   └── themes/        # Theme definitions and configurations
│   ├── nixos/             # NixOS-specific modules
│   │   ├── boot/          # Boot loader and kernel configurations
│   │   ├── environment/   # System environment settings
│   │   ├── gaming/        # Gaming-related configurations
│   │   ├── gui/           # Desktop environments and display managers
│   │   ├── hardware/      # Hardware-specific configurations
│   │   ├── kernel/        # Kernel modules and parameters
│   │   ├── networking/    # Network configuration and firewall
│   │   ├── security/      # Security, polkit, and authentication
│   │   ├── services/      # System services
│   │   ├── theme/         # System-wide theming
│   │   └── virtual/       # Virtualization and containerization
│   ├── darwin/            # macOS-specific modules
│   │   ├── apps/          # macOS applications
│   │   ├── brew/          # Homebrew package management
│   │   ├── defaults/      # macOS system preferences
│   │   ├── networking/    # Network settings for macOS
│   │   ├── services/      # macOS services
│   │   └── users/         # User account management
│   └── home/              # Home Manager modules
│       ├── cli/           # Command-line interface tools
│       │   ├── ai/        # AI tools and assistants
│       │   ├── editors/   # Text editors (helix, nvim, etc.)
│       │   ├── mux/       # Terminal multiplexers (tmux, zellij)
│       │   ├── pager/     # Pagers and file viewers
│       │   ├── security/  # Security tools (age, gpg, ssh)
│       │   ├── shells/    # Shell configurations (bash, fish, zsh)
│       │   ├── tools/     # CLI utilities and tools
│       │   └── vcs/       # Version control systems
│       ├── environment/   # User environment variables
│       ├── gui/           # Graphical user interface
│       │   ├── apps/      # GUI applications
│       │   ├── desktop/   # Desktop environments and WMs
│       │   │   ├── darwin/    # macOS desktop (Aerospace)
│       │   │   └── wayland/   # Wayland compositors
│       │   │       ├── idles/     # Idle management
│       │   │       ├── locks/     # Screen lockers
│       │   │       ├── shell/     # Desktop shell (DMS)
│       │   │       ├── shots/     # Screenshot tools
│       │   │       └── wms/       # Window managers
│       │   │           ├── hyprland/  # Hyprland compositor
│       │   │           ├── niri/      # Niri compositor
│       │   │           └── cosmic/    # COSMIC desktop (NixOS only)
│       │   ├── fonts/     # Font configurations
│       │   ├── gtk/       # GTK theming
│       │   ├── qt/        # Qt theming
│       │   └── terminals/ # Terminal emulators
│       ├── langs/         # Programming language environments
│       │   ├── cc.nix         # C/C++ toolchain
│       │   ├── java.nix       # Java development
│       │   ├── lua.nix        # Lua and LuaRocks
│       │   ├── node.nix       # Node.js and npm/yarn/pnpm
│       │   ├── python.nix     # Python environments
│       │   ├── r.nix          # R language and packages
│       │   ├── rust.nix       # Rust toolchain
│       │   └── shell.nix      # Shell scripting tools
│       └── theme/         # User-level theming
├── 📁 lib/                # Custom library functions and helpers
├── 📁 packages/           # Custom package definitions
├── 📁 config/             # Application dotfiles and configurations
│   ├── avatars/           # User avatar images
│   ├── fastfetch/         # System information tool config
│   ├── fcitx5/            # Input method framework
│   ├── kanata/            # Keyboard remapping
│   ├── nvim/              # Neovim configuration
│   └── wezterm/           # WezTerm terminal config
├── 📁 secrets/            # SOPS-encrypted secrets
│   ├── core/              # Core system secrets
│   ├── johnson/           # User-specific secrets
│   └── services/          # Service credentials and API keys
├── 📁 overlays/           # Nixpkgs overlays
├── 📁 templates/          # Project templates
└── flake.nix             # Main flake configuration
```

### Module Organization Philosophy

The configuration follows a layered architecture:

1. **Platform Layer** (`modules/common/`, `nixos/`, `darwin/`): Platform-specific system
   configurations
2. **User Layer** (`modules/home/`): Cross-platform user environment managed by Home Manager
3. **Host Layer** (`hosts/`): Machine-specific configurations and overrides
4. **Library Layer** (`lib/`): Reusable functions and utilities shared across modules

## 🖥️ Hosts

### Production Hosts

| Host       | Platform | Type        | Desktop   | Description                                          |
| ---------- | -------- | ----------- | --------- | ---------------------------------------------------- |
| **tyr**    | Darwin   | Mac Mini    | Aerospace | Primary macOS workstation for development and media  |
| **sigurd** | NixOS    | Desktop     | Hyprland  | High-performance Linux workstation with GPU          |
| **eir**    | Darwin   | MacBook Air | Aerospace | Portable development machine for travel and learning |

### Development & Testing

| Host          | Platform | Type     | Desktop  | Description                                 |
| ------------- | -------- | -------- | -------- | ------------------------------------------- |
| **ymir**      | NixOS    | Laptop   | Niri     | Testing ground for new NixOS configurations |
| **loki**      | NixOS    | Flexible | Various  | Multi-purpose host for experimentation      |
| **nidhogg**   | WSL2     | Virtual  | Headless | Linux development environment on Windows    |
| **installer** | NixOS    | ISO      | N/A      | Custom NixOS installation media             |

### Host Configuration

Each host has its own directory under `hosts/` with:

- `default.nix`: Host entry point and module imports
- `config.nix`: Host-specific options (username, timezone, hardware features)
- `hardware-configuration.nix`: Auto-generated hardware configuration (NixOS only)

Common configurations shared across hosts are in `hosts/common/`:

- CLI tools and shell configurations
- Development environment setup
- Neovim configuration and plugins

## 📚 Usage

### Building & Deployment

```bash
# Build system configuration (test without switching)
just build [hostname]

# Apply configuration changes
just switch [hostname]      # Using nh (recommended)
just switch2 [hostname]     # Classic nixos-rebuild/darwin-rebuild

# Deploy to remote host
just deploy <hostname>

# Fresh installation
just install <hostname>     # Install on existing OS
just disko <hostname>       # Full disk setup + install
```

### Development & Maintenance

```bash
# Code quality & formatting
just fmt                   # Format all Nix files with treefmt
just check                 # Validate flake & run statix linting

# Updates & maintenance
just up                    # Update all flake inputs
just upp <input>           # Update specific input
just clean                 # Remove system generations older than 7 days
just gc                    # Garbage collect unused Nix store entries
just verify                # Verify all store entries for corruption
just repair <paths>        # Repair corrupted Nix store objects

# Development workflows
just dev [shell]           # Enter development shell (default or named)
just cfg <program>         # Move program config to ~/.config for development
just add <program>         # Backup program config from ~/.config to repo
just rm <program>          # Remove program's config folder

# Advanced operations
just offline <host>        # Build configuration in offline mode
just repl                  # Open Nix REPL with flake loaded
```

## 🔧 Key Technologies

### Core Infrastructure

- **[Nix Flakes](https://wiki.nixos.org/wiki/Flakes)**: Modern package management with lock files
  for reproducible builds
- **[flake-parts](https://flake.parts/)**: Modular flake architecture with composable modules
  - Clean separation of concerns (hosts, packages, devshells, formatters)
  - Extensible configuration system
- **[Home Manager](https://github.com/nix-community/home-manager)**: Declarative dotfile and user
  environment management across platforms

### Development Tools

- **[devshell](https://github.com/numtide/devshell)**: Enhanced development shell environments
- **[treefmt](https://github.com/numtide/treefmt-nix)**: Multi-language code formatting
  - nixfmt for Nix files
  - Pre-configured formatters per language
- **[pre-commit-hooks](https://github.com/cachix/git-hooks.nix)**: Git hooks with Nix integration
  - Automatic code formatting
  - Linting (statix, deadnix, nil)
  - Conventional commit validation

### System Management

- **[SOPS](https://github.com/Mic92/sops-nix)**: Secure secret management
  - Age encryption by default
  - GPG support for team workflows
  - Per-host secret decryption
- **[disko](https://github.com/nix-community/disko)**: Declarative disk partitioning
  - Automated installation workflows
  - Reproducible disk layouts
- **[impermanence](https://github.com/nix-community/impermanence)**: Stateless system configuration
  - Explicit persistence declarations
  - Enhanced security posture

### Platform-Specific

- **[nix-darwin](https://github.com/LnL7/nix-darwin)**: macOS system configuration
  - System preferences management
  - Homebrew integration via nix-homebrew
- **[nixos-wsl](https://github.com/nix-community/NixOS-WSL)**: NixOS for Windows Subsystem for Linux
  - Native WSL integration
  - Systemd support
- **[nixos-hardware](https://github.com/nixos/nixos-hardware)**: Hardware-specific configurations
  - Optimized settings for specific hardware

### Desktop & Graphics

- **[Hyprland](https://hyprland.org/)**: Dynamic tiling Wayland compositor
  - Extensive plugin ecosystem
  - Advanced animations and effects
- **[Niri](https://github.com/YaLTeR/niri)**: Scrollable-tiling Wayland compositor
  - Innovative workspace model
- **[DMS](https://github.com/gjSCUT/dank-material-shell)**: Desktop shell framework
  - Material Design aesthetics
  - Customizable widgets
- **[uwsm](https://github.com/Vladimir-csp/uwsm)**: Universal Wayland Session Manager
  - Session management across compositors
  - Environment variable handling

## 📦 Custom Packages

The repository includes numerous custom package definitions in `packages/`:

### Zellij Plugin Ecosystem

An extensive collection of Zellij plugins for enhanced terminal multiplexing:

**Session & Workspace Management:**

- `zellij-sessionizer`: Tmux-sessionizer clone for Zellij
- `zellij-switch`: Quick session switching
- `zellij-workspace`: Workspace management
- `zellij-bookmarks`: Bookmark frequently used sessions
- `zellij-favs`: Favorite session quick access

**Navigation & Layout:**

- `vim-zellij-navigator`: Seamless vim/zellij navigation
- `zellij-jump-list`: Jump to recent locations
- `zellij-choose-tree`: Tree-based session picker
- `zjframes`: Frame layout management
- `zjpane`: Enhanced pane operations
- `zbuffers`: Buffer management
- `multitask`: Multi-pane task runner
- `monocle`: Focus mode layout
- `room`: Workspace isolation
- `harpoon`: Quick file navigation

**UI & Status:**

- `zjstatus`: Enhanced status bar
- `zj-status-bar`: Alternative status bar
- `zashboard`: Dashboard interface

**Productivity:**

- `zellij-autolock`: Automatic session locking
- `zellij-forgot`: Command history helper
- `zellij-cb`: Clipboard integration
- `zellij-datetime`: Date and time display
- `zj-docker`: Docker container management
- `zj-quit`: Enhanced quit functionality

### Desktop & Theming

- `bibata-hyprcursor`: Bibata cursor theme with hyprcursor support
- `bibata-xcursor`: Bibata cursor theme for X11/Wayland
- `plymouth-themes`: Custom Plymouth boot splash themes

### Applications

- `equicord`: Equibop Discord client (custom build)
- `vencord`: Enhanced Discord client

### Development Tools

- `jbz`: Custom JetBrains toolbox wrapper
- `sub2singbox`: Subscription to sing-box converter

All packages are automatically built and exported through the flake for use across hosts.

## 🎨 Desktop Environment

### Wayland Compositors (NixOS)

#### Hyprland

- **[Hyprland](https://hyprland.org/)**: Dynamic tiling Wayland compositor with advanced features
  - Extensive plugin system (hyprfocus, hyprsplit, hyprgrass, hypr-dynamic-cursors)
  - Custom animations and window rules
  - Multi-monitor support with per-monitor configuration
  - Integration with hyprnome for workspace management
  - hyprshell for window switching

#### Niri

- **[Niri](https://github.com/YaLTeR/niri)**: Scrollable-tiling Wayland compositor
  - Unique scrollable workspace paradigm
  - Window management keybindings (center, resize, maximize)
  - Advanced layout configurations
  - Monitor and input management

#### COSMIC (Experimental)

- **[COSMIC Desktop](https://github.com/pop-os/cosmic-epoch)**: System76's Rust-based desktop
  environment
  - Modern desktop experience
  - Built with Rust for performance and safety

### Desktop Shell & Components

- **[DMS (Dank Material Shell)](https://github.com/gjSCUT/dank-material-shell)**: Material
  Design-inspired desktop shell
  - Custom widgets and bars
  - System monitoring (dgop)
  - Unified keybinding system across compositors
  - Integration with uwsm (Universal Wayland Session Manager)

### Desktop Tools

- **Screen Locking**: hyprlock, swaylock integration
- **Idle Management**: hypridle, swayidle for power management
- **Screenshots**: grimblast, wayshot for screenshot capture
- **Wallpapers**: hyprpaper, swww for wallpaper management
- **Notifications**: mako notification daemon
- **Application Launcher**: Rofi/wofi integration

### macOS Integration (Darwin)

- **[Aerospace](https://github.com/nikitabobko/AeroSpace)**: i3-like tiling window manager for macOS
  - Declarative workspace configuration
  - Keyboard-driven window management
- **System Preferences**: Declarative macOS settings via nix-darwin
  - Dock, Finder, and system-wide preferences
  - Keyboard shortcuts and input settings
- **Homebrew**: GUI application management through nix-darwin
  - Casks for GUI applications
  - Native macOS app integration

### Theming & Appearance

- **Color Schemes**:
  - Tokyo Night: Primary dark theme
  - Catppuccin: Alternative color scheme support
- **Fonts**:
  - JetBrains Mono: Primary monospace font
  - Nerd Font patches for icon support
  - CJK font support via fcitx5
- **Cursor Themes**:
  - Bibata cursor (with hyprcursor support)
  - Custom cursor configurations per desktop
- **GTK/Qt Theming**: Consistent theming across toolkits
  - GTK theme integration
  - Qt5/Qt6 styling
  - Icon themes

## 🛠️ Development Environment

### Editors & IDEs

- **Neovim**: Heavily customized modern Vim configuration
  - LSP support for multiple languages (rust-analyzer, pyright, typescript, etc.)
  - AI integration (Copilot, Supermaven, codeium)
  - Tree-sitter for syntax highlighting
  - Custom plugins and workflows
  - Obsidian integration for note-taking
- **Helix**: Modern modal editor with built-in LSP
  - Tree-sitter integration
  - Multiple selections
  - Space-based command palette
- **VS Code**: Platform-specific IDE setup (when needed)

### Terminal Multiplexers

#### Zellij

Extensive customization with numerous custom plugins:

- **Session Management**: zellij-sessionizer, zellij-switch, zellij-workspace
- **Navigation**: zellij-jump-list, zellij-choose-tree, vim-zellij-navigator
- **Productivity**: zellij-bookmarks, zellij-forgot, zellij-cb (clipboard)
- **UI Enhancements**: zjstatus, zj-status-bar, zjframes, zashboard
- **Utilities**: zellij-autolock, zellij-datetime, zj-docker, zj-quit
- **Layout**: zbuffers, multitask, monocle, room, harpoon

#### tmux

- Traditional terminal multiplexer alternative
- Custom keybindings and status bar
- Session management

### Shell Environments

- **Fish**: Modern shell with excellent defaults
  - Syntax highlighting and autosuggestions
  - Vi/Emacs mode support
  - Bass plugin for bash script compatibility
  - Nix-your-shell integration
- **Zsh**: Extended shell with plugins
  - Oh-my-zsh framework
  - Custom themes and completions
  - Plugin management
- **Bash**: POSIX-compliant shell
  - Scripting and compatibility

### Language Support

- **Rust** (`langs/rust.nix`):
  - Toolchain managed with fenix
  - Complete toolchain (rustc, cargo, clippy, rustfmt)
  - rust-analyzer LSP
  - Cargo tools and utilities
- **Python** (`langs/python.nix`):
  - Multiple Python versions
  - Package managers: pip, poetry, uv
  - Conda/mamba integration
  - Virtual environment management
  - ipython, jupyter support
- **Node.js** (`langs/node.nix`):
  - npm, yarn, pnpm, bun package managers
  - Multiple node versions (via volta/fnm)
  - typescript, eslint, prettier
- **Java** (`langs/java.nix`):
  - JDK management (OpenJDK)
  - Build tools: maven, gradle
  - Language servers
- **C/C++** (`langs/cc.nix`):
  - GCC and clang toolchains
  - CMake and build systems
  - Debuggers (gdb, lldb)
  - Clangd LSP
- **R** (`langs/r.nix`):
  - R language and RStudio
  - Package management
  - Statistical computing tools
- **Lua** (`langs/lua.nix`):
  - Lua interpreter
  - LuaRocks package manager
  - Neovim plugin development
- **Shell** (`langs/shell.nix`):
  - ShellCheck for linting
  - shfmt for formatting
  - Bash language server

### CLI Tools & Utilities

#### Version Control

- **Git**: Advanced configuration with delta, lazygit TUI
- **Jujutsu (jj)**: Next-generation VCS
- **GitHub CLI (gh)**: GitHub integration

#### File Management & Search

- **Modern alternatives**:
  - `ripgrep` (rg): Fast grep alternative
  - `fd`: Fast find alternative
  - `bat`: Cat with syntax highlighting
  - `eza`: Modern ls replacement
  - `dust`: Disk usage analyzer
  - `duf`: Disk usage in human-readable format
- **File managers**:
  - `yazi`: Modern terminal file manager
  - `ranger`: Vi-like file manager alternative

#### Productivity Tools

- **fzf**: Fuzzy finder integration
- **navi**: Interactive cheatsheet tool
- **pet**: Command snippet manager
- **atuin**: Shell history in SQLite
- **zoxide**: Smarter cd command
- **direnv**: Per-directory environment variables

#### System Monitoring

- **btop/htop**: System resource monitors
- **bottom**: Cross-platform system monitor
- **fastfetch/neofetch**: System information
- **bandwhich**: Network bandwidth monitor

#### AI & Assistants

- **AI tools** (`cli/ai/`):
  - GitHub Copilot CLI
  - Codeium
  - Various LLM integrations

#### Security Tools

- **age**: Modern encryption tool
- **gpg**: PGP encryption with YubiKey support
- **ssh**: Advanced SSH configuration
  - Agent forwarding
  - Key management
  - Config per host
- **pass**: Password manager integration

## 🔐 Secret Management

### SOPS Integration

Secrets are encrypted using SOPS with age encryption:

```bash
# Edit secrets (automatically decrypts and re-encrypts)
sops secrets/services/example.yaml

# Re-key secrets for new hosts (after adding age keys)
sops updatekeys secrets/services/example.yaml

# View decrypted secrets without editing
sops -d secrets/services/example.yaml
```

### Secret Organization

The `secrets/` directory is organized by purpose:

- `secrets/johnson/`: User-specific secrets
  - `core/`: Johnson-owned bootstrap secrets (SSH host keys, GPG public keys, YubiKey metadata)
  - SSH keys and configurations
  - GPG keys and trust database
  - Personal credentials
- `secrets/services/`: Service credentials and API keys
  - GitHub tokens
  - API keys for various services
  - Application-specific credentials

### Age Key Management

- Age keys are stored in `~/.config/sops/age/keys.txt`
- Each host has its own age key pair
- Public keys are committed to the repository in `.sops.yaml`
- Private keys are generated during host setup
- YubiKey can be used as a backup decryption key

### Security Best Practices

- **Hardware Security Keys**: YubiKey integration for GPG and SSH
  - Smart card support via gpg-agent
  - Touch-to-authenticate for sensitive operations
  - Backup keys stored securely offline
- **Authentication**:
  - Soteria polkit agent for graphical authentication prompts
  - PAM configuration for system authentication
  - GPG agent with SSH support
- **Network Security**:
  - Per-host firewall configurations
  - Proxy support with automatic environment variables
  - Secure DNS configuration
- **Secure Boot**: Support for UEFI Secure Boot on compatible hardware
- **Disk Encryption**: LUKS setup via disko for encrypted installations

## 🐛 Troubleshooting

### Common Issues

**Build failures after flake updates:**

```bash
# Clean build cache and retry
nix-collect-garbage -d
just build hostname
```

**Secret decryption issues:**

```bash
# Verify age key availability
age-keygen -y ~/.config/sops/age/keys.txt

# Re-import SOPS keys
sops updatekeys secrets/path/to/secret.yaml
```

**Home Manager activation failures:**

```bash
# Reset conflicting files
mv ~/.config/conflicting-app ~/.config/conflicting-app.bak
just switch hostname
```

### Debug Commands

```bash
# Verify flake structure
nix flake check

# Build with verbose output
nix build .#nixosConfigurations.hostname.config.system.build.toplevel -v

# Check system journal
sudo journalctl -u home-manager-username.service
```

### Recovery Procedures

**System rollback:**

```bash
# List available generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Or boot into previous generation from GRUB/systemd-boot menu
```

**Home Manager rollback:**

```bash
# List Home Manager generations
home-manager generations

# Rollback to specific generation
/nix/var/nix/profiles/per-user/$USER/home-manager-<generation>-link/activate
```

**Emergency recovery (NixOS):**

1. Boot from NixOS installation media
2. Mount existing system:

   ```bash
   mount /dev/disk/by-label/nixos /mnt
   mount /dev/disk/by-label/boot /mnt/boot
   ```

3. Enter installed system:

   ```bash
   nixos-enter --root /mnt
   ```

4. Rollback or fix configuration, then rebuild

**Darwin recovery:**

```bash
# List darwin generations
ls -l /nix/var/nix/profiles/system-*

# Activate previous generation
/nix/var/nix/profiles/system-<generation>-link/activate
```

### Platform-Specific Issues

**NixOS:**

- **Boot issues**: Check systemd-boot/GRUB configuration in `modules/nixos/boot/`
- **Graphics problems**: Verify GPU drivers in `modules/nixos/hardware/gpu/`
- **Network issues**: Check `modules/nixos/networking/` configuration
- **Wayland compositor crashes**: Check logs with `journalctl --user -u <compositor>`

**macOS:**

- **Homebrew conflicts**: Run `brew cleanup` and rebuild
- **Permission issues**: May need to run with `sudo` for system changes
- **Aerospace not loading**: Check `launchd` service status with `launchctl list`
- **Nix daemon issues**: Restart with `sudo launchctl kickstart -k system/org.nixos.nix-daemon`

**WSL:**

- **Systemd not working**: Verify WSL version 2 and systemd enabled in `/etc/wsl.conf`
- **Network DNS issues**: Check `modules/nixos/networking/` configuration
- **Windows integration**: Ensure WSL integration is enabled in Docker Desktop if using containers

## 🤝 Contributing

### Development Workflow

The repository uses pre-commit hooks to maintain code quality. To set up:

```bash
# Enter development shell (automatically installs hooks)
just dev

# Or manually
nix develop
```

Pre-commit hooks will automatically:

- Format Nix code with nixfmt (via treefmt)
- Run linters: statix, deadnix, nil
- Check for large files, merge conflicts, and secrets
- Validate conventional commit messages

### Making Changes

1. **Create a branch**: Use descriptive branch names

   ```bash
   git checkout -b feature/description
   ```

2. **Make your changes**: Edit configuration files as needed

3. **Test locally**: Always test on a development host first

   ```bash
   just build hostname    # Test build
   just switch hostname   # Apply if build succeeds
   ```

4. **Format and validate**:

   ```bash
   just fmt              # Format all Nix files
   just check            # Validate flake and run linters
   ```

5. **Commit with conventional commits**:

   ```bash
   git commit -m "feat(module): add new feature"
   # Types: feat, fix, docs, style, refactor, test, chore, build, ci, perf
   ```

6. **Update documentation**: Keep README.md and CLAUDE.md synchronized

### Code Style Guidelines

**Nix Code:**

- Use 2-space indentation (enforced by nixfmt)
- Follow existing naming conventions:
  - Module options: `my.category.subcategory.option`
  - Functions: `camelCase`
  - Attributes: `kebab-case` or `camelCase` depending on context
- Add comments for complex logic:
  ```nix
  # Why this configuration exists
  services.example.enable = true;
  ```
- Organize imports logically:
  ```nix
  {
    lib,
    config,
    pkgs,
    ...
  }: let
    inherit (lib) mkIf;
    cfg = config.my.example;
  in {
    # Configuration here
  }
  ```

**Module Structure:**

- Use `options` for configuration
- Use `config` for implementation
- Separate concerns into different files
- Keep modules focused and composable

**File Organization:**

- Group related functionality together
- Use `default.nix` for directory entry points
- Name files descriptively (e.g., `hyprland.nix`, not `wm.nix`)

### Adding New Hosts

1. **Create host directory**:

   ```bash
   mkdir -p hosts/hostname
   ```

2. **Create configuration files**:
   - `default.nix`: Host entry point with module imports
   - `config.nix`: Host-specific options (username, timezone, etc.)
   - `hardware-configuration.nix`: Hardware-specific settings (NixOS only)

3. **Define host in flake**: The host will be automatically discovered by `lib/hosts.nix` if it
   follows the standard structure

4. **Test the build**:

   ```bash
   just build hostname
   ```

5. **Document the host**: Update the Hosts table in README.md

### Adding New Modules

1. **Create module file** in appropriate directory:
   - `modules/nixos/` for NixOS-specific
   - `modules/darwin/` for macOS-specific
   - `modules/home/` for Home Manager (cross-platform)
   - `modules/common/` for shared system configuration

2. **Follow module structure**:

   ```nix
   {
     lib,
     config,
     pkgs,
     ...
   }: let
     inherit (lib) mkEnableOption mkIf;
     cfg = config.my.category.module;
   in {
     options.my.category.module = {
       enable = mkEnableOption "module description";
       # Additional options
     };

     config = mkIf cfg.enable {
       # Implementation
     };
   }
   ```

3. **Import in `default.nix`**: Add to the appropriate `default.nix` file

4. **Test thoroughly**: Verify module works on relevant hosts

### Adding Custom Packages

1. **Create package file** in `packages/`:

   ```nix
   {
     lib,
     stdenv,
     fetchFromGitHub,
   }:
   stdenv.mkDerivation {
     pname = "package-name";
     version = "1.0.0";
     # Package definition
   }
   ```

2. **Export in `flake/packages.nix`**: The package will be automatically discovered if placed in
   `packages/`

3. **Test the package**:
   ```bash
   nix build .#package-name
   ```

### Testing Changes

**Local testing:**

```bash
# Build without switching
just build hostname

# Build and switch
just switch hostname

# Test specific module
nix eval .#nixosConfigurations.hostname.config.my.module
```

**Offline testing:**

```bash
# Test build without network access
just offline hostname
```

**Clean build test:**

```bash
# Clean build cache and test fresh build
nix-collect-garbage -d
just build hostname
```

## 📖 References

### Learning Resources

- **[nixos-and-flakes-book](https://github.com/ryan4yin/nixos-and-flakes-book)** - Comprehensive
  tutorial for NixOS and flakes
- **[NixOS Wiki](https://wiki.nixos.org/)** - Official documentation and guides
- **[Home Manager Manual](https://nix-community.github.io/home-manager/)** - User environment
  management

### Configuration Inspirations

- **[ryan4yin's nix-config](https://github.com/ryan4yin/nix-config)** - Original architectural
  inspiration
- **[Misterio77's nix-config](https://github.com/Misterio77/nix-config)** - Excellent module
  organization
- **[isabelroses's dotfiles](https://github.com/isabelroses/dotfiles)** - Amazing NixOS desktop
  configuration
- **[fufexan's dotfiles](https://github.com/fufexan/dotfiles)** - Hyprland and Wayland expertise
- **[hilissner's dotfiles](https://github.com/hlissner/dotfiles)** - Clean code layout and structure
- **[khaneliman's khanelinix](https://github.com/khaneliman/khanelinix)** - Extensive AI
  configuration

### Framework & Tools

- **[flake-parts](https://flake.parts/)** - Modular flake architecture
- **[gytis-ivaskevicius's nixfiles](https://github.com/gytis-ivaskevicius/nixfiles)** - Framework
  concepts
- **[oddlama's nix-config](https://github.com/oddlama/nix-config)** - flake-parts implementation
- **[EmergentMind's nixos-config](https://github.com/EmergentMind/nixos-config)** - System
  organization
- **[runarsf's dotfiles](https://github.com/runarsf/dotfiles)** - Great configuration patterns

### Specialized Knowledge

- **[oluceps's nixos-config](https://github.com/oluceps/nixos-config)** - Advanced networking
  configuration
- **[Nobbz's nixos-config](https://github.com/Nobbz/nixos-config)** - Innovative configuration
  techniques
- **[azuwis's nix-config](https://github.com/azuwis/nix-config)** - Framework implementation ideas

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

Special thanks to the incredible NixOS community and the maintainers of the projects that make this
configuration possible. The declarative approach to system configuration has transformed my
development workflow and system reliability.

> _"The best time to plant a tree was 20 years ago. The second best time is now."_ - The same
> applies to adopting NixOS! 🌱

---

**Note**: This configuration is tailored for my specific use cases and preferences. Feel free to
fork and adapt it to your needs, but remember to update host-specific configurations and regenerate
secrets appropriately.
