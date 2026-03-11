{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.modules) mkForce;
  persist = config.my.persistence.enable;
in
  if pkgs.stdenv.hostPlatform.isLinux
  then {
    config = {
      home.persistence =
        if persist
        then {
          "/persist" = {
            directories = [
              # keep-sorted start
              ".cache/nix"
              ".cache/nixpkgs-review"
              ".cache/pre-commit"
              ".config/sops"
              ".docker"
              ".dotfiles"
              ".local/bin"
              ".local/share/nix"
              ".local/state/home-manager"
              ".local/state/nix/profiles"
              ".secrets"
              "Desktop"
              "Dev"
              "Documents"
              "Downloads"
              "Media"
              "Misc"
              "Public"
              # keep-sorted end
            ];
          };
        }
        else mkForce {};
    };
  }
  else {
    options = {
      home.persistence = lib.mkOption {
        type = lib.types.anything;
        default = {};
        description = "Dummy persistence option for non-Linux systems.";
      };
    };
  }
