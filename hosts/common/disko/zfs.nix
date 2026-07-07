{
  devices ? [ "/dev/nvme0n1" ],
  poolName ? "rpool",
  poolMode ? "",
  swapSize ? "32G",
  ...
}:
let
  mountOptions = [
    "noatime"
  ];
  mkDisk =
    index: device:
    let
      diskName = "disk${toString index}";
    in
    {
      name = diskName;
      value = {
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
                mountOptions = [ "umask=0077" ];
              };
            };

            swap = {
              priority = 2;
              label = "SWAP";
              size = swapSize;
              content = {
                type = "swap";
                randomEncryption = true;
              };
            };

            zfs = {
              priority = 3;
              name = "zfs";
              label = "ZFS";
              size = "100%";
              content = {
                type = "zfs";
                pool = poolName;
              };
            };
          };
        };
      };
    };
in
{
  disko.devices = {
    disk = builtins.listToAttrs (
      builtins.genList (index: mkDisk index (builtins.elemAt devices index)) (builtins.length devices)
    );

    zpool.${poolName} = {
      type = "zpool";
      mode = poolMode;
      options = {
        ashift = "12";
        autotrim = "on";
      };
      rootFsOptions = {
        acltype = "posixacl";
        atime = "off";
        canmount = "off";
        compression = "zstd";
        dnodesize = "auto";
        mountpoint = "none";
        normalization = "formD";
        xattr = "sa";
      };

      datasets = {
        "local" = {
          type = "zfs_fs";
          options = {
            canmount = "off";
            mountpoint = "none";
          };
        };

        "local/root" = {
          type = "zfs_fs";
          mountpoint = "/";
          inherit mountOptions;
        };

        "local/nix" = {
          type = "zfs_fs";
          mountpoint = "/nix";
          inherit mountOptions;
        };

        "safe" = {
          type = "zfs_fs";
          options = {
            canmount = "off";
            mountpoint = "none";
          };
        };

        "safe/persist" = {
          type = "zfs_fs";
          mountpoint = "/persist";
          inherit mountOptions;
        };

        "safe/log" = {
          type = "zfs_fs";
          mountpoint = "/var/log";
          inherit mountOptions;
        };

        "safe/home" = {
          type = "zfs_fs";
          mountpoint = "/home";
          inherit mountOptions;
        };

        "local/snapshots" = {
          type = "zfs_fs";
          mountpoint = "/.snapshots";
          inherit mountOptions;
        };
      };
    };
  };
}
