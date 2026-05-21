{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.dot) scanPaths;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.modules) mkDefault;
  inherit (lib.attrsets) attrNames filterAttrs;
  inherit (lib.types)
    attrsOf
    bool
    enum
    listOf
    str
    ;
  userType = lib.dot.mkUserType { inherit isLinux; };
  usersDir = lib.dot.getFile "users";
  userNames = attrNames (
    filterAttrs (
      name: type: type == "directory" && builtins.pathExists "${usersDir}/${name}/default.nix"
    ) (builtins.readDir usersDir)
  );
in
{
  imports = scanPaths ./.;

  options = {
    dot = {
      primaryUser = mkOption {
        type = enum userNames;
        default = "johnson";
        description = "The primary user for host-level user integrations.";
      };
      admin = mkOption {
        internal = true;
        readOnly = true;
        type = userType;
        default = config.dot.users.${config.dot.primaryUser};
        description = "The primary dot user configuration.";
      };
      enabledUsers = mkOption {
        internal = true;
        readOnly = true;
        type = listOf str;
        default = attrNames (filterAttrs (_: user: user.enable) config.dot.users);
        description = "Enabled dot users.";
      };
      singleUser = mkOption {
        internal = true;
        readOnly = true;
        type = bool;
        default = builtins.length config.dot.enabledUsers == 1;
        description = "Whether exactly one dot user is enabled.";
      };
      users = mkOption {
        type = attrsOf userType;
        default = { };
        description = "Dotfile users managed by this host.";
      };
      security = {
        enable = mkEnableOption "Security" // {
          default = true;
        };
      };
      stateVersion = mkOption {
        internal = true;
        type = str;
        default = "26.05";
        description = "The version of my system";
      };
    };
  };

  config = {
    assertions = [
      {
        assertion = !config.dot.singleUser || config.dot.enabledUsers == [ config.dot.primaryUser ];
        message = ''
          dot.singleUser is true, so the only enabled dot user must be dot.primaryUser.
          Set dot.primaryUser to the enabled user, or enable another dot user intentionally.
        '';
      }
    ];

    dot.users.${config.dot.primaryUser}.enable = mkDefault true;
  };
}
