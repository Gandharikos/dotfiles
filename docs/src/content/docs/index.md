---
title: Johnson's dotfiles
description: Personal NixOS, nix-darwin, and Home Manager configuration.
---

<div class="hero-logo">
  <img src="./nixos_logo.png" alt="NixOS logo" />
</div>

# Johnson's dotfiles

Personal NixOS, nix-darwin, and Home Manager configuration. Modular, opinionated, and wired for real
machines rather than a generic starter template.

<div class="hero-actions">
  <a href="./getting-started/">Start reading</a>
  <a href="https://github.com/Gandharikos/dotfiles">View on GitHub</a>
</div>

<img
  class="screenshot"
  src="./Screenshot_2026-07-04_10-16-06.png-region.png"
  alt="Desktop screenshot"
/>

## What This Repo Provides

- A flake-parts based Nix flake with reusable system and user modules.
- NixOS, nix-darwin, WSL, and Home Manager entry points.
- SOPS-backed secrets for users, hosts, and self-hosted services.
- Desktop modules for Wayland, Hyprland, Niri, shells, themes, and GUI tools.
- Operational helpers through `just`, Disko, nixos-anywhere, and deploy workflows.

## Read Next

<ul class="link-list">
  <li><a href="./getting-started/">Getting Started</a><br />Clone, inspect, and build safely.</li>
  <li><a href="./architecture/">Architecture</a><br />How hosts, users, modules, and flakes fit together.</li>
  <li><a href="./operations/secrets/">Secrets</a><br />SOPS recipient model and bootstrap flow.</li>
  <li><a href="./desktop/">Desktop</a><br />Wayland, themes, terminals, launchers, and applications.</li>
</ul>
