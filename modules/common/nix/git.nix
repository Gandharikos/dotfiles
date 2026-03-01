{config, ...}: let
  # We only need this system-wide on Linux for nixos-rebuild,
  # or if we want to ensure root can also read the flake repo.
  # But it's generally safe to add it to the system-wide git config.
  dotfilesPath = "${config.my.home}/.dotfiles";
in {
  programs.git = {
    enable = true;
    # On NixOS and nix-darwin, this maps to the system-wide git configuration.
    config = {
      safe.directory = [dotfilesPath];
    };
  };
}
