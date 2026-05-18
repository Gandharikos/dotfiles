{ lib, ... }:
let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types)
    anything
    deferredModule
    enum
    listOf
    singleLineStr
    str
    submodule
    ;
  mkUserOptions =
    {
      isLinux,
      inferName ? true,
      name,
      config,
    }:
    {
      name = mkOption (
        {
          readOnly = true;
          type = str;
          description = "The user's login name.";
        }
        // optionalAttrs inferName {
          default = name;
        }
      );
      enable = mkEnableOption "dot user ${name}";
      fullName = mkOption {
        type = str;
        default = config.name;
        description = "The user's full name.";
      };
      email = mkOption {
        type = str;
        description = "The user's email address.";
      };
      shell = mkOption {
        type = enum [
          "bash"
          "fish"
          "zsh"
          "nushell"
        ];
        default = "fish";
        description = "The user's login shell.";
      };
      initialHashedPassword = mkOption {
        internal = true;
        type = singleLineStr;
        description = "The user's initial hashed password.";
      };
      homeDirectory = mkOption {
        internal = true;
        type = str;
        default = if isLinux then "/home/${config.name}" else "/Users/${config.name}";
        description = "The user's home directory.";
      };
      groups = mkOption {
        type = listOf str;
        default = [
          "wheel"
          config.name
          "users"
          "git"
          "networkmanager"
          "docker"
          "wireshark"
          "adbusers"
          "libvirtd"
        ];
        description = "System groups for this user.";
      };
      authorizedKeys = mkOption {
        type = listOf str;
        default = [ ];
        description = "SSH public keys authorized for this user.";
      };
    };
in
{
  inherit mkUserOptions;

  mkUserType =
    {
      isLinux,
      inferName ? true,
    }:
    submodule (
      { name, config, ... }:
      {
        options =
          (mkUserOptions {
            inherit
              config
              inferName
              isLinux
              name
              ;
          })
          // {
            home = mkOption {
              type = deferredModule;
              default = { };
              description = "Home Manager module for this user.";
            };
            persistence = {
              commonMountOptions = mkOption {
                type = listOf str;
                default = [
                  "x-gvfs-hide"
                ];
                description = "Common mount options for this user's preserved home paths.";
              };
              directories = mkOption {
                type = listOf anything;
                default = [ ];
                description = "Home directories to persist for this user.";
              };
              files = mkOption {
                type = listOf anything;
                default = [ ];
                description = "Home files to persist for this user.";
              };
            };
          };
      }
    );
}
