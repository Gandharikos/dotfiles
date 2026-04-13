{
  config,
  lib,
  ...
}:
let
  cfg = config.my.services.btrbk;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
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

  options.my.services.btrbk = {
    enable = mkEnableOption "btrbk";
  };

  config = mkIf cfg.enable {
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
  };
}
