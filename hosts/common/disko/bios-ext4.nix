{
  device ? "/dev/sda",
  swapSize ? "2G",
  ...
}:
{
  disko.devices.disk.main = {
    type = "disk";
    inherit device;
    content = {
      type = "gpt";
      partitions = {
        boot = {
          priority = 1;
          size = "1M";
          type = "EF02";
        };
        swap = {
          priority = 2;
          label = "swap";
          size = swapSize;
          content = {
            type = "swap";
            randomEncryption = true;
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
      };
    };
  };
}
