{
  config,
  lib,
  ...
}:
let
  cfg = config.dot.services.zfs;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types) bool str;
in
{
  options.dot.services.zfs = {
    enable = mkEnableOption "ZFS storage support";

    scrub = {
      enable = mkOption {
        type = bool;
        default = true;
        description = "Whether to periodically scrub ZFS pools.";
      };

      interval = mkOption {
        type = str;
        default = "weekly";
        description = "systemd calendar interval for ZFS scrub jobs.";
      };
    };

    trim = {
      enable = mkOption {
        type = bool;
        default = true;
        description = "Whether to periodically trim ZFS pools.";
      };

      interval = mkOption {
        type = str;
        default = "weekly";
        description = "systemd calendar interval for ZFS trim jobs.";
      };
    };

    autoSnapshot.enable = mkOption {
      type = bool;
      default = false;
      description = "Whether to enable automatic ZFS snapshots.";
    };
  };

  config = mkIf cfg.enable {
    boot.supportedFilesystems = [ "zfs" ];

    environment.systemPackages = [
      config.boot.zfs.package
    ];

    services.zfs = {
      autoScrub = {
        inherit (cfg.scrub) enable interval;
      };

      trim = {
        inherit (cfg.trim) enable interval;
      };

      autoSnapshot.enable = cfg.autoSnapshot.enable;
    };
  };
}
