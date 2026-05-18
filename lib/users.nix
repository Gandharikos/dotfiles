{ lib, ... }:
let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.filesystem) listFilesRecursive;
  inherit (lib.lists) forEach optionals;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types)
    anything
    deferredModule
    enum
    listOf
    nullOr
    path
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
    let
      hasSecretsCore = config.secretsCore != null && builtins.pathExists config.secretsCore;
      regularKey = config.secretsCore + "/id_ed25519.pub";
      extraKeysDir = config.secretsCore + "/keys";
    in
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
      secretsCore = mkOption {
        type = nullOr path;
        default = null;
        description = "Directory containing this user's core public SSH keys.";
      };
      authorizedKeys = mkOption {
        type = listOf str;
        default =
          optionals (hasSecretsCore && builtins.pathExists regularKey) [
            (builtins.readFile regularKey)
          ]
          ++ optionals (hasSecretsCore && builtins.pathExists extraKeysDir) (
            forEach (lib.filter (path: lib.hasSuffix ".pub" (toString path)) (
              listFilesRecursive extraKeysDir
            )) (key: builtins.readFile key)
          );
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
