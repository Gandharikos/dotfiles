<div align=center>

# ❄️ nix-template-python-devenv 🐍

[![NixOS](https://img.shields.io/badge/Made_for-Python-blue.svg?logo=python&style=for-the-badge)](https://www.python.org/)
[![NixOS](https://img.shields.io/badge/Flakes-Nix-informational.svg?logo=nixos&style=for-the-badge)](https://nixos.org)
![License](https://img.shields.io/github/license/mordragt/nix-templates?style=for-the-badge)

Minimal **Python** development template for **Nix**

</div>

## About

This is a minimal template for Python development with `uv` managed by `devenv`.

## Initialization

See the parent README for further instructions, but you can initialize this template with the
following command in your current directory.

```bash
nix flake init -t github:Gandharikos/dotfiles#python
```

## Usage

- `nix develop --no-pure-eval`: opens the devenv shell with the project virtualenv and `uv`
- `devenv test`: runs the devenv test hooks
- `python -m package`: runs the Python module inside the dev shell
- `uv add <dependency>`: adds a dependency to `pyproject.toml`
- `uv lock`: refreshes `uv.lock`

## Reference

1. [wiki/Flakes](https://nixos.wiki/wiki/Flakes)
2. [devenv](https://devenv.sh/) - used for the development environment
3. [uv](https://docs.astral.sh/uv/) - used for Python package management
