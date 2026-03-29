{
  device ? "/dev/nvme0n1",
  swapSize ? "32G",
  ...
}:
{
  disko = {
    # Do not let Disko manage fileSystems.* config for NixOS.
    # Reason is that Disko mounts partitions by GPT partition names, which are
    # easily overwritten with tools like fdisk. When you fail to deploy a new
    # config in this case, the old config that comes with the disk image will
    # not boot either.
    # enableConfig = false;
    devices.disk = {
      main = {
        type = "disk";
        inherit device;
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              label = "BOOT";
              start = "1M";
              end = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                # Fix world-accessible /boot/loader/random-seed
                # https://github.com/nix-community/disko/issues/527#issuecomment-1924076948
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              name = "root";
              label = "ROOT";
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Override existing partition
                # Subvolumes must set a mountpoint in order to be mounted,
                # unless their parent is mounted
                subvolumes =
                  let
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  in
                  {
                    "@root" = {
                      mountpoint = "/";
                      inherit mountOptions;
                    };
                    "@persist" = {
                      mountpoint = "/persist";
                      inherit mountOptions;
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      inherit mountOptions;
                    };
                    "@snapshots" = {
                      mountpoint = "/.snapshots";
                      inherit mountOptions;
                    };
                    "@swap" = {
                      mountpoint = "/.swap";
                      mountOptions = [ "noatime" ];
                      swap.swapfile.size = swapSize;
                    };
                  };
              };
            };
          };
        };
      };
    };
  };
}
