{
  device ? "/dev/disk/by-id/scsi-0HC_Volume_106097038",
  nixSize ? "100G",
  ...
}:
{
  disko.devices.disk.athena-volume = {
    type = "disk";
    inherit device;
    content = {
      type = "gpt";
      partitions = {
        nix-store = {
          priority = 1;
          size = nixSize;
          content = {
            type = "filesystem";
            format = "ext4";
            extraArgs = [
              "-L"
              "nix-store"
            ];
            mountpoint = "/nix";
            mountOptions = [
              "noatime"
            ];
          };
        };

        persistent-state = {
          priority = 2;
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            extraArgs = [
              "-L"
              "persistent-state"
            ];
            mountpoint = "/var/lib";
            mountOptions = [
              "noatime"
            ];
          };
        };
      };
    };
  };
}
