{ config, lib, ... }:
let
  cfg = config.my.pi;
in
{
  options.my.pi.enable = lib.mkEnableOption "Pi coding agent";

  config = lib.mkIf cfg.enable {
    programs.pi-coding-agent = {
      enable = true;
      mutableSettings = true;
    };
  };
}
