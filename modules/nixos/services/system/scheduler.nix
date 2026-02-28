{
  pkgs,
  config,
  ...
}: let
  enable = config.my.machine.type == "workstation";
in {
  services.scx = {
    inherit enable;
    scheduler = "scx_bpfland";
    package = pkgs.scx.rustscheds;
  };
}
