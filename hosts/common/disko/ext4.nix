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
      partitions = {
        ESP = {
          priority = 1;
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };

        swap = {
          label = "swap";
          size = swapSize;
          content = {
            type = "swap";
            randomEncryption = true;
          };
        };

        root = {
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
