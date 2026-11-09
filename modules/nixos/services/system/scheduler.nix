{
  pkgs,
  config,
  ...
}:
let
  enable = config.dot.device.type == "workstation";
in
{
  services.scx-loader = {
    inherit enable;
    config.default_sched = "scx_bpfland";
    schedsPackages = [ pkgs.scx.rustscheds ];
  };
}
