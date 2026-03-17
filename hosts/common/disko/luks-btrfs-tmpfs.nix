{
  device ? "/dev/nvme0n1",
  swapSize ? "32G",
  ...
}:
{
  disko.devices = {
    nodev."/" = {
      fsType = "tmpfs";
      mountOptions = [
        "defaults"
        # set mode to 755, otherwise systemd will set it to 777, which cause problems.
        # relatime: Update inode access times relative to modify or change time.
        "mode=755"
      ];
    };

    disk.main = {
      type = "disk";
      inherit device;

      content = {
        type = "gpt";
        partitions = {
          ESP = {
            priority = 1;
            size = "512M";
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

          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypted";
              settings = {
                allowDiscards = true;
                bypassWorkqueues = true; # SSD optimization
                # https://github.com/hmajid2301/dotfiles/blob/a0b511c79b11d9b4afe2a5e2b7eedb2af23e288f/systems/x86_64-linux/framework/disks.nix#L36
                crypttabExtraOpts = [
                  "fido2-device=auto"
                  "token-timeout=10"
                ];
              };
              # encrypt the root partition with luks2 and argon2id, will prompt for a passphrase, which will be used to unlock the partition.
              # cryptsetup luksFormat
              extraFormatArgs = [
                "--type luks2"
                "--cipher aes-xts-plain64"
                "--hash sha512"
                "--iter-time 5000"
                "--key-size 256"
                "--pbkdf argon2id"
                # use true random data from /dev/random, will block until enough entropy is available
                "--use-random"
              ];
              extraOpenArgs = [
                "--timeout 10"
              ];
              content = {
                type = "btrfs";
                # Override existing filesystem
                extraArgs = [ "-f" ];
                # Subvolumes must set a mountpoint in order to be mounted
                # unless its parent is mounted
                subvolumes =
                  let
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                      "nodiratime"
                      "discard"
                      "nofail"
                    ];
                  in
                  {
                    # mount the top-level subvolume at /btr_pool
                    # it will be used by btrbk to create snapshots
                    "/" = {
                      mountpoint = "/btr_pool";
                      # btrfs's top-level subvolume, internally has an id 5
                      # we can access all other subvolumes from this subvolume.
                      mountOptions = [ "subvolid=5" ];
                    };
                    # why use @ in btrfs subvolume names:
                    # https://askubuntu.com/questions/987104/why-the-in-btrfs-subvolume-names
                    # https://www.reddit.com/r/btrfs/comments/11wnyoj/btrfs_what_is/
                    "@nix" = {
                      mountpoint = "/nix";
                      inherit mountOptions;
                    };
                    "@persist" = {
                      mountpoint = "/persist";
                      inherit mountOptions;
                    };
                    "@log" = {
                      mountpoint = "/var/log";
                      inherit mountOptions;
                    };
                    "@tmp" = {
                      mountpoint = "/tmp";
                      mountOptions = [ "noatime" ];
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
