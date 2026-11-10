{ config, lib, ... }:
let
  cfg = config.my.agy;
in
{
  options.my.agy.enable = lib.mkEnableOption "agy";

  config = lib.mkIf cfg.enable {
    programs.antigravity-cli = {
      enable = true;
      mutableSettings = true;
      enableMcpIntegration = config.my.mcp.enable or false;
    };
  };
}
