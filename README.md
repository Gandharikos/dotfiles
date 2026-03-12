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

- **SOPS integration**: Encrypted secrets with age and GPG support
- **Impermanence**: Stateless system configuration for enhanced security
- **Secure Boot**: Support for secure boot configurations
- **YubiKey integration**: Hardware security key support

### 🎮 Rich Desktop Experience

- **Hyprland**: Modern Wayland compositor with advanced features
- **AGS**: Custom widgets and desktop components
- **Tokyo Night theme**: Consistent theming across all applications
- **Multiple display support**: Seamless multi-monitor configurations

## 🚀 Quick Start

### Prerequisites

- **Nix package manager** (with flakes enabled)
- **Git** for cloning the repository
- **Just** command runner (optional, but recommended)

### Installation

1. **Enable Nix Flakes** (if not already enabled):

   ```bash
   mkdir -p ~/.config/nix
   echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
   ```

2. **Clone the repository**:

   ```bash
   git clone https://github.com/yourusername/dotfiles ~/.dotfiles
   cd ~/.dotfiles
   ```

3. **Build for your system**:

   ```bash
   # For NixOS
   sudo nixos-rebuild switch --flake .#hostname

   # For macOS
   darwin-rebuild switch --flake .#hostname

   # Using just (recommended)
   just build hostname
   ```

### First-Time Setup

1. **Generate SSH keys** and add to your Git provider
2. **Configure SOPS** with your age key for secret management
3. **Customize** host-specific settings in `hosts/hostname/`
4. **Apply changes** with `just switch hostname`

## 🏗️ Architecture

### Repository Structure

```
📁 ~/.dotfiles/
├── 📁 flake/           # Flake-parts modules
│   ├── hosts.nix       # Host definitions
│   ├── packages.nix    # Custom packages
│   └── devshells.nix   # Development shells
├── 📁 hosts/           # Host-specific configurations
│   ├── common/         # Shared host configs
│   └── <hostname>/     # Individual host settings
├── 📁 modules/         # Modular system components
│   ├── common/         # Cross-platform modules
│   ├── nixos/          # NixOS-specific modules
│   ├── darwin/         # macOS-specific modules
│   └── home/           # Home Manager modules
├── 📁 lib/             # Custom library functions
├── 📁 pkgs/            # Custom package definitions
├── 📁 config/          # Application dotfiles
├── 📁 secrets/         # SOPS-encrypted secrets
└── flake.nix          # Main flake configuration
```

### Module Organization

- **`modules/common/`**: Cross-platform configurations (environment, nix settings, themes)
- **`modules/nixos/`**: Linux-specific modules (boot, desktop, hardware, networking)
- **`modules/darwin/`**: macOS-specific modules (brew, system preferences)
- **`modules/home/`**: User environment modules organized by category:
  - `cli/`: Command-line tools, editors, shells
  - `desktop/`: GUI applications, window managers
  - `langs/`: Programming language environments

## 🖥️ Hosts

### Production Hosts

| Host       | Platform | Purpose     | Description                                          |
| ---------- | -------- | ----------- | ---------------------------------------------------- |
| **tyr**    | macOS    | Mac Mini    | Primary macOS workstation for development and media  |
| **sigurd** | NixOS    | Desktop     | High-performance Linux workstation with Hyprland     |
| **eir**    | macOS    | MacBook Air | Portable development machine for travel and learning |

### Development & Testing

| Host        | Platform | Purpose  | Description                                 |
| ----------- | -------- | -------- | ------------------------------------------- |
| **ymir**    | NixOS    | Laptop   | Testing ground for new NixOS configurations |
| **nidhogg** | WSL2     | Windows  | Linux development environment on Windows    |
| **loki**    | NixOS    | Flexible | Additional host for experimentation         |

## 📚 Usage

### Building & Deployment

```bash
# Build system configuration (test without switching)
just build [hostname]

# Apply configuration changes
just switch [hostname]      # Classic nixos-rebuild/darwin-rebuild
just switch2 [hostname]     # Using nh (recommended)

# Deploy to remote host
just deploy <hostname>

# Fresh installation
just install <hostname>     # Install on existing OS
just disko <hostname>       # Full disk setup + install
```

### Development & Maintenance

```bash
# Code quality & formatting
just fmt                   # Format all Nix files
just check                 # Validate flake & run linting

# Updates & maintenance
just up                    # Update all flake inputs
just upp <input>           # Update specific input
just clean                 # Remove old system generations
just gc                    # Garbage collect unused store entries

# Development workflows
just dev [shell]           # Enter development shell
just cfg <program>         # Move config to ~/.config for development
just add <program>         # Backup config from ~/.config to repo
```

