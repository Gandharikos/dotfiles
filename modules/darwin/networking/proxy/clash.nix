{
  lib,
  config,
  ...
}:
let
  cfg = config.my.networking.proxy;
  inherit (lib.modules) mkIf;
in
{
  config = mkIf (cfg.enable && cfg.backend == "mihomo") {
    homebrew.casks = [ "clash-verge-rev" ];
  };
}
