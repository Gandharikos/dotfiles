{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dot.services.btrbk;
  runAsRoot = config.dot.security.privilege == "run0";
  btrbkConfig = pkgs.writeText "btrbk.conf" ''
    backend btrfs-progs
    timestamp_format long-iso
    preserve_day_of_week monday
    preserve_hour_of_day 23
    snapshot_preserve_min 6h

    volume /btr_pool
      snapshot_dir @snapshots

      subvolume @persist
        snapshot_preserve 48h 7d 4w

      subvolume @log
        snapshot_preserve 48h 7d
  '';
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf mkMerge;
in
{
  # ==================================================================
  #
  # Tool for creating snapshots and remote backups of btrfs subvolumes
  #   https://github.com/digint/btrbk
  #
  # Usage:
  #   1. btrbk will create snapshots on schedule
  #   2. we can use `btrbk run` command to create a backup manually
  #
  # How to restore a snapshot:
  #   1. Find the snapshot you want to restore in /snapshots
  #   2. Use `btrfs subvol delete /btr_pool/@persistent` to delete the current subvolume
  #   3. Use `btrfs subvol snapshot /snapshots/2021-01-01 /btr_pool/@persistent` to restore the snapshot
  #   4. reboot the system or remount the filesystem to see the changes
  #
  # ==================================================================

  options.dot.services.btrbk = {
    enable = mkEnableOption "btrbk";
  };

  config = mkIf cfg.enable (mkMerge [
    (mkIf (!runAsRoot) {
      # Grant btrbk user passwordless sudo for btrfs operations
      security.sudo-rs = {
        # Allow non-wheel users to execute sudo (needed for service users like btrbk)
        execWheelOnly = false;
        extraRules = [
          {
            users = [ "btrbk" ];
            commands = [
              {
                command = lib.getExe' pkgs.btrfs-progs "btrfs";
                options = [ "NOPASSWD" ];
              }
              {
                command = lib.getExe' pkgs.coreutils "readlink";
                options = [ "NOPASSWD" ];
              }
              {
                command = lib.getExe' pkgs.coreutils "test";
                options = [ "NOPASSWD" ];
              }
              {
                command = lib.getExe' pkgs.coreutils "mkdir";
                options = [ "NOPASSWD" ];
              }
              {
                command = lib.getExe' pkgs.coreutils "stat";
                options = [ "NOPASSWD" ];
              }
            ];
          }
        ];
      };

      services.btrbk.instances.btrbk = {
        # Trigger snapshots every half hour, providing an extremely powerful "time machine" capability.
        onCalendar = "*:00,30";

        settings = {
          timestamp_format = "long-iso";
          preserve_day_of_week = "monday";
          preserve_hour_of_day = "23";

          # Retain all newly created snapshots for at least 6 hours regardless of other rules
          # (a lifesaver for accidental file deletions).
          snapshot_preserve_min = "6h";

          # -----------------------------------------------------------------
          # Core Routing: Tell Btrbk where to find data and where to store snapshots
          # -----------------------------------------------------------------

          # Your disko config mounts the Btrfs top-level root (subvolid=5) at /btr_pool
          volume."/btr_pool" = {
            # Elegant design: Use your @snapshots subvolume as the snapshot storage directory.
            # Since it's a relative path, Btrbk will automatically write snapshots to /btr_pool/@snapshots/.
            # And because you mounted @snapshots to /.snapshots, they are readily accessible in your system!
            snapshot_dir = "@snapshots";

            # [Primary Protection Target]: @persist contains all your user data and system state.
            # Policy: Keep 48 hours of half-hourly snapshots + 7 days of daily snapshots + 4 weeks of weekly snapshots.
            subvolume."@persist" = {
              snapshot_preserve = "48h 7d 4w";
            };

            # [Secondary Protection Target]: @log (Optional)
            # Policy: Retain the last 48 hours and 7 days of logs for troubleshooting.
            # No need to keep them for a whole month to save space.
            subvolume."@log" = {
              snapshot_preserve = "48h 7d";
            };

            # ⚠️ WARNING: Absolutely do NOT include @nix, @tmp, and @swap here!
          };
        };
      };
    })

    (mkIf runAsRoot {
      environment = {
        systemPackages = [ pkgs.btrbk ];

        etc."btrbk/btrbk.conf".source = btrbkConfig;
      };

      systemd = {
        services.btrbk-btrbk = {
          description = "Takes BTRFS snapshots and maintains retention policies.";
          unitConfig.Documentation = "man:btrbk(1)";
          path = [
            pkgs.btrfs-progs
            pkgs.coreutils
          ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${lib.getExe pkgs.btrbk} -c /etc/btrbk/btrbk.conf run";
            Nice = 10;
            IOSchedulingClass = "best-effort";
            StateDirectory = "btrbk";
          };
        };

        timers.btrbk-btrbk = {
          description = "Timer to take BTRFS snapshots and maintain retention policies.";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "*:00,30";
            AccuracySec = "10min";
            Persistent = true;
          };
        };
      };
    })
  ]);
}
