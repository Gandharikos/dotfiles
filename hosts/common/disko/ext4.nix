{
  device ? "/dev/nvme0n1",
  swapSize ? "32G",
  ...
}:
{
  disko.devices.disk.main = {
    type = "disk";
    inherit device;

    content = {
      type = "gpt";
      # Null disables disk swap for zram-only hosts; existing callers keep their sizes.
      partitions = {
        ESP = {
          priority = 1;
          label = "boot";
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };

        root = {
          priority = 3;
          label = "nixos";
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      }
      // (
        if swapSize == null then
          { }
        else
          {
            swap = {
              priority = 2;
              label = "swap";
              size = swapSize;
              content = {
                type = "swap";
                randomEncryption = true;
              };
            };
          }
      );
    };
  };
}
