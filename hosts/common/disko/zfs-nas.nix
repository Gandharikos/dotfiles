{
  osDevice ? "/dev/disk/by-id/REPLACE_OS_DISK",
  dataDevices ? [
    "/dev/disk/by-id/REPLACE_DATA_DISK_1"
    "/dev/disk/by-id/REPLACE_DATA_DISK_2"
  ],
  poolName ? "tank",
  mountRoot ? "/tank",
  poolMode ? "mirror",
  swapSize ? "16G",
  encryptedKeyLocation ? "prompt",
  ...
}:
let
  mountOptions = [
    "noatime"
  ];

  autoSnapshot = enabled: {
    "com.sun:auto-snapshot" = if enabled then "true" else "false";
  };

  encryptedRootOptions = {
    encryption = "aes-256-gcm";
    keyformat = "passphrase";
    keylocation = encryptedKeyLocation;
  };

  mkDataDisk =
    index: device:
    let
      diskName = "data${toString index}";
    in
    {
      name = diskName;
      value = {
        type = "disk";
        inherit device;

        content = {
          type = "gpt";
          partitions.zfs = {
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

  mkDataset =
    {
      mountpoint,
      recordsize,
      snapshot ? true,
      options ? { },
    }:
    {
      type = "zfs_fs";
      inherit mountpoint mountOptions;
      options = {
        inherit recordsize;
      }
      // autoSnapshot snapshot
      // options;
    };
in
{
  disko.devices = {
    disk = {
      os = {
        type = "disk";
        device = osDevice;

        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              type = "EF00";
              size = "1G";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };

            swap = {
              priority = 2;
              size = swapSize;
              content = {
                type = "swap";
                randomEncryption = true;
              };
            };

            root = {
              priority = 3;
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    }
    // builtins.listToAttrs (
      builtins.genList (index: mkDataDisk index (builtins.elemAt dataDevices index)) (
        builtins.length dataDevices
      )
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
      }
      // autoSnapshot false;

      datasets = {
        media = mkDataset {
          mountpoint = "${mountRoot}/media";
          recordsize = "1M";
          snapshot = false;
        };

        docker = mkDataset {
          mountpoint = "${mountRoot}/docker";
          recordsize = "128K";
        };

        scratch = mkDataset {
          mountpoint = "${mountRoot}/scratch";
          recordsize = "1M";
          snapshot = false;
        };

        secure = {
          type = "zfs_fs";
          options =
            encryptedRootOptions
            // {
              canmount = "off";
              mountpoint = "none";
            }
            // autoSnapshot false;
        };

        "secure/photos" = mkDataset {
          mountpoint = "${mountRoot}/photos";
          recordsize = "1M";
        };

        "secure/documents" = mkDataset {
          mountpoint = "${mountRoot}/documents";
          recordsize = "128K";
        };

        "secure/backups" = mkDataset {
          mountpoint = "${mountRoot}/backups";
          recordsize = "1M";
        };

        "secure/appdata" = mkDataset {
          mountpoint = "${mountRoot}/appdata";
          recordsize = "128K";
        };

        "secure/postgres" = mkDataset {
          mountpoint = "${mountRoot}/postgres";
          recordsize = "16K";
          options = {
            primarycache = "metadata";
          };
        };

        "secure/vm" = mkDataset {
          mountpoint = "${mountRoot}/vm";
          recordsize = "128K";
        };
      };
    };
  };
}
