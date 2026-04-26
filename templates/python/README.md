<div align=center>

# ❄️ nix-template-python-uv2nix 🐍

[![NixOS](https://img.shields.io/badge/Made_for-Python-blue.svg?logo=python&style=for-the-badge)](https://www.python.org/)
[![NixOS](https://img.shields.io/badge/Flakes-Nix-informational.svg?logo=nixos&style=for-the-badge)](https://nixos.org)
![License](https://img.shields.io/github/license/mordragt/nix-templates?style=for-the-badge)

Minimal **Python** development template for **Nix**

</div>

## About

This is a minimal template for Python development with `uv` and `uv2nix`.

## Initialization

See the parent README for further instructions, but you can initialize this template with the
following command in your current directory.

```bash
nix flake init -t github:Gandharikos/.dotfiles#python
```

## Usage

- `nix develop`: opens a shell with the project virtualenv and `uv`
- `nix build`: builds the Python project virtualenv. The script defined in `pyproject.toml` will be
  available under `./result/bin/<name>`
- `nix run`: runs the Python program.
- `python -m package`: runs the Python module inside the dev shell
- `uv add <dependency>`: adds a dependency to `pyproject.toml`
- `uv lock`: refreshes `uv.lock`

## Reference

1. [wiki/Flakes](https://nixos.wiki/wiki/Flakes)
2. [uv](https://docs.astral.sh/uv/) - used for Python package management
3. [uv2nix](https://pyproject-nix.github.io/uv2nix/) - used to convert uv projects into Nix packages
