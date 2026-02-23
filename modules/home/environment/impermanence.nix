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
              ".local/bin"
              ".cache/nix"
              ".cache/pre-commit"
              ".dotfiles"
              ".docker"
              ".secrets"
              "Documents"
              "Downloads"
              "Desktop"
              "Media"
              "Public"
              "Dev"
              "Misc"
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
