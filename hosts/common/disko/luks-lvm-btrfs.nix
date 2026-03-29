{
  device ? "/dev/nvme0n1",
  swapSize ? "32G",
  ...
}:
{
  disko.devices = {
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
            label = "boot";
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
                allowDiscards = true; # SSD optimization
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
                type = "lvm_pv";
                vg = "pool";
              };
            };
          };
        };
      };
    };
    lvm_vg.pool = {
      type = "lvm_vg";
      lvs = {
        # swap = {
        #   name = "swap";
        #   size = swapSize;
        #   content = {
        #     type = "swap";
        #     resumeDevice = true; # resume from hiberation from this device
        #   };
        # };
        nixos = {
          # Uses different format for specifying size
          # Based on `lvcreate` arguments
          size = "100%FREE";
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ]; # Override existing filesystem
            # Subvolumes must set a mountpoint in order to be mounted
            # unless its parent is mounted
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
                "@nix" = {
                  mountpoint = "/nix";
                  inherit mountOptions;
                };
                "@persist" = {
                  mountpoint = "/persist";
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
}
