# Python uv2nix project template

A Python application with reproducible uv dependency locking, uv2nix builds, an editable development
environment, Ruff, Pytest, direnv, Git hooks, and GitHub Actions.

## Create a project

```console
nix flake init -t ~/.dotfiles#python
git init
git add .
direnv allow
```

New template files must be added to Git before Nix evaluates a Git flake.

## Develop

```console
nix develop
uv add httpx
uv add --dev mypy
just check
just fmt
```

The Nix shell provides the locked environment in editable mode. Run commands directly rather than
through `uv run`; uv2nix already places Python and project entry points on `PATH`.

## Build and run with Nix

```console
nix build
nix run
nix run . -- --version
nix flake check
nix fmt
```

`uv.lock` is the dependency source of truth. After changing `pyproject.toml`, refresh it with
`uv lock` and add both files to Git.
