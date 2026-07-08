{
  modules = [
    ./config.nix
    (import ../common/disko/bios-ext4.nix {
      device = "/dev/vda";
      swapSize = "2G";
    })
  ];
}
