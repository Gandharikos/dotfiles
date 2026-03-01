{
  config,
  lib,
  ...
}: let
  cfg = config.my.services.zram;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
in {
  options.my.services.zram = {
    enable = mkEnableOption "Enable zram swap";
  };
  config = mkIf cfg.enable {
    # Enable in-memory compressed devices and swap space provided by the zram kernel module.
    # By enable this, we can store more data in memory instead of fallback to disk-based swap devices directly,
    # and thus improve I/O performance when we have a lot of memory.
    #
    #   https://www.kernel.org/doc/Documentation/blockdev/zram.txt
    services.zram-generator = {
      enable = true;
      settings.zram0 = {
        # one of "lzo", "lz4", "zstd"
        compression-algorithm = "zstd";
        # Priority of the zram swap devices.
        # It should be a number higher than the priority of your disk-based swap devices
        # (so that the system will fill the zram swap devices before falling back to disk swap).
        swap-priority = 5;
        # Maximum total amount of memory that can be stored in the zram swap devices (as a percentage of your total memory).
        # Defaults to 1/2 of your total RAM. Run zramctl to check how good memory is compressed.
        zram-size = "ram / 2";
      };
    };

    boot.kernel.sysctl = {
      # zram is relatively cheap, prefer swap
      "vm.swappiness" = 180;
      "vm.watermark_boost_factor" = 0;
      "vm.watermark_scale_factor" = 125;
      # zram is in memory, no need to readahead
      "vm.page-cluster" = 0;
    };
  };
}