## 🔧 Key Technologies

### Core Infrastructure

- **[Nix Flakes](https://wiki.nixos.org/wiki/Flakes)**: Modern package management with lock files
  for reproducible builds
- **[flake-parts](https://flake.parts/)**: Modular flake architecture for better organization
- **[Home Manager](https://github.com/nix-community/home-manager)**: Declarative dotfile and user
  environment management

### System Management

- **[SOPS](https://github.com/Mic92/sops-nix)**: Secure secret management with age encryption
- **[disko](https://github.com/nix-community/disko)**: Declarative disk partitioning and formatting
- **[impermanence](https://github.com/nix-community/impermanence)**: Stateless system configuration

### Platform-Specific

- **[nix-darwin](https://github.com/LnL7/nix-darwin)**: macOS system configuration
- **[nixos-wsl](https://github.com/nix-community/NixOS-WSL)**: NixOS for Windows Subsystem for Linux

## 🎨 Desktop Environment

### Wayland Ecosystem (NixOS)

- **[Hyprland](https://hyprland.org/)**: Dynamic tiling Wayland compositor
- **[AGS](https://github.com/Aylur/ags)**: Customizable widgets and bars
- **[Hyprpaper](https://github.com/hyprwm/hyprpaper)**: Wallpaper management
- **[Hyprlock](https://github.com/hyprwm/hyprlock)**: Screen locker
- **[Anyrun](https://github.com/Kirottu/anyrun)**: Application launcher

### macOS Integration (Darwin)

- **[Aerospace](https://github.com/nikitabobko/AeroSpace)**: Tiling window manager for macOS
- **System Preferences**: Declarative macOS settings management
- **Homebrew**: GUI application management via nix-darwin

### Theming

- **Tokyo Night**: Consistent dark theme across all applications
- **JetBrains Mono**: Primary monospace font with Nerd Font patches
- **Cursor themes**: Custom cursor styling across platforms

## 🛠️ Development Environment

### Editors & IDEs

- **Neovim**: Heavily customized with LazyVim configuration
  - LSP support for multiple languages
  - AI integration (Copilot, Supermaven)
  - Custom plugins and workflows
- **VS Code**: Platform-specific IDE setup
- **Helix**: Modern modal editor alternative

### Language Support

- **Rust**: Complete toolchain with cargo, clippy, rustfmt
- **Python**: Multiple versions, pip, poetry, conda integration
- **Node.js**: npm, yarn, pnpm package managers
- **Java**: JDK management and build tools
- **C/C++**: GCC, clang, cmake, debugging tools
- **Shell**: bash, zsh, fish with enhanced tooling

### CLI Tools

- **Git**: Advanced configuration with lazygit TUI
- **tmux**: Terminal multiplexer with custom config
- **zsh**: Enhanced shell with oh-my-zsh and plugins
- **fzf**: Fuzzy finder integration everywhere
- **ripgrep, fd, bat**: Modern alternatives to grep, find, cat

## 🔐 Secret Management

### SOPS Integration

Secrets are encrypted using SOPS with age encryption:

```bash
# Edit secrets
sops secrets/services/example.yaml

# Re-key secrets for new hosts
sops updatekeys secrets/services/example.yaml
```

### Secret Organization

- `secrets/johnson/`: User-specific secrets (SSH keys, GPG keys)
- `secrets/services/`: Service credentials and API keys
- Age keys stored securely with hardware security key backup

### Security Features

- Hardware security key (YubiKey) integration
- GPG configuration with smart card support
- SSH key management with agent forwarding
- Secure boot support on compatible hardware

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

- Boot from NixOS installer for system recovery
- Use previous generation if current build fails
- Rollback Home Manager with `home-manager generations`

## 🤝 Contributing

### Making Changes

1. **Test locally**: Always test changes on your development host first
2. **Format code**: Run `just fmt` before committing
3. **Validate configuration**: Use `just check` to ensure flake validity
4. **Update documentation**: Keep README.md and CLAUDE.md in sync

### Code Style

- Use 2-space indentation for Nix files
- Follow existing naming conventions
- Add comments for complex configurations
- Organize imports alphabetically

### Adding New Hosts

1. Create `hosts/hostname/` directory
2. Add `default.nix` and `config.nix`
3. Update `flake/hosts.nix` with new host definition
4. Test build before committing

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
