{
  pkgs,
  config,
  ...
}:
let
  enable = config.dot.device.type == "workstation";
in
{
  services.scx = {
    inherit enable;
    scheduler = "scx_bpfland";
    package = pkgs.scx.rustscheds;
  };
}
